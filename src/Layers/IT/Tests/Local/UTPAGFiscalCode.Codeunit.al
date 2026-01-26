codeunit 144146 "UT PAG Fiscal Code"
{
    // Test for feature - Fiscal Code.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateWithHoldTaxEntryVendorLedgerEntriesError()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // Purpose of the test is to validate CreateWithHoldTaxEntry Action of Page - 29 Vendor Ledger Entries.

        // Setup: Create Vendor Ledger Entry.
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice);
        OpenEditVendorLedgerEntriesPage(VendorLedgerEntries, VendorLedgerEntry."Entry No.");

        // Exercise.
        asserterror VendorLedgerEntries.CreateWithHoldTaxEntry.Invoke();

        // Verify actual error: You cannot create the withhold entry from entry because it's an Invoice Document.
        Assert.ExpectedErrorCode(DialogErr);
        VendorLedgerEntries.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateWithHoldTaxEntryVendorLedgerEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WithholdingTax: Record "Withholding Tax";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // Purpose of the test is to validate CreateWithHoldTaxEntry Action of Page - 29 Vendor Ledger Entries.

        // Setup: Create Vendor Ledger Entry.
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment);
        OpenEditVendorLedgerEntriesPage(VendorLedgerEntries, VendorLedgerEntry."Entry No.");

        // Exercise.
        VendorLedgerEntries.CreateWithHoldTaxEntry.Invoke();

        // Verify: Verify Vendor Ledger Entry - Document Number and Posting Date.
        WithholdingTax.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
        WithholdingTax.FindFirst();
        WithholdingTax.TestField("Document No.", VendorLedgerEntry."Document No.");
        WithholdingTax.TestField("Payment Date", VendorLedgerEntry."Posting Date");
        VendorLedgerEntries.Close();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Withholding Tax Code" := CreateWithholdCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry."Entry No." := 1;
        if VendorLedgerEntry2.FindLast() then
            VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        VendorLedgerEntry."Vendor No." := CreateVendor();
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateWithholdCode(): Code[20]
    var
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        WithholdCode.Code := LibraryUTUtility.GetNewCode();
        WithholdCode.Insert();
        WithholdCodeLine."Withhold Code" := WithholdCode.Code;
        WithholdCodeLine.Insert();
        exit(WithholdCode.Code);
    end;

    local procedure OpenEditVendorLedgerEntriesPage(var VendorLedgerEntries: TestPage "Vendor Ledger Entries"; EntryNo: Integer)
    begin
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Entry No.", Format(EntryNo));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

