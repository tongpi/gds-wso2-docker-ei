#! /bin/bash

#=====================================================================================================
#
#修改以下环境变量适合你的环境,其中：
#
#    PROCUCT_NAME                          EI业务融合服务器的产品名称。用来生成镜像名称和可独立部署的安装包的文件名
#    PROCUCT_VERSION                       EI业务融合服务器的版本。用来生成镜像版本和可独立部署的安装包的文件名
#    EI_HOST_PORT                          EI业务融合服务器的机器的主服务端口  用来生成提示信息
#    EI_PORTS_OFFSET                       EI业务融合服务器的机器的端口偏移量，默认是0，控制台默认端口是9443，若偏移量设为1 ，则控制台端口是“默认端口+偏移量”，也就是9444. EI的其它端口也会一起偏移 
#
#======================================================================================================
PROCUCT_NAME=wso2ei
PROCUCT_VERSION=6.4.0
EI_HOST_NAME=${EI_HOST_NAME:-ei.cd.mtn}
EI_HOST_PORT=${EI_HOST_PORT:-9143}
EI_PORTS_OFFSET=${EI_PORTS_OFFSET:-0}
EI_IMAGE_PROFIX=${EI_IMAGE_PROFIX:-gds}
CARBON_UI_CUSTOM_EI_BRANCH=${CARBON_UI_CUSTOM_EI_BRANCH:-master}
#======================================================================================================
CUR_DIR=$PWD
if [ ! -d "$PWD/docker-ei" ]; then
  git clone -b gdsmaster https://github.com/tongpi/docker-ei.git
fi

EI_HOME=$PWD/docker-ei/dockerfiles/ubuntu/integrator/files/$PROCUCT_NAME-$PROCUCT_VERSION
if [ -d $EI_HOME ]; then
  rm -Rf $EI_HOME
fi

PROCUCT_RELEASE_ZIP_FILE=$PROCUCT_NAME-$PROCUCT_VERSION.zip
if [ ! -f "$PROCUCT_RELEASE_ZIP_FILE" ]; then
# wget  $PROCUCT_RELEASE_ZIP_FILE
  echo "================================================================================================="  
  echo "用法："
  echo "请首先复制从ES源码库( https://github.com/tongpi/product-ei.git )构建出来的$PROCUCT_RELEASE_ZIP_FILE到$0所在目录下"
  echo "================================================================================================="  
  exit 1
fi

if [ ! type unzip > /dev/null 2>&1 ]; then
  echo "正在安装zip软件包"
  sodo apt-get install -y zip > /dev/null
fi
unzip $PROCUCT_RELEASE_ZIP_FILE -d $PWD/docker-ei/dockerfiles/ubuntu/integrator/files > /dev/null 2>&1
echo '已解压缩$PROCUCT_RELEASE_ZIP_FILE到$PWD/docker-ei/dockerfiles/ubuntu/integrator/files目录下'
cp -r ./lib $PWD/docker-ei/dockerfiles/ubuntu/integrator/files
echo "已复制ei 的相关的包到$PWD/docker-ei/dockerfiles/ubuntu/integrator/files目录下"

# 这一步是给docker build准备的
cp ./jdbc-drivers/*.jar $PWD/docker-ei/dockerfiles/ubuntu/integrator/files
#这一步仅仅为了单独部署而准备，对build docker image来说不是必需的
cp ./jdbc-drivers/*.jar $EI_HOME/lib
echo "已复制数据库jdbc驱动到$PWD/docker-ei/dockerfiles/ubuntu/integrator/files目录下"
#======================================================================================================
echo "开始进行EI管理控制台个性化定制组件的安装工作"
if [ ! -d "$PWD/carbon-ui-custom-ei" ]; then
  git clone -b $CARBON_UI_CUSTOM_EI_BRANCH https://github.com/tongpi/carbon-ui-custom-ei.git
else 
  rm -Rf $PWD/carbon-ui-custom-ei
  git clone -b $CARBON_UI_CUSTOM_EI_BRANCH https://github.com/tongpi/carbon-ui-custom-ei.git
fi
cd carbon-ui-custom-ei
mvn clean install > /dev/null
cp modules/org.wso2.carbon.ui_fragment/target/org.wso2.carbon.ui_4.4.36_fragment-1.0.0.jar ../docker-ei/dockerfiles/ubuntu/integrator/files/$PROCUCT_NAME-$PROCUCT_VERSION/dropins/
cp modules/org.wso2.carbon.ui_patch/target/org.wso2.carbon.ui_4.4.36_patch-1.0.0.jar ../docker-ei/dockerfiles/ubuntu/integrator/files/$PROCUCT_NAME-$PROCUCT_VERSION/dropins/
cd $CUR_DIR

#======================================================================================================
chmod +x ./scripts/*.sh
# 自动配置及文件编码转换工作
./scripts/ei_auto_config.sh $EI_HOME $EI_PORTS_OFFSET
# 自动配置数据库文件
./scripts/ei_auto_config_oracle.sh $EI_HOME 

#======================================================================================================
cd $PWD/docker-ei/dockerfiles/ubuntu/integrator
echo "开始构建之前先删除旧的本地EI镜像"
echo "sudo docker rmi $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION"
sudo docker rmi $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION

echo "开始构建新的EI的docker镜像......"
echo "--------------------------------------------------------------------------------------------------"
echo "docker build -t $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION ."
sudo docker build -t $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION .

cd $CUR_DIR
# 生成可单独部署的wos2ei产品包到$PWD/target/目录下
if [ ! -d "$PWD/target" ]; then
  mkdir target
fi
# 生成用于在系统单独部署的zip包
cd $PWD/docker-ei/dockerfiles/ubuntu/integrator/files
echo "导出EI单独部署的zip包到$PWD/target目录下"
zip -r $CUR_DIR/target/$PROCUCT_NAME-$PROCUCT_VERSION-oracle.zip ./$PROCUCT_NAME-$PROCUCT_VERSION > /dev/null

cd $CUR_DIR
#导出镜像文件以便迁移到其它docker环境中
echo "导出EI镜像到$PWD/target目录下"
sudo docker save -o $PWD/target/$PROCUCT_NAME:$PROCUCT_VERSION-oracle.tar $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION

echo "========================================================================================================================="
echo "提示  1："
echo "EI的本地镜像版本已生成 TAG为：$EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION"
echo "你可以复制$PWD/target/$PROCUCT_NAME-$PROCUCT_VERSION-oracle.tar文件到光盘以便迁移到其它docker环境中"
echo "你也可以直接在本机执行如下的docker命令来启动EI："
echo "     docker run -it -p $EI_HOST_PORT:9443 $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION"
echo "     docker run -d -p $EI_HOST_PORT:9443 --name YOUR_EI_CONTAINER_NAME --restart=always $EI_IMAGE_PROFIX/$PROCUCT_NAME-oracle:$PROCUCT_VERSION"
echo "提示  2："
echo "已生成能够在单独部署的wso2ei版本到$PWD/target/目录下的$PROCUCT_NAME-$PROCUCT_VERSION-oracle.zip文件中"
echo "你可以直接复制该文件来独立安装已按产品化要求配置好的EI运行版"
echo "提示  3："
echo "EI服务启动完成后，你可以通过类似下面的地址访问EI的管理控制台："
echo "     https://$EI_HOST_NAME:$EI_HOST_PORT/carbon"
