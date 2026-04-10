codeunit 132546 "Data Exch. Field Mapping UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exch. Mapping] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        MissingFieldErr: Label '%1 must have a value in %2';

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFieldMappingMissingColumnNo()
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Table ID" := LibraryRandom.RandInt(100);
        DataExchFieldMapping."Field ID" := LibraryRandom.RandInt(100);

        // Exercise
        asserterror DataExchFieldMapping.Insert(true);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(MissingFieldErr, DataExchFieldMapping.FieldCaption("Column No."), DataExchFieldMapping.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetColumnCaption()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payroll Import");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnDef(DataExchColumnDef, DataExchLineDef);

        DataExchFieldMapping."Data Exch. Def Code" := DataExchDef.Code;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchFieldMapping."Column No." := DataExchColumnDef."Column No.";

        // Verify
        Assert.AreEqual(DataExchFieldMapping.GetColumnCaption(), DataExchColumnDef.Name, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFieldCaption()
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        Customer: Record Customer;
    begin
        // Setup
        DataExchFieldMapping."Table ID" := DATABASE::Customer;
        DataExchFieldMapping."Field ID" := Customer.FieldNo(Name);

        // Verify
        Assert.AreEqual(DataExchFieldMapping.GetFieldCaption(), Customer.FieldCaption(Name), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingAllowsExternalDataLineTags()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        // Setup.
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        DataExchLineDef.Validate("Data Line Tag", LibraryUtility.GenerateGUID());
        DataExchLineDef.Modify(true);
        DataExchColDef.InsertRecordForImport(
            DataExchDef.Code, DataExchLineDef.Code, 1,
            LibraryUtility.GenerateRandomCode(DataExchColDef.FieldNo(Name),
            DATABASE::"Data Exch. Column Def"), '', true, DataExchColDef."Data Type"::Decimal, '', '');
        DataExchMapping.InsertRecForImport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', 0, 0);
        DataExchFieldMapping.InsertRec(DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code",
          DATABASE::"Gen. Journal Line", 0, GenJournalLine.FieldNo(Amount), false, 1);

        // Exercise.
        DataExchFieldMapping.Validate("Column No.", DataExchColDef."Column No.");

        // Verify: no validation errors
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingAllowsInternalDataLineTags()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        // Setup.
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        DataExchLineDef.Validate("Data Line Tag", LibraryUtility.GenerateGUID());
        DataExchLineDef.Modify(true);
        DataExchColDef.InsertRecordForImport(
            DataExchDef.Code, DataExchLineDef.Code, 1,
            LibraryUtility.GenerateRandomCode(DataExchColDef.FieldNo(Name),
            DATABASE::"Data Exch. Column Def"), '', true, DataExchColDef."Data Type"::Decimal, '', '');
        DataExchColDef.Validate(Path,
          CopyStr(DataExchLineDef."Data Line Tag" + '/' + DataExchColDef.Name, 1, MaxStrLen(DataExchColDef.Path)));
        DataExchColDef.Modify(true);

        DataExchMapping.InsertRecForImport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', 0, 0);
        DataExchFieldMapping.InsertRec(DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code",
          DATABASE::"Gen. Journal Line", 0, GenJournalLine.FieldNo(Amount), false, 1);

        // Exercise.
        DataExchFieldMapping.Validate("Column No.", DataExchColDef."Column No.");

        // Verify: No validation errors.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingOverwriteValueOfFieldCodeType()
    var
        BankAccount: Record "Bank Account";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215352] Function "Process Data Exch.".SetField should overwrite value of field with type "Code" if "Data Exch. Field Mapping"."Overwrite Value" = TRUE

        // [GIVEN] Bank Account with "Search Name" = "Test Search Name"
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        RecRef.GetTable(BankAccount);

        // [GIVEN] "Data Exch. Field Mapping" with "Overwrite Value" = TRUE
        // [GIVEN] "Data Exch. Field" for field "Search Name" and Value = "Updated Search Name"
        CreateDataExchSetupAndFieldMappingWithOverwriteValue(
          DataExchFieldMapping, DataExchField, BankAccount.FieldNo("Search Name"), true);

        // [WHEN] Invoke "Process Data Exch.".SetField
        ProcessDataExch.SetField(RecRef, DataExchFieldMapping, DataExchField, Integer);
        RecRef.Modify(true);

        // [THEN] "Bank Account"."Search Name" = "Updated Search Name"
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField("Search Name", CopyStr(DataExchField.Value, 1, MaxStrLen(BankAccount."Search Name")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingOverwriteValueOfFieldTextType()
    var
        BankAccount: Record "Bank Account";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215352] Function "Process Data Exch.".SetField should overwrite value of field with type "Text" if "Data Exch. Field Mapping"."Overwrite Value" = TRUE

        // [GIVEN] Bank Account with "Name" = "Test Name"
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        RecRef.GetTable(BankAccount);

        // [GIVEN] "Data Exch. Field Mapping" with "Overwrite Value" = TRUE
        // [GIVEN] "Data Exch. Field" for field "Name" and Value = "Updated Name"
        CreateDataExchSetupAndFieldMappingWithOverwriteValue(DataExchFieldMapping, DataExchField, BankAccount.FieldNo(Name), true);

        // [WHEN] Invoke "Process Data Exch.".SetField
        ProcessDataExch.SetField(RecRef, DataExchFieldMapping, DataExchField, Integer);
        RecRef.Modify(true);

        // [THEN] "Bank Account"."Name" = "Updated Name"
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Name, CopyStr(DataExchField.Value, 1, MaxStrLen(BankAccount.Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingAppendValueOfFieldCodeType()
    var
        BankAccount: Record "Bank Account";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
        ExpectedString: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215352] Function "Process Data Exch.".SetField should append value of field with type "Code" if "Data Exch. Field Mapping"."Overwrite Value" = FALSE

        // [GIVEN] Bank Account with "Search Name" = "Test Search Name"
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        RecRef.GetTable(BankAccount);

        // [GIVEN] "Data Exch. Field Mapping" with "Overwrite Value" = TRUE
        // [GIVEN] "Data Exch. Field" for field "Search Name" and Value = "Updated Search Name"
        CreateDataExchSetupAndFieldMappingWithOverwriteValue(
          DataExchFieldMapping, DataExchField, BankAccount.FieldNo("Search Name"), false);

        // [WHEN] Invoke "Process Data Exch.".SetField
        ProcessDataExch.SetField(RecRef, DataExchFieldMapping, DataExchField, Integer);
        RecRef.Modify(true);

        // [THEN] "Bank Account"."Search Name" = "Test Search Name Updated Search Name"
        ExpectedString := CopyStr(BankAccount."Search Name" + ' ' + DataExchField.Value, 1, MaxStrLen(BankAccount."Search Name"));
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField("Search Name", ExpectedString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingAppendValueOfFieldTextType()
    var
        BankAccount: Record "Bank Account";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
        ExpectedString: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215352] Function "Process Data Exch.".SetField should append value of field with type "Text" if "Data Exch. Field Mapping"."Overwrite Value" = FALSE

        // [GIVEN] Bank Account with "Name" = "Test Name"
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        RecRef.GetTable(BankAccount);

        // [GIVEN] "Data Exch. Field Mapping" with "Overwrite Value" = TRUE
        // [GIVEN] "Data Exch. Field" for field "Name" and Value = "Updated Name"
        CreateDataExchSetupAndFieldMappingWithOverwriteValue(DataExchFieldMapping, DataExchField, BankAccount.FieldNo(Name), false);

        // [WHEN] Invoke "Process Data Exch.".SetField
        ProcessDataExch.SetField(RecRef, DataExchFieldMapping, DataExchField, Integer);
        RecRef.Modify(true);

        // [THEN] "Bank Account"."Name" = "Test Name Updated Name"
        ExpectedString := CopyStr(BankAccount.Name + ' ' + DataExchField.Value, 1, MaxStrLen(BankAccount.Name));
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Name, ExpectedString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingOverwriteValueOfMaxFilledFieldCodeType()
    var
        BankAccount: Record "Bank Account";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215352] Function "Process Data Exch.".SetField should overwrite value of field with type "Code" if "Data Exch. Field Mapping"."Overwrite Value" = TRUE and the current value has a max lenght of field

        // [GIVEN] Bank Account with maximum filled field "Search Name"
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        LibraryUtility.FillFieldMaxText(BankAccount, BankAccount.FieldNo("Search Name"));
        BankAccount.Get(BankAccount."No.");
        RecRef.GetTable(BankAccount);

        // [GIVEN] "Data Exch. Field Mapping" with "Overwrite Value" = TRUE
        // [GIVEN] "Data Exch. Field" for field "Search Name" and Value = "Updated Search Name"
        CreateDataExchSetupAndFieldMappingWithOverwriteValue(
          DataExchFieldMapping, DataExchField, BankAccount.FieldNo("Search Name"), true);

        // [WHEN] Invoke "Process Data Exch.".SetField
        ProcessDataExch.SetField(RecRef, DataExchFieldMapping, DataExchField, Integer);
        RecRef.Modify(true);

        // [THEN] "Bank Account"."Search Name" = "Updated Search Name"
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField("Search Name", CopyStr(DataExchField.Value, 1, MaxStrLen(BankAccount."Search Name")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FieldMappingOverwriteValueOfMaxFilledFieldTextType()
    var
        BankAccount: Record "Bank Account";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        "Integer": Record "Integer";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215352] Function "Process Data Exch.".SetField should overwrite value of field with type "Text" if "Data Exch. Field Mapping"."Overwrite Value" = TRUE and the current value has a max lenght of field

        // [GIVEN] Bank Account with maximum filled field "Name"
        LibraryPaymentExport.CreateBankAccount(BankAccount);
        LibraryUtility.FillFieldMaxText(BankAccount, BankAccount.FieldNo(Name));
        BankAccount.Get(BankAccount."No.");
        RecRef.GetTable(BankAccount);

        // [GIVEN] "Data Exch. Field Mapping" with "Overwrite Value" = TRUE
        // [GIVEN] "Data Exch. Field" for field "Name" and Value = "Updated Name"
        CreateDataExchSetupAndFieldMappingWithOverwriteValue(DataExchFieldMapping, DataExchField, BankAccount.FieldNo(Name), true);

        // [WHEN] Invoke "Process Data Exch.".SetField
        ProcessDataExch.SetField(RecRef, DataExchFieldMapping, DataExchField, Integer);
        RecRef.Modify(true);

        // [THEN] "Bank Account"."Name" = "Updated Name"
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Name, CopyStr(DataExchField.Value, 1, MaxStrLen(BankAccount.Name)));
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; ParamaterType: Enum "Data Exchange Definition Type")
    begin
        DataExchDef.Init();
        DataExchDef.Code :=
          LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef.Validate(Type, ParamaterType);
        if ParamaterType <> DataExchDef.Type::"Payment Export" then
            DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"Read Data Exch. from File";
        DataExchDef.Insert(true);
    end;

    local procedure CreateDataExchLineDef(var DataExchDef: Record "Data Exch. Def"; var DataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExchLineDef.Init();
        DataExchLineDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef.Code :=
          LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Code), DATABASE::"Data Exch. Line Def");
        DataExchLineDef.Insert();
    end;

    [Test]
    [HandlerFunctions('FieldsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeFieldID()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchMappingPage: TestPage "Data Exch Mapping Card";
    begin
        // Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchMappingPage.OpenEdit();
        DataExchMappingPage.GotoRecord(DataExchMapping);

        // Exercise
        DataExchMappingPage."Field Mapping"."Field ID".Lookup();

        // Verify
        Assert.AreEqual(2, DataExchMappingPage."Field Mapping"."Field ID".AsInteger(), 'Handler must set FieldID to 2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetUseDefaultValueTrueWithImport()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping2(
          DataExchDef, DataExchMapping, DataExchFieldMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Modify();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", DataExchMapping."Table ID");
        DataExchFieldMapping.FindFirst();

        // Execute
        DataExchFieldMapping.Validate("Use Default Value", true);

        // Verify
        Assert.AreEqual(true, DataExchFieldMapping."Use Default Value", 'Use Default Value should be true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetUseDefaultValueFalseWithExport()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping2(
          DataExchDef, DataExchMapping, DataExchFieldMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDef.Type := DataExchDef.Type::"Payment Export";
        DataExchDef.Modify();

        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Default Value" := 'Default';
        DataExchFieldMapping.Validate("Use Default Value", false);

        // Verify
        Assert.AreEqual('', DataExchFieldMapping."Default Value", 'Payment Export types must reset Default Value property');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierStays1OnModify()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping2(
          DataExchDef, DataExchMapping, DataExchFieldMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Modify();

        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping.TestField(Multiplier, 1);

        // Exercise
        DataExchFieldMapping.Validate(Optional, true);
        DataExchFieldMapping.Modify(true);

        // Verify
        DataExchFieldMapping.Find();
        DataExchFieldMapping.TestField(Multiplier, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenFieldMappingPageWithLongTableCaption()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DummyDataExchLineDef: Record "Data Exch. Line Def";
        DataExchMappingCard: TestPage "Data Exch Mapping Card";
    begin
        // [SCENARIO] "Data Exch Mapping Card" Page must may be opened even if mapping is set for table with a 250 symbols (max possible) length
        DataExchMappingCard.Trap();

        CreateDataExchColumnDef(DataExchColumnDef, DummyDataExchLineDef);
        CreateDataExchMapping(DataExchMapping, DummyDataExchLineDef, DATABASE::"Payment Export Remittance Text");
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchMapping, DataExchColumnDef."Column No.");
        DataExchFieldMapping."Target Table Caption" := CopyStr(LibraryUtility.GenerateRandomText(250), 1, 250);
        DataExchFieldMapping.Modify();

        PAGE.Run(PAGE::"Data Exch Mapping Card", DataExchMapping);
    end;

    local procedure CreateDataExchMapping(var DataExchMapping: Record "Data Exch. Mapping"; DataExchLineDef: Record "Data Exch. Line Def"; TableID: Integer)
    begin
        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping."Table ID" := TableID;
        DataExchMapping.Insert();
    end;

    local procedure CreateDataExchFieldMapping(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchMapping: Record "Data Exch. Mapping"; ColumnNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DataExchMapping."Table ID");
        FieldRef := RecRef.FieldIndex(1);
        CreateDataExchFieldMappingWithFieldID(DataExchFieldMapping, DataExchMapping, ColumnNo, FieldRef.Number);
    end;

    local procedure CreateDataExchFieldMappingWithFieldID(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchMapping: Record "Data Exch. Mapping"; ColumnNo: Integer; FieldID: Integer)
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchFieldMapping."Table ID" := DataExchMapping."Table ID";
        DataExchFieldMapping."Column No." := ColumnNo;
        DataExchFieldMapping."Field ID" := FieldID;
        DataExchFieldMapping.Insert();
    end;

    local procedure CreateDataExchSetupAndFieldMappingWithOverwriteValue(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; var DataExchField: Record "Data Exch. Field"; FieldNo: Integer; OverwriteValue: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payroll Import");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnDefWithColumnNo(DataExchColumnDef, DataExchLineDef, FieldNo);
        CreateDataExchMapping(DataExchMapping, DataExchLineDef, DATABASE::"Bank Account");
        CreateDataExchFieldMappingWithFieldID(DataExchFieldMapping, DataExchMapping, FieldNo, FieldNo);
        DataExchFieldMapping.Validate("Overwrite Value", OverwriteValue);
        DataExchFieldMapping.Modify(true);
        CreateDataExchField(DataExchField, DataExchLineDef, FieldNo);
        LibraryUtility.FillFieldMaxText(DataExchField, DataExchField.FieldNo(Value));
        DataExchField.Get(DataExchField."Data Exch. No.", DataExchField."Line No.", DataExchField."Column No.", DataExchField."Node ID");
    end;

    local procedure CreateDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def")
    begin
        CreateDataExchColumnDefWithColumnNo(DataExchColumnDef, DataExchLineDef, LibraryRandom.RandInt(10));
    end;

    local procedure CreateDataExchColumnDefWithColumnNo(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer)
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColumnDef."Column No." := ColumnNo;
        DataExchColumnDef.Insert();
    end;

    local procedure CreateDataExchField(var DataExchField: Record "Data Exch. Field"; DataExchLineDef: Record "Data Exch. Line Def"; ColumnNo: Integer)
    begin
        DataExchField.Init();
        DataExchField."Data Exch. No." := LibraryRandom.RandIntInRange(1, 10);
        DataExchField."Line No." := LibraryRandom.RandIntInRange(1, 10);
        DataExchField."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchField."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchField."Node ID" := LibraryUtility.GenerateGUID();
        DataExchField."Column No." := ColumnNo;
        DataExchField.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldsModalPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    begin
        FieldsLookup.Next();
        FieldsLookup.OK().Invoke();
    end;
}

