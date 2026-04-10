codeunit 132554 "Data Exch. E2E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Mapping]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        WrongDataExchFieldNameErr: Label 'Data Exch Field name is incorrect';
        WrongDataExchFieldValueErr: Label 'Data Exch Field value is incorrect';
        TooManyDataExchFieldRecordsErr: Label 'Data Exch Field has unexpected entries';


    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line without any grouping
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);

        // [GIVEN] to journal lines in the system
        CreateGenJournalLines();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Country Code', 'DK');
            DataExchField.Next();

            // [THEN] Third is equal to third mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '100');
            DataExchField.Next();

            // [THEN] Fourth is equal to first mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '20000');
            DataExchField.Next();

            // [THEN] Fifth is equal to second mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Country Code', 'DK');
            DataExchField.Next();

            // [THEN] Sixth is equal to third mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '200');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithTransformationTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line without any grouping. Apply EUCOUNTRYCODELOOKUP transformation rule 
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        DataExchFieldMapping.SetFilter("Column No.", '2');
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Transformation Rule" := 'EUCOUNTRYCODELOOKUP';
        DataExchFieldMapping.Modify(true);
        Commit();

        // [GIVEN] to journal lines in the system
        CreateGenJournalLines();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule
            CheckDataExchField(DataExchField, 'Country Code', 'Denmark');
            DataExchField.Next();

            // [THEN] Third is equal to third mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '100');
            DataExchField.Next();

            // [THEN] Fourth is equal to first mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '20000');
            DataExchField.Next();

            // [THEN] Fifth is equal to second mapped field from second Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule
            CheckDataExchField(DataExchField, 'Country Code', 'Denmark');
            DataExchField.Next();

            // [THEN] Sixth is equal to third mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '200');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithTransformationRoundingTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line without any grouping. Apply ROUNDTOINT transformation rule 
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        DataExchFieldMapping.SetFilter("Column No.", '3');
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Transformation Rule" := 'ROUNDTOINT';
        DataExchFieldMapping.Modify();
        Commit();

        // [GIVEN] to journal lines in the system
        CreateGenJournalLinesWithDecimal();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule
            CheckDataExchField(DataExchField, 'Country Code', 'DK');
            DataExchField.Next();

            // [THEN] Third is equal to third mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '101');
            DataExchField.Next();

            // [THEN] Fourth is equal to first mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '20000');
            DataExchField.Next();

            // [THEN] Fifth is equal to second mapped field from second Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule
            CheckDataExchField(DataExchField, 'Country Code', 'DK');
            DataExchField.Next();

            // [THEN] Sixth is equal to third mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '200');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithDefaultValueAndTransformationTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line without any grouping, use default value and EUCOUNTRYCODELOOKUP transformation rule 
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        DataExchFieldMapping.SetFilter("Column No.", '2');
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Use Default Value" := true;
        DataExchFieldMapping."Default Value" := 'FR';
        DataExchFieldMapping."Transformation Rule" := 'EUCOUNTRYCODELOOKUP';
        DataExchFieldMapping.Modify(true);
        Commit();

        // [GIVEN] to journal lines in the system
        CreateGenJournalLines();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            // Result is changed from DK to FR. As we applied default value Field Lookup transformation rule is skipped
            CheckDataExchField(DataExchField, 'Country Code', 'FR');
            DataExchField.Next();

            // [THEN] Third is equal to third mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '100');
            DataExchField.Next();

            // [THEN] Fourth is equal to first mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '20000');
            DataExchField.Next();

            // [THEN] Fifth is equal to second mapped field from second Gen Journal Line record
            // Result is changed from DK to FR. As we applied default value Field Lookup transformation rule is skipped
            CheckDataExchField(DataExchField, 'Country Code', 'FR');
            DataExchField.Next();

            // [THEN] Sixth is equal to third mapped field from second Gen Journal Line record
            CheckDataExchField(DataExchField, 'Amount', '200');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithGroupingTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line with grouping
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        CreateDataExchFieldGrouping(DataExchMapping, DATABASE::"Gen. Journal Line");

        // [GIVEN] to journal lines in the system
        CreateGenJournalLines();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Country Code', 'DK');
            DataExchField.Next();

            // [THEN] Third is equal to the sum of all amounts for grouped fields. 
            // IN this test it is DK, so Amount should be 300
            CheckDataExchField(DataExchField, 'Amount', '300');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithGroupingAndTransformationTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line with grouping and apply EUCOUNTRYCODELOOKUP transformation rule
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        CreateDataExchFieldGrouping(DataExchMapping, DATABASE::"Gen. Journal Line");
        DataExchFieldMapping.SetFilter("Column No.", '2');
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Transformation Rule" := 'EUCOUNTRYCODELOOKUP';
        DataExchFieldMapping.Modify(true);
        Commit();

        // [GIVEN] to journal lines in the system
        CreateGenJournalLines();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule
            CheckDataExchField(DataExchField, 'Country Code', 'Denmark');
            DataExchField.Next();

            // [THEN] Third is equal to the sum of all amounts for grouped fields. 
            // IN this test it is DK, so Amount should be 300
            CheckDataExchField(DataExchField, 'Amount', '300');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithGroupingAndPaddingTransformationTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line with grouping and apply EUCOUNTRYCODELOOKUP transformation rule
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        CreateDataExchFieldGrouping(DataExchMapping, DATABASE::"Gen. Journal Line");
        DataExchFieldMapping.SetFilter("Column No.", '2');
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Transformation Rule" := 'EUCOUNTRYCODELOOKUP';
        DataExchFieldMapping.Modify(true);

        DataExchColumnDef.SetFilter("Column No.", '2');
        DataExchColumnDef.FindFirst();
        DataExchColumnDef."Text Padding Required" := true;
        DataExchColumnDef."Pad Character" := '-';
        DataExchColumnDef.Justification := DataExchColumnDef.Justification::Right;
        DataExchColumnDef.Modify(true);
        Commit();

        // [GIVEN] to journal lines in the system
        CreateGenJournalLines();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule and then padded string to 10 characters
            CheckDataExchField(DataExchField, 'Country Code', '---Denmark');
            DataExchField.Next();

            // [THEN] Third is equal to the sum of all amounts for grouped fields. 
            // IN this test it is DK, so Amount should be 300
            CheckDataExchField(DataExchField, 'Amount', '300');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFormatWithGroupingAndTransformationRoundingTest()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        // [SCENARIO] Creating a Data Exchange format for mapping fields from Gen Journal Line with grouping and apply ROUNDTOINT transformation rule
        // [GIVEN] A Data Exchange format that maps data from Gen Journal Line
        Initialize(DataExchDef, DataExchLineDef, DataExchField, DataExchFieldMapping, DataExchColumnDef, DataExchMapping);
        CreateDataExchFieldGrouping(DataExchMapping, DATABASE::"Gen. Journal Line");
        DataExchFieldMapping.SetFilter("Column No.", '3');
        DataExchFieldMapping.FindFirst();
        DataExchFieldMapping."Transformation Rule" := 'ROUNDTOINT';
        DataExchFieldMapping.Modify(true);
        Commit();

        // [GIVEN] to journal lines in the system
        CreateGenJournalLinesWithDecimal();

        // [WHEN] Init data exchange and export from
        DataExch.Init();
        DataExch."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExch.Insert(true);
        DataExch.ExportFromDataExch(DataExchMapping);

        // [WHEN] Getting exported data exchange fields
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin

            // [THEN] First is equal to first mapped field from first Gen Journal Line record
            CheckDataExchField(DataExchField, 'Line No', '10000');
            DataExchField.Next();

            // [THEN] Second is equal to second mapped field from first Gen Journal Line record
            // Result is changed from DK to Denmark, as we applied Field Lookup transformation rule
            CheckDataExchField(DataExchField, 'Country Code', 'DK');
            DataExchField.Next();

            // [THEN] Third is equal to the sum of all amounts for grouped fields. 
            // IN this test it is DK, so Amount should be 301 as the sum of amounts is 300.7; 
            CheckDataExchField(DataExchField, 'Amount', '301');
            Assert.AreEqual(DataExchField.Next(), 0, TooManyDataExchFieldRecordsErr);
        end;
    end;


    local procedure Initialize(var DataExchDef: Record "Data Exch. Def"; var DataExchLineDef: Record "Data Exch. Line Def"; var DataExchField: Record "Data Exch. Field"; var DataExchFieldMapping: Record "Data Exch. Field Mapping"; var DataExchColumnDef: Record "Data Exch. Column Def"; var DataExchMapping: Record "Data Exch. Mapping")
    var
        TransformationRule: Record "Transformation Rule";
    begin
        DataExchDef.DeleteAll();
        DataExchLineDef.DeleteAll();
        DataExchField.DeleteAll();
        DataExchFieldMapping.DeleteAll();
        DataExchColumnDef.DeleteAll();
        DataExchMapping.DeleteAll();
        Commit();

        CreateDataExchDef(DataExchDef, DataExchDef.Type::"Generic Export", DataExchDef."File Type"::"Variable Text");
        CreateDataExchLineDef(DataExchDef, DataExchLineDef);
        CreateDataExchColumnDef(DataExchColumnDef, DataExchLineDef);
        CreateDataExchMapping(DataExchMapping, DataExchLineDef, DATABASE::"Gen. Journal Line");
        CreateDataExchFieldMapping(DataExchFieldMapping, DataExchMapping);

        if not TransformationRule.Get('EUCOUNTRYCODELOOKUP') then begin
            TransformationRule.CreateRule('EUCOUNTRYCODELOOKUP', 'EU Country Lookup', Enum::"Transformation Rule Type"::"Field Lookup", 0, 0, '', '');
            TransformationRule.Get('EUCOUNTRYCODELOOKUP');
        end;
        TransformationRule."Table ID" := 9;
        TransformationRule."Source Field ID" := 1;
        TransformationRule."Target Field ID" := 2;
        TransformationRule."Field Lookup Rule" := TransformationRule."Field Lookup Rule"::Target;
        TransformationRule.Modify();

        if not TransformationRule.Get('ROUNDTOINT') then begin
            TransformationRule.CreateRule('ROUNDTOINT', 'Round to int', Enum::"Transformation Rule Type"::Round, 0, 0, '', '');
            TransformationRule.Get('ROUNDTOINT');
        end;
        TransformationRule.Precision := 1.00;
        TransformationRule.Direction := '=';
        TransformationRule.Modify();
    end;

    local procedure CheckDataExchField(var DataExchField: Record "Data Exch. Field"; FieldName: Text; FieldValue: Text)
    begin
        Assert.AreEqual(FieldName, DataExchField.GetFieldName(), WrongDataExchFieldNameErr);
        Assert.AreEqual(FieldValue, DataExchField.GetValue(), WrongDataExchFieldValueErr);
    end;

    local procedure CreateGenJournalLines()
    var
        GenJourrnalLine: Record "Gen. Journal Line";
    begin
        GenJourrnalLine.DeleteAll();

        GenJourrnalLine.Init();
        GenJourrnalLine."Line No." := 10000;
        GenJourrnalLine."Country/Region Code" := 'DK';
        GenJourrnalLine.Amount := 100;
        GenJourrnalLine.Insert();

        GenJourrnalLine.Init();
        GenJourrnalLine."Line No." := 20000;
        GenJourrnalLine."Country/Region Code" := 'DK';
        GenJourrnalLine.Amount := 200;
        GenJourrnalLine.Insert();
    end;

    local procedure CreateGenJournalLinesWithDecimal()
    var
        GenJourrnalLine: Record "Gen. Journal Line";
    begin
        GenJourrnalLine.DeleteAll();

        GenJourrnalLine.Init();
        GenJourrnalLine."Line No." := 10000;
        GenJourrnalLine."Country/Region Code" := 'DK';
        GenJourrnalLine.Amount := 100.6;
        GenJourrnalLine.Insert();

        GenJourrnalLine.Init();
        GenJourrnalLine."Line No." := 20000;
        GenJourrnalLine."Country/Region Code" := 'DK';
        GenJourrnalLine.Amount := 200.1;
        GenJourrnalLine.Insert();
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; ParamaterType: Enum "Data Exchange Definition Type"; FileType: Option)
    begin
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef."File Type" := FileType;
        DataExchDef.Validate(Type, ParamaterType);
        DataExchDef."Reading/Writing Codeunit" := Codeunit::"Data Exch Mock Read Write";
        DataExchDef."Ext. Data Handling Codeunit" := 1277;
        DataExchDef.Insert(true);
    end;

    local procedure CreateDataExchLineDef(var DataExchDef: Record "Data Exch. Def"; var DataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExchLineDef.Init();
        DataExchLineDef."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef.Code := LibraryUtility.GenerateRandomCode(DataExchLineDef.FieldNo(Code), DATABASE::"Data Exch. Line Def");
        DataExchLineDef."Column Count" := 3;
        DataExchLineDef.Insert();
    end;

    local procedure CreateDataExchColumnDef(var DataExchColumnDef: Record "Data Exch. Column Def"; DataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColumnDef."Column No." := 1;
        DataExchColumnDef.Length := 10;
        DataExchColumnDef.Name := 'Line No';
        DataExchColumnDef.Insert();

        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColumnDef."Column No." := 2;
        DataExchColumnDef.Length := 10;
        DataExchColumnDef.Name := 'Country Code';
        DataExchColumnDef.Insert();

        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchColumnDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColumnDef."Column No." := 3;
        DataExchColumnDef.Length := 10;
        DataExchColumnDef.Name := 'Amount';
        DataExchColumnDef.Insert();
    end;

    local procedure CreateDataExchMapping(var DataExchMapping: Record "Data Exch. Mapping"; DataExchLineDef: Record "Data Exch. Line Def"; TableID: Integer)
    begin
        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping."Table ID" := TableID;
        DataExchMapping."Mapping Codeunit" := Codeunit::"Export Mapping";
        DataExchMapping.Insert();
    end;

    local procedure CreateDataExchFieldMapping(var DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchMapping: Record "Data Exch. Mapping")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Journal Line Number
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchFieldMapping."Table ID" := DataExchMapping."Table ID";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchFieldMapping."Column No." := 1;

        RecRef.Open(DataExchFieldMapping."Table ID");
        FieldRef := RecRef.Field(2);
        DataExchFieldMapping."Field ID" := FieldRef.Number;
        DataExchFieldMapping.Insert();
        RecRef.Close();

        // Country Code
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchFieldMapping."Table ID" := DataExchMapping."Table ID";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchFieldMapping."Column No." := 2;
        DataExchFieldMapping.Optional := true;

        RecRef.Open(DataExchFieldMapping."Table ID");
        FieldRef := RecRef.Field(120);
        DataExchFieldMapping."Field ID" := FieldRef.Number;
        DataExchFieldMapping.Insert();
        RecRef.Close();

        // Amount
        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchFieldMapping."Table ID" := DataExchMapping."Table ID";
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchFieldMapping."Column No." := 3;

        RecRef.Open(DataExchFieldMapping."Table ID");
        FieldRef := RecRef.Field(13);
        DataExchFieldMapping."Field ID" := FieldRef.Number;
        DataExchFieldMapping.Insert();

    end;

    local procedure CreateDataExchFieldGrouping(var DataExchMapping: Record "Data Exch. Mapping"; TableID: Integer)
    var
        DataExchFieldGrouping: Record "Data Exch. Field Grouping";
    begin
        DataExchFieldGrouping.DeleteAll();
        DataExchFieldGrouping.Init();
        DataExchFieldGrouping."Data Exch. Def Code" := DataExchMapping."Data Exch. Def Code";
        DataExchFieldGrouping."Data Exch. Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        DataExchFieldGrouping."Table ID" := TableID;
        DataExchFieldGrouping."Field ID" := 120;
        DataExchFieldGrouping.Insert();
    end;

}

