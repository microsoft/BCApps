codeunit 143002 "Library - Payment Journal BE"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateTemplate(var PaymentJnlTemplate: Record "Payment Journal Template")
    begin
        PaymentJnlTemplate.Init();
        PaymentJnlTemplate.Name := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentJnlTemplate.Name));
        PaymentJnlTemplate.Description := 'Description';
        PaymentJnlTemplate."Page ID" := PAGE::"EB Payment Journal";
        PaymentJnlTemplate.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBatch(PaymentJnlTemplate: Record "Payment Journal Template"; var PaymJournalBatch: Record "Paym. Journal Batch")
    begin
        PaymJournalBatch.Init();
        PaymJournalBatch."Journal Template Name" := PaymentJnlTemplate.Name;
        // Name may be INCSTR'ed which gives an overflow if last digit is '9'. Hence changing 9's to 0's.
        PaymJournalBatch.Name := ConvertStr(CopyStr(CreateGuid(), 1, MaxStrLen(PaymJournalBatch.Name)), '9', '0');
        PaymJournalBatch.Description := 'Description';
        PaymJournalBatch.Insert();
        PaymJournalBatch.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
    end;

    [Scope('OnPrem')]
    procedure InitPmtJournalLine(PaymentJnlTemplate: Record "Payment Journal Template"; PaymJournalBatch: Record "Paym. Journal Batch"; var PaymentJournalLine: Record "Payment Journal Line")
    begin
        PaymentJournalLine.Init();
        PaymentJournalLine."Journal Template Name" := PaymentJnlTemplate.Name;
        PaymentJournalLine."Journal Batch Name" := PaymJournalBatch.Name;
        PaymentJournalLine.SetRange("Journal Template Name", PaymentJournalLine."Journal Template Name");
        PaymentJournalLine.SetRange("Journal Batch Name", PaymentJournalLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    procedure CreateDomTemplate(var DomiciliationJournalTemplate: Record "Domiciliation Journal Template")
    begin
        DomiciliationJournalTemplate.Init();
        DomiciliationJournalTemplate.Name := CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalTemplate.Name));
        DomiciliationJournalTemplate.Description := 'Description';
        DomiciliationJournalTemplate."Page ID" := PAGE::"Domiciliation Journal";
        DomiciliationJournalTemplate.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateDomBatch(DomiciliationJournalTemplate: Record "Domiciliation Journal Template"; var DomiciliationJournalBatch: Record "Domiciliation Journal Batch")
    begin
        DomiciliationJournalBatch.Init();
        DomiciliationJournalBatch."Journal Template Name" := DomiciliationJournalTemplate.Name;
        // Name may be INCSTR'ed which gives an overflow if last digit is '9'. Hence changing 9's to 0's.
        DomiciliationJournalBatch.Name := ConvertStr(CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalBatch.Name)), '9', '0');
        DomiciliationJournalBatch.Description := 'Description';
        DomiciliationJournalBatch.Insert();
        DomiciliationJournalBatch.SetRange("Journal Template Name", DomiciliationJournalTemplate.Name);
    end;

    [Scope('OnPrem')]
    procedure CreateDomLine(var DomiciliationJournalLine: Record "Domiciliation Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        DomiciliationJournalLine.Init();
        DomiciliationJournalLine."Journal Template Name" := JournalTemplateName;
        DomiciliationJournalLine."Journal Batch Name" := JournalBatchName;
        DomiciliationJournalLine."Line No." := LibraryUtility.GetNewRecNo(DomiciliationJournalLine, DomiciliationJournalLine.FieldNo("Line No."));
        DomiciliationJournalLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InitDomJournalLine(DomiciliationJournalTemplate: Record "Domiciliation Journal Template"; DomiciliationJournalBatch: Record "Domiciliation Journal Batch"; var DomiciliationJournalLine: Record "Domiciliation Journal Line")
    begin
        DomiciliationJournalLine.Init();
        DomiciliationJournalLine."Journal Template Name" := DomiciliationJournalTemplate.Name;
        DomiciliationJournalLine."Journal Batch Name" := DomiciliationJournalBatch.Name;
        DomiciliationJournalLine.SetRange("Journal Template Name", DomiciliationJournalLine."Journal Template Name");
        DomiciliationJournalLine.SetRange("Journal Batch Name", DomiciliationJournalLine."Journal Batch Name");
    end;

    [Scope('OnPrem')]
    procedure CreateCustLedgEntryInvoice(var Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    begin
        if CustLedgEntry.FindLast() then;
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." += 1;
        CustLedgEntry."Customer No." := Customer."No.";
        CustLedgEntry."Posting Date" := WorkDate();
        CustLedgEntry."Document Type" := CustLedgEntry."Document Type"::Invoice;
        CustLedgEntry."Document No." := Customer."No.";
        CustLedgEntry."Currency Code" := CurrencyCode;
        CustLedgEntry.Amount := 1;
        CustLedgEntry."Pmt. Discount Date" := WorkDate() + 1;
        CustLedgEntry."Original Pmt. Disc. Possible" := 0.05;
        CustLedgEntry."Remaining Pmt. Disc. Possible" := 0.05;
        CustLedgEntry.Open := true;
        CustLedgEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure CreateVendLedgEntryInvoice(var Vendor: Record Vendor; var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    begin
        if VendLedgEntry.FindLast() then;
        VendLedgEntry.Init();
        VendLedgEntry."Entry No." += 1;
        VendLedgEntry."Vendor No." := Vendor."No.";
        VendLedgEntry."Posting Date" := WorkDate();
        VendLedgEntry."Document Type" := VendLedgEntry."Document Type"::Invoice;
        VendLedgEntry."Document No." := Vendor."No.";
        VendLedgEntry."Currency Code" := CurrencyCode;
        VendLedgEntry.Amount := 1;
        VendLedgEntry."Pmt. Discount Date" := WorkDate() + 1;
        VendLedgEntry."Original Pmt. Disc. Possible" := 0.05;
        VendLedgEntry."Remaining Pmt. Disc. Possible" := 0.05;
        VendLedgEntry.Open := true;
        VendLedgEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure RunSuggestDomiciliations(DomiciliationJournalLine: Record "Domiciliation Journal Line")
    var
        SuggestDomicilations: Report "Suggest domicilations";
    begin
        SuggestDomicilations.SetJournal(DomiciliationJournalLine);
        SuggestDomicilations.RunModal();
    end;
}

