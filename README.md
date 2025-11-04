# STEMgraph-API

A FastAPI solution for [STEMgraph](https://github.com/STEMgraph).

## Repository structure

/doc: Documentation  
/bin: Scripts and Binaries

## Overview

![planned use-cases for STEMgraph-API](/doc/useCase.svg "STEMgraph-API Use-Cases")

## Usage

### Initial Setup (Github-Login)
```bash
docker compose --profile setup run setup
```

### Generate Graph Data by parsing through the STEMgraph repositories
```bash
docker compose up stemgraph-parser
```

### Start API
```bash
docker compose up api
```

API available at `http://localhost:8000/` ([docs](http://localhost:8000/docs))
