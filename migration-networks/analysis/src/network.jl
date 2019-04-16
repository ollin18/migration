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

c = Connection("localhost";user="neo4j", password="")
#  c = Connection("localhost")

year = 2015

query = """
MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries)
WHERE s.Year='$year' AND toInt(s.Applied) > 0
WITH point({ longitude: toFloat(from.lon), latitude: toFloat(from.lat)}) AS p1,
    point({ latitude: toFloat(to.lat), longitude: toFloat(to.lon)}) AS p2, to, s, from
RETURN from.Country AS From, to.Country as To, sum(toInt(s.Applied)) as Count, round(distance(p1,p2)) as Dist
ORDER BY Count DESC
"""

query2 = "MATCH ()<-[s :SEEKERS]-(from :Countries) WHERE s.Year='$year' RETURN SUM(toInt(s.Applied)) as Total, from.Country as From ORDER BY Total desc"

#  query = "MATCH (c1 :Countries) MATCH (c2 :Countries) WHERE s.Year='$year' WITH c1, c2 sum(toInt((c1)-[s.Applied :SEEKERS]->())) AS Total, sum(toInt((c1)-[s.Applied :SEEKERS]->(c2))) AS Fraction WITH c1, c2, Total, Fraction, Fraction/Total AS Proportion RETURN c1.Country as From, c2.Country AS To, Proportion"
#
#  query = "MATCH () <-[s :SEEKERS]-(from :Countries) WHERE s.Year='$year' AND toInt(s.Applied) > 0 MATCH (to :Countries)<-[s1 :SEEKERS]-(from) RETURN sum(toInt(s1.Applied) as Ap from.Country as From"
#
#  query = "MATCH (c :Countries {Country:'DR Congo'}) RETURN c.`'$year'`"
#  query = "MATCH (c :Countries) WHERE c.`'$year'` is NULL return c.Country as Country, c.`'$year'` as Pop"


#  query = "MATCH (c :Countries) RETURN DISTINCT c.Country"

results = cypherQuery(c, query)
results2 = cypherQuery(c, query2)

df = join(results, results2, on = :From)
df[:Count] = df[:Count]./df[:Total]

results = filter(x -> x[:Count] > 0, df)
#  results = filter(x -> log10(x[:Count]) > 0, results)
#  results[:Count] = log10.(results[:Count])
asdf = bb[nonunique(bb[:, filter(x -> !(x in [:weight,:alpha]), names(bb))]),:]
filter(x -> x[:from]=="1",bb)
filter(x -> x[:to]=="1",bb)
results[nonunique(results[:, filter(x -> !(x in [:Count]), names(results))]),:]

g, Nodes, dic_nodes = lectura(results)
g1, Nodes, dic_nodes = lectura_unw(results)
g2, Nodesn, dic_nodes = lectura_backbone(bb)
Nodesn = @. parse(Int64,Nodesn)
#  Nodesn = map(x->dic_nodes[x],Nodesn)
Nodes = Nodes[Nodesn]

com = communities(g2)
com = communities(g2;matrix=ollin_reluctant)
com = communities(g2;matrix=flux_matrix)
unique(com)

com = clus

Nodes[findall(x->x==1,com)]
Nodes[findall(x->x==2,com)]
Nodes[findall(x->x==3,com)]
Nodes[findall(x->x==4,com)]
filter(x -> x[:From] == "Ireland", results)
filter(x -> x[:To] == "Ireland", results)

membership = com
membership = clus
#  nodecolor = [colorant"red",colorant"yellow",colorant"blue",colorant"violet",colorant"orange",colorant"green"]
nodecolor = distinguishable_colors(length(unique(membership)))
nodefillc =  nodecolor[membership]


#  graphplot(g)
graphplot(g2,method=:stress,markercolor=nodefillc)
graphplot(g2,method=:spring,markercolor=nodefillc)





@rput results

reval("""
paquetines <- c("stringi","reshape2","plyr","dplyr","tidyr","sets","plotly","readr",
                "ggplot2","igraph","lubridate","e1071","useful","magrittr","gower","cluster","RNeo4j","disparityfilter",
                "factoextra","NbClust","readr","DescTools","gridExtra","egg")
no_instalados <- paquetines[!(paquetines %in% installed.packages()[,"Package"])]
if(length(no_instalados)) install.packages(no_instalados, repos='http://cran.us.r-project.org')
lapply(paquetines, library, character.only = TRUE)
""")

#  reval("results\$Count <- results\$Count/max(results\$Count)")
reval("gg <- graph_from_data_frame(results,directed=TRUE)")
reval("renamed <- set.vertex.attribute(gg, 'name', value=1:length(V(gg)))")
reval("wei <- E(gg)\$Count")
reval("bb <- backbone(renamed,weights=wei,directed=TRUE,alpha=0.005)")
reval("gg <- graph_from_data_frame(bb,directed=TRUE)")
reval("wei <- E(gg)\$weight")
@rget bb


reval("cl <- cluster_infomap(gg,e.weights=wei)")
@rget cl
clus = Int64.(cl[:membership])

Nodes[findall(x->x==1,clus)]
Nodes[findall(x->x==2,clus)]
Nodes[findall(x->x==3,clus)]
Nodes[findall(x->x==4,clus)]
Nodes[findall(x->x==5,clus)]
Nodes[findall(x->x==6,clus)]
Nodes[findall(x->x==7,clus)]
Nodes[findall(x->x==8,clus)]
Nodes[findall(x->x==9,clus)]
Nodes[findall(x->x==10,clus)]
Nodes[findall(x->x==11,clus)]
Nodes[findall(x->x==12,clus)]
Nodes[findall(x->x==13,clus)]
Nodes[findall(x->x==14,clus)]
Nodes[findall(x->x==15,clus)]
Nodes[findall(x->x==16,clus)]

reval("ggl <- graph_from_data_frame(bb,directed=FALSE)")
reval("cll <- cluster_louvain(ggl,weights=wei)")
@rget cll
clus = Int64.(cll[:membership])

Nodes[findall(x->x==1,clus)]
Nodes[findall(x->x==2,clus)]
Nodes[findall(x->x==3,clus)]
Nodes[findall(x->x==4,clus)]








widedf = unstack(results, :From, :To, :Count)

@df widedf heatmap(:From, :To, aspect_ratio=1)

savefig("/figs/2010_heatmap.png")

heatmap(widedf.From, widedf.To, , aspect_ratio=1)










