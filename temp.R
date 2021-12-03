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
workpath<-"C:/Users/xueti/Dropbox (University of Michigan)/Umich/class/term 1/625/Final/625_Group/625_Group"
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
    if(nrow(demo_data)==0){
      demo_data=df
    } else {
      demo_data=bind_rows(demo_data,df) 
    }
  }
}
setwd('..')


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
# year="1999_2000"
# setwd(year)
# fileList=list.files()
# for(f in fileList){
#   if(sum(stri_detect_fixed(f,fileRdList))!=0){
#     print(f)
#     df=read_xpt(f)
#     print(sum(duplicated(df$SEQN)))
#   }
# }

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

# year="1999_2000"
# setwd(year)
# fileList=list.files()
# for(f in fileList){
#   if(sum(stri_detect_fixed(f,fileRdList))!=0 & sum(stri_detect_fixed(f,fileNolist))==0){
#     print(f)
#     df=read_xpt(f)
#     print(sum(duplicated(df$SEQN)))
#   }
# }

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
    ques_data=bind_rows(ques_data,tempdata)
  } else {
    ques_data=tempdata
  }
  setwd('..')
  
}
sum(duplicated(ques_data$SEQN))
setwd('..')

#Merge all data together:
all_data=full_join(demo_data,dia_data,by="SEQN")
names(all_data)
all_data=full_join(all_data,exam_data,by="SEQN")
names(all_data)
all_data=full_join(all_data,ques_data,by="SEQN")
names(all_data)
