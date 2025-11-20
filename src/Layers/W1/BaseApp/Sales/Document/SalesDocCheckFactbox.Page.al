// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Utilities;
using System.Utilities;

page 9119 "Sales Doc. Check Factbox"
{
    PageType = ListPart;
    Caption = 'Document Check';
    Editable = false;
    LinksAllowed = false;
    SourceTable = "Sales Header";

    layout
    {
        area(content)
        {
            cuegroup(Control1)
            {
                ShowCaption = false;
                field(NumberOfErrors; NumberOfErrors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issues Total';
                    ToolTip = 'Specifies the number of issues that have been found in the document.';
                    StyleExpr = TotalErrorsStyleTxt;

                    trigger OnDrillDown()
                    begin
                        TempErrorMessage.Reset();
                        TempErrorMessage.SetRange(Duplicate, false);
                        Page.Run(Page::"Error Messages", TempErrorMessage);
                    end;
                }
            }
#if not CLEAN27
            field(Refresh; RefreshTxt)
            {
                ApplicationArea = Basic, Suite;
                ShowCaption = false;
                ObsoleteReason = 'Use the Refresh action instead.';
                ObsoleteState = Pending;
                ObsoleteTag = '27.0';
                Visible = false;
                trigger OnDrillDown()
                var
                    DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
                begin
                    DocumentErrorsMgt.SetFullDocumentCheck(true);
                    CheckErrorsInBackground(Rec);
                end;
            }
#endif
            group(Control2)
            {
                Caption = 'Issues';
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

    actions
    {
        area(processing)
        {
            action(RefreshData)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the document check.';

                trigger OnAction()
                var
                    DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
                begin
                    DocumentErrorsMgt.SetFullDocumentCheck(true);
                    CheckErrorsInBackground(Rec);
                end;
            }
        }
    }

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId = TaskIdCountErrors then begin
            BackgroundErrorHandlingMgt.GetErrorsFromDocumentCheckResultValues(Results.Values, TempErrorMessage, ErrorHandlingParameters);
            CalcErrors();
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
        NumberOfErrors: Integer;
        TotalErrorsStyleTxt: Text;
        CurrentLineStyleTxt: Text;
        ErrorText: array[2] of Text;
        OtherIssuesTxt: Label '(+%1 other issues)', comment = '%1 - number of issues';
        NoIssuesFoundTxt: Label 'No issues found.';
#if not CLEAN27
        RefreshTxt: Label 'Refresh';
#endif
    local procedure GetTotalErrorsStyle(): Text
    begin
        if NumberOfErrors = 0 then
            exit('Favorable')
        else
            exit('Unfavorable');
    end;

    local procedure GetCurrentLineStyle(): Text
    begin
        if NumberOfErrors = 0 then
            exit('Standard')
        else
            exit('Attention');
    end;

    procedure CheckErrorsInBackground(SalesHeader: Record "Sales Header")
    var
        Args: Dictionary of [Text, Text];
    begin
        BackgroundErrorHandlingMgt.FeatureTelemetryLogUptakeUsed();
        if TaskIdCountErrors <> 0 then
            CurrPage.CancelBackgroundTask(TaskIdCountErrors);

        BackgroundErrorHandlingMgt.CollectSalesDocCheckParameters(SalesHeader, ErrorHandlingParameters);
        ErrorHandlingParameters.ToArgs(Args);

        CurrPage.EnqueueBackgroundTask(TaskIdCountErrors, Codeunit::"Check Sales Doc. Backgr.", Args);
    end;

    local procedure CalcErrors()
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange(Duplicate, false);
        BackgroundErrorHandlingMgt.FeatureTelemetryLogUsageSales(not TempErrorMessage.IsEmpty, Rec.TableName, Rec."Document Type");

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
    end;
}
