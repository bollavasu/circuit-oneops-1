
#nssservice
Chef::Log.info("Copy the nsservice")
template "/etc/nsswitch.conf" do
  if(node[:workorder][:cloud][:ciAttributes][:location].index('google') > -1)
  source "/home/oneops/circuit-oneops-1/components/cookbooks/os/templates/default/nsswitch.conf.erb"
  local true
  else
  source "nsswitch.conf.erb"
  end
  mode "0644"
  variables({ :ldap => ""})
  user "root"
  group "root"
  only_if {File.exists?("/etc/nsswitch.conf")}
end

# cp system-auth-ac and password-auth-ac
Chef::Log.info("Copy the password-auth-ac")
template "/etc/pam.d/password-auth-ac" do
  source "password-auth-ac.erb"
    variables(
     { :auth => "",
       :session => "",
       :account => "",
       :password => ""
     })
  mode "0644"
  user "root"
  group "root"
  only_if {File.exists?("/etc/pam.d/password-auth-ac")}
end

Chef::Log.info("Copy the system-auth-ac.erb")
template "/etc/pam.d/system-auth-ac" do
  source "system-auth-ac.erb"
   variables(
     { :auth => "",
       :session => "",
       :account => "",
       :password => ""
     })
  mode "0644"
  only_if {File.exists?("/etc/pam.d/system-auth-ac")}
  user "root"
  group "root"
end
