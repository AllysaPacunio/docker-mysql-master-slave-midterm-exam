Docker MySQL master-slave replication 
========================

MySQL master-slave replication with using Docker. 

## Run

To run this examples you will need to start containers with "docker-compose" 
and after starting setup replication. See commands inside ./build.sh. 

#### Create 2 MySQL containers with master-slave row-based replication 

```
chmod +x build.sh
```

```
./build.sh
```
```
npm install mysql
```
```
cd example_app
```
```
cd REST
```
```
code request.rest
```
```
cd ..
```
```
node index.js
```

Click Send Request at the request.rest file

## Troubleshooting

#### Check Logs

```
docker-compose logs
```

#### Start containers in "normal" mode

> Go through "build.sh" and run command step-by-step.

#### Check running containers

```
docker-compose ps
```

#### Clean data dir

```
rm -rf ./master/data/*
rm -rf ./slave/data/*
```

#### Run command inside "mysql_master"

```
docker exec mysql_master sh -c 'mysql -u root -p111 -e "SHOW MASTER STATUS \G"'
```

#### Run command inside "mysql_slave"

```
docker exec mysql_slave sh -c 'mysql -u root -p111 -e "SHOW SLAVE STATUS \G"'
```

#### Enter into "mysql_master"

```
docker exec -it mysql_master bash
```

#### Enter into "mysql_slave"

```
docker exec -it mysql_slave bash
```
