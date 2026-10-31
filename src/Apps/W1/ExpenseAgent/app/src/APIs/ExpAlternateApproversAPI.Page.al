// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7147 "Exp. Alternate Approvers API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Alternate Approver';
    EntitySetCaption = 'Expense Alternate Approvers';
    EntityName = 'expenseAlternateApprover';
    EntitySetName = 'expenseAlternateApprovers';
    PageType = API;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Alternate Approver";
    AboutText = 'Provides access to configured primary and alternate approver coverage windows.';

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
                field(primaryApproverNumber; Rec."Primary Approver No.")
                {
                    Caption = 'Primary Approver Number';
                }
                field(primaryApproverSystemId; PrimaryApproverSystemId)
                {
                    Caption = 'Primary Approver System Id';
                }
                field(alternateApproverNumber; Rec."Alternate Approver No.")
                {
                    Caption = 'Alternate Approver Number';
                }
                field(alternateApproverSystemId; AlternateApproverSystemId)
                {
                    Caption = 'Alternate Approver System Id';
                }
                field(effectiveStartDate; Rec."Effective Start Date")
                {
                    Caption = 'Effective Start Date';
                }
                field(effectiveEndDate; Rec."Effective End Date")
                {
                    Caption = 'Effective End Date';
                }
            }
        }
    }

    var
        PrimaryApproverSystemId: Guid;
        AlternateApproverSystemId: Guid;

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
        PrimaryApproverSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Primary Approver No.");
        AlternateApproverSystemId := ExpenseUser.GetSystemIdByExpenseUserNo(Rec."Alternate Approver No.");
    end;
}
