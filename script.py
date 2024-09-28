import networkx as nx
import osmnx as ox

print(ox.__version__)

# download/model a street network for some city then visualize it
G = ox.graph_from_place("Rogoźno, 64-610, Poland", network_type="bike", simplify=False)
print("Downloaded")

# convert your MultiDiGraph to a DiGraph without parallel edges
D = ox.convert.to_digraph(G)
print("Converted to DiGraph")

# what sized area does our network cover in square meters?
G_proj = ox.project_graph(G)
nodes_proj = ox.graph_to_gdfs(G_proj, edges=False)
graph_area_m = nodes_proj.unary_union.convex_hull.area
print(f"Size {graph_area_m}")

# convert graph to line graph so edges become nodes and vice versa
edge_centrality = nx.closeness_centrality(nx.line_graph(G))
nx.set_edge_attributes(G, edge_centrality, "edge_centrality")
print("Converted to line graph")

# color edges in original graph with closeness centralities from line graph
ec = ox.plot.get_edge_colors_by_attr(G, "edge_centrality", cmap="inferno")
fig, ax = ox.plot_graph(G, edge_color=ec, edge_linewidth=2, node_size=0)
