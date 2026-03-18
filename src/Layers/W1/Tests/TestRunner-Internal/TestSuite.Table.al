table 130020 "Test Suite"
{
    DataCaptionFields = Name, Description;
    LookupPageID = "Test Suites";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
        }
        field(3; "Tests to Execute"; Integer)
        {
            CalcFormula = count("Test Line" where("Test Suite" = field(Name),
                                                   "Line Type" = const(Function),
                                                   Run = const(true)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Tests not Executed"; Integer)
        {
            CalcFormula = count("Test Line" where("Test Suite" = field(Name),
                                                   "Line Type" = const(Function),
                                                   Run = const(true),
                                                   Result = const(" ")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Failures; Integer)
        {
            CalcFormula = count("Test Line" where("Test Suite" = field(Name),
                                                   "Line Type" = const(Function),
                                                   Run = const(true),
                                                   Result = const(Failure)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Last Run"; DateTime)
        {
            Editable = false;
        }
        field(8; Export; Boolean)
        {
        }
        field(9; "Show Test Details"; Boolean)
        {
            Editable = false;
        }
        field(21; Attachment; BLOB)
        {
        }
        field(22; "Re-run Failing Codeunits"; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TestLine: Record "Test Line";
    begin
        TestLine.SetRange("Test Suite", Name);
        TestLine.DeleteAll(true);
    end;

    var
        Text000: Label 'Could not export Unit Test XML definition.';
        Text004: Label 'UT';
        ImportTxt: Label 'Import';
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*';
        ExportImportTestSuiteSetupXML: XMLport "Export/Import Test Suite";
        ExportImportTestSuiteResultXML: XMLport "Export/Import Test SuiteResult";
        FileName: Text;

    [Scope('OnPrem')]
    procedure ExportTestSuiteSetup()
    var
        TestSuite: Record "Test Suite";
        OStream: OutStream;
    begin
        Attachment.CreateOutStream(OStream);
        TestSuite.SetRange(Name, Name);

        ExportImportTestSuiteSetupXML.SetDestination(OStream);
        ExportImportTestSuiteSetupXML.SetTableView(TestSuite);

        if not ExportImportTestSuiteSetupXML.Export() then
            Error(Text000);

        Attachment.Export(Text004 + Name);
    end;

    [Scope('OnPrem')]
    procedure ImportTestSuiteSetup()
    var
        IStream: InStream;
    begin
        FileName := '*.xml';
        UploadIntoStream(ImportTxt, '', AllFilesDescriptionTxt, FileName, IStream);
        ExportImportTestSuiteSetupXML.SetSource(IStream);
        ExportImportTestSuiteSetupXML.Import();
    end;

    [Scope('OnPrem')]
    procedure ExportTestSuiteResult()
    var
        TestSuite: Record "Test Suite";
        OStream: OutStream;
    begin
        Attachment.CreateOutStream(OStream);
        TestSuite.SetRange(Name, Name);

        ExportImportTestSuiteResultXML.SetDestination(OStream);
        ExportImportTestSuiteResultXML.SetTableView(TestSuite);

        if not ExportImportTestSuiteResultXML.Export() then
            Error(Text000);

        Attachment.Export(Text004 + Name);
    end;

    [Scope('OnPrem')]
    procedure ImportTestSuiteResult()
    var
        IStream: InStream;
    begin
        FileName := '*.xml';
        UploadIntoStream(ImportTxt, '', AllFilesDescriptionTxt, FileName, IStream);
        ExportImportTestSuiteResultXML.SetSource(IStream);
        ExportImportTestSuiteResultXML.Import();
    end;
}

