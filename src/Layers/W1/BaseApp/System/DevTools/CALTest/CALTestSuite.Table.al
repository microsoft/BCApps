namespace System.TestTools.TestRunner;

using System.IO;
using System.Utilities;

table 130400 "CAL Test Suite"
{
    Caption = 'CAL Test Suite';
    DataCaptionFields = Name, Description;
    LookupPageID = "CAL Test Suites";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Tests to Execute"; Integer)
        {
            CalcFormula = count("CAL Test Line" where("Test Suite" = field(Name),
                                                       "Line Type" = const(Function),
                                                       Run = const(true)));
            Caption = 'Tests to Execute';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Tests not Executed"; Integer)
        {
            CalcFormula = count("CAL Test Line" where("Test Suite" = field(Name),
                                                       "Line Type" = const(Function),
                                                       Run = const(true),
                                                       Result = const(" ")));
            Caption = 'Tests not Executed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Failures; Integer)
        {
            CalcFormula = count("CAL Test Line" where("Test Suite" = field(Name),
                                                       "Line Type" = const(Function),
                                                       Run = const(true),
                                                       Result = const(Failure)));
            Caption = 'Failures';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Last Run"; DateTime)
        {
            Caption = 'Last Run';
            Editable = false;
        }
        field(8; Export; Boolean)
        {
            Caption = 'Export';
        }
        field(21; Attachment; BLOB)
        {
            Caption = 'Attachment';
        }
        field(23; "Update Test Coverage Map"; Boolean)
        {
            Caption = 'Update Test Coverage Map';
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
        CALTestLine: Record "CAL Test Line";
    begin
        CALTestLine.SetRange("Test Suite", Name);
        CALTestLine.DeleteAll(true);
    end;

    var
        CALTestSuiteXML: XMLport "CAL Test Suite";
        CALTestResultsXML: XMLport "CAL Test Results";
        CouldNotExportErr: Label 'Could not export Unit Test XML definition.', Locked = true;
        UTTxt: Label 'UT', Locked = true;

    [Scope('OnPrem')]
    procedure ExportTestSuiteSetup()
    var
        CALTestSuite: Record "CAL Test Suite";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OStream: OutStream;
    begin
        TempBlob.CreateOutStream(OStream);
        CALTestSuite.SetRange(Name, Name);

        CALTestSuiteXML.SetDestination(OStream);
        CALTestSuiteXML.SetTableView(CALTestSuite);

        if not CALTestSuiteXML.Export() then
            Error(CouldNotExportErr);

        FileMgt.ServerTempFileName('*.xml');
        FileMgt.BLOBExport(TempBlob, UTTxt + Name, true);
    end;

    [Scope('OnPrem')]
    procedure ImportTestSuiteSetup()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        IStream: InStream;
    begin
        FileMgt.BLOBImport(TempBlob, '*.xml');
        TempBlob.CreateInStream(IStream);
        CALTestSuiteXML.SetSource(IStream);
        CALTestSuiteXML.Import();
    end;

    [Scope('OnPrem')]
    procedure ExportTestSuiteResult()
    var
        CALTestSuite: Record "CAL Test Suite";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OStream: OutStream;
    begin
        TempBlob.CreateOutStream(OStream);
        CALTestSuite.SetRange(Name, Name);

        CALTestResultsXML.SetDestination(OStream);
        CALTestResultsXML.SetTableView(CALTestSuite);

        if not CALTestResultsXML.Export() then
            Error(CouldNotExportErr);

        FileMgt.ServerTempFileName('*.xml');
        FileMgt.BLOBExport(TempBlob, UTTxt + Name, true);
    end;

    [Scope('OnPrem')]
    procedure ImportTestSuiteResult()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        IStream: InStream;
    begin
        FileMgt.BLOBImport(TempBlob, '*.xml');
        TempBlob.CreateInStream(IStream);
        CALTestResultsXML.SetSource(IStream);
        CALTestResultsXML.Import();
    end;
}

