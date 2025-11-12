from fastapi import FastAPI
from fastapi import status
from fastapi.responses import JSONResponse
from collections import defaultdict
from datetime import datetime
import copy
import json


# initialize global variables

DB_LOC = "/app/data/jsonld.json"
CONTEXT_LOC = "/app/data/graphContext.json"
with open(DB_LOC) as db_file:
    db = json.load(db_file)


# here comes the api code
app = FastAPI()

@app.get("/")
def read_root():
    """Returns a greeting."""
    return {"message": "Welcome to STEMgraph API"}

@app.get("/getExercise/{uuid}")
def get_exercise(uuid: str):
    """Returns a graph with one single exercise node."""
    ex = get_exercise_node(uuid)
    if ex is None:
        return error_noEx404(uuid)
    exercise = init_graph()
    exercise["@graph"].append(ex)
    return exercise

@app.get("/getExercisesByKeyword/{keyword}")
def get_exercises_by_keyword(keyword: str):
    """Returns a graph with all exercises tagged with a specific keyword."""
    keyword = keyword.lower()
    exTagged = init_graph()
    for ex in db["@graph"]:
        if ex.get("keywords") is not None:
            if any(keyword == key.lower() for key in ex["keywords"]):
                exTagged["@graph"].append(ex)
    if not exTagged["@graph"]:
        return error_noKey404(keyword)
    return exTagged

@app.get("/getKeywordCount")
def get_keyword_count():
    """Returns all keywords found along with their frequency."""
    keywordCount = {}
    add_graph_metadata(keywordCount)
    counts = defaultdict(int)
    for ex in db["@graph"]:
        if ex.get("keywords") is not None:
            for keyword in ex["keywords"]:
                counts[keyword.lower()] += 1
    keywordCount["keywords"] = dict(counts)
    return keywordCount

@app.get("/getKeywordList")
def get_keyword_list():
    """Returns a list with all keywords found in the database."""
    keywordList = {}
    add_graph_metadata(keywordList)
    keywords = set() 
    for ex in db["@graph"]:
        if ex.get("keywords") is not None:
            keywords.update(key.lower() for key in ex["keywords"])
    keywordList["keywords"] = sorted(list(keywords))
    return keywordList

@app.get("/getPathToExercise/{uuid}")
def get_path_to_exercise(uuid: str):
    """Returns a graph with all nodes leading to the given one."""
    path = get_exercise(uuid)
    if not isinstance(path, JSONResponse) and path.get("@graph"):
        visited = None
        expand_dependencies(path, path["@graph"][0], visited)
    return path

@app.get("/getWholeGraph")
def get_whole_graph():
    """Returns the whole graph, i.e. database."""
    wholeGraph = copy.deepcopy(db)
    wholeGraph["generatedAt"] = now()
    return wholeGraph 


# auxiliary graph manipulation subroutines

def init_graph():
    """Returns an empty graph framework."""
    graph = {}
    add_graph_context(graph)
    add_graph_metadata(graph)
    graph["@graph"] = []
    return graph

def get_exercise_node(uuid):
    """Get the list element with the given uuid as @id."""
    for ex in db["@graph"]:
        if ex["@id"] == uuid:
            return ex
    return None

def expand_dependencies(data, curEx, visited):
    """Add the current exercise's dependencies to the graph."""
    if visited is None:
        visited = set()
    if curEx.get("dependsOn") is not None:
        for dep in curEx["dependsOn"]:
            if isinstance(dep, str):
                add_exercise(data, dep, visited)
            elif isinstance(dep, dict) and dep.get("oneOf"):
                for alt in dep["oneOf"]:
                    add_exercise(data, alt, visited)
            else:
                print("unexpected dependency structure in ", curEx["@id"], ": ", dep)

def add_exercise(data, uuid, visited):
    """Adds an exercise to the data structure."""
    if uuid not in visited:
        visited.add(uuid)
        ex = get_exercise_node(uuid)
        if ex is not None:
            data["@graph"].append(ex)
            expand_dependencies(data, ex, visited)

def add_graph_context(data):
    """Gets context data from local context file and adds it to the data."""
    with open(CONTEXT_LOC) as context_file:
        context = json.load(context_file)
    data["@context"] = context["@context"]

def add_graph_metadata(data):
    """Adds metadata (url, created at & by) to the data."""
    data["@id"] = "https://example.com/"
    data["generatedBy"] = {}
    data["generatedBy"]["@type"] = "schema:Organization"
    data["generatedBy"]["schema:name"] = "STEMgraph API"
    data["generatedBy"]["schema:url"] = "https://github.com/STEMgraph/API"
    data["generatedAt"] = now()


# lightweight and error functions

def now():
    """Gets the current timestamp."""
    return datetime.utcnow().isoformat()

def error_noEx404(uuid):
    """Returns customized file not found error message."""
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"error": f"Exercise '{uuid}' not found."}
    )

def error_noKey404(keyword):
    """Returns customized keyword not found error message."""
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"error": f"No exercises found for keyword '{keyword}'"}
    )
