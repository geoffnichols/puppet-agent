platform "aix-6.1-ppc" do |plat|
  plat.servicetype "aix"

  plat.make "gmake"
  plat.tar "/opt/freeware/bin/tar"
  plat.rpmbuild "/usr/bin/rpmbuild"
  plat.patch "/opt/freeware/bin/patch"
  plat.environment "LIBPATH", "/opt/puppetlabs/pupppet/lib:/opt/freeware/lib:/usr/lib:$(LIBPATH)"

  os_version = 6.1
  # For pl-build-tools, we can't rely on yum, and rpm can't download over https on AIX, so curl packages before installing them
  # Order matters here - there is no automatic dependency resolution
  packages = [
    "http://pl-build-tools.delivery.puppetlabs.net/aix/#{os_version}/ppc/pl-cmake-3.2.3-2.aix#{os_version}.ppc.rpm",
  ]

  packages.each do |uri|
    name = uri.split("/").last
    plat.provision_with("curl -O #{uri} > /dev/null")
    plat.provision_with("rpm -Uvh --replacepkgs --nodeps #{name}")
  end

  # Bootstrap yum and dependencies
  plat.provision_with "curl -O http://pl-build-tools.delivery.puppetlabs.net/aix/yum_bootstrap/rpm.rte && installp -acXYgd . rpm.rte all"
  plat.provision_with "curl http://pl-build-tools.delivery.puppetlabs.net/aix/yum_bootstrap/openssl-1.0.2.1500.tar | tar xvf - && cd openssl-1.0.2.1500 && installp -acXYgd . openssl.base all"
  plat.provision_with "rpm --rebuilddb && updtvpkg"
  plat.provision_with "mkdir -p /tmp/yum_bundle && cd /tmp/yum_bundle/ && curl -O http://pl-build-tools.delivery.puppetlabs.net/aix/yum_bootstrap/yum_bundle.tar && tar xvf yum_bundle.tar && rpm -Uvh /tmp/yum_bundle/*.rpm"

   # Use artifactory mirror for AIX toolbox packages
   plat.provision_with "/usr/bin/sed 's/enabled=1/enabled=0/g' /opt/freeware/etc/yum/yum.conf > tmp.$$ && mv tmp.$$ /opt/freeware/etc/yum/yum.conf"
   plat.provision_with "echo '[AIX_Toolbox_mirror]\nname=AIX Toolbox local mirror\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/ppc/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-generic-mirror.repo"
   plat.provision_with "echo '[AIX_Toolbox_noarch_mirror]\nname=AIX Toolbox noarch repository\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/noarch/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-noarch-mirror.repo"
   plat.provision_with "echo '[AIX_Toolbox_61_mirror]\nname=AIX 61 specific repository\nbaseurl=https://artifactory.delivery.puppetlabs.net/artifactory/rpm__remote_aix_linux_toolbox/RPMS/ppc-6.1/\ngpgcheck=0' > /opt/freeware/etc/yum/repos.d/toolbox-61-mirror.repo"

  plat.provision_with "yum install -y rsync coreutils sed make tar pkg-config zlib zlib-devel gawk autoconf gcc gcc-c++ glib2"

  # Workaround hardcoded path in pl-cmake toolchain file
  plat.provision_with "/opt/freeware/bin/sed -i 's|/opt/pl-build-tools|/opt/freeware|g' /opt/pl-build-tools/pl-build-toolchain.cmake"

  plat.install_build_dependencies_with "yum install -y"
  plat.vmpooler_template "aix-6.1-power"
end
