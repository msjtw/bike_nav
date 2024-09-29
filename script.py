# ruff: noqa: N802, N803, N806
import os.path
from functools import partial

import networkx as nx
import osmnx as ox
from networkx import MultiDiGraph
from osmnx import distance  # it has weird imports


def getLocation(name):
    y,x = ox.geocode(name)
    return x, y

def getOrLoadMap(name) -> MultiDiGraph:
    if os.path.isfile("maps/" + name):
        return ox.load_graphml("maps/" + name)
    G = ox.graph_from_place(name, network_type="all", simplify=False)
    if not isinstance(G, MultiDiGraph):
        raise Exception("Not a MultiDiGraph")
    ox.save_graphml(G, "maps/" + name)
    return G


def lengthBetweenNodes(G: MultiDiGraph, fromNode, toNode):
    node1 = G.nodes[fromNode]
    x1 = node1["x"]
    y1 = node1["y"]
    node2 = G.nodes[toNode]
    x2 = node2["x"]
    y2 = node2["y"]
    return distance.great_circle(y1, x1, y2, x2)


def weightFun(G: MultiDiGraph, fromNode, toNode, dicts, *, allowedLength=10):
    banned = [
        "motorway",
        "trunk",
        "primary",
        "motorway_link",
        "trunk_link",
        "bus_guideway",
        "busway",
    ]
    length = dicts.get("length", lengthBetweenNodes(G, fromNode, toNode))
    if dicts.get("highway", "") in banned and length > allowedLength:
        return None
    return length


def getPath(city: str, start: str, end: str) -> list[list[float]]:
    G = getOrLoadMap(city)
    nodeA = distance.nearest_nodes(G, *getLocation(start))
    nodeB = distance.nearest_nodes(G, *getLocation(end))
    nodes = nx.astar_path(G, nodeA, nodeB, weight=partial(weightFun, G)) # type: ignore
    path: list[list[float]] = []
    for node in nodes:
        x, y = G.nodes[node]["x"], G.nodes[node]["y"]
        path.append([x, y])
    return path


def main():
    while True:
        G = getOrLoadMap(input("Pass map: "))
        #fig, ax = ox.plot_graph(G, node_color="r")
        print("-----------")
        nodeA = distance.nearest_nodes(G, *getLocation(input("Pass first loc: ")))
        nodeB = distance.nearest_nodes(G, *getLocation(input("Pass second loc: ")))
        nodes = nx.astar_path(G, nodeA, nodeB, weight=partial(weightFun, G)) # type: ignore
        for node in nodes:
            x, y = G.nodes[node]["x"], G.nodes[node]["y"]
            print([x, y], end=", ")
        ox.plot_graph_route(G, nodes, "r")


if __name__ == "__main__":
    main()
