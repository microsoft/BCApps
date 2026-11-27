// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.CRM.Team;
using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Reflection;

// Translation keyword reference (Leitweg-ID specification terminology):
//   E-Invoice Routing No. = Leitweg-ID
//   coarse routing         = Grobadressierung
//   fine routing           = Feinadressierung
//   check digit            = Prüfziffer
//   state code             = Bundesland-Code
//   federal code           = Bund-Code

codeunit 11038 "E-Document DE Helper"
{
    Access = Public;

    /// <summary>
    /// Checks whether the given routing number (Leitweg-ID) is structurally valid.
    /// </summary>
    /// <param name="RoutingNo">The routing number to validate.</param>
    /// <returns>True if the routing number passes all structural validation rules; otherwise, false.</returns>
    procedure IsValidRoutingNo(RoutingNo: Text[50]): Boolean
    begin
        exit(TryValidateRoutingNo(RoutingNo));
    end;

    /// <summary>
    /// Determines whether the source document has a routing number (Leitweg-ID) available.
    /// First checks the document's Buyer Reference field for a valid routing number,
    /// then falls back to the bill-to customer's E-Invoice Routing No.
    /// </summary>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header (Sales Header, Sales Invoice Header, Sales Cr.Memo Header, Service Header, Service Invoice Header, or Service Cr.Memo Header).</param>
    /// <returns>True if a routing number is found on the document or on the bill-to customer; otherwise, false.</returns>
    procedure HasRoutingNo(SourceDocumentHeader: RecordRef): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        BuyerReferenceFieldRef: FieldRef;
        CustomerNoFieldRef: FieldRef;
        BuyerReferenceValue: Text;
    begin
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit(false);

        BuyerReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Buyer Reference"));
        BuyerReferenceValue := BuyerReferenceFieldRef.Value();
        if (BuyerReferenceValue <> '') and (StrLen(BuyerReferenceValue) <= 50) then
            if IsValidRoutingNo(CopyStr(BuyerReferenceValue, 1, 50)) then
                exit(true);

        CustomerNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        Customer.SetLoadFields("E-Invoice Routing No.");
        if Customer.Get(Format(CustomerNoFieldRef.Value)) then
            if Customer."E-Invoice Routing No." <> '' then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// Validates the structure of a routing number (Leitweg-ID) and raises an error if it is invalid.
    /// Validates the overall length, segment count, coarse routing (Grobadressierung), optional fine routing (Feinadressierung), and check digit (Prüfziffer) using Mod 97-10.
    /// </summary>
    /// <param name="RoutingNo">The routing number to validate. An empty value is accepted without error.</param>
    procedure ValidateRoutingNo(RoutingNo: Text[50])
    var
        Parts: List of [Text];
        CoarseRouting: Text;
        FineRouting: Text;
        CheckDigitText: Text;
    begin
        if RoutingNo = '' then
            exit;

        if (StrLen(RoutingNo) < 5) or (StrLen(RoutingNo) > 46) then
            Error(OverallLengthErr, StrLen(RoutingNo));

        Parts := RoutingNo.Split('-');
        if not (Parts.Count() in [2, 3]) then
            Error(SegmentCountErr);

        CoarseRouting := Parts.Get(1);
        if Parts.Count() = 3 then
            FineRouting := Parts.Get(2);
        CheckDigitText := Parts.Get(Parts.Count());

        ValidateCoarseRouting(CoarseRouting);
        if FineRouting <> '' then
            ValidateFineRouting(FineRouting);
        ValidateCheckDigitFormat(CheckDigitText);
        ValidateCheckDigitMod97(CoarseRouting, FineRouting, CheckDigitText);
    end;

    local procedure ValidateCoarseRouting(CoarseRouting: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        StateCode: Integer;
        StateCodeText: Text;
        i: Integer;
    begin
        if CoarseRouting = '' then
            Error(CoarseDigitsErr, CoarseRouting);

        for i := 1 to StrLen(CoarseRouting) do
            if not TypeHelper.IsDigit(CoarseRouting[i]) then
                Error(CoarseDigitsErr, CoarseRouting);

        if not (StrLen(CoarseRouting) in [2, 3, 5, 8, 9, 12]) then
            Error(CoarseLengthErr, StrLen(CoarseRouting));

        StateCodeText := CopyStr(CoarseRouting, 1, 2);
        Evaluate(StateCode, StateCodeText);
        if not ((StateCode in [1 .. 16]) or (StateCode = 99)) then
            Error(StateCodeErr, StateCodeText);
    end;

    local procedure ValidateFineRouting(FineRouting: Text)
    begin
        if (StrLen(FineRouting) < 1) or (StrLen(FineRouting) > 30) then
            Error(FineRoutingLengthErr, FineRouting);

        if not IsAlphanumOnly(FineRouting) then
            Error(FineRoutingCharsErr, FineRouting);
    end;

    local procedure ValidateCheckDigitFormat(CheckDigitText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        i: Integer;
    begin
        if StrLen(CheckDigitText) <> 2 then
            Error(CheckDigitFormatErr, CheckDigitText);

        for i := 1 to StrLen(CheckDigitText) do
            if not TypeHelper.IsDigit(CheckDigitText[i]) then
                Error(CheckDigitFormatErr, CheckDigitText);
    end;

    local procedure ValidateCheckDigitMod97(CoarseRouting: Text; FineRouting: Text; CheckDigitText: Text)
    var
        FullNumeric: Text;
    begin
        FullNumeric := ConvertToNumericString(CoarseRouting + FineRouting + CheckDigitText);
        if ComputeMod97(FullNumeric) <> 1 then
            Error(CheckDigitVerifyErr);
    end;

    local procedure ConvertToNumericString(Input: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        UpperInput: Text;
        Result: Text;
        Ch: Char;
        i: Integer;
    begin
        UpperInput := UpperCase(Input);
        for i := 1 to StrLen(UpperInput) do begin
            Ch := UpperInput[i];
            if TypeHelper.IsLatinLetter(Ch) then
                Result += Format(Ch - 55) // A=65 → 10, B=66 → 11, ..., Z=90 → 35
            else
                Result += Format(Ch - 48); // '0'=48 → 0, '1'=49 → 1, etc.
        end;
        exit(Result);
    end;

    local procedure ComputeMod97(NumericString: Text): Integer
    var
        Remainder: Integer;
        DigitValue: Integer;
        i: Integer;
    begin
        Remainder := 0;
        for i := 1 to StrLen(NumericString) do begin
            Evaluate(DigitValue, CopyStr(NumericString, i, 1));
            Remainder := (Remainder * 10 + DigitValue) mod 97;
        end;
        exit(Remainder);
    end;

    local procedure IsAlphanumOnly(Input: Text): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        Ch: Char;
        i: Integer;
    begin
        if Input = '' then
            exit(false);
        for i := 1 to StrLen(Input) do begin
            Ch := Input[i];
            if not (TypeHelper.IsDigit(Ch) or TypeHelper.IsLatinLetter(Ch)) then
                exit(false);
        end;
        exit(true);
    end;

    local procedure IsSupportedDocumentType(SourceDocumentHeader: RecordRef): Boolean
    begin
        exit(SourceDocumentHeader.Number() in
            [Database::"Sales Header",
            Database::"Sales Invoice Header",
            Database::"Sales Cr.Memo Header",
            Database::"Service Header",
            Database::"Service Invoice Header",
            Database::"Service Cr.Memo Header"]);
    end;

    /// <summary>
    /// Resolves the Buyer Reference (BT-10) value using a priority chain.
    /// Priority 1: Document Buyer Reference field — accepted only if it is a structurally valid Leitweg-ID.
    /// Priority 2: Bill-to Customer E-Invoice Routing No.
    /// Priority 3a: Document Buyer Reference if explicitly set but not a valid Leitweg-ID (preserves user intent and migration data).
    /// Priority 3b: Your Reference.
    /// </summary>
    /// <param name="DocumentBuyerReference">The Buyer Reference value stored on the document header.</param>
    /// <param name="BillToCustomerNo">The Bill-to Customer No. used to look up the customer's E-Invoice Routing No.</param>
    /// <param name="YourReference">The Your Reference value stored on the document header.</param>
    /// <returns>The resolved Buyer Reference value, or empty text if none of the sources yield a value.</returns>
    internal procedure GetBuyerReferenceValue(DocumentBuyerReference: Text[100]; BillToCustomerNo: Code[20]; YourReference: Text[35]): Text
    var
        Customer: Record Customer;
    begin
        // Priority 1: Document Buyer Reference — only if it is a structurally valid Leitweg-ID
        if (DocumentBuyerReference <> '') then
            if (StrLen(DocumentBuyerReference) <= 50) then
                if IsValidRoutingNo(CopyStr(DocumentBuyerReference, 1, 50)) then
                    exit(DocumentBuyerReference);

        // Priority 2: Bill-to Customer E-Invoice Routing No.
        Customer.SetLoadFields("E-Invoice Routing No.");
        if Customer.Get(BillToCustomerNo) then
            if Customer."E-Invoice Routing No." <> '' then
                exit(Customer."E-Invoice Routing No.");

        // Priority 3a: Document Buyer Reference if explicitly set but not a valid Leitweg-ID
        //   (preserves explicit user intent and old migration data)
        if DocumentBuyerReference <> '' then
            exit(DocumentBuyerReference);

        // Priority 3b: Your Reference
        exit(YourReference);
    end;

    /// <summary>
    /// Checks whether a Buyer Reference (BT-10) can be resolved for the given document and raises an error if not.
    /// Only runs when the E-Document Service has "Buyer Reference Mandatory" enabled and the document is a supported type.
    /// Uses GetBuyerReferenceValue to resolve the reference via the same priority chain used during export.
    /// </summary>
    /// <param name="EDocumentService">The E-Document Service record. Must have "Buyer Reference Mandatory" set to true for the check to run.</param>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    internal procedure CheckBuyerReferenceMandatory(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BuyerReferenceFieldRef: FieldRef;
        CustomerNoFieldRef: FieldRef;
        YourReferenceFieldRef: FieldRef;
        DocumentNoFieldRef: FieldRef;
        BuyerReference: Text[100];
        BillToCustomerNo: Code[20];
        YourReference: Text[35];
        BuyerReferenceValue: Text;
        MissingBuyerReferenceErr: Label 'Buyer Reference is mandatory for document %1.', Comment = '%1 = Document No.';
    begin
        if not EDocumentService."Buyer Reference Mandatory" then
            exit;
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit;
        BuyerReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Buyer Reference"));
        CustomerNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Bill-to Customer No."));
        YourReferenceFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("Your Reference"));
        BuyerReference := BuyerReferenceFieldRef.Value();
        BillToCustomerNo := CustomerNoFieldRef.Value();
        YourReference := YourReferenceFieldRef.Value();
        BuyerReferenceValue := GetBuyerReferenceValue(BuyerReference, BillToCustomerNo, YourReference);
        if BuyerReferenceValue = '' then begin
            DocumentNoFieldRef := SourceDocumentHeader.Field(SalesInvoiceHeader.FieldNo("No."));
            Error(MissingBuyerReferenceErr, DocumentNoFieldRef.Value());
        end;
    end;

    /// <summary>
    /// Checks that the seller contact (BG-6) can be fully supplied from the source that the export uses,
    /// so that BR-DE-2 (group present), BR-DE-5 (BT-41 name), BR-DE-6 (BT-42 telephone) and
    /// BR-DE-7 (BT-43 e-mail) are satisfied.
    /// When a salesperson is assigned to the document, the salesperson supplies all three terms and must
    /// therefore have Name, Phone No. and E-Mail. Otherwise they come from Company Information.
    /// The Company Information E-Mail is not checked here: it is the same field that supplies the seller
    /// electronic address (BT-34), which CheckCompanyInfoMandatory already requires in the format codeunits.
    /// </summary>
    /// <param name="SourceDocumentHeader">A RecordRef pointing to a supported document header.</param>
    internal procedure CheckSellerContactMandatory(SourceDocumentHeader: RecordRef)
    var
        CompanyInformation: Record "Company Information";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonCode: Code[20];
    begin
        if not IsSupportedDocumentType(SourceDocumentHeader) then
            exit;

        SalespersonCode := GetSalespersonCode(SourceDocumentHeader);
        if SalespersonCode <> '' then begin
            SalespersonPurchaser.SetLoadFields(Name, "Phone No.", "E-Mail");
            if SalespersonPurchaser.Get(SalespersonCode) then begin
                if SalespersonPurchaser.Name = '' then
                    SalespersonPurchaser.FieldError(Name, SellerContactReasonErr);
                if SalespersonPurchaser."Phone No." = '' then
                    SalespersonPurchaser.FieldError("Phone No.", SellerContactReasonErr);
                if SalespersonPurchaser."E-Mail" = '' then
                    SalespersonPurchaser.FieldError("E-Mail", SellerContactReasonErr);
                exit;
            end;
        end;

        CompanyInformation.SetLoadFields("Contact Person", "Phone No.");
        CompanyInformation.Get();
        if CompanyInformation."Contact Person" = '' then
            CompanyInformation.FieldError("Contact Person", SellerContactReasonErr);
        if CompanyInformation."Phone No." = '' then
            CompanyInformation.FieldError("Phone No.", SellerContactReasonErr);
    end;

    local procedure GetSalespersonCode(SourceDocumentHeader: RecordRef): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SalespersonCodeFieldRef: FieldRef;
        SalespersonFieldNo: Integer;
    begin
        SalespersonFieldNo := SalesInvoiceHeader.FieldNo("Salesperson Code");
        if SourceDocumentHeader.Number() in
            [Database::"Service Header", Database::"Service Invoice Header", Database::"Service Cr.Memo Header"]
        then
            SalespersonFieldNo := ServiceInvoiceHeader.FieldNo("Salesperson Code");

        SalespersonCodeFieldRef := SourceDocumentHeader.Field(SalespersonFieldNo);
        exit(SalespersonCodeFieldRef.Value());
    end;

    /// <summary>
    /// Tells whether a signed amount is reported as a charge or as an allowance.
    /// </summary>
    /// <param name="SignedAmount">The signed amount of the allowance/charge.</param>
    /// <returns>True for a charge, false for an allowance.</returns>
    internal procedure IsCharge(SignedAmount: Decimal): Boolean
    begin
        exit(SignedAmount >= 0);
    end;

    /// <summary>
    /// Gets the amount to report for a signed allowance/charge amount. The e-document formats report allowances with a
    /// positive amount and distinguish them from charges through the charge indicator.
    /// </summary>
    /// <param name="SignedAmount">The signed amount of the allowance/charge.</param>
    /// <returns>The absolute amount.</returns>
    internal procedure GetReportedAmount(SignedAmount: Decimal): Decimal
    begin
        exit(Abs(SignedAmount));
    end;

    /// <summary>
    /// Collects, per invoice line, the first and last posting date of the posted sales shipments the line was invoiced from.
    /// A line is traced through its shipment line (Get Shipment Lines), the value entries of the item it delivered or an item
    /// charge was assigned to, or the shipment lines of the order line it was invoiced from, up to the invoice's posting date.
    /// A line with a quantity that cannot be traced gets 0D; lines without quantity get no entry.
    /// Temporary lines are not posted invoice lines, so they get no entries.
    /// </summary>
    /// <param name="SalesInvoiceLine">The exported lines of the posted sales invoice.</param>
    /// <param name="DeliveryStartDates">Returns the earliest shipment posting date per line number.</param>
    /// <param name="DeliveryEndDates">Returns the latest shipment posting date per line number.</param>
    internal procedure CollectActualDeliveryDates(var SalesInvoiceLine: Record "Sales Invoice Line"; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date])
    var
        DocumentSalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
        ShipmentStartDates: Dictionary of [Integer, Date];
        ShipmentEndDates: Dictionary of [Integer, Date];
        LineNosToTrace: List of [Integer];
    begin
        Clear(DeliveryStartDates);
        Clear(DeliveryEndDates);
        if SalesInvoiceLine.IsTemporary() then
            exit;
        DocumentSalesInvoiceLine.Copy(SalesInvoiceLine);
        DocumentSalesInvoiceLine.SetLoadFields(Quantity, "Shipment No.", "Shipment Line No.", "Order No.", "Order Line No.", "Posting Date");
        if not DocumentSalesInvoiceLine.FindSet() then
            exit;

        SalesShipmentLine.SetLoadFields("Posting Date");
        repeat
            if DocumentSalesInvoiceLine.Quantity <> 0 then
                if (DocumentSalesInvoiceLine."Shipment No." <> '') and SalesShipmentLine.Get(DocumentSalesInvoiceLine."Shipment No.", DocumentSalesInvoiceLine."Shipment Line No.") then
                    AddActualDeliveryDate(DocumentSalesInvoiceLine."Line No.", SalesShipmentLine."Posting Date", DeliveryStartDates, DeliveryEndDates)
                else
                    LineNosToTrace.Add(DocumentSalesInvoiceLine."Line No.");
        until DocumentSalesInvoiceLine.Next() = 0;
        if LineNosToTrace.Count() = 0 then
            exit;

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, DocumentSalesInvoiceLine."Document No.");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Invoice");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Shipment");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if SalesShipmentLine.Get(ValueItemLedgerEntries.Item_Ledg_Document_No, ValueItemLedgerEntries.Item_Ledg_Document_Line_No) then
                AddActualDeliveryDate(ValueItemLedgerEntries.Value_Entry_Doc_Line_No, SalesShipmentLine."Posting Date", ShipmentStartDates, ShipmentEndDates);
        ValueItemLedgerEntries.Close();

        DocumentSalesInvoiceLine.FindSet();
        repeat
            if LineNosToTrace.Contains(DocumentSalesInvoiceLine."Line No.") then
                if ShipmentStartDates.ContainsKey(DocumentSalesInvoiceLine."Line No.") then
                    AddActualDeliveryPeriod(DocumentSalesInvoiceLine."Line No.", ShipmentStartDates, ShipmentEndDates, DeliveryStartDates, DeliveryEndDates)
                else
                    if not AddOrderShipmentDates(DocumentSalesInvoiceLine, DeliveryStartDates, DeliveryEndDates) then
                        AddUntracedDeliveryLine(DocumentSalesInvoiceLine."Line No.", DeliveryStartDates, DeliveryEndDates);
        until DocumentSalesInvoiceLine.Next() = 0;
    end;

    /// <summary>
    /// Collects, per credit memo line, the first and last posting date of the posted return receipts the line was invoiced from.
    /// A line is traced through its return receipt line (Get Return Receipt Lines), the value entries of the item it returned or an
    /// item charge was assigned to, or the return receipt lines of the return order line it was invoiced from, up to the credit
    /// memo's posting date. A line with a quantity that cannot be traced gets 0D; lines without quantity get no entry.
    /// Temporary lines are not posted credit memo lines, so they get no entries.
    /// </summary>
    /// <param name="SalesCrMemoLine">The exported lines of the posted sales credit memo.</param>
    /// <param name="DeliveryStartDates">Returns the earliest return receipt posting date per line number.</param>
    /// <param name="DeliveryEndDates">Returns the latest return receipt posting date per line number.</param>
    internal procedure CollectActualDeliveryDates(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date])
    var
        DocumentSalesCrMemoLine: Record "Sales Cr.Memo Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
        ReceiptStartDates: Dictionary of [Integer, Date];
        ReceiptEndDates: Dictionary of [Integer, Date];
        LineNosToTrace: List of [Integer];
    begin
        Clear(DeliveryStartDates);
        Clear(DeliveryEndDates);
        if SalesCrMemoLine.IsTemporary() then
            exit;
        DocumentSalesCrMemoLine.Copy(SalesCrMemoLine);
        DocumentSalesCrMemoLine.SetLoadFields(Quantity, "Return Receipt No.", "Return Receipt Line No.", "Order No.", "Order Line No.", "Posting Date");
        if not DocumentSalesCrMemoLine.FindSet() then
            exit;

        ReturnReceiptLine.SetLoadFields("Posting Date");
        repeat
            if DocumentSalesCrMemoLine.Quantity <> 0 then
                if (DocumentSalesCrMemoLine."Return Receipt No." <> '') and ReturnReceiptLine.Get(DocumentSalesCrMemoLine."Return Receipt No.", DocumentSalesCrMemoLine."Return Receipt Line No.") then
                    AddActualDeliveryDate(DocumentSalesCrMemoLine."Line No.", ReturnReceiptLine."Posting Date", DeliveryStartDates, DeliveryEndDates)
                else
                    LineNosToTrace.Add(DocumentSalesCrMemoLine."Line No.");
        until DocumentSalesCrMemoLine.Next() = 0;
        if LineNosToTrace.Count() = 0 then
            exit;

        // No filter on the invoiced quantity: the value entries of an item charge carry none.
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, DocumentSalesCrMemoLine."Document No.");
        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Credit Memo");
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Return Receipt");
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            if ReturnReceiptLine.Get(ValueItemLedgerEntries.Item_Ledg_Document_No, ValueItemLedgerEntries.Item_Ledg_Document_Line_No) then
                AddActualDeliveryDate(ValueItemLedgerEntries.Value_Entry_Doc_Line_No, ReturnReceiptLine."Posting Date", ReceiptStartDates, ReceiptEndDates);
        ValueItemLedgerEntries.Close();

        DocumentSalesCrMemoLine.FindSet();
        repeat
            if LineNosToTrace.Contains(DocumentSalesCrMemoLine."Line No.") then
                if ReceiptStartDates.ContainsKey(DocumentSalesCrMemoLine."Line No.") then
                    AddActualDeliveryPeriod(DocumentSalesCrMemoLine."Line No.", ReceiptStartDates, ReceiptEndDates, DeliveryStartDates, DeliveryEndDates)
                else
                    if not AddReturnOrderReceiptDates(DocumentSalesCrMemoLine, DeliveryStartDates, DeliveryEndDates) then
                        AddUntracedDeliveryLine(DocumentSalesCrMemoLine."Line No.", DeliveryStartDates, DeliveryEndDates);
        until DocumentSalesCrMemoLine.Next() = 0;
    end;

    /// <summary>
    /// Gets the actual delivery date (BT-72) of the document. When no line has a posted delivery, the default date is returned.
    /// When the posted deliveries do not share one date, or some delivered lines have no posted delivery, no date is returned,
    /// because one date cannot represent the whole document.
    /// </summary>
    /// <param name="DeliveryStartDates">The earliest posted delivery date per line number; 0D for a line without a posted delivery.</param>
    /// <param name="DeliveryEndDates">The latest posted delivery date per line number; 0D for a line without a posted delivery.</param>
    /// <param name="DefaultDeliveryDate">The date to return when no line has a posted delivery.</param>
    /// <returns>The common delivery date, the default date, or 0D.</returns>
    internal procedure GetDocumentActualDeliveryDate(DeliveryStartDates: Dictionary of [Integer, Date]; DeliveryEndDates: Dictionary of [Integer, Date]; DefaultDeliveryDate: Date): Date
    var
        DocumentDeliveryDate: Date;
        UntracedLineExists: Boolean;
        LineNo: Integer;
    begin
        DocumentDeliveryDate := 0D;
        foreach LineNo in DeliveryStartDates.Keys() do
            if DeliveryStartDates.Get(LineNo) = 0D then
                UntracedLineExists := true
            else begin
                if DeliveryStartDates.Get(LineNo) <> DeliveryEndDates.Get(LineNo) then
                    exit(0D);
                if DocumentDeliveryDate = 0D then
                    DocumentDeliveryDate := DeliveryStartDates.Get(LineNo);
                if DeliveryStartDates.Get(LineNo) <> DocumentDeliveryDate then
                    exit(0D);
            end;

        if DocumentDeliveryDate = 0D then
            exit(DefaultDeliveryDate);
        if UntracedLineExists then
            exit(0D);
        exit(DocumentDeliveryDate);
    end;

    /// <summary>
    /// Gets the posted delivery period of a document line.
    /// </summary>
    /// <param name="LineNo">The line number of the document line.</param>
    /// <param name="DeliveryStartDates">The earliest posted delivery date per line number.</param>
    /// <param name="DeliveryEndDates">The latest posted delivery date per line number.</param>
    /// <param name="StartDate">Returns the first posted delivery date of the line.</param>
    /// <param name="EndDate">Returns the last posted delivery date of the line.</param>
    /// <returns>True when the line has a posted delivery; otherwise, false.</returns>
    internal procedure GetActualDeliveryPeriod(LineNo: Integer; DeliveryStartDates: Dictionary of [Integer, Date]; DeliveryEndDates: Dictionary of [Integer, Date]; var StartDate: Date; var EndDate: Date): Boolean
    begin
        if not DeliveryStartDates.Get(LineNo, StartDate) then
            exit(false);
        if StartDate = 0D then
            exit(false);
        EndDate := DeliveryEndDates.Get(LineNo);
        exit(true);
    end;

    local procedure AddOrderShipmentDates(SalesInvoiceLine: Record "Sales Invoice Line"; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date]) ShipmentFound: Boolean
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        if SalesInvoiceLine."Order No." = '' then
            exit(false);
        SalesShipmentLine.SetCurrentKey("Order No.", "Order Line No.", "Posting Date");
        SalesShipmentLine.SetRange("Order No.", SalesInvoiceLine."Order No.");
        SalesShipmentLine.SetRange("Order Line No.", SalesInvoiceLine."Order Line No.");
        SalesShipmentLine.SetRange("Posting Date", 0D, SalesInvoiceLine."Posting Date");
        SalesShipmentLine.SetLoadFields(Quantity, "Posting Date");
        if not SalesShipmentLine.FindSet() then
            exit(false);
        repeat
            if SalesShipmentLine.Quantity <> 0 then begin
                AddActualDeliveryDate(SalesInvoiceLine."Line No.", SalesShipmentLine."Posting Date", DeliveryStartDates, DeliveryEndDates);
                ShipmentFound := true;
            end;
        until SalesShipmentLine.Next() = 0;
    end;

    local procedure AddReturnOrderReceiptDates(SalesCrMemoLine: Record "Sales Cr.Memo Line"; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date]) ReceiptFound: Boolean
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        if SalesCrMemoLine."Order No." = '' then
            exit(false);
        ReturnReceiptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
        ReturnReceiptLine.SetRange("Return Order No.", SalesCrMemoLine."Order No.");
        ReturnReceiptLine.SetRange("Return Order Line No.", SalesCrMemoLine."Order Line No.");
        ReturnReceiptLine.SetRange("Posting Date", 0D, SalesCrMemoLine."Posting Date");
        ReturnReceiptLine.SetLoadFields(Quantity, "Posting Date");
        if not ReturnReceiptLine.FindSet() then
            exit(false);
        repeat
            if ReturnReceiptLine.Quantity <> 0 then begin
                AddActualDeliveryDate(SalesCrMemoLine."Line No.", ReturnReceiptLine."Posting Date", DeliveryStartDates, DeliveryEndDates);
                ReceiptFound := true;
            end;
        until ReturnReceiptLine.Next() = 0;
    end;

    local procedure AddActualDeliveryPeriod(LineNo: Integer; SourceStartDates: Dictionary of [Integer, Date]; SourceEndDates: Dictionary of [Integer, Date]; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date])
    begin
        AddActualDeliveryDate(LineNo, SourceStartDates.Get(LineNo), DeliveryStartDates, DeliveryEndDates);
        AddActualDeliveryDate(LineNo, SourceEndDates.Get(LineNo), DeliveryStartDates, DeliveryEndDates);
    end;

    local procedure AddUntracedDeliveryLine(LineNo: Integer; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date])
    begin
        DeliveryStartDates.Add(LineNo, 0D);
        DeliveryEndDates.Add(LineNo, 0D);
    end;

    local procedure AddActualDeliveryDate(LineNo: Integer; DeliveryDate: Date; var DeliveryStartDates: Dictionary of [Integer, Date]; var DeliveryEndDates: Dictionary of [Integer, Date])
    begin
        if DeliveryDate = 0D then
            exit;
        if not DeliveryStartDates.ContainsKey(LineNo) then begin
            DeliveryStartDates.Add(LineNo, DeliveryDate);
            DeliveryEndDates.Add(LineNo, DeliveryDate);
            exit;
        end;
        if DeliveryDate < DeliveryStartDates.Get(LineNo) then
            DeliveryStartDates.Set(LineNo, DeliveryDate);
        if DeliveryDate > DeliveryEndDates.Get(LineNo) then
            DeliveryEndDates.Set(LineNo, DeliveryDate);
    end;

    [TryFunction]
    local procedure TryValidateRoutingNo(RoutingNo: Text[50])
    begin
        ValidateRoutingNo(RoutingNo);
    end;

    var
        OverallLengthErr: Label 'The E-Invoice Routing No. must be between 5 and 46 characters long. Current length: %1.', Comment = '%1 = actual length';
        SegmentCountErr: Label 'The E-Invoice Routing No. must consist of 2 or 3 segments separated by hyphens (-).';
        CoarseDigitsErr: Label 'The coarse routing segment must contain only digits (0-9). Found: "%1".', Comment = '%1 = coarse routing value';
        CoarseLengthErr: Label 'The coarse routing segment must be 2, 3, 5, 8, 9, or 12 digits long. Current length: %1.', Comment = '%1 = actual length';
        StateCodeErr: Label 'The coarse routing segment must start with a valid German state code (01-16) or federal code (99). Found: "%1".', Comment = '%1 = two-digit state code';
        FineRoutingLengthErr: Label 'The fine routing segment must be between 1 and 30 characters long. Found: "%1".', Comment = '%1 = fine routing value';
        FineRoutingCharsErr: Label 'The fine routing segment must contain only letters (A-Z) and digits (0-9). Found: "%1".', Comment = '%1 = fine routing value';
        CheckDigitFormatErr: Label 'The check digit must be exactly 2 digits. Found: "%1".', Comment = '%1 = check digit value';
        CheckDigitVerifyErr: Label 'The check digit verification failed (Mod 97-10). The E-Invoice Routing No. may contain a typo.';
        SellerContactReasonErr: Label 'must be filled in. It is required for the seller contact (BG-6) of the electronic document';
}