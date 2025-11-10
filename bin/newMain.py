from fastapi import FastAPI
from fastapi import status
from fastapi.responses import JSONResponse
from datetime import datetime
import copy
import json


# initialize global variables

DB_LOC = "/app/data/jsonld.json"
CONTENT_LOC = "/app/data/graphContent.json"
with open(DB_LOC) as db_file:
    db = json.load(db_file)


# here comes the api code

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "STEMgraph API"}

@app.get("/getWholeGraph")
def get_whole_graph():
    wholeGraph = copy.deepcopy(db)
    wholeGraph["generatedAt"] = now()
    return wholeGraph 

@app.get("/getPathToExercise/{uuid}")
def get_path_to_exercise(uuid: str):
    # initialize return object
    path = {}
    add_graph_context(path)
    add_graph_metadata(path)
    path["@graph"] = []
    
    # get exercise tree
    ex = get_exercise(uuid)
    if ex is None:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"error": f"Exercise with ID '{uuid}' not found."}
        )
    path["@graph"].append(ex)
    expand_dependencies(path, ex)
    return path


# auxiliary subroutines

def get_exercise(uuid):
    """Find the list element with the given uuid as @id."""
    for ex in db["@graph"]:
        if ex["@id"] == uuid:
            return ex
    return None

def expand_dependencies(data, curEx, visited=None):
    """Add the current exercise's dependencies to the graph."""
    if visited is None:
        visited = set()
    if curEx.get("dependsOn") is not None:
        for dep in curEx["dependsOn"]:
            if isinstance(dep, str):
                if dep not in visited:
                    visited.add(dep)
                    ex = get_exercise(dep)
                    if ex is not None:
                        data["@graph"].append(ex)
                        expand_dependencies(data, ex, visited)
            elif isinstance(dep, dict) and dep.get("oneOf"):
                for alt in dep["oneOf"]:
                    if alt not in visited:
                        visited.add(alt)
                        ex = get_exercise(alt)
                        if ex is not None:
                            data["@graph"].append(ex)
                            expand_dependencies(data, ex, visited)

def add_graph_context(data):
    """Gets contextdata from local context file and adds it to the data."""
    with open(CONTEXT_LOC) as context_file:
        context = json.load(context_file)
    data["@context"] = context["@context"]

def add_graph_metadata(data):
    """Adds metadata (url, created at & by) to the data."""
    data["@id"] = "https://example.com/"
    data["generatedBy"]["@type"] = "schema:Organization"
    data["generatedBy"]["schema:name"] = "STEMgraph API"
    data["generatedBy"]["schema:url"] = "https://github.com/KJHStraube/STEMgraph-API"
    data["generatedAt"] = now()

def now():
    """Gets the current timestamp."""
    return datetime.utcnow().isoformat()
