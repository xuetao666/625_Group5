###Raw data file:
###This file was used to merge and clean the raw data, since the raw data is large and mess, we didn't put it into the github
##Data result goes to Results/Data

##########Clean up and import package:
rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("plyr","dplyr", "haven","stringi","stringr")
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
workpath<-"C:/Users/xueti/Dropbox (University of Michigan)/Umich/class/term 1/625/Final/625_Group5/625_Group5/Results/Data"
datapath<-"C:/Users/xueti/Dropbox (University of Michigan)/Umich/class/term 1/625/Final/Data"
date<-gsub("-","_",Sys.Date())
#########################
#set path and create result folder, import data:
#---------------------Step1. Import and merge the data-------------------------
#-------------------------------------------------------------------------------
setwd(datapath)
##Demographic:
#--------------------------------
setwd("Demographics")
demo_data=data.frame()
yearList=list.files()
for(year in yearList){ ##Get into year
  #For demo:
  if(stri_detect_fixed(year,".XPT")){
    df=read_xpt(year)
    df$year=str_remove(year,".XPT")
    #Drop weighted variables:
    if(nrow(demo_data)==0){
      demo_data=df
    } else {
      demo_data=bind_rows(demo_data,df) 
    }
  }
}
setwd('..')
name1=colnames(demo_data)
name1=name1[!stri_detect_fixed(name1,"WTMREP")]
name1=name1[!stri_detect_fixed(name1,"WTIREP")]
demo_data=demo_data[,colnames(demo_data) %in% name1]
#Diatery:
#--------------------------------
setwd("Diatery")
#"DRXFMT.XPT": FOOD CODE, NOT RELATED TO INDIVIDUAL DATA:
#"DRXIFF.XPT": Long data, information in DRXTOT, drop
#"DSQFILE2.XPT":have suppliment ID, not useful, drop
fileRdList=c("DRXTOT","DSQFILE1","DR1TOT","DSQ1")
dia_data=data.frame()
yearList=list.files()
for(year in yearList){ ##Get into year
 #For others:
  print(year)
  tempdata=data.frame()
  setwd(year)
  fileList=list.files()
  for(f in fileList){
    if(sum(stri_detect_fixed(f,fileRdList))!=0){ #Exclude some code book data
      df=read_xpt(f)
      print(f)
      if(nrow(tempdata)==0){
        tempdata=df
      } else {
        tempdata=full_join(tempdata,df,by="SEQN") 
      }
    }
  }
  if(nrow(dia_data)!=0){
    dia_data=bind_rows(dia_data,tempdata)
  } else {
    dia_data=tempdata
  }
  setwd('..')
}
sum(duplicated(dia_data$SEQN))
setwd('..')
#Examination
#--------------------------------
#Hearing, only use the first file for useful information
setwd("Examination")
fileRdList=c("AUX","BPX","BMX","VIX")
fileNolist=c("AUXWBR","AUXAR","AUXTYM")
exam_data=data.frame()
yearList=list.files()
for(year in yearList){ ##Get into year
  #For others:
  print(year)
  tempdata=data.frame()
  setwd(year)
  fileList=list.files()
  for(f in fileList){
    if(sum(stri_detect_fixed(f,fileRdList))!=0 & sum(stri_detect_fixed(f,fileNolist))==0){ #Exclude some code book data
      df=read_xpt(f)
      print(f)
      print(sum(duplicated(df$SEQN)))
      if(nrow(tempdata)==0){
        tempdata=df
      } else {
        tempdata=full_join(tempdata,df,by="SEQN") 
      }
    }
  }
  if(nrow(exam_data)!=0){
    exam_data=bind_rows(exam_data,tempdata)
  } else {
    exam_data=tempdata
  }
  setwd('..')
}
sum(duplicated(exam_data$SEQN))
setwd('..')
#Questionnaires
#--------------------------------
#Hearing, only use the first file for useful information
setwd("Questionnaires")
fileRdList=c("ACQ","ALQ","AUQ","BPQ","CDQ","CBQ","HSQ","DEQ","DIQ","DBQ","DUQ",
             "FCQ","FSQ","HIQ","HUQ","HOQ","IMQ","KIQ","MCQ","CIQMDEP","OCQ",
             "OHQ","PUQ","PAQ","PFQ","RHQ","RDQ","SXQ","SMQMEC",
             "SMQFAM","SMQRTU","WHQ","WHQMEC")
fileNolist=c("PAQIAF")
ques_data=data.frame()
yearList=list.files()
for(year in yearList){ ##Get into year
  #For others:
  print(year)
  tempdata=data.frame()
  setwd(year)
  fileList=list.files()
  for(f in fileList){
    if(sum(stri_detect_fixed(f,fileRdList))!=0 & sum(stri_detect_fixed(f,fileNolist))==0){ #Exclude some code book data
      df=read_xpt(f)
      #REMOVE Other variables in the diabete file:
      if(stri_detect_fixed(f,"DIQ")){
        df=df[,colnames(df) %in% c("SEQN","DIQ010")]
      }
      if(sum(names(df) %in% "WTDRD1")!=0){
        print("st--------")
        print(f)
        print(year)
        print("----------------")
      }
      # print(f)
      # print(sum(duplicated(df$SEQN)))
      if(nrow(tempdata)==0){
        tempdata=df
      } else {
        tempdata=full_join(tempdata,df,by="SEQN") 
      }
    }
  }
  if(nrow(exam_data)!=0){
    ques_data=bind_rows(ques_data,tempdata)
  } else {
    ques_data=tempdata
  }
  setwd('..')
}
sum(duplicated(ques_data$SEQN))
setwd('..')
#Merge all data together:
#--------------------------------
all_data=full_join(demo_data,dia_data,by="SEQN")
names(all_data)
all_data=full_join(all_data,exam_data,by="SEQN")
names(all_data)
all_data=full_join(all_data,ques_data,by="SEQN")
names(all_data)
all_data$WTDRD1_x=ifelse(is.na(all_data$WTDRD1.x),all_data$WTDRD1.x.x,all_data$WTDRD1.x)
all_data$WTDRD1_y=ifelse(is.na(all_data$WTDRD1.y),all_data$WTDRD1.y.y,all_data$WTDRD1.y)
all_data$WTDRD1=ifelse(is.na(all_data$WTDRD1_x),all_data$WTDRD1_y,all_data$WTDRD1_x)
all_data$DBQ095=ifelse(is.na(all_data$DBQ095.x),all_data$DBQ095.y,all_data$DBQ095.x)
rmlist=c("WTDRD1.x","WTDRD1.y","WTDRD1.x.x",
         "WTDRD1.y.y","WTDRD1_x","WTDRD1_y","DBQ095.y",
         "DBQ095.x","SDMVPSU","WTDRD1","WTINT2YR","WTINT4YR","WTDR2D","WTMEC2YR",
         "WTMEC4YR","WTSAU4YR","WTSAU01","WTDR4YR","WTSCI2YR","WTSCI4YR")
all_data=all_data[,!names(all_data) %in% rmlist]
all_data=all_data[,!stri_detect_fixed(names(all_data),"WTSAU")]
all_data=all_data[,!stri_detect_fixed(names(all_data),"WTSCI")]
#Clean DIQ010
all_data$DIQ010 = ifelse(all_data$DIQ010 %in% c(7,9), NA, all_data$DIQ010)
all_data = all_data[!is.na(all_data$DIQ010),]
all_data$DIQ010 = ifelse(all_data$DIQ010 == 3, 1, all_data$DIQ010)
all_data$DIQ010 = ifelse(all_data$DIQ010 == 2, 0, all_data$DIQ010)
table(all_data$DIQ010) # Extremely Unbalanced
all_data$DIQ010 = as.factor(all_data$DIQ010)
all_data = all_data[,-1]
#Save data:
#--------------------------------
setwd(workpath)
#Save Overall
saveRDS(all_data,"AllData_v20211213_1.RDS")
#Save in year
Ylist=levels(as.factor(all_data$year))
for(year in Ylist){
  data=all_data[all_data$year==year,]
  na = colSums(is.na(data))/nrow(data)*100
  na=na[na<10]
  data=data[complete.cases(data[,names(na)]),names(na)]
  print(year)
  print(table(data$DIQ010))
  #Loop for factor names:
  varname=c("BMAAMP")
  for(varn in names(na)){
    if(length(levels(as.factor(data[[varn]])))==1){
      varname=c(varname,varn)
    }
  }
  print(varname)
  data=data[,!colnames(data) %in% varname]
  assign(paste0("data",year),data)
  saveRDS(data, paste0("data",year,".rds"))
}
