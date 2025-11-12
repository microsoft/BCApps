// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9068 "Check Purch. Doc. Backgr."
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
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters.FromArgs(Args);
        PurchaseHeader.Get(ErrorHandlingParameters."Purchase Document Type", ErrorHandlingParameters."Document No.");
        if ErrorHandlingParameters."Full Document Check" then
            RunPurchaseDocCheckCodeunit(PurchaseHeader, TempErrorMessage)
        else
            if ErrorHandlingParameters."Line No." <> 0 then begin
                PurchaseLine.Get(ErrorHandlingParameters."Purchase Document Type", ErrorHandlingParameters."Document No.", ErrorHandlingParameters."Line No.");
                RunPurchaseDocLineCheckCodeunit(PurchaseHeader, PurchaseLine, TempErrorMessage);
            end;
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunPurchaseDocCheckCodeunit(PurchaseHeader: Record "Purchase Header"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempFoundErrorMessage: Record "Error Message" temporary;
        CheckPurchaseDocument: Codeunit "Check Purchase Document";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchaseHeader.RecordId, 0, '');

        if CheckPurchaseDocument.Run(PurchaseHeader) then begin
            ErrorMessageMgt.GetErrors(TempFoundErrorMessage);
            ErrorMessageMgt.CollectErrors(TempFoundErrorMessage);
            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end else begin
            InsertTempLineErrorMessage(
                TempFoundErrorMessage,
                PurchaseHeader.RecordId(),
                0,
                GetLastErrorText(),
                false);

            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end;
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunPurchaseDocLineCheckCodeunit(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempFoundErrorMessage: Record "Error Message" temporary;
        CheckPurchaseDocumentLine: Codeunit "Check Purchase Document Line";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, PurchaseHeader.RecordId, 0, '');
        CheckPurchaseDocumentLine.SetPurchaseHeader(PurchaseHeader);
        if CheckPurchaseDocumentLine.Run(PurchaseLine) then begin
            ErrorMessageMgt.GetErrors(TempFoundErrorMessage);
            ErrorMessageMgt.CollectErrors(TempFoundErrorMessage);
            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end else begin
            if not ErrorMessageMgt.GetErrors(TempFoundErrorMessage) then
                InsertTempLineErrorMessage(
                    TempFoundErrorMessage,
                    PurchaseHeader.RecordId(),
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
        TempLineErrorMessage."Table Number" := Database::"Purchase Header";
        TempLineErrorMessage."Context Record ID" := ContextRecordId;
        TempLineErrorMessage."Context Field Number" := ContextFieldNo;
        TempLineErrorMessage."Context Table Number" := Database::"Purchase Header";
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
