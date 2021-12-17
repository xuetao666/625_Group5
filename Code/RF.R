library(randomForest)
library(tictoc)
library(caret)
library(performanceEstimation)
year = seq(1999,2017,2)
namelist = paste(rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")
for(i in namelist){
  temp =  readRDS(paste("Results/Data/",i,".rds",sep = ""))
  eval(parse(text = paste0(i,"<- temp")))
}
# RF function returning the model, chosen parameters and confusion matrix
rf = function(train.data, test.data){
  Variable.Importance =randomForest(DIQ010~., data = train.data,ntree = 2000,
                                    mtry = 19,importance = TRUE)
  rf.pre = predict(Variable.Importance, test.data,type="class")
  #confusion matrix
  cm.f <- confusionMatrix(rf.pre,test.data$DIQ010,positive='1');
  result = cm.f$byClass
  return(list(model =  Variable.Importance, result = result))
}
tbl1 = c()
time_out = rep(0,length(namelist))
for(i in 1:length(namelist)){
  tic()
  tmp = get(namelist[i])
  # Train test split
  train.index <- createDataPartition(tmp$DIQ010, p = 0.6, list= FALSE)
  train.data <- tmp[train.index ,]
  test.data <- tmp[-train.index,]
  # Smote the imbalanced train data
  train.data = smote(DIQ010~., train.data, perc.over = 20, perc.under = 1)
  # rf function
  result = rf(train.data, test.data)
  time_return = toc()
  save(result, file=paste0("Results/Selection Results/RF/RF_",namelist[i], ".RData"))
  time_out[i] = time_return$toc - time_return$tic
  print(time_out[i])
  print(paste0("finish for data", namelist[i]))
}

save(time_out,file = "Results/Selection Results/RF/timeout.RData")
