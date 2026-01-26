codeunit 142074 "UT REP Export Electronic Pmt."
{
    // Check the Report 10083 (Export Electronic Payments)
    // 1. Verify Journal Template Name after report generation 10083(Export Electronic Payments) .
    // 
    // Covers Test Cases for WI - 336326
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                               TFS ID
    // ----------------------------------------------------------------------------------------------
    // OnAfterGenJnlLineUSFormatCustomerExportElectronicPayments        207335, 207336, 171127,171256
    // OnAfterGenJnlLineMXFormatCustomerExportElectronicPayments        207335, 207336, 171127,171256
    // OnAfterGenJnlLineCAFormatCustomerExportElectronicPayments        207335, 207336, 171127,171256
    // OnAfterGenJnlLineUSFormatVendorExportElectronicPayments          207335, 207336, 171127,171256
    // OnAfterGenJnlLineMXFormatVendorExportElectronicPayments          207335, 207336, 171127,171256
    // OnAfterGenJnlLineCAFormatVendorExportElectronicPayments          207335, 207336, 171127,171256
    // VoidExportedElectronicPaymentIAT                                 100395 // Removed due to IAT file download blocking test execution due to framework limitations
    // VoidExportedElectronicPayment

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Payment]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        TransitNoTxt: Label '095021007';
        GenJournalLineJournalTemplateNameTxt: Label 'Gen__Journal_Line_Journal_Template_Name';
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        VoidElectronicPaymentIATErr: Label 'Wrong result of Void Electronic Payment-IAT for field %1', Comment = '%1=Record field name being tested';
        VendRemittanceReportSelectionErr: Label 'You must add at least one Vendor Remittance report to the report selection.';
        CustomTransitNoTxt: Label '1234567800';
        CLABETransitNoTxt: Label '123456789123456789';
        "Layout": Option RDLC,Word;
        TempSubDirectoryTxt: Label '142083_Test\';
        PayeeAddressTxt: Label 'PayeeAddress_1_';

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGenJnlLineUSFormatCustomerExportElectronicPayments()
    var
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
        ExportFormat: Option ,US,CA,MX;
    begin
        // Purpose of the test to export file in US format for Customer for Report 10083 (Export Electronic Payments).
        // [GIVEN] Create payment journal
        // [WHEN] Export the payment journal
        // [THEN] Verify Journal Template Name after report generation for US Customer.
        BindSubscription(UTREPExportElectronicPmt);
        ExportElectronicPaymentsCustomer(ExportFormat::US);
        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGenJnlLineMXFormatCustomerExportElectronicPayments()
    var
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
        ExportFormat: Option ,US,CA,MX;
    begin
        // Purpose of the test to export file in MX format for Customer for Report 10083 (Export Electronic Payments).
        // [GIVEN] Create payment journal
        // [WHEN] Export the payment journal
        // [THEN] Verify Journal Template Name after report generation for MX Customer.
        BindSubscription(UTREPExportElectronicPmt);
        ExportElectronicPaymentsCustomer(ExportFormat::MX);
        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGenJnlLineCAFormatCustomerExportElectronicPayments()
    var
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
        ExportFormat: Option ,US,CA,MX;
    begin
        // Purpose of the test to export file in CA format for Customer for Report 10083 (Export Electronic Payments).
        // [GIVEN] Create payment journal
        // [WHEN] Export the payment journal
        // [THEN] Verify Journal Template Name after report generation for CA Customer.
        BindSubscription(UTREPExportElectronicPmt);
        ExportElectronicPaymentsCustomer(ExportFormat::CA);
        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGenJnlLineUSFormatVendorExportElectronicPayments()
    var
        ExportFormat: Option ,US,CA,MX;
    begin
        // Purpose of the test to export file in US format for Vendor for Report 10083 (Export Electronic Payments).
        // [GIVEN] Create payment journal
        // [WHEN] Export the payment journal
        // [THEN] Verify Journal Template Name after report generation for US Vendor.
        ExportElectronicPaymentsVendor(ExportFormat::US);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGenJnlLineMXFormatVendorExportElectronicPayments()
    var
        ExportFormat: Option ,US,CA,MX;
    begin
        // Purpose of the test to export file in MX format for Vendor for Report 10083 (Export Electronic Payments).
        // [GIVEN] Create payment journal
        // [WHEN] Export the payment journal
        // [THEN] Verify Journal Template Name after report generation for MX Vendor.
        ExportElectronicPaymentsVendor(ExportFormat::MX);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGenJnlLineCAFormatVendorExportElectronicPayments()
    var
        ExportFormat: Option ,US,CA,MX;
    begin
        // Purpose of the test to export file in CA format for Vendor for Report 10083 (Export Electronic Payments).
        // [GIVEN] Create payment journal
        // [WHEN] Export the payment journal
        // [THEN] Verify Journal Template Name after report generation for CA Vendor.
        ExportElectronicPaymentsVendor(ExportFormat::CA);
    end;

    local procedure ExportElectronicPaymentsCustomer(ExportFormat: Option)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        CustomerNo, CustomerBankAccountCode : Code[20];
    begin
        // Setup: Create Customer,Bank Account and General Journal Line.
        Initialize();
        CreateExportReportSelection(Layout::RDLC);
        CustomerNo := CreateCustomer();
        CustomerBankAccountCode := CreateCustomerBankAccount(CustomerNo, ExportFormat);
        CreateCustLedgerEntry(CustLedgerEntry, CustomerNo);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo,
          CustLedgerEntry."Document No.", ExportFormat, CustLedgerEntry.Amount, CustomerBankAccountCode);
        EnqueueValuesForExportElectronicPayment(GenJournalLine);
        Commit();
        // Exercise.
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        // Verify: Verify XML Data.
        GenJournalLine.Find();

        // Verify: Verify Journal Template Name after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GenJournalLineJournalTemplateNameTxt, GenJournalLine."Journal Template Name");
    end;

    local procedure ExportElectronicPaymentsVendor(ExportFormat: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
    begin
        // Setup: Create Vendor,Bank Account and General Journal Line.
        Initialize();
        BindSubscription(UTREPExportElectronicPmt);
        RunExportElectronicPaymentsVendor(GenJournalLine, ExportFormat, false);

        // Verify: Verify Journal Template Name after report generation.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GenJournalLineJournalTemplateNameTxt, GenJournalLine."Journal Template Name");
        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler,VoidElectronicPaymentsRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VoidExportedElectronicPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
        ExportFormat: Option ,US,CA,MX;
    begin
        // Test Void for Electronic Payment-IAT
        // [GIVEN] Create payment journal
        Initialize();
        BindSubscription(UTREPExportElectronicPmt);

        RunExportElectronicPaymentsVendor(GenJournalLine, ExportFormat::US, false); // ExportFormat doesn't matter
        // [WHEN] Void Electronic Payment
        RunVoidElectronicPayments(GenJournalLine);

        // [THEN] Verify Check Printed, Check Exported and Check Transmitted
        GenJournalLine.Find();
        Assert.IsFalse(
          GenJournalLine."Check Printed", StrSubstNo(VoidElectronicPaymentIATErr, GenJournalLine.FieldCaption("Check Printed")));
        Assert.IsFalse(
          GenJournalLine."Check Exported", StrSubstNo(VoidElectronicPaymentIATErr, GenJournalLine.FieldCaption("Check Exported")));
        Assert.IsFalse(
          GenJournalLine."Check Transmitted", StrSubstNo(VoidElectronicPaymentIATErr, GenJournalLine.FieldCaption("Check Transmitted")));
        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunExportElectronicPaymentsVendorWithoutReportSelectionRecord()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ReportSelections: Record "Report Selections";
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
        BulkVendorRemitReporting: Codeunit "Bulk Vendor Remit Reporting";
        VendorNo, VendorBankAccountCode : Code[20];
        ExportFormat: Option;
    begin
        // [SCENARIO 381364] Export Electronic Payments through Codeunit "Bulk Vendor Remit Reporting" when no reports in Report Selections
        Initialize();
        BindSubscription(UTREPExportElectronicPmt);

        // [GIVEN] There are no reports for Vendor Remittance in Report Selection
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        ReportSelections.DeleteAll();

        // [GIVEN] Gen. Journal Line ready for Export Electronic Payment
        VendorNo := CreateVendor();
        VendorBankAccountCode := CreateVendorBankAccount(VendorNo, ExportFormat);
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorNo);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          VendorLedgerEntry."Document No.", ExportFormat, VendorLedgerEntry.Amount, VendorBankAccountCode);

        // [WHEN] Run export via the Codeunit "Bulk Vendor Remit Reporting"
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        asserterror BulkVendorRemitReporting.RunWithRecord(GenJournalLine);
        // [THEN] Error is expected about no reports found in Report Selections for Vendor Remittance
        Assert.ExpectedError(VendRemittanceReportSelectionErr);
        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    [Test]
    [HandlerFunctions('ExportElectronicPaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsVendorShowRemitAddress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RemitAddress: Record "Remit Address";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        UTREPExportElectronicPmt: Codeunit "UT REP Export Electronic Pmt.";
        PaymentJournal: TestPage "Payment Journal";
        VendorNo, VendorBankAccountCode : Code[20];
        ExportFormat: Option ,US,CA,MX;
    begin
        // [SCENARIO 568388] The default remit address defined on the vendor is used on the Remittance Advice printed as a part of the (Bank - Export) 
        // processing of the CA/US Electronic Payments.
        Initialize();

        // [GIVEN] Bind the subscription
        BindSubscription(UTREPExportElectronicPmt);

        // [GIVEN] Create Vendor and Vendor Bank Account 
        VendorNo := CreateVendor();
        VendorBankAccountCode := CreateVendorBankAccount(VendorNo, ExportFormat::US);

        // [GIVEN] Create Remit to Address and set as default 
        LibraryPurchase.CreateRemitToAddress(RemitAddress, VendorNo);
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify();

        // [GIVEN] Create Vendor Ledger Entry
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorNo);

        // [GIVEN] Create Payment Journal
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          VendorLedgerEntry."Document No.", ExportFormat::US, VendorLedgerEntry.Amount, VendorBankAccountCode);

        // [GIVEN] Assign Remit to code
        GenJournalLine."Remit-to Code" := RemitAddress.Code;
        GenJournalLine.Modify();

        // [GIVEN]  Enqueue value for Report "Export Electronic Payments"
        EnqueueValuesForExportElectronicPayment(GenJournalLine);
        Commit();

        // [WHEN] Open Payment Journal and run the report "Export Electronic Payments"
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine);

        // [GIVEN] Close the Payment Journal Page
        PaymentJournal.Close();

        // [THEN] Load the report dataset file
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Verify Remit address on PayeeAddress
        LibraryReportDataset.AssertElementWithValueExists(PayeeAddressTxt, RemitAddress.Address);

        UnbindSubscription(UTREPExportElectronicPmt);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        UpdateCompanyInformation();  // Update Federal ID No. in Company Information.
    end;

    local procedure RunExportElectronicPaymentsVendor(var GenJournalLine: Record "Gen. Journal Line"; ExportFormat: Option; ElecPaymIAT: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentJournal: TestPage "Payment Journal";
        VendorNo, VendorBankAccountCode : Code[20];
    begin
        // Setup: Create Vendor,Bank Account and General Journal Line.
        Initialize();
        VendorNo := CreateVendor();
        VendorBankAccountCode := CreateVendorBankAccount(VendorNo, ExportFormat);
        CreateVendorLedgerEntry(VendorLedgerEntry, VendorNo);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo,
          VendorLedgerEntry."Document No.", ExportFormat, VendorLedgerEntry.Amount, VendorBankAccountCode);
        if ElecPaymIAT then
            ModifyGenJnlLineBankPaymentType(GenJournalLine);
        EnqueueValuesForExportElectronicPayment(GenJournalLine);
        Commit();
        // Exercise.
        PaymentJournal.OpenEdit();
        asserterror ExportPaymentJournalDirect(PaymentJournal, GenJournalLine);
        PaymentJournal.Close();
        // Verify: Verify XML Data.
        GenJournalLine.Find();
    end;

    local procedure RunVoidElectronicPayments(GenJournalLine: Record "Gen. Journal Line")
    var
        VoidTransmitElecPayments: Report "Void/Transmit Elec. Payments";
    begin
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        VoidTransmitElecPayments.SetUsageType(1); // Void
        VoidTransmitElecPayments.SetTableView(GenJournalLine);
        Commit();
        VoidTransmitElecPayments.RunModal();
    end;

    local procedure CreateBankAccount(ExportFormat: Option): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account");
        BankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account");
        BankAccount."Bank Acc. Posting Group" := CreateBankAccountPostingGroup();
        BankAccount."Bank Branch No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Branch No."), DATABASE::"Bank Account");
        BankAccount."Last Statement No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account");
        BankAccount."Export Format" := ExportFormat;
        BankAccount."Last Remittance Advice No." :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Remittance Advice No."), DATABASE::"Bank Account");
        BankAccount."Transit No." := TransitNoTxt;  // Fix Value required due to file format.
        BankAccount."E-Pay Export File Path" := TemporaryPath;
        BankAccount."Last E-Pay Export File Name" := 'E_000.txt';  // Name is not mandatory, Only txt format required.
        BankAccount."Client No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Client No."), DATABASE::"Bank Account");
        BankAccount."Client Name" := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Client Name"), DATABASE::"Bank Account");
        BankAccount."Input Qualifier" :=
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Input Qualifier"), DATABASE::"Bank Account");
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUtility.GenerateRandomCode(GLAccount.FieldNo("No."), DATABASE::"G/L Account");
        GLAccount.Insert();
        BankAccountPostingGroup.Code :=
          LibraryUtility.GenerateRandomCode(BankAccountPostingGroup.FieldNo(Code), DATABASE::"Bank Account Posting Group");
        BankAccountPostingGroup."G/L Account No." := GLAccount."No.";
        BankAccountPostingGroup.Insert();
        exit(BankAccountPostingGroup.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]; TransitNoFormat: Option ,US,CA,MX): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CustomerNo;
        CustomerBankAccount.Code :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account");
        CustomerBankAccount."Bank Branch No." :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Branch No."), DATABASE::"Customer Bank Account");
        CustomerBankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Account No."), DATABASE::"Customer Bank Account");
        case TransitNoFormat of
            TransitNoFormat::US,
          TransitNoFormat::CA:
                CustomerBankAccount."Transit No." := CustomTransitNoTxt;
            TransitNoFormat::MX:
                CustomerBankAccount."Transit No." := CLABETransitNoTxt;
        end;
        CustomerBankAccount."Use for Electronic Payments" := true;
        CustomerBankAccount.Insert();

        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; TransitNoFormat: Option ,US,CA,MX): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.Code := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account");
        VendorBankAccount."Bank Branch No." :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Branch No."), DATABASE::"Vendor Bank Account");
        VendorBankAccount."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Account No."), DATABASE::"Vendor Bank Account");
        case TransitNoFormat of
            TransitNoFormat::US,
          TransitNoFormat::CA:
                VendorBankAccount."Transit No." := CustomTransitNoTxt;
            TransitNoFormat::MX:
                VendorBankAccount."Transit No." := CLABETransitNoTxt;
        end;
        VendorBankAccount."Use for Electronic Payments" := true;
        VendorBankAccount.Insert();

        exit(VendorBankAccount.Code);
    end;

    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry2.FindLast() then
            CustLedgerEntry."Entry No." := CustLedgerEntry2."Entry No." + 1
        else
            CustLedgerEntry."Entry No." := 1;

        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." :=
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Remaining Amount" := CustLedgerEntry.Amount;
        CustLedgerEntry."Original Amt. (LCY)" := CustLedgerEntry.Amount;
        CustLedgerEntry."Remaining Amt. (LCY)" := CustLedgerEntry.Amount;
        CustLedgerEntry."Amount (LCY)" := CustLedgerEntry.Amount;
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Due Date" := WorkDate();
        CustLedgerEntry.Positive := true;
        CustLedgerEntry."Debit Amount" := CustLedgerEntry.Amount;
        CustLedgerEntry."Debit Amount (LCY)" := CustLedgerEntry.Amount;
        CustLedgerEntry."Original Amount" := CustLedgerEntry.Amount;
        CustLedgerEntry."Amount to Apply" := CustLedgerEntry.Amount;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry2.FindLast() then
            VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1
        else
            VendorLedgerEntry."Entry No." := 1;

        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." :=
          LibraryUtility.GenerateRandomCode(VendorLedgerEntry.FieldNo("Document No."), DATABASE::"Vendor Ledger Entry");
        VendorLedgerEntry.Amount := LibraryRandom.RandDec(10, 2);
        VendorLedgerEntry."Remaining Amount" := VendorLedgerEntry.Amount;
        VendorLedgerEntry."Original Amt. (LCY)" := VendorLedgerEntry.Amount;
        VendorLedgerEntry."Remaining Amt. (LCY)" := VendorLedgerEntry.Amount;
        VendorLedgerEntry."Amount (LCY)" := VendorLedgerEntry.Amount;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Due Date" := WorkDate();
        VendorLedgerEntry."Credit Amount" := VendorLedgerEntry.Amount;
        VendorLedgerEntry."Credit Amount (LCY)" := VendorLedgerEntry.Amount;
        VendorLedgerEntry."Original Amount" := VendorLedgerEntry.Amount;
        VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry.Amount;
        VendorLedgerEntry.Insert();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; ApplyToDocNo: Code[20]; ExportFormat: Option; Amount: Decimal; RecipientBankAccount: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // GenJournalTemplate.Name := LibraryUtility.GenerateRandomCode(GenJournalTemplate.FIELDNO(Name),DATABASE::"Gen. Journal Line");
        // GenJournalTemplate.Insert();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Line No." := LibraryRandom.RandInt(100);
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Document No." :=
          LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line");
        GenJournalLine."Bal. Account No." := CreateBankAccount(ExportFormat);
        GenJournalLine.Amount := Amount;
        GenJournalLine."Amount (LCY)" := Amount;
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := ApplyToDocNo;
        GenJournalLine."Due Date" := WorkDate();
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        GenJournalBatch."Bal. Account No." := GenJournalLine."Bal. Account No.";
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch.Insert();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Electronic Payment";
        GenJournalLine."Transaction Code" :=
          CopyStr(LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Transaction Code"), DATABASE::"Gen. Journal Line"), 1, 3);
        GenJournalLine."Transaction Type Code" := GenJournalLine."Transaction Type Code"::BUS;
        GenJournalLine."Company Entry Description" :=
        LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Company Entry Description"), DATABASE::"Gen. Journal Line");
        GenJournalLine."Recipient Bank Account" := RecipientBankAccount;
        GenJournalLine.Insert();
    end;

    local procedure ModifyGenJnlLineBankPaymentType(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Amount (LCY)" := GenJournalLine.Amount;
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT";
        GenJournalLine.Modify();
    end;

    local procedure EnqueueValuesForExportElectronicPayment(GenJournalLine: Record "Gen. Journal Line")
    begin
        // Enqueue value required in ExportElectronicPaymentsRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Document No.");
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Federal ID No." :=
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Federal ID No."), DATABASE::"Company Information");
        CompanyInformation.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportElectronicPaymentsRequestPageHandler(var ExportElectronicPayments: TestRequestPage "Export Electronic Payments")
    var
        No: Variant;
        BankAccountNo: Variant;
        JournalTemplateName: Variant;
        JournalBatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(JournalTemplateName);
        LibraryVariableStorage.Dequeue(JournalBatchName);
        LibraryVariableStorage.Dequeue(No); // Most recently queued
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Document No.", No);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Template Name", JournalTemplateName);
        ExportElectronicPayments."Gen. Journal Line".SetFilter("Journal Batch Name", JournalBatchName);
        ExportElectronicPayments.BankAccountNo.SetValue(BankAccountNo);
        ExportElectronicPayments.NumberOfCopies.SetValue(0);
        ExportElectronicPayments.PrintCompanyAddress.SetValue(false);
        ExportElectronicPayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VoidElectronicPaymentsRequestPageHandler(var VoidElectronicPayments: TestRequestPage "Void/Transmit Elec. Payments")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        VoidElectronicPayments."BankAccount.""No.""".SetValue(BankAccountNo); // Bank Account No.
        VoidElectronicPayments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CreateExportReportSelection("Layout": Option RDLC,Word)
    var
        ReportSelections: Record "Report Selections";
    begin
        // Insert or modify to get the expected remittance report selection
        ReportSelections.DeleteAll();
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"V.Remittance";
        case Layout of
            Layout::RDLC:
                ReportSelections."Report ID" := REPORT::"Export Electronic Payments";
            Layout::Word:
                ReportSelections."Report ID" := REPORT::"ExportElecPayments - Word";
        end;
        ReportSelections.Sequence := '1';
        ReportSelections.Insert();
    end;

    [Scope('OnPrem')]
    procedure ExportPaymentJournalDirect(var PaymentJournal: TestPage "Payment Journal"; GenJournalLine: Record "Gen. Journal Line")
    var
        ReportSelections: Record "Report Selections";
        Vendor: Record Vendor;
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        FileManagement: Codeunit "File Management";
        GenJnlLineRecRef: RecordRef;
        TempDirectory: Text;
    begin
        Commit();

        // Functions expect this to be opened and set up
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");

        GenJournalLine.SetFilter("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJnlLineRecRef.GetTable(GenJournalLine);
        GenJnlLineRecRef.SetView(GenJournalLine.GetView());

        TempDirectory := FileManagement.CombinePath(TemporaryPath, TempSubDirectoryTxt);
        if not FileManagement.ServerDirectoryExists(TempDirectory) then
            FileManagement.ServerCreateDirectory(TempDirectory);

        // Handle the layout runs
        CustomLayoutReporting.SetOutputFileBaseName('Test Remittance');
        CustomLayoutReporting.SetSavePath(TempDirectory);
        CustomLayoutReporting.SetOutputOption(CustomLayoutReporting.GetXMLOption());
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"V.Remittance", GenJnlLineRecRef, GenJournalLine.FieldName("Account No."), DATABASE::Vendor,
          Vendor.FieldName("No."), false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnIsTestMode', '', false, false)]
    local procedure EnableTestModeOnIsTestMode(var TestMode: Boolean)
    begin
        TestMode := true
    end;
}

