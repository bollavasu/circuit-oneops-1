# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fog/google'
require 'json'


def clean_for_log( log )
  return log.gsub("\n"," ").gsub("<","").gsub(">","")
end

cloud_name = node[:workorder][:cloud][:ciName]
token = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
conn = Fog::Compute.new({
                          :provider => 'Google',
                          :google_project => 'oneops-153015',
                          :google_client_email => token[:key],
                          :google_json_key_location => token[:secret]
                        })

rfcCi = node[:workorder][:rfcCi]
Chef::Log.debug("rfcCi attrs:"+rfcCi[:ciAttributes].inspect.gsub("\n"," "))

nsPathParts = rfcCi[:nsPath].split("/")
security_domain = nsPathParts[3]+'.'+nsPathParts[2]+'.'+nsPathParts[1]
Chef::Log.debug("security domain: "+ security_domain)


# size / flavor
sizemap = JSON.parse( token[:sizemap] )
size_id = sizemap[rfcCi[:ciAttributes][:size]]
Chef::Log.info("flavor: #{size_id}")

# image_id
image = conn.images.get node[:image_id]
Chef::Log.info("image: "+clean_for_log(image.inspect) )

server = nil

if ! rfcCi["ciAttributes"]["instance_id"].nil? &&
    ! rfcCi["ciAttributes"]["instance_id"].empty? &&
    ! rfcCi["rfcAction"] == "replace"

  server = conn.servers.get(rfcCi["ciAttributes"]["instance_id"])

else
  conn.servers.all.each do |s|

    tags = s.tags
    Chef::Log.debug("tags: "+tags.inspect)

    if tags.has_key?("Name") && tags["Name"] == node.server_name  && (s.state == "running" || s.state == "stopped")
      s.reload
      server = s
      break
    end

  end

end


# security group
secgroup = node.workorder.payLoad.DependsOn.select { |d| d[:ciClassName] =~ /Secgroup/ }.first
Chef::Log.info("secgroup: #{secgroup[:ciAttributes][:group_name]}")


if server.nil?
  Chef::Log.info("creating server")

  compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
  if compute_service.has_key?("availability_zones") && !compute_service[:availability_zones].empty?
    availability_zones = JSON.parse(compute_service[:availability_zones])
  end

  if availability_zones.size > 0
    case node.workorder.box.ciAttributes.availability
      when "redundant"
        instance_index = node.workorder.rfcCi.ciName.split("-").last.to_i + node.workorder.box.ciId
        index = instance_index % availability_zones.size
        availability_zone = availability_zones[index]
      else
        random_index = rand(availability_zones.size)
        availability_zone = availability_zones[random_index]
    end
  end

  manifest_ci = node.workorder.payLoad.RealizedAs[0]

  if manifest_ci["ciAttributes"].has_key?("required_availability_zone") &&
      !manifest_ci["ciAttributes"]["required_availability_zone"].empty?

    availability_zone = manifest_ci["ciAttributes"]["required_availability_zone"]
    Chef::Log.info("using required_availability_zone: #{availability_zone}")
  end

  puts "***RESULT:availability_zone=#{availability_zone}"

  # needed for centos to see ephemerals
  block_device_mapping = [
      { 'DeviceName' => '/dev/sdf', 'VirtualName' => 'ephemeral0' },
      { 'DeviceName' => '/dev/sdg', 'VirtualName' => 'ephemeral1' }
  ]
  disk_name = node.server_name
  server_name = node.server_name
      Chef::Log.info("server_name "+server_name)
	  Chef::Log.info("image id "+image.id)
	  Chef::Log.info(" server image id "+ node.image_id)
  begin
    if conn.disks.get(disk_name).nil?
      disk = conn.disks.create({
                                   :name => disk_name,
                                   :zone_name => availability_zone,
                                   :size_gb => 10,
                                   :source_image => node.image_id
                               })

  else
     disk = conn.disks.get(disk_name)
    end
      Chef::Log.info("CREATING DISK")
      disk.wait_for { disk.ready? }
      Chef::Log.info("DISK READY")

     if conn.servers.get(server_name).nil?
      server = conn.servers.create({
                                       :name => server_name,
                                       :machine_type => size_id,
                                       :zone_name => availability_zone,
				       :tags => ["http-server"],
                                       :disks => [disk.get_as_boot_disk(true,true)]
                                   })

     else
     server = conn.servers.get(server_name)
     end
  Chef::Log.info("CREATING SERVER")
  server.wait_for { server.ready? }
  Chef::Log.info("SERVER READY")
  rescue Exception => e
    #Chef::Log.error("NEW MESSAGE : "+e.message)
  end

  Chef::Log.info("server ready: "+clean_for_log(server.inspect) )
  Chef::Log.info("server ready: "+clean_for_log(server.inspect) )
  node.set[:ip] = server.public_ip_address || server.private_ip_address

  file "vm_ip" do
  path "/opt/vm_ip"
  mode 0644
  content server.public_ip_address || server.private_ip_address
  end

  include_recipe "compute::ssh_port_wait"

else

  if server.state == "stopped"
    Chef::Log.info("starting server")
    server.start
    server.wait_for { ready? }
  end

  a = server
  server = nil
  server = conn.servers.get(a.id)
  node.set[:ip] = server.public_ip_address || server.private_ip_address
  Chef::Log.info("running server: "+clean_for_log(server.inspect) )

end

if node.ostype =~ /centos/ &&
    node.set["use_initial_user"] = true
  node.set["initial_user"] = "centos"
end

