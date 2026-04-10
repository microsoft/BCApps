codeunit 132545 "Data Exch. Mapping UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Mapping]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        DataExchLineNoFieldNameTxt: Label 'Data Exch. Line No.';
        DataExchEntryNoFieldNameTxt: Label 'Data Exch. Entry No.';
        RecordNameFormatTok: Label '%1 to %2';
        RenameErr: Label 'You cannot rename the record if one or more field mapping lines exist.';

    [Test]
    [Scope('OnPrem')]
    procedure RenameRecord()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import", DataExchDef."File Type"::"Variable Text");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnDef(DataExchColumnDef, DataExchLineDef);
        CreateDataExchMapping(DataExchMapping, DataExchLineDef, DATABASE::"Gen. Journal Line");
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchMapping, DataExchColumnDef."Column No.");

        // Exercise
        asserterror DataExchMapping.Rename(DataExchDef.Code, DataExchLineDef.Code, LibraryRandom.RandIntInRange(1, 10));

        // Verify
        Assert.ExpectedError(RenameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDataExchMapping()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        // Setup
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import", DataExchDef."File Type"::"Variable Text");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);

        // Exercise
        DataExchMapping."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping.CreateDataExchMapping(DATABASE::"Gen. Journal Line", 0,
          GetFieldID(DATABASE::"Gen. Journal Line", DataExchEntryNoFieldNameTxt),
          GetFieldID(DATABASE::"Gen. Journal Line", DataExchLineNoFieldNameTxt));

        DataExchMapping.Get(DataExchDef.Code, DataExchLineDef.Code, DATABASE::"Gen. Journal Line");

        // Verify;
        DataExchMapping.TestField(Name, CreateName(DATABASE::"Gen. Journal Line", DataExchDef.Code));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeleteDataExchMapping()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMappingForDeleting: Record "Data Exch. Mapping";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        // [SCENARIO 371787] Removal of "Data Exch. Mapping" entry should not delete entries from "Data Exch. Field Mapping" with same "Data Exch. Def Code" and different "Table ID"
        // [GIVEN] Data Exchange Definition - "DED" with two "Data Exch. Mapping" - "DEM1" and "DEM2"
        // [GIVEN] "DEM1" with "Data Exch. Field Mapping" - "DEFM1" and "Data Exch. Def Code" = "DED"
        // [GIVEN] "DEM2" with "Data Exch. Field Mapping" - "DEFM2" and "Data Exch. Def Code" = "DED"
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import", DataExchDef."File Type"::Xml);
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnMappingField(DataExchMappingForDeleting, DataExchLineDef, DATABASE::Customer);
        CreateDataExchColumnMappingField(DataExchMapping, DataExchLineDef, DATABASE::Vendor);

        // [WHEN] Delete "DEM1"
        DataExchMappingForDeleting.Delete(true);

        // [THEN] "DEFM1" deleted
        // [THEN] "DEFM2" is not deleted
        VerifyNotExistingDataExchFieldMapping(DataExchMappingForDeleting);
        VerifyExistingDataExchFieldMapping(DataExchMapping);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestDeleteDataExchMappingSameTable()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Array[2] of Record "Data Exch. Line Def";
        DataExchMapping: Array[2] of Record "Data Exch. Mapping";
    begin
        // [SCENARIO 402216] Removal of "Data Exch. Mapping" entry should not delete entries from "Data Exch. Field Mapping" with same "Data Exch. Def Code", same "Table ID" and different "Data Exch. Line Def Code"
        // [GIVEN] Data Exchange Definition - "DED" with two "Data Exch. Mapping" - "DEM1" and "DEM2"
        // [GIVEN] "DEM1" with "Data Exch. Field Mapping" - "DEFM1", "Data Exch. Def Code" = "DED" and Table Id = "TID1"
        // [GIVEN] "DEM2" with "Data Exch. Field Mapping" - "DEFM2", "Data Exch. Def Code" = "DED" and Table Id = "TID1"
        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import", DataExchDef."File Type"::Xml);
        CreateDataExchLineDef(DataExchDef, DataExchLineDef[1]);
        CreateDataExchLineDef(DataExchDef, DataExchLineDef[2]);

        CreateDataExchColumnMappingField(DataExchMapping[1], DataExchLineDef[1], DATABASE::"Intermediate Data Import");
        CreateDataExchColumnMappingField(DataExchMapping[2], DataExchLineDef[2], DATABASE::"Intermediate Data Import");

        // [WHEN] Delete "DEM2"
        DataExchMapping[2].Delete(true);

        // [THEN] "DEFM2" deleted
        // [THEN] "DEFM1" is not deleted
        VerifyNotExistingDataExchFieldMapping(DataExchMapping[2]);
        VerifyExistingDataExchFieldMapping(DataExchMapping[1]);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; ParamaterType: Enum "Data Exchange Definition Type"; FileType: Option)
    begin
        DataExchDef.Init();
        DataExchDef.Code :=
          LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef."File Type" := FileType;
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
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchFieldMapping."Table ID" := DataExchMapping."Table ID";
        DataExchFieldMapping."Column No." := ColumnNo;
        RecRef.Open(DataExchFieldMapping."Table ID");
        FieldRef := RecRef.FieldIndex(1);
        DataExchFieldMapping."Field ID" := FieldRef.Number;
        DataExchFieldMapping.Insert();
    end;

    local procedure CreateDataExchColumnMappingField(var DataExchMapping: Record "Data Exch. Mapping"; DataExchLineDef: Record "Data Exch. Line Def"; TableID: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        CreateDataExchColumnDef(DataExchColumnDef, DataExchLineDef);
        CreateDataExchMapping(DataExchMapping, DataExchLineDef, TableID);
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchMapping, DataExchColumnDef."Column No.");
    end;

    local procedure FilterDataExchFieldMapping(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableID: Integer)
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchFieldMapping.SetRange("Table ID", TableID);
    end;

    local procedure GetFieldID(TableID: Integer; FieldName: Text): Integer
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(FieldName, FieldName);
        Field.FindFirst();
        exit(Field."No.");
    end;

    local procedure CreateName(TableID: Integer; "Code": Code[20]): Text[50]
    var
        recRef: RecordRef;
    begin
        recRef.Open(TableID);
        exit(StrSubstNo(RecordNameFormatTok, Code, recRef.Caption));
    end;

    local procedure VerifyExistingDataExchFieldMapping(DataExchMapping: Record "Data Exch. Mapping")
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        FilterDataExchFieldMapping(
          DataExchFieldMapping, DataExchMapping."Data Exch. Def Code",
          DataExchMapping."Data Exch. Line Def Code", DataExchMapping."Table ID");
        Assert.RecordIsNotEmpty(DataExchFieldMapping);
    end;

    local procedure VerifyNotExistingDataExchFieldMapping(DataExchMapping: Record "Data Exch. Mapping")
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        FilterDataExchFieldMapping(
          DataExchFieldMapping, DataExchMapping."Data Exch. Def Code",
          DataExchMapping."Data Exch. Line Def Code", DataExchMapping."Table ID");
        Assert.RecordIsEmpty(DataExchFieldMapping);
    end;
}

