// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Bank.Payment;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 11515 "CH Report Management"
{

    trigger OnRun()
    begin
    end;

    var
        PurchPersonTxt: Label 'Purchaser';
        SalesPersonTxt: Label 'Salesperson';
        YourReferenceTxt: Label 'Reference';
        OrderNoTxt: Label 'Order No.';
        InvoiceNoTxt: Label 'Ext. Invoice No.';
        PaymentTermsTxt: Label 'Payment Terms';
        ApplyToDocTxt: Label 'Refers to Document';
        ShipCondTxt: Label 'Shipping Conditions';
        ShipAdrTxt: Label 'Shipping Address';
        InvAdrTxt: Label 'Invoice Address';
        OrderAdrTxt: Label 'Order Address';
        ShipDateTxt: Label 'Shipping Date';
        ExpReceiptDateTxt: Label 'Expected Receipt Date';
        BankInformationTxt: Label 'Bank Information';
        AccountTxt: Label 'Account';

    procedure PrepareHeader(RecRef: RecordRef; ReportId: Integer; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    begin
        Clear(HeaderLabel);
        Clear(HeaderTxt);

        case ReportId of
            REPORT::"Standard Sales - Quote",
          REPORT::"Blanket Sales Order",
          REPORT::"Sales Picking List",
          REPORT::"Standard Sales - Order Conf.",
          REPORT::"Return Order Confirmation",
          REPORT::"Sales - Shipment",
          REPORT::"Standard Sales - Credit Memo":
                PrepareHeaderSalesCommonPart(RecRef, HeaderLabel, HeaderTxt);
            REPORT::"Sales Invoice ESR",
          REPORT::"Standard Sales - Invoice":
                PrepareHeaderSalesInvoice(RecRef, HeaderLabel, HeaderTxt);
            REPORT::"Purchase - Quote",
          REPORT::"Purchase - Credit Memo",
          REPORT::"Purchase - Receipt",
          REPORT::"Return Order",
          REPORT::"Blanket Purchase Order",
          REPORT::Order:
                PrepareHeadePurchaseCommonPart(RecRef, HeaderLabel, HeaderTxt);
            REPORT::"Purchase - Invoice":
                PrepareHeaderPurchaseInvoice(RecRef, HeaderLabel, HeaderTxt);
        end;

        OnAfterPrepareHeader(RecRef, ReportId, HeaderLabel, HeaderTxt);

        CompressArray(HeaderLabel);
        CompressArray(HeaderTxt);
    end;

    local procedure PrepareHeaderSalesCommonPart(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        YourReference: Text;
    begin
        if SalespersonPurchaser.Get(GetFieldValue(RecRef, SalesHeader.FieldNo("Salesperson Code"))) then begin
            HeaderLabel[2] := SalesPersonTxt;
            HeaderTxt[2] := SalespersonPurchaser.Name;
        end;

        YourReference := GetFieldValue(RecRef, SalesHeader.FieldNo("Your Reference"));
        if YourReference <> '' then begin
            HeaderLabel[3] := YourReferenceTxt;
            HeaderTxt[3] := YourReference;
        end;
    end;

    local procedure PrepareHeaderSalesInvoice(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        RecRef.SetTable(SalesInvoiceHeader);
        if SalesInvoiceHeader."Order No." <> '' then begin
            HeaderLabel[1] := OrderNoTxt;
            HeaderTxt[1] := SalesInvoiceHeader."Order No.";
        end;

        PrepareHeaderSalesCommonPart(RecRef, HeaderLabel, HeaderTxt);
    end;

    local procedure PrepareHeadePurchaseCommonPart(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        PurchaseHeader: Record "Purchase Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        YourReference: Text;
    begin
        if SalespersonPurchaser.Get(GetFieldValue(RecRef, PurchaseHeader.FieldNo("Purchaser Code"))) then begin
            HeaderLabel[3] := PurchPersonTxt;
            HeaderTxt[3] := SalespersonPurchaser.Name;
        end;

        YourReference := GetFieldValue(RecRef, PurchaseHeader.FieldNo("Your Reference"));
        if YourReference <> '' then begin
            HeaderLabel[4] := YourReferenceTxt;
            HeaderTxt[4] := YourReference;
        end;
    end;

    procedure PrepareFooter(RecRef: RecordRef; ReportId: Integer; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    begin
        Clear(FooterLabel);
        Clear(FooterTxt);

        case ReportId of
            REPORT::"Standard Sales - Quote",
          REPORT::"Blanket Sales Order",
          REPORT::"Standard Sales - Order Conf.",
          REPORT::"Return Order Confirmation",
          REPORT::"Standard Sales - Invoice",
          REPORT::"Sales Invoice ESR",
          REPORT::"Standard Sales - Credit Memo":
                PrepareFooterSalesCommonPart(RecRef, FooterLabel, FooterTxt, true);
            REPORT::"Sales Picking List",
          REPORT::"Sales - Shipment":
                PrepareFooterSalesCommonPart(RecRef, FooterLabel, FooterTxt, false);
            REPORT::"Purchase - Quote",
          REPORT::"Purchase - Invoice",
          REPORT::"Purchase - Credit Memo",
          REPORT::"Purchase - Receipt",
          REPORT::"Return Order",
          REPORT::"Blanket Purchase Order",
          REPORT::Order:
                PrepareFooterPurchaseCommonPart(RecRef, FooterLabel, FooterTxt);
        end;

        OnAfterPrepareFooter(RecRef, ReportId, FooterLabel, FooterTxt);

        CompressArray(FooterLabel);
        CompressArray(FooterTxt);
    end;

    local procedure PrepareFooterSalesCommonPart(RecRef: RecordRef; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text; ShowBankInfo: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        AppliesToDocNo: Text;
    begin
        if PaymentTerms.Get(GetFieldValue(RecRef, SalesHeader.FieldNo("Payment Terms Code"))) then begin
            FooterLabel[1] := PaymentTermsTxt;
            PaymentTerms.TranslateDescription(PaymentTerms, SalesHeader."Language Code");
            FooterTxt[1] := PaymentTerms.Description;
        end;

        AppliesToDocNo := GetFieldValue(RecRef, SalesHeader.FieldNo("Applies-to Doc. No."));
        if AppliesToDocNo <> '' then begin
            FooterLabel[2] := ApplyToDocTxt;
            FooterTxt[2] := GetFieldValue(RecRef, SalesHeader.FieldNo("Applies-to Doc. Type")) + ' ' + AppliesToDocNo;
        end;

        if ShipmentMethod.Get(GetFieldValue(RecRef, SalesHeader.FieldNo("Shipment Method Code"))) then begin
            FooterLabel[3] := ShipCondTxt;
            ShipmentMethod.TranslateDescription(ShipmentMethod, SalesHeader."Language Code");
            FooterTxt[3] := ShipmentMethod.Description;
        end;

        if GetFieldValue(RecRef, SalesHeader.FieldNo("Ship-to Code")) <> '' then begin
            FooterLabel[4] := ShipAdrTxt;
            FooterTxt[4] := GetFieldValue(RecRef, SalesHeader.FieldNo("Ship-to Name")) + ' ' + GetFieldValue(RecRef, SalesHeader.FieldNo("Ship-to City"));
        end;

        if GetFieldValue(RecRef, SalesHeader.FieldNo("Sell-to Customer No.")) <> GetFieldValue(RecRef, SalesHeader.FieldNo("Bill-to Customer No.")) then begin
            FooterLabel[5] := InvAdrTxt;
            FooterTxt[5] := GetFieldValue(RecRef, SalesHeader.FieldNo("Bill-to Name")) + ', ' + GetFieldValue(RecRef, SalesHeader.FieldNo("Bill-to City"));
            FooterLabel[6] := OrderAdrTxt;
            FooterTxt[6] :=
              GetFieldValue(RecRef, SalesHeader.FieldNo("Sell-to Customer Name")) + ', ' + GetFieldValue(RecRef, SalesHeader.FieldNo("Sell-to City"));
        end;

        if (GetFieldValue(RecRef, SalesHeader.FieldNo("Shipment Date")) <> GetFieldValue(RecRef, SalesHeader.FieldNo("Document Date"))) and
           (GetFieldValue(RecRef, SalesHeader.FieldNo("Shipment Date")) <> '')
        then begin
            FooterLabel[7] := ShipDateTxt;
            FooterTxt[7] := GetDateFieldValue(RecRef, SalesHeader.FieldNo("Shipment Date"));
        end;

        if ShowBankInfo then begin
            CompanyInformation.Get();
            CompanyInformation.TestField("Bank Name");
            FooterLabel[8] := BankInformationTxt;
            FooterTxt[8] := StrSubstNo('%1, %2 %3', CompanyInformation."Bank Name", AccountTxt, CompanyInformation."Bank Account No.");
        end;
    end;

    local procedure PrepareFooterPurchaseCommonPart(RecRef: RecordRef; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    var
        PaymentTerms: Record "Payment Terms";
        ShipmentMethod: Record "Shipment Method";
        PurchaseHeader: Record "Purchase Header";
    begin
        if PaymentTerms.Get(GetFieldValue(RecRef, PurchaseHeader.FieldNo("Payment Terms Code"))) then begin
            FooterLabel[1] := PaymentTermsTxt;
            PaymentTerms.TranslateDescription(PaymentTerms, PurchaseHeader."Language Code");
            FooterTxt[1] := PaymentTerms.Description;
        end;

        if ShipmentMethod.Get(GetFieldValue(RecRef, PurchaseHeader.FieldNo("Shipment Method Code"))) then begin
            FooterLabel[2] := ShipCondTxt;
            ShipmentMethod.TranslateDescription(ShipmentMethod, PurchaseHeader."Language Code");
            FooterTxt[2] := ShipmentMethod.Description;
        end;

        if GetFieldValue(RecRef, PurchaseHeader.FieldNo("Ship-to Code")) <> '' then begin
            FooterLabel[3] := ShipAdrTxt;
            FooterTxt[3] := GetFieldValue(RecRef, PurchaseHeader.FieldNo("Ship-to Name")) + ' ' + GetFieldValue(RecRef, PurchaseHeader.FieldNo("Ship-to City"));
        end;

        if GetFieldValue(RecRef, PurchaseHeader.FieldNo("Buy-from Vendor No.")) <> GetFieldValue(RecRef, PurchaseHeader.FieldNo("Pay-to Vendor No.")) then begin
            FooterLabel[4] := InvAdrTxt;
            FooterTxt[4] := GetFieldValue(RecRef, PurchaseHeader.FieldNo("Pay-to Name")) + ', ' + GetFieldValue(RecRef, PurchaseHeader.FieldNo("Pay-to City"));
            FooterLabel[5] := OrderAdrTxt;
            FooterTxt[5] :=
              GetFieldValue(RecRef, PurchaseHeader.FieldNo("Buy-from Vendor Name")) + ', ' + GetFieldValue(RecRef, PurchaseHeader.FieldNo("Buy-from City"));
        end;

        if (GetFieldValue(RecRef, PurchaseHeader.FieldNo("Expected Receipt Date")) <> GetFieldValue(RecRef, PurchaseHeader.FieldNo("Document Date"))) and
           (GetFieldValue(RecRef, PurchaseHeader.FieldNo("Expected Receipt Date")) <> '')
        then begin
            FooterLabel[6] := ExpReceiptDateTxt;
            FooterTxt[6] := GetDateFieldValue(RecRef, PurchaseHeader.FieldNo("Expected Receipt Date"));
        end;
    end;

    local procedure PrepareHeaderPurchaseInvoice(RecRef: RecordRef; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        RecRef.SetTable(PurchInvHeader);
        if PurchInvHeader."Order No." <> '' then begin
            HeaderLabel[1] := OrderNoTxt;
            HeaderTxt[1] := PurchInvHeader."Order No.";
        end;

        if PurchInvHeader."Vendor Invoice No." <> '' then begin
            HeaderLabel[2] := InvoiceNoTxt;
            HeaderTxt[2] := PurchInvHeader."Vendor Invoice No.";
        end;
        PrepareHeadePurchaseCommonPart(RecRef, HeaderLabel, HeaderTxt);
    end;

    local procedure GetFieldValue(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        exit(Format(FieldRef.Value));
    end;

    local procedure GetDateFieldValue(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        exit(Format(FieldRef.Value, 0, 4));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareHeader(RecRef: RecordRef; ReportId: Integer; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareFooter(RecRef: RecordRef; ReportId: Integer; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    begin
    end;
}

