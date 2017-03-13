
case node[:platform]
when "debian", "ubuntu"
  rabbitmq_repository "rabbitmq" do
    uri "http://www.rabbitmq.com/debian/"
    distribution "testing"
    components ["main"]
    key "http://www.rabbitmq.com/rabbitmq-signing-key-public.asc"
    action :add
  end
  package "rabbitmq-server" do
    action :install
    options "--force-yes"
  end
when "redhat", "centos", "fedora"
  package "erlang"
  package "socat"
end

cloud_name = node[:workorder][:cloud][:ciName]
if node[:workorder][:services].has_key? "mirror"
  mirrors = JSON.parse(node[:workorder][:services][:mirror][cloud_name][:ciAttributes][:mirrors])
else
  mirrors = Hash.new
end

source = mirrors["rabbitmq-server"]
if source.nil?
  Chef::Log.info("rabbitmq source repository has not beed defined in cloud mirror service.. taking default #{node.rabbitmq.source}")
  source = node.rabbitmq.source
else
  Chef::Log.info("using rabbitmq source repository that has been defined in cloud mirror service #{source}")
end

version = node.rabbitmq.version

if node.platform_version.start_with?("6")
  file_name = "rabbitmq-server-#{version}-1.el6.noarch.rpm"
elsif node.platform_version.start_with?("7")
  file_name = "rabbitmq-server-#{version}-1.el7.noarch.rpm"
end

#chef_gem 'parallel'

shared_download_http "#{source}/v#{version}/#{file_name}" do
  path "/tmp/#{file_name}"
  action :create
end

#remote_file "/tmp/#{file_name}" do
#  source "#{source}/v#{version}/#{file_name}"
#end

bash "Install Rabbitmq" do
  code <<-EOH
  rpm -ivh /tmp/#{file_name}
  chkconfig rabbitmq-server on
  EOH
end

service "rabbitmq-server" do
  action :stop
end

directory "/etc/rabbitmq/" do
  owner "root"
  group "root"
  mode 0755
  action :create
end

template "/etc/rabbitmq/rabbitmq-env.conf" do
  source "rabbitmq-env.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/var/lib/rabbitmq/.erlang.cookie" do
  source "doterlang.cookie.erb"
  owner "rabbitmq"
  group "rabbitmq"
  mode 0400
end

execute "Remove old rabbitmq data directory" do
  command "rm -rf /var/lib/rabbitmq/mnesia"
end

directory node.workorder.rfcCi.ciAttributes.datapath do
  owner "rabbitmq"
  group "rabbitmq"
  mode 0755
  action :create
  recursive true
end

directory "/log/rabbitmq" do
  owner "rabbitmq"
  group "rabbitmq"
  mode 0755
  action :create
  recursive true
end

service "rabbitmq-server" do
  action [:enable, :start]
end

execute "Enable Rabbitmq Management" do
  not_if "/usr/lib/rabbitmq/bin/rabbitmq-plugins  list | grep '\[E\].*rabbitmq_management'"
  command "/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management"
  user 0
  action :run
end

rabbitmq_user "guest" do
  password "guest123"
  action :add
end

rabbitmq_user "nova" do
  password "sekret"
  action :add
end

rabbitmq_user "guest" do
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
end

rabbitmq_user "nova" do
  permissions "\".*\" \".*\" \".*\""
  action :set_permissions
end

execute "Enable Rabbitmq Management for user nova" do
  command "/usr/sbin/rabbitmqctl set_user_tags nova administrator"
  action :run
end

execute "Enable Rabbitmq Management for user guest" do
  command "/usr/sbin/rabbitmqctl set_user_tags guest administrator"
  action :run
end

service "rabbitmq-server" do
  action :restart
end

file "/tmp/#{file_name}" do
  action :delete
end
