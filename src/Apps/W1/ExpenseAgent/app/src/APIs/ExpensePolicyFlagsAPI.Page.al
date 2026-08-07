// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7102 "Expense Policy Flags API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Policy Flag';
    EntitySetCaption = 'Expense Policy Flags';
    DelayedInsert = true;
    EntityName = 'expensePolicyFlag';
    EntitySetName = 'expensePolicyFlags';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Policy Flag";
    AboutText = 'Provides access to data from the Expense Policy Flag table';
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

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
                field(subjectSystemId; Rec."Subject System Id")
                {
                    Caption = 'Subject System Id';
                }
                field(subjectType; Rec."Subject Type")
                {
                    Caption = 'Subject Type';
                }
                field(subjectVersion; Rec."Subject Version")
                {
                    Caption = 'Subject Version';
                    Editable = false;
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                    Editable = false;
                }
                field(policySystemId; Rec."Policy System Id")
                {
                    Caption = 'Policy System Id';
                }
                field(policyVersion; Rec."Policy Version")
                {
                    Caption = 'Policy Version';
                    Editable = false;
                }
                field(isCurrent; Rec."Is Current")
                {
                    Caption = 'Is Current';
                    Editable = false;
                }
                field(reason; Rec."Reason")
                {
                    Caption = 'Reason';
                }
                field(flaggedAt; Rec."Flagged At")
                {
                    Caption = 'Flagged At';
                }
                field(compliant; Rec."Compliant")
                {
                    Caption = 'Compliant';
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
