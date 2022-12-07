#!/bin/bash

echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo "   该脚本用于快速安装nginx+ws+vless,仅供测试"
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
sleep 2

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
iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save 
systemctl stop firewalld && systemctl disable firewalld
yum -y install epel-release && yum install wget git nginx certbot curl -y && rm -rf /html/* && mkdir -p /html && cd /html && git clone https://github.com/xiongbao/we.dog.git && rm -rf /etc/nginx/sites-enabled/default
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service
chattr -i  /etc/selinux/config && sed -i 's/enforcing/disabled/g' /etc/selinux/config && chattr +i  /etc/selinux/config
systemctl stop nginx && yes | certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
else
iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save
systemctl stop ufw && systemctl disable ufw
apt update
apt install wget git nginx certbot curl -y && rm -rf /html/* && mkdir -p /html && cd /html && git clone https://github.com/xiongbao/we.dog.git && rm -rf /etc/nginx/sites-enabled/default
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service
systemctl stop nginx && yes | certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
myFile="/etc/letsencrypt/live/$DOMIN/fullchain.pem"
if [ ! -f "$myFile" ]; then
echo "你的证书申请失败，如果域名刚解析到本机，请等几分钟后继续申请，若为控制面板80、443端口未开，请开启后继续！！！"
PS3='请在以上操作完成后继续，或直接退出本脚本: '
foods=("继续" "退出")
select fav in "${foods[@]}"; do
    case $fav in
        "继续")
            yes | certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
            if [ ! -f "$myFile" ]; then
            echo "你的证书申请失败，请完成以上操作后重新运行本脚本！！！" && exit 1
            fi
	    # optionally call a function or run some code here
	    break
            ;;
	    "退出")
	        echo "退出中，感谢使用本脚本"
	    exit 2
	    ;;
        *) echo "invalid option $REPLY";;
    esac
done
fi

echo
echo "已配置完成，正在写入config..."
sleep 1
cat > /etc/nginx/conf.d/dog.conf <<EOF
server { 
                listen 443 ssl;  
                root /html/we.dog; 
 index index.html index.htm index.nginx-debian.html index.php; 
    ssl_certificate       /etc/letsencrypt/live/$DOMIN/fullchain.pem;
    ssl_certificate_key   /etc/letsencrypt/live/$DOMIN/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;
  
    ssl_protocols         TLSv1.2 TLSv1.3;
    ssl_ciphers           ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
 	  location /ray {
                    proxy_pass                  http://127.0.0.1:24600; 
                    proxy_redirect              off;
                    proxy_http_version          1.1;
                    proxy_set_header Upgrade    \$http_upgrade;
                    proxy_set_header Connection "upgrade";
                    proxy_set_header Host       \$http_host;
           }
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
            "port": 24600,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "alterId": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/ray"
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
wget -N --no-check-certificate -q -O /html/we.dog/$UUID.yaml "https://raw.githubusercontent.com/huahsui/tcp-xtls/gh-pages/clash.yaml" && sed -i '32 i\  - {name: tcp+xtls, server: '$DOMIN', port: 443, type: vless, uuid: '$UUID', udp: true, tls: true, network: ws, skip-cert-verify: false, servername: '$DOMIN', ws-opts: {path: /ray, headers: {Host: '$DOMIN'}}}' /html/we.dog/$UUID.yaml
sleep 1
clear

# 开启bbr
if [ "$ID" == "debian" ] || [ "$ID" == "ubuntu" ];then
sed -i '/net\.core\.default_qdisc=fq/d' /etc/sysctl.conf
sed -i '/net\.ipv4\.tcp_congestion_control=bbr/d' /etc/sysctl.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo "   你的bbr已启用"
else 
echo -e "${red}未支持该系统版本，bbr启动失败，请自行启动！！！${plain}\n"
fi
sleep 2

echo
echo "   恭喜，你的ws+tls已配置成功，以下为你的clash配置"
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo "- {name: ws+tls, server: $DOMIN, port: 443, type: vless, uuid: $UUID, udp: true, tls: true, network: ws, skip-cert-verify: false, servername: $DOMIN, ws-opts: {path: /ray, headers: {Host: $DOMIN}}}"
echo "   clash配置文件在 https://$DOMIN/$UUID.yaml ,请直接在clash客户端中输入该网址食用,clash使用请用meta内核，自行谷歌"
echo
echo "   vless://$UUID@$DOMIN:443?encryption=none&security=tls&sni=$DOMIN&type=ws&host=$DOMIN&path=%2Fray#dog"
echo "   直接导入v2rayN使用"
echo
echo "   其他客户端请自行参考clash配置中的数据！"
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
# END
