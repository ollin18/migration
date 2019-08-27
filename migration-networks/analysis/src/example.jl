using Pkg
function useit(list::Array{Symbol})
        installed = [key for key in keys(Pkg.installed())]
        strpackages = @. string(list)
        uninstalled = setdiff(strpackages,installed)

        map(Pkg.add,uninstalled)
        for package ∈ list
            @eval using $package
        end
end

packages = [:OhMyREPL, :RCall, :SNAPDatasets, :Clustering, :LightGraphs, :SimpleWeightedGraphs, :Random, :GraphPlot, :Colors, :Plots, :GraphRecipes, :Statistics, :LinearAlgebra, :Arpack, :Neo4j, :RCall, :DataFrames, :StatsPlots,:PlotlyJS]
useit(packages)
include("temp_correlation.jl")
include("readgraph.jl")

c = Connection("localhost";user="neo4j", password="")

year = 2010

query = """
MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries)
RETURN DISTINCT toInt(s.Year) as Year ORDER BY Year
"""

results = cypherQuery(c, query)

query2 = "MATCH (c :Countries) RETURN c.Country as Country"

results2 = cypherQuery(c, query2)

query3 = "MATCH ()<-[s :SEEKERS]-(from :Countries) WHERE s.Year='$year' RETURN SUM(toInt(s.Applied)) as Total, from.Country as From ORDER BY Total desc"

results3 = cypherQuery(c, query3)

query4 = """
MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries)
WHERE s.Year='$year' AND toInt(s.Applied) > 0
WITH point({ longitude: toFloat(from.lon), latitude: toFloat(from.lat)}) AS p1,
    point({ latitude: toFloat(to.lat), longitude: toFloat(to.lon)}) AS p2, to, s, from
WITH from.Country AS From, to.Country as To, sum(toInt(s.Applied)) as Count, round(distance(p1,p2)) as Dist
RETURN From, To, Count, Dist
ORDER BY Count DESC
"""

results4 = cypherQuery(c, query4)

df = join(results3, results4, on = :From)

df[:Count] = df[:Count]./df[:Total]
df[:Dist] = df[:Dist]./maximum(df[:Dist])
df[:weight] = df[:Count].*df[:Dist]
results = filter(x -> x[:weight] > 0, df)


q = """
MATCH (c :Countries)
RETURN c.Country as C, (c.\`'2000'\`) as pop
"""
cypherQuery(c, q) |>
        x -> x[:pop]






function net_year(year;weighted=true)
    year=year
    query = """
    MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries)
    WHERE s.Year='$year' AND toInt(s.Applied) > 0
    WITH point({ longitude: toFloat(from.lon), latitude: toFloat(from.lat)}) AS p1,
        point({ latitude: toFloat(to.lat), longitude: toFloat(to.lon)}) AS p2, to, s, from
    WITH from.Country AS From, to.Country as To, sum(toInt(s.Applied)) as Count, round(distance(p1,p2)) as Dist
    RETURN From, To, Count, Dist
    ORDER BY Count DESC
    """

    query2 = "MATCH ()<-[s :SEEKERS]-(from :Countries) WHERE s.Year='$year' RETURN SUM(toInt(s.Applied)) as Total, from.Country as From ORDER BY Total desc"
    results = cypherQuery(c, query)
    results2 = cypherQuery(c, query2)
    df = join(results, results2, on = :From)
    df[:Count] = df[:Count]./df[:Total]
    df[:Dist] = df[:Dist]./maximum(df[:Dist])
    df[:weight] = df[:Count].*df[:Dist]
    results = filter(x -> x[:weight] > 0, df)
    if weighted
        g, Nodes, dic_nodes = lectura(results,:weight,Countries)
    else
        g, Nodes, dic_nodes = lectura_unw(results,Countries)
    end
    g, Nodes, dic_nodes
end



