// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 6232 "E-Doc. MLLM Schema Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetDefaultSchema() Value: Text
    var
        DefaultSchemaFileLbl: Label 'AITools/ubl_example.json', Locked = true;
        JsonObject: JsonObject;
    begin
        JsonObject := NavApp.GetResourceAsJson(DefaultSchemaFileLbl, TextEncoding::UTF8);
        JsonObject.WriteTo(Value);
    end;

#pragma warning disable AA0139
    procedure MapHeaderFromJson(HeaderObj: JsonObject; var TempHeader: Record "E-Document Purchase Header" temporary)
    var
        NestedObj: JsonObject;
        NestedObj2: JsonObject;
        NestedObj3: JsonObject;
        CurrencyText: Text;
    begin
        GetString(HeaderObj, 'id', MaxStrLen(TempHeader."Sales Invoice No."), TempHeader."Sales Invoice No.");
        GetDate(HeaderObj, 'issue_date', TempHeader."Document Date");
        GetDate(HeaderObj, 'due_date', TempHeader."Due Date");

        GetString(HeaderObj, 'document_currency_code', MaxStrLen(TempHeader."Currency Code"), CurrencyText);
        SetCurrencyCode(CurrencyText, TempHeader."Currency Code");

        if GetNestedObject(HeaderObj, 'order_reference', NestedObj) then
            GetString(NestedObj, 'id', MaxStrLen(TempHeader."Purchase Order No."), TempHeader."Purchase Order No.");

        if GetNestedObject(HeaderObj, 'payment_terms', NestedObj) then
            GetString(NestedObj, 'note', MaxStrLen(TempHeader."Payment Terms"), TempHeader."Payment Terms");

        if GetNestedObject(HeaderObj, 'accounting_supplier_party', NestedObj) then
            if GetNestedObject(NestedObj, 'party', NestedObj2) then begin
                if GetNestedObject(NestedObj2, 'party_name', NestedObj3) then
                    GetString(NestedObj3, 'name', MaxStrLen(TempHeader."Vendor Company Name"), TempHeader."Vendor Company Name");
                if GetNestedObject(NestedObj2, 'postal_address', NestedObj3) then
                    BuildAddress(NestedObj3, MaxStrLen(TempHeader."Vendor Address"), TempHeader."Vendor Address");
                if GetNestedObject(NestedObj2, 'party_tax_scheme', NestedObj3) then
                    GetString(NestedObj3, 'company_id', MaxStrLen(TempHeader."Vendor VAT Id"), TempHeader."Vendor VAT Id");
                if GetNestedObject(NestedObj2, 'contact', NestedObj3) then
                    GetString(NestedObj3, 'name', MaxStrLen(TempHeader."Vendor Contact Name"), TempHeader."Vendor Contact Name");
            end;

        if GetNestedObject(HeaderObj, 'accounting_customer_party', NestedObj) then
            if GetNestedObject(NestedObj, 'party', NestedObj2) then begin
                if GetNestedObject(NestedObj2, 'party_name', NestedObj3) then
                    GetString(NestedObj3, 'name', MaxStrLen(TempHeader."Customer Company Name"), TempHeader."Customer Company Name");
                if GetNestedObject(NestedObj2, 'postal_address', NestedObj3) then
                    BuildAddress(NestedObj3, MaxStrLen(TempHeader."Customer Address"), TempHeader."Customer Address");
                if GetNestedObject(NestedObj2, 'party_tax_scheme', NestedObj3) then
                    GetString(NestedObj3, 'company_id', MaxStrLen(TempHeader."Customer VAT Id"), TempHeader."Customer VAT Id");
            end;

        if GetNestedObject(HeaderObj, 'delivery', NestedObj) then begin
            if GetNestedObject(NestedObj, 'delivery_location', NestedObj2) then
                if GetNestedObject(NestedObj2, 'address', NestedObj3) then
                    BuildAddress(NestedObj3, MaxStrLen(TempHeader."Shipping Address"), TempHeader."Shipping Address");
            if GetNestedObject(NestedObj, 'delivery_party', NestedObj2) then
                if GetNestedObject(NestedObj2, 'party_name', NestedObj3) then
                    GetString(NestedObj3, 'name', MaxStrLen(TempHeader."Shipping Address Recipient"), TempHeader."Shipping Address Recipient");
        end;

        if GetNestedObject(HeaderObj, 'payment_means', NestedObj) then
            if GetNestedObject(NestedObj, 'payee_financial_account', NestedObj2) then
                GetString(NestedObj2, 'name', MaxStrLen(TempHeader."Remittance Address Recipient"), TempHeader."Remittance Address Recipient");

        if GetNestedObject(HeaderObj, 'tax_total', NestedObj) then
            GetDecimal(NestedObj, 'tax_amount', TempHeader."Total VAT");

        if GetNestedObject(HeaderObj, 'legal_monetary_total', NestedObj) then begin
            GetDecimal(NestedObj, 'tax_exclusive_amount', TempHeader."Sub Total");
            GetDecimal(NestedObj, 'allowance_total_amount', TempHeader."Total Discount");
            GetDecimal(NestedObj, 'payable_amount', TempHeader.Total);
            GetDecimal(NestedObj, 'payable_amount', TempHeader."Amount Due");
        end;
    end;

    procedure MapLinesFromJson(LinesArray: JsonArray; EDocEntryNo: Integer; var TempLine: Record "E-Document Purchase Line" temporary)
    var
        LineToken: JsonToken;
        LineObj: JsonObject;
        NestedObj: JsonObject;
        NestedObj2: JsonObject;
        LineNumber: Integer;
    begin
        TempLine.DeleteAll();

        for LineNumber := 0 to LinesArray.Count() - 1 do
            if LinesArray.Get(LineNumber, LineToken) then begin
                Clear(TempLine);
                TempLine."E-Document Entry No." := EDocEntryNo;
                TempLine."Line No." := 10000 + (LineNumber * 10000);

                LineObj := LineToken.AsObject();

                if GetNestedObject(LineObj, 'item', NestedObj) then begin
                    GetString(NestedObj, 'name', MaxStrLen(TempLine.Description), TempLine.Description);
                    if GetNestedObject(NestedObj, 'sellers_item_identification', NestedObj2) then
                        GetString(NestedObj2, 'id', MaxStrLen(TempLine."Product Code"), TempLine."Product Code");
                    if GetNestedObject(NestedObj, 'classified_tax_category', NestedObj2) then
                        GetDecimal(NestedObj2, 'percent', TempLine."VAT Rate");
                end;

                if GetNestedObject(LineObj, 'invoiced_quantity', NestedObj) then begin
                    GetDecimal(NestedObj, 'value', TempLine.Quantity);
                    GetString(NestedObj, 'unit_code', MaxStrLen(TempLine."Unit of Measure"), TempLine."Unit of Measure");
                end;
                if TempLine.Quantity <= 0 then
                    TempLine.Quantity := 1;

                if GetNestedObject(LineObj, 'price', NestedObj) then
                    GetDecimal(NestedObj, 'price_amount', TempLine."Unit Price");

                GetDecimal(LineObj, 'line_extension_amount', TempLine."Sub Total");

                if GetNestedObject(LineObj, 'allowance_charge', NestedObj) then
                    if GetNestedObject(NestedObj, 'amount', NestedObj2) then
                        GetDecimal(NestedObj2, 'value', TempLine."Total Discount");

                TempLine.Insert();
            end;
    end;
#pragma warning restore AA0139

    internal procedure GetString(JsonObj: JsonObject; PropertyName: Text; MaxLen: Integer; var FieldValue: Text)
    var
        JsonToken: JsonToken;
        TextValue: Text;
    begin
        if not JsonObj.Get(PropertyName, JsonToken) then
            exit;
        if JsonToken.AsValue().IsNull() then
            exit;
        TextValue := JsonToken.AsValue().AsText();
        if StrLen(TextValue) > MaxLen then
            TextValue := CopyStr(TextValue, 1, MaxLen);
        FieldValue := TextValue;
    end;

    local procedure GetDate(JsonObj: JsonObject; PropertyName: Text; var FieldValue: Date)
    var
        JsonToken: JsonToken;
        DateText: Text;
        DateValue: Date;
    begin
        if not JsonObj.Get(PropertyName, JsonToken) then
            exit;
        if JsonToken.AsValue().IsNull() then
            exit;
        DateText := JsonToken.AsValue().AsText();
        if DateText = '' then
            exit;
        if Evaluate(DateValue, DateText, 9) then
            FieldValue := DateValue;
    end;

    local procedure GetDecimal(JsonObj: JsonObject; PropertyName: Text; var FieldValue: Decimal)
    var
        JsonToken: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, JsonToken) then
            exit;
        if JsonToken.AsValue().IsNull() then
            exit;
        FieldValue := JsonToken.AsValue().AsDecimal();
    end;

    internal procedure GetNestedObject(JsonObj: JsonObject; PropertyName: Text; var NestedObj: JsonObject): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonObj.Get(PropertyName, JsonToken) then
            exit(false);
        if not JsonToken.IsObject() then
            exit(false);
        NestedObj := JsonToken.AsObject();
        exit(true);
    end;

    local procedure BuildAddress(PostalAddressObj: JsonObject; MaxLen: Integer; var FieldValue: Text)
    var
        CountryObj: JsonObject;
        Street: Text;
        AdditionalStreet: Text;
        City: Text;
        PostalZone: Text;
        CountryCode: Text;
        Address: Text;
    begin
        GetString(PostalAddressObj, 'street_name', 250, Street);
        GetString(PostalAddressObj, 'additional_street_name', 250, AdditionalStreet);
        GetString(PostalAddressObj, 'city_name', 250, City);
        GetString(PostalAddressObj, 'postal_zone', 250, PostalZone);
        if GetNestedObject(PostalAddressObj, 'country', CountryObj) then
            GetString(CountryObj, 'identification_code', 250, CountryCode);

        Address := Street;
        AppendToAddress(Address, AdditionalStreet, ', ');
        AppendToAddress(Address, City, ', ');
        AppendToAddress(Address, PostalZone, ' ');
        AppendToAddress(Address, CountryCode, ', ');

        if StrLen(Address) > MaxLen then
            Address := CopyStr(Address, 1, MaxLen);
        FieldValue := Address;
    end;

    local procedure AppendToAddress(var Address: Text; Part: Text; Separator: Text)
    begin
        if Part = '' then
            exit;
        if Address <> '' then
            Address += Separator;
        Address += Part;
    end;

    local procedure SetCurrencyCode(CurrencyText: Text; var CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyText = '' then
            exit;

        GeneralLedgerSetup.Get();
        if UpperCase(CurrencyText) = GeneralLedgerSetup."LCY Code" then
            exit;

        CurrencyCode := CopyStr(UpperCase(CurrencyText), 1, MaxStrLen(CurrencyCode));
    end;
}
