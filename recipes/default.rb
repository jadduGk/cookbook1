#
# Cookbook:: cookbook1
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.
#
# Install default JRE
apt_update 'update'
package 'default-jre' do
  action :install
end

# Download Ignite binary distribution
remote_file '/tmp/apache-ignite-2.14.0-bin.zip' do
  source 'https://dlcdn.apache.org/ignite/2.14.0/apache-ignite-2.14.0-bin.zip'
  mode '0755'
  action :create
end

group 'ignite'

user 'ignite' do
  gid 'ignite'
  shell '/bin/bash'
  home '/home/ignite'
  manage_home true
  action :create
  not_if 'getent passwd ignite'
end

directory '/opt' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory '/opt/ignite' do
  owner 'ignite'
  group 'ignite'
  mode '0755'
  action :create
end

# Unzip Ignite distribution and move to /opt/ignite
execute 'unzip_ignite_distribution' do
  command 'unzip /tmp/apache-ignite-2.14.0-bin.zip -d /opt/ignite'
  not_if { ::File.exist?('/opt/ignite/apache-ignite-2.14.0-bin') }
end

# Create a directory for the exporter
directory '/opt/ignite/apache-ignite-2.14.0-bin/exporter' do
  owner 'ignite'
  group 'ignite'
  mode '0755'
  action :create
end

# Download the JMX exporter
remote_file '/opt/ignite/apache-ignite-2.14.0-bin/exporter/jmx_prometheus_javaagent-0.18.0.jar' do
  source 'https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar'
  mode '0644'
end

template '/opt/ignite/apache-ignite-2.14.0-bin/exporter/ignite.yaml' do
  source 'ignite.yaml.erb'
  owner 'ignite'
  group 'ignite'
  mode '0644'
end

template '/etc/systemd/system/ignite.service' do
  source 'ignite.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[systemctl-daemon-reload]', :immediately
  notifies :restart, 'service[ignite.service]'
end

execute 'systemctl-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

service 'ignite.service' do
  action [:enable, :start]
end
