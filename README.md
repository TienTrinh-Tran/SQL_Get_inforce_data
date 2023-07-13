# SQL & Python scripts to generate files needed to do Premium Impact

When actuaries make rate changes for a state, there is a need to check if the overall rate increase/decrease of entire in-force policies in the book matches their calculated filed % change to the Department of Insurance. Our team gets the in-force data from SQL server and output them into an Excel workbook. We then use a separate VBA program to connect this data to our state Excel rater to calculate the current and proposed premium for these policies and calculate the various changes for quality control. 

In the past, due to the variations from states to states, we had multiple SQL scripts to generate the data we need and used Excel to combine the data together. This was time consuming and very error-proned. I wrote a set of dynamic SQL scripts that works for all the states and combine with a Python script to further transform data into the final Excel format that can work well with our Excel raters. 

In addition, Actuarial team also has their own rating engine on SQL server (we call SQL-rerater) to do the same premium calculation in addition to other complex methods they use when making rate changes. This rating engine is quite complex and has so many steps thus caused incorrect factors applied occassionally. Sometimes when we don't match the overall rate change filed by actuaries, we compare the factors applied in this SQL-rerater to the factors applied in our Excel rater. To make comparison faster, I write another SQL script to retrieve factors from actuarial sql results for requested policies to Excel workbook. Our team member can copy & paste the factors generated from our Excel rater on the side columns. Using conditional formatting, the unmatched factors will be immediatly visible to us. 

1 - Files to generate in-force data:
    -
    -
    -
    -
2 - Script to do factor comparison
    - GW_SQL-Rater_Factors_Comparison.py
