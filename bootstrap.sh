vmname=$1
vmindex=${vmname#zhangyue}
zookeeper_home=/usr/local/zookeeper
storm_home=/usr/local/storm
kafka_home=/usr/local/kafka
pid_dir=/tmp/run

function install_pkgs()
{
    sudo apt-get update -qqy
    sudo apt-get install -qqy openjdk-7-jdk
    sudo apt-get install -qqy scala
    if [ ! -d $zookeeper_home ]
    then
        wget -nc -q -P /var/cache/wget http://mirror.nus.edu.sg/apache/zookeeper/stable/zookeeper-3.4.6.tar.gz
        tar xvf /var/cache/wget/zookeeper-3.4.6.tar.gz -C ~ > /dev/null
        sudo mv zookeeper-3.4.6 $zookeeper_home
    fi
    if [ ! -d $storm_home ]
    then
        wget -nc -q -P /var/cache/wget http://mirror.nus.edu.sg/apache/storm/apache-storm-0.9.3/apache-storm-0.9.3.tar.gz
        tar xvf /var/cache/wget/apache-storm-0.9.3.tar.gz -C ~ > /dev/null
        sudo mv apache-storm-0.9.3 $storm_home
    fi
    if [ ! -d $kafka_home ]
    then
        wget -nc -q -P /var/cache/wget http://mirror.nus.edu.sg/apache/kafka/0.8.2.0/kafka_2.9.2-0.8.2.0.tgz
        tar xvf /var/cache/wget/kafka_2.9.2-0.8.2.0.tgz -C ~ > /dev/null
        sudo mv kafka_2.9.2-0.8.2.0 $kafka_home
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
    cat << EOF > conf/zoo.cfg
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
    cat << EOF > conf/storm_env.ini
[environment]
JAVA_HOME:/usr/lib/jvm/java-1.7.0-openjdk-amd64
EOF
    cat << EOF > conf/storm.yaml
storm.zookeeper.servers:
    - "zhangyue0"
    - "zhangyue1"
    - "zhangyue2"

nimbus.host: "zhangyue0"

storm.local.dir: "/home/vagrant/storm"
EOF
}

function write_kafka()
{
    mkdir -p ~/kafka
    cd $kafka_home
    sed -i "s/broker.id=.*/broker.id=$vmindex/g" config/server.properties
    sed -i "s/zookeeper.connect=.*/zookeeper.connect=zhangyue0:2181,zhangyue1:2181,zhangyue2:2181/g" config/server.properties
    sed -i "s/log.dirs=.*/log.dirs=\/home\/vagrant\/kafka/g" config/server.properties
}

function start_storm()
{
    cd $zookeeper_home
    bin/zkServer.sh restart
    cd $storm_home
    mkdir -p $pid_dir/storm
    if [ "$vmname" == "zhangyue0" ]
    then
        if [ -f $pid_dir/storm/nimbus.pid ]
        then
            kill -TERM $(cat $pid_dir/storm/nimbus.pid)
            sleep 2
        fi
        nohup bin/storm nimbus &
        echo $! > $pid_dir/storm/nimbus.pid
    fi
    if [ -f $pid_dir/storm/supervisor.pid ]
    then
        kill -TERM $(cat $pid_dir/storm/supervisor.pid)
        sleep 2
    fi
    nohup bin/storm supervisor &
    echo $! > $pid_dir/storm/supervisor.pid
    if [ -f $pid_dir/storm/ui.pid ]
    then
        kill -TERM $(cat $pid_dir/storm/ui.pid)
        sleep 2
    fi
    nohup bin/storm ui &
    echo $! > $pid_dir/storm/ui.pid
}

function start_kafka()
{
    cd $kafka_home
    if [ -f $pid_dir/kafka/server.pid ]
    then
        kill -TERM $(cat $pid_dir/kafka/server.pid)
        sleep 2
    fi
    mkdir -p $pid_dir/kafka
    nohup bin/kafka-server-start.sh config/server.properties &
    echo $! > $pid_dir/kafka/server.pid
}

install_pkgs
write_hosts
write_zk
write_storm
write_kafka
start_storm
start_kafka
