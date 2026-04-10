codeunit 132573 "Payment Export XMLPort UT"
{
    Permissions = TableData "Data Exch." = i;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Export] [Data Exchange]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        MaxNoOfColumns: Integer;
        ColumnsNotSequentialErr: Label 'The data to be exported is not structured correctly. The columns in the dataset must be sequential.';
        FileDoesNotExistErr: Label 'File %1 does not exist.';
        ExportedDataIsWrongErr: Label 'The data from the export file does not match the expected value.';
        FieldDelimiter: Text[1];
        FieldSeparator: Text[1];
        LinesNotSequentialErr: Label 'The data to be exported is not structured correctly. The lines in the dataset must be sequential.';

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVNoData()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertDataExchLineWithHeader(DataExch, LibraryRandom.RandInt(MaxNoOfColumns));

        // Exercise
        DataExch."Entry No." := DataExch."Entry No." + 1; // Passing in a non-existing key.
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileIsEmpty(Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVSpecificDataset()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
        DataExchEntryNo: Integer;
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesVariableNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100));
        InsertMultipleDataExchLinesVariableNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100));
        DataExchEntryNo := DataExch."Entry No.";
        InsertMultipleDataExchLinesVariableNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100));

        // Exercise
        DataExch.Get(DataExchEntryNo);
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVOneLineOneColumn()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertDataExchLineWithHeader(DataExch, 1);

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVOneLineMultipleColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertDataExchLineWithHeader(DataExch, LibraryRandom.RandIntInRange(2, MaxNoOfColumns - 1));

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVOneLineMaxColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertDataExchLineWithHeader(DataExch, MaxNoOfColumns);

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVOneLineNonConsecutiveColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertDataExch(DataExch);
        InsertDataExchLineWithNonConsecutiveColumns(DataExch, MaxNoOfColumns);

        // Exercise
        asserterror ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        Assert.ExpectedError(ColumnsNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineOneColumn()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesFixedNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100), 1);

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineMultipleColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        // This test will verify that lines are cut off at right point, i.e. no trailing blank columns.

        Initialize();

        // Setup
        InsertMultipleDataExchLinesFixedNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100),
          LibraryRandom.RandIntInRange(2, MaxNoOfColumns - 1));

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineMaxColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesFixedNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100), MaxNoOfColumns);

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineTooManyColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesFixedNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100), MaxNoOfColumns + 1);

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineNonConsecutiveColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesFixedNoOfColumns(DataExch, LibraryRandom.RandIntInRange(1, 10),
          LibraryRandom.RandIntInRange(2, MaxNoOfColumns - 1));
        InsertDataExchLineWithNonConsecutiveColumns(DataExch, MaxNoOfColumns);
        InsertDataExchLine(DataExch, LibraryRandom.RandIntInRange(2, MaxNoOfColumns - 1));

        // Exercise
        asserterror ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        Assert.ExpectedError(ColumnsNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineVariableColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesVariableNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100));

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMultiLineVariableAndTooManyColumns()
    var
        DataExch: Record "Data Exch.";
        Filename: Text[1024];
    begin
        Initialize();

        // Setup
        InsertMultipleDataExchLinesVariableNoOfColumns(DataExch, LibraryRandom.RandIntInRange(2, 100));
        InsertDataExchLine(DataExch, MaxNoOfColumns + 1);
        InsertDataExchLine(DataExch, LibraryRandom.RandIntInRange(2, MaxNoOfColumns - 1));

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", Filename);

        // Verify
        VerifyFileContent(DataExch, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVSunshine()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        i: Integer;
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic CSV",
          DataExchDef."File Type"::"Variable Text");

        for i := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, i, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        VerifyOutput(InStream, ExportTextArray, TempBlob, DataExchDef.ColumnSeparatorChar(), '"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMissingInnerLines()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic CSV",
          DataExchDef."File Type"::"Variable Text");

        CreateDataExchFieldForLine(ExportTextArray, 1, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        CreateDataExchFieldForLine(ExportTextArray, 3, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(LinesNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMissingFirstLine()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic CSV",
          DataExchDef."File Type"::"Variable Text");

        CreateDataExchFieldForLine(ExportTextArray, 3, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(LinesNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMissingInnerColumns()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        i: Integer;
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic CSV",
          DataExchDef."File Type"::"Variable Text");

        for i := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, i, DataExch."Entry No.", 1, 2, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(ColumnsNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportCSVMissingFirstColumn()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        i: Integer;
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic CSV",
          DataExchDef."File Type"::"Variable Text");

        for i := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, i, DataExch."Entry No.", 2, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(ColumnsNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportFixedWSunshine()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        i: Integer;
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic Fixed Width",
          DataExchDef."File Type"::"Fixed Text");

        for i := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, i, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        VerifyOutput(InStream, ExportTextArray, TempBlob, '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportFixedWMissingInnerLines()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic Fixed Width",
          DataExchDef."File Type"::"Fixed Text");

        CreateDataExchFieldForLine(ExportTextArray, 1, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        CreateDataExchFieldForLine(ExportTextArray, 3, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(LinesNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportFixedWMissingFirstLine()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic Fixed Width",
          DataExchDef."File Type"::"Fixed Text");

        CreateDataExchFieldForLine(ExportTextArray, 3, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(LinesNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportFixedWMissingInnerColumns()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        i: Integer;
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic Fixed Width",
          DataExchDef."File Type"::"Fixed Text");

        for i := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, i, DataExch."Entry No.", 1, 2, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(ColumnsNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportFixedWMissingFirstColumn()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        i: Integer;
    begin
        // Setup
        SetupExport(TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic Fixed Width",
          DataExchDef."File Type"::"Fixed Text");

        for i := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, i, DataExch."Entry No.", 2, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // Execute
        TempBlob.CreateOutStream(OutStream);
        asserterror XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // Verify Stream Content.
        Assert.ExpectedError(ColumnsNotSequentialErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVariableTextWithSeparator()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        ExportTextArray: array[10, 100] of Text[250];
        CurrentColumnNo: Integer;
    begin
        // [SCENARIO 381084] Run Positive Pay Export through Data Exch. Definition where File Type is set as Variable Text with a Column Separator
        Initialize();

        // [GIVEN] DataExch. Definition with "File Type" as "Variable Text" and with "Column Separator" as "Comma"
        // [GIVEN] Mock data with text as an array of 100 columns and 10 lines
        SetupExport(
          TempBlob, DataExch, DataExchDef, ExportTextArray, XMLPORT::"Export Generic Fixed Width",
          DataExchDef."File Type"::"Variable Text");

        for CurrentColumnNo := 1 to ArrayLen(ExportTextArray, 1) do
            CreateDataExchFieldForLine(ExportTextArray, CurrentColumnNo, DataExch."Entry No.", 1, 1, ArrayLen(ExportTextArray, 2), '');
        DataExchField.Init();
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        // [WHEN] Export through XMLPORT "Export Generic Fixed Width"
        TempBlob.CreateOutStream(OutStream);
        XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutStream, DataExchField);

        // [THEN] Output with "Variable Text" with "Column Separator" char
        VerifyOutput(InStream, ExportTextArray, TempBlob, DataExchDef.ColumnSeparatorChar(), '');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        MaxNoOfColumns := 150;
        FieldDelimiter := '"';
        FieldSeparator := ',';
        IsInitialized := true;
    end;

    local procedure SetupExport(var TempBlobANSI: Codeunit "Temp Blob"; var DataExch: Record "Data Exch."; var DataExchDef: Record "Data Exch. Def"; var ExportTextArray: array[10, 100] of Text[250]; ProcessingXMLport: Integer; FileType: Option)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        CreateDataExchDef(DataExchDef, ProcessingXMLport, DataExchDef."Column Separator"::Comma, FileType);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);
        CreateExportData(ExportTextArray);
        DataExchLineDef.InsertRec(DataExchDef.Code, DataExchDef.Code, DataExchDef.Code, ArrayLen(ExportTextArray, 2));
    end;

    local procedure CreateExportData(var ExportText: array[10, 100] of Text[250])
    var
        FixedId: Text[250];
        i: Integer;
        j: Integer;
        NoOfColumns: Integer;
    begin
        FixedId := LibraryUtility.GenerateGUID();
        for i := 1 to ArrayLen(ExportText, 1) do begin
            NoOfColumns := LibraryRandom.RandIntInRange(65, ArrayLen(ExportText, 2));
            for j := 1 to 5 do
                ExportText[i] [j] := FixedId; // repeating info for each line.
            for j := 6 to NoOfColumns do
                ExportText[i] [j] := LibraryUtility.GenerateGUID() + 'æøåÆØÅ';
        end;
    end;

    local procedure CreateDataExchFieldForLine(ExportText: array[10, 10] of Text[250]; LineNo: Integer; DataExchEntryNo: Integer; FirstColumnIndex: Integer; SkipColumns: Integer; MaxNoOfColumns: Integer; DataExchLineDefNo: Code[20])
    var
        DataExchField: Record "Data Exch. Field";
        j: Integer;
    begin
        j := FirstColumnIndex;
        while j <= MaxNoOfColumns do begin
            if ExportText[LineNo] [j] <> '' then
                DataExchField.InsertRec(DataExchEntryNo, LineNo, j, ExportText[LineNo] [j], DataExchLineDefNo);
            j += SkipColumns;
        end;
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDefCode: Code[20]; TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDefCode);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; ProcessingXMLport: Integer; ColumnSeparator: Option; FileType: Option)
    begin
        DataExchDef.InsertRecForExport(LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def"),
          LibraryUtility.GenerateGUID(), DataExchDef.Type::"Payment Export".AsInteger(), ProcessingXMLport, FileType);
        DataExchDef."Column Separator" := ColumnSeparator;
        DataExchDef."File Encoding" := DataExchDef."File Encoding"::WINDOWS;
        DataExchDef.Modify();
    end;

    local procedure GetExpectedLine(ExportData: array[10, 100] of Text; LineNo: Integer; ColumnSeparator: Text; ColumnDelimiter: Text): Text
    var
        LineContent: Text;
        j: Integer;
    begin
        for j := 1 to ArrayLen(ExportData, 2) do
            if ExportData[LineNo, j] <> '' then
                LineContent += ColumnDelimiter + ExportData[LineNo, j] + ColumnDelimiter + ColumnSeparator;

        exit(CopyStr(LineContent, 1, StrLen(LineContent) - StrLen(ColumnSeparator)));
    end;

    local procedure InsertDataExch(var DataExch: Record "Data Exch.")
    begin
        DataExch."Entry No." := 0;
        DataExch.Insert();
    end;

    local procedure InsertDataExchLine(DataExch: Record "Data Exch."; NoOfColumns: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        i: Integer;
    begin
        DataExchField.Init();
        DataExchField."Data Exch. No." := DataExch."Entry No.";
        DataExchField."Line No." := FindLastDataExchLineNo(DataExch."Entry No.") + 1;
        for i := 1 to NoOfColumns do begin
            DataExchField."Column No." := i;
            DataExchField.Value := StrSubstNo('Line %1 - Column %2', DataExchField."Line No.", DataExchField."Column No.");
            DataExchField.Insert();
        end;
    end;

    local procedure InsertDataExchLineWithHeader(var DataExch: Record "Data Exch."; NoOfColumns: Integer)
    begin
        InsertDataExch(DataExch);
        InsertDataExchLine(DataExch, NoOfColumns)
    end;

    local procedure InsertDataExchLineWithNonConsecutiveColumns(DataExch: Record "Data Exch."; NoOfColumns: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        i: Integer;
    begin
        DataExchField.Init();
        DataExchField."Data Exch. No." := DataExch."Entry No.";
        DataExchField."Line No." := FindLastDataExchLineNo(DataExch."Entry No.") + 1;
        for i := 1 to NoOfColumns do
            if (i mod 2) = 1 then begin // only insert odd numbered columns
                DataExchField."Column No." := i;
                DataExchField.Value := StrSubstNo('Line %1 - Column %2', DataExchField."Line No.", DataExchField."Column No.");
                DataExchField.Insert();
            end;
    end;

    local procedure InsertMultipleDataExchLinesFixedNoOfColumns(var DataExch: Record "Data Exch."; NoOfLines: Integer; NoOfColumns: Integer)
    var
        i: Integer;
    begin
        InsertDataExch(DataExch);
        for i := 1 to NoOfLines do
            InsertDataExchLine(DataExch, NoOfColumns);
    end;

    local procedure InsertMultipleDataExchLinesVariableNoOfColumns(var DataExch: Record "Data Exch."; NoOfLines: Integer)
    var
        i: Integer;
    begin
        InsertDataExch(DataExch);
        for i := 1 to NoOfLines do
            InsertDataExchLine(DataExch, LibraryRandom.RandInt(MaxNoOfColumns));
    end;

    local procedure FindLastDataExchLineNo(DataExchNo: Integer): Integer
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        if DataExchField.FindLast() then;
        exit(DataExchField."Line No.")
    end;

    local procedure ExportDataExchToCSVFile(DataExchNo: Integer; var Filename: Text[1024])
    var
        DataExchField: Record "Data Exch. Field";
        FileManagement: Codeunit "File Management";
        ExportGenericCSV: XMLport "Export Generic CSV";
        ExportFile: File;
        OutStream: OutStream;
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        Filename := CopyStr(FileManagement.ServerTempFileName('csv'), 1, 1024);

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(Filename);
        ExportFile.CreateOutStream(OutStream);
        ExportGenericCSV.SetDestination(OutStream);
        ExportGenericCSV.SetTableView(DataExchField);
        ExportGenericCSV.Export();
        ExportFile.Close();
    end;

    local procedure VerifyFileContent(DataExch: Record "Data Exch."; Filename: Text[1024])
    var
        DataExchField: Record "Data Exch. Field";
        ExportFile: DotNet File;
        LinesRead: DotNet Array;
        DataExchLine: Text;
        LineNo: Integer;
    begin
        Assert.IsTrue(ExportFile.Exists(Filename), StrSubstNo(FileDoesNotExistErr, Filename));
        LinesRead := ExportFile.ReadAllLines(Filename);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin
            LineNo := DataExchField."Line No.";
            repeat
                if DataExchField."Line No." <> LineNo then begin
                    Assert.AreEqual(DataExchLine, LinesRead.GetValue(LineNo - 1), ExportedDataIsWrongErr);
                    DataExchLine := '';
                    LineNo := DataExchField."Line No.";
                end;
                if DataExchLine <> '' then
                    DataExchLine += FieldSeparator;
                DataExchLine += StrSubstNo('%1%2%3', FieldDelimiter, DataExchField.Value, FieldDelimiter);
            until DataExchField.Next() = 0;
            Assert.AreEqual(DataExchLine, LinesRead.GetValue(LineNo - 1), ExportedDataIsWrongErr);
        end;
        Assert.AreEqual(LineNo, LinesRead.Length, ExportedDataIsWrongErr)
    end;

    local procedure VerifyFileIsEmpty(Filename: Text[1024])
    var
        File: File;
    begin
        Assert.IsTrue(File.Open(Filename), StrSubstNo(FileDoesNotExistErr, Filename));
        Assert.AreEqual(0, File.Len, ExportedDataIsWrongErr);
    end;

    local procedure VerifyOutput(var InStream: InStream; ExportData: array[10, 100] of Text[250]; TempBlobANSI: Codeunit "Temp Blob"; ColumnSeparator: Text; FieldDelimiter: Text)
    var
        Reader: DotNet StreamReader;
        Encoding: DotNet Encoding;
        LineText: Text;
        i: Integer;
    begin
        TempBlobANSI.CreateInStream(InStream);
        Reader := Reader.StreamReader(InStream, Encoding.GetEncoding(0));
        for i := 1 to ArrayLen(ExportData, 1) do
            VerifyOutputForLine(Reader, ExportData, i, ColumnSeparator, FieldDelimiter);

        LineText := Reader.ReadLine();
        Assert.AreEqual('', LineText, 'There should be no more data in the stream after line ' + Format(i));
        Reader.Close();
    end;

    local procedure VerifyOutputForLine(var Reader: DotNet StreamReader; ExportData: array[10, 100] of Text[250]; LineNo: Integer; ColumnSeparator: Text; FieldDelimiter: Text)
    var
        LineText: Text;
    begin
        LineText := Reader.ReadLine();
        Assert.AreEqual(GetExpectedLine(ExportData, LineNo, ColumnSeparator, FieldDelimiter),
          LineText, 'Wrong export text on line ' + Format(LineNo));
    end;
}
