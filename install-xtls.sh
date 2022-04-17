#!/bin/bash

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install"
    exit 1
fi

# Check os
source /etc/os-release
if [ "$ID" == "debian" ] || [ "$ID" == "ubuntu" ] || [ "$ID" == "centos" ];then
  echo -e "你的系统版本为$ID，可以继续"
else 
  echo -e "${red}未支持该系统版本，请联系脚本作者！${plain}\n" && exit 1
fi
sleep 1

read -p "请输入域名（保证域名已解析到本机） :" DOMIN
echo -e "\n"
echo "域名为:$DOMIN"

UUID=$(cat /proc/sys/kernel/random/uuid)

echo
echo "正在配置中..."
sleep 1

if [ "$ID" == "centos" ] ; then
setenforce 0
iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save && systemctl stop firewalld && systemctl disable firewalld
yum -y install epel-release && yum install wget git nginx certbot -y && rm -rf /html/* && mkdir -p /html && cd /html && git clone https://github.com/xiongbao/we.dog.git && rm -rf /etc/nginx/sites-enabled/default && bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service
chattr -i  /etc/selinux/config && sed -i 's/enforcing/disabled/g' /etc/selinux/config && chattr +i  /etc/selinux/config
systemctl stop nginx && yes | certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
else
iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save && systemctl stop ufw && systemctl disable ufw
apt update && apt install wget git nginx certbot -y && rm -rf /html/* && mkdir -p /html && cd /html && git clone https://github.com/xiongbao/we.dog.git && rm -rf /etc/nginx/sites-enabled/default && bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service && systemctl stop nginx && yes | certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
fi

echo
echo "已配置完成，正在写入config..."
sleep 1
cat > /etc/nginx/conf.d/dog.conf <<EOF
server { 
                listen 127.0.0.1:82;  
                root /html/we.dog; 
 index index.html index.htm index.nginx-debian.html index.php; 
} 
server { 
        return 301 https://$DOMIN; 
                listen 80; 
                server_name $DOMIN; 
}
EOF

sleep 1
cat > /usr/local/etc/xray/config.json <<EOF
{
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-direct",
                        "level": 0
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                               {
                        "dest": 82
                      }
                    ]
                },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/letsencrypt/live/$DOMIN/fullchain.pem",
                            "keyFile": "/etc/letsencrypt/live/$DOMIN/privkey.pem"
                        }
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF

echo
echo "已写入完成，正在启动与设置证书自更"
sleep 2
systemctl daemon-reload && systemctl restart xray && systemctl enable xray && systemctl restart nginx && systemctl enable nginx && touch cronfile && echo '15 2 * */2 * root certbot renew --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx"' > ./cronfile && crontab -u root ./cronfile
sleep 1
wget -N --no-check-certificate -q -O /html/we.dog/$UUID.yaml "https://raw.githubusercontent.com/huahsui/tcp-xtls/gh-pages/clash.yaml" && sed -i '32 i\  - {name: tcp+xtls, server: '$DOMIN', port: 443, type: vless, uuid: '$UUID', flow: xtls-rprx-direct, skip-cert-verify: false,servername: '$DOMIN'}' /html/we.dog/$UUID.yaml
sleep 1

# 开启bbr
if [ "$ID" == "debian" ] || [ "$ID" == "ubuntu" ];then
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo "你的bbr已启用"
else 
echo -e "${red}未支持该系统版本，bbr启动失败，请自行启动！！！${plain}\n" && exit 1
fi

echo
echo "   恭喜，你的tcp+xtls已配置成功，以下为你的clash配置"
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo "- {name: tcp+xtls, server: $DOMIN, port: 443, type: vless, uuid: $UUID, flow: xtls-rprx-direct, skip-cert-verify: false, servername: $DOMIN}"
echo
echo "   clash配置文件在 https://$DOMIN/$UUID.yaml ,请直接在clash客户端中输入该网址食用,clash使用请用meta内核，自行谷歌"
echo
echo "   其他客户端请自行参考clash配置中的数据！"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
# END
