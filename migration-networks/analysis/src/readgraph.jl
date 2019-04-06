using SimpleWeightedGraphs
using LightGraphs

function lectura(red)
    Nodes = union(unique(red.From),unique(red.To))
    dic_nodes = Dict{String,Int64}(Dict(Nodes[i]=>i for i in 1:length(Nodes)))
    g = SimpleWeightedDiGraph()
    last_node = Int64(length(Nodes))
    add_vertices!(g,last_node)
    for n in 1:nrow(red)
        add_edge!(g,dic_nodes[red[n,1]],dic_nodes[red[n,2]],red[n,3])
    end
    return g, Nodes, dic_nodes
end

function lectura_unw(red)
    Nodes = union(unique(red.From),unique(red.To))
    dic_nodes = Dict{String,Int64}(Dict(Nodes[i]=>i for i in 1:length(Nodes)))
    g = SimpleDiGraph()
    last_node = Int64(length(Nodes))
    add_vertices!(g,last_node)
    for n in 1:nrow(red)
        add_edge!(g,dic_nodes[red[n,1]],dic_nodes[red[n,2]])
    end
    return g, Nodes, dic_nodes
end
