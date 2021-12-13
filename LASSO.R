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
dataRDS <- readRDS("AllData.rds")

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
  tmp = names(tmp[tmp[,1] != 0,] )[-1]
  
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
  return(list(model = model, var = tmp, result = result))
}
  
for (i in namelist){
  tmp = get(i)
  train.index <- createDataPartition(tmp$DIQ010, p = 0.6, list= FALSE)
  train.data <- tmp[train.index ,]
  test.data <- tmp[-train.index,]
  
  train.data = smote(DIQ010~., train.data, perc.over = 20, perc.under = 1)
  
  result = lasso(train.data, test.data)
  
  save(result, file=paste0(i, ".RData"))
}
