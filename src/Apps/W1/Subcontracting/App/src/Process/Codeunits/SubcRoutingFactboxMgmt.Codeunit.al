// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

codeunit 99001561 "Subc. Routing Factbox Mgmt."
{
    /// <summary>
    /// Returns the subcontractor vendor number for the work center on the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to retrieve the subcontractor for.</param>
    /// <returns>The subcontractor vendor number, or an empty string if the line is a machine center type.</returns>
    procedure GetSubcontractorNo(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then
            exit('');
        WorkCenter.SetLoadFields("Subcontractor No.");
        if WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
            exit(WorkCenter."Subcontractor No.");
    end;

    /// <summary>
    /// Opens the Vendor Card for the subcontractor assigned to the work center on the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line whose work center subcontractor to show.</param>
    procedure ShowSubcontractor(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then begin
            WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");
            if Vendor.Get(WorkCenter."Subcontractor No.") then
                Page.Run(Page::"Vendor Card", Vendor);
        end;
    end;

    /// <summary>
    /// Returns the total quantity on open purchase order lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to sum purchase order quantities for.</param>
    /// <returns>The sum of Quantity on matching open purchase order lines.</returns>
    procedure GetPurchOrderQtyFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.CalcSums(PurchaseLine.Quantity);
        exit(PurchaseLine.Quantity);
    end;

    /// <summary>
    /// Opens the Purchase Lines page filtered to open purchase lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to filter purchase lines by.</param>
    procedure ShowPurchaseOrderLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Operation No.", ProdOrderRoutingLine."Operation No.");

        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    /// <summary>
    /// Returns the total received quantity on purchase receipt lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to sum received quantities for.</param>
    /// <returns>The sum of Quantity on matching purchase receipt lines.</returns>
    procedure GetPurchReceiptQtyFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchRcptLine.SetRange(PurchRcptLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchRcptLine.CalcSums(PurchRcptLine.Quantity);
        exit(PurchRcptLine.Quantity);
    end;

    /// <summary>
    /// Opens the Purch. Receipt Lines page filtered to receipt lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to filter receipt lines by.</param>
    procedure ShowPurchaseReceiptLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchRcptLine.SetRange(PurchRcptLine."Operation No.", ProdOrderRoutingLine."Operation No.");

        Page.Run(Page::"Purch. Receipt Lines", PurchRcptLine);
    end;

    /// <summary>
    /// Returns the total invoiced quantity on purchase invoice lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to sum invoiced quantities for.</param>
    /// <returns>The sum of Quantity on matching purchase invoice lines.</returns>
    procedure GetPurchInvoicedQtyFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange(PurchInvLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchInvLine.SetRange(PurchInvLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchInvLine.SetRange(PurchInvLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchInvLine.CalcSums(PurchInvLine.Quantity);
        exit(PurchInvLine.Quantity);
    end;

    /// <summary>
    /// Opens the Posted Purchase Invoice Lines page filtered to invoice lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to filter invoice lines by.</param>
    procedure ShowPurchaseInvoiceLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetCurrentKey(PurchInvLine.Type, PurchInvLine."Prod. Order No.", PurchInvLine."Prod. Order Line No.");
        PurchInvLine.SetRange(PurchInvLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchInvLine.SetRange(PurchInvLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchInvLine.SetRange(PurchInvLine."Operation No.", ProdOrderRoutingLine."Operation No.");

        Page.Run(Page::"Posted Purchase Invoice Lines", PurchInvLine);
    end;

    /// <summary>
    /// Returns the number of outbound subcontracting transfer lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to count transfer lines for.</param>
    /// <returns>The count of matching outbound transfer lines.</returns>
    procedure GetNoOfTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Routing No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        TransferLine.SetRange(TransferLine."Routing No.", ProdOrderRoutingLine."Routing No.");
        TransferLine.SetRange(TransferLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        exit(TransferLine.Count());
    end;

    /// <summary>
    /// Returns the number of return subcontracting transfer lines linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to count return transfer lines for.</param>
    /// <returns>The count of matching return transfer lines.</returns>
    procedure GetNoOfReturnTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Routing Reference No.", 0);
        TransferLine.SetRange(TransferLine."Operation No.", '');
        exit(TransferLine.Count());
    end;

    /// <summary>
    /// Opens the Transfer Lines page filtered to outbound subcontracting transfer lines for the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to filter transfer lines by.</param>
    procedure ShowTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Routing No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        TransferLine.SetRange(TransferLine."Routing No.", ProdOrderRoutingLine."Routing No.");
        TransferLine.SetRange(TransferLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    /// <summary>
    /// Opens the Transfer Lines page filtered to return subcontracting transfer lines for the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to filter return transfer lines by.</param>
    procedure ShowReturnTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Routing Reference No.", 0);
        TransferLine.SetRange(TransferLine."Operation No.", '');
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    /// <summary>
    /// Returns the number of production order components linked via routing link code to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to count linked components for.</param>
    /// <returns>The count of matching production order components, or 0 if the routing link code is empty.</returns>
    procedure GetNoOfLinkedComponentsFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit(0);
        ProdOrderComponent.SetRange(ProdOrderComponent.Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        exit(ProdOrderComponent.Count());
    end;

    /// <summary>
    /// Opens the Subc. Prod. Order Components page filtered to components linked to the given production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production order routing line to filter production order components by.</param>
    procedure ShowProdOrderComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(ProdOrderComponent.Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        Page.Run(Page::"Subc. Prod. Order Components", ProdOrderComponent);
    end;
}
