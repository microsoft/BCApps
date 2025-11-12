// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Setup;

codeunit 5762 "Whse.-Post Receipt + Print"
{
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code();
        Rec := WhseReceiptLine;
    end;

    var
        WhseActivHeader: Record "Warehouse Activity Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        PrintedDocuments: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Number of put-away activities printed: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        ReportSelectionWarehouse: Record "Report Selection Warehouse";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        ShouldRunPrint: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        WhsePostReceipt.Run(WhseReceiptLine);
        WhsePostReceipt.GetResultMessage();

        PrintedDocuments := 0;
        ShouldRunPrint := WhsePostReceipt.GetFirstPutAwayDocument(WhseActivHeader);
        OnCodeOnAfterCalcShouldRunPrint(WhseReceiptLine, WhsePostReceipt, ShouldRunPrint);
        if ShouldRunPrint then begin
            repeat
                WhseActivHeader.SetRecFilter();
                OnBeforePrintReport(WhseActivHeader);
                ReportSelectionWarehouse.PrintWhseActivityHeader(WhseActivHeader, Enum::"Report Selection Warehouse Usage"::"Put-away", true);
                OnAfterPrintReport(WhseActivHeader);
                PrintedDocuments := PrintedDocuments + 1;
            until not WhsePostReceipt.GetNextPutAwayDocument(WhseActivHeader);
            Message(Text001, PrintedDocuments);
        end;
        Clear(WhsePostReceipt);

        OnAfterCode(WhseReceiptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintReport(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintReport(var WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldRunPrint(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var WhsePostReceipt: Codeunit "Whse.-Post Receipt"; var ShouldRunPrint: Boolean)
    begin
    end;
}
