using Pkg
ENV["PLOTS_USE_ATOM_PLOTPANE"] = "false"
function useit(list::Array{Symbol})
        installed = [key for key in keys(Pkg.installed())]
        strpackages = @. string(list)
        uninstalled = setdiff(strpackages,installed)

        map(Pkg.add,uninstalled)
        for package ∈ list
            @eval using $package
        end
end

packages = [:OhMyREPL, :SNAPDatasets, :Clustering, :LightGraphs, :SimpleWeightedGraphs, :Random, :GraphPlot, :Plots, :GraphRecipes, :Statistics, :LinearAlgebra, :Arpack, :Neo4j, :RCall, :DataFrames, :StatsPlots,:Missings]
useit(packages)

c = Connection("localhost";user="neo4j", password="")

year = 2015

query = "MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries) WHERE s.Year='$year' RETURN DISTINCT from.Country AS From, to.Country as To, toInt(s.Applied) as Count ORDER BY To"

#  query = "MATCH (c :Countries) RETURN DISTINCT c.Country"

results = cypherQuery(c, query)
results = results[results.Count .> 0,:]
#  results.Count =results.Count/maximum(results.Count)
results.Count =log10.(results.Count)
results = results[results.Count .> 0,:]

g, Nodes, dic_nodes = lectura(results)
g1, Nodes, dic_nodes = lectura_unw(results)

gplot(g1)
draw(PNG("plotgraph.png"), gplot(g1,layout=spring_layout))





draw(PNG("plotgraphollin.png", 16cm, 16cm), gplot(g1,nodefillc=nodefillc,layout=spring_layout))


### Communities









