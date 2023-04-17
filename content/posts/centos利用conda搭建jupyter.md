---
title: centos利用conda搭建jupyter
date: 2022-03-24T15:32:24+08:00
lastmod:
author: 晚风
cover: "img/jupyter.png"
categories:
  - 服务搭建
tags:
  - 服务搭建

---
centos利用conda搭建jupyter

<!--more-->
### 1、官网下载conda安装包 

- https://www.anaconda.com/distribution/


### 2、上传云服务器(腾讯云直接scp)

### 3、sh Anaconda3-xxxx-Linux-x86_64.sh

### 4、重新加载环境变量

```shell
# 如果profile没有export PATH=/usr/anaconda3/bin:$PATH则添加

source /etc/profile
```

### 5、conda --version或conda -V 查看是否安装成功

### 6、conda安装jupyter-nootbook

```shell
conda install jupyter notebook
```

### 7、生成配置文件

```shell
jupyter notebook --generate-config # 建立配置文件
```

### 8、修改配置

```shell
# 上一步生成的配置文件一般在 /root/.jupyter/jupyter_notebook_config.py
vim jupyter_notebook_config.py

注意去掉前面的#
c.NotebookApp.port = 20001 # 自定义端口
c.NotebookApp.ip = '你的服务器公网IP' #或填”*”允许ip访问
c.NotebookApp.open_browser = False
修改Jupyter文件默认存储路径
c.NotebookApp.notebook_dir = '/data/'
```

### 9、为jupyter生成密码

```shell
jupyter notebook password
```

### 10、修改云服务器安全策略

​	创建安全组/防火墙规则

​	自定义规则-开放你自定义的jupyter端口 网段应是你出口网段

### 11、测试jupyter运行

```shell
jupyter notebook --allow-root --ip=0.0.0.0
# 然后 服务器ip:port 访问 密码登陆查看是否成功
```

### 12、jupyter启动脚本并增加权限

```shell
#!/bin/bash
jupyter notebook --allow-root --ip=0.0.0.0
```

​	chmod +x run-jupyter-notebook.sh

### 12、下载supervisor并配置jupyter启动程序

```shell
yum install -y supervisor
pip3 install supervisor

vim /etc/supervisord.d/run-jupyter-notebook.ini

[program:jupyter-notebook]
directory= directory-path # 这个是你配置的 c.NotebookApp.notebook_dir 路径
command=/bin/bash -E -c shell-path/run-jupyter-notebook.sh # 上一步配置的启动脚本路径
autostart=true
autorestart=true
stopsignal=INT
stopasgroup=true
killasgroup=true
user=root
```

### 13、启动supervisor并测试

```
>> supervisord
>> supervisorctl status

访问查看是否正常
```

### 14、利用nginx代理jupyter服务

```shell
server {
       listen      443 ssl ;
        server_name jupyter.starrye.com;
       index index.html index.htm index.jsp ;

       access_log  off;

       ssl_certificate      /etc/nginx/cert/jupyter.starrye.com.pem; # 证书地址
       ssl_certificate_key /etc/nginx/cert/jupyter.starrye.com.key; # 证书地址
       ssl_session_timeout  5m ;
       ssl_protocols  TLSv1 TLSv1.1 TLSv1.2 ;
       ssl_ciphers  HIGH:!RC4:!MD5:!aNULL:!eNULL:!NULL:!DH:!EDH:!EXP:+MEDIUM ;
       ssl_prefer_server_ciphers   on ;
       add_header Content-Security-Policy upgrade-insecure-requests;

        location / {
            proxy_pass http://127.0.0.1:20001;
            access_log off;
	    proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            client_max_body_size 100m;
            proxy_connect_timeout 500s;
            proxy_read_timeout 500s;
            proxy_send_timeout 500s;
            proxy_redirect off;
        }
	location ~ /api/kernels/ {
            proxy_pass            http://127.0.0.1:20001;
            proxy_set_header      Host $host;
            # websocket support
            proxy_http_version    1.1;
            proxy_set_header      Upgrade "websocket";
            proxy_set_header      Connection "Upgrade";
            proxy_read_timeout    86400;
        }
        location ~ /terminals/ {
            proxy_pass            http://127.0.0.1:20001;
            proxy_set_header      Host $host;
            # websocket support
            proxy_http_version    1.1;
            proxy_set_header      Upgrade "websocket";
            proxy_set_header      Connection "Upgrade";
            proxy_read_timeout    86400;
        }
}
```

