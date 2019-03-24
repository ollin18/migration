---
title: "R Notebook"
output: html_notebook
---

```{r,echo=FALSE,warning=FALSE,include=FALSE}
paquetines <- c("stringi","reshape2","plyr","dplyr","tidyr","sets","plotly","readr",
                "ggplot2","lubridate","e1071","useful","magrittr","gower","cluster","RNeo4j",
                "factoextra","NbClust","readr","DescTools","gridExtra","egg")
no_instalados <- paquetines[!(paquetines %in% installed.packages()[,"Package"])]
if(length(no_instalados)) install.packages(no_instalados)
lapply(paquetines, library, character.only = TRUE)
```


```{r}
graph = startGraph('http://localhost:7474/db/data/')

query <- '
MATCH (c :Countries) RETURN DISTINCT c.Country AS Country ORDER BY Country
'
countries <- cypher(graph,query)

countries
```

```{r}
hm <- function(year){
  query <- paste0('
  MATCH (to :Countries) <-[s :SEEKERS]-(from :Countries)
  WHERE s.Year="',year,'"
  RETURN to.Country AS To, from.Country as From, s.Applied as Count
  ORDER BY To
  ')
  
  the_year <- cypher(graph,query)
  the_year$Count <- as.integer(the_year$Count)

  f <- unique(countries[!countries$Country %in% unique(the_year$From),])
  t <- unique(countries[!countries$Country %in% unique(the_year$To),])
  
  the_year <- the_year %>%
    rbind(data.frame(To=t,From=t,Count=rep(0,length(t)))) %>%
    rbind(data.frame(To=f,From=f,Count=rep(0,length(f))))

  p<-ggplot(the_year,aes(x=From,y=To))+
    geom_tile(aes(fill=log10(Count)))+
    scale_fill_gradient(low="white",high="blue",na.value="grey50")+
    ggtitle(year)+
    theme(axis.text.x = element_text(size = 1, angle = 45, hjust = 1),
          axis.text.y = element_text(size = 1)) +
    coord_fixed(ratio = 1)
  wh<-paste0("./figs/",year,".png")
  ggsave(wh,p)
  p
}
```


```{r}
hm("2010")
```
![](./figs/2010.png)

```{r}
hm("2011")
```
![](./figs/2011.png)

```{r}
hm("2012")
```

![](./figs/2012.png)



```{r}
hm("2013")
```

![](./figs/2013.png)

```{r}
hm("2014")
```

![](./figs/2014.png)


```{r}
hm("2015")
```

![](./figs/2015.png)

```{r}
hm("2016")
```

![](./figs/2016.png)

```{r}
hm("2017")
```

![](./figs/2017.png)



















