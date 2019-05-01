using SimpleWeightedGraphs
using LightGraphs

function lectura(red,weight,set)
    Nodes = sort(union(union(unique(red.From),unique(red.To)),set))
    dic_nodes = Dict{String,Int64}(Dict(Nodes[i]=>i for i in 1:length(Nodes)))
    g = SimpleWeightedDiGraph()
    last_node = Int64(length(Nodes))
    add_vertices!(g,last_node)
    for n in 1:nrow(red)
        add_edge!(g,dic_nodes[red[n,1]],dic_nodes[red[n,2]],red[n,weight])
    end
    return g, Nodes, dic_nodes
end

function lectura_backbone(red,set)
    Nodes = sort(union(union(unique(red.from),unique(red.to)),set))
    dic_nodes = Dict{String,Int64}(Dict(Nodes[i]=>i for i in 1:length(Nodes)))
    g = SimpleWeightedDiGraph()
    last_node = Int64(length(Nodes))
    add_vertices!(g,last_node)
    for n in 1:nrow(red)
        add_edge!(g,dic_nodes[red[n,:from]],dic_nodes[red[n,:to]],red[n,:weight])
    end
    return g, Nodes, dic_nodes
end

function lectura_unw(red,set)
    Nodes = sort(union(union(unique(red.From),unique(red.To)),set))
    dic_nodes = Dict{String,Int64}(Dict(Nodes[i]=>i for i in 1:length(Nodes)))
    g = SimpleDiGraph()
    last_node = Int64(length(Nodes))
    add_vertices!(g,last_node)
    for n in 1:nrow(red)
        add_edge!(g,dic_nodes[red[n,1]],dic_nodes[red[n,2]])
    end
    return g, Nodes, dic_nodes
end
