// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

using Microsoft.Utilities;

codeunit 379 "Transfer Old Ext. Text Lines"
{

    trigger OnRun()
    begin
    end;

    var
        TempLineNumberBuffer: Record "Line Number Buffer" temporary;

    local procedure InsertLineNumbers(OldLineNo: Integer; NewLineNo: Integer)
    begin
        TempLineNumberBuffer."Old Line Number" := OldLineNo;
        TempLineNumberBuffer."New Line Number" := NewLineNo;
        TempLineNumberBuffer.Insert();
    end;

    procedure GetNewLineNumber(OldLineNo: Integer): Integer
    begin
        if TempLineNumberBuffer.Get(OldLineNo) then
            exit(TempLineNumberBuffer."New Line Number");

        exit(0);
    end;

    procedure ClearLineNumbers()
    begin
        TempLineNumberBuffer.DeleteAll();
    end;

    procedure TransferExtendedText(OldLineNo: Integer; NewLineNo: Integer; AttachedLineNo: Integer) Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferExtendedText(OldLineNo, NewLineNo, AttachedLineNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        InsertLineNumbers(OldLineNo, NewLineNo);
        if AttachedLineNo <> 0 then
            exit(GetNewLineNumber(AttachedLineNo));

        exit(0);
    end;

    procedure GetLineNoBuffer(var OutTempLineNumberBuffer: Record "Line Number Buffer" temporary)
    begin
        OutTempLineNumberBuffer.Copy(TempLineNumberBuffer, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferExtendedText(OldLineNo: Integer; NewLineNo: Integer; AttachedLineNo: Integer; var Result: Integer; var IsHandled: Boolean)
    begin
    end;
}

