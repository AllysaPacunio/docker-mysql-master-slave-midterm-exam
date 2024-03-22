#!/bin/bash

docker compose down
# rm -rf ./master/data/* ./master/data/.gitkeep
# rm -rf ./slave/data/* ./slave/data/.gitkeep
chmod 044 ./master/conf/mysql.conf.cnf
chmod 044 ./slave/conf/mysql.conf.cnf
docker compose build
docker compose up -d
until docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

ally_stmt='GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_ally"@"%" IDENTIFIED BY "mydb_ally_pwd"; FLUSH PRIVILEGES;'
meibs_stmt='GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_meibs"@"%" IDENTIFIED BY "mydb_meibs_pwd"; FLUSH PRIVILEGES;'
phia_stmt='GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_phia"@"%" IDENTIFIED BY "mydb_phia_pwd"; FLUSH PRIVILEGES;'

docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$ally_stmt'"
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$meibs_stmt'"
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root -e '$phia_stmt'"


until docker-compose exec mysql_slave_ally sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave_ally database connection..."
    sleep 4
done

until docker-compose exec mysql_slave_meibs sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave_meibs database connection..."
    sleep 4
done

until docker-compose exec mysql_slave_phia sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave_phia database connection..."
    sleep 4
done


docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

MS_STATUS=`docker exec mysql_master sh -c 'export MYSQL_PWD=111; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $5}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $6}'`

start_ally_stmt="RESET SLAVE;CHANGE MASTER TO MASTER_HOST='$(docker-ip mysql_master)',MASTER_USER='mydb_slave_ally',MASTER_PASSWORD='mydb_ally_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_ally_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_ally_cmd+="$start_ally_stmt"
start_ally_cmd+='"'
echo "$start_ally_cmd"
docker exec mysql_slave sh -c "$start_ally_cmd"

start_meibs_stmt="RESET SLAVE;CHANGE MASTER TO MASTER_HOST='$(docker-ip mysql_master)',MASTER_USER='mydb_meibs_user',MASTER_PASSWORD='mydb_meibs_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_meibs_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_meibs_cmd+="$start_meibs_stmt"
start_meibs_cmd+='"'
echo "$start_meibs_cmd"
docker exec mysql_slave sh -c "$start_meibs_cmd"

start_phia_stmt="RESET SLAVE;CHANGE MASTER TO MASTER_HOST='$(docker-ip mysql_master)',MASTER_USER='mydb_slave_user',MASTER_PASSWORD='mydb_slave_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_phia_cmd='export MYSQL_PWD=111; mysql -u root -e "'
start_phia_cmd+="$start_phia_stmt"
start_phia_cmd+='"'
echo "$start_phia_cmd"
docker exec mysql_slave sh -c "$start_phia_cmd"

docker exec mysql_slave_ally sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"
docker exec mysql_slave_meibs sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"
docker exec mysql_slave_phia sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"
docker exec mysql_master sh -c "export MYSQL_PWD=111; mysql -u root mydb < /db/mydb.sql"

