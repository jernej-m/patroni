#-------------- Install postgre, etcd, patroni --------------------
echo "Installing PostgreSQL repo..."
sleep 5
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

echo "Installing postgresql 10 and postgresql10-server..."
sleep 5
yum -y install postgresql10 postgresql10-server

echo "Installing etcd..."
sleep 5
yum -y install etcd

echo "Installing epel, for python36-psycopg2 needed by Patroni..."
sleep 5
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

echo "Installing wget..."
sleep 5
yum -y install wget

echo "Downloading Patroni rpm..."
sleep 5
wget https://github.com/cybertec-postgresql/patroni-packaging/releases/download/1.6.0-1/patroni-1.6.0-1.rhel7.x86_64.rpm

echo "Installing Patroni rpm..."
sleep 5
yum -y install patroni-1.6.0-1.rhel7.x86_64.rpm

# --------- Edit etcd configuration file ------------
read -p "member 1 private ip: " v_ip_1
read -p "member 2 private ip: " v_ip_2
read -p "member 3 private ip: " v_ip_3
read -p "Enter this member number (1,2,3): " v_member_no

echo "Editing etcd configuration file..."
sleep 5

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

# --------- Edit patroni configuration file -----------
echo "Editing patroni configuration file..."
sleep 5
mv /opt/app/patroni/etc/postgresql.yml.sample /opt/app/patroni/etc/postgresql.yml

sed -i "s/^scope:.*/scope: patroni_cluster/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/^name:.*/name: patroni_member_$v_member_no/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/connect_address:.*:8008/connect_address: $v_this_ip:8008/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/host:.*:2379/host: localhost:2379/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/host replicatio.*md5/host replication replicator 0.0.0.0/0 md5/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/connect_address:.*:5432/connect_address: $v_this_ip:5432/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/data_dir:.*/data_dir: /var/lib/pgsql/10/data/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/bin_dir:.*/bin_dir: /usr/pgsql-10/bin/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/password:.*/password: iskratel/g" /opt/app/patroni/etc/postgresql.yml
