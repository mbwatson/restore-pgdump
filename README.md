# Restore PostgreSQL Dump in Docker

## What does this accomplish?

This starts a containerized PostgreSQL server populated with data from data exported with pg_dump from another PostgreSQL database.

## Why?

If you're developing a service, say a frontend or an API, that requires access to a remote database, you probably want to avoid sending loads of requests to the production database during development. Additionally, remotely querying the remote database may be difficult or impossible to do remotely.

The solution is to spin up a Docker container running locally that contains a snapshot of the contents of the remote database. Then you can query the database and even alter it to your heart's desire, making the development a little less cumbersome.

## How?

1. Dump the remote database contents.

Say the remote database you'd like to clone is accessible via ssh. Log into the remote machine and dump the data you're interested in.

```bash
$ ssh username@remote.host.com
```

Log into the account allowing access, such as the `postgres` user.

```bash
$ su postgres
```

Dump the database contents to a `.sql` file. This is a plain text file completely describing the database schema and contents.

```bash
$ pwd /home/username
$ pg_dump DATABASE_NAME > dump.sql
```

This file sits in your home directory, waiting to be fetched. Back out on your local machine, fetch it.

```bash
$ scp username@remote.host.com:/home/username /path/to/save/
```

2. Put dumped data, `dump.sql` into this project's `./db` directory.

The structure of this repo should, then, look like the following.

```bash
$ tree
.
├── db
│   ├── Dockerfile
│   ├── dump.sql
│   ├── init-user-db.sh
│   └── pgdata
├── db.env
├── docker-compose.yml
└── README.md
```

3. Credentials

Put the database credentials into a `db.env` file. This file should lbasically look like the sample `db.env.sample` file. The `db.env` file is not tracked in version control. These credentials are located here, outside the `docker-compose.yml`, because this information will likely be shared across multiple services, minimizing repetition within that file.

Any other service requiring this information cna access it by the addition of 

```yaml
    env_file:
     - ./db.env
```

to the service block in the `docker-compose.yml` file.

4. Build and spin up the container.

```bash
$ docker-compose up --build
```

Note we're using Docker Compose here. It's not necessary, as we could move the apropriate configurations into the `./db/Dockerfile` and use vanilla Docker.

However, if we're doing all this under the assumptions outlined at the beginning of this document, then we're going to orchesrate deployment of this database alongside some other service, like a frontend or API. Thus preparing for this with Docker Compose makes getting up and running quicker.

### Some things

The `init-user-db.sh` script is mounted as a volume in the container's `/docker-entrypoint-initdb.d/` directory so that it is executed automatically when postgres starts. The information in the main block of this script--the calls to `psql` can be customized to suit your situation. It maynot even be required in certain situations.

The last line of this file imports that dumped data (from step 1) into your containerized database server.

```bash
$ cat ./db/init-user-db.sh

#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER root;
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO root;
EOSQL

psql $POSTGRES_DB < /data/dump.sql
```

An alternative option to the above method is to copy in (or just mount) the `dump.sql` file into the container's `/docker-entrypoint-initdb.d/` directory. Then the container will run the init script _and_ import the data dump. However, it seems that this import runs before the init script is run, and it's possible that the data import requires certain users or roles to exist beforehand. This is why this method is done here--so we can guarantee any necessary setup is run _before_ the data is imported.

## Additional References

- Docker: [https://docs.docker.com](https://docs.docker.com)
- Docker Compose: [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
- PostgreSQL: [https://www.postgresql.org/](https://www.postgresql.org/) 
- Postgres Official Docker Image: [https://hub.docker.com/_/postgres/](https://hub.docker.com/_/postgres/)
- 