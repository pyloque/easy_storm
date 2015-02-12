vmname=$1
vmindex=${vmname#zhangyue}
zookeeper_home=/usr/local/zookeeper
storm_home=/usr/local/storm

function install_pkgs()
{
    #sudo apt-get update -qqy
    sudo apt-get install -qqy openjdk-7-jdk
    if [ ! -d /usr/local/zookeeper ]
    then
        wget -nc -q -P /var/cache/wget http://mirror.nus.edu.sg/apache/zookeeper/stable/zookeeper-3.4.6.tar.gz
        tar xvf /var/cache/wget/zookeeper-3.4.6.tar.gz -C ~ > /dev/null
        sudo mv zookeeper-3.4.6 $zookeeper_home
    fi
    if [ ! -d /usr/local/storm ]
    then
        wget -nc -q -P /var/cache/wget http://mirror.nus.edu.sg/apache/storm/apache-storm-0.9.3/apache-storm-0.9.3.tar.gz
        tar xvf /var/cache/wget/apache-storm-0.9.3.tar.gz -C ~ > /dev/null
        sudo mv apache-storm-0.9.3 $storm_home
    fi
}

function write_hosts()
{
    touch /tmp/hosts
    if ! grep "master" /etc/hosts > /dev/null
    then
    cat /etc/hosts > /tmp/hosts
    sed -i '/zhangyue/d' /tmp/hosts
    cat << EOF >> /tmp/hosts
172.28.2.10 master zhangyue0
172.28.2.11 slave1 zhangyue1
172.28.2.12 slave2 zhangyue2
EOF
    sudo cp /tmp/hosts /etc/hosts
    fi
}

function write_zk()
{
    mkdir -p ~/zkdata
    echo $vmindex > ~/zkdata/myid
    cd $zookeeper_home
    sudo cat << EOF > conf/zoo.cfg
tickTime=2000
dataDir=/home/vagrant/zkdata
clientPort=2181
initLimit=5
syncLimit=2
server.0=zhangyue0:2888:3888
server.1=zhangyue1:2888:3888
server.2=zhangyue2:2888:3888
EOF
}

function write_storm()
{
    mkdir -p ~/storm
    cd $storm_home
    sudo cat << EOF > conf/storm_env.ini
[environment]
JAVA_HOME:/usr/lib/jvm/java-1.7.0-openjdk-amd64
EOF
    sudo cat << EOF > conf/storm.yaml
storm.zookeeper.servers:
    - "zhangyue0"
    - "zhangyue1"
    - "zhangyue2"

nimbus.host: "zhangyue0"

storm.local.dir: "/home/vagrant/storm"
EOF
}

function start_service()
{
    cd $zookeeper_home
    bin/zkServer.sh restart
    cd $storm_home
    if [ "$vmname" == "zhangyue0" ]
    then
        nohup bin/storm nimbus &
    fi
    nohup bin/storm supervisor &
    nohup bin/storm ui &
}

install_pkgs
write_hosts
write_zk
write_storm
start_service
