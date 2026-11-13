sudo dnf install -y autoconf
sudo dnf install -y bison
sudo dnf install -y git wget tar sqlite* libxslt* gcc gcc-c++ make autoconf automake bison
wget https://github.com/skvadrik/re2c/releases/download/1.3/re2c-1.3.tar.xz
sudo dnf install -y libcurl-devel
sudo dnf install -y gd-devel
sudo dnf install -y libicu-devel
sudo vim /etc/selinux/config
sudo dnf config-manager --enable ol8_developer_EPEL
sudo dnf config-manager --enable ol8_codeready_builder
sudo dnf install -y oniguruma-devel
sudo dnf install -y libpq-devel
sudo dnf install -y readline-devel
sudo dnf install -y libxslt-devel sqlite-devel bzip2-devel gd-devel oniguruma-devel libzip-devel openssl-devel curl-devel
