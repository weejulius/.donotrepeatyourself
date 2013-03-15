#reboot the industry web

iwreboot(){
     $INDUSTRY_WEB/deploy/target/web-deploy/bin/killws.sh
     $INDUSTRY_WEB/deploy/target/web-deploy/bin/startws.sh    

}

iwboot(){
    cd $INDUSTRY_WEB
    cd deploy/target/web-deploy/bin
    export JAVA_OPTIONS="${JAVA_OPTIONS} -javaagent:~/projects/hotcode.jar -Dhotcode.confFile=$INDUSTRY_WEB/workspace.xml -noverify"
    echo $JAVA_OPTIONS
    ./killws.sh
    ./startws.sh
    echo $JAVA_OPTIONS
}

iwstop(){
     sh  $INDUSTRY_WEB/deploy/target/web-deploy/bin/killws.sh
}

iwboot2(){
    # start the industry web directly
    iwstop
    /usr/alibaba/java/bin/java -DappName=industryweb -Xms64m -Xmx1024m -XX:MaxPermSize=128m -Ddatabase.codeset=ISO-8859-1 -Ddatabase.logging=false -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dapplication.codeset=GBK -Djava.util.logging.config.file=/home/jyu/projects/industryweb/deploy/target/web-deploy/conf/general/logging.properties -Dcom.sun.management.config.file=/home/jyu/projects/industryweb/deploy/target/web-deploy/conf/jmx/jmx_monitor_management.properties -Dorg.eclipse.jetty.util.URI.charset=GBK -Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=2108,server=y,suspend=n -Djetty.logs=/home/jyu/projects/industryweb/deploy/target/web-deploy/jetty_server/logs -Djetty.home=/usr/alibaba/jetty -Djava.io.tmpdir=/home/jyu/projects/industryweb/deploy/target/web-deploy/jetty_server/tmp -javaagent:/home/jyu/projects/hotcode.jar -Dhotcode.confFile=/home/jyu/projects/industryweb/workplace.xml -noverify -jar /usr/alibaba/jetty/start.jar --ini=/home/jyu/projects/industryweb/deploy/target/web-deploy/jetty_server/conf/start.ini --daemon
}

