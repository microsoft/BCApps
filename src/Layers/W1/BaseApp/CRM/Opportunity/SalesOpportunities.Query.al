// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

query 105 "Sales Opportunities"
{
    Caption = 'Sales Opportunities';

    elements
    {
        dataitem(Opportunity; Opportunity)
        {
            column(No; "No.")
            {
            }
            column(Description; Description)
            {
            }
            column(Creation_Date; "Creation Date")
            {
            }
            column(Closed; Closed)
            {
            }
            column(Sales_Cycle_Code; "Sales Cycle Code")
            {
            }
            column(Date_Closed; "Date Closed")
            {
            }
            column(Priority; Priority)
            {
            }
            column(Status; Status)
            {
            }
            column(Calcd_Current_Value_LCY; "Calcd. Current Value (LCY)")
            {
            }
            column(Chances_of_Success; "Chances of Success %")
            {
            }
            column(Completed; "Completed %")
            {
            }
            column(Contact_Name; "Contact Name")
            {
            }
            column(Estimated_Closing_Date; "Estimated Closing Date")
            {
            }
            column(Salesperson_Name; "Salesperson Name")
            {
            }
            column(Estimated_Value_LCY; "Estimated Value (LCY)")
            {
            }
            column(Contact_Company_Name; "Contact Company Name")
            {
            }
        }
    }
}

