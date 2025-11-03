from fastapi import FastAPI
import json

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "STEMgraph API"}

@app.get("/getWholeGraph")
def get_graph():
    with open("data/jsonld.json") as jsonld_file:
        data = json.load(jsonld_file)
    return data

@app.get("/getPathToExercise")
def get_path():
    with open("data/jsonld.json") as jsonld_file:
        data = json.load(jsonld_file)
    path = {}
    path["@context"] = data["@context"]
    path["@graph"] = find_exercise(data, "fb98095a-0ef6-465a-886a-e8b9e3cad876") 
    return path


def find_exercise(db, uuid):
    """Find the list element with the given uuid as @id."""
    for ex in db["@graph"]:
        if ex["@id"] == uuid:
            return ex
