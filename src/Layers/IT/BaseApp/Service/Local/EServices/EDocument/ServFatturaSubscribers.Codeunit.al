// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Utilities;

codeunit 12189 "Serv. Fattura Subscribers"
{
    var
        ErrorMessage: Record System.Utilities."Error Message";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        FatturaDocTypeDiffQst: Label 'There are one or more different values of Fattura document type coming from the VAT posting setup of lines. As it''''s not possible to identify the value, %1 from the header will be used.\\Do you want to continue?', Comment = '%1 = the value of Fattura Document type from the header';

    [EventSubscriber(ObjectType::Table, Database::"Fattura Header", 'OnGetTableID', '', false, false)]
    local procedure OnGetTableID(var FatturaHeader: Record "Fattura Header"; var TableID: Integer)
    begin
        if FatturaHeader."Entry Type" = FatturaHeader."Entry Type"::Service then
            case FatturaHeader."Document Type" of
                FatturaHeader."Document Type"::Invoice:
                    TableID := Database::"Service Invoice Header";
                FatturaHeader."Document Type"::"Credit Memo":
                    TableID := Database::"Service Cr.Memo Header";
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fattura Doc. Helper", 'OnInitFatturaHeaderWithCheckForTable', '', false, false)]
    local procedure OnInitFatturaHeaderWithCheckForTable(var HeaderRecRef: RecordRef; var LineRecRef: RecordRef; var TempFatturaHeader: Record "Fattura Header" temporary; PaymentMethod: Record "Payment Method")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case HeaderRecRef.Number of
            Database::"Service Invoice Header":
                begin
                    HeaderRecRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.CalcFields("Amount Including VAT");
                    CheckServiceInvHeaderFields(ServiceInvoiceHeader, PaymentMethod);
                    TempFatturaHeader."Entry Type" := TempFatturaHeader."Entry Type"::Service;
                    TempFatturaHeader."Document Type" := "Gen. Journal Document Type"::Invoice.AsInteger();
                    TempFatturaHeader."Posting Date" := ServiceInvoiceHeader."Posting Date";
                    TempFatturaHeader."Document No." := ServiceInvoiceHeader."No.";
                    LineRecRef.Open(Database::"Service Invoice Line");
                end;
            Database::"Service Cr.Memo Header":
                begin
                    HeaderRecRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.CalcFields("Amount Including VAT");
                    CheckServiceCrMemoHeaderFields(ServiceCrMemoHeader, PaymentMethod);
                    TempFatturaHeader."Entry Type" := TempFatturaHeader."Entry Type"::Service;
                    TempFatturaHeader."Document Type" := "Gen. Journal Document Type"::"Credit Memo".AsInteger();
                    TempFatturaHeader."Posting Date" := ServiceCrMemoHeader."Posting Date";
                    TempFatturaHeader."Document No." := ServiceCrMemoHeader."No.";
                    LineRecRef.Open(Database::"Service Cr.Memo Line");
                end;
        end;
    end;

    local procedure CheckServiceInvHeaderFields(ServiceInvoiceHeader: Record "Service Invoice Header"; PaymentMethod: Record "Payment Method")
    begin
        if ErrorMessage.LogIfEmpty(
             ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Warning) = 0
        then
            ErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);

        ErrorMessage.LogIfEmpty(
          ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Payment Terms Code"), ErrorMessage."Message Type"::Warning);
    end;

    local procedure CheckServiceCrMemoHeaderFields(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PaymentMethod: Record "Payment Method")
    begin
        if ErrorMessage.LogIfEmpty(
             ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Warning) = 0
        then
            ErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);

        ErrorMessage.LogIfEmpty(
          ServiceCrMemoHeader, ServiceCrMemoHeader.FieldNo("Payment Terms Code"), ErrorMessage."Message Type"::Warning);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fattura Doc. Helper", 'OnUpdateFatturaHeaderWithDiscountInformation', '', false, false)]
    local procedure OnUpdateFatturaHeaderWithDiscountInformation(var TempFatturaHeader: Record "Fattura Header" temporary; LineRecRef: RecordRef; LineInvDiscAmountFieldNo: Integer)
    begin
        TempFatturaHeader."Total Inv. Discount" := CalcServInvDiscAmount(LineRecRef, LineInvDiscAmountFieldNo, TempFatturaHeader);
    end;

    local procedure CalcServInvDiscAmount(var LineRecRef: RecordRef; LineInvDiscAmountFieldNo: Integer; TempFatturaHeader: Record "Fattura Header" temporary) ServInvDiscount: Decimal
    var
        InvDiscountAmount: Decimal;
    begin
        if TempFatturaHeader."Entry Type" <> TempFatturaHeader."Entry Type"::Service then
            exit;

        if not LineRecRef.FindSet() then
            exit;

        repeat
            if Evaluate(InvDiscountAmount, Format(LineRecRef.Field(LineInvDiscAmountFieldNo).Value)) then;
            ServInvDiscount += InvDiscountAmount;
        until LineRecRef.Next() = 0;
        exit(ServInvDiscount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fattura Doc. Helper", 'OnFindSourceDocumentInvoice', '', false, false)]
    local procedure OnFindSourceDocumentInvoice(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; DocRecRef: RecordRef; var Found: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        if ServiceInvoiceHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
            DocRecRef.GetTable(ServiceInvoiceHeader);
            Found := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fattura Doc. Helper", 'OnFindSourceDocumentCrMemo', '', false, false)]
    local procedure OnFindSourceDocumentCrMemo(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; DocRecRef: RecordRef; var Found: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceCrMemoHeader.Get(AppliedCustLedgerEntry."Document No.") then begin
            DocRecRef.GetTable(ServiceCrMemoHeader);
            Found := true;
        end;
    end;

    procedure UpdateFatturaDocTypeInServDoc(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        COmpanyInformation: Record "Company Information";
    begin
        if ServiceHeader."Bill-to Customer No." <> '' then begin
            Customer.Get(ServiceHeader."Bill-to Customer No.");
            CompanyInformation.Get();
            if Customer."VAT Registration No." = CompanyInformation."VAT Registration No." then begin
                ServiceHeader."Fattura Document Type" := FatturaDocHelper.GetSelfBillingCode();
                exit;
            end;
        end;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice:
                ServiceHeader."Fattura Document Type" := FatturaDocHelper.GetInvoiceCode();
            ServiceHeader."Document Type"::"Credit Memo":
                ServiceHeader."Fattura Document Type" := FatturaDocHelper.GetCrMemoCode();
        end;
    end;

    procedure AssignFatturaDocTypeFromVATPostingSetupToServiceHeader(var ServiceHeader: Record "Service Header"; Confirmation: Boolean)
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Stop: Boolean;
        FatturaDocType: Code[20];
        FatturaDocTypeIsDifferent: Boolean;
        FirstLineHandled: Boolean;
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                if (VATPostingSetup."VAT Bus. Posting Group" <> ServiceLine."VAT Bus. Posting Group") or
                   (VATPostingSetup."VAT Prod. Posting Group" <> ServiceLine."VAT Prod. Posting Group")
                then
                    if not VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
                        VATPostingSetup.Init();
                if not FirstLineHandled then begin
                    FatturaDocType := VATPostingSetup."Fattura Document Type";
                    FirstLineHandled := true;
                end else
                    if FatturaDocType <> VATPostingSetup."Fattura Document Type" then begin
                        FatturaDocTypeIsDifferent := true;
                        Stop := true;
                    end;
                if Stop then
                    FatturaDocType := '';
                Stop := Stop or (ServiceLine.Next() = 0);
            until Stop;
        if FatturaDocTypeIsDifferent then begin
            if GuiAllowed() and Confirmation then
                if not Confirm(StrSubstNo(FatturaDocTypeDiffQst, ServiceHeader."Fattura Document Type"), false) then
                    Error('');
            exit;
        end;
        if FatturaDocType <> '' then begin
            ServiceHeader.Validate("Fattura Document Type", FatturaDocType);
            ServiceHeader.Modify(true);
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fattura Doc. Helper", 'OnCollectShipmentInfo', '', false, false)]
    local procedure OnCollectShipmentInfo(ShptNo: Code[20]; var ShipmentDate: Date; var FatturaProjectCode: Code[15]; var FatturaTenderCode: Code[15]; var CustomerPurchOrderNo: Text[35]; var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        case TempFatturaHeader."Entry Type" of
            TempFatturaHeader."Entry Type"::Service:
                begin
                    ServiceShipmentHeader.Get(ShptNo);
                    ShipmentDate := ServiceShipmentHeader."Posting Date";
                    FatturaProjectCode := ServiceShipmentHeader."Fattura Project Code";
                    FatturaTenderCode := ServiceShipmentHeader."Fattura Tender Code";
                    CustomerPurchOrderNo := ServiceShipmentHeader."Customer Purchase Order No.";
                end;

        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Fattura Doc. Helper", 'OnCollectShipmentInfoFromLines', '', false, false)]
    local procedure OnCollectShipmentInfoFromLines(var TempFatturaHeader: Record "Fattura Header" temporary; var TempShptFatturaLine: Record "Fattura Line" temporary; var TempLineNumberBuffer: Record "Line Number Buffer" temporary; var FatturaProjectCode: Code[15]; var FatturaTenderCode: Code[15]; var CustomerPurchOrderNo: Text[35]; Type: Text[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        i: Integer;
    begin
        case TempFatturaHeader."Entry Type" of
            TempFatturaHeader."Entry Type"::Service:
                begin
                    i := 0;
                    ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Item);
                    ServiceShipmentLine.SetRange("Order No.", TempFatturaHeader."Order No.");
                    if ServiceShipmentLine.FindSet() then
                        repeat
                            i += 1;
                            TempLineNumberBuffer.Get(ServiceShipmentLine."Order Line No.");
                            FatturaDocHelper.InsertShipmentBuffer(
                                TempShptFatturaLine, Type, TempLineNumberBuffer."New Line Number", ServiceShipmentLine."Document No.",
                                ServiceShipmentLine."Posting Date", FatturaProjectCode, FatturaTenderCode, CustomerPurchOrderNo, false);
                        until ServiceShipmentLine.Next() = 0;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"VAT Register - Print", 'OnSetDetailsForCustomerInvoice', '', false, false)]
    local procedure OnSetDetailsForCustomerInvoice(var VATBookEntry: Record "VAT Book Entry"; var Name: Text[100])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        if ServiceInvoiceHeader.Get(VATBookEntry."Document No.") then
            Name := ServiceInvoiceHeader."Bill-to Name";
    end;

    [EventSubscriber(ObjectType::Report, Report::"VAT Register - Print", 'OnSetDetailsForCustomerCrMemo', '', false, false)]
    local procedure OnSetDetailsForCustomerCrMemo(var VATBookEntry: Record "VAT Book Entry"; var Name: Text[100])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceCrMemoHeader.Get(VATBookEntry."Document No.") then
            Name := ServiceCrMemoHeader."Bill-to Name";
    end;
}