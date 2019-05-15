#! /bin/bash
#=====================================================================================================
#
#修改以下环境变量适合你的环境,其中：
#
#    EI_HOME                               EI业务融合服务器产品目录
#    DB_HOST                               EI身份管理服务器的主数据库Oracle的主机地址，如：192.168.3.49  
#    DB_PORT                               EI身份管理服务器的主数据库Oracle的端口，如：1521
#    DB_SID                                EI身份管理服务器的主数据库Oracle的SID，如：kyy
#    DB_USERNAME                           EI身份管理服务器的主数据库Oracle的用户名
#    DB_PASSWORD                           EI身份管理服务器的主数据库Oracle的密码
#    DATASOURCE_NAME                       EI身份管理服务器的主数据库库名称
#
#======================================================================================================
EI_HOME=$1
#======================================================================================================
#oracle数据库参数
DB_HOST=$2
DB_PORT=$3
DB_SID=$4
DB_USERNAME=$5
DB_PASSWORD=$6
DATASOURCE_NAME=$7
DB_URL=jdbc:oracle:thin:@$DB_HOST:$DB_PORT/$DB_SID
#======================================================================================================
#检查环境变量
if [ -z "$EI_HOME" ]; then
  echo "环境变量$EI_HOME 必须需设置"
  echo 1
fi
#======================================================
#更改数据库相关文件配置
#修改配置文件conf/datasources/master-datasources.xml
sed -i "s#<name>jdbc/WSO2CarbonDB#<name>jdbc/$DATASOURCE_NAME#g" $EI_HOME/conf/datasources/master-datasources.xml
sed -i "s#<url>jdbc:h2:./repository/database/WSO2CARBON_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000#<url>$DB_URL#g" $EI_HOME/conf/datasources/master-datasources.xml
sed -i "s/<username>wso2carbon/<username>$DB_USERNAME/g" $EI_HOME/conf/datasources/master-datasources.xml
sed -i "s/<password>wso2carbon/<password>$DB_PASSWORD/g" $EI_HOME/conf/datasources/master-datasources.xml
sed -i "s/<driverClassName>org.h2.Driver/<driverClassName>oracle.jdbc.OracleDriver/g" $EI_HOME/conf/datasources/master-datasources.xml
#确保多次运行该版本，只替换一次.因为源文件中H2数据库配置中没有<minIdle>元素，需要通过替换方法自动给添加上去
if [ `grep -c "<minIdle>5</minIdle>" $EI_HOME/conf/datasources/master-datasources.xml` -eq 0 ];then  
    sed -i "s#<maxWait>60000</maxWait>#<maxWait>60000</maxWait>\r                    <minIdle>5</minIdle>#g" $EI_HOME/conf/datasources/master-datasources.xml
fi
sed -i "s/<validationQuery>SELECT 1/<validationQuery>SELECT 1 FROM DUAL/g" $EI_HOME/conf/datasources/master-datasources.xml

#修改配置文件conf/registry.xml
sed -i "s#<dataSource>jdbc/WSO2CarbonDB#<dataSource>jdbc/$DATASOURCE_NAME#g" $EI_HOME/conf/registry.xml

#修改配置文件conf/user-mgt.xml
sed -i "s#<Property name=\"dataSource\">jdbc/WSO2CarbonDB#<Property name=\"dataSource\">jdbc/$DATASOURCE_NAME#g" $EI_HOME/conf/user-mgt.xml

echo "ei的主数据源已经切换到Oracle($DB_URL)"
