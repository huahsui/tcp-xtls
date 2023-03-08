#!/bin/bash

echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo "   该脚本用于快速安装vision+reality,仅供测试"
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

echo
echo "正在清除影响因素..."
sleep 1
rm -rf /usr/local/etc/xray && rm -rf /etc/systemd/system/xray* && rm -rf /usr/local/bin/xray
echo "已清理完成！"
sleep 1

UUID=$(cat /proc/sys/kernel/random/uuid)

read -p "请输入本机ip:" Zero
echo -e "\n"
echo "VPS的IP为:$Zero"
echo -e

echo
echo "正在配置中..."
sleep 1

if [ "$ID" == "centos" ] ; then
setenforce 0
iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save
systemctl stop firewalld && systemctl disable firewalld
yum -y install net-tools
kill -9 $(netstat -nlp | grep :443 | awk '{print $7}' | awk -F"/" '{ print $1 }')
kill -9 $(netstat -nlp | grep :80 | awk '{print $7}' | awk -F"/" '{ print $1 }')
yum -y install epel-release && yum install wget git certbot curl -y && rm -rf /etc/nginx/sites-enabled/default
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service
chattr -i  /etc/selinux/config && sed -i 's/enforcing/disabled/g' /etc/selinux/config && chattr +i  /etc/selinux/config
rm -rf /usr/local/bin/xray && wget https://github.com/huahsui/tcp-xtls/raw/gh-pages/xray && mv xray /usr/local/bin/xray && chmod +x /usr/local/bin/xray
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
/usr/local/bin/xray x25519
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
read -p "请输入上面的Private key:" One
echo -e "\n"
echo "privekey is $One"
echo -e
read -p "请输入上面的Public key:" Two
echo -e "\n"
echo "publickey is $Two"
else
iptables -F && iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables-save
systemctl stop ufw && systemctl disable ufw
apt update
apt install net-tools -y
kill -9 $(netstat -nlp | grep :443 | awk '{print $7}' | awk -F"/" '{ print $1 }')
kill -9 $(netstat -nlp | grep :80 | awk '{print $7}' | awk -F"/" '{ print $1 }')
apt install wget git certbot curl -y && rm -rf /etc/nginx/sites-enabled/default
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && sed -i 's/nobody/root/g' /etc/systemd/system/xray.service
rm -rf /usr/local/bin/xray && wget https://github.com/huahsui/tcp-xtls/raw/gh-pages/xray && mv xray /usr/local/bin/xray && chmod +x /usr/local/bin/xray
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
/usr/local/bin/xray x25519
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
read -p "请输入上面的Private key:" One
echo -e "\n"
echo "privekey is $One"
echo -e
read -p "请输入上面的Public key:" Two
echo -e "\n"
echo "publickey is $Two"
fi

sleep 1

echo
echo "已配置完成，正在写入config..."
sleep 1

cat > /usr/local/etc/xray/config.json <<EOF
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:cn"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
                },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                  "show":false,
                  "dest":"learn.microsoft.com:443",
                  "serverNames":["learn.microsoft.com"],
                  "privateKey":"$One",
                  "shortIds":["12345678","12a34b56c78d1a2b"]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }            
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF

echo
echo "已写入完成"
sleep 2
systemctl daemon-reload && systemctl restart xray && systemctl enable xray
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

cat > /root/client.json <<EOF
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "domain": [
                    "geosite:cn",
                    "geosite:private"
                ],
                "outboundTag": "direct"
            },
            {
                "type": "field",
                "ip": [
                    "geoip:cn",
                    "geoip:private"
                ],
                "outboundTag": "direct"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "127.0.0.1",
            "port": 10808,
            "protocol": "socks",
            "settings": {
                "udp": true
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {
            "listen": "127.0.0.1",
            "port": 10809,
            "protocol": "http",
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "vless",
            "settings": {
                "vnext": [
                    {
                        "address": "$Zero",
                        "port": 443,
                        "users": [
                            {
                                "id": "$UUID",
                                "encryption": "none",
                                "flow": "xtls-rprx-vision"
                            }
                        ]
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                  "show": false,
                  "serverName": "learn.microsoft.com",
                  "fingerprint": "chrome", 
                  "publicKey":"$Two", 
                  "shortId":"12a34b56c78d1a2b", 
                  "spiderX":"/"
                }
            },
            "tag": "proxy"
        },
        {
            "protocol": "freedom",
            "tag": "direct"
        }
    ]
}
EOF
sleep 1

cat > /root/singbox.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "cloudflare",
        "address": "https://1.1.1.1/dns-query"
      },
      {
        "tag": "dnspod",
        "address": "https://1.12.12.12/dns-query",
        "detour": "direct"
      },
      {
        "tag": "block",
        "address": "rcode://success"
      }
    ],
    "rules": [
      {
        "geosite": "cn",
        "server": "dnspod"
      },
      {
        "geosite": "category-ads-all",
        "server": "block",
        "disable_cache": true
      }
    ]
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "inet4_address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": true,
      "stack": "gvisor",
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "vless-out",
      "server": "$Zero",
      "server_port": 443,
      "uuid": "$UUID",
      "flow": "xtls-rprx-vision",
      "network": "tcp",
      "tls": {
        "enabled": true,
        "server_name": "learn.microsoft.com",
        "utls": {
      	  "enabled": true,
      	  "fingerprint": "safari"
         },
        "reality": {
      	  "enabled": true,
      	  "public_key": "$Two",
      	  "short_id": "12a34b56c78d1a2b"
        }
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns"
      },
      {
        "geosite": "cn",
        "geoip": [
          "cn",
          "private"
        ],
        "outbound": "direct"
      },
      {
        "geosite": "category-ads-all",
        "outbound": "block"
      }
    ]
  }
}
EOF

echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo -e "\033[36m\033[1m                                            恭喜，你的vision+reality已配置成功                                         \033[0m"
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo "   客户端配置文件在 /root/client.json 请直接下载，也可通过 cat /root/client.json  复制配置 "
echo
echo "   电脑端可使用v2rayN,见以下说明                                   "
echo -e "\033[31m\033[1m                                            v2rayN使用新版内核和自定义配置                                             \033[0m"
echo "   https://github.com/2dust/v2rayN/releases/download/5.39/v2rayN.zip"
echo "   https://github.com/huahsui/tcp-xtls/blob/gh-pages/Xray-windows-64.zip"
echo "   1、先下载以上内核和v2rayN,然后解压v2rayN,并把Xray-windows-64压缩包里的文件复制进v2rayN文件夹。"
echo "   2、打开v2rayN.exe,左上角依次选择 服务器 ——> 添加自定义配置服务器 ——> 浏览（打开客户端配置文件) ——> core类型（选xray） ——> 确定"
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo "   SFI配置文件在 /root/singbox.json IOS端可通过SFI使用，请直接下载并导入SFI， "
echo "   关于sfi的安装可看这里：https://sing-box.sagernet.org/zh/installation/clients/sfi/"
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"
echo
echo -e "\033[35m   以下为clash meta配置，可在openwrt等客户端使用"
echo "- {name: Reality, server: $Zero, port: 443, type: vless, uuid: $UUID, network: tcp, tls: true, flow: xtls-rprx-vision, client-fingerprint: chrome, reality-opts: {server-name: learn.microsoft.com, public-key: $Two, short-id: 12a34b56c78d1a2b}}
echo
echo "----------------------------------------------------------------------------------------------------------------------------------------------"

# END
