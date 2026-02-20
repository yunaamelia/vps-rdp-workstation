# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian12"

  # Forward standard RDP port
  config.vm.network "forwarded_port", guest: 3389, host: 33890

  # Libvirt Provider Configuration
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 4096
    libvirt.cpus = 2
    libvirt.video_type = "virtio" # Better graphics support
    libvirt.graphics_type = "spice"
  end

  # VirtualBox Provider Confirmation (fallback)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
    vb.gui = true
    vb.customize ["modifyvm", :id, "--vram", "128"]
  end

  # Provision using our Ansible playbook
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbooks/main.yml"
    ansible.extra_vars = {
      vps_hostname: "vagrant-workstation",
      vps_install_desktop: true
    }
  end
end
