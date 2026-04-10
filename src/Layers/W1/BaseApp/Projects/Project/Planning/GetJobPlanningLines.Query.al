// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;

query 1033 GetJobPlanningLines
{
    QueryType = Normal;
    Caption = 'Get Job Planning Lines';

    elements
    {
        dataitem(Job; Job)
        {
            filter(Task_Billing_Method_Filter; "Task Billing Method") { }
            filter(Job_Bill_to_Customer_No_Filter; "Bill-to Customer No.") { }
            filter(Job_Sell_to_Customer_No_Filter; "Sell-to Customer No.") { }
            filter(Job_Invoice_Currency_Code_Filter; "Invoice Currency Code") { }

            dataitem(Job_Task; "Job Task")
            {
                DataItemLink = "Job No." = Job."No.";
                SqlJoinType = InnerJoin;

                filter(Task_Bill_to_Customer_No_Filter; "Bill-to Customer No.") { }
                filter(Task_Sell_to_Customer_No_Filter; "Sell-to Customer No.") { }
                filter(Task_Invoice_Currency_Code_Filter; "Invoice Currency Code") { }

                dataitem(Job_Planning_Line; "Job Planning Line")
                {
                    DataItemLink = "Job No." = Job_Task."Job No.", "Job Task No." = Job_Task."Job Task No.";
                    SqlJoinType = InnerJoin;

                    filter(Line_Type_Filter; "Line Type") { }
                    filter(Qty_to_Transfer_to_Invoice_Filter; "Qty. to Transfer to Invoice") { }

                    column(Job_No; "Job No.") { }
                    column(Job_Task_No; "Job Task No.") { }
                    column(Line_No; "Line No.") { }
                }
            }
        }
    }
}