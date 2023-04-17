---
title: clickhouse同步mysql数据
date: 2022-07-13T14:25:00+08:00
lastmod:
author: 晚风
cover: "img/mysql-ck.png"
categories:
  - 数据库
tags:
  - 数据库

---

***ClickHouse利用MaterializeMySQL引擎实现从MySQL全量及增量实时数据同步,MaterializeMySQL将MySQL的Binlog Event转化为底层Block结构，然后写入底层存储引擎，接近于物理复制***

<!--more-->
## 1、Mysql配置

### 1.1 开启binlog

找到服务器上的mysql配置文件，一般为/etc/my.cnf 或 /etc/my.ini

```
# 复制使用gtid模式
gtid_mode=ON
enforce_gtid_consistency=1
# binlog日志格式
binlog_format=ROW
server-id=1
```

### 1.2 确认配置

#### 查看配置是否开启

```mysql
mysql> show variables like '%log_bin%';
+---------------------------------+-----------------------------+
| Variable_name                   | Value                       |
+---------------------------------+-----------------------------+
| log_bin                         | ON                          |
| log_bin_basename                | /data/mysql/mysql-bin       |
| log_bin_index                   | /data/mysql/mysql-bin.index |
| log_bin_trust_function_creators | OFF                         |
| log_bin_use_v1_row_events       | OFF                         |
| sql_log_bin                     | ON                          |
+---------------------------------+-----------------------------+
6 rows in set (0.00 sec)
```

#### 查看binlog文件列表

当binlog日志写满(binlog大小max_binlog_size，默认1G),或者数据库重启才会生产新文件，但是也可通过手工进行切换让其重新生成新的文件（flush logs）

```mysql
mysql> show binary logs;
+------------------+-----------+
| Log_name         | File_size |
+------------------+-----------+
| mysql-bin.000001 |       351 |
| mysql-bin.000002 |      1169 |
| mysql-bin.000003 |       177 |
| mysql-bin.000004 |       177 |
| mysql-bin.000005 |       177 |
| mysql-bin.000006 |       177 |
| mysql-bin.000007 |  56078526 |
| mysql-bin.000008 |    213388 |
| mysql-bin.000009 |       201 |
| mysql-bin.000010 |       201 |
| mysql-bin.000011 |  28271347 |
+------------------+-----------+
11 rows in set (0.00 sec)
```



#### 查看日志状态

显示当前正在写入的文件及position

```mysql
mysql> show master status;
+------------------+----------+--------------+------------------+----------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                            |
+------------------+----------+--------------+------------------+----------------------------------------------+
| mysql-bin.000011 | 28271347 |              |                  | 3d385890-667b-11e9-84ae-06991b5d85ac:1-30320 |
+------------------+----------+--------------+------------------+----------------------------------------------+
1 row in set (0.00 sec)

```

#### 刷新日志

产生一个新的binlog文件，每当mysqld服务重启时，会自动执行此命令，刷新binlog日志；

```mysql
flush logs;
```

## 2、Clickhouse配置

### 2.1 Clickhouse安装

```shell
# 首先，添加官方存储库：
yum install yum-utils
rpm --import https://repo.clickhouse.tech/CLICKHOUSE-KEY.GPG
yum-config-manager --add-repo https://repo.clickhouse.tech/rpm/stable/x86_64
# 如果您想使用最新版本，请将stable替换为testing（建议您在测试环境中使用）。

# 然后运行这些命令以实际安装包：
yum install clickhouse-server clickhouse-client

# Clickhouse配置文件位于/etc/clickhouse-server/ 下 config.xml为Clickhosue配置，user.xml为Clickhouse用户管理
```

### 2.2 启动Clickhouse

```shell
systemctl start clickhouse-server 	# 启动
systemctl stop clickhouse-server	# 停止
systemctl status clickhouse-server	# 查看状态
or
service clickhouse-server start
```



### 2.3 进入Clickhouse

```shell
clickhouse-client	# 默认情况使用default用户 无密码 可通过user.xml配置default用户

clickhouse-client --host=xxxx.com -u root --password xxxx
```

### 2.4 Clickhouse配置

```mysql
-- 该参数默认关闭，若需要使用MaterializeMySQL引擎，必须打开该参数
star :) set allow_experimental_database_materialized_mysql=1; 


# dbname: 本地库名 mysql_ip: 要同步的mysql地址 mysql_port: mysql的端口，一般为3306
# mysql_dbname: 要同步的库名 mysql_user：mysql用户  mysql_password:mysql密码
CREATE DATABASE ${dbname} ENGINE = MaterializeMySQL('${mysql_ip}:${mysql_port}', '${mysql_dbname}', '${mysql_user}', '${mysql_passoword}');

# 查看数据是否同步
use ${dbname};
select * from ${tablename};
```

### 2.5 可能遇到的问题

```markdown
# the MaterializedMySQL engine requires default_authentication_plugin='mysql_native_password'
修改mysql配置文件my.cnf 增加一行 default_authentication_plugin=mysql_native_password 然后重启mysql
进入mysql验证是否设置成功 show variables like '%default_authentication_plugin%';

# Code: 1002. DB::Exception: The replication sender thread cannot start in AUTO_POSITION mode: this server has GTID_MODE = OFF instead of ON
1.确保MySQL版本在5.6 以上
2.在MySQL5.7版本支持热部署，即不停止服务的情况下开启GTID模式
    SET GLOBAL ENFORCE_GTID_CONSISTENCY = 'WARN';
    SET GLOBAL ENFORCE_GTID_CONSISTENCY = 'ON';
    SET GLOBAL GTID_MODE = 'OFF_PERMISSIVE';
    SET GLOBAL GTID_MODE = 'ON_PERMISSIVE';
    SET GLOBAL GTID_MODE = 'ON';
查看验证：
    show variables like 'gtid_mode';
    show variables like 'ENFORCE_GTID_CONSISTENCY';
    
```

