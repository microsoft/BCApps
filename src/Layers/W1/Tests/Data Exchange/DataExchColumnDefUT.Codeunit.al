codeunit 132544 "Data Exch. Column Def UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Column] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LengthErr: Label 'Length must have a value in Data Exch. Column Def: ';
        DataFormatErr: Label 'Data Format must have a value in Data Exch. Column Def:';
        DataFormattingCultureErr: Label 'Data Formatting Culture must have a value in Data Exch. Column Def:';

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRecFixedText()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payment Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");
        DataExchDef.Modify(true);

        DataExchColumnDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchColumnDef."Column No." := LibraryRandom.RandIntInRange(1, 10);
        asserterror DataExchColumnDef.ValidateRec();
        Assert.ExpectedError(LengthErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRecPaymentExportDataTypeNotText()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payment Export");

        DataExchColumnDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchColumnDef."Column No." := LibraryRandom.RandIntInRange(1, 10);
        DataExchColumnDef."Data Type" := DataExchColumnDef."Data Type"::Decimal;
        asserterror DataExchColumnDef.ValidateRec();
        Assert.ExpectedError(DataFormatErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRecImportDataTypeDecimal()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payroll Import");

        DataExchColumnDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchColumnDef."Column No." := LibraryRandom.RandIntInRange(1, 10);
        DataExchColumnDef."Data Type" := DataExchColumnDef."Data Type"::Decimal;
        asserterror DataExchColumnDef.ValidateRec();
        Assert.ExpectedError(DataFormattingCultureErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateRecImportDataTypeDate()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import");

        DataExchColumnDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchColumnDef."Column No." := LibraryRandom.RandIntInRange(1, 10);
        DataExchColumnDef."Data Formatting Culture" := 'da-DK';
        DataExchColumnDef."Data Type" := DataExchColumnDef."Data Type"::Date;
        asserterror DataExchColumnDef.ValidateRec();
        Assert.ExpectedError(DataFormatErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteColumnDefinitionYes()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payment Export");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnDef(DataExchColumnDef, DataExchLineDef);
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchColumnDef);

        // Exercise
        DataExchColumnDef.Delete(true);

        // Verify
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchColumnDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchColumnDef."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Column No.", DataExchColumnDef."Column No.");
        Assert.IsTrue(DataExchFieldMapping.IsEmpty, 'Data Exch. Field Mapping should be deleted.')
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DeleteColumnDefinitionNo()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Payment Export");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnDef(DataExchColumnDef, DataExchLineDef);
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchColumnDef);
        Commit();

        // Exercise
        asserterror DataExchColumnDef.Delete(true);

        // Verify
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchColumnDef."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchColumnDef."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Column No.", DataExchColumnDef."Column No.");
        Assert.IsFalse(DataExchFieldMapping.IsEmpty, 'Data Exch. Field Mapping should not be deleted.')
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; ParamaterType: Enum "Data Exchange Definition Type")
    begin
        DataExchDef.Init();
        DataExchDef.Code :=
          LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef."File Type" := DataExchDef."File Type"::"Variable Text";
        DataExchDef.Validate(Type, ParamaterType);
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

    local procedure CreateDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColumnDef."Column No." := LibraryRandom.RandIntInRange(1, 10);
        DataExchColumnDef.Insert();
    end;

    local procedure CreateDataExchFieldMapping(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchColumnDef: Record "Data Exch. Column Def")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchColumnDef."Data Exch. Def Code";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchColumnDef."Data Exch. Line Def Code";
        DataExchFieldMapping."Table ID" := DATABASE::"Gen. Journal Line";
        DataExchFieldMapping."Column No." := DataExchColumnDef."Column No.";
        DataExchFieldMapping."Field ID" := GenJnlLine.FieldNo(Amount);
        DataExchFieldMapping.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

