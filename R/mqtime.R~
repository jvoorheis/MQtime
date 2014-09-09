#mqtime in R
mqtime<-function(address1, address2, km=F, full=F){
  require(RCurl)
  require(rjson)
  if (address1=="Georgia"){
    address1="Atlanta,Georgia"
  }
  if (address2=="Georgia"){
    address2="Atlanta,Georgia"
  }
  URL2 = paste("http://open.mapquestapi.com/directions/v1/route?key=",
               "Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from=",  address1, "&to=", address2, "&outFormat='json'", 
               "boundingBox=24,-85,50,-125", sep="")
  URL2<-gsub(" ", "+", URL2)
  x = getURL(URL2)
  x1 <- fromJSON(x)
  if (length(x1$route$distance)==0){
    return(NA)
  }
  if (full==F){
    return(c("Time"=x1$route$time, "Distance"=x1$route$distance, "fuelUsed"=x1$route$fuelUsed))
  }
  else{
    return(x1)
  }
}
try1<-mqtime("Atlanta, Georgia", "Newark, NJ")



URL1 <- "http://open.mapquestapi.com/directions/v2/routematrix?key=Fmjtd%7Cluub2huanl%2C20%3Do5-9uzwdz&from=Detroit,MI&to=Atlanta,GA&to=Athens,GA&allToAll=True"
x <- getURL(URL1)
x <- fromJSON(x)
