# rebuild all the project


build(){
    svn update
    mvn clean install -Denv=release1 -DskipTests
}

rebuild_all(){
    echo $INDUSTRY_SHARED
    cd $INDUSTRY_SHARED
    build

    cd $INDUSTRY_CENTER
    build

    cd $INDUSTRY_WEB
    build
}
