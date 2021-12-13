rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("tidyverse","dplyr","caret","glmnet","performanceEstimation")
new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,dependencies = TRUE)
lapply(x, require, character.only=T)
# ## Read Data 
# dataRDS <- readRDS("AllData.rds")
# 
# ## Data Cleaning
# dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 %in% c(7,9), NA, dataRDS$DIQ010)
# dataRDS = dataRDS[!is.na(dataRDS$DIQ010),]
# dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 == 3, 1, dataRDS$DIQ010)
# dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 == 2, 0, dataRDS$DIQ010)
# table(dataRDS$DIQ010) # Extremely Unbalanced
# dataRDS$DIQ010 = as.factor(dataRDS$DIQ010)
# dataRDS = dataRDS[,-1] # Remove SEQN
# 
# Ylist=levels(as.factor(dataRDS$year))
# namelist = c()
# for(year in Ylist){
#   data=dataRDS[dataRDS$year==year,]
#   na = colSums(is.na(data))/nrow(data)*100
#   na=na[na<10]
#   data=data[complete.cases(data[,names(na)]),names(na)]
#   
#   print(year)
#   print(table(data$DIQ010))
#   
#   #Loop for factor names:
#   varname=c("BMAAMP")
#   for(varn in names(na)){
#     if(length(levels(as.factor(data[[varn]])))==1){
#       varname=c(varname,varn)
#     }
#   }
#   print(varname)
#   data=data[,!colnames(data) %in% varname]
#   
#   assign(paste0("data",year),data)
#   namelist = c(paste0("data",year),namelist)
# }

setwd("C:/Users/wjhlang/Downloads")
year = seq(1999,2017,2)
namelist = paste(rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")

for(i in namelist){
    temp =  readRDS(paste("data/",i,".rds",sep = ""))
    eval(parse(text = paste0(i,"<- temp")))
}
## Lasso

set.seed(123)
lasso = function(train.data, test.data){
    x <- model.matrix(DIQ010~., train.data)[,-1]
    # Convert the outcome (class) to a numerical variable
    y <- ifelse(train.data$DIQ010 == 1, 1, 0)
    cv.lasso <- cv.glmnet(x, y, alpha = 1, family = "binomial")
    # Fit the final model on the training data
    model <- glmnet(x, y, alpha = 1, family = "binomial",
                    lambda = cv.lasso$lambda.1se)
    # Names of selected variables
    tmp = names(tmp[tmp[,1] != 0,] )[-1]
    
    # Get sensitivity
    x.test <- model.matrix(DIQ010~., test.data)[,-1]
    probabilities <- model %>% predict(newx = x.test, type="response")
    predicted.classes <- ifelse(probabilities > 0.5, 1, 0)
    # Model accuracy
    cm = confusionMatrix(factor(predicted.classes),test.data$DIQ010, positive = "1")
    result = cm$byClass
    return(list(model = model, var = tmp, result = result))
}

for (i in namelist){
    tmp = get(i)
    train.index <- createDataPartition(tmp$DIQ010, p = 0.6, list= FALSE)
    train.data <- tmp[train.index ,]
    test.data <- tmp[-train.index,]
    
    train.data = smote(DIQ010~., train.data, perc.over = 20, perc.under = 1)
    print(i)
    result = lasso(train.data, test.data)
    
    save(result, file=paste0("Lasso_glmnet_", i, ".RData"))
}

