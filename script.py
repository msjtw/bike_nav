import networkx as nx
import osmnx as ox

print(ox.__version__)

G = ox.graph_from_place("Rogoźno, 64-610, Poland", network_type="bike")
#fig, ax = ox.plot_graph(G, node_color="r")

nodeA = ox.distance.nearest_nodes(G, 16.99249, 52.75207)
nodeB = ox.distance.nearest_nodes(G, 16.97167, 52.75430)
nodes = nx.astar_path(G, nodeA, nodeB, weight="length")
ox.plot_graph_route(G, nodes, 'r')


