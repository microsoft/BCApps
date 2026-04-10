codeunit 132560 "Exp. Workflow Gen. Jnl. UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        LibraryRandom: Codeunit "Library - Random";
        RecordNotFoundErr: Label '%1 was not found.';
        LibraryHumanResource: Codeunit "Library - Human Resource";

    [Test]
    [Scope('OnPrem')]
    procedure PreMappingCodeunit()
    var
        BankAcc: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentExportData: Record "Payment Export Data";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        // [SCENARIO 1] Create the Payment Export Data records.
        // [GIVEN] One or more Gen. Journal Lines, applied to Vendor Ledger Entries.
        // [WHEN] Run the codeunit.
        // [THEN] The Data Exch. record is created, and the "File Name" field is set.
        // [THEN] The Data Exch. Entry No. field is updated on the Gen. Journal Lines.
        // [THEN] The Payment Export Data records are created.

        // Pre-Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
        CreateBankAccountWithExportFormat(BankAcc, BankExportImportSetup.Code);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Pre-Exercise
        DataExch.Init();
        DataExch.Insert();
        GenJnlLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", DataExch);

        // Verify
        PaymentExportData.SetRange("Document No.", GenJnlLine."Document No.");
        Assert.IsFalse(PaymentExportData.IsEmpty, StrSubstNo(RecordNotFoundErr, PaymentExportData.TableCaption()));

        // Cleanup
        PaymentExportData.FindFirst();
        PaymentExportData.Delete(true);
        DataExch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMappingCodeunit()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 3] Log the exporting action.
        // [GIVEN] One or more Gen. Journal Lines.
        // [WHEN] Run the codeunit.
        // [THEN] The Credit Transfer Register is created.
        // [THEN] The Credit Transfer Entries are created, one for each Gen. Journal Line.

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAcc);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID(), BankAcc."No.");

        // Pre-Exercise
        DataExch.Init();
        DataExch.Insert();
        GenJnlLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Post-Mapping Gen. Jnl.", DataExch);

        // Verify
        CreditTransferEntry.SetRange("Credit Transfer Register No.", CreditTransferRegister."No.");
        Assert.IsFalse(CreditTransferEntry.IsEmpty, StrSubstNo(RecordNotFoundErr, CreditTransferEntry.TableCaption()));

        // Cleanup
        DataExch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMappingCodeunitMiltiApplies()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        DataExch: Record "Data Exch.";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        ExpectedCount: Integer;
        i: Integer;
        AppliesCount: Integer;
    begin
        // [SCENARIO 379772] Credit Transfer Entries are created per each applies-to entry per journal line

        // [GIVEN] Payment journal with several lines each has several applied entries
        DataExch.Init();
        DataExch.Insert();
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        CreateExportGenJournalBatch(GenJnlBatch, BankAccountNo);
        VendorNo := LibraryPurchase.CreateVendorNo();

        for i := 1 to LibraryRandom.RandIntInRange(10, 20) do begin
            AppliesCount := LibraryRandom.RandIntInRange(10, 20);
            CreateVendPmtJournalLineWithMultiApplies(GenJnlBatch, VendorNo, DataExch."Entry No.", AppliesCount);
            ExpectedCount += AppliesCount;
        end;

        // [WHEN] Run Export Payment (using export setup via codeunit 1275 "Exp. Post-Mapping Gen. Jnl.")
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID(), BankAccountNo);
        CODEUNIT.Run(CODEUNIT::"Exp. Post-Mapping Gen. Jnl.", DataExch);

        // [THEN] Credit transfer register entries are created per each applies-to entry per journal line
        CreditTransferEntry.SetRange("Credit Transfer Register No.", CreditTransferRegister."No.");
        Assert.RecordCount(CreditTransferEntry, ExpectedCount);

        // Cleanup
        DataExch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserFeedbackCodeunit()
    var
        BankAcc: Record "Bank Account";
        CreditTransferEntry: Record "Credit Transfer Entry";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        CreditTransferRegisterNo: Integer;
        GenJnlLineLineNo: Integer;
    begin
        // [SCENARIO 6] Mark the Gen. Journal Lines as exported, and log the successful export status.
        // [GIVEN] One or more Gen. Journal Lines, applied to Vendor Ledger Entries.
        // [GIVEN] One Credit Transfer Register.
        // [WHEN] Run the codeunit.
        // [THEN] The status of the Credit Transfer Register is set to "File Created".
        // [THEN] The "Exported to Payment File" is set to True on the Gen. Journal Lines.

        // Pre-Setup
        LibraryERM.CreateBankAccount(BankAcc);
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Setup
        CreditTransferRegister.CreateNew(LibraryUtility.GenerateGUID(), BankAcc."No.");
        CreditTransferEntry.CreateNew(CreditTransferRegister."No.", 1,
          GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.GetAppliesToDocEntryNo(),
          GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount, '',
          GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");

        // Post-Setup
        GenJnlLineLineNo := GenJnlLine."Line No.";
        CreditTransferRegisterNo := CreditTransferRegister."No.";

        // Pre-Exercise
        DataExch.Init();
        DataExch.Insert();
        GenJnlLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJnlLine.Modify();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Gen. Jnl.", DataExch);

        // Verify
        CreditTransferRegister.Get(CreditTransferRegisterNo);
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");

        GenJnlLine.Get(GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLineLineNo);
        GenJnlLine.TestField("Exported to Payment File", true);

        // Cleanup
        DataExch.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreMappingEmployeeBankAccountFields()
    var
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentExportData: Record "Payment Export Data";
        DataExch: Record "Data Exch.";
        DummyPaymentType: Code[20];
    begin
        // [FEATURE] [Payment Journal] [Employee] [Bank Account] [Payment Export]
        // [SCENARIO 316225] Payment Journal export "Bank Account No." and "Bank Branch No." for Employee with Bank Account and Data Exch. Definition setup for the export

        CreateEmployeeWithBankAccount(Employee, DummyPaymentType);
        PrepareDataExchDefWithBankAccountsSetupForExport(DummyPaymentType, BankAccount);

        CreateExportGenJournalBatch(GenJournalBatch, BankAccount."No.");
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(1000, 2));

        DataExch.Init();
        DataExch.Insert();
        GenJournalLine."Data Exch. Entry No." := DataExch."Entry No.";
        GenJournalLine.Modify();
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", DataExch);

        PaymentExportData.SetRange("Data Exch Entry No.", GenJournalLine."Data Exch. Entry No.");
        PaymentExportData.FindFirst();
        PaymentExportData.TestField("Recipient Acc. No.", Employee."Bank Account No.");
        PaymentExportData.TestField("Recipient Reg. No.", Employee."Bank Branch No.");
    end;

    local procedure PrepareDataExchDefWithBankAccountsSetupForExport(PaymentType: Code[20]; var BankAccount: Record "Bank Account")
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
        CreateBankAccountWithExportFormat(BankAccount, CreatePaymentExportFormatWithMinSetup(PaymentType));
    end;

    [Normal]
    local procedure CreateEmployeeWithBankAccount(var Employee: Record Employee; PaymentType: Code[20])
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Pmt. Export Line Definition", LibraryUtility.GenerateGUID());
        PaymentMethod.Modify(true);

        PaymentType := PaymentMethod."Pmt. Export Line Definition";
    end;

    local procedure CreateBankAccountWithExportFormat(var BankAcc: Record "Bank Account"; PaymentExportFormat: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc.Validate("Payment Export Format", PaymentExportFormat);
        BankAcc.Modify(true);
    end;

    local procedure CreatePaymentExportFormatWithMinSetup(PaymentType: Code[20]): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, 0, 0, CODEUNIT::"Exp. Writing Gen. Jnl.",
          XMLPORT::"Export Generic CSV", CODEUNIT::"Save Data Exch. Blob Sample", 0);
        DataExchLineDef.InsertRec(DataExchDef.Code, PaymentType, LibraryUtility.GenerateGUID(), 3);
        LibraryPaymentFormat.CreateDataExchColumnDef(DataExchColumnDef, DataExchDef.Code, DataExchLineDef.Code);
        LibraryPaymentFormat.CreateDataExchMapping(DataExchMapping, DataExchDef.Code, DataExchLineDef.Code,
          CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", CODEUNIT::"Exp. Mapping Gen. Jnl.", 0);
        LibraryPaymentFormat.CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);
        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateExportGenJournalBatch(var GenJnlBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryPaymentExport.SelectPaymentJournalTemplate());
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJnlBatch.Validate("Allow Payment Export", true);
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateVendPmtJournalLineWithMultiApplies(GenJnlBatch: Record "Gen. Journal Batch"; VendorNo: Code[20]; DataExchEntryNo: Integer; AppliesCount: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, VendorNo, LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Applies-to ID" := LibraryUtility.GenerateGUID();
        GenJnlLine."Data Exch. Entry No." := DataExchEntryNo;
        GenJnlLine.Modify();

        for i := 1 to AppliesCount do
            MockVendorLegderEntryWithAppliesToID(VendorNo, GenJnlLine."Applies-to ID");
    end;

    local procedure MockVendorLegderEntryWithAppliesToID(VendorNo: Code[20]; AppliesToID: Code[50])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry."Entry No." :=
            LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo(VendorLedgerEntry."Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry."Applies-to ID" := AppliesToID;
        VendorLedgerEntry.Insert();
    end;
}

