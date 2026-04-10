This module provides functionality for handling data classification for objects that might contain sensitive information.

Use this module to do the following:
- create an entry in the Data Sensitivity table for every field in the database that might contain sensitive information 
- set the data sensitivity for a given field 
- synchronize the Data Sensitivity and Field tables by introducing new entries in the Data Sensitivity table for every new entry in the Field table 
- query on whether or not all the fields are classified 
- query on whether or not the Data Sensitivity table is empty for the current company 
- insert a new Data Sensitivity entry in the database for a given field 
- insert a new Data Privacy Entities entry in the database for a given table 
- get the date when the Field and Data Sensitivity tables have last been synchronized 
- raise an event to retrieve all the Data Privacy Entities 

