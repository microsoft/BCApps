// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9084 "Check Service Doc. Backgr."
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
        ServiceHeader: Record "Service Header";
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters.FromArgs(Args);
        ServiceHeader.Get(ErrorHandlingParameters."Service Document Type", ErrorHandlingParameters."Document No.");
        RunServiceDocCheckCodeunit(ServiceHeader, TempErrorMessage);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunServiceDocCheckCodeunit(ServiceHeader: Record "Service Header"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempFoundErrorMessage: Record "Error Message" temporary;
        CheckServiceDocument: Codeunit "Check Service Document";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, ServiceHeader.RecordId, 0, '');

        if CheckServiceDocument.Run(ServiceHeader) then begin
            ErrorMessageMgt.GetErrors(TempFoundErrorMessage);
            ErrorMessageMgt.CollectErrors(TempFoundErrorMessage);
            CopyErrorsToBuffer(TempFoundErrorMessage, TempErrorMessage);
        end else begin
            InsertTempLineErrorMessage(
                TempFoundErrorMessage,
                ServiceHeader.RecordId(),
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
        TempLineErrorMessage."Table Number" := Database::"Service Header";
        TempLineErrorMessage."Context Record ID" := ContextRecordId;
        TempLineErrorMessage."Context Field Number" := ContextFieldNo;
        TempLineErrorMessage."Context Table Number" := Database::"Service Header";
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
