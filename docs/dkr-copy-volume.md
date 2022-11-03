# dkr-copy-volume 

Copies one docker volume to another - used for copying the postgres volume as an alternative for re-creating and restoring a backup.
`navigator_db-data-backend`


## EXAMPLES

Assuming you've already copied a volume which had production data in to `prod-database` this will restore the volume:

```
  dk-copy-volume.sh prod-database navigator_db-data-backend
```

## References: 
 - https://github.com/moby/moby/issues/31154#issuecomment-360531460
 - https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes
