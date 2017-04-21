if node.platform != "ubuntu"
 if(node[:workorder][:cloud][:ciAttributes][:location].index('google') == nil)
  execute "sudo pkill -f '^/usr/sbin/postfix -d' ; service postfix restart"
 end
end
  
