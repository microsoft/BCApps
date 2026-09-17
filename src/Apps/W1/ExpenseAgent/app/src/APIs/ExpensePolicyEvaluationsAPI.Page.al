// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7126 "Expense Policy Evaluations API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Expense Policy Evaluation';
    EntitySetCaption = 'Expense Policy Evaluations';
    DelayedInsert = true;
    EntityName = 'expensePolicyEvaluation';
    EntitySetName = 'expensePolicyEvaluations';
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = "Expense Policy Evaluation";
    AboutText = 'Provides access to expense policy evaluation results';
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
                field(subjectVersion; SubjectVersionInput)
                {
                    Caption = 'Subject Version';
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
                field(policyVersion; PolicyVersionInput)
                {
                    Caption = 'Policy Version';
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
                field(evaluatedAt; Rec."Evaluated At")
                {
                    Caption = 'Evaluated At';
                    Editable = false;
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
        InitializeVersionInputs();
    end;

    trigger OnAfterGetRecord()
    begin
        SubjectVersionInput := Rec."Subject Version";
        PolicyVersionInput := Rec."Policy Version";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        InitializeVersionInputs();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if SubjectVersionInput < 0 then
            Error(SubjectVersionRequiredErr);
        if PolicyVersionInput < 0 then
            Error(PolicyVersionRequiredErr);

        Rec."Subject Version" := SubjectVersionInput;
        Rec."Policy Version" := PolicyVersionInput;
        exit(true);
    end;

    local procedure InitializeVersionInputs()
    begin
        SubjectVersionInput := -1;
        PolicyVersionInput := -1;
    end;

    var
        SubjectVersionInput: Integer;
        PolicyVersionInput: Integer;
        SubjectVersionRequiredErr: Label 'Subject Version is required.';
        PolicyVersionRequiredErr: Label 'Policy Version is required.';
}
