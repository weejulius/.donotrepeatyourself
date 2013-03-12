#boot the industry web
cd $INDUSTRY_WEB
cd deploy/target/web-deploy/bin
export JAVA_OPTIONS="${JAVA_OPTIONS} -javaagent:~/projects/hotcode.jar -Dhotcode.confFile=$INDUSTRY_WEB/workspace.xml -noverify"
echo $JAVA_OPTIONS
./killws.sh
./startws.sh
echo $JAVA_OPTIONS
