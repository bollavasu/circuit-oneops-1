name             "Google"
description      "Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'key',
  :description => "Service Account Email",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Service Account Email from the provider',
    :category => '1.Authentication',
    :order => 1
  }

attribute 'secret',
  :description => "Google Json Key absolute Path",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Json key path generated from the Google security credentials page',
    :category => '1.Authentication',
    :order => 2
  }

attribute 'region',
  :description => "Region",
  :default => "",
  :format => {
    :help => 'Region Name',
    :category => '2.Placement',
    :order => 1
  }

attribute 'availability_zones',
  :description => "Availability Zones",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Availability Zones - Singles will round robin, Redundant will use platform id',
    :category => '2.Placement',
    :order => 2
  }  
  
attribute 'subnet',
  :description => "Subnet Name",
  :default => "",
  :format => {
    :help => 'Subnet Name is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 3
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{"XS":"f1-micro","S":"n1-standard-2","M":"n1-standard-1","L":"n1-standard-2","XL":"n1-standard-4",
"XXL":"n1-standard-8","4XL":"n1-standard-16"}',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"ubuntu-16.04":"",
                "centos-7.2":"",
                "debian-8":""},
				"fedora-24":""}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
    :order => 2
  }

attribute 'repo_map',
  :description => "OS Package Repositories keyed by OS Name",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of repositories by OS Type containing add commands - ex) yum-config-manager --add-repo repository_url or deb http://us.archive.ubuntu.com/ubuntu/ hardy main restricted ',
    :category => '4.Operating System',
    :order => 2
  }

attribute 'env_vars',
  :description => "System Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Environment variables - ex) http => http://yourproxy, https => https://yourhttpsproxy, etc',
    :category => '4.Operating System',
    :order => 2
  }

# operating system
attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "ubuntu-16.04",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '4.Operating System',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 16.04 (xenial)','ubuntu-16.04'],
      ['CentOS 7.2','centos-7.2'],
      ['Debian 8','debian-8'],
      ['Fedora 24','fedora-24']	  ] }
  }
