#reboot the industry web

cd $INDUSTRY_WEB/deploy/target/web-deploy/
cd bin
./killws.sh
./startws.sh
