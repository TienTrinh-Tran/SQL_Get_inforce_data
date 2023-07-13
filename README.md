# SQL & Python scripts to generate files needed to do Premium Impact

When actuaries make rate changes for a state, there is a need to verify if the overall rate increase or decrease of all in-force policies in the book aligns with the calculated filed percentage change submitted to the Department of Insurance. Our team retrieves the in-force data from the SQL server and exports it to an Excel workbook. Subsequently, we utilize a separate VBA program to link this data to our state Excel rater. This allows us to calculate the current and proposed premiums for these policies and assess various changes for quality control purposes. 

Due to the variations from state to state, we used to use multiple SQL scripts to generate the necessary data. We then had to manually combine the data using Excel, which was a time-consuming process and prone to errors. To address these challenges, I developed a set of dynamic SQL scripts capable of handling all states. Additionally, I integrated a Python script to further transform the data into the final Excel format that seamlessly integrates with our Excel raters. This automation significantly streamlines the process, reduces errors, and enhances efficiency.

In addition, our Actuarial team utilizes their own rating engine called SQL-rerater on the SQL server. This rating engine performs premium calculations and incorporates various complex methods when making rate changes. However, due to the intricacy of the rating engine and the numerous steps involved, occasional errors can occur, resulting in incorrect factors being applied.
In cases where we don't match the overall rate change filed by the actuaries, we compare the factors applied in the SQL-rerater to the factors applied in our Excel rater. To expedite this comparison process, I have developed another Python script that retrieves the factors from the actuarial SQL results and outputs them to an Excel workbook. Our team members can then copy and paste the factors generated from our Excel rater into the side columns of the workbook. By utilizing conditional formatting, any unmatched factors will be immediately visible to us.
This approach allows for a faster and more efficient comparison of factors between the SQL-rerater and our Excel rater. By quickly identifying any discrepancies through visual cues, our team can address and resolve issues effectively.

1 - Scripts to generate in-force data:

    - 3 SQL scripts
    
    - GW_Inforce_Auto_Situations_GW.py
    
2 - Script to do factor comparison:

    - GW_SQL-Rater_Factors_Comparison.py

3 - Sample Excel outputs:

    - in-force data Excel output

    - factor comparison Excel output
