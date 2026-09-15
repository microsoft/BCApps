// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Utilities;
using System.Utilities;

page 9123 "Res. Journal Errors Factbox"
{
    PageType = ListPart;
    Caption = 'Journal Check';
    Editable = false;
    LinksAllowed = false;
    SourceTable = "Res. Journal Line";

    layout
    {
        area(content)
        {
            cuegroup(Control1)
            {
                ShowCaption = false;
                field(NumberOfLinesChecked; NumberOfLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lines checked';
                    ToolTip = 'Specifies the number of journal lines that have been checked for potential issues.';
                }
                field(NumberOfLinesWithErrors; NumberOfLinesWithErrors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lines with issues';
                    ToolTip = 'Specifies the number of journal lines that have issues.';
                }
                field(NumberOfBatchErrors; NumberOfBatchErrors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issues Total';
                    ToolTip = 'Specifies the number of issues that have been found in the journal.';
                    StyleExpr = TotalErrorsStyleTxt;

                    trigger OnDrillDown()
                    begin
                        TempErrorMessage.Reset();
                        TempErrorMessage.SetRange(Duplicate, false);
                        Page.Run(Page::"Error Messages", TempErrorMessage);
                    end;
                }
            }
            group(Control2)
            {
                Caption = 'Current line';
                field(Error1; ErrorText[1])
                {
                    ShowCaption = false;
                    ApplicationArea = Basic, Suite;
                    StyleExpr = CurrentLineStyleTxt;
                }
                field(Error2; ErrorText[2])
                {
                    ShowCaption = false;
                    ApplicationArea = Basic, Suite;
                    StyleExpr = CurrentLineStyleTxt;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            CheckErrorsInBackground();
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId = TaskIdCountErrors then begin
            BackgroundErrorHandlingMgt.GetErrorsFromResJnlCheckResultValues(Results.Values, TempErrorMessage, ErrorHandlingParameters);
            CalcErrors();
            NumberOfLines := GetNumberOfLines();
        end;
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    begin
        if TaskId = TaskIdCountErrors then
            IsHandled := true;
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        TaskIdCountErrors: Integer;
        NumberOfBatchErrors: Integer;
        NumberOfLineErrors: Integer;
        NumberOfLines: Integer;
        NumberOfLinesWithErrors: Integer;
        TotalErrorsStyleTxt: Text;
        CurrentLineStyleTxt: Text;
        ErrorText: array[2] of Text;
        OtherIssuesTxt: Label '(+%1 other issues)', comment = '%1 - number of issues';
        NoIssuesFoundTxt: Label 'No issues found.';

    local procedure GetTotalErrorsStyle(): Text
    begin
        if NumberOfBatchErrors = 0 then
            exit('Favorable')
        else
            exit('Unfavorable');
    end;

    local procedure GetCurrentLineStyle(): Text
    begin
        if NumberOfLineErrors = 0 then
            exit('Standard')
        else
            exit('Attention');
    end;

    local procedure GetNumberOfLines(): Integer
    var
        ResJnlLine: Record "Res. Journal Line";
    begin
        ResJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        exit(ResJnlLine.Count());
    end;

    local procedure CheckErrorsInBackground()
    var
        ResJournalErrorsMgt: Codeunit "Res. Journal Errors Mgt.";
        Args: Dictionary of [Text, Text];
    begin
        BackgroundErrorHandlingMgt.FeatureTelemetryLogUptakeUsed();
        if TaskIdCountErrors <> 0 then
            CurrPage.CancelBackgroundTask(TaskIdCountErrors);

        ResJournalErrorsMgt.CollectResJnlCheckParameters(Rec, ErrorHandlingParameters);
        ErrorHandlingParameters.ToArgs(Args);

        CurrPage.EnqueueBackgroundTask(TaskIdCountErrors, Codeunit::"Check Res. Jnl. Line. Backgr.", Args);
    end;

    local procedure CalcErrors()
    var
        NumberOfErrors: Integer;
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange(Duplicate, false);
        BackgroundErrorHandlingMgt.FeatureTelemetryLogUsage(not TempErrorMessage.IsEmpty, Rec.TableName);
        NumberOfBatchErrors := TempErrorMessage.Count();
        TempErrorMessage.SetRange(Duplicate);
        TempErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        NumberOfLineErrors := TempErrorMessage.Count();

        Clear(ErrorText);
        NumberOfErrors := TempErrorMessage.Count();
        if TempErrorMessage.FindFirst() then
            ErrorText[1] := TempErrorMessage."Message"
        else
            ErrorText[1] := NoIssuesFoundTxt;

        if NumberOfErrors > 2 then
            ErrorText[2] := StrSubstNo(OtherIssuesTxt, NumberOfErrors - 1)
        else
            if TempErrorMessage.Next() <> 0 then
                ErrorText[2] := TempErrorMessage."Message";

        TotalErrorsStyleTxt := GetTotalErrorsStyle();
        CurrentLineStyleTxt := GetCurrentLineStyle();
        NumberOfLinesWithErrors := GetNumberOfLinesWithErrors();
    end;

    local procedure GetNumberOfLinesWithErrors(): Integer
    var
        TempLineErrorMessage: Record "Error Message" temporary;
    begin
        TempErrorMessage.Reset();
        if TempErrorMessage.FindSet() then
            repeat
                TempLineErrorMessage.SetRange("Context Record ID", TempErrorMessage."Context Record ID");
                if TempLineErrorMessage.IsEmpty() then begin
                    TempLineErrorMessage := TempErrorMessage;
                    TempLineErrorMessage.Insert();
                end;
            until TempErrorMessage.Next() = 0;

        TempLineErrorMessage.Reset();
        exit(TempLineErrorMessage.Count());
    end;
}
