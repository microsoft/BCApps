// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.History;

codeunit 5766 "Whse.-Post Receipt + Pr. Pos."
{
    TableNo = "Warehouse Receipt Line";

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code();
    end;

    var
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
#pragma warning disable AA0074
        Text001: Label 'Number of posted whse. receipts printed: 1.';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        WarehouseDocumentPrint: Codeunit "Warehouse Document-Print";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        WhsePostReceipt.Run(WhseReceiptLine);
        WhsePostReceipt.GetResultMessage();

        PostedWhseRcptHeader.SetRange("Whse. Receipt No.", WhseReceiptLine."No.");
        PostedWhseRcptHeader.SetRange("Location Code", WhseReceiptLine."Location Code");
        PostedWhseRcptHeader.FindLast();

        Commit();
        WarehouseDocumentPrint.PrintPostedRcptHeader(PostedWhseRcptHeader);
        Message(Text001);

        Clear(WhsePostReceipt);

        OnAfterCode(WhseReceiptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;
}

