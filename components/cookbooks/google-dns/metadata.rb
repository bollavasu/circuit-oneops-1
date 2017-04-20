name             "Google-dns"
description      "DNS Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

  
attribute 'key',
  :description => "Service account email",
  :required => "required",
  :default => "",
  :format => { 
    :help => 'service account email from the Google security credentials page',
    :category => '1.Credentials',
    :order => 1
  }
  
attribute 'secret',
  :description => "Json Key Path",
  :encrypted => true,
  :required => "required",
  :default => "",
  :format => {
    :help => 'Json key path generated from the Google security credentials page', 
    :category => '1.Credentials',
    :order => 2
  }
  
attribute 'zone',
  :description => "Zone",
  :default => "",
  :format => {
    :help => 'Specify the zone name where to insert DNS records', 
    :category => '2.DNS',
    :order => 1
  }
   
attribute 'cloud_dns_id',
  :description => "Cloud DNS Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Cloud DNS Id - prepended to zone name, but replaced w/ fqdn.global_dns_id for GLB',
    :category => '2.DNS',
    :order => 3
  }

attribute 'authoritative_server',
  :description => "authoritative_server",
  :default => "",
  :format => {
    :help => 'Explicit authoritative_server for verification - useful for testing. If not set uses NS records for the zone.',
    :category => '2.DNS',
    :order => 4
  }
