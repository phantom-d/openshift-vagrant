require 'yaml'
require 'fileutils'

config = {
  local: './vagrant/config/vagrant-local.yml',
  example: './vagrant/config/vagrant-local.example.yml'
}

# read config
if File.exist?(config[:local])
  options = YAML.load_file config[:local]
else
  # copy config from example if local config not exists
  FileUtils.cp config[:example], config[:local] unless File.exist?(config[:local])
  # read config
  options = YAML.load_file config[:local]
end

domains = {
  oc: "oc.#{options['domain_name']}",
  apps: "apps.#{options['domain_name']}",
}

required_plugins = %w( vagrant-hostmanager vagrant-vbguest )
required_plugins.each do |plugin|
    exec "vagrant plugin install #{plugin};vagrant #{ARGV.join(" ")}" unless Vagrant.has_plugin? plugin || ARGV[0] == 'plugin'
end

# vagrant configurate
Vagrant.configure(2) do |config|
  # select the box
  if options.has_key?('vm_box')
    config.vm.box = options['vm_box']
  else
    config.vm.box = options['domain_name']
  end

  if options.has_key?('vm_box_url')
    config.vm.box_url = options['vm_box_url']
  end

  # should we ask about box updates?
  config.vm.box_check_update = options['box_check_update']

  config.vm.provider 'virtualbox' do |vb|
    # machine cpus count
    vb.cpus = options['cpus']
    # machine memory size
    vb.memory = options['memory']
    # machine name (for VirtualBox UI)
    if options.has_key?('machine_name')
      vb.name = options['machine_name']
    end
    vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
  end

  if options.has_key?('machine_name')
    # machine name (for vagrant console)
    config.vm.define options['machine_name']

    # machine name (for guest machine console)
    config.vm.hostname = options['machine_name']
  end

  # network settings
  config.vm.network 'private_network', ip: options['ip']
  if options.has_key?('vagrant_ssh')
    config.vm.network "forwarded_port",
      guest: 22,
      host: options['vagrant_ssh'],
      id: 'ssh'
  end

  # sync: project folder (host machine) -> folder options['app_path'] (guest machine)
  config.vm.synced_folder './', options['app_path'], owner: 'vagrant', group: 'vagrant'

  # disable folder '/vagrant' (guest machine)
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # hosts settings (host machine)
  # vagrant plugin install vagrant-hostmanager
  config.vm.provision :hostmanager
  config.hostmanager.enabled            = true
  config.hostmanager.manage_host        = true
  config.hostmanager.manage_guest       = true
  config.hostmanager.ignore_private_ip  = false
  config.hostmanager.include_offline    = true
  config.hostmanager.aliases            = domains.values

  # provisioners
  config.vm.provision 'shell',
    inline: <<-SHELL
      echo " "
      echo "--> Fix no tty"
      sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile
      echo "--> Done!"
      echo " "
    SHELL

  # once run
  config.vm.provision 'shell',
    path: "./vagrant/provision/once-as-root.sh",
    args: [
      options['app_path'],
      options['timezone'],
      domains[:oc],
      domains[:apps],
      options['version'],
    ]

  # always run
  config.vm.provision 'shell',
    path: "./vagrant/provision/always-as-root.sh",
    args: [
      options['app_path'],
    ],
    run: 'always'

  # post-install message (vagrant console)
  config.vm.post_up_message = "Openshift console URL: https://#{domains[:oc]}:8443"
end
