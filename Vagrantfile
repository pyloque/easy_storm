# -*- mode: ruby -*-

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.proxy.http = "http://59.151.100.77:33100"
  config.proxy.https = "https://59.151.100.77:33100"
  config.proxy.no_proxy = "localhost,127.0.0.1"
  config.cache.scope = :box
  config.cache.enable :generic, {
    "wget" => { cache_dir: "/var/cache/wget" }    
  }
  3.times do |i|
    config.vm.define vmname="zhangyue%d" % i do |config|
        config.vm.hostname = vmname
        config.vm.network "private_network", ip: "172.28.2.1%s" % i
        config.vm.provider "virtualbox" do |vb|
            memsize = "1024"
            memsize = "2048" if i == 0
            vb.customize ["modifyvm", :id, "--memory", memsize]
        end
        config.vm.provision :shell, :path => "./bootstrap.sh", :args => vmname, :privileged => false
    end
  end
end
