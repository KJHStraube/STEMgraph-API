from fastapi import FastAPI
import json

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "STEMgraph API"}


@app.get("/graph")
def get_graph():
    with open("/app/data/jsonld.json") as jsonld_file:
        data = json.load(jsonld_file)
    return data
