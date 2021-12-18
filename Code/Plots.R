rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("ggplot2","cowplot","magick","DT","ggpubr","tidyverse","dplyr","DescTools","PropCIs",
     "qpcR","scales","kableExtra","broom","logistf","RColorBrewer","factoextra","psych",
     "reshape2","e1071","rpart","rpart.plot","caret","glmnet","xgboost","Ckmeans.1d.dp",
     "performanceEstimation","lars","gridExtra","ranger")
new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

lapply(x, require, character.only=T)
coalesce <- function(...) {
  apply(cbind(...), 1, function(x) {
    x[which(!is.na(x))[1]]
  })
}
#-------------------------------------------------------------------------------#
##Data cleaning and backup:
# Read original data
dataRDS = readRDS("../Results/Data/AllData_v20211213_1.rds")
# Data cleaning
dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 %in% c(7,9), NA, dataRDS$DIQ010)
dataRDS = dataRDS[!is.na(dataRDS$DIQ010),]
dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 == 3, 1, dataRDS$DIQ010)
dataRDS$DIQ010 = ifelse(dataRDS$DIQ010 == 2, 0, dataRDS$DIQ010)
#table(dataRDS$DIQ010) # Extremely Unbalanced
dataRDS$DIQ010 = as.factor(dataRDS$DIQ010)
dataRDS = dataRDS[,-1]
#------------------------------
# Read Lasso Results
year = seq(1999, 2017,2)
namelist = paste("Lasso_glmnet_",rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")
# Store the results in tbl
tbl_LASSO=c()
for(i in namelist){
  load(paste("../Results/Selection Results/Lasso_glmnet_result_20/",i,".RData",sep = ""))
  tbl_LASSO=rbind(tbl_LASSO,result$result)
  assign(i,result)
  #eval(parse(text = paste0(i,"= temp")))
}
# Store the important variables
resultvarslasso = list()
for(i in namelist){
  tmp = get(i)
  resultvarslasso[[i]] = tmp$var
}
# Get the common variables
comvarlasso = unlist(resultvarslasso)
comvarlasso = sort(table(comvarlasso), decreasing = T)
#------------------------------
## Xgboost
year = seq(1999, 2017,2)
namelist = paste("Xgboost_",rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")
tbl_Xgboost=c()
for(i in namelist){
  load(paste("../Results/Selection Results/Xgboost_result/",i,".RData",sep = ""))
  tbl_Xgboost=rbind(tbl_Xgboost,result$result)
  assign(i,result)
  #eval(parse(text = paste0(i,"= temp")))
}
# Store the important variables
resultvarsxgboost = list()
for(i in namelist){
  tmp = get(i)
  resultvarsxgboost[[i]] = tmp$var
}
# Get the common variables
comvarxgboost = unlist(resultvarsxgboost)
comvarxgboost = sort(table(comvarxgboost), decreasing = T)
#------------------------------
##RF
year = seq(1999, 2017,2)
namelist = paste("RF_",rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")
tbl_RF=c()
for(i in namelist){
  load(paste("../Results/Selection Results/RF/",i,".RData",sep = ""))
  tbl_RF=rbind(tbl_RF,result$result)
  assign(i,result)
  #eval(parse(text = paste0(i,"= temp")))
}
year = seq(1999,2017,2)
namelist = paste(rep("data",length(year)),year,rep("_",length(year)),year+1,sep = "")
#------------------------------
# Store the important variables
yearvars= list()
for(i in namelist){
  temp = readRDS(paste("../Results/Data/",i,".rds",sep = ""))
  yearvars[[i]] = colnames(temp)
}
yearvars = unlist(yearvars)
yearvars = sort(table(yearvars), decreasing = T)
# Calculate variable coverage rate: percentages of frequencies
comvar = comvarlasso/yearvars[names(yearvars)%in%names(comvarlasso)]
comvar = names(comvar[comvar>0.5])
# Remove "RIDAGEEX"
comvar = comvar[!comvar %in% c("RIDAGEEX","SDMVSTRA", "MCQ010", "DMDHRGND", "DMDHRAGE", "BMXWT", "BMXHT", "HSAQUEX","RIDEXMON")]
# Include response
comvar = c("DIQ010", comvar)
# Select the important variables obtained from Lasso
data=dataRDS[,colnames(dataRDS) %in% comvar]
# Remove those with lots of NA
missingness = colSums(is.na(data))
data=data[,colnames(data) %in% names(missingness[missingness < 10000])]
# Complete cases
complete = data[complete.cases(data),]
#------------------------------
# Train test split & smote train data
train.index = createDataPartition(complete$DIQ010, p = 0.6, list= FALSE)
train.data = complete[train.index ,]
train.data = smote(DIQ010~., train.data, perc.over = 11, perc.under = 1)
test.data = complete[-train.index,]
# To keep our test data and prevent test data being mixed with training data, (as smote is similar to copy and pasting the original data).
#------------------------------
# logistic regression
lmod = glm(DIQ010~.,data = train.data, family="binomial",maxit=50)
x.test = test.data[,which(colnames(test.data) != "DIQ010")]
probabilities = predict(lmod, newdata = x.test, type = "response")
predicted.classes = ifelse(probabilities > 0.5, 1, 0)
cm.log = confusionMatrix(factor(predicted.classes),test.data$DIQ010, positive = "1");cm.log
#------------------------------
# RF with ranger
fit <- ranger(DIQ010~., data = train.data, 
              num.trees = 1000,
              max.depth = 8,
              probability = TRUE)
rf.pre = predict(fit, test.data)
predicted.classes = ifelse(rf.pre$predictions[,2] > 0.5, 1, 0)
cm.f = confusionMatrix(as.factor(predicted.classes),test.data$DIQ010,positive='1');cm.f
#------------------------------
# Lasso
x = model.matrix(DIQ010~., train.data)[,-1]
# Convert the outcome (DIQ010) to a numerical variable
y = ifelse(train.data$DIQ010 == 1, 1, 0)
### using lars lasso
lars_lasso = lars(x = x, y = y, trace = FALSE, type = "lasso")
# lars_lasso
# plot(lars_lasso$R2)
# Importance plot for Lasso
importancelasso = data.frame(diff_R2 = rep(NA,length(lars_lasso$actions)), names = rep(NA,length(lars_lasso$actions)))
for (i in 1:length(lars_lasso$actions)){
  importancelasso$names[i] = names(lars_lasso$actions[[i]])
  importancelasso$diff_R2[i] = lars_lasso$R2[i+1] - lars_lasso$R2[i]
}
importancelasso = importancelasso[order(-importancelasso$diff_R2),]
colfunc = colorRampPalette(c("steel blue", "yellow"))
importancelasso$match = colfunc(3*length(lars_lasso$actions))[seq(from = 1, to = 3*length(lars_lasso$actions), by = 3)]
cv.lasso = cv.glmnet(x, y, alpha = 1, family = "binomial")
model = glmnet(x, y, alpha = 1, family = "binomial",
               lambda = cv.lasso$lambda.1se)
# Get sensitivity
x.test = model.matrix(DIQ010~., test.data)[,-1]
probabilities = model %>% predict(newx = x.test, type="response")
cutoffs = seq(0.01, 0.99, 0.01)
accus = c()
sensitivities = c()
specificities = c()
for (i in 1:length(cutoffs)) {
  predicted.classes = ifelse(probabilities > cutoffs[i], 1, 0)
  cm.k = confusionMatrix(factor(predicted.classes),test.data$DIQ010)
  accus = c(accus,cm.k$overall['Accuracy'])
  sensitivities = c(sensitivities, cm.k$byClass['Sensitivity'])
  specificities = c(specificities, cm.k$byClass['Specificity'])
}
euclid = sqrt((1-specificities)^2 + (sensitivities-1)^2)
predicted.classes = ifelse(probabilities > cutoffs[which.min(euclid)], 1, 0)
# Model accuracy
cm.lasso = confusionMatrix(factor(predicted.classes),test.data$DIQ010, positive = "1");cm.lasso
#------------------------------
# Xgboost
test.label = as.integer(test.data$DIQ010)-1
train.label = as.integer(train.data$DIQ010)-1
train.data = data.frame(lapply(train.data, as.numeric))
test.data = data.frame(lapply(test.data, as.numeric))
train.data$DIQ010 = NULL
train.data=as.matrix(train.data)
test.data$DIQ010 = NULL
test.data=as.matrix(test.data)
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
  nrounds=2000,
  early_stopping_rounds=10,
  watchlist=list(training=trainMatrix,testing=testMatrix),
  verbose=0
)
XGpred = predict(fit.xg, newdata = testMatrix)
XGprediction = as.numeric(XGpred>0.5)
# Use the predicted label with the highest probability
cmXG=confusionMatrix(factor(XGprediction),
                     factor(test.label), positive = '1');cmXG
# Importance Matrix
names = colnames(train.data)
importance_matrix = xgb.importance(feature_names = names, model = fit.xg)
# Output importance plot
n.col = 26
my.col2 = colorRampPalette(brewer.pal(8,"Set2"))(n.col)

#-------------------------------------------------------------------------------
#Drawing plot
load("../Results/Selection Results/Lasso_glmnet_result_20/timeout.RData")
time_LASSO = time_out
load("../Results/Selection Results/Xgboost_result/timeout.RData")
time_XG = time_out
load("../Results/Selection Results/RF/timeout.RData")
time_RF = time_out
time_la = c()
time_xgb = c()
time_rfs = c()
for (i in 1:10) {
  time_la = c(time_la, time_LASSO[[i]])
  time_xgb = c(time_xgb, time_XG[[i]])
  time_rfs = c(time_rfs, time_RF[[i]])
}

namelist = paste(year,rep("_",length(year)),year+1,sep = "")
Sensis = data.frame(year = namelist, sens_LASSO = tbl_LASSO[,1], sens_Xgboost = tbl_Xgboost[,1], sens_RF = tbl_RF[,1])
Specis = data.frame(year = namelist, sens_LASSO = tbl_LASSO[,2], sens_Xgboost = tbl_Xgboost[,2], sens_RF = tbl_RF[,2])
accus = data.frame(year = namelist, accus_LASSO = tbl_LASSO[,11], accus_Xgboost = tbl_Xgboost[,11], accus_RF = tbl_RF[,11])
times = data.frame(year = namelist, time_LASSO = time_la, time_Xgboost = time_xgb, time_RF = time_rfs)

p1 = ggplot(data = Sensis, aes(x = year, group = 1)) + geom_line(aes(y = sens_LASSO, color = "LASSO")) + 
  geom_line(aes(y = sens_Xgboost, color = "Xgboost")) + 
  geom_line(aes(y = sens_RF, color = "Random Forest")) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        axis.title.y = element_blank()) + 
  ylim(0,1) + theme(legend.position="none")+ggtitle("Sensitivities")+theme(plot.margin = unit(c(0,1,0,0), "cm"))

p2 = ggplot(data = Specis, aes(x = year, group = 1)) + geom_line(aes(y = sens_LASSO, color = "LASSO")) + 
  geom_line(aes(y = sens_Xgboost, color = "Xgboost")) + geom_line(aes(y = sens_RF, color = "Random Forest")) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        axis.title.y = element_blank(), axis.text.y = element_blank(), 
        axis.ticks.y = element_blank()) + ylim(0,1) + 
  theme(legend.position="none")+ggtitle("Specificities")+theme(plot.margin = unit(c(0,1,0,0), "cm"))

p3 = ggplot(data = accus, aes(x = year, group = 1)) + geom_line(aes(y = accus_LASSO, color = "LASSO")) + 
  geom_line(aes(y = accus_Xgboost, color = "Xgboost")) + geom_line(aes(y = accus_RF, color = "Random Forest")) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        axis.title.y = element_blank(), axis.text.y = element_blank(), 
        axis.ticks.y = element_blank()) + ylim(0,1) + 
  theme(legend.position="none")+ggtitle("Accuracies")+theme(plot.margin = unit(c(0,1,0,0), "cm"))

p4 = ggplot(data = times, aes(x = year, group = 1)) + geom_line(aes(y = time_LASSO, color = "LASSO")) + 
  geom_line(aes(y = time_Xgboost, color = "Xgboost")) + geom_line(aes(y = time_RF, color = "Random Forest")) + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        axis.title.y = element_blank()) + 
  theme(legend.position="right", legend.direction = "vertical") + ggtitle("Time Elapsed(seconds)")+
  labs(color='Method') +theme(plot.margin = unit(c(0,5,0,0), "cm"))

plot1=plot_grid(p1,p2,p3,ncol = 3,rel_widths = c(1.25,1,1))
plot=plot_grid(plot1,p4,ncol=1,rel_heights = c(1,1))

plot
ggsave(
  "../Results/Sensitivity_spec_byyear.png",
  plot = plot,
  device = "png",
  scale = 1,
  width = 10,
  height = 6,
  units = "in"
)

##Plot2. Importance matrix
colfunc = colorRampPalette(c("steel blue", "yellow"))
importancelasso$match = colfunc(3*length(lars_lasso$actions))[seq(from = 1, to = 3*length(lars_lasso$actions), by = 3)]
importances = data.frame(names = importance_matrix$Feature, importance_XG = importance_matrix$Gain)
importances = importances %>% full_join(importancelasso, by = "names")
g1 = ggplot(data = importances, aes(x = reorder(names, diff_R2), y = diff_R2)) + 
  geom_bar(stat = "identity", width = 0.98, fill = importances$match) + 
  theme(axis.title.x = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(), 
        axis.ticks.y = element_blank(), plot.margin = unit(c(1,0,1,0), "mm")) + scale_y_reverse() + 
  coord_flip() + ggtitle("Variables Importances by LASSO")
g2 = ggplot(data = importances, aes(x = reorder(names, diff_R2), y = importance_XG)) + 
  geom_bar(stat = "identity", width = 0.98, fill = importances$match) + 
  theme(axis.title.x = element_blank(), axis.title.y = element_blank(), plot.margin = unit(c(1,0,1,0), "mm")) + 
  coord_flip() + ggtitle("Variables Importances by Xgboost")

title <- ggdraw() + 
  draw_label(
    "3a.Variable importance",
    fontface = 'bold',
    x = 0,
    hjust = 0
  ) +
  theme(
    # add margin on the left of the drawing canvas,
    # so title is aligned with left edge of first plot
    plot.margin = margin(0, 0, 0, 200)
  )

plot_row<-plot_grid(g1,g2,
                ncol = 2)
plot<-plot_grid(
  plot_row, title,
  ncol = 1,
  rel_heights = c(1, 0.1)
)
plot
ggsave(
 "../Results/Importance_matrix.png",
  plot = plot,
  device = "png",
  scale = 1,
  width = 10,
  height = 6,
  units = "in"
)
##Plot3: Confusion matrix
draw_confusion_matrix <- function(cm,title="") {
  layout(matrix(c(1,1,2)))
  par(mar=c(2,2,2,2))
  plot(c(100, 345), c(300, 450), type = "n", xlab="", ylab="", xaxt='n', yaxt='n')
  title(title, cex.main=2)
  # create the matrix 
  rect(150, 430, 240, 370, col='#3F97D0')
  text(195, 435, 'Class1', cex=1.2)
  rect(250, 430, 340, 370, col='#F7AD50')
  text(295, 435, 'Class2', cex=1.2)
  text(125, 370, 'Predicted', cex=1.3, srt=90, font=2)
  text(245, 450, 'Actual', cex=1.3, font=2)
  rect(150, 305, 240, 365, col='#F7AD50')
  rect(250, 305, 340, 365, col='#3F97D0')
  text(140, 400, 'Class1', cex=1.2, srt=90)
  text(140, 335, 'Class2', cex=1.2, srt=90)
  # add in the cm results 
  res <- as.numeric(cm$table)
  text(195, 400, res[1], cex=1.6, font=2, col='white')
  text(195, 335, res[2], cex=1.6, font=2, col='white')
  text(295, 400, res[3], cex=1.6, font=2, col='white')
  text(295, 335, res[4], cex=1.6, font=2, col='white')
  # add in the specifics 
  plot(c(100, 0), c(100, 0), type = "n", xlab="", ylab="", main = "DETAILS", xaxt='n', yaxt='n')
  text(10, 85, names(cm$byClass[1]), cex=1.2, font=2)
  text(10, 70, round(as.numeric(cm$byClass[1]), 3), cex=1.2)
  text(30, 85, names(cm$byClass[2]), cex=1.2, font=2)
  text(30, 70, round(as.numeric(cm$byClass[2]), 3), cex=1.2)
  text(50, 85, names(cm$byClass[5]), cex=1.2, font=2)
  text(50, 70, round(as.numeric(cm$byClass[5]), 3), cex=1.2)
  text(70, 85, names(cm$byClass[6]), cex=1.2, font=2)
  text(70, 70, round(as.numeric(cm$byClass[6]), 3), cex=1.2)
  text(90, 85, names(cm$byClass[7]), cex=1.2, font=2)
  text(90, 70, round(as.numeric(cm$byClass[7]), 3), cex=1.2)
  # add in the accuracy information 
  text(30, 35, names(cm$overall[1]), cex=1.5, font=2)
  text(30, 20, round(as.numeric(cm$overall[1]), 3), cex=1.4)
  text(70, 35, names(cm$overall[2]), cex=1.5, font=2)
  text(70, 20, round(as.numeric(cm$overall[2]), 3), cex=1.4)
} 
png(filename = "../Results/Confusion_matrix_log.png",width = 400, height = 400)
p1 = draw_confusion_matrix(cm.log,title="Logistic")
dev.off()
png(filename = "../Results/Confusion_matrix_lasso.png",width = 400, height = 400)
p2 = draw_confusion_matrix(cm.lasso,title="LASSO")
dev.off()
png(filename = "../Results/Confusion_matrix_RF.png",width = 400, height = 400)
p3 = draw_confusion_matrix(cm.f,title="Random Forest")
dev.off()
png(filename = "../Results/Confusion_matrix_XGboost.png",width = 400, height = 400)
p4 = draw_confusion_matrix(cmXG,title="XGBoost")
dev.off()

