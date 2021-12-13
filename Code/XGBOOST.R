setwd("/home/zhaoleo/625_group5")
rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("tidyverse","dplyr","xgboost","performanceEstimation","doParallel","caret")
new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,dependencies = TRUE)
lapply(x, require, character.only=T)
year = seq(1999,2017,2)
namelist = paste(rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")

for(i in namelist){
  temp =  readRDS(paste("data/",i,".rds",sep = ""))
  eval(parse(text = paste0(i,"<- temp")))
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

cl = makeCluster(10)
registerDoParallel(cl) 

foreach(i = namelist) %dopar% {
  lapply(x, require, character.only=T)
  temp =  readRDS(paste("data/",i,".rds",sep = ""))
  eval(parse(text = paste0(i,"<- temp")))
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
  
  save(result, file=paste0("Xgboost_result/Xgboost_",i, ".RData"))
  print(paste0("finish for data", i))
}
