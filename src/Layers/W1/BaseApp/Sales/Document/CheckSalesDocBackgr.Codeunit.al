// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9072 "Check Sales Doc. Backgr."
{
    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMsgMgt: Codeunit "Error Message Management";
        Args: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        Sleep(100);
        Args := Page.GetBackgroundParameters();

        RunCheck(Args, TempErrorMessage);

        ErrorMsgMgt.PackErrorMessagesToResults(TempErrorMessage, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    var
        ErrorMessageMgt: Codeunit "Error Message Management";

    procedure RunCheck(Args: Dictionary of [Text, Text]; var TempErrorMessage: Record "Error Message" temporary)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters.FromArgs(Args);
        SalesHeader.Get(ErrorHandlingParameters."Sales Document Type", ErrorHandlingParameters."Document No.");
        if ErrorHandlingParameters."Full Document Check" then
            RunSalesDocCheckCodeunit(SalesHeader, TempErrorMessage)
        else
            if ErrorHandlingParameters."Line No." <> 0 then begin
                SalesLine.Get(ErrorHandlingParameters."Sales Document Type", ErrorHandlingParameters."Document No.", ErrorHandlingParameters."Line No.");
                RunSalesDocLineCheckCodeunit(SalesHeader, SalesLine, TempErrorMessage);
            end;
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunSalesDocCheckCodeunit(SalesHeader: Record "Sales Header"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempFoundErrorMessage: Record "Error Message" temporary;
        CheckSalesDocument: Codeunit "Check Sales Document";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, '');

        if CheckSalesDocument.Run(SalesHeader) then begin
            ErrorMessageMgt.GetErrors(TempFoundErrorMessage);
            ErrorMessageMgt.CollectErrors(TempFoundErrorMessage);
            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end else begin
            InsertTempLineErrorMessage(
                TempFoundErrorMessage,
                SalesHeader.RecordId(),
                0,
                GetLastErrorText(),
                false);

            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end;
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunSalesDocLineCheckCodeunit(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempFoundErrorMessage: Record "Error Message" temporary;
        CheckSalesDocumentLine: Codeunit "Check Sales Document Line";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, '');
        CheckSalesDocumentLine.SetSalesHeader(SalesHeader);
        if CheckSalesDocumentLine.Run(SalesLine) then begin
            ErrorMessageMgt.GetErrors(TempFoundErrorMessage);
            ErrorMessageMgt.CollectErrors(TempFoundErrorMessage);
            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end else begin
            if not ErrorMessageMgt.GetErrors(TempFoundErrorMessage) then
                InsertTempLineErrorMessage(
                    TempFoundErrorMessage,
                    SalesHeader.RecordId(),
                    0,
                    GetLastErrorText(),
                    false);

            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end;
    end;

    local procedure InsertTempLineErrorMessage(var TempLineErrorMessage: Record "Error Message" temporary; ContextRecordId: RecordId; ContextFieldNo: Integer; Description: Text; Duplicate: Boolean)
    begin
        TempLineErrorMessage."Record ID" := ContextRecordId;
        TempLineErrorMessage."Field Number" := ContextFieldNo;
        TempLineErrorMessage."Table Number" := Database::"Sales Header";
        TempLineErrorMessage."Context Record ID" := ContextRecordId;
        TempLineErrorMessage."Context Field Number" := ContextFieldNo;
        TempLineErrorMessage."Context Table Number" := Database::"Sales Header";
        TempLineErrorMessage."Message" := CopyStr(Description, 1, MaxStrLen(TempLineErrorMessage."Message"));
        TempLineErrorMessage.Duplicate := Duplicate;
        TempLineErrorMessage.Insert();
    end;

    local procedure CopyErrorsToBuffer(var TempLineErrorMessage: Record "Error Message" temporary; var TempErrorMessage: Record "Error Message" temporary)
    var
        ID: Integer;
    begin
        if TempErrorMessage.FindLast() then;
        ID := TempErrorMessage.ID + 1;

        if TempLineErrorMessage.FindSet() then
            repeat
                TempErrorMessage.Init();
                if TempLineErrorMessage."Error Call Stack".HasValue() then
                    TempLineErrorMessage.CalcFields("Error Call Stack");
                TempErrorMessage.TransferFields(TempLineErrorMessage);
                TempErrorMessage.ID := ID;
                TempErrorMessage.Insert();
                ID += 1;
            until TempLineErrorMessage.Next() = 0;
    end;
}
