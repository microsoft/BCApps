// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 6203 "E-Doc. MLLM Schema Helper"
{
    Access = Internal;

    procedure GetDefaultSchema(): Text
    var
        DefaultSchemaLbl: Label '{"invoiceNumber":"","issueDate":"","dueDate":"","invoicePeriod":{"startDate":"","endDate":""},"orderReference":"","documentCurrencyCode":"","postingDescription":"","accountingSupplierParty":{"name":"","address":"","addressRecipient":"","contactName":"","vatId":"","gln":"","externalId":""},"accountingCustomerParty":{"name":"","companyId":"","address":"","addressRecipient":"","vatId":"","gln":""},"billingAddress":{"address":"","addressRecipient":""},"delivery":{"address":"","addressRecipient":""},"paymentMeans":{"remittanceAddress":"","remittanceAddressRecipient":""},"paymentTerms":"","legalMonetaryTotal":{"taxExclusiveAmount":0,"allowanceTotalAmount":0,"taxAmount":0,"payableAmount":0,"amountDue":0,"previousUnpaidBalance":0},"invoiceLines":[{"description":"","sellersItemIdentification":"","invoicedQuantity":0,"unitCode":"","priceAmount":0,"lineExtensionAmount":0,"allowanceAmount":0,"taxPercent":0,"currencyCode":"","date":""}]}', Locked = true;
    begin
        exit(DefaultSchemaLbl);
    end;

#pragma warning disable AA0139
    procedure MapHeaderFromJson(HeaderObj: JsonObject; var TempHeader: Record "E-Document Purchase Header" temporary)
    var
        NestedObj: JsonObject;
        CurrencyText: Text;
    begin
        GetString(HeaderObj, 'invoiceNumber', MaxStrLen(TempHeader."Sales Invoice No."), TempHeader."Sales Invoice No.");
        GetDate(HeaderObj, 'issueDate', TempHeader."Document Date");
        GetDate(HeaderObj, 'dueDate', TempHeader."Due Date");
        GetString(HeaderObj, 'orderReference', MaxStrLen(TempHeader."Purchase Order No."), TempHeader."Purchase Order No.");
        GetString(HeaderObj, 'postingDescription', MaxStrLen(TempHeader."Posting Description"), TempHeader."Posting Description");
        GetString(HeaderObj, 'paymentTerms', MaxStrLen(TempHeader."Payment Terms"), TempHeader."Payment Terms");

        GetString(HeaderObj, 'documentCurrencyCode', MaxStrLen(TempHeader."Currency Code"), CurrencyText);
        SetCurrencyCode(CurrencyText, TempHeader."Currency Code");

        if GetNestedObject(HeaderObj, 'invoicePeriod', NestedObj) then begin
            GetDate(NestedObj, 'startDate', TempHeader."Service Start Date");
            GetDate(NestedObj, 'endDate', TempHeader."Service End Date");
        end;

        if GetNestedObject(HeaderObj, 'accountingSupplierParty', NestedObj) then begin
            GetString(NestedObj, 'name', MaxStrLen(TempHeader."Vendor Company Name"), TempHeader."Vendor Company Name");
            GetString(NestedObj, 'address', MaxStrLen(TempHeader."Vendor Address"), TempHeader."Vendor Address");
            GetString(NestedObj, 'addressRecipient', MaxStrLen(TempHeader."Vendor Address Recipient"), TempHeader."Vendor Address Recipient");
            GetString(NestedObj, 'contactName', MaxStrLen(TempHeader."Vendor Contact Name"), TempHeader."Vendor Contact Name");
            GetString(NestedObj, 'vatId', MaxStrLen(TempHeader."Vendor VAT Id"), TempHeader."Vendor VAT Id");
            GetString(NestedObj, 'gln', MaxStrLen(TempHeader."Vendor GLN"), TempHeader."Vendor GLN");
            GetString(NestedObj, 'externalId', MaxStrLen(TempHeader."Vendor External Id"), TempHeader."Vendor External Id");
        end;

        if GetNestedObject(HeaderObj, 'accountingCustomerParty', NestedObj) then begin
            GetString(NestedObj, 'name', MaxStrLen(TempHeader."Customer Company Name"), TempHeader."Customer Company Name");
            GetString(NestedObj, 'companyId', MaxStrLen(TempHeader."Customer Company Id"), TempHeader."Customer Company Id");
            GetString(NestedObj, 'address', MaxStrLen(TempHeader."Customer Address"), TempHeader."Customer Address");
            GetString(NestedObj, 'addressRecipient', MaxStrLen(TempHeader."Customer Address Recipient"), TempHeader."Customer Address Recipient");
            GetString(NestedObj, 'vatId', MaxStrLen(TempHeader."Customer VAT Id"), TempHeader."Customer VAT Id");
            GetString(NestedObj, 'gln', MaxStrLen(TempHeader."Customer GLN"), TempHeader."Customer GLN");
        end;

        if GetNestedObject(HeaderObj, 'billingAddress', NestedObj) then begin
            GetString(NestedObj, 'address', MaxStrLen(TempHeader."Billing Address"), TempHeader."Billing Address");
            GetString(NestedObj, 'addressRecipient', MaxStrLen(TempHeader."Billing Address Recipient"), TempHeader."Billing Address Recipient");
        end;

        if GetNestedObject(HeaderObj, 'delivery', NestedObj) then begin
            GetString(NestedObj, 'address', MaxStrLen(TempHeader."Shipping Address"), TempHeader."Shipping Address");
            GetString(NestedObj, 'addressRecipient', MaxStrLen(TempHeader."Shipping Address Recipient"), TempHeader."Shipping Address Recipient");
        end;

        if GetNestedObject(HeaderObj, 'paymentMeans', NestedObj) then begin
            GetString(NestedObj, 'remittanceAddress', MaxStrLen(TempHeader."Remittance Address"), TempHeader."Remittance Address");
            GetString(NestedObj, 'remittanceAddressRecipient', MaxStrLen(TempHeader."Remittance Address Recipient"), TempHeader."Remittance Address Recipient");
        end;

        if GetNestedObject(HeaderObj, 'legalMonetaryTotal', NestedObj) then begin
            GetDecimal(NestedObj, 'taxExclusiveAmount', TempHeader."Sub Total");
            GetDecimal(NestedObj, 'allowanceTotalAmount', TempHeader."Total Discount");
            GetDecimal(NestedObj, 'taxAmount', TempHeader."Total VAT");
            GetDecimal(NestedObj, 'payableAmount', TempHeader.Total);
            GetDecimal(NestedObj, 'amountDue', TempHeader."Amount Due");
            GetDecimal(NestedObj, 'previousUnpaidBalance', TempHeader."Previous Unpaid Balance");
        end;
    end;

    procedure MapLinesFromJson(LinesArray: JsonArray; EDocEntryNo: Integer; var TempLine: Record "E-Document Purchase Line" temporary)
    var
        LineToken: JsonToken;
        LineObj: JsonObject;
        CurrencyText: Text;
        LineNumber: Integer;
    begin
        TempLine.DeleteAll();

        for LineNumber := 0 to LinesArray.Count() - 1 do begin
            if LinesArray.Get(LineNumber, LineToken) then begin
                Clear(TempLine);
                TempLine."E-Document Entry No." := EDocEntryNo;
                TempLine."Line No." := 10000 + (LineNumber * 10000);

                LineObj := LineToken.AsObject();
                GetString(LineObj, 'description', MaxStrLen(TempLine.Description), TempLine.Description);
                GetString(LineObj, 'sellersItemIdentification', MaxStrLen(TempLine."Product Code"), TempLine."Product Code");
                GetDecimal(LineObj, 'invoicedQuantity', TempLine.Quantity);
                if TempLine.Quantity <= 0 then
                    TempLine.Quantity := 1;
                GetString(LineObj, 'unitCode', MaxStrLen(TempLine."Unit of Measure"), TempLine."Unit of Measure");
                GetDecimal(LineObj, 'priceAmount', TempLine."Unit Price");
                GetDecimal(LineObj, 'lineExtensionAmount', TempLine."Sub Total");
                GetDecimal(LineObj, 'allowanceAmount', TempLine."Total Discount");
                GetDecimal(LineObj, 'taxPercent', TempLine."VAT Rate");
                GetString(LineObj, 'currencyCode', MaxStrLen(TempLine."Currency Code"), CurrencyText);
                SetCurrencyCode(CurrencyText, TempLine."Currency Code");
                GetDate(LineObj, 'date', TempLine.Date);

                TempLine.Insert();
            end;
        end;
    end;
#pragma warning restore AA0139

    local procedure GetString(JsonObj: JsonObject; PropertyName: Text; MaxLen: Integer; var FieldValue: Text)
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

    local procedure GetNestedObject(JsonObj: JsonObject; PropertyName: Text; var NestedObj: JsonObject): Boolean
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
