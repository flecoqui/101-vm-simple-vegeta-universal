#!/bin/bash
# This bash file install apache
# Parameter 1 hostname 
azure_hostname=$1
#############################################################################
log()
{
	# If you want to enable this logging, uncomment the line below and specify your logging key 
	#curl -X POST -H "content-type:text/plain" --data-binary "$(date) | ${HOSTNAME} | $1" https://logs-01.loggly.com/inputs/${LOGGING_KEY}/tag/redis-extension,${HOSTNAME}
	echo "$1"
	echo "$1" >> /testvegeta/log/install.log
}
#############################################################################
check_os() {
    grep ubuntu /proc/version > /dev/null 2>&1
    isubuntu=${?}
    grep centos /proc/version > /dev/null 2>&1
    iscentos=${?}
    grep redhat /proc/version > /dev/null 2>&1
    isredhat=${?}	
	if [ -f /etc/debian_version ]; then
    isdebian=0
	else
	isdebian=1	
    fi

	if [ $isubuntu -eq 0 ]; then
		OS=Ubuntu
		VER=$(lsb_release -a | grep Release: | sed  's/Release://'| sed -e 's/^[ \t]*//' | cut -d . -f 1)
	elif [ $iscentos -eq 0 ]; then
		OS=Centos
		VER=$(cat /etc/centos-release)
	elif [ $isredhat -eq 0 ]; then
		OS=RedHat
		VER=$(cat /etc/redhat-release)
	elif [ $isdebian -eq 0 ];then
		OS=Debian  # XXX or Ubuntu??
		VER=$(cat /etc/debian_version)
	else
		OS=$(uname -s)
		VER=$(uname -r)
	fi
	
	ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

	log "OS=$OS version $VER Architecture $ARCH"
}

#############################################################################
configure_network(){
# firewall configuration 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
}

#############################################################################
install_vegeta(){
wget -q go1.12.7.linux-amd64.tar.gz https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz
mkdir /usr/local/go
tar -C /usr/local -xzf go1.12.7.linux-amd64.tar.gz 

echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
echo "export GOPATH=/testvegeta/go" >> /etc/profile
export GOPATH=/testvegeta/go
echo "export GOCACHE=/testvegeta/gocache" >> /etc/profile
export GOCACHE=/testvegeta/gocache
/usr/local/go/bin/go get -u github.com/tsenart/vegeta
export PATH=$PATH:/testvegeta/go/bin
echo "export PATH=\$PATH:/testvegeta/go/bin" >> /etc/profile
chmod +x /testvegeta/go/bin/vegeta
}
#############################################################################
install_git_ubuntu(){
apt-get -y install git
}
install_git_centos(){
yum -y install git
}
#############################################################################



#############################################################################
configure_network_centos(){
# firewall configuration 
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT


service firewalld start
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
}



#############################################################################

environ=`env`
# Create folders
mkdir /git
mkdir /testvegeta
mkdir /testvegeta/log
mkdir /testvegeta/go
mkdir /testvegeta/gocache
mkdir /testvegeta/config

# Write access in log subfolder
chmod -R a+rw /testvegeta/log
log "Environment before installation: $environ"

log "Installation script start : $(date)"
log "GO Installation: $(date)"
log "#####  azure_hostname: $azure_hostname"
log "Installation script start : $(date)"
check_os
if [ $iscentos -ne 0 ] && [ $isredhat -ne 0 ] && [ $isubuntu -ne 0 ] && [ $isdebian -ne 0 ];
then
    log "unsupported operating system"
    exit 1 
else
	if [ $iscentos -eq 0 ] ; then
	    log "configure network centos"
		configure_network_centos
	    log "install git centos"
		install_git_centos
	    log "install vegeta centos"		
		install_vegeta
	elif [ $isredhat -eq 0 ] ; then
	    log "configure network redhat"
		configure_network_centos
	    log "install git redhat"
		install_git_centos
	    log "install vegeta redhat"
		install_vegeta
	elif [ $isubuntu -eq 0 ] ; then
	    log "configure network ubuntu"
		configure_network
	    log "install git ubuntu"
		install_git_ubuntu
		log "install vegeta ubuntu"
		install_vegeta
	elif [ $isdebian -eq 0 ] ; then
	    log "configure network"
		configure_network
		log "install git debian"
		install_git_ubuntu
		log "install vegeta debian"
		install_vegeta
	fi
	log "installation done"
fi
exit 0 

