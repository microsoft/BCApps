using Microsoft.Foundation.Company;
using Microsoft.Foundation.Registration;
using System.Environment.Configuration;

codeunit 132557 "Data Exch. Exp. Latin Char UT"
{
    Permissions = TableData "Data Exch." = i;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Preserve Non-Latin Characters] [UT]
    end;

    var
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        IsInitialized: Boolean;
        StringWithNonLatinChars: Text[20];

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        StringWithNonLatinChars := 'ABCÆØÅ@!'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreparePaymentExportDataJnlPreserveTRUE()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        LineNo: Integer;
    begin
        Initialize();

        // Setup
        CreateVendorPaymentLineWithNonLatinCharsPreserve(GenJournalLine);
        LineNo := 1;

        // Exercise
        PmtExportMgtGenJnlLine.PreparePaymentExportDataJnl(TempPaymentExportData, GenJournalLine,
          GenJournalLine."Data Exch. Entry No.", LineNo);

        // Verify
        Assert.AreEqual(TempPaymentExportData."Document No.", GenJournalLine."Document No.",
          'The non-latin characters were not preserved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreparePaymentExportDataJnlPreserveFALSE()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
        StringConversionManagement: Codeunit StringConversionManagement;
        LineNo: Integer;
    begin
        Initialize();

        // Setup
        CreateVendorPaymentLineWithNonLatinCharsDoNotPreserve(GenJournalLine);
        LineNo := 1;

        // Exercise
        PmtExportMgtGenJnlLine.PreparePaymentExportDataJnl(TempPaymentExportData, GenJournalLine,
          GenJournalLine."Data Exch. Entry No.", LineNo);

        // Verify
        Assert.AreNotEqual(TempPaymentExportData."Document No.", GenJournalLine."Document No.",
          'The non-latin characters were not preserved');
        Assert.AreEqual(TempPaymentExportData."Document No.",
          StringConversionManagement.WindowsToASCII(GenJournalLine."Document No."),
          'The non-latin characters were not converted as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreparePaymentExportDataVLEPreserveTRUE()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
        LineNo: Integer;
    begin
        Initialize();

        // Setup
        CreateVendLedgEntryPaymentWithNonLatinCharsPreserve(VendorLedgerEntry);
        DataExch.Init();
        DataExch.Insert();
        LineNo := 1;

        // Exercise
        PmtExportMgtVendLedgEntry.PreparePaymentExportDataVLE(TempPaymentExportData, VendorLedgerEntry,
          DataExch."Entry No.", LineNo);

        // Verify
        Assert.AreEqual(TempPaymentExportData."Document No.", VendorLedgerEntry."Document No.",
          'The non-latin characters were not preserved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreparePaymentExportDataVLEPreserveFALSE()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
        StringConversionManagement: Codeunit StringConversionManagement;
        LineNo: Integer;
    begin
        Initialize();

        // Setup
        CreateVendLedgEntryPaymentWithNonLatinCharsDoNotPreserve(VendorLedgerEntry);
        DataExch.Init();
        DataExch.Insert();
        LineNo := 1;

        // Exercise
        PmtExportMgtVendLedgEntry.PreparePaymentExportDataVLE(TempPaymentExportData, VendorLedgerEntry,
          DataExch."Entry No.", LineNo);

        // Verify
        Assert.AreNotEqual(TempPaymentExportData."Document No.", VendorLedgerEntry."Document No.",
          'The non-latin characters were not preserved');
        Assert.AreEqual(TempPaymentExportData."Document No.",
          StringConversionManagement.WindowsToASCII(VendorLedgerEntry."Document No."),
          'The non-latin characters were not converted as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreparePaymentExportDataCLEPreserveTRUE()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
        LineNo: Integer;
    begin
        Initialize();

        // Setup
        CreateCustLedgEntryPaymentWithNonLatinCharsPreserve(CustLedgerEntry);
        DataExch.Init();
        DataExch.Insert();
        LineNo := 1;

        // Exercise
        PmtExportMgtCustLedgEntry.PreparePaymentExportDataCLE(TempPaymentExportData, CustLedgerEntry,
          DataExch."Entry No.", LineNo);

        // Verify
        Assert.AreEqual(TempPaymentExportData."Document No.", CustLedgerEntry."Document No.",
          'The non-latin characters were not preserved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreparePaymentExportDataCLEPreserveFALSE()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
        StringConversionManagement: Codeunit StringConversionManagement;
        LineNo: Integer;
    begin
        Initialize();

        // Setup
        CreateCustLedgEntryPaymentWithNonLatinCharsDoNotPreserve(CustLedgerEntry);
        DataExch.Init();
        DataExch.Insert();
        LineNo := 1;

        // Exercise
        PmtExportMgtCustLedgEntry.PreparePaymentExportDataCLE(TempPaymentExportData, CustLedgerEntry,
          DataExch."Entry No.", LineNo);

        // Verify
        Assert.AreNotEqual(TempPaymentExportData."Document No.", CustLedgerEntry."Document No.",
          'The non-latin characters were not preserved');
        Assert.AreEqual(TempPaymentExportData."Document No.",
          StringConversionManagement.WindowsToASCII(CustLedgerEntry."Document No."),
          'The non-latin characters were not converted as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreMappingExportDataJnlPreserveTRUE()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentExportData: Record "Payment Export Data";
        DataExch: Record "Data Exch.";
    begin
        Initialize();

        // Setup
        CreateVendorPaymentLineWithNonLatinCharsPreserve(GenJournalLine);
        DataExch.Get(GenJournalLine."Data Exch. Entry No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", DataExch);

        // Verify
        PaymentExportData.SetRange("Data Exch Entry No.", GenJournalLine."Data Exch. Entry No.");
        PaymentExportData.FindFirst();
        Assert.AreEqual(PaymentExportData."Document No.", GenJournalLine."Document No.",
          'The non-latin characters were not preserved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreMappingExportDataJnlPreserveFALSE()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentExportData: Record "Payment Export Data";
        DataExch: Record "Data Exch.";
        StringConversionManagement: Codeunit StringConversionManagement;
    begin
        Initialize();

        // Setup
        CreateVendorPaymentLineWithNonLatinCharsDoNotPreserve(GenJournalLine);
        DataExch.Get(GenJournalLine."Data Exch. Entry No.");

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", DataExch);

        // Verify
        PaymentExportData.SetRange("Data Exch Entry No.", GenJournalLine."Data Exch. Entry No.");
        PaymentExportData.FindFirst();
        Assert.AreNotEqual(PaymentExportData."Document No.", GenJournalLine."Document No.",
          'The non-latin characters were not preserved');
        Assert.AreEqual(PaymentExportData."Document No.",
          StringConversionManagement.WindowsToASCII(GenJournalLine."Document No."),
          'The non-latin characters were not converted as expected');
    end;

    [Test]
    procedure VendorPaymentRejectsLossyLegalSenderConversion()
    var
        CompanyInformation: Record "Company Information";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        Initialize();
        SetRegistrationFeatureEnabled(true);
        CompanyInformation.Get();
        CompanyInformation."Registration No." := 'LEGAL&001';
        CompanyInformation.Modify();
        CreateVendLedgEntryPaymentWithNonLatinCharsDoNotPreserve(VendorLedgerEntry);

        asserterror PmtExportMgtVendLedgEntry.PreparePaymentExportDataVLE(TempPaymentExportData, VendorLedgerEntry, 0, 1);

        Assert.ExpectedError('cannot be exported unchanged');
    end;

    [Test]
    procedure CustomerPaymentRejectsLossyLegalSenderConversion()
    var
        CompanyInformation: Record "Company Information";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
    begin
        Initialize();
        SetRegistrationFeatureEnabled(true);
        CompanyInformation.Get();
        CompanyInformation."Registration No." := 'LEGAL_001';
        CompanyInformation.Modify();
        CreateCustLedgEntryPaymentWithNonLatinCharsDoNotPreserve(CustLedgerEntry);

        asserterror PmtExportMgtCustLedgEntry.PreparePaymentExportDataCLE(TempPaymentExportData, CustLedgerEntry, 0, 1);

        Assert.ExpectedError('cannot be exported unchanged');
    end;

    [Test]
    procedure UnicodePaymentPreservesFullLegalSenderAndBankBranch()
    var
        CompanyInformation: Record "Company Information";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBankAccount: Record "Vendor Bank Account";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
        NonLatinCharacter: Char;
        RegistrationNo: Text[50];
    begin
        Initialize();
        SetRegistrationFeatureEnabled(true);
        NonLatinCharacter := 233;
        RegistrationNo := PadStr('Ab-& /' + Format(NonLatinCharacter), 50, 'x');
        CompanyInformation.Get();
        CompanyInformation."Registration No." := RegistrationNo;
        CompanyInformation.Modify();
        CreateVendLedgEntryPaymentWithNonLatinCharsPreserve(VendorLedgerEntry);
        VendorBankAccount.Get(VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Recipient Bank Account");
        VendorBankAccount."Bank Branch No." := '0123';
        VendorBankAccount.Modify();

        PmtExportMgtVendLedgEntry.PreparePaymentExportDataVLE(TempPaymentExportData, VendorLedgerEntry, 0, 1);

        Assert.AreEqual(RegistrationNo, TempPaymentExportData."Sender Reg. No.", 'A Unicode payment must retain the full legal identifier.');
        TempPaymentExportData.TestField("Recipient Reg. No.", VendorBankAccount."Bank Branch No.");
    end;

    [Test]
    procedure DisabledRegistrationFeaturePreservesSenderConversion()
    var
        CompanyInformation: Record "Company Information";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        Initialize();
        SetRegistrationFeatureEnabled(false);
        CompanyInformation.Get();
        CompanyInformation."Registration No." := 'LEGAL&001';
        CompanyInformation.Modify();
        CreateVendLedgEntryPaymentWithNonLatinCharsDoNotPreserve(VendorLedgerEntry);

        PmtExportMgtVendLedgEntry.PreparePaymentExportDataVLE(TempPaymentExportData, VendorLedgerEntry, 0, 1);

        TempPaymentExportData.TestField("Sender Reg. No.", 'LEGAL+001');
    end;

    [Test]
    procedure LegalSenderRejectsNarrowFixedTextColumnBeforeFormatting()
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        RegistrationNoMgt: Codeunit "Registration No. Mgt.";
    begin
        SetRegistrationFeatureEnabled(true);
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(
            DataExchMapping, Database::"Payment Export Data", TempPaymentExportData.FieldNo("Sender Reg. No."));
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        DataExchDef."File Type" := DataExchDef."File Type"::"Fixed Text";
        DataExchDef.Modify();
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchColumnDef.FindFirst();
        DataExchColumnDef.Length := 10;
        DataExchColumnDef.Modify();
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch.Insert();
        TempPaymentExportData."Data Exch Entry No." := DataExch."Entry No.";
        TempPaymentExportData."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";

        asserterror RegistrationNoMgt.ValidatePaymentExportField(TempPaymentExportData, PadStr('0012', 50, 'X'),
            TempPaymentExportData.FieldNo("Sender Reg. No."), false, false);

        Assert.ExpectedError('maximum length of 10');
    end;

    local procedure SetRegistrationFeatureEnabled(Enabled: Boolean)
    var
        FeatureKey: Record "Feature Key";
        Status: Record "Feature Data Update Status";
        Feature: Codeunit "Registration No. Feature";
    begin
        if not FeatureKey.Get(Feature.GetFeatureKey()) then begin
            FeatureKey.ID := Feature.GetFeatureKey();
            FeatureKey.Insert();
        end;
        if Enabled then
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users"
        else
            FeatureKey.Enabled := FeatureKey.Enabled::None;
        FeatureKey."Data Update Required" := true;
        FeatureKey.Modify();
        if not Status.Get(FeatureKey.ID, CompanyName()) then begin
            Status."Feature Key" := FeatureKey.ID;
            Status."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Status."Company Name"));
            Status.Insert();
        end;
        Status."Feature Status" := Status."Feature Status"::Complete;
        Status."Data Update Required" := true;
        Status.Modify();
    end;

    local procedure CreateVendorPaymentLineWithNonLatinCharsPreserve(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateVendorPaymentLineWithNonLatinChars(GenJournalLine, true)
    end;

    local procedure CreateVendorPaymentLineWithNonLatinCharsDoNotPreserve(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateVendorPaymentLineWithNonLatinChars(GenJournalLine, false)
    end;

    local procedure CreateVendorPaymentLineWithNonLatinChars(var GenJournalLine: Record "Gen. Journal Line"; PreserveNonLatinChars: Boolean)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
        DataExch: Record "Data Exch.";
    begin
        CreateVendorWithBankAccount(Vendor, VendorBankAccount);
        CreateBankAccountWithExportFormat(BankAccount, PreserveNonLatinChars);
        DataExch.Init();
        DataExch.Insert();
        CreateGenJnlLine(GenJournalLine, BankAccount."No.", Vendor."No.");
        GenJournalLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJournalLine."Document No." := StringWithNonLatinChars; // some latin and non-latin chars
        GenJournalLine.Modify();
    end;

    local procedure CreateVendLedgEntryPaymentWithNonLatinCharsPreserve(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        CreateVendLedgEntryPaymentWithNonLatinChars(VendorLedgerEntry, true)
    end;

    local procedure CreateVendLedgEntryPaymentWithNonLatinCharsDoNotPreserve(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        CreateVendLedgEntryPaymentWithNonLatinChars(VendorLedgerEntry, false)
    end;

    local procedure CreateVendLedgEntryPaymentWithNonLatinChars(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PreserveNonLatinChars: Boolean)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        BankAccount: Record "Bank Account";
    begin
        CreateVendorWithBankAccount(Vendor, VendorBankAccount);
        CreateBankAccountWithExportFormat(BankAccount, PreserveNonLatinChars);

        // for unit testing only
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry."Bal. Account No." := BankAccount."No.";
        VendorLedgerEntry."Recipient Bank Account" := VendorBankAccount.Code;
        VendorLedgerEntry."Document No." := StringWithNonLatinChars; // some latin and non-latin chars
    end;

    local procedure CreateCustLedgEntryPaymentWithNonLatinCharsPreserve(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CreateCustLedgEntryPaymentWithNonLatinChars(CustLedgerEntry, true);
    end;

    local procedure CreateCustLedgEntryPaymentWithNonLatinCharsDoNotPreserve(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CreateCustLedgEntryPaymentWithNonLatinChars(CustLedgerEntry, false);
    end;

    local procedure CreateCustLedgEntryPaymentWithNonLatinChars(var CustLedgerEntry: Record "Cust. Ledger Entry"; PreserveNonLatinChars: Boolean)
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        BankAccount: Record "Bank Account";
    begin
        CreateCustomerWithBankAccount(Customer, CustomerBankAccount);
        CreateBankAccountWithExportFormat(BankAccount, PreserveNonLatinChars);

        // for unit testing only
        CustLedgerEntry."Customer No." := Customer."No.";
        CustLedgerEntry."Bal. Account No." := BankAccount."No.";
        CustLedgerEntry."Recipient Bank Account" := CustomerBankAccount.Code;
        CustLedgerEntry."Document No." := StringWithNonLatinChars; // some latin and non-latin chars
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; var VendorBankAccount: Record "Vendor Bank Account")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account")
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
    end;

    local procedure CreateBankAccountWithExportFormat(var BankAccount: Record "Bank Account"; PreserveNonLatinChars: Boolean): Code[20]
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");

        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
        BankExportImportSetup."Preserve Non-Latin Characters" := PreserveNonLatinChars;
        BankExportImportSetup.Modify();

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Payment Export Format" := BankExportImportSetup.Code;
        BankAccount.Modify();
        exit(BankAccount."No.")
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; VendorNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccountNo;
        GenJournalBatch.Modify();
        LibraryERM.CreateGeneralJnlLine2(GenJournalLine, GenJournalTemplate.Name,
          GenJournalBatch.Name, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          LibraryRandom.RandDec(1000, 2));
    end;
}

