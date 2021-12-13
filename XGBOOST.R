library(ggbiplot)
library(factoextra)
library(psych)
library(reshape2)
library(caret)
library(e1071)
library(rpart)
library(rpart.plot)
library(caret)
library(glmnet)
library(xgboost) # the main algorithm # for the sample dataset 
library(Ckmeans.1d.dp) # for xgb.ggplot.importance
library(dplyr)
library(performanceEstimation)
suppressMessages(library(shiny))
suppressMessages(library(DT))
suppressMessages(library(ggplot2))
suppressMessages(library(ggpubr))
suppressMessages(library(tidyverse))
suppressMessages(library(dplyr))
suppressMessages(library(DescTools))
suppressMessages(library(PropCIs))
suppressMessages(library(qpcR))
suppressMessages(library(scales))
suppressMessages(library(kableExtra))
suppressMessages(library(broom))
suppressMessages(library(logistf))

## Read Data
setwd("C:/Users/wjhlang/Downloads")
dataRDS <- readRDS("AllData (3).RDS")

## Data Cleaning
dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 %in% c(7,9), NA, dataRDS$DIQ010)
dataRDS = dataRDS[!is.na(dataRDS$DIQ010),]
dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 == 3, 1, dataRDS$DIQ010)
dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 == 2, 0, dataRDS$DIQ010)
table(dataRDS$DIQ010) # Extremely Unbalanced
dataRDS$DIQ010 = as.factor(dataRDS$DIQ010)
dataRDS = dataRDS[,-1] # Remove SEQN

Ylist=levels(as.factor(dataRDS$year))
namelist = c()
for(year in Ylist){
  data=dataRDS[dataRDS$year==year,]
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
  namelist = c(paste0("data",year),namelist)
}

## XGBoost

myxgboost = function(train.data, test.data){
  trainMatrix = xgb.DMatrix(data=train.data,label=train.label)
  testMatrix = xgb.DMatrix(data=test.data,label=test.label)
  # Define the parameters
  params = list(
    booster="gbtree",
    eta=0.001,
    max_depth=5,
    gamma=3,
    subsample=0.75,
    colsample_bytree=1,
    objective="binary:logistic",
    eval_metric="rmse"
  )
  # Train the XGBoost classifier
  fit.xg=xgb.train(
    params=params,
    data=trainMatrix,
    nrounds=1000,
    
    early_stopping_rounds=10,
    watchlist=list(training=trainMatrix,testing=testMatrix),
    verbose=0
  )
  XGpred <- predict(fit.xg, newdata = testMatrix)
  XGprediction <- as.numeric(XGpred>0.5)
  # Use the predicted label with the highest probability
  cmXG<-confusionMatrix(factor(XGprediction),
                        factor(test.label), positive = '1')
  # get the feature real names
  names <- colnames(train.data)
  # compute feature importance matrix
  importance_matrix = xgb.importance(feature_names = names, model = fit.xg)
  
  vars = importance_matrix$Feature[which(importance_matrix$Gain > 1/length(names))]
  
  
  
  
  
  train.data=train.data[,colnames(train.data) %in% vars]
  test.data=test.data[,colnames(test.data) %in% vars]
  
  trainMatrix = xgb.DMatrix(data=train.data,label=train.label)
  testMatrix = xgb.DMatrix(data=test.data,label=test.label)
  
  fit.xg=xgb.train(
    params=params,
    data=trainMatrix,
    nrounds=1000,
    
    early_stopping_rounds=10,
    watchlist=list(training=trainMatrix,testing=testMatrix),
    verbose=0
  )
  XGpred <- predict(fit.xg, newdata = testMatrix)
  XGprediction <- as.numeric(XGpred>0.5)
  # Use the predicted label with the highest probability
  cmXG<-confusionMatrix(factor(XGprediction),
                        factor(test.label), positive = '1')
  
  result = cmXG$byClass
  return(list(model = fit.xg, var = vars, result = result))
}

for (i in namelist){
  tmp = get(i)
  train.index <- createDataPartition(tmp$DIQ010, p = 0.6, list= FALSE)
  train.data <- tmp[train.index ,]
  test.data <- tmp[-train.index,]
  test.label = as.integer(test.data$DIQ010)-1
  
  train.data = smote(DIQ010~., train.data, perc.over = 20, perc.under = 1)
  train.label = as.integer(train.data$DIQ010)-1
  
  train.data <- data.frame(lapply(train.data, as.numeric))
  test.data <- data.frame(lapply(test.data, as.numeric))
  
  train.data$DIQ010 = NULL
  train.data=as.matrix(train.data)
  
  test.data$DIQ010 = NULL
  test.data=as.matrix(test.data)
  
  result = myxgboost(train.data, test.data)
  
  save(result, file=paste0("Xgboost_",i, ".RData"))
}
