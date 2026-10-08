// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6955 "Expense Approval Setup API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Approval Setup';
    EntitySetCaption = 'Expense Approval Setups';
    EntityName = 'expenseApprovalSetup';
    EntitySetName = 'expenseApprovalSetups';
    PageType = API;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Approval Setup";
    AboutText = 'Provides access to data from the Expense Approval Setup table';

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
                field(expenseUserNumber; Rec."Expense User No.")
                {
                    Caption = 'Expense User Number';
                }
                field(expenseUserSystemId; ExpenseUserSystemId)
                {
                    Caption = 'Expense User System Id';
                }
                field(entraId; Rec."Entra Id")
                {
                    Caption = 'Entra Id';
                }
                field(approverNumber; Rec."Approver No.")
                {
                    Caption = 'Approver Number';
                }
                field(approverSystemId; ApproverSystemId)
                {
                    Caption = 'Approver System Id';
                }
            }
        }
    }

    var
        ExpenseUserSystemId: Guid;
        ApproverSystemId: Guid;

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnAfterGetRecord()
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUserSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Expense User No.");
        ApproverSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Approver No.");
    end;
}