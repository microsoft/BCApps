codeunit 132543 "Data Exch. Def UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [UT]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        Assert: Codeunit Assert;
        LibraryXMLRead: Codeunit "Library - XML Read";
        DefaultTxt: Label 'DEFAULT', Comment = 'Please translate';
        ServerFileName: Text;
        AssertIsNotTrueOnInsertFailedErr: Label 'The record should be inserted.';

    [Test]
    [Scope('OnPrem')]
    procedure InsertDataExchDef()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup
        DataExchDefCard.OpenNew();
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard.OK().Invoke();

        // Verify
        DataExchDef.Get(DataExchCode);
        DataExchDef.TestField(Name, DataExchDef.Code);
        DataExchLineDef.Get(DataExchDef.Code, DefaultTxt);
        DataExchLineDef.TestField(Code, DefaultTxt);
        DataExchLineDef.TestField(Name, DefaultTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDataExchDef()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup
        DataExchDefCard.OpenNew();
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard.OK().Invoke();
        DataExchDef.Get(DataExchCode);

        // Pre-Verify
        Assert.IsTrue(DataExchLineDef.Get(DataExchDef.Code, DefaultTxt), '');

        // Exercise
        DataExchDef.Delete(true);

        // Verify
        Assert.IsFalse(DataExchLineDef.Get(DataExchDef.Code, DefaultTxt), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableIsNonXMLFileType()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");
        // Verify
        Assert.IsTrue(DataExchDef.CheckEnableDisableIsNonXMLFileType(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableIsImportTypePaymentExport()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Init
        DataExchDef."File Type" := DataExchDef."File Type"::"Variable Text";

        // Setup
        DataExchDef.Validate(Type, DataExchDef.Type::"Payment Export");

        // Verify
        Assert.IsFalse(DataExchDef.CheckEnableDisableIsImportType(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableIsImportTypePayrollImport()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        DataExchDef.Validate(Type, DataExchDef.Type::"Payroll Import");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::Xml);

        // Verify
        Assert.IsFalse(DataExchDef.CheckEnableDisableIsImportType(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEnableDisableDelimitedFileType()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");

        // Verify
        Assert.IsTrue(DataExchDef.CheckEnableDisableDelimitedFileType(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLineDefititionsForImportAreAllowed()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef1: Record "Data Exch. Line Def";
        DataExchLineDef2: Record "Data Exch. Line Def";
    begin
        // Pre-Setup
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Insert(true);

        // Setup
        DataExchLineDef1.Init();
        DataExchLineDef1."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef1.Code := LibraryUtility.GenerateGUID();
        DataExchLineDef1.Insert(true);

        // Exercise
        DataExchLineDef2.Init();
        DataExchLineDef2."Data Exch. Def Code" := DataExchDef.Code;
        DataExchLineDef2.Code := LibraryUtility.GenerateGUID();
        DataExchLineDef2.Insert(true);

        // Verify: no error was raised.
    end;

    [Test]
    [HandlerFunctions('MappingPageHandler')]
    [Scope('OnPrem')]
    procedure SetCustomType()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping, DATABASE::"Bank Acc. Reconciliation", 1);
        DataExchDefCard.OpenNew();
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard.OK().Invoke();

        DataExchDef.Get(DataExchCode);
        DataExchDef.Type := "Data Exchange Definition Type".FromInteger(1000);
        DataExchDef.Modify();

        // Verify - Check is done in handler
        DataExchDefCard.OpenView();
        DataExchDefCard.GotoRecord(DataExchDef);

        DataExchDefCard."Line Definitions"."Field Mapping".Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MappingPageHandler(var MappingPage: TestPage "Data Exch Mapping Card")
    begin
        Assert.AreEqual(0, MappingPage."Table ID".AsInteger(), 'There must be no default mapping for custom Types');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineTypesAreCreatedInTable()
    var
        DataExchLineType: Option Detail,Header,Footer;
    begin
        // Scenario 1: New Data Exch. Line Type can be set on the page and is saved correctly.
        ValidateUISavesLineType(DataExchLineType::Header);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineTypesExport()
    var
        DataExchLineType: Option Detail,Header,Footer;
    begin
        // Scenario 2: Export of Data Exchange Definition correctly captures the new Line Type field value
        ValidateExportOfLineType(DataExchLineType::Header);
        ValidateExportOfLineType(DataExchLineType::Detail);
        ValidateExportOfLineType(DataExchLineType::Footer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLineTypesImport()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef1: Record "Data Exch. Line Def";
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
        DataExchCode: Code[20];
        DataExchLineType: Option Detail,Header,Footer;
        LineTypeCount: Integer;
    begin
        // Secnario 3: Import of Data Exchange Definition correctly recreates new Line Type field values
        // Pre-Setup
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchCode := DataExchDef.Code;
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef.Insert(true);

        InsertLineTypeRecords(DataExchCode, DataExchLineType::Header, '');
        InsertLineTypeRecords(DataExchCode, DataExchLineType::Detail, '');
        InsertLineTypeRecords(DataExchCode, DataExchLineType::Footer, '');

        // Export Data Exch Def with 3 line records via XML1225 to file BLAH
        DataExchDef.SetRange(Code, DataExchCode);
        ServerFileName := FileManagement.ServerTempFileName('.xml');

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream, DataExchDef);
        ExportFile.Close();

        // Remove Header and Line Records just saved.
        RemoveDataExch(DataExchCode);

        // Import file via XML1225
        ImportViaXMLPort(DataExchDef);

        // Verify that there are 3 records in 1227 table with different Line Types.
        LineTypeCount := 1;
        DataExchLineDef1.SetRange("Data Exch. Def Code", DataExchCode);
        if DataExchLineDef1.FindSet() then
            repeat
                case LineTypeCount of
                    1:
                        DataExchLineDef1.TestField("Line Type", DataExchLineType::Header);
                    2:
                        DataExchLineDef1.TestField("Line Type", DataExchLineType::Detail);
                    3:
                        DataExchLineDef1.TestField("Line Type", DataExchLineType::Footer);
                end;

                LineTypeCount := LineTypeCount + 1;
            until DataExchLineDef1.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLinesImportWhenDescendantGoesFirstAlphabetically()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        FileManagement: Codeunit "File Management";
        DataExchLineType: Option Detail,Header,Footer;
        ParentCode: Code[20];
    begin
        // [SCENARIO 381089] When descendant Data Exch. Def. Line goes before parent alphabetically, then export and import of such Data Exch. Def. should not cause an error

        // [GIVEN] Data Exch. Def.
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID());
        DataExchDef.Validate(Type, DataExchDef.Type::"Bank Statement Import");
        DataExchDef.Insert(true);

        // [GIVEN] Data Exch. Def. Line ZZZ, which surely be last alphabetically
        InsertLineTypeRecords(DataExchDef.Code, DataExchLineType::Detail, 'Z');
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindLast();
        ParentCode := DataExchLineDef.Code;

        // [GIVEN] Data Exch. Def. Line AAA, which surely be 1st alphabetically and has ZZZ as "Parent Code"
        InsertLineTypeRecords(DataExchDef.Code, DataExchLineType::Detail, 'A');
        DataExchLineDef.FindFirst();
        DataExchLineDef.Validate("Parent Code", ParentCode);
        DataExchLineDef.Modify(true);

        // [GIVEN] Export Data Exch Def with 2 lines via XMLPort "Imp / Exp Data Exch Def & Map" to file
        DataExchDef.SetRecFilter();
        ServerFileName := FileManagement.ServerTempFileName('.xml');

        ExportViaXMLPort(DataExchDef);

        // [GIVEN] Data Exch. Def. header and lines are deleted
        RemoveDataExch(DataExchDef.Code);

        // [WHEN] Import file via XMLPort "Imp / Exp Data Exch Def & Map"
        ImportViaXMLPort(DataExchDef);

        // [THEN] There are 2 records in "Data Exch. Line Def" table and no errors appeared
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        Assert.RecordCount(DataExchLineDef, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnModifyDefinitionCheckPositivePayExportFileTypeFixedText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] When the Data Exch. Def. "Type" has value of "Positive Pay Export", then the "File Type" can be changed to "Fixed Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition inserted
        // [GIVEN] Validating "Type" as "Positive Pay Export" and "File Type" as "Fixed Text"
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID());
        DataExchDef.Insert(true);
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");

        // [WHEN] Modify the record
        DataExchDef.Modify(true);

        // [THEN] The record is modified and "File Type" as "Fixed Text" is saved
        DataExchDef.Find();
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Fixed Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnModifyDefinitionCheckPositivePayExportFileTypeVariableText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] When the Data Exch. Def. "Type" has value of "Positive Pay Export", then the "File Type" can be changed to "Variable Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition inserted
        // [GIVEN] Validating "Type" as "Positive Pay Export" and "File Type" as "Variable Text" and modify the record
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID());
        DataExchDef.Insert(true);
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");

        // [WHEN] Modify the record
        DataExchDef.Modify(true);

        // [THEN] The record is modified and "File Type" as "Variable Text" is saved
        DataExchDef.Find();
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Variable Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnInsertDefinitionCheckPositivePayExportFileTypeFixedText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] A newly created Data Exch. Def. with "Type" of "Positive Pay Export" can have "File Type" as "Fixed Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition
        // [GIVEN] Validate "Type" as "Positive Pay Export" and "File Type" as "Fixed Text"
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID());
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Fixed Text");

        // [WHEN] Insert a record
        DataExchDef.Insert(true);

        // [THEN] The record is inserted with "File Type" as "Fixed Text"
        Assert.IsTrue(DataExchDef.Find(), AssertIsNotTrueOnInsertFailedErr);
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Fixed Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnInsertDefinitionCheckPositivePayExportFileTypeVariableText()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381084] A newly created Data Exch. Def. with "Type" of "Positive Pay Export" can have "File Type" as "Variable Text"
        // Updated Test Coverage from TFSID 122828 Test that the user can create a "Positive Pay Export" type Data Exchange Definition

        // [GIVEN] Empty Data Exch. Definition
        // [GIVEN] Validate "Type" as "Positive Pay Export" and "File Type" as "Variable Text"
        DataExchDef.Init();
        DataExchDef.Validate(Code, LibraryUtility.GenerateGUID());
        DataExchDef.Validate(Type, DataExchDef.Type::"Positive Pay Export");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");

        // [WHEN] Insert a record
        DataExchDef.Insert(true);

        // [THEN] The record is inserted with "File Type" as "Variable Text"
        Assert.IsTrue(DataExchDef.Find(), AssertIsNotTrueOnInsertFailedErr);
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Variable Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExhangeDefinitionImportInsertsRuleFromNextTransformationRuleField()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchMapping: Record "Data Exch. Mapping";
        TransformationRule: array[2] of Record "Transformation Rule";
        FileManagement: Codeunit "File Management";
    begin
        // [FEATURE] [Transformation Rule]
        // [SCENARIO 361509] Data Exhange Definition XMLPort import inserts rules from "Next Transformation Rule" field.

        // [GIVEN] Transformation Rules T1 and T2, with T1 having "Next Transformation Rule" = T2.
        CreateTransformationRule(TransformationRule[1]);
        CreateTransformationRule(TransformationRule[2]);
        TransformationRule[1].Validate("Next Transformation Rule", TransformationRule[2].Code);
        TransformationRule[1].Modify(true);

        // [GIVEN] Data Exhange Definition using T1.
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping2(DataExchDef, DataExchMapping, DataExchFieldMapping, DATABASE::Customer, 1);
        DataExchFieldMapping.Validate("Transformation Rule", TransformationRule[1].Code);
        DataExchFieldMapping.Modify(true);

        // [GIVEN] Data Exhange Definition is exported to xml.
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        DataExchDef.SetRecFilter();
        ExportViaXMLPort(DataExchDef);

        // [GIVEN] Data Exhange Definition, T1 and T2 are deleted.
        RemoveDataExch(DataExchDef.Code);
        TransformationRule[1].Delete();
        TransformationRule[2].Delete();

        // [WHEN] Data Exhange Definition is imported from xml.
        ImportViaXMLPort(DataExchDef);

        // [THEN] T2 was imported.
        Assert.IsTrue(TransformationRule[2].Find(), '');
    end;

    [Test]
    procedure ImportDataExchangeXmlDataWithSeveralColumnsWithSamePath()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
    begin
        // [FEAUTRE] [XML] [Import]
        // [SCENARIO 396422] Data Exchange Xml Import in case of several columns with the same path

        // [GIVEN] Data exchange definition setup for import xml
        MockDataExchDef(DataExchDef, DataExchDef.Type::"Generic Import", DataExchDef."File Type"::Xml);

        // [GIVEN] Single line definition with "Data Line Tag" = '/root'
        MockDataExchLineDef(DataExchLineDef, DataExchDef.Code, DataExchLineDef."Line Type"::Detail, '/root');

        // [GIVEN] Two column definitions each with the same "Path" = '/root/testnode'
        MockDataExchColDef(DataExchColDef, DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, 1, '/root/testnode');
        MockDataExchColDef(DataExchColDef, DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, 2, '/root/testnode');

        // [WHEN] Import xml file containing "<root> <testnode> testvalue </testnode> </root>"
        DataExchField."Data Exch. No." :=
            ImportXmlFromText(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, '<root><testnode>testvalue</testnode></root>');

        // [THEN] There are 3 data exch. fields have been created: 1 "root" (parent line def) and 2 columns ("testvalue")
        DataExchField.SetRange("Data Exch. No.", DataExchField."Data Exch. No.");
        Assert.RecordCount(DataExchField, 3);

        DataExchField.SetRange("Column No.", -1);
        Assert.RecordCount(DataExchField, 1);

        DataExchField.SetRange("Column No.", 1);
        DataExchField.FindFirst();
        DataExchField.TestField(Value, 'testvalue');

        DataExchField.SetRange("Column No.", 2);
        DataExchField.FindFirst();
        DataExchField.TestField(Value, 'testvalue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExhangeDefinitionImportConservesCustomColumSeparatorField()
    var
        DataExchDef: Record "Data Exch. Def";
        FileManagement: Codeunit "File Management";
        OldCustomColumnSeparator: Text[10];
    begin
        // [SCENARIO 416979] Data Exhange Definition XMLPort import conserves value of "Custom Column Separator" field

        // [GIVEN] Data Exhange Definition exists
        MockDataExchDef(DataExchDef, DataExchDef.Type::"Generic Import", DataExchDef."File Type"::Xml);

        // [GIVEN] Data Exhange Definition has "Custom Column Separator"
        OldCustomColumnSeparator := LibraryUtility.GenerateGUID();
        DataExchDef.Validate("Column Separator", DataExchDef."Column Separator"::Custom);
        DataExchDef.Validate("Custom Column Separator", OldCustomColumnSeparator);
        DataExchDef.Modify(true);

        // [GIVEN] Data Exhange Definition is exported to xml.
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        DataExchDef.SetRecFilter();
        ExportViaXMLPort(DataExchDef);

        // [GIVEN] Data Exhange Definition is deleted.
        RemoveDataExch(DataExchDef.Code);

        // [WHEN] Data Exhange Definition is imported from xml.
        ImportViaXMLPort(DataExchDef);

        // [THEN] Imported Data Exchange Definitaion has "Custom Column Separator" = XXX
        DataExchDef.FindFirst();
        DataExchDef.TestField("Custom Column Separator", OldCustomColumnSeparator);
    end;

    local procedure MockDataExchDef(var DataExchDef: Record "Data Exch. Def"; Type: Enum "Data Exchange Definition Type"; FileType: Option)
    begin
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef.Type := Type;
        DataExchDef."File Type" := FileType;
        DataExchDef.Insert(true);
    end;

    local procedure MockDataExchLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDefCode: Code[20]; LineType: Option; DataLineTag: Text[250])
    begin
        DataExchLineDef.Init();
        DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchLineDef.Code := LibraryUtility.GenerateGUID();
        DataExchLineDef."Line Type" := LineType;
        DataExchLineDef."Data Line Tag" := DataLineTag;
        DataExchLineDef.Insert(true);
    end;

    local procedure MockDataExchColDef(var DataExchColDef: Record "Data Exch. Column Def"; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; Path: Text[250])
    begin
        DataExchColDef.Init();
        DataExchColDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchColDef."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExchColDef."Column No." := ColumnNo;
        DataExchColDef.Path := Path;
        DataExchColDef.Insert(true);
    end;

    local procedure CreateTransformationRule(var TransformationRule: Record "Transformation Rule")
    begin
        TransformationRule.Init();
        TransformationRule.Code := LibraryUtility.GenerateRandomCode(TransformationRule.FieldNo(Code), DATABASE::"Transformation Rule");
        TransformationRule.Insert();
    end;

    local procedure ExportViaXMLPort(var DataExchDef: Record "Data Exch. Def")
    var
        ExportFile: File;
        OutStream: OutStream;
    begin
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream, DataExchDef);
        ExportFile.Close();
    end;

    local procedure ImportViaXMLPort(var DataExchDef: Record "Data Exch. Def")
    var
        InputFile: File;
        InStream: InStream;
    begin
        InputFile.Open(ServerFileName);
        InputFile.CreateInStream(InStream);
        XMLPORT.Import(XMLPORT::"Imp / Exp Data Exch Def & Map", InStream, DataExchDef);
    end;

    local procedure ImportXmlFromText(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; SourceText: Text): Integer
    var
        DataExch: Record "Data Exch.";
        OutStream: OutStream;
    begin
        DataExch."Entry No." := LibraryUtility.GetNewRecNo(DataExch, DataExch.FieldNo("Entry No."));
        DataExch."Data Exch. Def Code" := DataExchDefCode;
        DataExch."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExch."File Content".CreateOutStream(OutStream);
        OutStream.WriteText(SourceText);
        DataExch.Insert(true);
        DataExch.SetRecFilter();
        Codeunit.Run(Codeunit::"Import XML File to Data Exch.", DataExch);
        exit(DataExch."Entry No.");
    end;

    local procedure RemoveDataExch(DataExchDefCode: Code[20])
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchDef.SetRange(Code, DataExchDefCode);
        DataExchDef.DeleteAll(true);

        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.DeleteAll(true);
    end;

    local procedure ValidateExportOfLineType(LineType: Option Detail,Header,Footer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
        DataExchCode: Code[20];
        OptionNumber: Integer;
    begin
        // Setup for Line Type validation
        MockDataExchDef(DataExchDef, DataExchDef.Type::"Bank Statement Import", DataExchDef."File Type"::Xml);
        DataExchCode := DataExchDef.Code;
        OptionNumber := LineType;

        MockDataExchLineDef(DataExchLineDef, DataExchDef.Code, OptionNumber, '');

        // Export Data Exch Def with Header Type line record via XML1225 to XML file
        DataExchDef.SetRange(Code, DataExchCode);
        ServerFileName := FileManagement.ServerTempFileName('.xml');

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream, DataExchDef);
        ExportFile.Close();

        // Verify that element in XML file with <LineType> tag of Header.
        LibraryXMLRead.Initialize(FileManagement.DownloadTempFile(ServerFileName));
        LibraryXMLRead.VerifyAttributeValueInSubtree('DataExchDef', 'DataExchLineDef', 'LineType', Format(OptionNumber));
    end;

    local procedure ValidateUISavesLineType(DataExchLineType: Option Detail,Header,Footer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
        DataExchCode: Code[20];
    begin
        // Setup for Detail Line Type
        DataExchDefCard.OpenNew();
        DataExchCode := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");

        // Exercise
        DataExchDefCard.Code.SetValue(DataExchCode);
        DataExchDefCard."Line Definitions"."Line Type".SetValue(DataExchLineType);
        DataExchDefCard.OK().Invoke();

        // Verify record saved, Line Type should equal Line Type passed in.
        DataExchDef.Get(DataExchCode);
        DataExchDef.TestField(Name, DataExchDef.Code);
        DataExchLineDef.Get(DataExchDef.Code, DefaultTxt);
        DataExchLineDef.TestField(Code, DefaultTxt);
        DataExchLineDef.TestField(Name, DefaultTxt);
        DataExchLineDef.TestField("Line Type", DataExchLineType);
    end;

    local procedure InsertLineTypeRecords(DataExchCode: Code[20]; DataExchLineType: Option Detail,Header,Footer; LineCodePrefix: Code[1])
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        // Setup
        DataExchLineDef.Init();
        DataExchLineDef.Code := LineCodePrefix + LibraryUtility.GenerateGUID();
        DataExchLineDef."Data Exch. Def Code" := DataExchCode;
        DataExchLineDef."Line Type" := DataExchLineType;
        DataExchLineDef."Column Count" := 1;
        DataExchLineDef.Insert(true);

        DataExchColDef.Init();
        DataExchColDef."Data Exch. Def Code" := DataExchCode;
        DataExchColDef."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchColDef."Column No." := 1;
        DataExchColDef.Name := 'Column1';
        DataExchColDef.Insert(true);

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchCode;
        DataExchMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchMapping."Table ID" := 271;
        DataExchMapping.Insert(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := DataExchLineDef.Code;
        DataExchFieldMapping."Table ID" := 271;
        DataExchFieldMapping."Column No." := 1;
        DataExchFieldMapping."Field ID" := 1;
        DataExchFieldMapping.Insert(true);
    end;
}

