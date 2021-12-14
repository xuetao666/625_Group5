#---------------Clean up and import package-------------------------------------
#-------------------------------------------------------------------------------
rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("DT","ggplot2","ggpubr","tidyverse","dplyr","DescTools","PropCIs","qpcR",
     "scales","kableExtra","broom","logistf","ggbiplot","factoextra","psych",
     "reshape2","caret","e1071","rpart","rpart.plot","glmnet","xgboost","Ckmeans.1d.dp",
     "shiny","DMwR","performanceEstimation","gridExtra","randomForest")
new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(x, require, character.only=T)
coalesce <- function(...) {
  apply(cbind(...), 1, function(x) {
    x[which(!is.na(x))[1]]
  })
}
#-------------------------------------------------------------------------------
#Method testing and exploration
## SMOTE
data1 = smote(DIQ010~., data1999_2000, perc.over = 20, perc.under = 1)
table(data1$DIQ010)
## Outlier Detection
fit.lm <- lm(as.numeric(DIQ010)~., data = data1999_2000)
#calculate cook's distance
cooksd = cooks.distance(fit.lm)
#get the outliers table
dfOutliers<-head(data1999_2000[cooksd > 4 * mean(cooksd, na.rm=T), ])%>%data.frame()
kable(dfOutliers,caption = "Outliers")%>%
  kable_styling(latex_options="scale_down")%>%kable_styling(latex_options = "hold_position")%>%
  kable_classic(full_width = F, html_font = "Cambria")
#outliers visualization
plot(cooksd, pch = 20, cex = 1, main = "Outlier",col = brewer.pal(9,"Greys"))
abline(h = 4*mean(cooksd, na.rm = T), col = "steelblue")
#outlier deletion
data <- data[cooksd <= 4 * mean(cooksd, na.rm=T), ]
## Principal Component Analysis
fit.pca = prcomp(data1999_2000[,-149],scale. = TRUE)
knitr::kable(fit.pca$rotation %>% round(3),
             caption = "Variable importance",booktabs = T)%>%
  kable_styling(latex_options="scale_down")%>%kable_styling(latex_options = "hold_position")%>%
  kable_classic(full_width = F, html_font = "Cambria")
ggbi<- ggbiplot(fit.pca, obs.scale = 1, var.scale = 1,
                ellipse = TRUE, circle = TRUE) +
  scale_color_discrete(name = '') +
  theme(legend.direction = 'horizontal', legend.position = 'top')
screePlot<-fviz_eig(fit.pca, addlabels = TRUE);screePlot
# Visualize variable with cos2 >= 0.6
# Top 10 active variables with the highest cos2
highestCos2<-fviz_pca_var(fit.pca, select.var= list(cos2 = 11), repel=T,
                          col.var = "contrib")
grid.arrange(ggbi,screePlot,nrow=1,top = "Visualizaiton of PCA")
grid.arrange(highestCos2,nrow=1,top="Contribution of Variables")
# cumulative variance
s <- summary(fit.pca)
cuv <- s$importance[3,]
cv <- data.frame(cuv)
r <- matrix(cv[,1], ncol = 25)
df.cuv <- data.frame(r)
colnames(df.cuv) <- rownames(cv)[1:25]
kable(df.cuv %>% round(3),
      caption = "Cumulative Variance")%>%
  kable_classic(full_width = F, html_font = "Cambria")%>% footnote(alphabet = "Table 2")
## Random Forest
set.seed(1)
# 80% as training data; 20% as testing
train.index <- createDataPartition(data1999_2000$DIQ010, p = 0.8, list= FALSE)
train.data <- data1999_2000[train.index ,]
test.data <- data1999_2000[-train.index,]
Variable.Importance =randomForest(DIQ010~., data = train.data,ntree = 2000,
                                  mtry = 19,importance = TRUE,classwt = c(1-0.05853659,0.05853659))
rf.pre = predict(Variable.Importance, test.data,type="class")
#confusion matrix
rp <- predict(Variable.Importance, train.data,type="class")
ft <- confusionMatrix(rp,train.data$DIQ010)
cm.f <- confusionMatrix(rf.pre,test.data$DIQ010,positive='1');cm.f
varImpPlot(Variable.Importance)
## Random Forest
set.seed(1)
# 80% as training data; 20% as testing
train.index <- createDataPartition(data1999_2000$DIQ010, p = 0.6, list= FALSE)
train.data <- data1999_2000[train.index ,]
test.data <- data1999_2000[-train.index,]
data1 = smote(DIQ010~., train.data, perc.over = 20, perc.under = 1)
fit.svm = svm(DIQ010~., data1,
              probability = TRUE,cost = 26)
pre.svm = predict(fit.svm, test.data,
                  decision.values = TRUE, probability = TRUE)
#confusion table
sp <- predict(fit.svm, data1,
              decision.values = TRUE, probability = TRUE)
sm <- confusionMatrix(sp,data1$DIQ010)
cm.s<- confusionMatrix(pre.svm,test.data$DIQ010);cm.s
Variable.Importance =randomForest(DIQ010~., data = data1,ntree = 5000,
                                  mtry = 19,importance = TRUE)
rf.pre = predict(Variable.Importance, test.data,type="class")
#confusion matrix
rp <- predict(Variable.Importance, train.data,type="class")
ft <- confusionMatrix(rp,train.data$DIQ010)
cm.f <- confusionMatrix(rf.pre,test.data$DIQ010);cm.f
varImpPlot(Variable.Importance)
## SVM
#library(e1071)
fit.svm = svm(DIQ010~., train.data,
              probability = TRUE,cost = 26)
pre.svm = predict(fit.svm, test.data,
                  decision.values = TRUE, probability = TRUE)
#confusion table
sp <- predict(fit.svm, train.data,
              decision.values = TRUE, probability = TRUE)
sm <- confusionMatrix(sp,train.data$DIQ010)
cm.s<- confusionMatrix(pre.svm,test.data$DIQ010);cm.s
## Decision Tree
# library(rpart)
# library(rpart.plot)
fit.dt <- rpart(class~., train.data,cp=.02)
rpart.plot(fit.dt)
#Model performance
dt.pre = predict(fit.dt, newdata=test.data,type="class")
cm.dt<- confusionMatrix(dt.pre,test.data$class);cm.dt
dp <- predict(fit.dt, newdata=train.data,type="class")
cd <- confusionMatrix(dp,train.data$class)
#variable importance
df3 = data.frame(Variable.importance=fit.dt$variable.importance)
knitr::kable(df3 %>% round(3),
             caption = "Variable Importance")%>%kable_styling(latex_options = "hold_position")
## Lasso Regression
# library(caret)
# library(glmnet)
set.seed(123)
# Dummy code categorical predictor variables
x <- model.matrix(DIQ010~., data1)[,-1]
# Convert the outcome (class) to a numerical variable
y <- ifelse(data1$DIQ010 == 1, 1, 0)
cv.lasso <- cv.glmnet(x, y, alpha = 1, family = "binomial")
# Fit the final model on the training data
model <- glmnet(x, y, alpha = 1, family = "binomial",
                lambda = cv.lasso$lambda.min)
# Display regression coefficients
coef(model)
x.test <- model.matrix(DIQ010~., test.data)[,-1]
probabilities <- model %>% predict(newx = x.test, type="response")
predicted.classes <- ifelse(probabilities > 0.5, 1, 0)
# Model accuracy
observed.classes <- test.data$DIQ010
mean(predicted.classes == observed.classes)
plot(cv.lasso)
coef(cv.lasso, cv.lasso$lambda.min)
coef(cv.lasso, cv.lasso$lambda.1se)
tmp = coef(cv.lasso, cv.lasso$lambda.1se)
tmp = names(tmp[tmp[,1] != 0,] )[-1]
## Lasso min
# Final model with lambda.min
# model
# Make prediction on test data
probabilities <- model %>% predict(newx = x.test, type="response")
predicted.classes <- ifelse(probabilities > 0.5, 1, 0)
# Model accuracy
cm <- confusionMatrix(factor(predicted.classes),test.data$DIQ010);cm
tLL <- model$nulldev - deviance(model)
k <- model$df
n <- model$nobs
AICc <- -tLL+2*k+2*k*(k+1)/(n-k-1)
AICc
## Lasso 1se
# Final model with lambda.mse
lasso.model <- glmnet(x, y, alpha = 1, family = "binomial",
                      lambda = cv.lasso$lambda.1se)
# Make prediction on test data
x.test <- model.matrix(DIQ010~., test.data)[,-1]
probabilities <- lasso.model %>% predict(newx = x.test, type="response")
#predicted.classes <- ifelse(probabilities > 0.4, 1, 0)
# Model accuracy
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
cutoffs[which.min(euclid)]
sensitivities[which.min(euclid)]
specificities[which.min(euclid)]
accus[which.min(euclid)]
max(accus)
#cm.k <- confusionMatrix(factor(predicted.classes),test.data$DIQ010);cm.k
tLL <- lasso.model$nulldev - deviance(lasso.model)
k <- lasso.model$df
n <- lasso.model$nobs
AICc <- -tLL+2*k+2*k*(k+1)/(n-k-1)
AICc
## Ridge
lambda_seq <- 10^seq(2, -2, by = -.1)
# Using glmnet function to build the ridge regression in r
fit <- glmnet(x, y, alpha = 0, lambda  = lambda_seq)
ridge_cv <- cv.glmnet(x, y, alpha = 0, lambda = lambda_seq)
# Best lambda value
best_lambda <- ridge_cv$lambda.min
best_lambda
best_ridge <- glmnet(x, y, alpha = 0, lambda = best_lambda)
coef(ridge_cv, ridge_cv$lambda.min)
coef(best_ridge)
probabilities <- best_ridge %>% predict(newx = x.test, type="response")
predicted.classes <- ifelse(probabilities > 0.5, 1, 0)
# Model accuracy
cm <- confusionMatrix(factor(predicted.classes),test.data$DIQ010);cm
## XGBoost
#using xghboost with ckd(contain NA)
# library(xgboost) # the main algorithm # for the sample dataset 
# library(Ckmeans.1d.dp) # for xgb.ggplot.importance
# library(dplyr)
ckd.num <- data.frame(lapply(data1999_2000, as.numeric))
class <- ckd.num$class
label <- as.integer(ckd.num$class)-1
ckd.num$class = NULL
train.index <- sample(nrow(ckd.num),floor(0.8*nrow(ckd.num)))
train.data = as.matrix(ckd.num[train.index,])
train.label = label[train.index]
test.data = as.matrix(ckd.num[-train.index,])
test.label = label[-train.index]
#set matrix
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
                      factor(test.label));cmXG
# get the feature real names
names <- colnames(ckd.num)
# compute feature importance matrix
importance_matrix = xgb.importance(feature_names = names, model = fit.xg)
#overfitting check
oc <- fit.xg$evaluation_log[c(1:5, 91:95, 995:1000)]
oc%>%data.frame()%>%
  kable(caption = "Overfitting Check")%>%
  kable_styling(latex_options="scale_down")%>%kable_styling(latex_options = "hold_position")%>%
  kable_classic(full_width = F, html_font = "Cambria")
#variable importance plot
# plot
n.col <- 26
my.col2 <- colorRampPalette(brewer.pal(9,"Set2"))(n.col)
xgb.ggplot.importance(importance_matrix)+scale_fill_manual(values = my.col2)+theme_classic()
## Logisitic Regression
lmod <- glm(DIQ010~.,data = data1, family="binomial",maxit=50)
summary(lmod)
car::vif(lmod)
newmod <- step(lmod)
summary(newmod)