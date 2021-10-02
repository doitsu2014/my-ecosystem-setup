ETH0_IP=$(ip address show label eth0 | grep 'inet ' |  awk '{ print $2 }')
echo $ETH0_IP quickstart.doitsu.tech
