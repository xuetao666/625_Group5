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
- Final_Report.rmd: Used for readin previous result and generate final report
