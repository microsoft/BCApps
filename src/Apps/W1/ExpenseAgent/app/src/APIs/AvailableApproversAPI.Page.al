// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7420 "Available Approvers API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Available Approver';
    EntitySetCaption = 'Available Approvers';
    EntityName = 'availableApprover';
    EntitySetName = 'availableApprovers';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Expense User";
    SourceTableView = where("Can Approve" = const(true), "Employee No." = filter(<> ''));
    AboutText = 'Lists expense users with an employee link who can approve.';

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
                field(number; Rec."No.")
                {
                    Caption = 'Number';
                }
                field(employeeNumber; Rec."Employee No.")
                {
                    Caption = 'Employee Number';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(eMail; Rec."E-mail")
                {
                    Caption = 'Email';
                }
                field(jobTitle; Rec."Job Title")
                {
                    Caption = 'Job Title';
                }
                field(canApprove; Rec."Can Approve")
                {
                    Caption = 'Can Approve';
                }
                field(employeeStatus; Rec."Employee Status")
                {
                    Caption = 'Employee Status';
                }
                field(approvalLimitLCY; Rec."Approval Limit (LCY)")
                {
                    Caption = 'Approval Limit (LCY)';
                }
                field(unlimitedApproval; Rec."Unlimited Approval")
                {
                    Caption = 'Unlimited Approval';
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
