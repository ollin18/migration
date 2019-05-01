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

packages = [:OhMyREPL, :RCall, :SNAPDatasets, :Clustering, :LightGraphs, :SimpleWeightedGraphs, :Random, :GraphPlot, :Colors, :Plots, :GraphRecipes, :Statistics, :LinearAlgebra, :Arpack, :Neo4j, :RCall, :DataFrames, :StatsPlots]
useit(packages)

reval("""
paquetines <- c("stringi","reshape2","plyr","dplyr","tidyr","sets","plotly","readr",
                "ggplot2","igraph","lubridate","e1071","useful","magrittr","gower","cluster","RNeo4j","disparityfilter",
                "factoextra","NbClust","readr","DescTools","gridExtra","egg")
no_instalados <- paquetines[!(paquetines %in% installed.packages()[,"Package"])]
if(length(no_instalados)) install.packages(no_instalados, repos='http://cran.us.r-project.org')
lapply(paquetines, library, character.only = TRUE)
""")

c = Connection("localhost";user="neo4j", password="")

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

query3 = "MATCH (c :Countries) RETURN c.Country as Country"

query4 = """
MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries)
RETURN DISTINCT toInt(s.Year) as Year ORDER BY Year
"""

results3 = cypherQuery(c, query3)
results4 = cypherQuery(c, query4)
Countries = results3[:Country]
Years = results4[:Year]

function net_year(year)
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
    g, Nodes, dic_nodes = lectura_unw(results,Countries)
    g, Nodes, dic_nodes
end


for year in Years
    if year != maximum(Years)
        g1, Nodes, dic_nodes = net_year(year)
        g2, Nodes, dic_nodes = net_year(year+1)
    end
    average_topological(g1,g2;how=outdegree)
end



#  results = filter(x -> x[:Count] > 0, df)
#  asdf = bb[nonunique(bb[:, filter(x -> !(x in [:weight,:alpha]), names(bb))]),:]
#  filter(x -> x[:from]=="1",bb)
#  filter(x -> x[:to]=="1",bb)
#  results[nonunique(results[:, filter(x -> !(x in [:Count]), names(results))]),:]

g, Nodes, dic_nodes = lectura(results,:weight,Countries)
g1, Nodes, dic_nodes = lectura_unw(results,Countries)
#  g2, Nodes, dic_nodes = lectura_unw(results,Countries)

average_topological(g1,g2;how=outdegree)


@rput results
@rput df

reval("gg <- graph_from_data_frame(results,directed=TRUE)")
reval("renamed <- set.vertex.attribute(gg, 'name', value=1:length(V(gg)))")
reval("wei <- E(gg)\$weight")
reval("bb <- backbone(renamed,weights=wei,directed=TRUE,alpha=0.05)")
reval("gg <- graph_from_data_frame(bb,directed=TRUE)")
reval("wei <- E(gg)\$weight")
@rget bb

reval("cl <- cluster_infomap(gg,e.weights=wei)")
@rget cl
clus = Int64.(cl[:membership])

reval("ggl <- graph_from_data_frame(bb,directed=FALSE)")
reval("cll <- cluster_louvain(ggl,weights=wei)")
@rget cll
clus_lou = Int64.(cll[:membership])

g2, Nodesn, dic_nodes = lectura_backbone(bb)
Nodesn = @. parse(Int64,Nodesn)
Nodes = Nodes[Nodesn]

graphplot(g2,method=:stress,nodelabel=Nodes)

com = communities(g2)
#  com = communities(g2;matrix=ollin_reluctant)
#  com = communities(g2;matrix=flux_matrix)
unique(com)

#  Nodes[findall(x->x==1,com)]
#  Nodes[findall(x->x==2,com)]
#  Nodes[findall(x->x==3,com)]
#  Nodes[findall(x->x==4,com)]
#  filter(x -> x[:From] == "Ireland", results)
#  filter(x -> x[:To] == "Ireland", results)

#  membership = com
#  membership = clus
membership = clus_lou

nodecolor = distinguishable_colors(length(unique(membership)))
nodefillc =  nodecolor[membership]

graphplot(g2,method=:stress,markercolor=nodefillc)
graphplot(g2,method=:spring,markercolor=nodefillc)













widedf = unstack(results, :From, :To, :Count)

@df widedf heatmap(:From, :To, aspect_ratio=1)

savefig("/figs/2010_heatmap.png")

heatmap(widedf.From, widedf.To, , aspect_ratio=1)










