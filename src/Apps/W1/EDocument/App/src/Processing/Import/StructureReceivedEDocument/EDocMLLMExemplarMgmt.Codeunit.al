// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;
using System.Utilities;

codeunit 6233 "E-Doc. MLLM Exemplar Mgmt"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions =
        tabledata "E-Doc. MLLM Vendor Exemplar" = rimd,
        tabledata "E-Document Purchase Header" = r,
        tabledata "E-Document Purchase Line" = r,
        tabledata "E-Doc. Data Storage" = r;

    procedure TryGetExemplar(VendorName: Text[250]; var ExemplarFound: Boolean; var PdfBase64: Text; var JsonText: Text)
    var
        Exemplar: Record "E-Doc. MLLM Vendor Exemplar";
        EDocDataStorage: Record "E-Doc. Data Storage";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        ExemplarFound := false;
        if VendorName = '' then
            exit;

        Exemplar.SetRange("Vendor Company Name", UpperCase(VendorName));
        if not Exemplar.FindLast() then
            exit;

        // Get PDF from data storage
        if not EDocDataStorage.Get(Exemplar."Unstructured Data Entry No.") then
            exit;

        TempBlob := EDocDataStorage.GetTempBlob();
        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        PdfBase64 := Base64Convert.ToBase64(InStream);

        // Get corrected JSON from blob
        Exemplar.CalcFields("Corrected UBL JSON");
        if not Exemplar."Corrected UBL JSON".HasValue() then
            exit;

        Clear(TempBlob);
        TempBlob.FromRecord(Exemplar, Exemplar.FieldNo("Corrected UBL JSON"));
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(JsonText);

        if (PdfBase64 <> '') and (JsonText <> '') then
            ExemplarFound := true;
    end;

    procedure ExtractVendorNameFromJson(JsonResponseText: Text): Text[250]
    var
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        RootObj: JsonObject;
        SupplierObj: JsonObject;
        PartyObj: JsonObject;
        PartyNameObj: JsonObject;
        VendorName: Text;
    begin
        if not RootObj.ReadFrom(JsonResponseText) then
            exit('');

        if not EDocMLLMSchemaHelper.GetNestedObject(RootObj, 'accounting_supplier_party', SupplierObj) then
            exit('');
        if not EDocMLLMSchemaHelper.GetNestedObject(SupplierObj, 'party', PartyObj) then
            exit('');
        if not EDocMLLMSchemaHelper.GetNestedObject(PartyObj, 'party_name', PartyNameObj) then
            exit('');

        EDocMLLMSchemaHelper.GetString(PartyNameObj, 'name', 250, VendorName);
        exit(CopyStr(VendorName, 1, 250));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import E-Document Process", OnDraftFinished, '', false, false)]
    local procedure HandleOnDraftFinished(EDocument: Record "E-Document")
    var
        EDocPurchaseHeader: Record "E-Document Purchase Header";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        VendorName: Text[250];
        VendorNo: Code[20];
        JsonText: Text;
    begin
        // Only capture exemplars for MLLM-processed documents
        if EDocument."Structure Data Impl." <> "Structure Received E-Doc."::MLLM then
            exit;

        if not EDocPurchaseHeader.Get(EDocument."Entry No") then
            exit;

        VendorName := EDocPurchaseHeader."Vendor Company Name";
        if VendorName = '' then
            exit;

        VendorNo := EDocPurchaseHeader."[BC] Vendor No.";

        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if not EDocPurchaseLine.FindSet() then
            exit;

        JsonText := BuildFullUblJson(EDocPurchaseHeader, EDocPurchaseLine);
        if JsonText = '' then
            exit;

        UpsertExemplar(VendorName, VendorNo, JsonText, EDocument."Entry No", EDocument."Unstructured Data Entry No.");
    end;

#pragma warning disable AA0139
    procedure BuildFullUblJson(Header: Record "E-Document Purchase Header"; var Lines: Record "E-Document Purchase Line"): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        RootObj: JsonObject;
        SupplierPartyObj: JsonObject;
        SupplierPartyInner: JsonObject;
        CustomerPartyObj: JsonObject;
        CustomerPartyInner: JsonObject;
        DeliveryObj: JsonObject;
        DeliveryPartyObj: JsonObject;
        PaymentMeansObj: JsonObject;
        PayeeAccountObj: JsonObject;
        PaymentTermsObj: JsonObject;
        TaxTotalObj: JsonObject;
        LegalMonetaryObj: JsonObject;
        OrderRefObj: JsonObject;
        LinesArray: JsonArray;
        CurrencyCode: Text;
        ResultText: Text;
    begin
        CurrencyCode := Header."Currency Code";
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            CurrencyCode := GeneralLedgerSetup."LCY Code";
        end;

        RootObj.Add('id', Header."Sales Invoice No.");
        RootObj.Add('issue_date', FormatDate(Header."Document Date"));
        RootObj.Add('due_date', FormatDate(Header."Due Date"));
        RootObj.Add('document_currency_code', CurrencyCode);

        // Order reference
        OrderRefObj.Add('id', Header."Purchase Order No.");
        RootObj.Add('order_reference', OrderRefObj);

        // Supplier party
        AddPartyObject(SupplierPartyInner, Header."Vendor Company Name", Header."Vendor Address", Header."Vendor VAT Id", Header."Vendor Contact Name");
        SupplierPartyObj.Add('party', SupplierPartyInner);
        RootObj.Add('accounting_supplier_party', SupplierPartyObj);

        // Customer party
        AddPartyObject(CustomerPartyInner, Header."Customer Company Name", Header."Customer Address", Header."Customer VAT Id", '');
        CustomerPartyObj.Add('party', CustomerPartyInner);
        RootObj.Add('accounting_customer_party', CustomerPartyObj);

        // Delivery
        DeliveryObj.Add('delivery_location', BuildDeliveryLocation(Header."Shipping Address"));
        AddPartyNameObject(DeliveryPartyObj, Header."Shipping Address Recipient");
        DeliveryObj.Add('delivery_party', DeliveryPartyObj);
        RootObj.Add('delivery', DeliveryObj);

        // Payment means
        PayeeAccountObj.Add('name', Header."Remittance Address Recipient");
        PaymentMeansObj.Add('payee_financial_account', PayeeAccountObj);
        RootObj.Add('payment_means', PaymentMeansObj);

        // Payment terms
        PaymentTermsObj.Add('note', Header."Payment Terms");
        RootObj.Add('payment_terms', PaymentTermsObj);

        // Tax total
        TaxTotalObj.Add('tax_amount', FormatDecimal(Header."Total VAT"));
        RootObj.Add('tax_total', TaxTotalObj);

        // Legal monetary total
        LegalMonetaryObj.Add('tax_exclusive_amount', FormatDecimal(Header."Sub Total"));
        LegalMonetaryObj.Add('allowance_total_amount', FormatDecimal(Header."Total Discount"));
        LegalMonetaryObj.Add('payable_amount', FormatDecimal(Header.Total));
        RootObj.Add('legal_monetary_total', LegalMonetaryObj);

        // Lines
        Lines.FindSet();
        repeat
            LinesArray.Add(BuildLineObject(Lines));
        until Lines.Next() = 0;
        RootObj.Add('invoice_line', LinesArray);

        RootObj.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure BuildLineObject(Line: Record "E-Document Purchase Line"): JsonObject
    var
        LineObj: JsonObject;
        ItemObj: JsonObject;
        SellersIdObj: JsonObject;
        TaxCatObj: JsonObject;
        QuantityObj: JsonObject;
        PriceObj: JsonObject;
        AllowanceObj: JsonObject;
        AllowanceAmountObj: JsonObject;
    begin
        // Item
        ItemObj.Add('name', Line.Description);
        SellersIdObj.Add('id', Line."Product Code");
        ItemObj.Add('sellers_item_identification', SellersIdObj);
        TaxCatObj.Add('percent', FormatDecimal(Line."VAT Rate"));
        ItemObj.Add('classified_tax_category', TaxCatObj);
        LineObj.Add('item', ItemObj);

        // Quantity
        QuantityObj.Add('value', FormatDecimal(Line.Quantity));
        QuantityObj.Add('unit_code', Line."Unit of Measure");
        LineObj.Add('invoiced_quantity', QuantityObj);

        // Price
        PriceObj.Add('price_amount', FormatDecimal(Line."Unit Price"));
        LineObj.Add('price', PriceObj);

        // Line extension amount
        LineObj.Add('line_extension_amount', FormatDecimal(Line."Sub Total"));

        // Allowance charge
        AllowanceAmountObj.Add('value', FormatDecimal(Line."Total Discount"));
        AllowanceObj.Add('amount', AllowanceAmountObj);
        LineObj.Add('allowance_charge', AllowanceObj);

        exit(LineObj);
    end;

    local procedure AddPartyObject(var PartyObj: JsonObject; CompanyName: Text; Address: Text; VatId: Text; ContactName: Text)
    var
        PartyNameObj: JsonObject;
        PostalAddressObj: JsonObject;
        TaxSchemeObj: JsonObject;
        ContactObj: JsonObject;
    begin
        PartyNameObj.Add('name', CompanyName);
        PartyObj.Add('party_name', PartyNameObj);

        PostalAddressObj.Add('street_name', Address);
        PartyObj.Add('postal_address', PostalAddressObj);

        TaxSchemeObj.Add('company_id', VatId);
        PartyObj.Add('party_tax_scheme', TaxSchemeObj);

        if ContactName <> '' then begin
            ContactObj.Add('name', ContactName);
            PartyObj.Add('contact', ContactObj);
        end;
    end;

    local procedure AddPartyNameObject(var PartyObj: JsonObject; Name: Text)
    var
        PartyNameObj: JsonObject;
    begin
        PartyNameObj.Add('name', Name);
        PartyObj.Add('party_name', PartyNameObj);
    end;

    local procedure BuildDeliveryLocation(Address: Text): JsonObject
    var
        DeliveryLocObj: JsonObject;
        AddressObj: JsonObject;
    begin
        AddressObj.Add('street_name', Address);
        DeliveryLocObj.Add('address', AddressObj);
        exit(DeliveryLocObj);
    end;

    local procedure FormatDate(DateValue: Date): Text
    begin
        if DateValue = 0D then
            exit('');
        exit(Format(DateValue, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatDecimal(DecValue: Decimal): Text
    begin
        exit(Format(DecValue, 0, '<Precision,2:2><Standard Format,9>'));
    end;
#pragma warning restore AA0139

    local procedure UpsertExemplar(VendorName: Text[250]; VendorNo: Code[20]; JsonText: Text; EDocEntryNo: Integer; UnstructuredDataEntryNo: Integer)
    var
        Exemplar: Record "E-Doc. MLLM Vendor Exemplar";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        RecordRef: RecordRef;
        NormalizedName: Text[250];
    begin
        NormalizedName := CopyStr(UpperCase(VendorName), 1, 250);

        Exemplar.SetRange("Vendor Company Name", NormalizedName);
        if Exemplar.FindFirst() then begin
            // Update existing
            TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.Write(JsonText);
            RecordRef.GetTable(Exemplar);
            TempBlob.ToRecordRef(RecordRef, Exemplar.FieldNo("Corrected UBL JSON"));
            RecordRef.SetTable(Exemplar);

            Exemplar."Vendor No." := VendorNo;
            Exemplar."E-Document Entry No." := EDocEntryNo;
            Exemplar."Unstructured Data Entry No." := UnstructuredDataEntryNo;
            Exemplar."Created At" := CurrentDateTime();
            Exemplar.Modify(true);
        end else begin
            // Insert new
            Exemplar.Init();
            Exemplar."Vendor Company Name" := NormalizedName;
            Exemplar."Vendor No." := VendorNo;
            Exemplar."E-Document Entry No." := EDocEntryNo;
            Exemplar."Unstructured Data Entry No." := UnstructuredDataEntryNo;
            Exemplar."Created At" := CurrentDateTime();
            Exemplar.Insert(true);

            TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.Write(JsonText);
            RecordRef.GetTable(Exemplar);
            TempBlob.ToRecordRef(RecordRef, Exemplar.FieldNo("Corrected UBL JSON"));
            RecordRef.SetTable(Exemplar);
            Exemplar.Modify();
        end;
    end;
}
