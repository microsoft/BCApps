codeunit 134801 "Exp. Pos. Pay Check Ledger UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Positive Pay] [Data Exchange] [UT]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PreMappingCodeunitForPrinted()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        PositivePayDetail: Record "Positive Pay Detail";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
    begin
        // [SCENARIO 122869]  Creating the Positive Pay Detail for Printed Check

        // [GIVEN] Create the Data Exch Def, Bank Export/Import Setup, Bank Account, Vendor and Check Ledger Entry
        Initialize();
        CreateDataExchDefWithBankExpImpSetup(DataExchDef, BankExportImportSetup);
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        LibraryPurchase.CreateVendor(Vendor);
        CreateCheckLedger(CheckLedgerEntry, Vendor."No.", BankAccount."No.", CheckLedgerEntry."Entry Status"::Printed);

        // [GIVEN] Data Exch is created and the No. is assigned to the check Ledger Entry
        CreateDataExch(DataExch);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, false);

        // [WHEN] Run the codeunit.
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [THEN] The Positive Pay Detail record is created and values are updated to the fields from Check Ledger Entry.
        PositivePayDetail.SetRange("Data Exch. Entry No.", DataExch."Entry No.");
        PositivePayDetail.FindFirst();
        PositivePayDetail.TestField("Account Number");
        PositivePayDetail.TestField("Check Number", CheckLedgerEntry."Check No.");
        PositivePayDetail.TestField("Record Type Code", 'O');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreMappingCodeunitForVoided()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        PositivePayDetail: Record "Positive Pay Detail";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
    begin
        // [SCENARIO 122869]  Creating the Positive Pay Detail for Voided Check

        // [GIVEN] Create the Data Exch Def, Bank Export/Import Setup, Bank Account, Vendor and Check Ledger Entry
        Initialize();
        CreateDataExchDefWithBankExpImpSetup(DataExchDef, BankExportImportSetup);
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        LibraryPurchase.CreateVendor(Vendor);
        CreateCheckLedger(CheckLedgerEntry, Vendor."No.", BankAccount."No.", CheckLedgerEntry."Entry Status"::Voided);

        // [GIVEN] Data Exch is created and the No. is assigned to the check Ledger Entry
        CreateDataExch(DataExch);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, true);

        // [WHEN] Run the codeunit.
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [THEN] The Positive Pay Detail record is created and values are updated to the fields from Check Ledger Entry.
        PositivePayDetail.SetRange("Data Exch. Entry No.", DataExch."Entry No.");
        PositivePayDetail.FindFirst();
        PositivePayDetail.TestField("Account Number");
        PositivePayDetail.TestField("Check Number", CheckLedgerEntry."Check No.");
        PositivePayDetail.TestField("Record Type Code", 'V');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreMappingCodeunitForTestPrint()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        PositivePayDetail: Record "Positive Pay Detail";
        DataExch: Record "Data Exch.";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        // [SCENARIO 377488] Positive Pay Detail with blank Payee for "Test Print" Check Ledger Entry should be created

        // [GIVEN] Data Exchange Mapping for Table "Positive Pay Detail", Field = "Payee"
        // [GIVEN] Bank Export/Import Setup
        // [GIVEN] Check Ledger Entry with "Entry Status" = "Test Print" and blank Payee
        Initialize();
        CreateDataExchMappingWithSpecificField(
          DataExchLineDef, BankExportImportSetup, DATABASE::"Positive Pay Detail", PositivePayDetail.FieldNo(Payee));
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        CreateCheckLedger(CheckLedgerEntry, '', BankAccount."No.", CheckLedgerEntry."Entry Status"::"Test Print");

        // [GIVEN] Data Exch with assigned check Ledger Entry
        CreateDataExch(DataExch);
        DataExch.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExch.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExch.Modify(true);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, true);
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [WHEN] Run Exchange Mapping for Positive Pay Detail
        CODEUNIT.Run(CODEUNIT::"Exp. Mapping Det Pos. Pay", DataExch);

        // [THEN] The Positive Pay Detail record is created and value of "Payee" is blank
        PositivePayDetail.SetRange("Data Exch. Entry No.", DataExch."Entry No.");
        PositivePayDetail.FindFirst();
        PositivePayDetail.TestField(Payee, '');
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure ExpClearedOnFinanciallyVoided()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DataExch: Record "Data Exch.";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // [SCENARIO 122869]  Voiding the check should clear the "Positive Pay Exported" flag on Check Ledger Entry.
        // Check is Exported once posted, Voiding needs to clear the Positive Pay Exported flag in Check Ledger Entry

        // [GIVEN] Create and Post a Manual Check so that it can be exported
        Initialize();
        DocumentNo := CreateAndPostCheckLedgerEntry(GenJournalLine."Account Type"::Vendor, CreateVendor());

        // [GIVEN] Create the Data Exch Def, Bank Export/Import Setup, Bank Account, Vendor
        CreateDataExchDefWithBankExpImpSetup(DataExchDef, BankExportImportSetup);
        ModifyBankAccount(CheckLedgerEntry, BankAccount, DocumentNo, BankExportImportSetup.Code);

        // [GIVEN] Data Exch is created and the No. is assigned to the check Ledger Entry
        CreateDataExch(DataExch);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, false);

        // [GIVEN] Run the codeunit to export the posted check
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [GIVEN] Run the codeunit to update for feedback
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Pos. Pay", DataExch);

        // [GIVEN] The Positive Pay Detail record is created and Check Ledger Entry is updated as exported.
        if IsCheckLedgerExported(DocumentNo) = false then
            asserterror;

        // [WHEN] Void the Check
        LibraryVariableStorage.Enqueue(VoidType::"Void check only");
        VoidCheck(DocumentNo);

        // [THEN] The "Positive Pay Exported" flag is cleared.
        CheckLedgerEntry.TestField("Positive Pay Exported", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpUserFeedBackForPrinted()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        PositivePayEntry: Record "Positive Pay Entry";
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
    begin
        // [SCENARIO 122869]  Creating the Positive Pay Entry and Positive Pay Detail Entry for Printed check

        // [GIVEN] Create the Data Exch Def, Bank Export/Import Setup, Bank Account, Vendor and Check Ledger Entry
        Initialize();
        CreateDataExchDefWithBankExpImpSetup(DataExchDef, BankExportImportSetup);
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        LibraryPurchase.CreateVendor(Vendor);
        CreateCheckLedger(CheckLedgerEntry, Vendor."No.", BankAccount."No.", CheckLedgerEntry."Entry Status"::Printed);

        // [GIVEN] Data Exch is created and the No. is assigned to the check Ledger Entry
        CreateDataExch(DataExch);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, false);

        // [GIVEN] Run the codeunit.
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [WHEN] Run the codeunit to update for feedback
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Pos. Pay", DataExch);

        // [THEN] The Positive Pay Entry and Positive Pay Detail Entry records are created
        PositivePayEntry.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntry.FindLast();
        PositivePayEntry.TestField("Number of Checks", 1);
        PositivePayEntry.TestField("Check Amount", 10000.0);
        PositivePayEntryDetail.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail.SetRange("Upload Date-Time", PositivePayEntry."Upload Date-Time");
        PositivePayEntryDetail.FindFirst();
        PositivePayEntryDetail.TestField("Check No.", CheckLedgerEntry."Check No.");
        PositivePayEntryDetail.TestField("Document Type", PositivePayEntryDetail."Document Type"::CHECK);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpUserFeedBackForVoided()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
        PositivePayEntry: Record "Positive Pay Entry";
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
    begin
        // [SCENARIO 122869]  Creating the Positive Pay Entry and Positive Pay Detail Entry for a Voided check

        // [GIVEN] Create the Data Exch Def, Bank Export/Import Setup, Bank Account, Vendor and Check Ledger Entry
        Initialize();
        CreateDataExchDefWithBankExpImpSetup(DataExchDef, BankExportImportSetup);
        CreateBankAccount(BankAccount, BankExportImportSetup.Code);
        LibraryPurchase.CreateVendor(Vendor);
        CreateCheckLedger(CheckLedgerEntry, Vendor."No.", BankAccount."No.", CheckLedgerEntry."Entry Status"::Voided);

        // [GIVEN] Data Exch is created and Check Ledger Entry is created as Voided check and the No. is assigned
        CreateDataExch(DataExch);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, true);

        // [GIVEN] Run the codeunit.
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [WHEN] Run the codeunit to update for feedback
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Pos. Pay", DataExch);

        // [THEN] The Positive Pay Entry and Positive Pay Detail Entry records are created
        PositivePayEntry.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntry.FindLast();
        PositivePayEntry.TestField("Number of Voids", 1);
        PositivePayEntry.TestField("Void Amount", 10000.0);
        PositivePayEntryDetail.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail.SetRange("Upload Date-Time", PositivePayEntry."Upload Date-Time");
        PositivePayEntryDetail.FindFirst();
        PositivePayEntryDetail.TestField("Check No.", CheckLedgerEntry."Check No.");
        PositivePayEntryDetail.TestField("Document Type", PositivePayEntryDetail."Document Type"::VOID);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure ExpUserFeedBackForFinaciallyVoided()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PositivePayEntry: Record "Positive Pay Entry";
        PositivePayEntryDetail: Record "Positive Pay Entry Detail";
        DataExch2: Record "Data Exch.";
        DocumentNo: Code[20];
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // [SCENARIO 122869]  Positive Pay Entry and Positive Pay Entry Detail are created after the financially voided
        // Check is Exported once posted, Voiding needs to clear the Positive Pay Exported flag in Check Ledger Entry, then export again

        // [GIVEN] Create and Post a Manual Check so that it can be exported
        Initialize();
        DocumentNo := CreateAndPostCheckLedgerEntry(GenJournalLine."Account Type"::Vendor, CreateVendor());

        // [GIVEN] Create the Data Exch Def, Bank Export/Import Setup, Bank Account, Vendor
        CreateDataExchDefWithBankExpImpSetup(DataExchDef, BankExportImportSetup);
        ModifyBankAccount(CheckLedgerEntry, BankAccount, DocumentNo, BankExportImportSetup.Code);

        // [GIVEN] Data Exch is created and the No. is assigned to the check Ledger Entry
        CreateDataExch(DataExch);
        UpdateCheckLedger(CheckLedgerEntry, DataExch, false);

        // [GIVEN] Run the codeunit to export the posted check
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch);

        // [GIVEN] Run the codeunit to update for feedback
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Pos. Pay", DataExch);

        // [GIVEN] The Positive Pay Detail record is created and Check Ledger Entry is updated as exported.
        if IsCheckLedgerExported(DocumentNo) = false then
            asserterror;

        // [GIVEN] Voiding the check should clear the Positive Pay Exported flag
        LibraryVariableStorage.Enqueue(VoidType::"Void check only");
        VoidCheck(DocumentNo);

        // [GIVEN] Data Exch is created for the voided document
        CreateDataExch(DataExch2);
        CheckLedgerEntry.Reset();
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        UpdateCheckLedger(CheckLedgerEntry, DataExch2, true);

        // [GIVEN] Run the codeunit to export the posted check
        CODEUNIT.Run(CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay", DataExch2);

        // [WHEN] Run the codeunit to update for feedback
        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Pos. Pay", DataExch2);

        // [THEN] The Positive Pay Entry and Positive Pay Detail Entry records are created
        PositivePayEntry.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntry.FindLast();
        PositivePayEntry.TestField("Number of Voids", 1);
        PositivePayEntry.TestField("Void Amount", CheckLedgerEntry.Amount);
        PositivePayEntryDetail.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail.SetRange("Bank Account No.", BankAccount."No.");
        PositivePayEntryDetail.SetRange("Upload Date-Time", PositivePayEntry."Upload Date-Time");
        PositivePayEntryDetail.FindFirst();
        PositivePayEntryDetail.TestField("Check No.", CheckLedgerEntry."Check No.");
        PositivePayEntryDetail.TestField("Document Type", PositivePayEntryDetail."Document Type"::VOID);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Exp. Pos. Pay Check Ledger UT");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Exp. Pos. Pay Check Ledger UT");
        LibraryERMCountryData.DisableActivateChequeNoOnGeneralLedgerSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Exp. Pos. Pay Check Ledger UT");
    end;

    local procedure CreateDataExchDefWithBankExpImpSetup(var DataExchDef: Record "Data Exch. Def"; var BankExportImportSetup: Record "Bank Export/Import Setup")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Positive Pay Detail", 1);
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
    end;

    local procedure CreateSimpleDataExchDefWithMapping(var DataExchMapping: Record "Data Exch. Mapping"; TableID: Integer; FieldID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CreateSimpleDataExchDefWithMapping2(DataExchDef, DataExchMapping, DataExchFieldMapping, TableID, FieldID);
    end;

    local procedure CreateSimpleDataExchDefWithMapping2(var DataExchDef: Record "Data Exch. Def"; var DataExchMapping: Record "Data Exch. Mapping"; var DataExchFieldMapping: Record "Data Exch. Field Mapping"; TableID: Integer; FieldID: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        CreateDataExchWithMapping(DataExchDef, DataExchLineDef, DataExchMapping, DataExchFieldMapping, TableID, FieldID);
    end;

    local procedure CreateDataExchMappingWithSpecificField(var DataExchLineDef: Record "Data Exch. Line Def"; var BankExportImportSetup: Record "Bank Export/Import Setup"; TableID: Integer; FieldID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CreateDataExchWithMapping(DataExchDef, DataExchLineDef, DataExchMapping, DataExchFieldMapping, TableID, FieldID);

        CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
    end;

    local procedure CreateDataExchWithMapping(var DataExchDef: Record "Data Exch. Def"; var DataExchLineDef: Record "Data Exch. Line Def"; var DataExchMapping: Record "Data Exch. Mapping"; var DataExchFieldMapping: Record "Data Exch. Field Mapping"; TableID: Integer; FieldID: Integer)
    var
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        CreateDataExchDef(DataExchDef);
        CreateDataExchLineDef(DataExchLineDef, DataExchDef.Code);
        CreateDataExchColDef(DataExchColDef, DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code);
        CreateDataExchMapping(DataExchMapping, DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, TableID);
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, TableID, FieldID);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def")
    var
        DataExchDefCode: Code[20];
    begin
        DataExchDefCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef.Init();
        DataExchDef.Code := DataExchDefCode;
        DataExchDef.Name := DataExchDef.Code;
        DataExchDef.Type := DataExchDef.Type::"Positive Pay Export";
        DataExchDef.Insert();
    end;

    local procedure CreateDataExchLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDefCode: Code[20])
    var
        DataExchLineDefCode: Code[20];
    begin
        DataExchLineDefCode := LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Code), DATABASE::"Data Exch. Line Def");
        DataExchLineDef.Init();
        DataExchLineDef.Code := DataExchLineDefCode;
        DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchLineDef.Insert();
    end;

    local procedure CreateDataExchColDef(var DataExchColDef: Record "Data Exch. Column Def"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20])
    begin
        DataExchColDef.Init();
        DataExchColDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchColDef."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchColDef."Column No." := 1;
        DataExchColDef.Insert();
    end;

    local procedure CreateDataExchMapping(var DataExchMapping: Record "Data Exch. Mapping"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableID: Integer)
    begin
        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchMapping."Table ID" := TableID;
        DataExchMapping.Insert();
    end;

    local procedure CreateDataExchFieldMapping(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableID: Integer; FieldID: Integer)
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchFieldMapping."Table ID" := TableID;
        DataExchFieldMapping."Column No." := 1;
        DataExchFieldMapping."Field ID" := FieldID;
        DataExchFieldMapping.Insert();
    end;

    local procedure CreateBankExportImportSetup(var BankExportImportSetup: Record "Bank Export/Import Setup"; DataExchDef: Record "Data Exch. Def")
    begin
        BankExportImportSetup.Validate(Code, DataExchDef.Code);
        BankExportImportSetup.Validate(Name, DataExchDef.Name);
        BankExportImportSetup.Validate(Direction, BankExportImportSetup.Direction::"Export-Positive Pay");
        BankExportImportSetup.Validate("Data Exch. Def. Code", DataExchDef.Code);
        BankExportImportSetup.Insert(true);
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; BankEISetupCode: Code[20])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Positive Pay Export Code" := BankEISetupCode;
        BankAccount."Bank Account No." := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        BankAccount.Modify();
    end;

    local procedure CreateCheckLedger(var CheckLedgerEntry: Record "Check Ledger Entry"; Vendor: Code[20]; BankAccount: Code[20]; EntryStatus: Integer)
    var
        CheckLedgerEntry2: Record "Check Ledger Entry";
        NextCheckEntryNo: Integer;
    begin
        CheckLedgerEntry2.LockTable();
        CheckLedgerEntry2.Reset();
        if CheckLedgerEntry2.FindLast() then
            NextCheckEntryNo := CheckLedgerEntry2."Entry No." + 1
        else
            NextCheckEntryNo := 1;

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Entry No." := NextCheckEntryNo;
        CheckLedgerEntry.Validate("Bank Account No.", BankAccount);
        CheckLedgerEntry."Posting Date" := Today;
        CheckLedgerEntry."Document Type" := CheckLedgerEntry."Document Type"::Payment;
        CheckLedgerEntry."Document No." := CopyStr(Format(CreateGuid()), 1, 20);
        CheckLedgerEntry.Amount := 10000.0;
        CheckLedgerEntry."Check Date" := Today;
        CheckLedgerEntry."Check No." := CopyStr(Format(CreateGuid()), 1, 20);
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Computer Check";
        CheckLedgerEntry."Entry Status" := EntryStatus;
        CheckLedgerEntry."Bal. Account Type" := CheckLedgerEntry."Bal. Account Type"::Vendor;
        CheckLedgerEntry."Bal. Account No." := Vendor;
        CheckLedgerEntry."User ID" := UserId;
        CheckLedgerEntry.Insert(true);
    end;

    local procedure ModifyBankAccount(var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccount: Record "Bank Account"; DocumentNo: Code[20]; BankEISetupCode: Code[20])
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();

        BankAccount.Get(CheckLedgerEntry."Bank Account No.");
        BankAccount."Positive Pay Export Code" := BankEISetupCode;
        BankAccount."Bank Account No." := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        BankAccount.Modify();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch.")
    begin
        DataExch.Init();
        DataExch.Insert();
    end;

    local procedure UpdateCheckLedger(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExch: Record "Data Exch."; Void: Boolean)
    begin
        if Void then
            CheckLedgerEntry."Data Exch. Voided Entry No." := DataExch."Entry No."
        else
            CheckLedgerEntry."Data Exch. Entry No." := DataExch."Entry No.";

        CheckLedgerEntry.Modify();
    end;

    local procedure CreateAndPostCheckLedgerEntry(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // Setup: Create and Post General Journal line with bank Payment Type Manual Check.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, AccountNo,
          GenJournalLine."Bank Payment Type"::"Manual Check", '', BankAccount."No.", LibraryRandom.RandDec(100, 2), '');

        DocumentNo := GenJournalLine."Document No.";
    end;

    local procedure IsCheckLedgerExported(DocumentNo: Code[20]): Boolean
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        if CheckLedgerEntry.FindFirst() then
            exit(CheckLedgerEntry."Positive Pay Exported");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    begin
        CreateGenJournalLine(
          GenJournalLine, DocumentType, AccountType, AccountNo, BankPaymentType, CurrencyCode, BalAccountNo, Amount, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
    begin
        // Take Random Amount for General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        // Get Posting Date for Closed Financial Year.
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure VoidCheck(DocumentNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
        ConfirmFinancialVoid: Page "Confirm Financial Void";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    var
        VoidTypeVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VoidTypeVariant);
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), VoidTypeVariant);
        Response := ACTION::Yes
    end;
}

