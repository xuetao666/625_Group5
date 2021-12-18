# A Study of Diabetes Classification based on NHANES Data with Different Machine Learning Methods
625 Final Project Group 5 
Xueting Tao, Jinhao Wang, Yili Wang, Dongyang Zhao

## Data source:
- NHANES data between year 1999-2018 were used in this project. Since the original data were complicated and could not be used directly, the data were later modified and kept in github. The code used to clean the data was named as Datacleaning.R, under ./Code folder
- Dataset that were used in the analysis was highlighted under ./Reference/Codebook for datatable.xlsx.

## Code Order and explaination:
- Data_cleaning.R: read and clean raw NHANES data, output to Result/Data/
- Initial_Method.R: Code used for data and method exploration( Draft version, just for reference)
- Method codes: Method used to select variables. Results saved in Results/Selection Results/. Note that Random forest result is too large to upload to github
  - a. LASSO.R: Lasso method used in cluster
  -  b. XGBOOST.R: XGBoost method used in cluster
  -  c. RF.R: Random Forest method used in cluster 
- Plots.R: Since the overall data and results is large, we decided to seperate the Rmarkdown and the script generating plots and tables. All the codes for generating results was saved under here. Used after finish Data_cleaning.R and Method codes.
- Final_Report.Rmd: Used for readin previous result and generate final report

The correct sequence of running the program is Data_cleaning.R --> Method codes --> Plots.R --> Final_Report.Rmd 
