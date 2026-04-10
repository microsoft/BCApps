codeunit 134800 "Pos. Pay Test Unit"
{
    Permissions = TableData "Data Exch." = id;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Positive Pay]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestPositivePayExportCodeNeg()
    var
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 122833]  Test the Pos Pay Export Code is invalid if it does not exist
        BankAccount.Init();
        asserterror BankAccount.Validate("Positive Pay Export Code", CopyStr(Format(CreateGuid()), 1, 20));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPositivePayExportCodePos()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 122833]  Test the Pos Pay Export Code is valid when exists in the Bank Export/Import Setup
        // [GIVEN] Create the Bank Export/Import Setup to validate
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, 20);
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-Positive Pay";
        BankExportImportSetup.Insert();

        // [WHEN] Positive Pay Export Code is a valid
        BankAccount.Init();
        BankAccount.Validate("Positive Pay Export Code", BankExportImportSetup.Code);

        // [THEN] Validation
        BankAccount.TestField("Positive Pay Export Code", BankExportImportSetup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPositivePayExportCodeInvalid()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 122833]  Test the Pos Pay Export Code is not valid even when it exists but is not of Type "Export-Positive Pay"
        // [GIVEN] Bank Eport/Import Setup.Code exists but create the Code so it is not a valid type
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, 20);
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup.Insert();

        // [THEN] Bank Account export code fails even though BankExportImportSetup code exists
        BankAccount.Init();
        asserterror BankAccount.Validate("Positive Pay Export Code", BankExportImportSetup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankExportImportCodeNeg()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 122833] From Bank Export/Import Setup, Test that Pos Pay Export Code is invalid if it does not exist
        // [GIVEN] Create the Bank Export/Import Setup record and attempt to add a BankExportImportSetup."Data Exch. Def. Code"
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, 20);
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-Positive Pay";

        // [THEN] Data Exch. Def. Code does not exist
        asserterror BankExportImportSetup.Validate("Data Exch. Def. Code", CopyStr(Format(CreateGuid()), 1, 20));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankExportImportCodePos()
    var
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 122833]  Test the Bank Export Import Setup.Data Exch Def Code is valid when exists in the Data Exchange Def
        // [GIVEN] Create the Data Exchange Def so it is valid
        DataExchDef.Init();
        DataExchDef.Code := CopyStr(Format(CreateGuid()), 1, 20);
        DataExchDef.Type := DataExchDef.Type::"Positive Pay Export";
        DataExchDef.Insert();

        // [WHEN] Data Exch. Def. Code is valid
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, 20);
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-Positive Pay";
        BankExportImportSetup.Validate("Data Exch. Def. Code", DataExchDef.Code);

        // [THEN] Validation
        BankExportImportSetup.TestField("Data Exch. Def. Code", DataExchDef.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankExportImportCodeInvalid()
    var
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        // [SCENARIO 122833] Test the Bank Export Import Setup.Data Exch Def Code is not valid when it exists but is not of Type "Positive Pay Export"
        // [GIVEN] No Bank Account Exists but create the Data Exchange Def so it is valid
        DataExchDef.Init();
        DataExchDef.Code := CopyStr(Format(CreateGuid()), 1, 20);
        DataExchDef.Type := DataExchDef.Type::"Payment Export";
        DataExchDef.Insert();

        // [THEN] Bank Export Import Setup Data Exchange Def. Code fails even though code exists
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, 20);
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::"Export-Positive Pay";
        asserterror BankExportImportSetup.Validate("Data Exch. Def. Code", DataExchDef.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateEntriesSumBankAcctNoNeg()
    var
        PositivePayEntry: Record "Positive Pay Entry";
    begin
        // [SCENARIO 123012] Test the Bank Account No. is invalid if it does not exist
        // [GIVEN] Bank Account does not exist
        PositivePayEntry.Init();
        asserterror PositivePayEntry.Validate("Bank Account No.", CopyStr(Format(CreateGuid()), 1, 20));

        // [THEN] Validate that the Update dates and times were also not set since the validation failed
        asserterror PositivePayEntry.TestField("Upload Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateEntriesSumBankAcctNoPos()
    var
        PositivePayEntry: Record "Positive Pay Entry";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 123012] Test the Bank Account No. is valid if it exists in the Bank Account.No.
        // [GIVEN] Bank Account does exist
        BankAccount.Init();
        BankAccount."No." := CopyStr(Format(CreateGuid()), 1, 20);
        BankAccount.Insert();

        // [WHEN] the Summary record also exists
        PositivePayEntry.Init();
        PositivePayEntry.Validate("Bank Account No.", BankAccount."No.");

        // [THEN] bank account and date-times are updated correctly
        PositivePayEntry.TestField("Bank Account No.", BankAccount."No.");

        // [THEN] Validate that the Update dates and times were set on the validation of the Bank Account No.
        PositivePayEntry.TestField("Upload Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateEntriesDetailPos()
    var
        PositivePayEntry: Record "Positive Pay Entry";
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 123012] Test the PositivePayEntryDetail is valid if it exists in the PositivePayEntry for "Bank Account No." and "Upload Date-Time"
        // [GIVEN] Need to create both the Bank Account and the Pos. Pay Upload Summary
        BankAccount.Init();
        BankAccount."No." := CopyStr(Format(CreateGuid()), 1, 20);
        BankAccount.Insert();

        PositivePayEntry.Init();
        PositivePayEntry."Bank Account No." := BankAccount."No.";
        PositivePayEntry.Insert();

        // [WHEN] validate the fields
        PositivePayEntryDetail.Init();
        PositivePayEntryDetail."Bank Account No." := PositivePayEntry."Bank Account No.";
        PositivePayEntryDetail.Validate("Upload Date-Time", PositivePayEntry."Upload Date-Time");
        PositivePayEntryDetail.Validate("Bank Account No.", BankAccount."No.");

        // [THEN] Test results
        PositivePayEntryDetail.TestField("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail.TestField("Bank Account No.", PositivePayEntry."Bank Account No.");
        PositivePayEntryDetail.TestField("Upload Date-Time", PositivePayEntry."Upload Date-Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateEntriesDetailNeg()
    var
        PositivePayEntry: Record "Positive Pay Entry";
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 123012] Test the PositivePayEntryDetail is invalid if it does not exists in the PositivePayEntry for "Bank Account No." and "Upload Date-Time"
        // [GIVEN] Need to create both the Bank Account and the Pos. Pay Upload Summary
        BankAccount.Init();
        BankAccount."No." := CopyStr(Format(CreateGuid()), 1, 20);
        BankAccount.Insert();

        PositivePayEntry.Init();
        PositivePayEntry."Bank Account No." := BankAccount."No.";
        PositivePayEntry.Insert();

        // [WHEN] Bank Account exists but the Upload Summary Record does not
        PositivePayEntryDetail.Init();
        PositivePayEntryDetail.Validate("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail."Bank Account No." := PositivePayEntry."Bank Account No.";

        // [THEN] Error given that date-time does not exist even though a summary existed for the bank acct
        asserterror PositivePayEntryDetail.Validate("Upload Date-Time", CreateDateTime(18001128D, 030000T));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateEntriesDetailBankAcctNeg()
    var
        PositivePayEntry: Record "Positive Pay Entry";
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 123012] Test the PositivePayEntryDetail is invalid if the Bank Account does not exist
        // [GIVEN] Need to create both the Bank Account and the Pos. Pay Upload Summary
        BankAccount.Init();
        BankAccount."No." := CopyStr(Format(CreateGuid()), 1, 20);
        BankAccount.Insert();

        PositivePayEntry.Init();
        PositivePayEntry."Bank Account No." := BankAccount."No.";
        PositivePayEntry.Insert();

        // [WHEN] Upload Summary Record exists but Bank Account does not
        PositivePayEntryDetail.Init();
        PositivePayEntryDetail."Bank Account No." := PositivePayEntry."Bank Account No.";
        PositivePayEntryDetail.Validate("Upload Date-Time", PositivePayEntry."Upload Date-Time");

        // [THEN] Error that bank account does not exist
        asserterror PositivePayEntryDetail.Validate("Bank Account No.", CopyStr(Format(CreateGuid()), 1, 20));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckLedgerEntryDataExchNoNeg()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // [SCENARIO 122869] Test the Data Exch. Entry No. and Data Exch. Voided Entry No. are invalid when Entry No. does not exist in the Data Exch.
        // [GIVEN] Check Ledger Entry created but Data Exch. does not exist
        CheckLedgerEntry.Init();
        CheckLedgerEntry."Entry No." := LibraryRandom.RandInt(100);

        // [THEN] Validation
        asserterror CheckLedgerEntry.Validate("Data Exch. Entry No.", LibraryRandom.RandInt(100));
        asserterror CheckLedgerEntry.Validate("Data Exch. Voided Entry No.", LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckLedgerEntryDataExchNoPos()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // [SCENARIO 122869] Test the Data Exch. Entry No. and Data Exch. Voided Entry No. are valid when Entry No. exists in the Data Exch.
        // [GIVEN] Create the Data Exchange Def
        DataExchDef.Init();
        DataExchDef.Code := CopyStr(Format(CreateGuid()), 1, 20);
        DataExchDef.Type := DataExchDef.Type::"Positive Pay Export";
        DataExchDef.Insert();

        // [GIVEN] Create the Data Exch. record
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchDef.Code;
        DataExch.Insert();

        // [WHEN] Check Ledger Entry.Data Exch. Entry No. is valid
        CheckLedgerEntry.Init();
        CheckLedgerEntry.Validate("Data Exch. Entry No.", DataExch."Entry No.");
        CheckLedgerEntry.Validate("Data Exch. Voided Entry No.", DataExch."Entry No.");

        // [THEN] Validation
        CheckLedgerEntry.TestField("Data Exch. Entry No.", DataExch."Entry No.");
        CheckLedgerEntry.TestField("Data Exch. Voided Entry No.", DataExch."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCheckLedgerEntryGetPayeeEmployee()
    var
        Employee: Record Employee;
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // [SCENARIO 327363] GetPayee function of "Check Ledger Entry" returns employee's full name if "Bal. Account Type" is "Employee" and "Bal. Account No." has been specified
        // [FEATURE] [UT] [Check Ledger Entry] [Employee]
        LibraryHumanResource.CreateEmployee(Employee);
        Employee."First Name" := 'A';
        Employee."Middle Name" := 'B';
        Employee."Last Name" := 'C';
        Employee.Modify();

        CheckLedgerEntry."Bal. Account Type" := CheckLedgerEntry."Bal. Account Type"::Employee;
        CheckLedgerEntry."Bal. Account No." := Employee."No.";

        Assert.AreEqual('A B C', CheckLedgerEntry.GetPayee(), 'Invalid GetPayee function resuly');
        Assert.AreEqual('A B C', Employee.FullName(), 'Employee name must not be blank');
    end;
}

