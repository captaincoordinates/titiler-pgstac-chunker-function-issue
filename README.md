# PostgreSQL 17 Chunker Function Issue in Tests

This fork demonstrates an issue with titiler-pgstac tests on Postgres 17. It appears that the issue only affects tests and not regular titiler-pgstac use.

## Chunker Function Issue

### Reproduce

To reproduce this issue:

```sh
scripts/setup.sh    # configure pgstac submodule prior to test
scripts/test.sh
```

This script builds two versions of pgstac: one with Postgres 16 and one with Postgres 17. It builds a tester container image on top of each pgstac version and executes this project's automated tests. Tests pass on Postgres 16 but fail on Postgres 17.

This project's CI currently [uses](https://github.com/stac-utils/titiler-pgstac/blob/1d6ef40698f86e4a12b071fd5629b7494abe837d/.github/workflows/ci.yml#L38) Postgres 16, which explains why this issue has not previously been apparent.

### Scope

I was unable to replicate the issue in normal titiler-pgstac use or [this](https://github.com/captaincoordinates/pgstac-chunker-function-issue) pgstac-only repo. I suspect this _could_ indicate an issue with the [pytest-postgresql](https://pypi.org/project/pytest-postgresql/) package used to support automated tests.

### Impact

As this issue does not appear to directly affect titiler-pgstac use its impact is likely low, however by generating false negatives in testing it can negatively impact development efforts that extend titiler-pgstac.

### Investigation

The cause appears to be within the [`pgstac.chunker`](https://github.com/stac-utils/pgstac/blob/497625a1ec77a197f6f2ff3e1dd7b9456bb1b3a1/src/pgstac/sql/004_search.sql#L2) function. This function joins to the `pgstac.partition_steps` materialized view using the `EXPLAIN` JSON's `Relation Name` field. `pgstac.partition_steps` has schema-prefixed table names and while Postgres 16's `Relation Name` field also has schema-prefixed table names, Postgres 17's does not. In Postgres 17 this creates a 0-row join product, which means calls to `pgstac.partition_queries` that include a `datetime` ORDER BY clause return 0 SQL statements, which means functions like `pgstac.geojsonsearch` erroneously return 0 features when they should return >0 features.

---


<p align="center">
  <img width="500" src="https://github.com/stac-utils/titiler-pgstac/assets/10407788/24a64ea9-fede-4ee8-ab8d-625c9e94db44"/>
  <p align="center">Connect PgSTAC and TiTiler.</p>
</p>

<p align="center">
  <a href="https://github.com/stac-utils/titiler-pgstac/actions?query=workflow%3ACI" target="_blank">
      <img src="https://github.com/stac-utils/titiler-pgstac/workflows/CI/badge.svg" alt="Test">
  </a>
  <a href="https://codecov.io/gh/stac-utils/titiler-pgstac" target="_blank">
      <img src="https://codecov.io/gh/stac-utils/titiler-pgstac/branch/main/graph/badge.svg" alt="Coverage">
  </a>
  <a href="https://pypi.org/project/titiler.pgstac" target="_blank">
      <img src="https://img.shields.io/pypi/v/titiler.pgstac?color=%2334D058&label=pypi%20package" alt="Package version">
  </a>
  <a href="https://github.com/stac-utils/titiler-pgstac/blob/main/LICENSE" target="_blank">
      <img src="https://img.shields.io/github/license/stac-utils/titiler-pgstac.svg" alt="License">
  </a>
</p>

---

**Documentation**: <a href="https://stac-utils.github.io/titiler-pgstac/" target="_blank">https://stac-utils.github.io/titiler-pgstac/</a>

**Source Code**: <a href="https://github.com/stac-utils/titiler-pgstac" target="_blank">https://github.com/stac-utils/titiler-pgstac</a>

---

**TiTiler-PgSTAC** is a [TiTiler](https://github.com/developmentseed/titiler) extension that connects to a [PgSTAC](https://github.com/stac-utils/pgstac) database to create dynamic **mosaics** based on [search queries](https://github.com/radiantearth/stac-api-spec/tree/master/item-search).

## Installation

To install from PyPI and run:

```bash
# Make sure to have pip up to date
python -m pip install -U pip

# Install `psycopg` or `psycopg["binary"]` or `psycopg["c"]`
python -m pip install psycopg["binary"]

python -m pip install titiler.pgstac
```

To install from sources and run for development:

We recommand using [`uv`](https://docs.astral.sh/uv) as project manager for development.

See https://docs.astral.sh/uv/getting-started/installation/ for installation 

```
git clone https://github.com/stac-utils/titiler-pgstac.git
cd titiler-pgstac

uv sync --extra psycopg 
```

### `PgSTAC` version

`titiler.pgstac` depends on `pgstac >=0.3.4` (https://github.com/stac-utils/pgstac/blob/main/CHANGELOG.md#v034).

### `psycopg` requirement

`titiler.pgstac` depends on the `psycopg` library. Because there are three ways of installing this package (`psycopg` or , `psycopg["c"]`, `psycopg["binary"]`), the user must install this separately from `titiler.pgstac`.

- `psycopg`: no wheel, pure python implementation. It requires the `libpq` installed in the system.
- `psycopg["binary"]`: binary wheel distribution (shipped with libpq) of the `psycopg` package and is simpler for development. It requires development packages installed on the client machine.
- `psycopg["c"]`: a C (faster) implementation of the libpq wrapper. It requires the `libpq` installed in the system.

`psycopg[c]` or `psycopg` are generally recommended for production use.

In `titiler.pgstac` setup.py, we have added three options to let users choose which psycopg install to use:

- `python -m pip install titiler.pgstac["psycopg"]`: pure python
- `python -m pip install titiler.pgstac["psycopg-c"]`: use the C wrapper (requires development packages installed on the client machine)
- `python -m pip install titiler.pgstac["psycopg-binary"]`: binary wheels

## Launch

You'll need to have `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGHOST`, `PGPORT` variables set in your environment pointing to your Postgres database where pgstac has been installed.

```
export PGUSER=username
export PGPASSWORD=password
export PGDATABASE=postgis
export PGHOST=database
export PGPORT=5432
```

```
$ python -m pip install uvicorn
$ uvicorn titiler.pgstac.main:app --reload
```

### Using Docker

```
$ git clone https://github.com/stac-utils/titiler-pgstac.git
$ cd titiler-pgstac
$ docker compose up --build tiler
# or
$ docker compose up --build tiler-uvicorn
```

## Contribution & Development

See [CONTRIBUTING.md](https://github.com//stac-utils/titiler-pgstac/blob/main/CONTRIBUTING.md)

## License

See [LICENSE](https://github.com//stac-utils/titiler-pgstac/blob/main/LICENSE)

## Authors

See [contributors](https://github.com/stac-utils/titiler-pgstac/graphs/contributors) for a listing of individual contributors.

## Changes

See [CHANGES.md](https://github.com/stac-utils/titiler-pgstac/blob/main/CHANGES.md).
