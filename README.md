# A Study of Diabetes Classification based on NHANES Data with Different Machine Learning Methods
625 Final Project Group 5 
Xueting Tao, Jinhao Wang, Yili Wang, Dongyang Zhao

## Data source:
- NHANES data between year 1999-2018 were used in this project. Since the original data were complicated and could not be used directly, the data were later modified and kept in github. The code used to clean the data was named as Datacleaning.R, under ./Code folder
- Dataset that were used in the analysis was highed under ./Reference/Codebook for datatable V2.xlsx. ???

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

## 2.2 Data cleaning
Data was download from NHANES webset(https://wwwn.cdc.gov/nchs/nhanes/Default.aspx). All the datasets were downloaded from webset and then arranged by year and data type(Demographic, Dietary, Examination, Laboratory and Questionnaire). A indicator table was made to check the coverage of each dataset(see "Reference/Codebook for datatables V2.xlsx"). Based on the indicator table, we decided to use the following inclusion/exclusion cretiera to chose the datasets to include.

* Drop datasets without Sequence ID information
* Select the datasets with information appearing in more or equals to 10 year period.
* Use easy-to-obtain variabels: Demographic, Questionnaires and easy examination like Weight, Height, Oral, Vision and Audiometry.

After basic exclusion, we merge the selected datasets and further clean the data exclude the variables based on the following creteira:

* Variables in the Diabetes questionnaire was dropped, only keep DIQ010 as outcome.
* survey weights related variables were excluded.
* Variables with missingness more than 20% each year period was dropped.
* Remove all levels(factor) == 1 variable/constant variable for each year period

Our outcome variable is defined as:

* Diabetes was defined as “Doctor told you have diabetes”(named as DIQ010 in the NHANES dataset). 1 refers to Yes, 2 refers to No, 3 refers to Borderline, 7 refers to Refused, 9 refers to don’t know. Yes and Borderline were combined as “Yes”, 7, 9 and NA were excluded from the analysis. The variable was then releveled to 0 and 1: 1 being Yes and 0 being No.


## 2.3 Analysis Approach

In the whole dataset with over 3000 variables, each having different missingness, there was no complete case in our data. Moreover, there were less than 200 variables with less than 20% missing values. To prevent excluding potentially useful variables and keep as many observations as possible, instead of modelling on the whole dataset, we predicted diabetes in each group. After conducting feature selection by every two years, we combined the variables which contributed the most in each group.  

Another problem we met was that our data was imbalanced.  The ratio of positive to negative class in response was 1:11. Synthetic Minority Oversampling Technique (SMOTE) was introduced to deal with the imbalanced data issue. SMOTE is a commonly used oversampling method to rebalance the response variable for better performance on predictive models. To avoid overfitting, we partitioned data into training and testing data and applied SMOTE to rebalance the response variable.
 
The feature selection methods in our project include LASSO, Xgboost, and Random Forest. By applying those methods to our data of 10 groups, we not only obtained sets of variabels selected by the methods, we were also able to compare the sensitivities, specificities, accuracies, and time elapsed among the three models. Based on the performances of the three methods, we determined which variables should be furthur selected. Furthermore, we also checked the meaning of those variables selected to prevent problem of multicollinearity. After determing the final variable set, we wanted to know if those variables would perform well in our overall data using the three different fitting methods. Thus we fit the three models again using our finally selected variabels.  
Complete cases was used in the final model. R version 4.1.12 was used for the analysis.

Following analysis approach was taken for the overall analysis

```{r pressure, echo=FALSE, fig.cap="Analysis Approach", out.width = '100%'}
knitr::include_graphics("../Results/Flowchart.drawio.png")
```



# 3. Results

## 3.1 Feature Selection
Following is the sensitivity and specificity results for each year using different methods in the variable selection process.

```{r Sensitivity, echo=FALSE, fig.cap="Sensitivity, Specificity and Accurancy by year",out.width = '100%'}
knitr::include_graphics("../Results/Sensitivity_spec_byyear.png")
```


Based on the results, we found that XGBoost and Random Forests have unsatisfiable sensitivity, which gave no reason to include variables selected by the above two methods. As a result, we only kept the variables selected by LASSO.  
We further reduced the number of variables according to at least a 50 percent selection rate in the years they appeared and less than 10,000 missing values.   
Here we present the descriptions of each selected variable.

Following is the plot showing the overall importance of variables selected.

```{r, echo=FALSE,fig.cap="Variables of selection", fig.show="hold", out.width="50%"}
knitr::include_graphics("../Results/Importance_matrix.png")
knitr::include_graphics("../Results/Var_meaning.png")
```

Based on the results, we found that Age(RIDAGEYR),Overall Health(HUQ010),BMI(BMXBMI),Routine place to go for healthcare(HUQ030) is the most important variables used to predict Diabetes. 

## 3.2 Model comparision

The following confusion matrices compare our final models fitted using the selected variables shown above. Overall, Logistic regression, LASSO Logistic Regression, Random Forest and XGBoost all produced similar results. Both logistic regression types had a slight advantage in sensitivity, where Random Forest and XGBoost showed higher specificity.

```{r, echo=FALSE,fig.cap="Confusion Matrix", fig.show="hold", out.width="50%"}
knitr::include_graphics("../Results/Confusion_matrix_log.png")
knitr::include_graphics("../Results/Confusion_matrix_lasso.png")
knitr::include_graphics("../Results/Confusion_matrix_XGboost.png")
knitr::include_graphics("../Results/Confusion_matrix_RF.png")
```

# 4. Conclusion


* LASSO works great
* Feature Selection using LASSO/XGBOOST/RF:
  + Lasso: features that’s important in 9 or 10 years
  + Xgboost/RF: Sensitivity Result not ideal, the selection result was not considered in the final model

* In order to make the result meaningful, meaningless variables need to be excluded based on selection. The process has been rerun multiple times. -- Data is messy with over 3000+ variables without cleaning, thus, difficult to select by hand. -- Thus use this process.

## 4.1 Computational challenge and solutions:

* High missingess and low overlap on the variables for different year of survey, thus, there is no complete cases if we work on the overall dataset. 
  + we chose to separate the analysis for different year and then combine to chose the highly overlapped variables
  + Drawback: Tried PCA/LDA, dimension reduction cannot be applied when we have data separated by year

* Figured the imbalance data problem ### 1:11
  + Talk about difference between class weights and SMOTE
  + Oversampling using SMOTE 
  + Since we don't want to have overlap in test and train data, we smote the data after separating the train/test dataset. Only train data has been smote
  + After SMOTE, all the sensitivity from different method increase, however, the results from Random Forest and XGBoost still didn't ideal(most have sensitivity less than 0.5). Thus, we choose to only use the LASSO result as our selection results.
  + Separate Data by year:no complete case in the overall dataset, some of the variables in the NHANES have different names throughout the years.
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


