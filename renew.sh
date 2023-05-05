#!/bin/bash

# 停止 Nginx
sudo systemctl stop nginx

# 更新证书
sudo certbot renew

# 重新启动 Nginx
sudo systemctl start nginx
