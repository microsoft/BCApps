// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Comment;

using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;

page 5222 "Human Resource Comment Sheet"
{
    AutoSplitKey = true;
    Caption = 'Comment Sheet';
    DataCaptionExpression = Caption(Rec);
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Human Resource Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the date the comment was created.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the comment itself.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies a code for the comment.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine();
    end;

    var
        Employee: Record Employee;
        EmployeeAbsence: Record "Employee Absence";
        EmployeeQualification: Record "Employee Qualification";
        EmployeeRelative: Record "Employee Relative";
        MiscArticleInfo: Record "Misc. Article Information";
        ConfidentialInfo: Record "Confidential Information";
        UntitledTxt: Label 'untitled';

    procedure Caption(HRCommentLine: Record "Human Resource Comment Line") Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCaption(HRCommentLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case HRCommentLine."Table Name" of
            HRCommentLine."Table Name"::"Employee Absence":
                if EmployeeAbsence.Get(HRCommentLine."Table Line No.") then begin
                    Employee.Get(EmployeeAbsence."Employee No.");
                    exit(
                      Employee."No." + ' ' + Employee.FullName() + ' ' +
                      EmployeeAbsence."Cause of Absence Code" + ' ' +
                      Format(EmployeeAbsence."From Date"));
                end;
            HRCommentLine."Table Name"::Employee:
                if Employee.Get(HRCommentLine."No.") then
                    exit(HRCommentLine."No." + ' ' + Employee.FullName());
            HRCommentLine."Table Name"::"Alternative Address":
                if Employee.Get(HRCommentLine."No.") then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      HRCommentLine."Alternative Address Code");
            HRCommentLine."Table Name"::"Employee Qualification":
                if EmployeeQualification.Get(HRCommentLine."No.", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      EmployeeQualification."Qualification Code");
            HRCommentLine."Table Name"::"Employee Relative":
                if EmployeeRelative.Get(HRCommentLine."No.", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      EmployeeRelative."Relative Code");
            HRCommentLine."Table Name"::"Misc. Article Information":
                if MiscArticleInfo.Get(
                     HRCommentLine."No.", HRCommentLine."Alternative Address Code", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      MiscArticleInfo."Misc. Article Code");
            HRCommentLine."Table Name"::"Confidential Information":
                if ConfidentialInfo.Get(HRCommentLine."No.", HRCommentLine."Table Line No.") and
                   Employee.Get(HRCommentLine."No.")
                then
                    exit(
                      HRCommentLine."No." + ' ' + Employee.FullName() + ' ' +
                      ConfidentialInfo."Confidential Code");
        end;
        exit(UntitledTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCaption(HRCommentLine: Record "Human Resource Comment Line"; var Result: Text; var IsHandled: Boolean)
    begin
    end;
}

