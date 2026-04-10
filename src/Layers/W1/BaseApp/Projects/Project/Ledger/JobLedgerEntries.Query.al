// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Ledger;

using Microsoft.Projects.Project.Job;

query 268 "Job Ledger Entries"
{
    Caption = 'Project Ledger Entries';

    elements
    {
        dataitem(Job_Ledger_Entry; "Job Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Job_No; "Job No.")
            {
            }
            column(Job_Task_No; "Job Task No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Job_Posting_Group; "Job Posting Group")
            {
            }
            column(Resource_Group_No; "Resource Group No.")
            {
            }
            column(Work_Type_Code; "Work Type Code")
            {
            }
            column(Gen_Bus_Posting_Group; "Gen. Bus. Posting Group")
            {
            }
            column(Gen_Prod_Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Source_Code; "Source Code")
            {
            }
            column(Reason_Code; "Reason Code")
            {
            }
            column(Quantity_Base; "Quantity (Base)")
            {
            }
            column(Direct_Unit_Cost_LCY; "Direct Unit Cost (LCY)")
            {
            }
            column(Unit_Cost_LCY; "Unit Cost (LCY)")
            {
            }
            column(Total_Cost_LCY; "Total Cost (LCY)")
            {
            }
            column(Unit_Price_LCY; "Unit Price (LCY)")
            {
            }
            column(Total_Price_LCY; "Total Price (LCY)")
            {
            }
            column(Line_Amount_LCY; "Line Amount (LCY)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Job; Job)
            {
                DataItemLink = "No." = Job_Ledger_Entry."Job No.";
                column(Job_Description; Description)
                {
                }
            }
        }
    }
}

