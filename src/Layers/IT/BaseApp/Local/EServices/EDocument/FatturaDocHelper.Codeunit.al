// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Utilities;

codeunit 12184 "Fattura Doc. Helper"
{
    Permissions = TableData "VAT Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        ErrorMessage: Record "Error Message";
        IsInitialized: Boolean;
        CustomerNoFieldNo: Integer;
        PaymentMethodCodeFieldNo: Integer;
        PaymentTermsCodeFieldNo: Integer;
        CurrencyCodeFieldNo: Integer;
        CurrencyFactorFieldNo: Integer;
        InvoiceDiscountAmountFieldNo: Integer;
        QuantityFieldNo: Integer;
        DocNoFieldNo: Integer;
        VatPercFieldNo: Integer;
        LineNoFieldNo: Integer;
        LineTypeFieldNo: Integer;
        NoFieldNo: Integer;
        DescriptionFieldNo: Integer;
        UnitOfMeasureFieldNo: Integer;
        UnitPriceFieldNo: Integer;
        LineDiscountPercFieldNo: Integer;
        LineInvDiscAmountFieldNo: Integer;
        LineAmountFieldNo: Integer;
        LineAmountIncludingVATFieldNo: Integer;
        VATProdPostingGroupCodeFieldNo: Integer;
        VATBusPostingGroupCodeFieldNo: Integer;
        FatturaDocumentTypeFieldNo: Integer;
        FatturaProjectCodeFieldNo: Integer;
        FatturaTenderCodeFieldNo: Integer;
        CustomerPurchaseOrderFieldNo: Integer;
        ShipmentNoFieldNo: Integer;
        AttachedToLineNoFieldNo: Integer;
        OrderNoFieldNo: Integer;
        PrepaymentInvoiceFieldNo: Integer;
        FatturaStampFieldNo: Integer;
        FatturaStampAmountFieldNo: Integer;
        MissingLinesErr: Label 'The document must contain lines in order to be sent through FatturaPA.';
        TxtTok: Label 'TXT%1', Locked = true;
        ExemptionDataMsg: Label '%1 del %2.', Locked = true;
        VATExemptionPrefixTok: Label 'Dich.Intento n.', Locked = true;
        NonPublicCompanyLbl: Label 'FPR12', Locked = true;
        BasicVATTypeLbl: Label 'I', Locked = true;
        ReverseChargeVATDescrLbl: Label 'Reverse Charge VAT %1', Comment = '%1 = VAT percent';
        PricesIncludingVATFieldNo: Integer;
        InvoiceTxt: Label 'Invoice';
        InvoiceInAdvanceTxt: Label 'Advance invoice';
        FeeInAdvanceTxt: Label 'Advance fee';
        CreditMemoTxt: Label 'Credit Memo';
        DebitMemoTxt: Label 'Debit Memo';
        FeeTxt: Label 'Fee';
        SimplifiedInvoiceTxt: Label 'Simplified Invoice';
        SimplifiedCrMemoTxt: Label 'Simplified Credit Memo';
        SimplifiedDebitMemoTxt: Label 'Simplified Debit Memo';
        IntegrationRevChargeTxt: Label 'Integration of Internal Reverse Charge Invoice';
        PurchasesFromAbroadTxt: Label 'Purchases from abroad';
        IntracommunityGoodsTxt: Label 'Intra-community goods';
        Selfbillingart17Txt: Label 'Integration/self-billing for goods ex art.17 c.2 DPR 633/72';
        SelfbillingRegulationTxt: Label 'Self-billiing for regulation and integration of invoices (ex art.6 c.8 d.lgs. 471/97 o art.46 c.5 D.L. 331/93)';
        SelfbillingPlafondOverrunTxt: Label 'Self-billing for plafond overrun';
        GoodsExtractionTxt: Label 'Goods extraction from VAT deposit';
        GoodsExtractionVATPmtTxt: Label 'Goods extraction from VAT deposit with VAT payment';
        DeferredInvLettaTxt: Label 'Deferred invoice (ex art. 21, comma 4, lett. a)';
        DeferredInvLettbTxt: Label 'Deferred invoice (ex art. 21, comma 4, terzo periodo lett. b)';
        FixedAssetTransferTxt: Label 'Fixed assed transfer or internal  transfer  (ex art.36 DPR 633/72)';
        SelfConsumingInvoiceTxt: Label 'Invoice for self-consuming or free gift without VAT Compensation';
        FatturaDocTypeDiffQst: Label 'There are one or more different values of Fattura document type coming from the VAT posting setup of lines. As it''''s not possible to identify the value, %1 from the header will be used.\\Do you want to continue?', Comment = '%1 = the value of Fattura Document type from the header';

    [Scope('OnPrem')]
    procedure CollectDocumentInformation(var TempFatturaHeader: Record "Fattura Header" temporary; var TempFatturaLine: Record "Fattura Line" temporary; HeaderRecRef: RecordRef)
    var
        LineRecRef: RecordRef;
        PricesIncludingVAT: Boolean;
    begin
        CompanyInformation.Get();
        if not CollectDocHeaderInformation(TempFatturaHeader, LineRecRef, HeaderRecRef, PricesIncludingVAT) then
            exit;

        CollectDocLinesInformation(TempFatturaLine, LineRecRef, TempFatturaHeader, PricesIncludingVAT);
        CollectPaymentInformation(TempFatturaLine, TempFatturaHeader);

        OnAfterCollectDocumentInformation(TempFatturaHeader, TempFatturaLine, HeaderRecRef);
    end;

    [Scope('OnPrem')]
    procedure SetFatturaVendorNoInVATEntry(EntryNo: Integer; VendNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        if EntryNo = 0 then
            exit;

        VATEntry.Get(EntryNo);
        VATEntry."Fattura Vendor No." := VendNo;
        VATEntry.Modify();
    end;

    local procedure CollectDocHeaderInformation(var TempFatturaHeader: Record "Fattura Header" temporary; var LineRecRef: RecordRef; HeaderRecRef: RecordRef; var PricesIncludingVAT: Boolean): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
    begin
        Initialize();
        Customer.Get(Format(HeaderRecRef.Field(CustomerNoFieldNo).Value));

        TempFatturaHeader.Init();
        TempFatturaHeader."Customer No" := Customer."No.";
        TempFatturaHeader."Document No." := Format(HeaderRecRef.Field(DocNoFieldNo).Value);
        TempFatturaHeader."Payment Method Code" := HeaderRecRef.Field(PaymentMethodCodeFieldNo).Value();
        TempFatturaHeader."Payment Terms Code" := HeaderRecRef.Field(PaymentTermsCodeFieldNo).Value();
        if not InitFatturaHeaderWithCheck(TempFatturaHeader, LineRecRef, HeaderRecRef) then
            exit(false);

        if TempFatturaHeader."Entry Type" = TempFatturaHeader."Entry Type"::Sales then
            Evaluate(TempFatturaHeader.Prepayment, Format(HeaderRecRef.Field(PrepaymentInvoiceFieldNo).Value));
        TempFatturaHeader."Fattura Document Type" :=
            copystr(
                GetTipoDocumento(TempFatturaHeader, Customer, HeaderRecRef.Field(FatturaDocumentTypeFieldNo).Value), 1, Maxstrlen(TempFatturaHeader."Fattura Document Type"));
        if TempFatturaHeader."Document Type" = TempFatturaHeader."Document Type"::Invoice then begin
            TempFatturaHeader."Order No." := Format(HeaderRecRef.Field(OrderNoFieldNo).Value);
            TempFatturaHeader."Customer Purchase Order No." := HeaderRecRef.Field(CustomerPurchaseOrderFieldNo).Value();
        end;

        GeneralLedgerSetup.Get();
        TempFatturaHeader."Currency Code" := Format(HeaderRecRef.Field(CurrencyCodeFieldNo));
        TempFatturaHeader."Currency Factor" := HeaderRecRef.Field(CurrencyFactorFieldNo).Value();

        TempFatturaHeader."Fattura Stamp" := HeaderRecRef.Field(FatturaStampFieldNo).Value();
        TempFatturaHeader."Fattura Stamp Amount" := HeaderRecRef.Field(FatturaStampAmountFieldNo).Value();
        TempFatturaHeader."Fattura Project Code" := HeaderRecRef.Field(FatturaProjectCodeFieldNo).Value();
        TempFatturaHeader."Fattura Tender Code" := HeaderRecRef.Field(FatturaTenderCodeFieldNo).Value();
        TempFatturaHeader."Transmission Type" := GetTransmissionType(Customer);

        TempFatturaHeader."Progressive No." := GetNextProgressiveNo();
        UpdateFatturaHeaderWithDiscountInformation(TempFatturaHeader, LineRecRef, HeaderRecRef);
        UpdateFattureHeaderWithApplicationInformation(TempFatturaHeader);
        UpdateFatturaHeaderWithTaxRepresentativeInformation(TempFatturaHeader);
        TempFatturaHeader.Insert();
        PricesIncludingVAT := HeaderRecRef.Field(PricesIncludingVATFieldNo).Value();
        exit(true);
    end;

    local procedure CollectDocLinesInformation(var TempFatturaLine: Record "Fattura Line" temporary; var LineRecRef: RecordRef; TempFatturaHeader: Record "Fattura Header" temporary; PricesIncludingVAT: Boolean)
    var
        TempShptFatturaLine: Record "Fattura Line" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
        IsSplitPayment: Boolean;
        DocLineNo: Integer;
        VATEntryCount: Integer;
    begin
        CollectShipmentInfo(TempShptFatturaLine, LineRecRef, TempFatturaHeader);
        BuildOrderDataBuffer(TempFatturaLine, TempShptFatturaLine, TempFatturaHeader);
        BuildShipmentDataBuffer(TempFatturaLine, TempShptFatturaLine);
        LineRecRef.FindSet();
        repeat
            if not IsSplitPaymentLine(LineRecRef) then
                InsertFatturaLine(TempFatturaLine, DocLineNo, TempFatturaHeader, LineRecRef, PricesIncludingVAT);
        until LineRecRef.Next() = 0;

        CollectVATOnLines(TempVATEntry, TempVATPostingSetup, TempFatturaHeader);
        TempVATEntry.Reset();
        if TempVATEntry.FindSet() then begin
            LineRecRef.FindSet();
            IsSplitPayment := HasSplitPayment(LineRecRef);
            Clear(TempFatturaLine);
            TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::VAT;
            VATEntryCount := TempVATEntry.Count();
            repeat
                if not IsSplitVATEntry(TempVATEntry) then
                    InsertVATFatturaLine(
                      TempFatturaLine, TempFatturaHeader."Document Type" = TempFatturaHeader."Document Type"::Invoice,
                      TempVATEntry, TempFatturaHeader."Customer No", IsSplitPayment, VATEntryCount);
            until TempVATEntry.Next() = 0;
        end;
    end;

    local procedure CollectPaymentInformation(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if (TempFatturaHeader."Payment Method Code" = '') or
           (TempFatturaHeader."Payment Terms Code" = '')
        then
            exit;

        FindCustLedgEntry(CustLedgerEntry, TempFatturaHeader);
        Clear(TempFatturaLine);
        TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Payment;
        repeat
            TempFatturaLine."Line No." += 1;
            TempFatturaLine."Due Date" := CustLedgerEntry."Due Date";
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TempFatturaLine.Amount := CustLedgerEntry."Amount (LCY)";
            TempFatturaLine.Insert();
        until CustLedgerEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CollectSelfBillingDocInformation(var TempFatturaHeader: Record "Fattura Header" temporary; var TempFatturaLine: Record "Fattura Line" temporary; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CompanyInformation.Get();
        CheckCompanyInformationFields(ErrorMessage);
        CheckFatturaPANos(ErrorMessage);
        if HasErrors() then
            exit;

        Initialize();

        TempFatturaHeader.Init();
        TempFatturaHeader."Entry Type" := TempFatturaHeader."Entry Type"::Sales;
        TempFatturaHeader."Document Type" := TempVATEntry."Document Type"::Invoice.AsInteger();
        TempFatturaHeader."Posting Date" := TempVATEntry."Posting Date";
        TempFatturaHeader."Document No." := TempVATEntry."Document No.";
        TempFatturaHeader."Progressive No." := GetNextProgressiveNo();
        TempFatturaHeader."Transmission Type" := NonPublicCompanyLbl;
        TempFatturaHeader."Fattura Document Type" :=
          CopyStr(TempVATEntry."Fattura Document Type", 1, MaxStrLen(TempFatturaHeader."Fattura Document Type"));
        TempFatturaHeader."External Document No." := TempVATEntry."External Document No.";
        if TempFatturaHeader."Fattura Document Type" = '' then begin
            VATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group");
            if VATPostingSetup."Fattura Document Type" = '' then
                TempFatturaHeader."Fattura Document Type" := GetDefaultFatturaDocType()
            else
                TempFatturaHeader."Fattura Document Type" :=
                  CopyStr(VATPostingSetup."Fattura Document Type", 1, MaxStrLen(TempFatturaHeader."Fattura Document Type"));
        end;
        TempVATEntry.CalcSums(Amount, Base);
        TempFatturaHeader."Total Amount" := Abs(TempVATEntry.Amount) + Abs(TempVATEntry.Base);
        TempFatturaHeader."Self-Billing Document" := true;
        TempFatturaHeader."Fattura Vendor No." := TempVATEntry."Fattura Vendor No.";
        TempFatturaHeader.Insert();
        CollectSelfBillingDocLinesInformation(TempFatturaLine, TempVATEntry);
    end;

    local procedure CollectSelfBillingDocLinesInformation(var TempFatturaLine: Record "Fattura Line" temporary; var TempVATEntry: Record "VAT Entry" temporary)
    begin
        TempVATEntry.SetCurrentKey(
            "Document No.", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
            "VAT %", "Deductible %", "VAT Identifier", "Transaction No.", "Unrealized VAT Entry No.");
        TempVATEntry.FindSet();
        TempFatturaLine.Init();
        TempFatturaLine.Quantity := 1;
        repeat
            TempVATEntry.SetRange("VAT Bus. Posting Group", TempVATEntry."VAT Bus. Posting Group");
            TempVATEntry.SetRange("VAT Prod. Posting Group", TempVATEntry."VAT Prod. Posting Group");
            TempVATEntry.CalcSums(Base, Amount);

            TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Document;
            TempFatturaLine.Description := StrSubstNo(ReverseChargeVATDescrLbl, TempVATEntry."VAT %");
            TempFatturaLine."Line No." += 1;
            TempFatturaLine."Unit Price" := -TempVATEntry.Base;
            TempFatturaLine.Amount := TempFatturaLine."Unit Price";
            TempFatturaLine."VAT %" := TempVATEntry."VAT %";
            TempFatturaLine.Insert();

            TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::VAT;
            TempFatturaLine."VAT Base" := TempFatturaLine.Amount;
            TempFatturaLine."VAT Amount" := -TempVATEntry.Amount;
            TempFatturaLine.Description := BasicVATTypeLbl;
            TempFatturaLine.Insert();

            TempVATEntry.FindLast();
            TempVATEntry.SetRange("VAT Bus. Posting Group");
            TempVATEntry.SetRange("VAT Prod. Posting Group");
        until TempVATEntry.Next() = 0;
    end;

    local procedure Initialize()
    begin
        CompanyInformation.Get();
        if IsInitialized then
            exit;

        // field id of the Header tables
        CustomerNoFieldNo := 4;
        PaymentTermsCodeFieldNo := 23;
        PaymentMethodCodeFieldNo := 104;
        CurrencyCodeFieldNo := 32;
        CurrencyFactorFieldNo := 33;
        InvoiceDiscountAmountFieldNo := 1305;
        DocNoFieldNo := 3;
        FatturaDocumentTypeFieldNo := 12187;
        FatturaProjectCodeFieldNo := 12182;
        FatturaTenderCodeFieldNo := 12183;
        CustomerPurchaseOrderFieldNo := 12184;
        PricesIncludingVATFieldNo := 35;

        // field id of Line tables
        QuantityFieldNo := 15;
        LineAmountIncludingVATFieldNo := 30;
        VatPercFieldNo := 25;
        LineNoFieldNo := 4;
        LineTypeFieldNo := 5;
        NoFieldNo := 6;
        DescriptionFieldNo := 11;
        UnitOfMeasureFieldNo := 13;
        UnitPriceFieldNo := 22;
        LineAmountFieldNo := 103;
        LineDiscountPercFieldNo := 27;
        LineInvDiscAmountFieldNo := 69;
        VATBusPostingGroupCodeFieldNo := 89;
        VATProdPostingGroupCodeFieldNo := 90;
        ShipmentNoFieldNo := 63;
        AttachedToLineNoFieldNo := 80;
        OrderNoFieldNo := 44;
        PrepaymentInvoiceFieldNo := 136;
        FatturaStampFieldNo := 12185;
        FatturaStampAmountFieldNo := 12186;

        IsInitialized := true;
    end;

    [Scope('OnPrem')]
    procedure InitializeErrorLog(ContextRecordVariant: Variant)
    begin
        ErrorMessage.SetContext(ContextRecordVariant);
        ErrorMessage.ClearLog();
    end;

    [Scope('OnPrem')]
    procedure HasErrors(): Boolean
    begin
        exit(ErrorMessage.HasErrors(false));
    end;

    local procedure InitFatturaHeaderWithCheck(var TempFatturaHeader: Record "Fattura Header" temporary; var LineRecRef: RecordRef; HeaderRecRef: RecordRef): Boolean
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        FieldRef: FieldRef;
    begin
        CheckMandatoryFields(HeaderRecRef, ErrorMessage);
        if PaymentMethod.Get(TempFatturaHeader."Payment Method Code") and
           PaymentTerms.Get(TempFatturaHeader."Payment Terms Code")
        then begin
            TempFatturaHeader."Fattura PA Payment Method" := PaymentMethod."Fattura PA Payment Method";
            TempFatturaHeader."Fattura Payment Terms Code" := PaymentTerms."Fattura Payment Terms Code";
        end;
        case HeaderRecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    HeaderRecRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.CalcFields("Amount Including VAT", "Invoice Discount Amount");
                    CheckSalesInvHeaderFields(SalesInvoiceHeader, PaymentMethod);
                    TempFatturaHeader."Entry Type" := TempFatturaHeader."Entry Type"::Sales;
                    TempFatturaHeader."Document Type" := CustLedgerEntry."Document Type"::Invoice.AsInteger();
                    TempFatturaHeader."Posting Date" := SalesInvoiceHeader."Posting Date";
                    TempFatturaHeader."Document No." := SalesInvoiceHeader."No.";
                    LineRecRef.Open(DATABASE::"Sales Invoice Line");
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    HeaderRecRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.CalcFields("Amount Including VAT", "Invoice Discount Amount");
                    CheckSalesCrMemoHeaderFields(SalesCrMemoHeader, PaymentMethod);
                    TempFatturaHeader."Entry Type" := TempFatturaHeader."Entry Type"::Sales;
                    TempFatturaHeader."Document Type" := CustLedgerEntry."Document Type"::"Credit Memo".AsInteger();
                    TempFatturaHeader."Posting Date" := SalesCrMemoHeader."Posting Date";
                    TempFatturaHeader."Document No." := SalesCrMemoHeader."No.";
                    LineRecRef.Open(DATABASE::"Sales Cr.Memo Line");
                end;
            else
                OnInitFatturaHeaderWithCheckForTable(HeaderRecRef, LineRecRef, TempFatturaHeader, PaymentMethod);
        end;

        FieldRef := LineRecRef.Field(DocNoFieldNo);
        FieldRef.SetRange(TempFatturaHeader."Document No.");

        if not LineRecRef.FindSet() then
            ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, MissingLinesErr);

        exit(not ErrorMessage.HasErrors(false));
    end;

    procedure CheckMandatoryFields(HeaderRecRef: RecordRef; var ErrorMessage: Record "Error Message")
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        TaxRepresentativeVendor: Record Vendor;
        TransmissionIntermediaryVendor: Record Vendor;
        PaymentTermsAndPaymentMethodExists: Boolean;
    begin
        Initialize();
        Customer.Get(Format(HeaderRecRef.Field(CustomerNoFieldNo).Value()));
        PaymentTermsAndPaymentMethodExists :=
          PaymentMethod.Get(Format(HeaderRecRef.Field(PaymentMethodCodeFieldNo).Value())) and
          PaymentTerms.Get(Format(HeaderRecRef.Field(PaymentTermsCodeFieldNo).Value()));

        CheckCompanyInformationFields(ErrorMessage);
        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("PA Code"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(Address), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo(City), ErrorMessage."Message Type"::Error);
        if Customer."Individual Person" then begin
            ErrorMessage.LogIfEmpty(
              Customer, Customer.FieldNo("Last Name"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(
              Customer, Customer.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(Customer, Customer.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error);
        end else
            ErrorMessage.LogIfEmpty(
              Customer, Customer.FieldNo(Name), ErrorMessage."Message Type"::Error);

        if TaxRepresentativeVendor.Get(CompanyInformation."Tax Representative No.") then begin
            ErrorMessage.LogIfEmpty(
              TaxRepresentativeVendor, TaxRepresentativeVendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(
              TaxRepresentativeVendor, TaxRepresentativeVendor.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error);
        end;

        if TransmissionIntermediaryVendor.Get(CompanyInformation."Transmission Intermediary No.") then begin
            ErrorMessage.LogIfEmpty(TransmissionIntermediaryVendor,
              TransmissionIntermediaryVendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(TransmissionIntermediaryVendor,
              TransmissionIntermediaryVendor.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error);
        end;

        if PaymentTermsAndPaymentMethodExists then begin
            ErrorMessage.LogIfEmpty(PaymentTerms,
              PaymentTerms.FieldNo("Fattura Payment Terms Code"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(PaymentMethod,
              PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);
        end;

        CheckFatturaPANos(ErrorMessage);
        OnAfterCheckMandatoryFields(HeaderRecRef, ErrorMessage);
    end;

    local procedure CheckCompanyInformationFields(var ErrorMessage: Record "Error Message")
    begin
        ErrorMessage.LogIfLengthExceeded(
          CompanyInformation, CompanyInformation.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Error, 16);
        ErrorMessage.LogIfEmpty(
          CompanyInformation, CompanyInformation.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(
          CompanyInformation, CompanyInformation.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(
          CompanyInformation, CompanyInformation.FieldNo("Company Type"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(Address), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("Post Code"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo(City), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("REA No."), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(
          CompanyInformation, CompanyInformation.FieldNo("Registry Office Province"), ErrorMessage."Message Type"::Error);
    end;

    local procedure CheckFatturaPANos(var ErrorMessage: Record "Error Message")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        FatturaPANoSeries: Record "No. Series";
        FatturaNoSeriesLine: Record "No. Series Line";
    begin
        SalesReceivablesSetup.Get();
        ErrorMessage.LogIfEmpty(
          SalesReceivablesSetup, SalesReceivablesSetup.FieldNo("Fattura PA Nos."), ErrorMessage."Message Type"::Error);
        if FatturaPANoSeries.Get(SalesReceivablesSetup."Fattura PA Nos.") then;
        FatturaNoSeriesLine.SetRange("Series Code", FatturaPANoSeries.Code);
        FatturaNoSeriesLine.SetRange(Open, true);
        if FatturaNoSeriesLine.FindFirst() then begin
            ErrorMessage.LogIfLengthExceeded(FatturaNoSeriesLine, FatturaNoSeriesLine.FieldNo("Starting No."),
              ErrorMessage."Message Type"::Error, 5);
            ErrorMessage.LogIfLengthExceeded(FatturaNoSeriesLine, FatturaNoSeriesLine.FieldNo("Ending No."),
              ErrorMessage."Message Type"::Error, 5);
        end;
    end;

    local procedure CheckSalesInvHeaderFields(SalesInvoiceHeader: Record "Sales Invoice Header"; PaymentMethod: Record "Payment Method")
    begin
        if ErrorMessage.LogIfEmpty(
             SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Warning) = 0
        then
            ErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);

        ErrorMessage.LogIfEmpty(
          SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Payment Terms Code"), ErrorMessage."Message Type"::Warning);
    end;

    local procedure CheckSalesCrMemoHeaderFields(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PaymentMethod: Record "Payment Method")
    begin
        if ErrorMessage.LogIfEmpty(
             SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Payment Method Code"), ErrorMessage."Message Type"::Warning) = 0
        then
            ErrorMessage.LogIfEmpty(
              PaymentMethod, PaymentMethod.FieldNo("Fattura PA Payment Method"), ErrorMessage."Message Type"::Error);

        ErrorMessage.LogIfEmpty(
          SalesCrMemoHeader, SalesCrMemoHeader.FieldNo("Payment Terms Code"), ErrorMessage."Message Type"::Warning);
    end;

    local procedure UpdateFatturaHeaderWithDiscountInformation(var TempFatturaHeader: Record "Fattura Header" temporary; var LineRecRef: RecordRef; HeaderRecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        TempFatturaHeader."Total Amount" := ExchangeToLCYAmount(TempFatturaHeader, GetTotalDocAmount(LineRecRef));
        case TempFatturaHeader."Entry Type" of
            TempFatturaHeader."Entry Type"::Sales:
                begin
                    FieldRef := HeaderRecRef.Field(InvoiceDiscountAmountFieldNo);
                    if FieldRef.Class = FieldClass::FlowField then
                        FieldRef.CalcField();
                    TempFatturaHeader."Total Inv. Discount" := FieldRef.Value();
                end;
            else
                OnUpdateFatturaHeaderWithDiscountInformation(TempFatturaHeader, LineRecRef, LineInvDiscAmountFieldNo);
        end;
        TempFatturaHeader."Total Inv. Discount" := ExchangeToLCYAmount(TempFatturaHeader, TempFatturaHeader."Total Inv. Discount");
    end;

    local procedure UpdateFattureHeaderWithApplicationInformation(var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgerEntry: Record "Cust. Ledger Entry";
        DocRecRef: RecordRef;
    begin
        FindCustLedgEntry(CustLedgerEntry, TempFatturaHeader);
        if not FindAppliedEntry(AppliedCustLedgerEntry, CustLedgerEntry) then
            exit;

        TempFatturaHeader."Applied Doc. No." := AppliedCustLedgerEntry."Document No.";
        TempFatturaHeader."Applied Posting Date" := AppliedCustLedgerEntry."Posting Date";

        if not FindSourceDocument(DocRecRef, AppliedCustLedgerEntry) then
            exit;

        TempFatturaHeader."Appl. Fattura Project Code" := DocRecRef.Field(FatturaProjectCodeFieldNo).Value();
        TempFatturaHeader."Appl. Fattura Tender Code" := DocRecRef.Field(FatturaTenderCodeFieldNo).Value();
    end;

    local procedure UpdateFatturaHeaderWithTaxRepresentativeInformation(var TempFatturaHeader: Record "Fattura Header" temporary)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", TempFatturaHeader."Document Type");
        VATEntry.SetRange("Document No.", TempFatturaHeader."Document No.");
        VATEntry.SetRange("Posting Date", TempFatturaHeader."Posting Date");
        if VATEntry.FindFirst() then
            if VATEntry."Tax Representative Type" <> 0 then begin
                TempFatturaHeader."Tax Representative Type" := VATEntry."Tax Representative Type";
                TempFatturaHeader."Tax Representative No." := VATEntry."Tax Representative No.";
            end;

        if (TempFatturaHeader."Tax Representative Type" = 0) and (CompanyInformation."Tax Representative No." <> '') then begin
            TempFatturaHeader."Tax Representative Type" := VATEntry."Tax Representative Type"::Vendor;
            TempFatturaHeader."Tax Representative No." := CompanyInformation."Tax Representative No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure BuildSelfBillingDocPageSource(var TempVATEntry: Record "VAT Entry" temporary; DateFilter: Text[30])
    var
        FatturaSetup: Record "Fattura Setup";
        VATEntry: Record "VAT Entry";
    begin
        FatturaSetup.VerifyAndSetData();
        TempVATEntry.Reset();
        TempVATEntry.DeleteAll();

        VATEntry.SetCurrentKey("Document No.", "Posting Date", "Unrealized VAT Entry No.");
        VATEntry.SetRange("VAT Bus. Posting Group", FatturaSetup."Self-Billing VAT Bus. Group");
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.SetFilter("Document Type", '%1|%2', VATEntry."Document Type"::Invoice, VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetFilter("Posting Date", DateFilter);
        OnBuildSelfBillingDocPageSourceOnAfterSetVATEntryFilters(TempVATEntry, VATEntry);
        BuildVATEntryBufferWithLinks(TempVATEntry, VATEntry);
    end;

    [Scope('OnPrem')]
    procedure BuildVATEntryBufferWithLinks(var TempVATEntry: Record "VAT Entry" temporary; var VATEntry: Record "VAT Entry")
    var
        FirstVATEntry: Record "VAT Entry";
        LastDocNo: Code[20];
        LastPostingDate: Date;
        LastEntryNo: Integer;
    begin
        if not VATEntry.FindSet() then
            exit;

        FirstVATEntry := VATEntry;
        repeat
            TempVATEntry := VATEntry;
            if (LastDocNo = VATEntry."Document No.") and (LastPostingDate = VATEntry."Posting Date") then
                TempVATEntry."Related Entry No." := LastEntryNo
            else begin
                TempVATEntry."Related Entry No." := 0;
                LastEntryNo := VATEntry."Entry No.";
            end;
            LastDocNo := VATEntry."Document No.";
            LastPostingDate := VATEntry."Posting Date";
            TempVATEntry.Insert();
        until VATEntry.Next() = 0;
        TempVATEntry := FirstVATEntry;
        TempVATEntry.Find();
    end;

    [Scope('OnPrem')]
    procedure GetFileName(ProgressiveNo: Code[20]): Text[40]
    var
        ZeroNo: Code[10];
        BaseString: Text;
    begin
        // - country code + the transmitter's unique identity code + unique progressive number of the file
        CompanyInformation.Get();
        BaseString := CopyStr(DelChr(ProgressiveNo, '=', ',?;.:/-_ '), 1, 10);
        ZeroNo := PadStr('', 10 - StrLen(BaseString), '0');
        exit(CompanyInformation."Country/Region Code" +
          CompanyInformation."Fiscal Code" + '_' + ZeroNo + BaseString);
    end;

    local procedure GetTransmissionType(Customer: Record Customer): Text[5]
    begin
        if Customer.IsPublicCompany() then
            exit('FPA12');
        exit(NonPublicCompanyLbl);
    end;

    local procedure GetTipoDocumento(TempFatturaHeader: Record "Fattura Header" temporary; Customer: Record Customer; FatturaDocType: Variant): Text
    begin
        if Format(FatturaDocType) <> '' then
            exit(Format(FatturaDocType));

        if Customer."VAT Registration No." = CompanyInformation."VAT Registration No." then
            exit(GetSelfBillingCode());

        case TempFatturaHeader."Document Type" of
            TempFatturaHeader."Document Type"::Invoice:
                exit(GetInvoiceCode());
            TempFatturaHeader."Document Type"::"Credit Memo":
                exit(GetCrMemoCode());
            else
                exit(GetPrepaymentCode());
        end;
    end;

    local procedure GetTotalDocAmount(var LineRecRef: RecordRef) TotalAmount: Decimal
    var
        AmountInclVAT: Decimal;
    begin
        repeat
            if not IsSplitPaymentLine(LineRecRef) then
                if Evaluate(AmountInclVAT, Format(LineRecRef.Field(LineAmountIncludingVATFieldNo).Value)) then
                    TotalAmount += AmountInclVAT;
        until LineRecRef.Next() = 0;
        exit(TotalAmount);
    end;

    local procedure GetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; LineRecRef: RecordRef): Boolean
    begin
        exit(VATPostingSetup.Get(Format(LineRecRef.Field(VATBusPostingGroupCodeFieldNo).Value),
            Format(LineRecRef.Field(VATProdPostingGroupCodeFieldNo).Value)));
    end;

    local procedure GetVATType(VATEntry: Record "VAT Entry"; IsSplitPaymentDoc: Boolean): Code[1]
    begin
        if IsSplitPaymentDoc then
            exit('S');
        if VATEntry."Unrealized Amount" <> 0 then
            exit('D');
        exit(BasicVATTypeLbl);
    end;

    local procedure GetVATExemptionDescription(CustomerNo: Code[20]; DocumentDate: Date): Text[50]
    var
        VATExemption: Record "VAT Exemption";
    begin
        if VATExemption.FindCustVATExemptionOnDate(CustomerNo, DocumentDate, DocumentDate) then
            exit(
              StrSubstNo(ExemptionDataMsg, VATExemption.GetVATExemptNo(),
                Format(VATExemption."VAT Exempt. Date", 0, '<Day,2>/<Month,2>/<Year4>')));
    end;

    local procedure GetNextProgressiveNo(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        FatturaPANoSeries: Record "No. Series";
        NoSeries: Codeunit "No. Series";
    begin
        SalesReceivablesSetup.Get();
        if FatturaPANoSeries.Get(SalesReceivablesSetup."Fattura PA Nos.") then
            exit(NoSeries.GetNextNo(FatturaPANoSeries.Code, Today()));
    end;

    [Scope('OnPrem')]
    procedure GetDefaultFatturaDocType(): Text[4]
    begin
        exit('TD01');
    end;

    local procedure FindCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; TempFatturaHeader: Record "Fattura Header" temporary)
    begin
        CustLedgerEntry.SetRange("Document Type", TempFatturaHeader."Document Type");
        CustLedgerEntry.SetRange("Document No.", TempFatturaHeader."Document No.");
        CustLedgerEntry.SetRange("Posting Date", TempFatturaHeader."Posting Date");
        CustLedgerEntry.FindSet();
    end;

    local procedure FindAppliedEntry(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; OriginalCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        InvDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AppliedDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AppliedDocType: Enum "Gen. Journal Document Type";
    begin
        case OriginalCustLedgerEntry."Document Type" of
            OriginalCustLedgerEntry."Document Type"::Invoice:
                AppliedDocType := "Gen. Journal Document Type"::"Credit Memo";
            OriginalCustLedgerEntry."Document Type"::"Credit Memo":
                AppliedDocType := "Gen. Journal Document Type"::Invoice;
            else
                exit(false);
        end;

        InvDtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", OriginalCustLedgerEntry."Entry No.");
        InvDtldCustLedgEntry.SetRange(Unapplied, false);
        if InvDtldCustLedgEntry.FindSet() then
            repeat
                if InvDtldCustLedgEntry."Cust. Ledger Entry No." =
                   InvDtldCustLedgEntry."Applied Cust. Ledger Entry No."
                then begin
                    AppliedDtldCustLedgEntry.SetRange(
                      "Applied Cust. Ledger Entry No.", InvDtldCustLedgEntry."Applied Cust. Ledger Entry No.");
                    AppliedDtldCustLedgEntry.SetRange("Entry Type", AppliedDtldCustLedgEntry."Entry Type"::Application);
                    AppliedDtldCustLedgEntry.SetRange(Unapplied, false);
                    if AppliedDtldCustLedgEntry.FindSet() then
                        repeat
                            if AppliedDtldCustLedgEntry."Cust. Ledger Entry No." <>
                               AppliedDtldCustLedgEntry."Applied Cust. Ledger Entry No."
                            then
                                if AppliedCustLedgerEntry.Get(AppliedDtldCustLedgEntry."Cust. Ledger Entry No.") and
                                   (AppliedCustLedgerEntry."Document Type" = AppliedDocType)
                                then
                                    exit(true);
                        until AppliedDtldCustLedgEntry.Next() = 0;
                end else
                    if AppliedCustLedgerEntry.Get(InvDtldCustLedgEntry."Applied Cust. Ledger Entry No.") and
                       (AppliedCustLedgerEntry."Document Type" = AppliedDocType)
                    then
                        exit(true);
            until InvDtldCustLedgEntry.Next() = 0;
        exit(false);
    end;

    local procedure FindSourceDocument(var DocRecRef: RecordRef; AppliedCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Found: Boolean;
    begin
        case AppliedCustLedgerEntry."Document Type" of
            AppliedCustLedgerEntry."Document Type"::Invoice:
                if SalesInvoiceHeader.Get(AppliedCustLedgerEntry."Document No.") then
                    DocRecRef.GetTable(SalesInvoiceHeader)
                else begin
                    Found := false;
                    OnFindSourceDocumentInvoice(AppliedCustLedgerEntry, DocRecRef, Found);
                    exit(Found);
                end;
            AppliedCustLedgerEntry."Document Type"::"Credit Memo":
                if SalesCrMemoHeader.Get(AppliedCustLedgerEntry."Document No.") then
                    DocRecRef.GetTable(SalesCrMemoHeader)
                else begin
                    Found := false;
                    OnFindSourceDocumentCrMemo(AppliedCustLedgerEntry, DocRecRef, Found);
                    exit(Found);
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CalcInvDiscAmountDividedByQty(RecRef: RecordRef; QuantityFieldNo: Integer; LineInvoiceDiscoutAmountFieldNo: Integer): Decimal
    var
        FieldRef: FieldRef;
        InvDiscAmount: Decimal;
        QtyValue: Decimal;
    begin
        FieldRef := RecRef.Field(LineInvoiceDiscoutAmountFieldNo);
        InvDiscAmount := FieldRef.Value();
        FieldRef := RecRef.Field(QuantityFieldNo);
        QtyValue := FieldRef.Value();
        if QtyValue = 0 then
            exit(0);
        exit(Round(InvDiscAmount / QtyValue));
    end;

    local procedure CalcForPricesIncludingVAT(Amount: Decimal; PricesIncludingVAT: Boolean; VATRate: Decimal; Precision: Decimal): Decimal
    begin
        if PricesIncludingVAT then
            exit(Round(Amount / (1 + VATRate / 100), Precision));
        exit(Amount);
    end;

    local procedure ExchangeToLCYAmount(TempFatturaHeader: Record "Fattura Header" temporary; Amount: Decimal): Decimal
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if TempFatturaHeader."Currency Code" = '' then
            exit(Amount);

        Currency.Get(TempFatturaHeader."Currency Code");
        Currency.InitRoundingPrecision();
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              TempFatturaHeader."Posting Date", TempFatturaHeader."Currency Code",
              Amount, TempFatturaHeader."Currency Factor"),
            Currency."Amount Rounding Precision"));
    end;

    local procedure CollectShipmentInfo(var TempShptFatturaLine: Record "Fattura Line" temporary; var LineRecRef: RecordRef; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        TempLineNumberBuffer: Record "Line Number Buffer" temporary;
        SalesLine: Record "Sales Line";
        ShptNo: Code[20];
        FatturaProjectCode: Code[15];
        FatturaTenderCode: Code[15];
        Type: Text[20];
        CustomerPurchOrderNo: Text[35];
        ShipmentDate: Date;
        i: Integer;
    begin
        if TempFatturaHeader."Document Type" <> TempFatturaHeader."Document Type"::Invoice then
            exit;

        if LineRecRef.FindSet() then
            repeat
                i += 1;
                FatturaProjectCode := '';
                FatturaTenderCode := '';
                CustomerPurchOrderNo := '';
                Type := CopyStr(Format(LineRecRef.Field(LineTypeFieldNo).Value), 1, MaxStrLen(Type));
                ShptNo := Format(LineRecRef.Field(ShipmentNoFieldNo).Value);
                if (Type = GetOptionCaptionValue(SalesLine.Type::Item.AsInteger())) and
                   (ShptNo <> '')
                then begin
                    case TempFatturaHeader."Entry Type" of
                        TempFatturaHeader."Entry Type"::Sales:
                            begin
                                SalesShipmentHeader.Get(ShptNo);
                                ShipmentDate := SalesShipmentHeader."Shipment Date";
                                FatturaProjectCode := SalesShipmentHeader."Fattura Project Code";
                                FatturaTenderCode := SalesShipmentHeader."Fattura Tender Code";
                                CustomerPurchOrderNo := SalesShipmentHeader."Customer Purchase Order No.";
                            end;
                        else
                            OnCollectShipmentInfo(
                                TempFatturaHeader, ShptNo, ShipmentDate, FatturaProjectCode, FatturaTenderCode, CustomerPurchOrderNo);
                    end;
                    InsertShipmentBuffer(
                      TempShptFatturaLine, Type, i, ShptNo, ShipmentDate, FatturaProjectCode, FatturaTenderCode,
                      CustomerPurchOrderNo, IsSplitPaymentLine(LineRecRef));
                end;
                if Type = GetOptionCaptionValue(SalesLine.Type::"G/L Account".AsInteger()) then
                    InsertShipmentBuffer(
                      TempShptFatturaLine, Type, i, '', TempFatturaHeader."Posting Date", '', '', '', IsSplitPaymentLine(LineRecRef));
                if TempFatturaHeader."Order No." <> '' then begin
                    TempLineNumberBuffer.Init();
                    Evaluate(TempLineNumberBuffer."Old Line Number", Format(LineRecRef.Field(LineNoFieldNo).Value));
                    TempLineNumberBuffer."New Line Number" := i;
                    TempLineNumberBuffer.Insert();
                end;
            until LineRecRef.Next() = 0;
        if TempFatturaHeader."Order No." <> '' then
            case TempFatturaHeader."Entry Type" of
                TempFatturaHeader."Entry Type"::Sales:
                    begin
                        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
                        SalesShipmentLine.SetRange("Order No.", TempFatturaHeader."Order No.");
                        if SalesShipmentLine.FindSet() then
                            repeat
                                i += 1;
                                TempLineNumberBuffer.Get(SalesShipmentLine."Order Line No.");
                                InsertShipmentBuffer(
                                    TempShptFatturaLine, Type, TempLineNumberBuffer."New Line Number", SalesShipmentLine."Document No.",
                                    SalesShipmentLine."Shipment Date", FatturaProjectCode, FatturaTenderCode, CustomerPurchOrderNo, false);
                            until SalesShipmentLine.Next() = 0;
                    end;
                else
                    OnCollectShipmentInfoFromLines(TempFatturaHeader, TempShptFatturaLine, TempLineNumberBuffer, FatturaProjectCode, FatturaTenderCode, CustomerPurchOrderNo, Type);
            end;
    end;

    local procedure CollectVATOnLines(var TempVATEntry: Record "VAT Entry" temporary; var TempVATPostingSetup: Record "VAT Posting Setup" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", TempFatturaHeader."Document Type");
        VATEntry.SetRange("Document No.", TempFatturaHeader."Document No.");
        VATEntry.SetRange("Posting Date", TempFatturaHeader."Posting Date");
        if VATEntry.FindSet() then
            repeat
                CollectVATPostingSetup(TempVATPostingSetup, VATEntry);
                if not IsSplitVATSetup(TempVATPostingSetup) then begin
                    TempVATEntry.SetRange("VAT %", VATEntry."VAT %");
                    TempVATEntry.SetRange("VAT Transaction Nature", TempVATPostingSetup."VAT Transaction Nature");
                    if TempVATEntry.FindFirst() then begin
                        TempVATEntry.Base += VATEntry.Base + VATEntry."Unrealized Base";
                        TempVATEntry.Amount += VATEntry.Amount + VATEntry."Unrealized Amount";
                        TempVATEntry.Modify();
                    end else begin
                        TempVATEntry.Init();
                        TempVATEntry := VATEntry;
                        TempVATEntry.Base += TempVATEntry."Unrealized Base";
                        TempVATEntry.Amount += TempVATEntry."Unrealized Amount";
                        TempVATEntry.Insert();
                    end;
                end;
            until VATEntry.Next() = 0;
    end;

    local procedure CollectVATPostingSetup(var TempVATPostingSetup: Record "VAT Posting Setup" temporary; VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if TempVATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
            exit;

        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        TempVATPostingSetup := VATPostingSetup;
        TempVATPostingSetup.Insert();
    end;

    local procedure BuildOrderDataBuffer(var TempFatturaLine: Record "Fattura Line" temporary; var TempShptFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        MultipleOrders: Boolean;
        Finished: Boolean;
        LineNo: Integer;
    begin
        if TempFatturaHeader."Customer Purchase Order No." = '' then
            exit;

        TempShptFatturaLine.Reset();
        TempShptFatturaLine.SetRange("Split Line", false);
        if not TempShptFatturaLine.FindSet() then
            exit;

        MultipleOrders := HasMultipleOrders(TempShptFatturaLine);

        Clear(TempFatturaLine);
        repeat
            TempFatturaLine := TempShptFatturaLine;
            TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Order;
            TempFatturaLine."Document No." := TempShptFatturaLine."Document No.";
            TempFatturaLine."Related Line No." := 0;
            repeat
                LineNo += 1;
                TempFatturaLine."Line No." += LineNo;
                if MultipleOrders then
                    TempFatturaLine."Related Line No." := TempShptFatturaLine."Related Line No.";
                Finished := TempShptFatturaLine.Next() = 0;
                TempFatturaLine.Insert();
            until Finished or (TempFatturaLine."Document No." <> TempShptFatturaLine."Document No.");
        until Finished;
    end;

    local procedure BuildShipmentDataBuffer(var TempFatturaLine: Record "Fattura Line" temporary; var TempShptFatturaLine: Record "Fattura Line" temporary)
    var
        SalesLine: Record "Sales Line";
        MultipleOrders: Boolean;
    begin
        TempShptFatturaLine.Reset();
        TempShptFatturaLine.SetRange(Type, GetOptionCaptionValue(SalesLine.Type::Item.AsInteger()));
        if TempShptFatturaLine.FindSet() then begin
            MultipleOrders := TempShptFatturaLine.Count() > 1;
            Clear(TempFatturaLine);
            TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Shipment;
            repeat
                TempFatturaLine."Line No." += 1;
                TempFatturaLine."Document No." := TempShptFatturaLine."Document No.";
                TempFatturaLine."Posting Date" := TempShptFatturaLine."Posting Date";
                if MultipleOrders then
                    TempFatturaLine."Related Line No." := TempShptFatturaLine."Related Line No.";
                TempFatturaLine.Insert();
            until TempShptFatturaLine.Next() = 0;
        end;
    end;

    local procedure BuildAttachedToLinesExtTextBuffer(var TempFatturaLine: Record "Fattura Line" temporary; CurrRecRef: RecordRef)
    var
        OriginalFatturaLine: Record "Fattura Line";
        LineRecRef: RecordRef;
        TypeFieldRef: FieldRef;
        AttachedToLineNoFieldRef: FieldRef;
        LineNoFieldRef: FieldRef;
        SourceTypeFound: Boolean;
        SourceNoNoValue: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBuildAttachedToLinesExtTextBuffer(TempFatturaLine, CurrRecRef, IsHandled);
        if IsHandled then
            exit;

        OriginalFatturaLine := TempFatturaLine;
        TempFatturaLine.Init();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::"Extended Text");
        if TempFatturaLine.FindLast() then
            TempFatturaLine."Line No." := TempFatturaLine."Line No.";
        TempFatturaLine."Related Line No." := OriginalFatturaLine."Line No.";
        TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::"Extended Text";

        LineRecRef := CurrRecRef.Duplicate();

        TypeFieldRef := LineRecRef.Field(LineTypeFieldNo);
        TypeFieldRef.SetRange(0);

        AttachedToLineNoFieldRef := LineRecRef.Field(AttachedToLineNoFieldNo);
        AttachedToLineNoFieldRef.SetFilter(Format(LineRecRef.Field(LineNoFieldNo).Value));

        if LineRecRef.FindSet() then begin
            SourceNoNoValue := CurrRecRef.Field(NoFieldNo).Value();
            repeat
                InsertExtTextFatturaLine(TempFatturaLine, LineRecRef, StrSubstNo(TxtTok, SourceNoNoValue));
            until LineRecRef.Next() = 0;
        end;
        TypeFieldRef.SetRange();
        AttachedToLineNoFieldRef.SetRange(0);
        LineNoFieldRef := LineRecRef.Field(LineNoFieldNo);
        LineNoFieldRef.SetFilter('>%1', Format(CurrRecRef.Field(LineNoFieldNo).Value));
        if LineRecRef.FindSet() then
            repeat
                SourceTypeFound := Format(TypeFieldRef.Value) <> ' ';
                if not SourceTypeFound then begin
                    SourceNoNoValue := LineRecRef.Field(NoFieldNo).Value();
                    if SourceNoNoValue <> '' then
                        InsertExtTextFatturaLine(TempFatturaLine, LineRecRef, SourceNoNoValue);
                end;
            until (LineRecRef.Next() = 0) or SourceTypeFound;

        TypeFieldRef.SetRange();
        AttachedToLineNoFieldRef.SetRange();
        LineNoFieldRef.SetRange();

        TempFatturaLine := OriginalFatturaLine;
    end;

    local procedure BuildVATExemptionExtTextBuffer(var TempFatturaLine: Record "Fattura Line" temporary; TempFatturaHeader: Record "Fattura Header" temporary)
    var
        OriginalFatturaLine: Record "Fattura Line";
        VATExemption: Record "VAT Exemption";
    begin
        if not VATExemption.FindCustVATExemptionOnDate(
             TempFatturaHeader."Customer No", TempFatturaHeader."Posting Date", TempFatturaHeader."Posting Date")
        then
            exit;

        OriginalFatturaLine := TempFatturaLine;
        TempFatturaLine.Init();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::"Extended Text");
        if TempFatturaLine.FindLast() then
            TempFatturaLine."Line No." := TempFatturaLine."Line No.";
        TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::"Extended Text";
        TempFatturaLine."Line No." += 10000;
        TempFatturaLine."Ext. Text Source No" := 'INTENTO';
        TempFatturaLine.Description := VATExemption."VAT Exempt. No.";
        if VATExemption."Consecutive VAT Exempt. No." <> '' then
            TempFatturaLine.Description += '-' + VATExemption."Consecutive VAT Exempt. No.";
        TempFatturaLine."Posting Date" := VATExemption."VAT Exempt. Date";
        TempFatturaLine.Insert();

        TempFatturaLine := OriginalFatturaLine;
    end;

    procedure InsertShipmentBuffer(var TempShptFatturaLine: Record "Fattura Line" temporary; Type: Text[20]; LineNo: Integer; ShipmentNo: Code[20]; ShipmentDate: Date; FatturaProjectCode: Code[15]; FatturaTenderCode: Code[15]; CustomerPurchOrderNo: Text[35]; IsSplitLine: Boolean)
    begin
        if TempShptFatturaLine.FindLast() then;
        TempShptFatturaLine.Init();
        TempShptFatturaLine.Type := Type;
        TempShptFatturaLine."Document No." := ShipmentNo;
        TempShptFatturaLine."Line No." := TempShptFatturaLine."Line No." + 10000;
        TempShptFatturaLine."Related Line No." := LineNo;
        TempShptFatturaLine."Posting Date" := ShipmentDate;
        TempShptFatturaLine."Split Line" := IsSplitLine;
        TempShptFatturaLine."Fattura Project Code" := FatturaProjectCode;
        TempShptFatturaLine."Fattura Tender Code" := FatturaTenderCode;
        TempShptFatturaLine."Customer Purchase Order No." := CustomerPurchOrderNo;
        TempShptFatturaLine.Insert();
    end;

    local procedure InsertFatturaLine(var TempFatturaLine: Record "Fattura Line" temporary; var DocLineNo: Integer; TempFatturaHeader: Record "Fattura Header" temporary; LineRecRef: RecordRef; PricesIncludingVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        Quantity: Decimal;
        UnitPrice: Decimal;
        InvDiscAmountByQty: Decimal;
        LineDiscountPct: Decimal;
        Amount: Decimal;
    begin
        if Format(LineRecRef.Field(LineTypeFieldNo).Value) = ' ' then
            exit;

        DocLineNo += 1;
        Clear(TempFatturaLine);
        TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Document;
        TempFatturaLine."Line No." := DocLineNo;
        TempFatturaLine.Type := Format(LineRecRef.Field(LineTypeFieldNo).Value);
        TempFatturaLine."No." := LineRecRef.Field(NoFieldNo).Value();
        TempFatturaLine.Description := LineRecRef.Field(DescriptionFieldNo).Value();

        TempFatturaLine."VAT %" := LineRecRef.Field(VatPercFieldNo).Value();
        Quantity := LineRecRef.Field(QuantityFieldNo).Value();
        UnitPrice := LineRecRef.Field(UnitPriceFieldNo).Value();
        Amount := Quantity * UnitPrice;

        Currency.Initialize(TempFatturaHeader."Currency Code");
        UnitPrice :=
            ExchangeToLCYAmount(TempFatturaHeader,
                CalcForPricesIncludingVAT(
                UnitPrice, PricesIncludingVAT, TempFatturaLine."VAT %", Currency."Unit-Amount Rounding Precision"));
        Amount := ExchangeToLCYAmount(TempFatturaHeader, Amount);
        if Quantity < 0 then
            TempFatturaLine."Unit Price" := -UnitPrice
        else begin
            TempFatturaLine.Quantity := Quantity;
            TempFatturaLine."Unit of Measure" := LineRecRef.Field(UnitOfMeasureFieldNo).Value();
            TempFatturaLine."Unit Price" := UnitPrice;
        end;

        InvDiscAmountByQty :=
          ExchangeToLCYAmount(
            TempFatturaHeader, CalcInvDiscAmountDividedByQty(LineRecRef, QuantityFieldNo, LineInvDiscAmountFieldNo));
        LineDiscountPct := LineRecRef.Field(LineDiscountPercFieldNo).Value();
        if (InvDiscAmountByQty <> 0) or (LineDiscountPct <> 0) then begin
            TempFatturaLine."Discount Percent" := LineDiscountPct;
            TempFatturaLine."Discount Amount" := InvDiscAmountByQty;
        end;

        TempFatturaLine.Amount := LineRecRef.Field(LineAmountFieldNo).Value();
        if (TempFatturaLine.Amount <> 0) and (InvDiscAmountByQty = 0) and (LineDiscountPct = 0) and (TempFatturaLine."Discount Amount" = 0) then
            TempFatturaLine.Amount := Round(Amount) - TempFatturaLine."Discount Amount"
        else
            TempFatturaLine.Amount :=
              ExchangeToLCYAmount(
                TempFatturaHeader, CalcForPricesIncludingVAT(
                TempFatturaLine.Amount, PricesIncludingVAT, TempFatturaLine."VAT %", Currency."Amount Rounding Precision")) -
              TempFatturaLine."Discount Amount";

        if TempFatturaLine."VAT %" = 0 then begin
            GetVATPostingSetup(VATPostingSetup, LineRecRef);
            TempFatturaLine."VAT Transaction Nature" := VATPostingSetup."VAT Transaction Nature";
        end;
        TempFatturaLine.Insert();

        if TempFatturaLine.Type <> '' then
            BuildAttachedToLinesExtTextBuffer(TempFatturaLine, LineRecRef);
        BuildVATExemptionExtTextBuffer(TempFatturaLine, TempFatturaHeader);
    end;

    local procedure InsertExtTextFatturaLine(var TempFatturaLine: Record "Fattura Line" temporary; LineRecRef: RecordRef; NoValue: Text)
    var
        ExtendedTextValue: Text;
    begin
        ExtendedTextValue := LineRecRef.Field(DescriptionFieldNo).Value();
        if ExtendedTextValue <> '' then begin
            TempFatturaLine."Line No." += 1;
            TempFatturaLine."Ext. Text Source No" := CopyStr(NoValue, 1, 10);
            TempFatturaLine.Description := CopyStr(ExtendedTextValue, 1, MaxStrLen(TempFatturaLine.Description));
            TempFatturaLine.Insert();
        end;
    end;

    local procedure InsertVATFatturaLine(var TempFatturaLine: Record "Fattura Line" temporary; IsInvoice: Boolean; VATEntry: Record "VAT Entry"; CustNo: Code[20]; IsSplitPayment: Boolean; VATEntryCount: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATIdentifier: Record "VAT Identifier";
        VATNatureDescription: Text[100];
        VATExemptionDescription: Text[50];
        VATBase: Decimal;
    begin
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::Document);
        if (VATEntryCount = 1) and (TempFatturaLine.Count() = 1) then begin
            TempFatturaLine.CalcSums(Amount);
            if VATEntry.Base > 0 then
                VATBase := TempFatturaLine.Amount
            else
                VATBase := -TempFatturaLine.Amount;
        end else
            VATBase := VATEntry.Base;
        TempFatturaLine.SetRange("Line Type");

        TempFatturaLine.Init();
        TempFatturaLine."Line No." += 1;
        TempFatturaLine."VAT %" := VATEntry."VAT %";
        if TempFatturaLine."VAT %" = 0 then begin
            VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
            TempFatturaLine."VAT Transaction Nature" := VATPostingSetup."VAT Transaction Nature";
            if VATIdentifier.Get(VATEntry."VAT Identifier") then
                VATNatureDescription := VATIdentifier.Description;
            VATExemptionDescription := GetVATExemptionDescription(CustNo, VATEntry."Document Date");
            if VATExemptionDescription <> '' then
                VATNatureDescription += StrSubstNo(' %1 %2', VATExemptionPrefixTok, VATExemptionDescription);
            TempFatturaLine."VAT Nature Description" := VATNatureDescription;
        end;
        TempFatturaLine."VAT Base" := VATBase;
        TempFatturaLine."VAT Amount" := VATEntry.Amount;
        if IsInvoice then begin
            TempFatturaLine."VAT Base" := -TempFatturaLine."VAT Base";
            TempFatturaLine."VAT Amount" := -TempFatturaLine."VAT Amount";
        end;
        if TempFatturaLine."VAT %" <> 0 then
            TempFatturaLine.Description := GetVATType(VATEntry, IsSplitPayment);
        TempFatturaLine.Insert();
    end;

    local procedure HasMultipleOrders(var TempShptFatturaLine: Record "Fattura Line" temporary) HasMultipleOrders: Boolean
    begin
        TempShptFatturaLine.SetFilter("Document No.", '<>%1', TempShptFatturaLine."Document No.");
        HasMultipleOrders := not TempShptFatturaLine.IsEmpty();
        TempShptFatturaLine.SetRange("Document No.");
        exit(HasMultipleOrders);
    end;

    local procedure HasSplitPayment(var LineRecRef: RecordRef): Boolean
    begin
        repeat
            if IsSplitPaymentLine(LineRecRef) then begin
                LineRecRef.FindFirst();
                exit(true);
            end;
        until LineRecRef.Next() = 0;
        LineRecRef.FindFirst();
        exit(false)
    end;

    local procedure IsSplitPaymentLine(LineRecRef: RecordRef): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ReversedVATPostingSetup: Record "VAT Posting Setup";
    begin
        if GetVATPostingSetup(VATPostingSetup, LineRecRef) then
            exit((VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT") and
              ReversedVATPostingSetup.Get(
                VATPostingSetup."Reversed VAT Bus. Post. Group",
                VATPostingSetup."Reversed VAT Prod. Post. Group"));
        exit(false);
    end;

    local procedure IsSplitVATEntry(VATEntry: Record "VAT Entry"): Boolean
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
            exit(IsSplitVATSetup(VATPostingSetup));
        exit(false);
    end;

    local procedure IsSplitVATSetup(VATPostingSetup: Record "VAT Posting Setup"): Boolean
    var
        ReversedVATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Full VAT" then
            exit(false);

        exit(
          ReversedVATPostingSetup.Get(
            VATPostingSetup."Reversed VAT Bus. Post. Group",
            VATPostingSetup."Reversed VAT Prod. Post. Group"));
    end;

    procedure InsertFatturaDocumentTypeList()
    var
        FatturaDocumentType: Record "Fattura Document Type";
    begin
        if not FatturaDocumentType.IsEmpty() then
            exit;

        AddFatturaDocumentType('TD01', InvoiceTxt, true, false, false, false);
        AddFatturaDocumentType('TD02', InvoiceInAdvanceTxt, false, false, false, true);
        AddFatturaDocumentType('TD03', FeeInAdvanceTxt, false, false, false, false);
        AddFatturaDocumentType('TD04', CreditMemoTxt, false, true, false, false);
        AddFatturaDocumentType('TD05', DebitMemoTxt, false, false, false, false);
        AddFatturaDocumentType('TD06', FeeTxt, false, false, false, false);
        AddFatturaDocumentType('TD07', SimplifiedInvoiceTxt, false, false, false, false);
        AddFatturaDocumentType('TD08', SimplifiedCrMemoTxt, false, false, false, false);
        AddFatturaDocumentType('TD09', SimplifiedDebitMemoTxt, false, false, false, false);
        AddFatturaDocumentType('TD16', IntegrationRevChargeTxt, false, false, false, false);
        AddFatturaDocumentType('TD17', PurchasesFromAbroadTxt, false, false, false, false);
        AddFatturaDocumentType('TD18', IntracommunityGoodsTxt, false, false, false, false);
        AddFatturaDocumentType(
          'TD19', Selfbillingart17Txt, false, false, false, false);
        AddFatturaDocumentType(
          'TD20', SelfbillingRegulationTxt,
          false, false, true, false);
        AddFatturaDocumentType('TD21', SelfbillingPlafondOverrunTxt, false, false, false, false);
        AddFatturaDocumentType('TD22', GoodsExtractionTxt, false, false, false, false);
        AddFatturaDocumentType('TD23', GoodsExtractionVATPmtTxt, false, false, false, false);
        AddFatturaDocumentType('TD24', DeferredInvLettaTxt, false, false, false, false);
        AddFatturaDocumentType('TD25', DeferredInvLettbTxt, false, false, false, false);
        AddFatturaDocumentType('TD26', FixedAssetTransferTxt, false, false, false, false);
        AddFatturaDocumentType('TD27', SelfConsumingInvoiceTxt, false, false, false, false);
    end;

    local procedure AddFatturaDocumentType("Code": Code[20]; Description: Text[250]; Invoice: Boolean; CreditMemo: Boolean; SelfBilling: Boolean; Prepayment: Boolean)
    var
        FatturaDocumentType: Record "Fattura Document Type";
    begin
        FatturaDocumentType.Init();
        FatturaDocumentType.Validate("No.", Code);
        FatturaDocumentType.Validate(Description, Description);
        FatturaDocumentType.Validate(Invoice, Invoice);
        FatturaDocumentType.Validate("Credit Memo", CreditMemo);
        FatturaDocumentType.Validate("Self-Billing", SelfBilling);
        FatturaDocumentType.Validate(Prepayment, Prepayment);
        FatturaDocumentType.Insert(true);
    end;

    procedure UpdateFatturaDocTypeInSalesDoc(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        if SalesHeader."Bill-to Customer No." <> '' then begin
            Customer.Get(SalesHeader."Bill-to Customer No.");
            CompanyInformation.Get();
            if Customer."VAT Registration No." = CompanyInformation."VAT Registration No." then begin
                SalesHeader."Fattura Document Type" := GetSelfBillingCode();
                exit;
            end;
        end;

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice:
                SalesHeader."Fattura Document Type" := GetInvoiceCode();
            SalesHeader."Document Type"::"Credit Memo":
                SalesHeader."Fattura Document Type" := GetCrMemoCode();
        end;
    end;


    procedure UpdateFatturaDocTypeInVATEntry(EntryNo: Integer; FatturaDocType: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        if EntryNo = 0 then
            exit;
        if not VATEntry.Get(EntryNo) then
            exit;
        VATEntry.Validate("Fattura Document Type", FatturaDocType);
        VATEntry.Modify(true);
    end;

    procedure GetSelfBillingCode(): Code[20]
    var
        FatturaDocumentType: Record "Fattura Document Type";
    begin
        InsertFatturaDocumentTypeList();
        FatturaDocumentType.SetRange("Self-Billing", true);
        if FatturaDocumentType.FindFirst() then
            exit(FatturaDocumentType."No.");
    end;

    procedure GetPrepaymentCode(): Code[20]
    var
        FatturaDocumentType: Record "Fattura Document Type";
    begin
        InsertFatturaDocumentTypeList();
        FatturaDocumentType.SetRange(Prepayment, true);
        if FatturaDocumentType.FindFirst() then
            exit(FatturaDocumentType."No.");
    end;

    procedure GetInvoiceCode(): Code[20]
    var
        FatturaDocumentType: Record "Fattura Document Type";
    begin
        InsertFatturaDocumentTypeList();
        FatturaDocumentType.SetRange(Invoice, true);
        if FatturaDocumentType.FindFirst() then
            exit(FatturaDocumentType."No.");
    end;

    procedure GetCrMemoCode(): Code[20]
    var
        FatturaDocumentType: Record "Fattura Document Type";
    begin
        InsertFatturaDocumentTypeList();
        FatturaDocumentType.SetRange("Credit Memo", true);
        if FatturaDocumentType.FindFirst() then
            exit(FatturaDocumentType."No.");
    end;

    [Scope('OnPrem')]
    procedure GetOptionCaptionValue(IntValue: Integer): Text
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"Sales Line");
        FieldRef := RecRef.Field(SalesLine.FieldNo(Type));
        exit(SelectStr(IntValue + 1, FieldRef.OptionCaption()));
    end;

    [Scope('OnPrem')]
    procedure AssignFatturaDocTypeFromVATPostingSetupToSalesHeader(var SalesHeader: Record "Sales Header"; Confirmation: Boolean)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Stop: Boolean;
        FatturaDocType: Code[20];
        FatturaDocTypeIsDifferent: Boolean;
        FirstLineHandled: Boolean;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if (VATPostingSetup."VAT Bus. Posting Group" <> SalesLine."VAT Bus. Posting Group") or
                   (VATPostingSetup."VAT Prod. Posting Group" <> SalesLine."VAT Prod. Posting Group")
                then
                    if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
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
                Stop := Stop or (SalesLine.Next() = 0);
            until Stop;
        if FatturaDocTypeIsDifferent then begin
            if GuiAllowed() and Confirmation then
                if not Confirm(StrSubstNo(FatturaDocTypeDiffQst, SalesHeader."Fattura Document Type"), false) then
                    Error('');
            exit;
        end;
        if FatturaDocType <> '' then begin
            SalesHeader.Validate("Fattura Document Type", FatturaDocType);
            SalesHeader.Modify(true);
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Quote to Invoice", 'OnBeforeInsertSalesInvoiceHeader', '', false, false)]
    local procedure AssignFatturaDocTypeOnBeforeInsertSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Header"; QuoteSalesHeader: Record "Sales Header")
    begin
        SalesInvoiceHeader."Fattura Document Type" := QuoteSalesHeader."Fattura Document Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnAfterCreateCopyDocument', '', false, false)]
    local procedure AssignFatturaDocTypeForCorrectiveCreditMemo(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        CrMemoCode: Code[20];
    begin
        CrMemoCode := GetCrMemoCode();
        if CrMemoCode = '' then
            exit;
        SalesHeader.Validate("Fattura Document Type", CrMemoCode);
        SalesHeader.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post Prepayments", 'OnCodeOnAfterPostingDescriptionSet', '', false, false)]
    local procedure AssignFatturaDocTypeOnBeforeInsertPostedHeaders(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var PostingDescription: Text[100])
    begin
        case DocumentType of
            DocumentType::Invoice:
                SalesHeader."Fattura Document Type" := GetPrepaymentCode();
            DocumentType::"Credit Memo":
                SalesHeader."Fattura Document Type" := GetCrMemoCode();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnInsertCrMemoHeaderOnAfterSalesCrMemoHeaderTransferFields', '', false, false)]
    local procedure AssignFatturaDocTypeOnBeforeInsertCrMemoHeader(var SalesHeader: Record "Sales Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order" then
            SalesCrMemoHeader."Fattura Document Type" := GetCrMemoCode();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMandatoryFields(HeaderRecRef: RecordRef; var ErrorMessage: Record "Error Message")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCollectDocumentInformation(var TempFatturaHeader: Record "Fattura Header" temporary; var TempFatturaLine: Record "Fattura Line" temporary; HeaderRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBuildAttachedToLinesExtTextBuffer(var TempFatturaLine: Record "Fattura Line" temporary; CurrRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFatturaHeaderWithCheckForTable(var HeaderRecRef: RecordRef; var LineRecRef: RecordRef; var TempFatturaHeader: Record "Fattura Header" temporary; PaymentMethod: Record "Payment Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFatturaHeaderWithDiscountInformation(var TempFatturaHeader: Record "Fattura Header" temporary; LineRecRef: RecordRef; LineInvDiscAmountFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSourceDocumentInvoice(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; DocRecRef: RecordRef; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindSourceDocumentCrMemo(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; DocRecRef: RecordRef; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectShipmentInfo(var TempFatturaHeader: Record "Fattura Header" temporary; ShptNo: Code[20]; var ShipmentDate: Date; var FatturaProjectCode: Code[15]; var FatturaTenderCode: Code[15]; var CustomerPurchOrderNo: Text[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectShipmentInfoFromLines(var TempFatturaHeader: Record "Fattura Header" temporary; var TempShptFatturaLine: Record "fattura Line" temporary; var TempLineNumberBuffer: Record "Line Number Buffer" temporary; var FatturaProjectCode: Code[15]; var FatturaTenderCode: Code[15]; var CustomerPurchOrderNo: Text[35]; Type: Text[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildSelfBillingDocPageSourceOnAfterSetVATEntryFilters(var TempVATEntry: Record "VAT Entry" temporary; var VATEntry: Record "VAT Entry")
    begin
    end;
}
