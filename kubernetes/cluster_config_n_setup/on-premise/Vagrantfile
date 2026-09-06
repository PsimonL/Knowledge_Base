# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_MASTERS = 1
NUM_WORKERS = 2

# UBUNTU_BOX = "ubuntu/focal64"
UBUNTU_BOX = "bento/ubuntu-20.04"
# ROCKY_BOX = "generic/rocky8"
# ROCKY_BOX = "rockylinux/9"
# DEBIAN_BOX = "bento/debian-11"
MASTER_NAME = "k8s-master"
WORKER_NAME = "k8s-worker"
RANGE_IP = "192.168.56"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox", owner: "vagrant", group: "vagrant"

  (1..NUM_MASTERS).each do |i|
      config.vm.define "k8s-master" do |master|
        master.vm.box = UBUNTU_BOX
        
        master.vm.network "private_network", ip: "#{RANGE_IP}.#{i + 180}"
        master.vm.hostname = "#{MASTER_NAME}-#{i + 180}"

        master.vm.provider :virtualbox do |vb|
          vb.name = "#{MASTER_NAME}-#{i + 180}"
          vb.memory = 2048
          vb.cpus = 2
        end

        config.vm.network "forwarded_port",
        guest: 8001,
        host:  8001,
        auto_correct: true
        
        config.vm.network "forwarded_port",
        guest: 30000,
        host:  30000,
        auto_correct: true
        
        config.vm.network "forwarded_port",
        guest: 8443,
        host:  8443,
        auto_correct: true

        master.vm.provision "shell", inline: <<-SHELL
          sudo apt-get update
          sudo apt install python3
          sudo apt-get -y install python3-pip
          sudo apt update
        SHELL
        master.vm.provision "ansible_local" do |ansible|
          ansible.compatibility_mode = "2.0"
          ansible.playbook = "master-playbook.yml"
          ansible.install_mode = "pip"
          ansible.version = "latest"
          ansible.extra_vars = {
            master_node_ip: "#{RANGE_IP}.#{i + 180}",
            worker_node_name: "#{WORKER_NAME}-#{i + 200}",
        }
      end
    end
  end


  (1..NUM_WORKERS).each do |i|
    config.vm.define "k8s-worker-#{i}" do |worker|
    worker.vm.box = UBUNTU_BOX

        worker.vm.network "private_network", ip: "#{RANGE_IP}.#{i + 200}"
        worker.vm.hostname = "#{WORKER_NAME}-#{i + 200}"
        
        worker.vm.provider :virtualbox do |vb|
          vb.name = "#{WORKER_NAME}-#{i + 200}"
          vb.memory = 2048
          vb.cpus = 2
        end

        worker.vm.provision "shell", inline: <<-SHELL
          sudo apt-get update
          sudo apt install python3
          sudo apt-get -y install python3-pip
          sudo apt update
        SHELL
        worker.vm.provision "ansible_local" do |ansible|
            ansible.playbook = "worker-playbook.yml"
            ansible.extra_vars = {
                worker_node_ip: "#{RANGE_IP}.#{i + 200}",
                worker_node_name: "#{WORKER_NAME}-#{i + 200}",
            }
        end
    end
  end


end