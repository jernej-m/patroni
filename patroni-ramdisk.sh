echo "Updating yum repositories..."
sleep 5
yum -y update

#-------------- Install postgre, etcd, patroni --------------------
echo "Installing PostgreSQL repo..."
sleep 5
yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

echo "Installing postgresql 10 and postgresql10 libraries..."
sleep 5
yum -y install postgresql10 postgresql10-server postgresql10-contrib postgresql10-devel

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

# --------- Get variables ------------
read -p "this ip: " v_this_ip
read -p "etcd ip:" v_etcd_ip
read -p "Enter this member number (1,2,3): " v_member_no

# --------- Edit patroni configuration file -----------
# in /usr/lib/systemd/system/patroni.service patroni configuration file is listed as /opt/app/patroni/etc/postgresql.yml
echo "Editing patroni configuration file..."
sleep 5
mv /opt/app/patroni/etc/postgresql.yml.sample /opt/app/patroni/etc/postgresql.yml

sed -i "s/^scope:.*/scope: patroni_cluster/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/^name:.*/name: patroni_member_$v_member_no/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/connect_address:.*:8008/connect_address: $v_this_ip:8008/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/host:.*:2379/host: $v_etcd_ip:2379/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/host replication.*md5/host replication replicator 0.0.0.0\/0 md5/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/connect_address:.*:5432/connect_address: $v_this_ip:5432/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/data_dir:.*/data_dir: \/var\/lib\/pgsql\/10\/data/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/bin_dir:.*/bin_dir: \/usr\/pgsql-10\/bin/g" /opt/app/patroni/etc/postgresql.yml
sed -i "s/password:.*/password: iskratel/g" /opt/app/patroni/etc/postgresql.yml

# ---------- Start etcd and patroni service ---------------
echo "Enabling patroni on start..."
sleep 2
systemctl enable patroni

read -p "Start Patroni service (y/n)? it's recommended that Patroni service is started simultaneously on all instances." CONT
if [ "$CONT" = "y" ]; then
  systemctl start patroni
else
  echo "Patroni service start aborted.";
fi
