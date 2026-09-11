// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.History;

codeunit 6532 "E-Doc. Item Charge Mapping"
{
    Permissions =
        tabledata "Item Charge" = r,
        tabledata "Sales Invoice Line" = r,
        tabledata "Sales Cr.Memo Line" = r,
        tabledata "Value Entry" = r;

    var
        CachedDocumentLineNos: Dictionary of [Integer, Integer];
        CachedLineNoDocumentNo: Code[20];
        CachedInvoiceLineToKeepNo: Code[20];
        CachedCrMemoLineToKeepNo: Code[20];
        CachedInvoiceLineToKeep: Boolean;
        CachedCrMemoLineToKeep: Boolean;
        UnitCodeOneTok: Label 'C62', Locked = true;

    /// <summary>
    /// Determines which structure an item charge line of a posted sales invoice is exported as.
    /// A mapping override on the item charge takes precedence over the setting of the service.
    /// </summary>
    /// <param name="EDocumentService">The service that exports the document. Its Item Charge E-Invoice Mapping can force a structure unless the item charge overrides it.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice that is exported.</param>
    /// <param name="SalesInvoiceLine">The item charge line to classify. Must be of type Charge (Item).</param>
    /// <param name="TargetSalesInvoiceLine">Return value: the invoice line the charge belongs to. Only set for a line level allowance/charge.</param>
    /// <returns>The structure the item charge is exported as.</returns>
    procedure GetItemChargeStructure(EDocumentService: Record "E-Document Service"; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceLine: Record "Sales Invoice Line"; var TargetSalesInvoiceLine: Record "Sales Invoice Line") Structure: Enum "Item Charge E-Doc. Structure"
    var
        AssignedSalesInvoiceLine: Record "Sales Invoice Line";
        Mapping: Enum "Item Charge E-Invoice Mapping";
        AssignedLineNo: Integer;
        TargetLineNo: Integer;
        HasLineToKeep: Boolean;
        AssignedLineHasSameVAT: Boolean;
    begin
        SalesInvoiceLine.TestField(Type, SalesInvoiceLine.Type::"Charge (Item)");
        Clear(TargetSalesInvoiceLine);

        Mapping := GetEffectiveMapping(EDocumentService, SalesInvoiceLine."No.");
        if NeedsLineToKeep(Mapping) then
            HasLineToKeep := HasLineToKeepInInvoice(SalesInvoiceHeader."No.");
        if NeedsAssignedLine(Mapping) then begin
            AssignedLineNo := FindSingleAssignedLineNo(SalesInvoiceHeader."No.", SalesInvoiceLine."Line No.", SalesInvoiceLine."No.");
            if AssignedLineNo <> 0 then
                if AssignedSalesInvoiceLine.Get(SalesInvoiceHeader."No.", AssignedLineNo) then
                    AssignedLineHasSameVAT :=
                        HasSameVAT(
                            SalesInvoiceLine."VAT Calculation Type", SalesInvoiceLine."VAT %",
                            AssignedSalesInvoiceLine."VAT Calculation Type", AssignedSalesInvoiceLine."VAT %")
                else
                    AssignedLineNo := 0;
        end;

        Structure := GetStructure(Mapping, HasLineToKeep, AssignedLineNo, AssignedLineHasSameVAT, TargetLineNo);
        if TargetLineNo <> 0 then
            TargetSalesInvoiceLine.Get(SalesInvoiceHeader."No.", TargetLineNo);

        OnAfterGetItemChargeStructure(EDocumentService, SalesInvoiceHeader, SalesInvoiceLine, Structure, TargetSalesInvoiceLine);
    end;

    /// <summary>
    /// Determines which structure an item charge line of a posted sales credit memo is exported as.
    /// A mapping override on the item charge takes precedence over the setting of the service.
    /// </summary>
    /// <param name="EDocumentService">The service that exports the document. Its Item Charge E-Invoice Mapping can force a structure unless the item charge overrides it.</param>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo that is exported.</param>
    /// <param name="SalesCrMemoLine">The item charge line to classify. Must be of type Charge (Item).</param>
    /// <param name="TargetSalesCrMemoLine">Return value: the credit memo line the charge belongs to. Only set for a line level allowance/charge.</param>
    /// <returns>The structure the item charge is exported as.</returns>
    procedure GetItemChargeStructure(EDocumentService: Record "E-Document Service"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line"; var TargetSalesCrMemoLine: Record "Sales Cr.Memo Line") Structure: Enum "Item Charge E-Doc. Structure"
    var
        AssignedSalesCrMemoLine: Record "Sales Cr.Memo Line";
        Mapping: Enum "Item Charge E-Invoice Mapping";
        AssignedLineNo: Integer;
        TargetLineNo: Integer;
        HasLineToKeep: Boolean;
        AssignedLineHasSameVAT: Boolean;
    begin
        SalesCrMemoLine.TestField(Type, SalesCrMemoLine.Type::"Charge (Item)");
        Clear(TargetSalesCrMemoLine);

        Mapping := GetEffectiveMapping(EDocumentService, SalesCrMemoLine."No.");
        if NeedsLineToKeep(Mapping) then
            HasLineToKeep := HasLineToKeepInCrMemo(SalesCrMemoHeader."No.");
        if NeedsAssignedLine(Mapping) then begin
            AssignedLineNo := FindSingleAssignedLineNo(SalesCrMemoHeader."No.", SalesCrMemoLine."Line No.", SalesCrMemoLine."No.");
            if AssignedLineNo <> 0 then
                if AssignedSalesCrMemoLine.Get(SalesCrMemoHeader."No.", AssignedLineNo) then
                    AssignedLineHasSameVAT :=
                        HasSameVAT(
                            SalesCrMemoLine."VAT Calculation Type", SalesCrMemoLine."VAT %",
                            AssignedSalesCrMemoLine."VAT Calculation Type", AssignedSalesCrMemoLine."VAT %")
                else
                    AssignedLineNo := 0;
        end;

        Structure := GetStructure(Mapping, HasLineToKeep, AssignedLineNo, AssignedLineHasSameVAT, TargetLineNo);
        if TargetLineNo <> 0 then
            TargetSalesCrMemoLine.Get(SalesCrMemoHeader."No.", TargetLineNo);

        OnAfterGetSalesCrMemoItemChargeStructure(EDocumentService, SalesCrMemoHeader, SalesCrMemoLine, Structure, TargetSalesCrMemoLine);
    end;

    /// <summary>
    /// Gets the quantity to use when an item charge is exported as a regular document line.
    /// </summary>
    /// <returns>The quantity of the fallback document line.</returns>
    procedure GetFallbackQuantity(): Decimal
    begin
        exit(1);
    end;

    /// <summary>
    /// Gets the quantity to use when an item charge of the given net amount is exported as a regular document line.
    /// A negative net amount is reported as a negative quantity, because the item net price of a document line must never be negative.
    /// </summary>
    /// <param name="NetAmount">The net amount that the fallback document line reports.</param>
    /// <returns>The quantity of the fallback document line, negative if the net amount is negative.</returns>
    procedure GetFallbackQuantity(NetAmount: Decimal): Decimal
    begin
        if NetAmount < 0 then
            exit(-GetFallbackQuantity());

        exit(GetFallbackQuantity());
    end;

    /// <summary>
    /// Gets the net price to use when an item charge of the given net amount is exported as a regular document line.
    /// The fallback document line reports a single unit, so the price carries the whole net amount, and it is never negative.
    /// </summary>
    /// <param name="NetAmount">The net amount that the fallback document line reports.</param>
    /// <returns>The net price of the fallback document line. Never negative, so that the exported document satisfies BR-27.</returns>
    procedure GetFallbackUnitPrice(NetAmount: Decimal): Decimal
    var
        FallbackQuantity: Decimal;
    begin
        FallbackQuantity := GetFallbackQuantity();
        if FallbackQuantity = 0 then
            exit(NetAmount);

        exit(Abs(NetAmount) / Abs(FallbackQuantity));
    end;

    /// <summary>
    /// Gets the unit code to use when the given item charge is exported as a regular document line.
    /// </summary>
    /// <param name="ItemChargeNo">The item charge whose unit code override applies.</param>
    /// <returns>The E-Invoice Unit Code of the item charge, or C62 - the UN/ECE Recommendation 20 code for 'one' - if none is set.</returns>
    procedure GetFallbackUnitOfMeasureCode(ItemChargeNo: Code[20]): Code[10]
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.SetLoadFields("E-Invoice Unit Code");
        if ItemCharge.Get(ItemChargeNo) then
            if ItemCharge."E-Invoice Unit Code" <> '' then
                exit(ItemCharge."E-Invoice Unit Code");

        exit(UnitCodeOneTok);
    end;

    /// <summary>
    /// Gets the allowance/charge reason code and reason text to export for the given item charge.
    /// Both are plain field reads without any resolution rule, so they are returned together to read the item charge only once.
    /// An item charge that cannot be read yields empty values, so that a missing item charge behaves like an item charge without a reason.
    /// </summary>
    /// <param name="ItemChargeNo">The item charge whose reason applies.</param>
    /// <param name="ReasonCode">Return value: the E-Invoice Reason Code of the item charge, or an empty code if none is set.</param>
    /// <param name="ReasonText">Return value: the E-Invoice Reason Text of the item charge, or an empty text if none is set.</param>
    procedure GetItemChargeReason(ItemChargeNo: Code[20]; var ReasonCode: Code[10]; var ReasonText: Text[100])
    var
        ItemCharge: Record "Item Charge";
    begin
        ReasonCode := '';
        ReasonText := '';

        ItemCharge.SetLoadFields("E-Invoice Reason Code", "E-Invoice Reason Text");
        if not ItemCharge.Get(ItemChargeNo) then
            exit;

        ReasonCode := ItemCharge."E-Invoice Reason Code";
        ReasonText := ItemCharge."E-Invoice Reason Text";
    end;

    local procedure GetEffectiveMapping(EDocumentService: Record "E-Document Service"; ItemChargeNo: Code[20]) Mapping: Enum "Item Charge E-Invoice Mapping"
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.SetLoadFields("E-Invoice Mapping");
        if ItemCharge.Get(ItemChargeNo) then
            case ItemCharge."E-Invoice Mapping" of
                ItemCharge."E-Invoice Mapping"::Automatic:
                    exit(Mapping::Automatic);
                ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge":
                    exit(Mapping::"Document Allowance/Charge");
                ItemCharge."E-Invoice Mapping"::"Line Allowance/Charge":
                    exit(Mapping::"Line Allowance/Charge");
                ItemCharge."E-Invoice Mapping"::"Line with Unit Code":
                    exit(Mapping::"Line with Unit Code");
            end;

        exit(EDocumentService."Item Charge E-Invoice Mapping");
    end;

    local procedure NeedsAssignedLine(Mapping: Enum "Item Charge E-Invoice Mapping"): Boolean
    begin
        exit(Mapping in [Mapping::Automatic, Mapping::"Line Allowance/Charge"]);
    end;

    local procedure NeedsLineToKeep(Mapping: Enum "Item Charge E-Invoice Mapping"): Boolean
    begin
        exit(Mapping in [Mapping::Automatic, Mapping::"Document Allowance/Charge", Mapping::"Line Allowance/Charge"]);
    end;

    local procedure GetStructure(Mapping: Enum "Item Charge E-Invoice Mapping"; HasLineToKeep: Boolean; AssignedLineNo: Integer; AssignedLineHasSameVAT: Boolean; var TargetLineNo: Integer) Structure: Enum "Item Charge E-Doc. Structure"
    begin
        TargetLineNo := 0;

        // Turning the only line of the document into an allowance/charge would leave the document without any document line.
        if not HasLineToKeep then
            exit(Structure::"Line with Unit Code");

        case Mapping of
            Mapping::Automatic:
                begin
                    if AssignedLineNo = 0 then
                        exit(Structure::"Document Allowance/Charge");
                    if not AssignedLineHasSameVAT then
                        exit(Structure::"Document Allowance/Charge");
                    TargetLineNo := AssignedLineNo;
                    exit(Structure::"Line Allowance/Charge");
                end;
            Mapping::"Document Allowance/Charge":
                exit(Structure::"Document Allowance/Charge");
            Mapping::"Line Allowance/Charge":
                begin
                    TargetLineNo := AssignedLineNo;
                    exit(Structure::"Line Allowance/Charge");
                end;
        end;

        exit(Structure::"Line with Unit Code");
    end;

    local procedure HasLineToKeepInInvoice(DocumentNo: Code[20]): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // The answer depends on the document, not on the item charge, but the classification runs once per
        // charge line. Caching it per document keeps a document with many item charges to a single query.
        if (CachedInvoiceLineToKeepNo = DocumentNo) and (DocumentNo <> '') then
            exit(CachedInvoiceLineToKeep);

        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetFilter(Type, '<>%1&<>%2', SalesInvoiceLine.Type::" ", SalesInvoiceLine.Type::"Charge (Item)");
        CachedInvoiceLineToKeep := not SalesInvoiceLine.IsEmpty();
        CachedInvoiceLineToKeepNo := DocumentNo;
        exit(CachedInvoiceLineToKeep);
    end;

    local procedure HasLineToKeepInCrMemo(DocumentNo: Code[20]): Boolean
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // Cached per document for the same reason as the invoice variant. Invoices and credit memos keep
        // separate caches, so a document number that exists in both tables cannot return the wrong answer.
        if (CachedCrMemoLineToKeepNo = DocumentNo) and (DocumentNo <> '') then
            exit(CachedCrMemoLineToKeep);

        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetFilter(Type, '<>%1&<>%2', SalesCrMemoLine.Type::" ", SalesCrMemoLine.Type::"Charge (Item)");
        CachedCrMemoLineToKeep := not SalesCrMemoLine.IsEmpty();
        CachedCrMemoLineToKeepNo := DocumentNo;
        exit(CachedCrMemoLineToKeep);
    end;

    local procedure FindSingleAssignedLineNo(DocumentNo: Code[20]; ChargeLineNo: Integer; ItemChargeNo: Code[20]): Integer
    var
        AssignedLineNos: List of [Integer];
    begin
        CollectAssignedLineNos(DocumentNo, ChargeLineNo, ItemChargeNo, AssignedLineNos);
        if AssignedLineNos.Count() <> 1 then
            exit(0);
        exit(AssignedLineNos.Get(1));
    end;

    local procedure CollectAssignedLineNos(DocumentNo: Code[20]; ChargeLineNo: Integer; ItemChargeNo: Code[20]; var AssignedLineNos: List of [Integer])
    var
        ChargeValueEntry: Record "Value Entry";
        DocumentLineNos: Dictionary of [Integer, Integer];
        AssignedLineNo: Integer;
    begin
        Clear(AssignedLineNos);

        ChargeValueEntry.SetLoadFields("Item Ledger Entry No.");
        ChargeValueEntry.SetRange("Document No.", DocumentNo);
        ChargeValueEntry.SetRange("Document Line No.", ChargeLineNo);
        ChargeValueEntry.SetRange("Item Charge No.", ItemChargeNo);
        if not ChargeValueEntry.FindSet() then
            exit;

        CollectDocumentLineNosByItemLedgerEntry(DocumentNo, DocumentLineNos);
        repeat
            if DocumentLineNos.Get(ChargeValueEntry."Item Ledger Entry No.", AssignedLineNo) then
                if (AssignedLineNo <> 0) and not AssignedLineNos.Contains(AssignedLineNo) then
                    AssignedLineNos.Add(AssignedLineNo);
        until ChargeValueEntry.Next() = 0;
    end;

    local procedure CollectDocumentLineNosByItemLedgerEntry(DocumentNo: Code[20]; var DocumentLineNos: Dictionary of [Integer, Integer])
    var
        SaleValueEntry: Record "Value Entry";
    begin
        // Every item charge of a document resolves against the same map, so it is built once per document
        // instead of once per charge line. The document number is the cache key, so a new document rebuilds it.
        if (CachedLineNoDocumentNo = DocumentNo) and (DocumentNo <> '') then begin
            DocumentLineNos := CachedDocumentLineNos;
            exit;
        end;

        SaleValueEntry.SetLoadFields("Item Ledger Entry No.", "Document Line No.");
        SaleValueEntry.SetRange("Document No.", DocumentNo);
        SaleValueEntry.SetRange("Item Charge No.", '');
        if SaleValueEntry.FindSet() then
            repeat
                if not DocumentLineNos.ContainsKey(SaleValueEntry."Item Ledger Entry No.") then
                    DocumentLineNos.Add(SaleValueEntry."Item Ledger Entry No.", SaleValueEntry."Document Line No.");
            until SaleValueEntry.Next() = 0;

        // A document without any matching value entry is cached as well, so that it is not looked up again.
        CachedLineNoDocumentNo := DocumentNo;
        CachedDocumentLineNos := DocumentLineNos;
    end;

    local procedure HasSameVAT(ChargeVATCalculationType: Enum "Tax Calculation Type"; ChargeVATPercent: Decimal; AssignedVATCalculationType: Enum "Tax Calculation Type"; AssignedVATPercent: Decimal): Boolean
    begin
        if ChargeVATCalculationType <> AssignedVATCalculationType then
            exit(false);

        exit(ChargeVATPercent = AssignedVATPercent);
    end;

    /// <summary>
    /// Integration event that allows subscribers to override the structure an item charge of a posted sales invoice is exported as.
    /// </summary>
    /// <param name="EDocumentService">The service that exports the document.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice that is exported.</param>
    /// <param name="SalesInvoiceLine">The item charge line that was classified.</param>
    /// <param name="Structure">The resolved structure. Change it to export the item charge differently.</param>
    /// <param name="TargetSalesInvoiceLine">The invoice line the charge belongs to. Set it when changing the structure to a line level allowance/charge.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemChargeStructure(EDocumentService: Record "E-Document Service"; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceLine: Record "Sales Invoice Line"; var Structure: Enum "Item Charge E-Doc. Structure"; var TargetSalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    /// <summary>
    /// Integration event that allows subscribers to override the structure an item charge of a posted sales credit memo is exported as.
    /// </summary>
    /// <param name="EDocumentService">The service that exports the document.</param>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo that is exported.</param>
    /// <param name="SalesCrMemoLine">The item charge line that was classified.</param>
    /// <param name="Structure">The resolved structure. Change it to export the item charge differently.</param>
    /// <param name="TargetSalesCrMemoLine">The credit memo line the charge belongs to. Set it when changing the structure to a line level allowance/charge.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesCrMemoItemChargeStructure(EDocumentService: Record "E-Document Service"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line"; var Structure: Enum "Item Charge E-Doc. Structure"; var TargetSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
    end;
}
