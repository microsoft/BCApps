// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Finance.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 134196 "Payment Practices Library"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";

    procedure CreatePaymentPracticeHeader(var PaymentPracticeHeader: Record "Payment Practice Header"; HeaderType: Enum "Paym. Prac. Header Type"; AggregationType: Enum "Paym. Prac. Aggregation Type"; StartingDate: Date; EndingDate: Date)
    begin
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader."Header Type" := HeaderType;
        PaymentPracticeHeader."Aggregation Type" := AggregationType;
        PaymentPracticeHeader."Starting Date" := StartingDate;
        PaymentPracticeHeader."Ending Date" := EndingDate;
        PaymentPracticeHeader.Insert();
    end;

    procedure CreatePaymentPracticeHeader(var PaymentPracticeHeader: Record "Payment Practice Header"; HeaderType: Enum "Paym. Prac. Header Type"; AggregationType: Enum "Paym. Prac. Aggregation Type"; ReportingScheme: Enum "Paym. Prac. Reporting Scheme"; StartingDate: Date; EndingDate: Date)
    begin
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader."Header Type" := HeaderType;
        PaymentPracticeHeader."Aggregation Type" := AggregationType;
        PaymentPracticeHeader."Reporting Scheme" := ReportingScheme;
        PaymentPracticeHeader."Starting Date" := StartingDate;
        PaymentPracticeHeader."Ending Date" := EndingDate;
        PaymentPracticeHeader.Insert();
    end;

    procedure CreatePaymentPracticeHeaderSimple(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        CreatePaymentPracticeHeader(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::"Company Size", WorkDate() - 180, WorkDate() + 180);
    end;

    procedure CreatePaymentPracticeHeaderSimple(var PaymentPracticeHeader: Record "Payment Practice Header"; HeaderType: Enum "Paym. Prac. Header Type"; AggregationType: Enum "Paym. Prac. Aggregation Type")
    begin
        CreatePaymentPracticeHeader(PaymentPracticeHeader, HeaderType, AggregationType, WorkDate() - 180, WorkDate() + 180);
    end;

    procedure CreateCompanySizeCode(): Code[20]
    var
        CompanySize: Record "Company Size";
    begin
        CompanySize.Init();
        CompanySize.Code := LibraryUtility.GenerateGUID();
        CompanySize.Description := CompanySize.Code;
        CompanySize.Insert();
        exit(CompanySize.Code);
    end;

    procedure CreateVendorNoWithSizeAndExcl(CompanySizeCode: Code[20]; ExclFromPaymentPractice: Boolean) VendorNo: Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        SetCompanySize(Vendor, CompanySizeCode);
        SetExcludeFromPaymentPractices(Vendor, ExclFromPaymentPractice);
        exit(Vendor."No.");
    end;

    procedure InitializeCompanySizes(var CompanySizeCodes: array[3] of Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(CompanySizeCodes) do
            CompanySizeCodes[i] := CreateCompanySizeCode();
    end;

    procedure InitializePaymentPeriods(var PaymentPeriods: array[3] of Record "Payment Period")
    var
        PaymentPeriod: Record "Payment Period";
        i: Integer;
    begin
        PaymentPeriod.SetCurrentKey("Days From");
        PaymentPeriod.FindSet();
        for i := 1 to ArrayLen(PaymentPeriods) do begin
            PaymentPeriods[i] := PaymentPeriod;
            PaymentPeriod.Next();
        end;
    end;

    procedure InitAndGetLastPaymentPeriod(var PaymentPeriod: Record "Payment Period")
    begin
        PaymentPeriod.SetRange("Days To", 0);
        PaymentPeriod.FindLast();
    end;

    procedure SetCompanySize(var Vendor: Record Vendor; CompanySizeCode: Code[20])
    begin
        Vendor."Company Size Code" := CompanySizeCode;
        Vendor.Modify();
    end;

    procedure SetExcludeFromPaymentPractices(var Vendor: Record Vendor; NewExcludeFromPaymentPractice: Boolean)
    begin
        Vendor."Exclude from Pmt. Practices" := NewExcludeFromPaymentPractice;
        Vendor.Modify();
    end;

    procedure SetExcludeFromPaymentPractices(var Customer: Record Customer; NewExcludeFromPaymentPractice: Boolean)
    begin
        Customer."Exclude from Pmt. Practices" := NewExcludeFromPaymentPractice;
        Customer.Modify();
    end;

    procedure SetExcludeFromPaymentPracticesOnAllVendorsAndCustomers()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
    begin
        Vendor.ModifyAll("Exclude from Pmt. Practices", true);
        Customer.ModifyAll("Exclude from Pmt. Practices", true);
    end;

    procedure VerifyLinesCount(PaymentPracticeHeader: Record "Payment Practice Header"; NumberOfLines: Integer)
    var
        PaymentPracticeLine: Record "Payment Practice Line";
    begin
        PaymentPracticeLine.SetRange("Header No.", PaymentPracticeHeader."No.");
        Assert.RecordCount(PaymentPracticeLine, NumberOfLines);
    end;

    procedure VerifyPeriodLine(PaymentPracticeHeaderNo: Integer; SourceType: Enum "Paym. Prac. Header Type"; PaymentPeriodDescription: Text[250]; PctInPeriodExpected: Decimal; PctInPeriodAmountExpected: Decimal)
    var
        PaymentPracticeLine: Record "Payment Practice Line";
    begin
        PaymentPracticeLine.SetRange("Header No.", PaymentPracticeHeaderNo);
#pragma warning disable AA0210
        PaymentPracticeLine.SetRange("Payment Period Description", PaymentPeriodDescription);
        PaymentPracticeLine.SetRange("Source Type", SourceType);
#pragma warning restore AA0210
        PaymentPracticeLine.FindFirst();
        Assert.AreNearlyEqual(PctInPeriodExpected, PaymentPracticeLine."Pct Paid in Period", 0.1, '"Pct Paid in Period" is not as expected');
        Assert.AreNearlyEqual(PctInPeriodAmountExpected, PaymentPracticeLine."Pct Paid in Period (Amount)", 0.1, '"Pct Paid in Period (Amount)" is not as expected');
    end;


    procedure VerifyBufferCount(PaymentPracticeHeader: Record "Payment Practice Header"; NumberOfLines: Integer; SourceType: Enum "Paym. Prac. Header Type")
    var
        PaymentPracticeData: Record "Payment Practice Data";
    begin
        PaymentPracticeData.SetRange("Header No.", PaymentPracticeHeader."No.");
        PaymentPracticeData.SetRange("Source Type", SourceType);
        Assert.RecordCount(PaymentPracticeData, NumberOfLines);
    end;

    procedure CreateDefaultPaymentPeriodTemplates()
    var
        PaymentPeriod: Record "Payment Period";
    begin
        PaymentPeriod.DeleteAll();
        PaymentPeriod.SetupDefaults();
    end;




    procedure CleanupPaymentPracticeHeaders()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeData: Record "Payment Practice Data";
    begin
        PaymentPracticeData.DeleteAll();
        PaymentPracticeHeader.DeleteAll();
    end;


    procedure CreatePaymentPracticeHeaderWithScheme(var PaymentPracticeHeader: Record "Payment Practice Header"; HeaderType: Enum "Paym. Prac. Header Type"; AggregationType: Enum "Paym. Prac. Aggregation Type"; ReportingScheme: Enum "Paym. Prac. Reporting Scheme")
    begin
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader."Header Type" := HeaderType;
        PaymentPracticeHeader."Aggregation Type" := AggregationType;
        PaymentPracticeHeader."Reporting Scheme" := ReportingScheme;
        PaymentPracticeHeader."Starting Date" := WorkDate() - 180;
        PaymentPracticeHeader."Ending Date" := WorkDate() + 180;
        PaymentPracticeHeader.Insert();
    end;


    procedure DisputeRetCalcHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")
    var
        SchemeHandler: Interface PaymentPracticeSchemeHandler;
    begin
        SchemeHandler := "Paym. Prac. Reporting Scheme"::"Dispute & Retention";
        SchemeHandler.CalculateHeaderTotals(PaymentPracticeHeader, PaymentPracticeData);
    end;


    procedure MockVendLedgerEntry(VendorNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; PmtPostingDate: Date; IsOpen: Boolean)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := DocType;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Document Date" := PostingDate;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry.Open := IsOpen;
        VendorLedgerEntry."Closed at Date" := PmtPostingDate;
        VendorLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        VendorLedgerEntry.Insert();
    end;

    procedure MockVendorInvoice(VendorNo: Code[20]; PostingDate: Date; DueDate: Date) InvoiceAmount: Decimal;
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgerEntry(VendorNo, VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, 0D, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := VendorLedgerEntry."Amount (LCY)";
    end;

    procedure MockVendorInvoiceAndPayment(VendorNo: Code[20]; PostingDate: Date; DueDate: Date; PaymentPostingDate: Date) InvoiceAmount: Decimal;
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgerEntry(VendorNo, VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, PaymentPostingDate, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := VendorLedgerEntry."Amount (LCY)";
    end;

    procedure MockVendorInvoiceAndPaymentInPeriod(VendorNo: Code[20]; StartingDate: Date; PaidInDays_min: Integer; PaidInDays_max: Integer) InvoiceAmount: Decimal;
    var
        PostingDate: Date;
        DueDate: Date;
        PaymentPostingDate: Date;
    begin
        PostingDate := StartingDate;
        DueDate := StartingDate;
        if PaidInDays_max <> 0 then
            PaymentPostingDate := PostingDate + LibraryRandom.RandIntInRange(PaidInDays_min, PaidInDays_max)
        else
            PaymentPostingDate := PostingDate + PaidInDays_min + LibraryRandom.RandInt(10);
        InvoiceAmount := MockVendorInvoiceAndPayment(VendorNo, PostingDate, DueDate, PaymentPostingDate);
    end;

    procedure MockCustLedgerEntry(CustomerNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; PmtPostingDate: Date; IsOpen: Boolean)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := DocType;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Date" := PostingDate;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := IsOpen;
        CustLedgerEntry."Closed at Date" := PmtPostingDate;
        CustLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        CustLedgerEntry.Insert();
    end;

    procedure MockCustomerInvoice(CustomerNo: Code[20]; PostingDate: Date; DueDate: Date) InvoiceAmount: Decimal;
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockCustLedgerEntry(CustomerNo, CustLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, 0D, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := CustLedgerEntry."Amount (LCY)";
    end;

    procedure MockCustomerInvoiceAndPayment(CustomerNo: Code[20]; PostingDate: Date; DueDate: Date; PaymentPostingDate: Date) InvoiceAmount: Decimal;
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockCustLedgerEntry(CustomerNo, CustLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, PaymentPostingDate, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := CustLedgerEntry."Amount (LCY)";
    end;

    procedure MockCustomerInvoiceAndPaymentInPeriod(CustomerNo: Code[20]; StartingDate: Date; PaidInDays_min: Integer; PaidInDays_max: Integer) InvoiceAmount: Decimal;
    var
        PostingDate: Date;
        DueDate: Date;
        PaymentPostingDate: Date;
    begin
        PostingDate := StartingDate;
        DueDate := StartingDate + LibraryRandom.RandIntInRange(1, 5);
        PaymentPostingDate := PostingDate + LibraryRandom.RandIntInRange(PaidInDays_min, PaidInDays_max);
        InvoiceAmount := MockCustomerInvoiceAndPayment(CustomerNo, PostingDate, DueDate, PaymentPostingDate);
    end;


}