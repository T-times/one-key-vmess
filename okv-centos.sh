#!/bin/bash

bbr_setup(){
	sysctl net.ipv4.tcp_available_congestion_control | grep bbr > /dev/null
	if [[ $? -eq 0 ]]; then
		echo "You have set bbr speed."
	else
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/athlonreg/myshell/master/centos-bbr.sh)"
	fi
}

var(){
	read -p "Input your domain name to set: " domain
	read -p "Input your encryption method of shadowsocks: " method
	read -p "Input your password of shadowsocks: " sspass
	read -p "Input the port of v2ray: " vmessport

	wget https://raw.githubusercontent.com/athlonreg/one-key-vmess/master/conf/shadowsocks.json
	wget https://raw.githubusercontent.com/athlonreg/one-key-vmess/master/conf/config.json
	wget https://raw.githubusercontent.com/athlonreg/one-key-vmess/master/conf/vmess.conf
	wget https://raw.githubusercontent.com/athlonreg/one-key-vmess/master/conf/nginx.repo 
}

swap_setup(){
	echo "Setup swap partition: "
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/athlonreg/myshell/master/swap_setup.sh)"
}

base_setup(){
	yum -y install epel-release axel wget unzip zip ntpdate libsodium
	if [[ $? -eq 0 ]]; then
		yum -y install python3-pip
	else
		exit 1
	fi
}

shadowsocks_setup(){
	echo "Installing shadowsocks..."
	pip3 install https://github.com/shadowsocks/shadowsocks/archive/master.zip
	cp -arf shadowsocks.json /etc/shadowsocks.json
	sed -i 's/encryption/$method/g' /etc/shadowsocks.json
	sed -i 's/shadowsocks/$sspass/g' /etc/shadowsocks.json
	ssserver -c /etc/shadowsocks.json -d start
}

optimize(){
	echo "Starting network optimize..."
	echo -e "
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
#net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla" >> /etc/sysctl.conf
	sysctl -p

	if [[ $? -eq 0 ]]; then
		sysctl net.ipv4.tcp_available_congestion_control | grep bbr > /dev/null
	else
		echo "Network optimize failed..."
		exit 1
	fi
	
	if [[ $? -eq 0 ]]; then
		ulimit -s 51200
	else
		echo "Network optimize failed..."
		exit 1
	fi

	echo -e "
* soft nofile 51200
* hard nofile 51200" >> /etc/security/limits.conf
}

nginx_setup(){
	echo "Installing nginx..."
	yum -y install nginx nginx-module-perl
	systemctl enable nginx
	systemctl start nginx
}

v2ray_setup(){
	echo "Installing v2ray..."
	wget https://install.direct/go.sh
	yum -y install python2-certbot-nginx certbot

	if [[ $? -eq 0 ]]; then
		systemctl stop nginx
	else
		echo "python2-certbot-nginx or certbot install failed..."
		exit 1
	fi

	bash go.sh

	if [[ $? -eq 0 ]]; then
		cid=$(cat /etc/v2ray/config.json | grep id | awk -F '"' '{print $4}')
		cp /etc/v2ray/config.json /etc/v2ray/config.json.bak
		cp -arf config.json /etc/v2ray/config.json
		sed -i 's/cid/$id/g' /etc/v2ray/config.json
		sed -i 's/12345/$vmessport/g' /etc/v2ray/config.json
		systemctl enable v2ray
		systemctl start v2ray
		ntpdate time2.aliyun.com
	else
		echo "v2ray install failed..."
		exit 1
	fi

	certbot --nginx -d $domain

	if [[ $? -eq 0 ]]; then
		cp vmess.conf /etc/nginx/conf.d/vmess.conf
		sed -i 's/www.example.com/$domain/g' /etc/nginx/conf.d/vmess.conf
		sed -i 's/12345/$vmessport/g' /etc/nginx/conf.d/vmess.conf
		systemctl restart nginx
	else
		echo "Certificate you apply failed..."
		exit 1
	fi

	echo "Please setup the timezone of your clients: "
	if [[ $? -eq 0 ]]; then
		tzselect
	else
		exit 1
	fi

	echo "Please setup these crontab tasks: "
	echo "#######################################################################"
	echo '#### 0 3 1 * * certbot renew –renew-hook "systemctl restart nginx" ####'
	echo "############## */15 * * * * ntpdate time2.aliyun.com ##################"
	echo "#######################################################################"

	crontab -e
}

main(){
	bbr_setup
	base_setup
	var
	swap_setup
	shadowsocks_setup
	optimize
	nginx_setup
	v2ray_setup
}

main

exit 0
