// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

using Microsoft.Projects.Resources.Resource;

query 269 "Res. Ledger Entries"
{
    Caption = 'Res. Ledger Entries';

    elements
    {
        dataitem(Res_Ledger_Entry; "Res. Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Entry_Type; "Entry Type")
            {
            }
            column(Resource_No; "Resource No.")
            {
            }
            column(Resource_Group_No; "Resource Group No.")
            {
            }
            column(Job_No; "Job No.")
            {
            }
            column(Work_Type_Code; "Work Type Code")
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
            column(Gen_Bus_Posting_Group; "Gen. Bus. Posting Group")
            {
            }
            column(Gen_Prod_Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Source_Code; "Source Code")
            {
            }
            column(Reason_Code; "Reason Code")
            {
            }
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }
            column(Quantity; Quantity)
            {
            }
            column(Quantity_Base; "Quantity (Base)")
            {
            }
            column(Direct_Unit_Cost; "Direct Unit Cost")
            {
            }
            column(Unit_Cost; "Unit Cost")
            {
            }
            column(Total_Cost; "Total Cost")
            {
            }
            column(Unit_Price; "Unit Price")
            {
            }
            column(Total_Price; "Total Price")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Resource; Resource)
            {
                DataItemLink = "No." = Res_Ledger_Entry."Resource No.";
                column(Resource_Name; Name)
                {
                }
                dataitem(Resource_Group; "Resource Group")
                {
                    DataItemLink = "No." = Res_Ledger_Entry."Resource Group No.";
                    column(Resource_Group_Name; Name)
                    {
                    }
                }
            }
        }
    }
}

