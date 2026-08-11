// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6969 "Approver View API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Approver View';
    EntitySetCaption = 'Approver Views';
    EntityName = 'approverView';
    EntitySetName = 'approverViews';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Expense User";
    AboutText = 'Provides a view for expense approvers, for example to see expense reports pending their approval.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(employeeNumber; Rec."Employee No.")
                {
                    Caption = 'Employee Number';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'Expense User Number';
                    Editable = false;
                }

                part(expenseReportsPendingApproval; "Expense Reports API")
                {
                    EntityName = 'expenseReport';
                    EntitySetName = 'expenseReports';
                    SubPageLink = "Pending Approval By" = field("No."),
                                    Status = const("Pending Approval");
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}