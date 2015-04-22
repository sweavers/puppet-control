# -*- mode: ruby -*-
# vi: set ft=ruby :


Vagrant.configure(2) do |config|
  
  config.vm.box = "landregistry/centos"
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "site.pp"
    puppet.hiera_config_path = "hiera.vagrant.yaml"
    puppet.working_directory = "/tmp/vagrant-puppet"
    puppet.options = '--environment=development'
    puppet.module_path = "site/profiles/manifests"
    puppet.facter = {
      'is_vagrant'   => true,
    }
  end

  if defined? VagrantPlugins::Cachier
    config.cache.scope = :box
    config.cache.auto_detect = true
  else
    puts "Yum cache is available (vagrant plugin install vagrant-cachier)."
    puts "You really want to install vagrant-cachier.  Vagrant build go zoooooom."
    puts "Continuing in slow mode..."
  end


  config.vm.define "charges" do |charges|
    charges.vm.host_name = "charges"
    charges.vm.provider :virtualbox do |v|
      v.customize ['modifyvm', :id, '--memory', '2048']
    end
  end
  
end
