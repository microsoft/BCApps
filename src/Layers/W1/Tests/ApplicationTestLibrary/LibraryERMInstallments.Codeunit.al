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
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

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
    end;

    procedure CreateInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        VATPostingSetup: Record "VAT Posting Setup";
        TempPlanLine: Record "Installment Plan Line" temporary;
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

    procedure CreateTemporaryRules(var TempPlanLine: Record "Installment Plan Line" temporary)
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

    procedure PayInstallment(PlanID: Guid; Sequence: Integer; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ApplicationID: Code[50];
    begin
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        CustLedgerEntry.SetRange("Installment No.", Sequence);
        CustLedgerEntry.FindFirst();
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
        GenJournalLine.Validate("Applies-to ID", ApplicationID);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;
}
