#!/bin/sh

set -e

if [ ! $1 ]; then
    echo "This is a tool helping developers to build and test Babelfish easily."
    echo ""
    echo "Prerequisites:"
    echo "  (1) postgresql_modified_for_babelfish, babelfish_extensions, and postgres should be in the same workspace."
    echo "  (2) should be executed in the \"babelfish_extension\" directory."
    echo ""
    echo "Commands:"
    echo "  (if TARGET_WS is not provided, the current workspace will be used)"
    echo ""
    echo "  initdb [TARGET_WS]"
    echo "      init data directory + modify postgresql.conf + restart db"
    echo ""
    echo "  initbbf [TARGET_WS]"
    echo "      execute babelfish_extensions/test/JDBC/init.sh"
    echo ""
    echo "  buildpg [TARGET_WS]"
    echo "      build postgresql_modified_for_babelfish + restart db"
    echo ""
    echo "  buildbbf [TARGET_WS]"
    echo "      build babelfish_extensions + restart db"
    echo ""
    echo "  buildall [TARGET_WS]"
    echo "      build postgresql_modified_for_babelfish + build babelfish_extensions + restart db"
    echo ""
    echo "  pg_upgrade SOURCE_WS [TARGET_WS]"
    echo "      run pg_upgrade from SOURCE_WS to TARGET_WS"
    echo ""
    echo "  test INPUT_DIR [TARGET_WS]"
    echo "      run JDBC test"
    exit 0
fi

CUR_DIR=`basename "$PWD"`
if [ "$CUR_DIR" != "babelfish_extensions" ]; then
    echo "Error: This script should be executed in the \"babelfish_extensions\" directory." 1>&2
    exit 1
fi

cd ..
CUR_WS=$PWD
echo "Current Workspace: $CUR_WS"

TARGET_WS=$2
if [ "$1" == "pg_upgrade" ] || [ "$1" == "test" ]; then
    TARGET_WS=$3
fi
if [ ! $TARGET_WS ]; then
    TARGET_WS=$CUR_WS
fi
echo "Target Workspace: $TARGET_WS"

TEST_DB="jdbc_testdb"

cd $TARGET_WS
if [ ! -d "./postgres" ]; then
    echo "Error: Directory \"postgres\" should exist in the target workspace." 1>&2
    exit 1
fi
if [ ! -d "./postgresql_modified_for_babelfish" ]; then
    echo "Error: Directory \"postgresql_modified_for_babelfish\" should exist in the target workspace." 1>&2
    exit 1
fi

restart() {
    cd $1/postgres
    bin/pg_ctl -D data/ -l logfile restart
}

stop() {
    cd $1/postgres
    bin/pg_ctl -D data/ -l logfile stop
}

build_pg() {
    cd $1/postgresql_modified_for_babelfish
    make install
}

build_bbf() {
    cd $1/babelfish_extensions
    export PG_CONFIG=$1/postgres/bin/pg_config
    export PG_SRC=$1/postgresql_modified_for_babelfish
    export cmake=$(which cmake)
    cd contrib/babelfishpg_money
    make clean && make && make install
    cd ../babelfishpg_common
    make clean && make && make install
    cd ../babelfishpg_tds
    make clean && make && make install
    cd ../babelfishpg_tsql
    make clean && make && make install
}

init_db() {
    cd $1/postgres
    rm -rf data
    bin/initdb -D data/
    PID=$(ps -ef | grep postgres/bin/postgres | grep -v grep | awk '{print $2}')
    if [ $PID ]
    then
        kill -9 $PID
    fi
    sleep 1
    bin/pg_ctl -D data/ -l logfile start
    cd data
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
    sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'babelfishpg_tds'/g" postgresql.conf
    sudo echo "host    all             all             0.0.0.0/0            trust" >> pg_hba.conf
    restart $1
}

if [ "$1" == "initdb" ]; then
    init_db $TARGET_WS
    exit 0
elif [ "$1" == "initbbf" ]; then
    $TARGET_WS/babelfish_extensions/test/JDBC/init.sh
    exit 0
elif [ "$1" == "buildpg" ]; then
    build_pg $TARGET_WS
    restart $TARGET_WS
    exit 0
elif [ "$1" == "buildbbf" ]; then
    build_bbf $TARGET_WS
    restart $TARGET_WS
    exit 0
elif [ "$1" == "buildall" ]; then
    build_pg $TARGET_WS
    build_bbf $TARGET_WS
    restart $TARGET_WS
    exit 0
elif [ "$1" == "pg_upgrade" ]; then
    init_db $TARGET_WS
    stop $TARGET_WS
    echo "Init target workspace ($TARGET_WS) done!"

    SOURCE_WS=$2
    stop $SOURCE_WS || true

    cd $TARGET_WS
    if [ ! -d "./upgrade" ]; then
        mkdir upgrade
    else
        rm upgrade/*
    fi
    cd upgrade
    ../postgres/bin/pg_upgrade -U $USER \
        -b $SOURCE_WS/postgres/bin -B $TARGET_WS/postgres/bin \
        -d $SOURCE_WS/postgres/data -D $TARGET_WS/postgres/data \
        -p 5432 -P 5433 -j 4 --link --verbose
    echo ""

    ./delete_old_cluster.sh
    cd $TARGET_WS/postgres
    bin/pg_ctl -D data/ -l logfile start

    echo ""
    echo 'Updating babelfish extensions...'
    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER EXTENSION babelfishpg_common UPDATE; ALTER EXTENSION babelfishpg_tsql UPDATE;"
    bin/psql -d $TEST_DB -U $USER -c \
        "ALTER SYSTEM SET babelfishpg_tsql.database_name = 'jdbc_testdb';"
    bin/psql -d $TEST_DB -U $USER -c \
        "SELECT pg_reload_conf();"
    exit 0
elif [ "$1" == "test" ]; then
    INPUT_DIR=$2
    cd $TARGET_WS/postgres
    if [ "$INPUT_DIR" == "upgrade/preparation" ] || [ "$INPUT_DIR" == "upgrade/verification" ]; then
        bin/psql -d $TEST_DB -U $USER -c \
            "ALTER SYSTEM SET babelfishpg_tsql.migration_mode = 'multi-db';"
    else
        bin/psql -d $TEST_DB -U $USER -c \
            "ALTER SYSTEM SET babelfishpg_tsql.migration_mode = 'single-db';"
    fi
    bin/psql -d $TEST_DB -U $USER -c \
        "SELECT pg_reload_conf();"

    cd $CUR_WS/babelfish_extensions/test/JDBC
    rm -rf output
    export inputFilesPath=$INPUT_DIR
    mvn test
    exit 0
fi
