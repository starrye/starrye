---
 title: 利用Logstash同步MySQL数据到ES
 date: 2022-08-01T17:05:00+08:00
 lastmod:
 author: 晚风
 cover: "img/mysql-es.png"
 categories:
   - 数据库
 tags:
   - 数据库

---
**利用Logstash同步MySQL数据到ES**

<!--more-->
# 一、数据库配置

## 1、建库建表

```sql
CREATE DATABASE es_test;
USE es_test;
CREATE TABLE es_table (
  id int NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  age INT(12) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unique_id (id),
  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  insertion_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

注意: update_time:在 mysql 中修改记录时，时间会自动更新。有了这个更新时间，Logstash 便可以得到截止到当前时间内mysql中被修改或者增加的任何记录。

## 2、利用faker导入测试数据

```shell
import random
import pymysql
from faker import Faker


MYSQL_CONFIG = {
    'NAME': 'es_test',
    'USER': 'root',
    'PASSWORD': '123456',
    'HOST': '127.0.0.1',
    'PORT': '3306',
},

fake = Faker()
conn = pymysql.connect(host=MYSQL_CONFIG["HOST"], user=MYSQL_CONFIG["USER"],passwd=MYSQL_CONFIG["PASSWORD"],db=MYSQL_CONFIG["NAME"])
cur = conn.cursor()
for i in range(200):
    name = fake.name_female()
    age = random.randint(10, 80)
    sql = "insert into es_table (name, age) values(%s, %s);"
    param = (name, age)
    cur.execute(sql, param)
    conn.commit()
    cur.close()
    conn.close()
```

## 3、修改mysql权限

​	修改my.cnf文件

​		mysql默认权限bind-address:127.0.0.1修改为0.0.0.0

```sql
use mysql;
更新一条允许所有主机访问数据库
UPDATE user SET Host = '%' WHERE User = 'root' LIMIT 1;
强制刷新权限
flush privileges;
```

## 4、下载mysql connector

connector是程序用来连接数据库的驱动，下载地址为https://mvnrepository.com/artifact/mysql/mysql-connector-java/

⚠️：需要和mysql版本一致

# 二、logstash配置

## 1、docker下载logstash

```shell
docker pull logstash:7.5.1

# 宿主机新建logstash目录 
-logstash
	-d config
		- logstash.yml
	-d conf.d
		- xxx.conf

docker run -it -d -p 5044:5044 --name logstash -v /Users/Star/logstash/config/logstash.yml:/usr/share/logstash/config/logstash.yml -v /Users/Star/logstash/conf.d/:/usr/share/logstash/conf.d/ logstash:7.5.1
```

## 2、配置文件

```shell
input {
  jdbc {
  	  # jar包地址放到挂载目录上，然后写docker内地址
      jdbc_driver_library => "/usr/share/logstash/conf.d/mysql-connector-java-8.0.27.jar"
      jdbc_driver_class => "com.mysql.cj.jdbc.Driver"
      
      # 数据库地址
      jdbc_connection_string => "jdbc:mysql://xxxx:3306/es_test"
      jdbc_user => "root"
      jdbc_password => "123456"
      
      # 数据量较大时分页
      jdbc_paging_enabled => true
      
      # 根据数据库表的哪个字段进行跟踪数据变化
      use_column_value => true
      tracking_column => "update_time"
      tracking_column_type => "timestamp"
      
      # 重复执行导入任务的时间间隔  分-时-日-月-星期
      schedule => "*/5 * * * * *"
      
      # clean_run 为 true 表示重启 logstash 重新读取数据库所有内容，false 会从上次读取的内容开始往后读取
      clean_run => true
      
      # 导入的表(查询SQL，可以过滤数据)
      statement => "SELECT *, UNIX_TIMESTAMP(update_time) AS unix_ts_in_secs FROM es_table WHERE (UNIX_TIMESTAMP(update_time) > :sql_last_value AND update_time < NOW()) ORDER BY update_time ASC"
  }
}

filter {
  mutate {
  	# mysql的id 复制到 _id 的元数组
    copy => { "id" => "[@metadata][_id]"}
    # 移除mysql字段
    remove_field => ["id", "@version", "unix_ts_in_secs"]
  }
}
output {
  # stdout { codec =>  "rubydebug"}
  elasticsearch {
      hosts => ["x x x x:9200"]
      index => "sql_sync"
      document_id => "%{[@metadata][_id]}"
  }
}
```

# 三、遇到的问题

1、logstash报错 jdbc_driver_library 无法加载 jar 提示找不到文件

```shell
确定jar包位于Logstash 挂载目录下，logstash文件中的jar包地址为docker内地址
```

2、Unable to connect to database. Tried 1 times {:error_message=>"Java::ComMysqlCjJdbcExceptions::CommunicationsException: Communications link failure\n\nThe last packet sent successfully to the server was 0 milliseconds ago. The driver has not received any packets from the server.

```shell
mysql默认权限bind-address:127.0.0.1修改为0.0.0.0 然后重启mysql
```

3、Unable to connect to database. Tried 1 times {:error_message=>"Java::JavaSql::SQLException: null,  message from server: \"Host '10.246.131.46' is not allowed to connect to this MySQL server\""}

```shell
查看数据库配置中的第三条
```

