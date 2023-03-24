# dkr-copy-volume 

Copies one docker volume to another - used for copying the postgres volume as an alternative for re-creating and restoring a backup.
`navigator_db-data-backend`


## EXAMPLES

Assuming you've already copied a volume which had production data in to `prod-database` this will restore the volume:

```
  dk-copy-volume.sh prod-database navigator_db-data-backend
```

## Creating a local volume from prod

- Use `nav-stack-connect.sh` to connect to prod
- Ensure the socat command is running on the bastion
- Source the vars file as the output suggests
- Run `pg_dump --create -s -d navigator > navigator_$(date --iso).sql`
- Disconnect from prod - really - now make sure again
- Edit the sql file and rename `navigator_admin` to `navigator` and remove any reference to rds users. Also at the top add the statement `use database navigator`
- From the backend repo type `make start` to create a fresh database
- Now manually stop all but the postgres container: `docker stop navigator-backend_backend_1 opensearch-dashboards opensearch-node1`
- Use `psql postgres` to connect to the postgres database
- Now re-create the navigator db with `drop database navigator; create database navigator;`
- Exist and restore the production database locally with `psql navigator -f  /home/peter/work/navigator-scripts/navigator_2023-01-25.sql`
- Finally save it with `dkr-copy-volume.sh navigator-backend_db-data-backend prod-database`
- `make start` should now have data in


## References: 
 - https://github.com/moby/moby/issues/31154#issuecomment-360531460
 - https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes
