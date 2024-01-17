# How to use this SQL script

## Limitations
This has been written for alembic version 0027, this may need altering for a higher version

## Instructions

Create a new folder somewhere to store all the table dumps.

Goto that folder and ensure that running `psql` connects to the correct db you want to copy.

Then run the script, e.g.:

```

psql -f ~/work/navigator-scripts/psql/copy-all-data.sql
COPY 1
COPY 2
COPY 540
COPY 836
COPY 540
COPY 2
COPY 5067
COPY 6454
COPY 10
COPY 75
COPY 6028
COPY 17
COPY 5067
COPY 5067
COPY 201
COPY 212
COPY 7893
COPY 2
COPY 3
COPY 2
COPY 2
COPY 6795
COPY 5884
COPY 11560
COPY 2
```
