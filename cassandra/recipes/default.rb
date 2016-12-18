#
# Cookbook Name:: cassandra
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#

#package 'java-1.8.0-openjdk-devel' do
#  action :install
#end

include_recipe 'java' if node['cassandra']['install_java']

template '/etc/yum.repos.d/datastax.repo' do
  source 'datastax.repo.erb'
#  owner 'web_admin'
#  group 'web_admin'
  mode '0755'
  action :create
end

package 'datastax-ddc' do
  action :install
end


package 'vim-enhanced' do
  action :install
end

# configuration files
template ::File.join(node['cassandra']['conf_dir'], 'cassandra.yaml') do
  source 'cassandra.yaml.erb'
  mode '0644'
end

#bash 'conf_cassandra' do
#  cwd '/'
#  code <<-EOH
#    sed -i -e \"s/listen_address:.*/listen_address: \"$(curl -s curl http://169.254.169.254/latest/meta-data/local-ipv4)\"/\" /etc/cassandra/default.conf/cassandra.yaml
#    EOH
#end

service 'cassandra' do
  action :start
end
