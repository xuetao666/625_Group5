# A Study of Diabetes Classification based on NHANES Data with Different Machine Learning Methods
625 Final Project Group 5 
Xueting Tao, Jinhao Wang, Yili Wang, Dongyang Zhao

## Data source:
- Data comes from NHANES data, year 1999-2018. Since the overall data is big and complicated, we only keep the cleaned version in the github. However, the code used to clean the data was named as Datacleaning.R, under ./Code folder
- Dataset that were used in the analysis was highed under ./Reference/Codebook for datatable V2.xlsx. 

## Code Order and explaination:
- Data_cleaning.R: read and clean raw NHANES data, output to Result/Data/
- Initial_Method.R: Code used for data and method exploration
- Method codes.R:
  - a. LASSO.R: Lasso method used in cluster
  -  b. XGBOOST.R: XGBoost method used in cluster
  -  c. RF.R: Random Forest method used in cluster

- Final_Report.rmd: Used for readin previous result and generate final report

#################################################################################################################################################################################
For Report draft

# 1. Background and Objectives

With a high prevalence of overweight individuals growing in the US, there is a trend of increasing prevalence in diabetes as well. To better control and prevent the development of diabetes, we aim to discover the most significant covariates and find the best machine learning algorithm for predicting diabetes, thus could give individual prevention ideas and help with earlier diagnosis of diabetes.

# 2. Method
## 2.1 Study Population
The Dataset we will be using is the National Health and Nutrition Examination Survey (NHANES), a program of studies designed to assess the health and nutritional status of adults and children in the United States,provided by the Centers for Disease Control and Prevention (CDC). The data range from 1999-2018, each with two years of a cross-sectional study. Different individuals were enrolled every two years. Data includes demographic, dietary, examination, laboratory, and questionnaire data.

## 2.2 Variables of selection
### 2.2.1 Outcome of Prediction
Diabetes was defined as “Doctor told you have diabetes”(named as DIQ010 in the NHANES dataset). 1 refers to Yes, 2 refers to No, 3 refers to Borderline, 7 refers to Refused, 9 refers to don’t know. Yes and Borderline were combined as “Yes”, 7, 9 and NA was excluded from the analysis.

### 2.2.2 Inclusion And Exclusion Criteria for variable selection

* Drop datasets without Sequence ID information
* Select datasets have information in more or equals to 10 year period.
* Use easy-to-obtain dataset: Demographic, Questionnaires and easy examination like Weight, Height, Oral, Vision and Audiometry.
* Variables in the Diabetes questionnaire was dropped, only keep DIQ010 as outcome.
* survy weights related variables were excluded.
* Variables with missingness more than 20% each year period was dropped.
* Remove all levels(factor) == 1 variable/constant variable for each year period
* After selection by year, we first select that variables that have more than 30% of overlap between years, then exclude the variables that have overall missingness more than 10,000.
* Complete cases was kept in the final model.

## 2.3 Analysis Approach

Following analysis approach was taken for the overall analysis

```{r, echo=FALSE, results='hide', message=FALSE, warning=FALSE}
rm(list=ls(all=TRUE))  #same to clear all in stata
cat("\014")
x<-c("ggplot2","cowplot","magick")
new.packages<-x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

lapply(x, require, character.only=T)
coalesce <- function(...) {
  apply(cbind(...), 1, function(x) {
    x[which(!is.na(x))[1]]
  })
}
```

Insert flowchart here:
```{r pressure, echo=FALSE, fig.cap="Analysis Approach", out.width = '100%'}
knitr::include_graphics("../Results/Flowchart.drawio.png")
```
### 2.3.1 Oversampling the minority group by Synthetic Minority Oversampling Technique:
* Oversampling using SMOTE: In our response variable, the ratio of "No" to "Yes" is 11:1, which leads to a severe imbalanced data problem. To deal with the imbalanced data issue, Synthetic Minority Oversampling Technique (SMOTE) was used. SMOTE is a commonly used method to oversample the observations in the minority group. In SMOTE, the k-nearest neighbors of each observation in the minority group are obtained by calculating the Euclidian distance between each observation and the other samples in the minority group. 
* To keep our test data clean and prevent test data being mixed with training data, the SMOTE technique was only used in the training data. We separated the training data set and test data set first and then apply SMOTE to the training data set. 

### 2.3.2 Comparing differenct feature selection methods:
* 

# 3. Results

## 3.1 Feature Selection
Following is the sensitivity and specificity results for each year using different method in the variable selection process.




Based on the results, we found that XGBoost and Random Forests have low sensitivity, thus not reasonable to include variabels using these two methods. As a result, for the overall selection, we only include the variables results in LASSO. For LASSO, we chose variables that have at least 50% coverage of the whole year period (1999-2018), also with less than 10,000 missingness.
Following is the plot showing the overall importance of variables selected and their definition.





```{r varm, echo=FALSE, fig.cap="Variables selected", out.width = '100%'}

# plot_grid(p1, p2)


knitr::include_graphics("../Results/Var_meaning.png")
```


Based on the results, we found that ___ is the most importance ..(more interpretation)


## 3.2 Model comparision
Following table is the comparision between different model fits using the variables selected above. Overall, LASSO and XGBoost have similar results. Since random forest took longer than expected(), thus we stopped the process.



# 4. Conclusion



* SVM, DT not ideal in our situation
* LASSO, XGBOOST works great
* Feature Selection using LASSO/XGBOOST/RF:
  + Lasso: features that’s important in 9 or 10 years
  + Xgboost/RF: Sensitivity Result not ideal, the selection result was not considered in the final model

* In order to make the result meaningful, meaningless variables need to be excluded based on selection. The process has been rerun multiple times. -- Data is messy with over 3000+ variables without cleaning, thus, difficult to select by hand. -- Thus use this process.

## 4.1 Computational chanllege and solutions:

* High missingess and low overlap on the variables for different year of survey, thus, there is no complete cases if we work on the overall dataset. 
  + we chose to separate the analysis for different year and then combine to chose the highly overlapped variables
  + Drawback: Tried PCA/LDA, dimension reduction cannot be applied when we have data separated by year

* Figured the imbalance data problem ### 1:11
  + Talk about difference between class weights and SMOTE
  + Oversampling using SMOTE 
  + Since we don't want to have overlap in test and train data, we smote the data after separating the train/test dataset. Only train data has been smote
  + After SMOTE, all the sensitivity from different method increase, however, the results from Random Forest and XGBoost still didn't ideal(most have sensitivity less than 0.5). Thus, we choose to only use the LASSO result as our selection results.
* Separate Data by year:no complete case in the overall dataset, some of the variables in the NHANES have different names throughout the years.
  + so we only chose those variables with missingness less than 10%.
  + Drawback: give us even larger datasets
  
* Feature selection is slow:
  + pack feature selection as separate functions and run on cluster
  
* Overall around 3,000 variables needed to be selected, difficult to clean by hand.
  + Thus, we first select, then based on the selection results, clean out meaningless variables and possible colinearities(like age in month & age in year)
  + After cleaning, we run the selection again until the selected variables are all meaningful.
  + Drawback: Saves labor but cost more time on running.
  
## 4.2 Future works

* Try the same process on less-missingness data
* Try imputation on the missing variables
* Would there be anyway to improve RandomForest/SVM etc. so that they could handle imbalanced data better.

