echo "Stopping Patroni and Etcd services..."
sleep 5
systemctl stop patroni
systemctl stop etcd

# --------- Get variables ------------
read -p "member 1 ip: " v_ip_1
read -p "member 2 ip: " v_ip_2
read -p "member 3 ip: " v_ip_3
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

# --------- Edit etcd configuration file -----------
echo "Editing etcd configuration file..."
sleep 5

sed -i "s/#\?ETCD_NAME=\".*\"/ETCD_NAME=\"patroni$v_member_no\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_LISTEN_PEER_URLS=\".*\"/ETCD_LISTEN_PEER_URLS=\"http:\/\/0.0.0.0:2380\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_LISTEN_CLIENT_URLS=\".*\"/ETCD_LISTEN_CLIENT_URLS=\"http:\/\/0.0.0.0:2379\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_ADVERTISE_PEER_URLS=\".*\"/ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http:\/\/$v_this_ip:2380\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_CLUSTER=\".*\"/ETCD_INITIAL_CLUSTER=\"patroni1=http:\/\/$v_ip_1:2380,patroni2=http:\/\/$v_ip_2:2380,patroni3=http:\/\/$v_ip_3:2380\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_CLUSTER_STATE=\".*\"/ETCD_INITIAL_CLUSTER_STATE=\"new\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_INITIAL_CLUSTER_TOKEN=\".*\"/ETCD_INITIAL_CLUSTER_TOKEN=\"itclustertoken\"/g" /etc/etcd/etcd.conf
sed -i "s/#\?ETCD_ADVERTISE_CLIENT_URLS=\".*\"/ETCD_ADVERTISE_CLIENT_URLS=\"http:\/\/$v_this_ip:2379\"/g" /etc/etcd/etcd.conf

# --------- Edit patroni configuration file -----------
# in /usr/lib/systemd/system/patroni.service patroni configuration file is listed as /opt/app/patroni/etc/postgresql.yml
echo "Editing patroni configuration file..."
sleep 5

sed -i "s/^scope:.*/scope: patroni_cluster/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/^name:.*/name: patroni_member_$v_member_no/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/connect_address:.*:8008/connect_address: $v_this_ip:8008/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/host:.*:2379/host: localhost:2379/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/host replication.*md5/host replication replicator 0.0.0.0\/0 md5/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/connect_address:.*:5432/connect_address: $v_this_ip:5432/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/data_dir:.*/data_dir: \/var\/lib\/pgsql\/10\/data/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/bin_dir:.*/bin_dir: \/usr\/pgsql-10\/bin/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/password:.*/password: iskratel/g" /opt/app/patroni/etc/postgresql.yml

# ---------- Start etcd and patroni service ---------------
read -p "Start Etcd service (y/n)? it's recommended that Etcd service is started simultaneously on all instances." CONT
if [ "$CONT" = "y" ]; then
  systemctl start etcd
else
  echo "Etcd service start aborted.";
fi

read -p "Start Patroni service (y/n)? it's recommended that Patroni service is started simultaneously on all instances." CONT
if [ "$CONT" = "y" ]; then
  systemctl start patroni
else
  echo "Patroni service start aborted.";
fi
