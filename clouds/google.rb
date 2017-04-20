name "google"
description "Google Cloud"
auth "googlesecretkey"

image_map = '{
      "centos-7.0":"centos-7-v20170110",
"ubuntu-16.04":"ubuntu-1604-xenial-v20170202",
"debian-8":"debian-8-jessie-v20170124"
    }'

repo_map = '{
      "centos-7.0":"yum -d0 -e0 -y install rsync; rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
}'

service "google-compute",
  :cookbook => 'google',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'compute' },
  :attributes => {
    :region => 'us-central1',
    :availability_zones => "[\"us-central1-a\",\"us-central1-b\",\"us-central1-c\",\"us-central1-f\"]",
    :imagemap => image_map,
    :repo_map => repo_map
#    :size_map => size_map

}

service "google-dns",
  :cookbook => 'google-dns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'dns' }

service "google-gdns",
  :cookbook => 'google-dns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'), 
  :provides => { :service => 'gdns' }
