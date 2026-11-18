// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 134495 "Library - ERM Installments"
{
    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";

    procedure Initialize()
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        GLSetup.Get();
        GLSetup."Amount Rounding Precision" := 0.01;
        GLSetup."Additional Reporting Currency" := '';
        GLSetup."Pmt. Disc. Excl. VAT" := false;
        GLSetup."Adjust for Payment Disc." := false;
        GLSetup.Modify();
        SalesSetup.Get();
        SalesSetup."Invoice Rounding" := false;
        SalesSetup."Calc. Inv. Discount" := false;
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"No Discounts";
        SalesSetup.Modify();
        PurchSetup.Get();
        PurchSetup."Invoice Rounding" := false;
        PurchSetup."Calc. Inv. Discount" := false;
        PurchSetup."Discount Posting" := PurchSetup."Discount Posting"::"No Discounts";
        PurchSetup.Modify();
    end;

    procedure CreateInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        VATPostingSetup: Record "VAT Posting Setup";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
        Rule: Record "Payment Term Installment";
    begin
        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 25);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Prices Including VAT", false);
        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        CreateTemporaryRules(TempPlanLine);
        TempPlanLine.FindSet();
        repeat
            Rule.Init();
            Rule."Payment Terms Code" := PaymentTerms.Code;
            Rule."Line No." := TempPlanLine."Line No.";
            Rule."Allocation Type" := TempPlanLine."Allocation Type";
            Rule."Payment %" := TempPlanLine."Payment %";
            Rule."Due Date Calculation" := TempPlanLine."Due Date Calculation";
            Rule."Discount Date Calculation" := TempPlanLine."Discount Date Calculation";
            Rule."Discount %" := TempPlanLine."Discount %";
            Rule.Insert(true);
        until TempPlanLine.Next() = 0;
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, Enum::"General Posting Type"::Sale), 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Modify(true);
    end;

    procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        VATPostingSetup: Record "VAT Posting Setup";
        Rule: Record "Payment Term Installment";
        TempPlanLine: Record "Purchase Installment Plan Line" temporary;
    begin
        Initialize();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 25);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Document Date", WorkDate());
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Prices Including VAT", false);
        if CurrencyCode <> '' then
            PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseTemporaryRules(TempPlanLine);
        TempPlanLine.FindSet();
        repeat
            Rule.Init();
            Rule."Payment Terms Code" := PaymentTerms.Code;
            Rule."Line No." := TempPlanLine."Line No.";
            Rule."Allocation Type" := TempPlanLine."Allocation Type";
            Rule."Payment %" := TempPlanLine."Payment %";
            Rule."Due Date Calculation" := TempPlanLine."Due Date Calculation";
            Rule."Discount Date Calculation" := TempPlanLine."Discount Date Calculation";
            Rule."Discount %" := TempPlanLine."Discount %";
            Rule.Insert(true);
        until TempPlanLine.Next() = 0;
        PurchaseHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, Enum::"General Posting Type"::Purchase), 1);
        PurchaseLine.Validate("Direct Unit Cost", 100);
        PurchaseLine.Validate("Allow Invoice Disc.", true);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseTemporaryRules(var TempPlanLine: Record "Purchase Installment Plan Line" temporary)
    var
        PlanID: Guid;
    begin
        PlanID := CreateGuid();
        CreatePurchaseRule(TempPlanLine, PlanID, 10000, 33.33333, '<30D>', 2, '<10D>');
        CreatePurchaseRule(TempPlanLine, PlanID, 20000, 33.33333, '<60D>', 1, '<20D>');
        TempPlanLine.Init();
        TempPlanLine."Plan ID" := PlanID;
        TempPlanLine."Line No." := 30000;
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::"Remaining Amount";
        Evaluate(TempPlanLine."Due Date Calculation", '<90D>');
        TempPlanLine.Insert();
    end;

    local procedure CreatePurchaseRule(var TempPlanLine: Record "Purchase Installment Plan Line" temporary; PlanID: Guid; LineNo: Integer; PaymentPercentage: Decimal; DueDateCalculation: Text; DiscountPercentage: Decimal; DiscountDateCalculation: Text)
    begin
        TempPlanLine.Init();
        TempPlanLine."Plan ID" := PlanID;
        TempPlanLine."Line No." := LineNo;
        TempPlanLine."Payment %" := PaymentPercentage;
        TempPlanLine."Discount %" := DiscountPercentage;
        Evaluate(TempPlanLine."Due Date Calculation", DueDateCalculation);
        Evaluate(TempPlanLine."Discount Date Calculation", DiscountDateCalculation);
        TempPlanLine.Insert();
    end;

    procedure CreateTemporaryRules(var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    var
        PlanID: Guid;
    begin
        PlanID := CreateGuid();
        TempPlanLine.Init();
        TempPlanLine."Plan ID" := PlanID;
        TempPlanLine."Line No." := 10000;
        TempPlanLine."Payment %" := 33.33333;
        TempPlanLine."Discount %" := 2;
        Evaluate(TempPlanLine."Due Date Calculation", '<30D>');
        Evaluate(TempPlanLine."Discount Date Calculation", '<10D>');
        TempPlanLine.Insert();
        TempPlanLine."Line No." := 20000;
        TempPlanLine."Discount %" := 1;
        Evaluate(TempPlanLine."Due Date Calculation", '<60D>');
        Evaluate(TempPlanLine."Discount Date Calculation", '<20D>');
        TempPlanLine.Insert();
        TempPlanLine."Line No." := 30000;
        TempPlanLine."Allocation Type" := TempPlanLine."Allocation Type"::"Remaining Amount";
        TempPlanLine."Payment %" := 0;
        TempPlanLine."Discount %" := 0;
        Evaluate(TempPlanLine."Due Date Calculation", '<90D>');
        Clear(TempPlanLine."Discount Date Calculation");
        TempPlanLine.Insert();
    end;

    procedure CreatePostedInvoice(var Invoice: Record "Sales Invoice Header"; CurrencyCode: Code[10]; WithDiscounts: Boolean)
    var
        Header: Record "Sales Header";
        Line: Record "Sales Line";
        PlanLine: Record "Sales Installment Plan Line";
    begin
        CreateInvoice(Header, Line, CurrencyCode);
        Header.Validate("External Document No.", LibraryUtility.GenerateGUID());
        Header.Modify(true);
        if not WithDiscounts then begin
            PlanLine.SetRange("Plan ID", Header."Installment Plan ID");
            PlanLine.FindSet(true);
            repeat
                PlanLine."Discount %" := 0;
                Clear(PlanLine."Discount Date Calculation");
                PlanLine.Modify(true);
            until PlanLine.Next() = 0;
        end;
        Invoice.Get(LibrarySales.PostSalesDocument(Header, true, true));
    end;

    procedure GetInstallment(var Entry: Record "Cust. Ledger Entry"; PlanID: Guid; Sequence: Integer)
    var
        PlanLine: Record "Sales Installment Plan Line";
    begin
        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.SetRange("Installment No.", Sequence);
        PlanLine.FindFirst();
        Entry.Get(PlanLine."Cust. Ledger Entry No.");
    end;

    procedure PayInstallment(PlanID: Guid; Sequence: Integer; Amount: Decimal)
    begin
        PayInstallment(PlanID, Sequence, Amount, WorkDate());
    end;

    procedure PayInstallment(PlanID: Guid; Sequence: Integer; Amount: Decimal; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApplicationID: Code[50];
    begin
        GetInstallment(CustLedgerEntry, PlanID, Sequence);
        ApplicationID := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Applies-to ID" := ApplicationID;
        CustLedgerEntry."Amount to Apply" := Amount;
        CustLedgerEntry.Modify(true);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        if CustLedgerEntry."Currency Code" <> '' then
            GenJournalLine.Validate("Currency Code", CustLedgerEntry."Currency Code");
        GenJournalLine.Validate("Applies-to ID", ApplicationID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    procedure CreditInstallment(Invoice: Record "Sales Invoice Header"; Sequence: Integer; Amount: Decimal; PostingDate: Date): Code[20]
    var
        Header: Record "Sales Header";
        Line: Record "Sales Line";
        Entry: Record "Cust. Ledger Entry";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        ApplicationID: Code[50];
    begin
        LibrarySales.CreateSalesHeader(Header, Header."Document Type"::"Credit Memo", Invoice."Bill-to Customer No.");
        CopyDocumentMgt.SetPropertiesForCorrectiveCreditMemo(true);
        CopyDocumentMgt.CopySalesDocForInvoiceCancelling(Invoice."No.", Header);
        Header.Validate("Posting Date", PostingDate);
        Header.Validate("Document Date", PostingDate);
        Header.Modify(true);
        Line.SetRange("Document Type", Header."Document Type");
        Line.SetRange("Document No.", Header."No.");
        Line.SetRange(Type, Line.Type::"G/L Account");
        Line.FindFirst();
        Line.Validate("Unit Price", Amount / (1 + Line."VAT %" / 100));
        Line.Modify(true);
        Header.Validate("Applies-to Doc. No.", '');
        GetInstallment(Entry, Invoice."Installment Plan ID", Sequence);
        ApplicationID := LibraryUtility.GenerateGUID();
        Entry."Applies-to ID" := ApplicationID;
        Entry."Amount to Apply" := Amount;
        Entry.Modify(true);
        Header.Validate("Applies-to ID", ApplicationID);
        Header.Modify(true);
        exit(LibrarySales.PostSalesDocument(Header, true, true));
    end;
}
