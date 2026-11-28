// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

report 6901 "Delegate Travel Approval Req"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Delegate Travel Approval Request';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(TravelRequest; "Spend Request")
        {
            DataItemTableView = sorting("No.") where("Document Type" = const("Travel Request"), Status = const(Released));
            RequestFilterFields = "No.", "Requested For", "Approver Expense User No.", "Alternate Approver No.";

            trigger OnAfterGetRecord()
            var
                TravelRequestApproval: Codeunit "Travel Request Approval";
            begin
                Commit();
                TravelRequestApproval.AssignActiveAlternateApproverForTravelRequest(TravelRequest);
            end;
        }
    }
}