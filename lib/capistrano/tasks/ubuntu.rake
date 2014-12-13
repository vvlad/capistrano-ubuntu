require 'capistrano/addins'

default_ubuntu_packages = %w[
  tmux
  htop
  vim-nox
  software-properties-common
  curl
  wget
  unattended-upgrades
  bash-completion
  git
  lsof
  ufw
]


set(:ubuntu_packages, [])
set(:ubuntu_software_sources, [])


namespace :ubuntu do


  task :update_sources do

    on roles(:all) do
      fetch(:ubuntu_software_sources).each do |source|

        if source.is_a? Array
          execute "wget --quiet -O - #{source.last} | sudo apt-key add -"
          source = source.first
        end

        sudo "apt-add-repository", "-y", source

      end
    end

  end

  task :install_packages do

    packages = default_ubuntu_packages + fetch(:ubuntu_packages)

    on roles(:all) do

      sudo "apt-get", "-q", "-y", "update"
      sudo "apt-get", "-q", "-y", "--force-yes","install", *packages.flatten
      sudo "apt-get", "-q", "-y", "--force-yes","autoremove"


    end

  end

  task :unattended_upgrades do
    on roles(:all) do
      sudo "yes | sudo dpkg-reconfigure -plow unattended-upgrades"
      file = StringIO.new
      file.puts 'APT::Periodic::Update-Package-Lists "1";'
      file.puts 'APT::Periodic::Unattended-Upgrade "1";'
      file.rewind
      upload_as :root, file, "/etc/apt/apt.conf.d/20auto-upgrades"
      file = StringIO.new
      file.puts <<-EOS
Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
        "${distro_id}:${distro_codename}-updates";
};
      EOS
      file.rewind
      upload_as :root, file, "/etc/apt/apt.conf.d/50unattended-upgrades"

    end
  end


end


before "deploy:starting", "ubuntu:update_sources"
after "ubuntu:update_sources", "ubuntu:install_packages"
after "ubuntu:install_packages", "ubuntu:unattended_upgrades"



