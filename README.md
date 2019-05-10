### 本项目的目标：

简化ei的产品化版本Docker镜像的发布工作：

- 修改配置

### 一、目录说明

```
│  build-init-default.sh    使用缺省的H2数据库生成镜像的脚本
│  build-init-oracel.sh     使用外部Oracle数据库生成镜像的脚本
│  readme.md              
│
|-lib                       构建镜像需要依赖的相关包
│      andes-client-3.2.82.jar
│      bcprov-jdk15on-1.56.jar
│      bpmn-sample-jars-6.4.0.jar
│      esapi-2.0.1.jar
│      geronimo-jms_1.1_spec-1.1.0.wso2v1.jar
│      org.wso2.securevault-1.0.0-wso2v2.jar
│      process-tools-6.4.0.jar
│      sample-utils-6.4.0.jar
│      
├─jdbc-drivers               数据库驱动
│      ojdbc6.jar
│      ojdbc7.jar
│      
└─scripts                     自动配置脚本
        ei_auto_config.sh     编码转换等工作
        ei_auto_config_oracle.sh 自动进行主数据库切换到oracle的工作
```

### 二、如何使用

1、在linux服务器上安装JDK、git、docker

2、用git拉取本项目到linux服务器的gds-wso2-docker-ei目录下

```
git clone https://github.com/tongpi/gds-wso2-docker-ei.git
```

3、复制从EI源代码库( https://github.com/tongpi/product-ei.git)构建出来的wso2ei-6.4.0.zip到本项目跟目录(gds-wso2-docker-ei)下

4、修改配置  根据使用场景，修改相应脚本的配置信息以便适应你的环境:

```
打开 build-init-default.sh           # 使用缺省的H2数据库生成镜像的脚本
按照参数说明修改：
PROCUCT_NAME=wso2ei
PROCUCT_VERSION=6.4.0
EI_HOST_NAME=ei.cd.mtn
EI_HOST_PORT=9143
EI_PORTS_OFFSET=0
EI_IMAGE_PROFIX=gds

或
打开build-init-oracel.sh            # 使用外部Oracle数据库生成镜像的脚本
按照参数说明修改：
PROCUCT_NAME=wso2ei
PROCUCT_VERSION=6.4.0
EI_HOST_NAME=ei.cd.mtn
EI_HOST_PORT=9143
EI_PORTS_OFFSET=0
EI_IMAGE_PROFIX=gds

#oracle数据库参数 ei_auto_config_oracle.sh
DB_HOST=192.168.3.49
DB_PORT=1521
DB_SID=kyy
DB_USERNAME=数据库用户名
DB_PASSWORD=数据库密码
DATASOURCE_NAME=WSO2CarbonDB
```

5、根据使用场景，选择执行:

```shell
./build-init-default.sh           # 使用缺省的H2数据库生成镜像的脚本

或

./build-init-oracel.sh            # 使用外部Oracle数据库生成镜像的脚本
```

6、脚本执行完毕，可以看到控制台输出信息如下：

***注：[-oracle]只在执行build-init-oracel.sh才出现***

> 提示  1：
> EI的本地镜像版本已生成 TAG为：gds/wso2ei-oracle:6.4.0
> 你可以执行如下的docker命令来启动EI：
>
> ```
> docker run -it -p 9443:9443 gds/wso2ei-oracle:6.4.0
> docker run -d -p 9443:9443 --name ei.cd.mtn --restart=always gds/wso2ei-oracle:6.4.0
> ```
>
> 提示  2：
> 已生成能够在单独部署的wso2ei版本到/gda-wso2-docker-ei/target/目录下的wso2ei-oracle-6.4.0.zip文件中
> 你可以直接复制该文件来独立安装已按产品化要求配置好的EI运行版
> 提示  3：
> EI服务一旦启动，你可以通过类似下面的地址访问EI的管理控制台：     
>
> ```
> https://ei.cd.mtn:9443/carbon
> ```

### 知识点附件：私有docker仓库  docker register的安装与使用（与本项目无关）

```
docker run -d -p 5000:5000 --name dockerregister --restart=always -v /opt/data/registry:/var/lib/registry registry
touch /opt/config.yml
docker run -d -p 5001:8080 --name registry-web  --restart=always --link dockerregister -v /opt/config.yml:/conf/config.yml:ro hyper/docker-registry-web
```

访问：

```
http://192.168.200.224:5001
```

其中 /opt/config.yml的文件内容如下：

```yml
registry:
  # Docker registry url
  url: http://registry-srv:5000/v2
  # Docker registry fqdn
  name: localhost:5000
  # To allow image delete, should be false
  readonly: false
  auth:
    # Disable authentication
    enabled: false
```

使用：

```
  http://192.168.200.224:5000/v2/_catalog 查看镜像清单
  http://192.168.200.224:5001 管理镜像
```

  命令行：

```shell
#为了验证，读者可以拉取一个busybox镜像（因为体积小），进行实验。
docker pull busybox
#拉取最新的busybox镜像后，再给其打标为v1.0，准备发布到Registry中。
docker tag busybox localhost:5000/bosybox:v1.0 
#发布busybox镜像的v1.0版本到本地docker仓库
docker push localhost:5000/bosybox:v1.0    
#从本地仓库获取bosybox:v1.0镜像
docker pull localhost:5000/bosybox:v1.0         
```

​    实操：

```shell
docker tag gds/wso2ei:6.4.0 localhost:5000/gds/wso2ei:6.4.0
docker push localhost:5000/gds/wso2ei:6.4.0

docker tag gds/wso2ei:6.4.0 localhost:5000/gds/wso2ei:6.4.0
docker push localhost:5000/gds/wso2ei:6.4.0
    
docker tag gds/wso2ei:6.4.0 localhost:5000/gds/wso2ei:latest
docker push localhost:5000/gds/wso2ei
```



