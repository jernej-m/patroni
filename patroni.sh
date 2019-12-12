#-------------- Install postgre, etcd, patroni --------------------
echo "Installing PostgreSQL repo..."
sleep 2
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
echo "-- Installed PosgreSQL repo. --"

echo "Installing postgresql 10 and postgresql10-server..."
sleep 2
yum -y install postgresql10 postgresql10-server
echo "-- Installed postgresql10 and postgresql10-server. --"

echo "Installing etcd..."
sleep 2
yum -y install etcd
echo "-- Installed etcd. --"

echo "Installing epel, for python36-psycopg2 needed by Patroni..."
sleep 2
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
echo "-- Installed epel. --"

echo "Installing wget..."
sleep 2
yum -y install wget
echo "-- Installed wget. --"

echo "Downloading Patroni rpm..."
sleep 2
wget https://github.com/cybertec-postgresql/patroni-packaging/releases/download/1.6.0-1/patroni-1.6.0-1.rhel7.x86_64.rpm
echo "-- Downloaded Patroni rpm. --"

echo "Installing Patroni rpm..."
sleep 2
yum -y install patroni-1.6.0-1.rhel7.x86_64.rpm
echo "-- Installed Patroni rpm --"

# --------- Edit etcd configuration file ------------
sleep 2
echo "Editing etcd configuration file..."

read -p "member 1 private ip: " v_ip_1
read -p "member 2 private ip: " v_ip_2
read -p "member 3 private ip: " v_ip_3
read -p "Enter this member number (1,2,3): " v_member_no

if [ $v_member_no == 1 ]
then
   v_this_ip=$v_ip_1
elif [ $v_member_no == 2 ]
then
   v_this_ip=$v_ip_2
elif [ $v_member_no == 3 ]
then
   v_this_ip=$v_ip_3
else
   echo "Wrong cluster number provided"
fi

sed -i "s/#\?ETCD_NAME=\".*\"/ETCD_NAME=\"patroni$v_member_no\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_LISTEN_PEER_URLS=\".*\"/ETCD_LISTEN_PEER_URLS=\"http:\/\/0.0.0.0:2380\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_LISTEN_CLIENT_URLS=\".*\"/ETCD_LISTEN_CLIENT_URLS=\"http:\/\/0.0.0.0:2379\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_ADVERTISE_PEER_URLS=\".*\"/ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http:\/\/$v_this_ip:2380\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_CLUSTER=\".*\"/ETCD_INITIAL_CLUSTER=\"patroni1=http:\/\/$v_ip_1:2380,patroni2=http:\/\/$v_ip_2:2380,patroni3=http:\/\/$v_ip_3:2380\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_CLUSTER_STATE=\".*\"/ETCD_INITIAL_CLUSTER_STATE=\"new\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_CLUSTER_TOKEN=\".*\"/ETCD_INITIAL_CLUSTER_TOKEN=\"itclustertoken\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_ADVERTISE_CLIENT_URLS=\".*\"/ETCD_ADVERTISE_CLIENT_URLS=\"http:\/\/$v_this_ip:2379\"/g" /etc/etcd/etcd.conf

echo "-- Edited postgresql configuration file. --"