// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7108 "Exp. Policies To Eval API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'expense';
    APIVersion = 'beta';
    EntityName = 'policyToEvaluate';
    EntitySetName = 'policiesToEvaluate';
    EntityCaption = 'Policy To Evaluate';
    EntitySetCaption = 'Policies To Evaluate';
    SourceTable = "Exp. Policy To Eval Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = "Subject System Id", "Policy System Id";
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    AboutTitle = 'Policies To Evaluate';
    AboutText = 'Returns the enabled policies that still need to be evaluated for an expense report line - policies newly introduced or bumped to a new version, or any policy not yet evaluated at the line''s current version. Read this to know which policies to (re)run when a line is stale.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(subjectSystemId; Rec."Subject System Id")
                {
                    Caption = 'Subject System Id';
                }
                field(subjectVersion; Rec."Subject Version")
                {
                    Caption = 'Subject Version';
                }
                field(policySystemId; Rec."Policy System Id")
                {
                    Caption = 'Policy System Id';
                }
                field(policyLineNo; Rec."Policy Line No.")
                {
                    Caption = 'Policy Line No.';
                }
                field(policyVersion; Rec."Policy Version")
                {
                    Caption = 'Policy Version';
                }
                field(expenseCategoryCode; Rec."Expense Category Code")
                {
                    Caption = 'Expense Category Code';
                }
                field(description; Rec."Description")
                {
                    Caption = 'Description';
                }
                field(policyText; Rec."Policy Text")
                {
                    Caption = 'Policy Text';
                }
            }
        }
    }

    var
        Builder: Codeunit "Exp. Policies To Eval Builder";
        BuiltSubjectFilter: Text;
        HasBuilt: Boolean;

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        SubjectFilter: Text;
        FilterView: Text;
    begin
        SubjectFilter := Rec.GetFilter("Subject System Id");
        // Rebuild whenever the parent subject changes so $expand across many lines stays correct.
        if (not HasBuilt) or (SubjectFilter <> BuiltSubjectFilter) then begin
            FilterView := Rec.GetView();
            Builder.Build(Rec, SubjectFilter);
            Rec.SetView(FilterView);
            BuiltSubjectFilter := SubjectFilter;
            HasBuilt := true;
        end;
        exit(Rec.Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(Rec.Next(Steps));
    end;
}
