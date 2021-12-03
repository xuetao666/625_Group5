##########Clean up and import package:

rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")

x<-c("plyr","dplyr", "haven")

new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


lapply(x, require, character.only=T)
coalesce <- function(...) {
  apply(cbind(...), 1, function(x) {
    x[which(!is.na(x))[1]]
  })
}

##########################
#set macros:
workpath<-"C:/Users/xueti/Dropbox (University of Michigan)/Umich/class/term 1/625/Final"
datapath<-"C:/Users/xueti/Dropbox (University of Michigan)/Umich/class/term 1/625/Final/Data/Demographics"
date<-gsub("-","_",Sys.Date())

#########################
#set path and create result folder, import data:
setwd(datapath)
clist=c("","_B","_c","_D","_E","_F","_G","_H","_I","_J")



for(i in 1:length(clist)){
  demo_temp=read_xpt(paste0("DEMO",clist[i],".XPT"),
    col_select = NULL,
    skip = 0,
    n_max = Inf,
    .name_repair = "unique"
  )
  demo_temp$year=clist[i]
  if(i!=1){
    demo=bind_rows(demo,demo_temp)
  } else {
    demo=demo_temp
  }
}


sum(duplicated(demo$SEQN))
