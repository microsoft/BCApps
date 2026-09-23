// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7105 "Posted Policy Evaluations API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Posted Expense Policy Evaluation';
    EntitySetCaption = 'Posted Expense Policy Evaluations';
    EntityName = 'postedExpensePolicyEvaluation';
    EntitySetName = 'postedExpensePolicyEvaluations';
    PageType = API;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    SourceTable = "Posted Exp. Policy Evaluation";
    AboutText = 'Provides access to posted expense policy evaluation results';

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
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(policySystemId; Rec."Policy System Id")
                {
                    Caption = 'Policy System Id';
                }
                field(policyVersion; Rec."Policy Version")
                {
                    Caption = 'Policy Version';
                }
                field(isCurrent; Rec."Is Current")
                {
                    Caption = 'Is Current';
                }
                field(reason; Rec."Reason")
                {
                    Caption = 'Reason';
                }
                field(evaluatedAt; Rec."Evaluated At")
                {
                    Caption = 'Evaluated At';
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
