codeunit 132572 "Payment Export FX Tables UT"
{
    // INSERT
    //   Sunshine
    //     Valid and M = 1 OR -1 OR 0.1
    //   Negative
    //     Valid and M = 0 ==> Error
    //     Not Valid and M = 0 ==> Error
    //     Not Valid and M = 1 OR -1 OR 0.1 ==> Error
    // 
    // MODIFY
    //   Sunshine
    //     Valid and DT = Decimal and M = 1 -> 2
    //     Valid and DT = Decimal -> Text and M = 1
    //     Valid and DT = Decimal and M = 1 -> 0
    // 
    // VALIDATE
    //   Negative
    //     Not Valid and M = 1 ==> Error
    //     Valid and M = 0 ==> Error

    Permissions = TableData "Data Exch." = i;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Mapping] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        ZeroNotAllowedErr: Label 'All numeric values are allowed except zero.';
        DataExchEntryNoRelationErr: Label 'Wrong relation to Data Exch Entry No.';

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierNonPmtExportFormat()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempDataExchMapping: Record "Data Exch. Mapping" temporary;
        TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary;
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), '', DataExchDef.Type::"Bank Statement Import".AsInteger(),
          XMLPORT::"Data Exch. Import - CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        TempDataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");

        // Exercise
        TempDataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          TempDataExchMapping."Table ID", DataExchColumnDef."Column No.", 1, false, 1);

        // Verify
        // No error occurs!

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatTextDataType()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempDataExchMapping: Record "Data Exch. Mapping" temporary;
        TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary;
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), '', DataExchDef.Type::"Payment Export".AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Text, '', '', '');

        // Setup
        TempDataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");

        // Exercise
        TempDataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          TempDataExchMapping."Table ID", DataExchColumnDef."Column No.", 1, false, 1);

        // Verify
        // No error occurs!

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatWrongValue()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempDataExchMapping: Record "Data Exch. Mapping" temporary;
        TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary;
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), '', DataExchDef.Type::"Payment Export".AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        TempDataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");

        // Exercise
        asserterror
          TempDataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
            TempDataExchMapping."Table ID", DataExchColumnDef."Column No.", 1, false, 0);

        // Verify
        Assert.ExpectedError(ZeroNotAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatFraction()
    begin
        MultiplierPmtExportFormat(0.1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatNegative()
    begin
        MultiplierPmtExportFormat(-1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatPositive()
    begin
        MultiplierPmtExportFormat(1);
    end;

    local procedure MultiplierPmtExportFormat(Multiplier: Decimal)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempDataExchMapping: Record "Data Exch. Mapping" temporary;
        TempDataExchFieldMapping: Record "Data Exch. Field Mapping" temporary;
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), '', DataExchDef.Type::"Payment Export".AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        TempDataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");

        // Exercise
        TempDataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          TempDataExchMapping."Table ID", DataExchColumnDef."Column No.", 1, false, Multiplier);

        // Verify
        // No error occurs!

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatDefault()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), '', DataExchDef.Type::"Payment Export".AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        DataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");

        // Exercise
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);

        // Verify
        DataExchFieldMapping.TestField(Multiplier, 1);

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatReset()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), DataExchDef.Type::"Payment Export".AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        DataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);

        // Post-Setup
        DataExchFieldMapping.TestField(Multiplier, 1);

        // Exercise
        DataExchColumnDef.Validate("Data Type", DataExchColumnDef."Data Type"::Text);
        DataExchColumnDef.Modify(true);
        DataExchFieldMapping.Validate(Multiplier, 1);

        // Verify
        // No errors occur!

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplierPmtExportFormatZero()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Pre-Setup
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), DataExchDef.Type::"Payment Export".AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, LibraryUtility.GenerateGUID(), '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, '',
          true, DataExchColumnDef."Data Type"::Decimal, '', '', '');

        // Setup
        DataExchMapping.InsertRecForExport(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Gen. Journal Line", '', CODEUNIT::"Payment Export Mgt");
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchDef.Code, DataExchLineDef.Code);

        // Post-Setup
        DataExchFieldMapping.TestField(Multiplier, 1);

        // Exercise
        DataExchFieldMapping.Multiplier := 0;
        DataExchFieldMapping.Modify(true);

        // Verify
        DataExchFieldMapping.TestField(Multiplier, 1);

        // Cleanup
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDataExchEntryNo()
    var
        DataExch: Record "Data Exch.";
        PaymentExportData: Record "Payment Export Data";
    begin
        // check validation passed
        if DataExch.FindLast() then;
        DataExch."Entry No." += 1;
        DataExch.Insert();

        if PaymentExportData.FindLast() then;
        PaymentExportData."Entry No." += 1;
        PaymentExportData.Validate("Data Exch Entry No.", DataExch."Entry No.");
        Assert.AreEqual(DataExch."Entry No.", PaymentExportData."Data Exch Entry No.", DataExchEntryNoRelationErr);
    end;

    local procedure CreateDataExchFieldMapping(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20])
    begin
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchFieldMapping."Table ID" := DATABASE::"Gen. Journal Line";
        DataExchFieldMapping."Column No." := 1;
        DataExchFieldMapping."Field ID" := 1;
        DataExchFieldMapping.Optional := false;
        DataExchFieldMapping.Insert(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseDefaultValueNonPmtExportFormat()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        CreatePmtExportFormat(DataExchDef, DataExchDef.Type::"Bank Statement Import");

        // Post-Setup
        DataExchMapping.Get(DataExchDef.Code, '', DATABASE::"Payment Export Data");

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", '');
        DataExchFieldMapping.SetRange("Table ID", DATABASE::"Payment Export Data");
        DataExchFieldMapping.SetRange("Column No.", 1);
        DataExchFieldMapping.FindFirst();

        // Exercise
        DataExchFieldMapping.Validate("Use Default Value", true);

        // Verify
        // No error occurs!

        // Cleanup
        DataExchMapping.Delete(true);
        DataExchDef.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseDefaultValuePmtExportFormat()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        CreatePmtExportFormat(DataExchDef, DataExchDef.Type::"Payment Export");

        // Post-Setup
        DataExchMapping.Get(DataExchDef.Code, '', DATABASE::"Payment Export Data");

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", '');
        DataExchFieldMapping.SetRange("Table ID", DATABASE::"Payment Export Data");
        DataExchFieldMapping.SetRange("Column No.", 1);
        DataExchFieldMapping.FindFirst();

        // Exercise
        DataExchFieldMapping.Validate("Use Default Value", true);

        // Verify
        // No error occurs!

        // Cleanup
        DataExchMapping.Delete(true);
        DataExchDef.Delete(true);
    end;

    local procedure CreatePmtExportFormat(var DataExchDef: Record "Data Exch. Def"; DataExchDefType: Enum "Data Exchange Definition Type")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchDef.InsertRecForExport(
          LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), DataExchDefType.AsInteger(),
          XMLPORT::"Export Generic CSV", DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 1);
        DataExchColumnDef.InsertRec(DataExchDef.Code, DataExchLineDef.Code, 1, LibraryUtility.GenerateGUID(),
          true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Payment Export Data", LibraryUtility.GenerateGUID(), 0, 0, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          DATABASE::"Payment Export Data", 1, 1, true, 0);
    end;
}

