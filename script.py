import networkx as nx
import osmnx as ox
import os.path

def getLocation(name):
    y,x = ox.geocoder.geocode(name)
    return x, y

def getOrLoadMap(name):
    if os.path.isfile("maps/" + name):
        return ox.load_graphml("maps/" + name)
    G = ox.graph_from_place(name, network_type="all", simplify=False)
    ox.save_graphml(G, "maps/" + name)
    return G

def lengthBetweenNodes(fromNode, toNode):
    node1 = G.nodes[fromNode]
    x1 = node1['x']
    y1 = node1['y']
    node2 = G.nodes[toNode]
    x2 = node2['x']
    y2 = node2['y']
    return ox.distance.great_circle(y1, x1, y2, x2)

def weightFun(fromNode, toNode, dicts):
    banned = ['motorway', 'trunk', 'primary', 'motorway_link', 'trunk_link', 'bus_guideway', 'busway']
    return None if dicts.get('highway', '') in banned and dicts.get('length', lengthBetweenNodes(fromNode, toNode)) > 10 else dicts.get('length', lengthBetweenNodes(fromNode, toNode))

G = getOrLoadMap(input("Pass map: "))
#fig, ax = ox.plot_graph(G, node_color="r")

while True:
    print("-----------")
    nodeA = ox.distance.nearest_nodes(G, *getLocation(input("Pass first loc: ")))
    nodeB = ox.distance.nearest_nodes(G, *getLocation(input("Pass second loc: ")))
    nodes = nx.astar_path(G, nodeA, nodeB, weight=weightFun)
#    for node in nodes:
#        print(G[node])
    ox.plot_graph_route(G, nodes, 'r')

