library(tictoc)
setwd("/home/zhaoleo/625_group5")
rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("tidyverse","dplyr","caret","glmnet","performanceEstimation","doParallel")
new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages,dependencies = TRUE)
lapply(x, require, character.only=T)
year = seq(1999,2017,2)
namelist = paste(rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")

for(i in namelist){
  temp =  readRDS(paste("data/",i,".rds",sep = ""))
  eval(parse(text = paste0(i,"<- temp")))
}

## Lasso

lasso = function(train.data, test.data){
  x <- model.matrix(DIQ010~., train.data)[,-1]
  # Convert the outcome (DIQ010) to a numerical variable
  y <- ifelse(train.data$DIQ010 == 1, 1, 0)
  cv.lasso <- cv.glmnet(x, y, alpha = 1, family = "binomial")
  
  
  # Fit the final model on the training data
  model <- glmnet(x, y, alpha = 1, family = "binomial",
                  lambda = cv.lasso$lambda.1se)
  # Names of selected variables
  vars = coef(cv.lasso, cv.lasso$lambda.1se)
  vars = names(vars[vars[,1] != 0,] )[-1]
  
  # Get sensitivity
  x.test <- model.matrix(DIQ010~., test.data)[,-1]
  probabilities <- model %>% predict(newx = x.test, type="response")
  
  
  cutoffs = seq(0.01, 0.99, 0.01)
  accus = c()
  sensitivities = c()
  specificities = c()
  for (i in 1:length(cutoffs)) {
    predicted.classes <- ifelse(probabilities > cutoffs[i], 1, 0)
    cm.k <- confusionMatrix(factor(predicted.classes),test.data$DIQ010);cm.k
    accus = c(accus,cm.k$overall['Accuracy'])
    sensitivities = c(sensitivities, cm.k$byClass['Sensitivity'])
    specificities = c(specificities, cm.k$byClass['Specificity'])
  }
  euclid = sqrt((1-specificities)^2 + (sensitivities-1)^2)
  
  
  predicted.classes <- ifelse(probabilities > cutoffs[which.min(euclid)], 1, 0)
  # Model accuracy
  cm = confusionMatrix(factor(predicted.classes),test.data$DIQ010, positive = "1")
  result = cm$byClass
  return(list(model = model, var = vars, result = result))
}

cl = makeCluster(10)
registerDoParallel(cl) 


tic()
foreach(i = namelist) %dopar% {
  library(tictoc)
  lapply(x, require, character.only=T)
  temp =  readRDS(paste("data/",i,".rds",sep = ""))
  eval(parse(text = paste0(i,"<- temp")))
  tmp = get(i)
  train.index <- createDataPartition(tmp$DIQ010, p = 0.6, list= FALSE)
  train.data <- tmp[train.index ,]
  test.data <- tmp[-train.index,]
  
  train.data = smote(DIQ010~., train.data, perc.over = 20, perc.under = 1)
  result = lasso(train.data, test.data)
  save(result, file=paste0("Lasso_glmnet_result_20/Lasso_glmnet_", i, ".RData"))
  print(paste0("finish for data", i))
}
time_out = toc()
stopCluster()

save(time_out,file = "Lasso_glmnet_result_20/timeout.RData")

