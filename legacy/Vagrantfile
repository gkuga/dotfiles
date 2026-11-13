VAGRANTFILE_API_VERSION = "2"
Dotenv.load

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"
  config.vm.hostname = "dev"

  config.vm.provider "hyperv" do |h|
    h.vmname = "dev"
    h.memory = 4096
    h.cpus = 2
    h.ip_address_timeout = 240
    h.vm_integration_services do |service|
      service.heartbeat = true
      service.time_synchronization = true
    end
  end

  config.vm.provision :ansible_local do |ansible|
    ansible.playbook       = "linux.yaml"
    ansible.verbose        = true
    ansible.install        = true
    ansible.limit          = "all"
    ansible.inventory_path = "inventory"

    ansible.install  = true
  end
end
