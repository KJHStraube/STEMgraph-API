from fastapi import FastAPI
import json

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "STEMgraph API"}

@app.get("/getWholeGraph")
def get_graph():
    with open("/app/data/jsonld.json") as jsonld_file:
        data = json.load(jsonld_file)
    return data

@app.get("/getPathToExercise/{uuid}")
def get_path(uuid: str):
    with open("/app/data/jsonld.json") as jsonld_file:
        data = json.load(jsonld_file)
    path = {}
    path["@context"] = data["@context"]
    path["@graph"] = find_exercise(data, uuid)
    if path["@graph"] is not None:
        expand_dependencies(data, path["@graph"])
    return path


def find_exercise(db, uuid):
    """Find the list element with the given uuid as @id."""
    for ex in db["@graph"]:
        if ex["@id"] == uuid:
            return ex
    return None

def expand_dependencies(db, curEx):
    """Expand the current exercise's dependencies."""
    if curEx.get("isBasedOn") is not None:
        baselist = curEx["isBasedOn"]
        curEx["isBasedOn"] = []
        for uuid in baselist:
            curEx["isBasedOn"].append(find_exercise(db, uuid))
            expand_dependencies(db, curEx["isBasedOn"][-1])
    if curEx.get("stg:hasAlternativeDependency") is not None:
        altlist = curEx["stg:hasAlternativeDependency"]["stg:isBasedOnOptions"]
        curEx["stg:hasAlternativeDependency"]["stg:isBasedOnOptions"] = []
        for uuid in altlist:
            curEx["stg:hasAlternativeDependency"]["stg:isBasedOnOptions"].append(find_exercise(db, uuid))
            expand_dependencies(db, curEx["stg:hasAlternativeDependency"]["stg:isBasedOnOptions"][-1])

