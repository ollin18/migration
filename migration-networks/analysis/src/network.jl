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

reval("""
paquetines <- c("stringi","reshape2","plyr","dplyr","tidyr","sets","plotly","readr","scales","data.table","plotly",
                "ggplot2","igraph","lubridate","e1071","useful","magrittr","gower","cluster","RNeo4j","disparityfilter",
                "factoextra","NbClust","readr","DescTools","gridExtra","egg","htmlwidgets")
no_instalados <- paquetines[!(paquetines %in% installed.packages()[,"Package"])]
if(length(no_instalados)) install.packages(no_instalados, repos='http://cran.us.r-project.org')
lapply(paquetines, library, character.only = TRUE)
""")

c = Connection("localhost";user="neo4j", password="")

year = 2010

#  MATCH (c :Countries) RETURN c.Country as C, c.\`'2000'\` as pop
#  MATCH (c :Countries) RETURN keys(c)
#  q = """
#  MATCH (c :Countries)
#  RETURN c.Country as C, (c.\`'2000'\`) as pop
#  """
#  cypherQuery(c, q) |>
#          x -> x[:pop]

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
    df[:weight] = df[:Count]#.*df[:Dist]
    results = filter(x -> x[:weight] > 0, df)
    if weighted
        g, Nodes, dic_nodes = lectura(results,:weight,Countries)
    else
        g, Nodes, dic_nodes = lectura_unw(results,Countries)
    end
    g, Nodes, dic_nodes
end

let
    global av_out = Array{Float64}(undef,length(Years)-1)
    global av_in = Array{Float64}(undef,length(Years)-1)
    global av_all = Array{Float64}(undef,length(Years)-1)
    global av_uw_out = Array{Float64}(undef,length(Years)-1)
    global av_uw_in = Array{Float64}(undef,length(Years)-1)
    global av_uw_all = Array{Float64}(undef,length(Years)-1)
    for year in enumerate(Years)
        if year[2] != maximum(Years)
            g1, Nodes, dic_nodes = net_year(year[2])
            g2, Nodes, dic_nodes = net_year(year[2]+1)
            av_out[year[1]] = average_topological_w(g1,g2;how=outdegree)
            av_in[year[1]] = average_topological_w(g1,g2;how=indegree)
            av_all[year[1]] = average_topological_w(g1,g2;how=degree)
            av_uw_out[year[1]] = average_topological(g1,g2;how=outdegree)
            av_uw_in[year[1]] = average_topological(g1,g2;how=indegree)
            av_uw_all[year[1]] = average_topological(g1,g2;how=degree)
        end
    end
    av_out,av_in,av_all,av_uw_in,av_uw_out,av_uw_all
end

function harm_mean(set)
    below = sum(@. 1/set)
    length(set)/below
end

function harm_mean(a,b)
    set = [a,b]
    below = sum(@. 1/set)
    length(set)/below
end

mean(av_uw_out)
mean(av_uw_in)
mean(av_uw_all)

mean(av_out)
mean(av_in)
mean(av_all)

broadcast(harm_mean,av_out,av_uw_out) |> mean
broadcast(harm_mean,av_in,av_uw_in) |> mean
broadcast(harm_mean,av_all,av_uw_all) |> mean

let
    global av_out = Array{Float64}(undef,length(Years)-1)
    global av_in = Array{Float64}(undef,length(Years)-1)
    global av_all = Array{Float64}(undef,length(Years)-1)
    global av_uw_out = Array{Float64}(undef,length(Years)-1)
    global av_uw_in = Array{Float64}(undef,length(Years)-1)
    global av_uw_all = Array{Float64}(undef,length(Years)-1)
    for year in enumerate(Years)
        if year[2] != maximum(Years)
            g1, Nodes, dic_nodes = net_year(year[2])
            g2, Nodes, dic_nodes = net_year(year[2]+1)
            av_out[year[1]] = average_topological_w(g1,g2;how=outdegree)
            av_in[year[1]] = average_topological_w(g1,g2;how=indegree)
            av_all[year[1]] = average_topological_w(g1,g2;how=degree)
            av_uw_out[year[1]] = average_topological(g1,g2;how=outdegree)
            av_uw_in[year[1]] = average_topological(g1,g2;how=indegree)
            av_uw_all[year[1]] = average_topological(g1,g2;how=degree)
        end
    end
    av_out,av_in,av_all,av_uw_in,av_uw_out,av_uw_all
end

g1, Nodes, dic_nodes = net_year(2015)
g2, Nodes, dic_nodes = net_year(2016)

outdeg = map(x-> topological_overlap_w(g1,g2,x;how=outdegree),vertices(g1)) |>
        x -> replace!(x,NaN=>1)

map(x-> topological_overlap_w(g1,g2,x),vertices(g1)) |>
        x -> replace!(x,NaN=>0)

aaa = sortslices(hcat(Nodes,outdeg), dims=1,by=x->x[2],rev=true)
aaa[aaa[:,1] .== "Mexico",:]



let
    global co_out = Array{Array}(undef,length(Years)-1)
    global co_in = Array{Array}(undef,length(Years)-1)
    global co_all = Array{Array}(undef,length(Years)-1)
    global co_uw_out = Array{Array}(undef,length(Years)-1)
    global co_uw_in = Array{Array}(undef,length(Years)-1)
    global co_uw_all = Array{Array}(undef,length(Years)-1)
    for year in enumerate(Years)
        if year[2] != maximum(Years)
            g1, Nodes, dic_nodes = net_year(year[2])
            g2, Nodes, dic_nodes = net_year(year[2]+1)
            co_out[year[1]]    = map(x->topological_overlap_w(g1,g2,x;how=outdegree),vertices(g1))
            co_in[year[1]]     = map(x->topological_overlap_w(g1,g2,x;how=indegree),vertices(g1))
            co_all[year[1]]    = map(x->topological_overlap_w(g1,g2,x;how=degree),vertices(g1))
            co_uw_out[year[1]] = map(x->topological_overlap(g1,g2,x;how=outdegree),vertices(g1))
            co_uw_in[year[1]]  = map(x->topological_overlap(g1,g2,x;how=indegree),vertices(g1))
            co_uw_all[year[1]] = map(x->topological_overlap(g1,g2,x;how=degree),vertices(g1))
        end
    end
    co_out,co_in,co_all,co_uw_in,co_uw_out,co_uw_all
end

g1, Nodes, dic_nodes = net_year(2010)
histogram2d(randn(1000), randn(1000),nbins=20)
z = float((1:4) * reshape(1:10, 1, :))
Yearss = Years[2:end]
vals = transpose(hcat(co_out...))
valss = transpose(hcat(co_in...))

nona = vals |> x -> filter(x,!isnan)
#  vals2 = vals |>
#  mean_top = mean(vals[isnan.(vals)],dims=1)
mean_top1 = sum(vals,dims=1)./17
mean_top2 = sum(valss,dims=1)./17
mean_top = vcat(mean_top1,mean_top2)

Countries = Nodes
@rput Countries
@rput Yearss
@rput vals
@rput mean_top

reval("""
      valores <- data.frame(vals)
      rownames(valores)<-Yearss
      colnames(valores)<-Countries

      valores2 <- data.frame(mean_top)
      rownames(valores2) <- c("Outdegree","Indegree")
      colnames(valores2) <- Countries
      """)

reval("setDT(valores,keep.rownames=TRUE)")
reval("setDT(valores2,keep.rownames=TRUE)")
reval("valores\$rn[1:3]")
reval("valores.m <- melt(valores)")
reval("valores2.m <- melt(valores2)")
reval("colnames(valores.m)<-c('Year','Country','Correlation')")
reval("colnames(valores2.m)<-c('Overlap','Country','Correlation')")

reval("""
      p<-ggplot(valores.m,aes(Year,Country)) +
      geom_tile(aes(fill=Correlation),color="white")+
      ggtitle("Topological Overlap Indegree")+
      scale_fill_gradient(low = "lightblue",high = "darkblue",na.value="black",limits=c(0,1))+
      theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1, colour = "grey50"),
      axis.text.y = element_text(size = 4, angle = 45, hjust = 1, colour = "grey50"))
      ggsave("/home/ollin/Documentos/migration/migration-networks/analysis/figs/topological_overlap_in_nodist.pdf")
      ggp <- ggplotly(p) %>% config(displayModeBar = F)
      ggp_build <- plotly_build(ggp)
      htmlwidgets::saveWidget(as_widget(ggp_build), "/home/ollin/Documentos/migration/migration-networks/analysis/figs/topological_overlap_in_nodist.html")

      #  p2<-ggplot(valores2.m,aes(Overlap,Country)) +
      #  geom_tile(aes(fill=Correlation),color="white")+
      #  ggtitle("Mean Topological Overlap")+
      #  scale_fill_gradient(low = "lightblue",high = "darkblue",na.value="black",limits=c(0,1))+
      #  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1, colour = "grey50"),
      #  axis.text.y = element_text(size = 4, angle = 45, hjust = 1, colour = "grey50"))
      #  ggsave("/home/ollin/Documentos/migration/migration-networks/analysis/figs/mean_topological_overlap_nodist.pdf")
      #  ggp <- ggplotly(p2) %>% config(displayModeBar = F)
      #  ggp_build <- plotly_build(ggp)
      #  htmlwidgets::saveWidget(as_widget(ggp_build), "/home/ollin/Documentos/migration/migration-networks/analysis/figs/mean_topological_overlap_nodist.html")
      """)

vals
Years[1:end-1]
heatmap(Countries,Years[1:end-1],vals,color=:blues)

plotlyjs()
pyplot()

heatmap(Years[2:end],Countries,vals',color=:blues,yticks=1:247,ylabel=Countries)#,xticks = Years[2:end],xrotation=45)
heatmap(Years[2:end],Countries,vals',color=:blues,xticks=Years[2:end],xrotation=45)
plot!(xticks = Years[2:end],xtickfont = font(8,"Courier"),xrotation=45)
plot!(yticks = Countries)#,ytickfont = font(1,"Courier"))


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










