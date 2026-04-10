codeunit 132540 "Test Data Exch.Import - CSV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Import] [CSV]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        ALongTxt: Label '250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..250 char long text and ..';
        TableErrorMsg: Label '%1 Line:%2';
        AssertMsg: Label '%1 Field:"%2" different from expected.';
        LastLineIsHeaderErr: Label 'The imported file contains unexpected formatting. One or more lines may be missing in the file.';
        WrongHeaderErr: Label 'The imported file contains unexpected formatting. One or more headers are incorrect.';

    [Test]
    [Scope('OnPrem')]
    procedure TestImportComma()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Field ABC, FieldABC ');
        WriteLine(OutStream, 'Field;)(%&/#!#%,Field`?=?`ÅØ^Å:_>.');
        WriteLine(OutStream, '"Field2",Field1');
        WriteLine(OutStream, '"Field2",' + ALongTxt + ALongTxt);

        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Comma);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);

        // Execute
        TempBlobANSI.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Field ABC', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'FieldABC', ''); // Leading and trailing speces will be removed
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 1, 'Field;)(%&/#!#%', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 2, 'Field`?=?`ÅØ^Å:_>.', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 3, 1, 'Field2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 3, 2, 'Field1', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 4, 1, 'Field2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 4, 2, ALongTxt, '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportSemicolon()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Field,)(%&/#!#%;Field`?=?`ÅØ^Å:_>.');

        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);

        // Execute
        TempBlobANSI.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Field,)(%&/#!#%', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'Field`?=?`ÅØ^Å:_>.', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportTab()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        Tab: Text;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        Tab[1] := 9;
        WriteLine(OutStream, ConvertStr('Field,)(%&/#!#%;Field`?=?`ÅØ^Å:_>.', ';', Tab));

        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Tab);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);

        // Execute
        TempBlobANSI.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Field,)(%&/#!#%', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'Field`?=?`ÅØ^Å:_>.', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportSpace()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Field,)(%&/#!#% "Field`?=?`ÅØ^Å:_ >."');

        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Space);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);

        // Execute
        TempBlobANSI.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Field,)(%&/#!#%', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'Field`?=?`ÅØ^Å:_ >.', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportCustom()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Field,)(%&/#!#%+Field`?=?`ÅØ^Å:_ >.');

        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Custom);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);

        // Execute
        TempBlobANSI.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Field,)(%&/#!#%', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'Field`?=?`ÅØ^Å:_ >.', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportOEM()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Field ABC, FieldABC ');
        WriteLine(OutStream, 'Field;)(%&/#!#%,Field`?=?`ÅØ^Å:_>.');
        WriteLine(OutStream, '"Field2",Field1');
        WriteLine(OutStream, '"Field2",' + ALongTxt + ALongTxt);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Comma);
        DataExchDef."File Encoding" := DataExchDef."File Encoding"::"MS-DOS";
        DataExchDef.Modify();

        CreateDataExch(DataExch, DataExchDef.Code, TempBlobOEM);

        // Execute
        TempBlobOEM.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'Field ABC', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'FieldABC', ''); // Leading and trailing speces will be removed
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 1, 'Field;)(%&/#!#%', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 2, 'Field`?=?`ÅØ^Å:_>.', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 3, 1, 'Field2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 3, 2, 'Field1', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 4, 1, 'Field2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 4, 2, ALongTxt, '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithHeaderLines()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobANSI: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Column1 Header;Column2 Header');
        WriteLine(OutStream, 'AnyData;AnyData');

        ConvertOEMToANSI(TempBlobOEM, TempBlobANSI);

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, '', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlobANSI);

        // Execute
        TempBlobANSI.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithHeaderLinesAndHeaderTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData;AnyData');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithMultipleHeaderLinesAndHeaderTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header1');
        WriteLine(OutStream, 'HeaderTag2;Column2 Header2');
        WriteLine(OutStream, 'AnyData;AnyData');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, 'HeaderTag2', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(WrongHeaderErr);
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'Expect no data in the table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithHeaderTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData;AnyData');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithHeaderTagMismatch()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTagMismatch;Column2 Header');
        WriteLine(OutStream, 'AnyData;AnyData');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'HeaderTagMismatch', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'Column2 Header', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithHeaderTagAndFooterTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData;AnyData');
        WriteLine(OutStream, 'FooterTag;Column2 Footer');

        CreateDataExchDef(
          DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, 'HeaderTag', 'FooterTag', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithHeaderLinesAndFooterTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'Column1 Header;Column2 Header');
        WriteLine(OutStream, 'AnyData;AnyData');
        WriteLine(OutStream, 'FooterTag;Column2 Footer');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, '', 'FooterTag', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithFooterTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'AnyData;AnyData');
        WriteLine(OutStream, 'FooterTag;Column2 Footer');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', 'FooterTag', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWithFooterTagMismatch()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'AnyData;AnyData');
        WriteLine(OutStream, 'FooterTagMismatch;Column2 Footer');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', 'FooterTag', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 1, 'FooterTagMismatch', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 2, 'Column2 Footer', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");

        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportEmptyDocument()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        // Setup
        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Comma);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        Clear(TempBlob);
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify
        Assert.ExpectedErrorCode('XmlPortData');
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImport94Columns()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        i: Integer;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        for i := 1 to 94 do
            OutStream.WriteText(StrSubstNo('Value Column %1,', i));

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, '', '', DataExchDef."Column Separator"::Comma);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.FindSet();
        i := 0;
        repeat
            i += 1;
            Assert.AreEqual(1, DataExchField."Line No.", 'Line no incorrect');
            Assert.AreEqual(i, DataExchField."Column No.", 'Column no incorrect');
            Assert.AreEqual(StrSubstNo('Value Column %1', i), DataExchField.Value, 'Value incorrect');
        until DataExchField.Next() = 0;
        Assert.AreEqual(94, i, 'Column count does not match');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportExtraHeadersInSequence()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData11;AnyData12');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header'); // The extra header
        WriteLine(OutStream, 'AnyData21;AnyData22');

        CreateDataExchDef(
          DataExchDef, XMLPORT::"Data Exch. Import - CSV", 3, 'HeaderTag', 'FooterTag', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(LastLineIsHeaderErr);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportLessHeadersInSequence()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData11;AnyData12');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData21;AnyData22');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 3, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(LastLineIsHeaderErr);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportHeaderAtEndWithoutLines()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');
        WriteLine(OutStream, 'AnyData1;AnyData2');
        WriteLine(OutStream, 'HeaderTag;Column2 Header');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(LastLineIsHeaderErr);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportOnlyHeaderWithoutLines()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2 Header');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(LastLineIsHeaderErr);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportNoHeaders()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'AnyData11;AnyData12');
        WriteLine(OutStream, 'AnyData21;AnyData22');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, 'HeaderTag', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(WrongHeaderErr);
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'Expect no data in the table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportWrongHeader()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column3 Header;Column2 Header;Column4 Header;Column5 Header');
        WriteLine(OutStream, 'AnyData1;AnyData2;AnyData3;AnyData4;AnyData5');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, 'HeaderTag;Column2 Header;Column3 Header;', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        asserterror XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        Assert.ExpectedError(WrongHeaderErr);
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'Expect no data in the table.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportLongHeaderTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, '012345678901234567890123456789HeaderTag;Column2 Header;Column3 Header;Column4 Header;Column5 Header');
        WriteLine(OutStream, 'AnyData1;AnyData2;AnyData3;AnyData4;AnyData5');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1,
          '012345678901234567890123456789HeaderTag;Column2 Header;Column3 Header;', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData1', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, 'AnyData3', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 4, 'AnyData4', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 5, 'AnyData5', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportLongFooterTag()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'AnyData1;AnyData2;AnyData3;AnyData4;AnyData5');
        WriteLine(OutStream, '012345678901234567890123456789FooterTag;Column2 Footer;Column3 Footer;Column4 Footer;Column5 Footer');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 0,
          '', '012345678901234567890123456789FooterTag;Column2 Footer;Column3 Footer;', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'AnyData1', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, 'AnyData3', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 4, 'AnyData4', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 5, 'AnyData5', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportHeaderSharingTextWithData()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Setup
        TempBlob.CreateOutStream(OutStream);
        WriteLine(OutStream, 'HeaderTag;Column2;XYZ;Column4;Column5');
        WriteLine(OutStream, 'XYZ;AnyData2;AnyData3;AnyData4;AnyData5');

        CreateDataExchDef(DataExchDef, XMLPORT::"Data Exch. Import - CSV", 1, 'HeaderTag;Column2;XYZ;', '', DataExchDef."Column Separator"::Semicolon);
        CreateDataExch(DataExch, DataExchDef.Code, TempBlob);

        // Execute
        TempBlob.CreateInStream(InStream);
        XMLPORT.Import(DataExchDef."Reading/Writing XMLport", InStream, DataExch);

        // Verify Table Layout
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'XYZ', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, 'AnyData2', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, 'AnyData3', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 4, 'AnyData4', '');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 5, 'AnyData5', '');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDefCode: Code[20]; TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDefCode);
        DataExch.SetRange("Entry No.", DataExch."Entry No.");
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; XMLPortId: Integer; HeaderLines: Integer; HeaderTag: Text[250]; FooterTag: Text[250]; ColumnSeparator: Option)
    begin
        DataExchDef.InsertRec(LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def"),
          LibraryUtility.GenerateGUID(), DataExchDef.Type::"Bank Statement Import", XMLPortId, HeaderLines, HeaderTag, FooterTag);
        DataExchDef."Column Separator" := ColumnSeparator;
        if DataExchDef."Column Separator" = DataExchDef."Column Separator"::Custom then
            DataExchDef."Custom Column Separator" := '+';
        DataExchDef.Modify();
    end;

    local procedure AssertDataInTable(var ExpectedDataExchField: Record "Data Exch. Field"; var ActualDataExchField: Record "Data Exch. Field"; Msg: Text)
    var
        LineNo: Integer;
    begin
        ExpectedDataExchField.FindFirst();
        ActualDataExchField.FindFirst();
        repeat
            LineNo += 1;
            AreEqualRecords(ExpectedDataExchField, ActualDataExchField, StrSubstNo(TableErrorMsg, Msg, LineNo));
        until (ExpectedDataExchField.Next() = 0) or (ActualDataExchField.Next() = 0);
        Assert.AreEqual(ExpectedDataExchField.Count, ActualDataExchField.Count, 'Row count does not match');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure AreEqualRecords(ExpectedRecord: Variant; ActualRecord: Variant; Msg: Text)
    var
        ExpectedRecRef: RecordRef;
        ActualRecRef: RecordRef;
        i: Integer;
    begin
        ExpectedRecRef.GetTable(ExpectedRecord);
        ActualRecRef.GetTable(ActualRecord);

        Assert.AreEqual(ExpectedRecRef.Number, ActualRecRef.Number, 'Tables are not the same');

        for i := 1 to ExpectedRecRef.FieldCount do
            if IsSupportedType(ExpectedRecRef.FieldIndex(i).Value) then
                Assert.AreEqual(ExpectedRecRef.FieldIndex(i).Value, ActualRecRef.FieldIndex(i).Value,
                  StrSubstNo(AssertMsg, Msg, ExpectedRecRef.FieldIndex(i).Name));
    end;

    local procedure IsSupportedType(Value: Variant): Boolean
    begin
        exit(Value.IsBoolean or
          Value.IsOption or
          Value.IsInteger or
          Value.IsDecimal or
          Value.IsText or
          Value.IsCode or
          Value.IsDate or
          Value.IsTime);
    end;

    local procedure ConvertOEMToANSI(TempBlobSource: Codeunit "Temp Blob"; var TempBlobDestination: Codeunit "Temp Blob")
    var
        Encoding: DotNet Encoding;
        Writer: DotNet StreamWriter;
        InStream: InStream;
        OutStream: OutStream;
        EncodedText: Text;
    begin
        TempBlobSource.CreateInStream(InStream);
        TempBlobDestination.CreateOutStream(OutStream);

        Writer := Writer.StreamWriter(OutStream, Encoding.GetEncoding(0));

        while 0 <> InStream.ReadText(EncodedText) do
            Writer.WriteLine(EncodedText);

        Writer.Close();
    end;
}

