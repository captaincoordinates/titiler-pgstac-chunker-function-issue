#!/bin/bash -e

pushd $(dirname $0)/..

for pg_version in 16 17; do
    echo; echo "* testing pgstac with PostgreSQL $pg_version"; echo
    pgstac_image_name="local/pgstac:postgres-$pg_version"
    docker build \
        --tag $pgstac_image_name \
        --build-arg PG_MAJOR=$pg_version \
        --file pgstac/docker/pgstac/Dockerfile \
        --target pgstac \
        pgstac

    tester_image_name="local/titiler-pgstac-tester:postgres-$pg_version"
    docker build \
        --tag $tester_image_name \
        --build-arg PGSTAC_IMAGE=$pgstac_image_name \
        --file Dockerfile.tester \
        .
    
    docker run \
        --rm \
        --tty \
        $tester_image_name \
        uv run pytest -x -s -vv
done
