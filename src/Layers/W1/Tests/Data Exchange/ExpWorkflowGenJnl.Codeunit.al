codeunit 134660 "Exp. Workflow Gen. Jnl."
{
    // The Open-Save-Cancel dialog has a different callback on the test client used in SNAP and the lab. Eventually,
    // the test cases SavePaymentDetailsToFileUsingFulllSetupClient and SavePaymentDetailsToFileUsingMinSetup won't
    // fail in SNAP or the lab.
    // 
    // To repeat the same experience on a local development box, the command ALTest RunTests needs to be used. Otherwise,
    // if a different test runner is used, then the regular Open-Save-Cancel dialog will pop up, as the actual server
    // callback is invoked.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Payment Export] [UT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileUsingFulllSetupClient()
    var
        BankAcc: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentType: Code[20];
    begin
        // [SCENARIO 1] Export Gen. Journal Lines to a payment file with all building blocks to a client file.
        // [GIVEN] One or more Gen. Journal Lines, applied to Vendor Ledger Entries.
        // [WHEN] Click the Export to File action on the Payment Journal.
        // [THEN] The payment file is created and saved to disk.

        // Pre-Setup
        PaymentType := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, PaymentType);
        CreateBankAccountWithExportFormat(BankAcc, CreatePaymentExportFormatWithFullSetupClient(PaymentType));
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Electronic Payment";
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAcc."No.");
        CreditTransferRegister.FindLast();

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        BankExportImportSetup.Get(BankAcc."Payment Export Format");

        // Verify
        CreditTransferRegister.TestField(Identifier, BankExportImportSetup."Data Exch. Def. Code");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
        GenJnlLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileUsingFulllSetupClientForEmployee()
    var
        BankAcc: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentType: Code[20];
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO 1] Export Gen. Journal Lines to a payment file with all building blocks to a client file.
        // [GIVEN] One or more Gen. Journal Lines, applied to Employee Ledger Entries.
        // [WHEN] Click the Export to File action on the Payment Journal.
        // [THEN] The payment file is created and saved to disk.

        // Pre-Setup
        PaymentType := LibraryUtility.GenerateGUID();
        CreateEmployeeWithBankAccount(Employee, PaymentType, PaymentMethodCode);
        CreateBankAccountWithExportFormat(BankAcc, CreatePaymentExportFormatWithFullSetupClient(PaymentType));
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Payment Method Code" := PaymentMethodCode;
        GenJnlLine."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Electronic Payment";
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAcc."No.");
        CreditTransferRegister.FindLast();

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        BankExportImportSetup.Get(BankAcc."Payment Export Format");

        // Verify
        CreditTransferRegister.TestField(Identifier, BankExportImportSetup."Data Exch. Def. Code");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
        GenJnlLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileUsingFulllSetupServer()
    var
        BankAcc: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentType: Code[20];
    begin
        // [SCENARIO 2] Export Gen. Journal Lines to a payment file with all building blocks to a server file.
        // [GIVEN] One or more Gen. Journal Lines, applied to Vendor Ledger Entries.
        // [WHEN] Click the Export to File action on the Payment Journal.
        // [THEN] The payment file is created and saved to disk.

        // Pre-Setup
        PaymentType := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, PaymentType);
        CreateBankAccountWithExportFormat(BankAcc, CreatePaymentExportFormatWithFullSetupServer(PaymentType));
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Electronic Payment";
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAcc."No.");
        CreditTransferRegister.FindLast();

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        BankExportImportSetup.Get(BankAcc."Payment Export Format");

        // Verify
        CreditTransferRegister.TestField(Identifier, BankExportImportSetup."Data Exch. Def. Code");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
        GenJnlLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileUsingFulllSetupServerForEmployee()
    var
        BankAcc: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentType: Code[20];
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO 2] Export Gen. Journal Lines to a payment file with all building blocks to a server file.
        // [GIVEN] One or more Gen. Journal Lines, applied to Employee Ledger Entries.
        // [WHEN] Click the Export to File action on the Payment Journal.
        // [THEN] The payment file is created and saved to disk.

        // Pre-Setup
        PaymentType := LibraryUtility.GenerateGUID();
        CreateEmployeeWithBankAccount(Employee, PaymentType, PaymentMethodCode);
        CreateBankAccountWithExportFormat(BankAcc, CreatePaymentExportFormatWithFullSetupServer(PaymentType));
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Payment Method Code" := PaymentMethodCode;
        GenJnlLine."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Electronic Payment";
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAcc."No.");
        CreditTransferRegister.FindLast();

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        BankExportImportSetup.Get(BankAcc."Payment Export Format");

        // Verify
        CreditTransferRegister.TestField(Identifier, BankExportImportSetup."Data Exch. Def. Code");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::"File Created");
        GenJnlLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileUsingMinSetup()
    var
        BankAcc: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentType: Code[20];
    begin
        // [SCENARIO 3] Export Gen. Journal Lines to a payment file with minimum building blocks to a client file.
        // [GIVEN] One or more Gen. Journal Lines, applied to Vendor Ledger Entries.
        // [WHEN] Click the Export to File action on the Payment Journal.
        // [THEN] The payment file is created and saved to disk.

        // Pre-Setup
        PaymentType := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, PaymentType);
        CreateBankAccountWithExportFormat(BankAcc, CreatePaymentExportFormatWithMinSetup(PaymentType));
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAcc."No.");
        CreditTransferRegister.FindLast();

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        BankExportImportSetup.Get(BankAcc."Payment Export Format");

        // Verify
        CreditTransferRegister.TestField(Identifier, BankExportImportSetup."Data Exch. Def. Code");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::Canceled);
        GenJnlLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SavePaymentDetailsToFileUsingMinSetupForEmployee()
    var
        BankAcc: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        PaymentType: Code[20];
        PaymentMethodCode: Code[10];
    begin
        // [SCENARIO 3] Export Gen. Journal Lines to a payment file with minimum building blocks to a client file.
        // [GIVEN] One or more Gen. Journal Lines, applied to Employee Ledger Entries.
        // [WHEN] Click the Export to File action on the Payment Journal.
        // [THEN] The payment file is created and saved to disk.

        // Pre-Setup
        PaymentType := LibraryUtility.GenerateGUID();
        CreateEmployeeWithBankAccount(Employee, PaymentType, PaymentMethodCode);
        CreateBankAccountWithExportFormat(BankAcc, CreatePaymentExportFormatWithMinSetup(PaymentType));
        CreateExportGenJournalBatch(GenJnlBatch, BankAcc."No.");

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Employee, Employee."No.", LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Payment Method Code" := PaymentMethodCode;
        GenJnlLine.Modify();

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJnlLine);

        // Pre-Verify
        CreditTransferRegister.SetRange("From Bank Account No.", BankAcc."No.");
        CreditTransferRegister.FindLast();

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        BankExportImportSetup.Get(BankAcc."Payment Export Format");

        // Verify
        CreditTransferRegister.TestField(Identifier, BankExportImportSetup."Data Exch. Def. Code");
        CreditTransferRegister.TestField(Status, CreditTransferRegister.Status::Canceled);
        GenJnlLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportGenJnlLineWhenPaymentExportFormatIsEmpty()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 288115]  Export Gen. Jornal Line when "Payment Export Format" of Bank Account in "Bal. Account No." is not set.

        // [GIVEN] Gen. Journal Line with "Bal. Account Type" = "Bank Account", "Bal. Account No." = "B".
        // [GIVEN] "Payment Export Format" of Bank Account "B" is empty.
        CreateVendorWithBankAccount(Vendor, LibraryUtility.GenerateGUID());
        LibraryERM.CreateBankAccount(BankAccount);
        CreateExportGenJournalBatch(GenJournalBatch, BankAccount."No.");

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Run codeunit "Exp. Launcher Gen. Jnl." on this Gen. Journal Line.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJournalLine);

        // [THEN] Error "Payment Export Format must have a value" is thrown.
        Assert.ExpectedTestFieldError(BankAccount.FieldCaption("Payment Export Format"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportGenJnlLineWhenDataExchDefCodeIsEmpty()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 288115]  Export Gen. Jornal Line when "Data Exch. Def. Code" of "Bank Export/Import Setup" of Bank Account in "Bal. Account No." is not set.

        // [GIVEN] Gen. Journal Line with "Bal. Account Type" = "Bank Account", "Bal. Account No." = "B".
        // [GIVEN] Bank Account "B" has "Payment Export Format", which has empty "Data Exch. Def. Code" field.
        CreateVendorWithBankAccount(Vendor, LibraryUtility.GenerateGUID());
        CreateBankAccountWithExportFormat(BankAccount, CreatePaymentExportFormatWithMinSetup(LibraryUtility.GenerateGUID()));
        BankExportImportSetup.Get(BankAccount."Payment Export Format");
        BankExportImportSetup."Data Exch. Def. Code" := '';
        BankExportImportSetup.Modify();
        CreateExportGenJournalBatch(GenJournalBatch, BankAccount."No.");

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Run codeunit "Exp. Launcher Gen. Jnl." on this Gen. Journal Line.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        asserterror CODEUNIT.Run(CODEUNIT::"Exp. Launcher Gen. Jnl.", GenJournalLine);

        // [THEN] Error "Data Exch. Def. Code must have a value" is thrown.
        Assert.ExpectedTestFieldError(BankExportImportSetup.FieldCaption("Data Exch. Def. Code"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTRunGetDataExchDefExportWhenDataExchDefTypeNotPaymentExport()
    var
        BankAccount: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 288115]  Run function GetDataExchDefPaymentExport from "Bank Account" table when "Data Exch. Def".Type is not equal to "Payment Export".

        // [GIVEN] Bank Account "B" has "Payment Export Format" "P".
        // [GIVEN] "P" has "Data Exch. Def. Code" "D".
        // [GIVEN] "D" has Type <> "Payment Export".
        CreateBankAccountWithExportFormat(BankAccount, CreatePaymentExportFormatWithMinSetup(LibraryUtility.GenerateGUID()));
        BankExportImportSetup.Get(BankAccount."Payment Export Format");
        DataExchDef.Get(BankExportImportSetup."Data Exch. Def. Code");
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Modify();

        // [WHEN] Run function GetDataExchDefPaymentExport from "Bank Account" table.
        asserterror BankAccount.GetDataExchDefPaymentExport(DataExchDef);

        // [THEN] Error "Type must be equal to 'Payment Export'  in Data Exch. Def" is thrown.
        Assert.ExpectedTestFieldError(DataExchDef.FieldCaption(Type), Format(DataExchDef.Type::"Payment Export"));
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; PaymentType: Code[20])
    var
        PaymentMethod: Record "Payment Method";
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAcc, Vendor."No.");
        VendorBankAcc.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAcc.Modify(true);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Pmt. Export Line Definition", PaymentType);
        PaymentMethod.Modify(true);

        Vendor.Validate("Preferred Bank Account Code", VendorBankAcc.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    [Normal]
    local procedure CreateEmployeeWithBankAccount(var Employee: Record Employee; PaymentType: Code[20]; var PaymentMethodCode: Code[20])
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);

        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Pmt. Export Line Definition", PaymentType);
        PaymentMethod.Modify(true);

        PaymentMethodCode := PaymentMethod.Code;
    end;

    local procedure CreateBankAccountWithExportFormat(var BankAcc: Record "Bank Account"; PaymentExportFormat: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc.Validate("Payment Export Format", PaymentExportFormat);
        BankAcc.Modify(true);
    end;

    local procedure CreatePaymentExportFormatWithFullSetupClient(PaymentType: Code[20]): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, CODEUNIT::"Exp. Data Handling Gen. Jnl.",
          CODEUNIT::"Exp. Validation Gen. Jnl.", CODEUNIT::"Exp. Writing Gen. Jnl.", XMLPORT::"Export Generic CSV",
          CODEUNIT::"Save Data Exch. Blob Sample", CODEUNIT::"Exp. User Feedback Gen. Jnl.");

        DataExchLineDef.InsertRec(DataExchDef.Code, PaymentType, LibraryUtility.GenerateGUID(), 3);

        LibraryPaymentFormat.CreateDataExchColumnDef(DataExchColumnDef, DataExchDef.Code, DataExchLineDef.Code);

        LibraryPaymentFormat.CreateDataExchMapping(DataExchMapping, DataExchDef.Code, DataExchLineDef.Code,
          CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", CODEUNIT::"Exp. Mapping Gen. Jnl.", CODEUNIT::"Exp. Post-Mapping Gen. Jnl.");

        LibraryPaymentFormat.CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);

        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);

        exit(BankExportImportSetup.Code);
    end;

    local procedure CreatePaymentExportFormatWithFullSetupServer(PaymentType: Code[20]): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, CODEUNIT::"Exp. Data Handling Gen. Jnl.",
          CODEUNIT::"Exp. Validation Gen. Jnl.", CODEUNIT::"Exp. Writing Gen. Jnl.", XMLPORT::"Export Generic CSV",
          CODEUNIT::"Save Data Exch. Blob Sample", CODEUNIT::"Exp. User Feedback Gen. Jnl.");

        DataExchLineDef.InsertRec(DataExchDef.Code, PaymentType, LibraryUtility.GenerateGUID(), 3);

        LibraryPaymentFormat.CreateDataExchColumnDef(DataExchColumnDef, DataExchDef.Code, DataExchLineDef.Code);

        LibraryPaymentFormat.CreateDataExchMapping(DataExchMapping, DataExchDef.Code, DataExchLineDef.Code,
          CODEUNIT::"Exp. Pre-Mapping Gen. Jnl.", CODEUNIT::"Exp. Mapping Gen. Jnl.", CODEUNIT::"Exp. Post-Mapping Gen. Jnl.");

        LibraryPaymentFormat.CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);

        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);

        exit(BankExportImportSetup.Code);
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
}

