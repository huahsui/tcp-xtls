## 搭建tcp+xtls
4串代码搭完xray的tcp+xtls
#### 另配置了一键代码，有需自取
```markdown
wget -N --no-check-certificate -q -O xtls.sh "https://raw.githubusercontent.com/huahsui/tcp-xtls/gh-pages/install-xtls.sh" && chmod +x xtls.sh && bash xtls.sh
```
### 特别提醒，第1串要根据自己的系统选择自己的代码框！！！


### 第1串  
（复制整个代码框先到文本，把你的域名改成你的域名，再丢进vps里，让代码跑一会儿，直到出现Yes or No,输入Y，ENTER！）
#### Debian/Ubuntu
```markdown
DOMIN="你的域名" && UUID=$(cat /proc/sys/kernel/random/uuid) && iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save && systemctl stop ufw && systemctl disable ufw && apt update && apt install wget git nginx certbot -y && rm -rf /html/* && mkdir -p /html && cd /html && git clone https://github.com/xiongbao/we.dog.git && rm -rf /etc/nginx/sites-enabled/default && bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service && systemctl stop nginx && certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
```
#### Centos
```markdown
DOMIN="你的域名" && UUID=$(cat /proc/sys/kernel/random/uuid) && setenforce 0 && iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save && systemctl stop firewalld && systemctl disable firewalld && yum -y install epel-release && yum install wget git nginx certbot -y && rm -rf /html/* && mkdir -p /html && cd /html && git clone https://github.com/xiongbao/we.dog.git && rm -rf /etc/nginx/sites-enabled/default && bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service && chattr -i  /etc/selinux/config && sed -i 's/enforcing/disabled/g' /etc/selinux/config && chattr +i  /etc/selinux/config && systemctl stop nginx && certbot certonly --standalone -d $DOMIN --agree-tos --email ppcert@gmail.com
```
### 第2串  
后面无脑丢去vps跑！
```markdown
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
```
### 第3串  
```markdown
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
```
### 第4串  
```markdown
systemctl daemon-reload && systemctl restart xray && systemctl enable xray && systemctl restart nginx && systemctl enable nginx && touch cronfile && echo '15 2 * */2 * root certbot renew --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx"' > ./cronfile && crontab -u root ./cronfile
```

### 结语
划到这里，你就已经搭完了，看你的域名应该已经出现很有意思的网页了，潜水去了🏊‍

配置? -o-  贴个clash的配置吧，下面代码丢进去就真的结束了
```markdown
echo " - {name: tcp+xtls, server: $DOMIN, port: 443, type: vless, uuid: $UUID, flow: xtls-rprx-direct, skip-cert-verify: false,servername: $DOMIN}"
```
