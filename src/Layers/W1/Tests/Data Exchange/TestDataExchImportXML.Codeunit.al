codeunit 132547 "Test Data Exch.Import - XML"
{
    Permissions = TableData "Data Exch." = m;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [XML] [Import]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        AssertMsg: Label '%1 Field:"%2" different from expected.';
        TableErrorMsg: Label '%1 Line:%2';
        NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:camt.053.001.02';
        IncorrectNamespaceTxt: Label 'incorrect namespace';
        IncorrectNamespaceErr: Label 'The imported file contains unsupported namespace "%1". The supported namespace is ''%2''.', Comment = '%1=File XML Namespace,%2=Supported XML Namespace';
        LongValueIncorrectlyProcessedErr: Label 'Long value incorrectly processed.';

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileUTF8()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileUTF16()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-16', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.Unicode);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileUTF8NodeName()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.ModifyAll("Use Node Name as Value", true);

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'MsgId',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileUTF8NodeNameUsingXmlReader()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchColumnDef.ModifyAll("Use Node Name as Value", true);

        // Execute
        CODEUNIT.Run(CODEUNIT::"Import XML File to Data Exch.", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '00010001', 'MsgId',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Column No.", 1);
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileUTF8BigData()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobBigXml: Codeunit "Temp Blob";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobBigXml.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithBigXmlData(TempBlobBigXml, OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempBlobBigXml.CreateInStream(InStream);
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', Base64Convert.ToBase64(InStream),
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
        DataExchField.Get(DataExch."Entry No.", 0, 1, '0001000100010001');
        TempBlobBigXml.CreateInStream(InStream);
        Assert.AreEqual(Base64Convert.ToBase64(InStream), DataExchField.GetValue(), 'Big data mismatch!');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadRepeatedLineFromXMLFile()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithMultiLineBankStatement(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/Stmt/Ntry/Sts');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '00010002000200030001', 'BOOK',
          DataExch."Data Exch. Line Def Code");
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 2, 1, '00010002000300030001', 'PDNG',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadRepeatedElementFromXMLFile()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithRepeatedElement(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/Stmt/Bal/CdtDbtInd');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '00010002000200020001', 'CRDT',
          DataExch."Data Exch. Line Def Code");
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '00010002000300020001', 'CRDT',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadSubElementFromXMLFile()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/Stmt/Ntry/Sts');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '00010002000200030001', 'BOOK',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadSubElementWithAttributeFromXMLFile()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/Stmt/Ntry/Amt[@Ccy]');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '0001000200020001', 'SEK',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileWithNamedNamespace()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithNamedNamespace(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileWithNamespaceOverride()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithNamespaceOverride(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileWithInnerNamedNamespace()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithInnerNamedNamespace(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementFromXMLFileWithInnerDefaultNamespace()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithInnerDefaultNamespace(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadElementValueWithDataTypeMismatch()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithDataTypeMismatch(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/Stmt/Ntry/Amt');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 1, 1, '00010002000200010001', 'Hello, World!',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnorePreHeaderComment()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithPreHeaderComment(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreValuesInParentElement()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithTextValueInParentElement(OutStream, 'UTF-8');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        TempExpectedDataExchField.InsertRecXMLField(DataExch."Entry No.", 0, 1, '0001000100010001', 'AAAASESS-FP-STAT001',
          DataExch."Data Exch. Line Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreUnmappedColumns()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateDataExchDef(DataExchDef);
        CreateDataExchLineDef(DataExchLineDef, DataExchDef.Code, NamespaceTxt);
        CreateDataExch(DataExch, DataExchDef.Code, DataExchLineDef.Code, TempBlobUTF8);

        // Execute
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapToTableWithCodeKey()
    var
        Customer: Record Customer;
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        ProcessDataExch: Codeunit "Process Data Exch.";
        RecRef: RecordRef;
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        Reference: Text;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        Reference := LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer);
        WriteCAMTFileWithReference(OutStream, 'UTF-8', Reference);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/Stmt/Ntry/NtryRef');
        CreateDataExchMapping(DataExchMapping, DataExchDef, DATABASE::Customer, Customer.FieldNo(Name), 1);
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Exercise.
        RecRef.GetTable(Customer);
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindFirst();
        ProcessDataExch.ProcessColumnMapping(DataExch, DataExchLineDef, RecRef);

        // Verify.
        Customer.SetRange(Name, Reference);
        Customer.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapToTableBlob()
    var
        GLAccount: Record "G/L Account";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchField: Record "Data Exch. Field";
        TempBlobBigXml: Codeunit "Temp Blob";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        ProcessDataExch: Codeunit "Process Data Exch.";
        Base64Convert: Codeunit "Base64 Convert";
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        InStream: InStream;
        InStream2: InStream;
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Initialize
        GLAccount.DeleteAll();

        // Pre-Setup
        TempBlobBigXml.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithBigXmlData(TempBlobBigXml, OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');
        CreateDataExchMapping(DataExchMapping, DataExchDef, DATABASE::"G/L Account", GLAccount.FieldNo(Picture), 1);
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.FindLast();
        DataExchField.CalcFields("Value BLOB");
        DataExchField."Line No." += 1;
        DataExchField.Insert();

        // Exercise.
        RecRef.GetTable(GLAccount);
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindFirst();
        ProcessDataExch.ProcessColumnMapping(DataExch, DataExchLineDef, RecRef);

        // Verify.
        TempBlobBigXml.CreateInStream(InStream);
        GLAccount.FindFirst();
        GLAccount.CalcFields(Picture);
        GLAccount.Picture.CreateInStream(InStream2, TEXTENCODING::UTF8);
        Assert.AreEqual(
          Base64Convert.ToBase64(InStream), TypeHelper.ReadAsTextWithSeparator(InStream2, TypeHelper.CRLFSeparator()),
          'Big Xml Data does not match!');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapToTableBlobWithIntermediate()
    var
        GLAccount: Record "G/L Account";
        IntermediateDataImport: Record "Intermediate Data Import";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TempBlobBigXml: Codeunit "Temp Blob";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Initialize
        GLAccount.DeleteAll();

        // Pre-Setup
        TempBlobBigXml.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFileWithBigXmlData(TempBlobBigXml, OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateFormatDefinition(DataExch, DataExchDef, TempBlobUTF8, '/Document/BkToCstmrStmt/GrpHdr/MsgId');
        CreateDataExchMapping(DataExchMapping, DataExchDef, DATABASE::"Intermediate Data Import", 0, 1);
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchMapping.ModifyAll("Use as Intermediate Table", true);
        DataExchMapping.FindFirst();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.ModifyAll("Target Table ID", DATABASE::"G/L Account");
        DataExchFieldMapping.ModifyAll("Target Field ID", GLAccount.FieldNo(Picture));
        DataExchFieldMapping.FindFirst();

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Map DataExch To Intermediate", DataExch);

        // Verify.
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.FindFirst();
        TempBlobBigXml.CreateInStream(InStream);
        Assert.AreEqual(Base64Convert.ToBase64(InStream), IntermediateDataImport.GetValue(), 'Big Xml Data does not match!');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectEmptyXMLFile()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        TempBlob: Codeunit "Temp Blob";
    begin
        // Setup
        CreateDataExchDef(DataExchDef);
        CreateDataExch(DataExch, DataExchDef.Code, '', TempBlob);
        SetupSourceMock(DataExchDef, TempBlob);

        // Execute
        asserterror CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        Assert.ExpectedError('System.Xml.XmlDocument.Load failed');
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportFileContentWhenNoFileChosen()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
    begin
        // Setup
        CreateDataExchDef(DataExchDef);
        SetupEmptySourceMoq(DataExchDef);

        Assert.IsFalse(DataExch.ImportFileContent(DataExchDef), 'Unexpected return value if user fails to choose a source file.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestImportFileContentWhenFileChosen()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
        ReadFileContentStream: InStream;
        ReadTempBlobStream: InStream;
        FileContentTxt: Text;
        TempBlobTxt: Text;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', NamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateDataExchDef(DataExchDef);
        CreateDataExchLineDef(DataExchLineDef, DataExchDef.Code, NamespaceTxt);
        SetupSourceMock(DataExchDef, TempBlobUTF8);

        Assert.IsTrue(DataExch.ImportFileContent(DataExchDef), 'Unexpected return value if user chooses a source file.');
        DataExch."File Content".CreateInStream(ReadFileContentStream);
        ReadFileContentStream.ReadText(FileContentTxt);
        TempBlobUTF8.CreateInStream(ReadTempBlobStream);
        ReadTempBlobStream.ReadText(TempBlobTxt);
        Assert.AreEqual(FileContentTxt, TempBlobTxt, 'Unexpected file content after user chooses a source file.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNamespaceIsIncorrect()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', '');
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateDataExchDef(DataExchDef);
        // when an empty namespace is specified in the Data Exch Line Def, no namespace validation should be done
        CreateDataExchLineDef(DataExchLineDef, DataExchDef.Code, '');
        CreateDataExch(DataExch, DataExchDef.Code, DataExchLineDef.Code, TempBlobUTF8);

        // Execute & Verify
        // The validation is that no err is thrown
        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNamespaceIsNotDefined()
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlobOEM: Codeunit "Temp Blob";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        Encoding: DotNet Encoding;
    begin
        // Pre-Setup
        TempBlobOEM.CreateOutStream(OutStream);
        WriteCAMTFile(OutStream, 'UTF-8', IncorrectNamespaceTxt);
        ConvertEncoding(TempBlobOEM, TempBlobUTF8, Encoding.UTF8);

        // Setup
        CreateDataExchDef(DataExchDef);
        CreateDataExchLineDef(DataExchLineDef, DataExchDef.Code, NamespaceTxt);
        CreateDataExch(DataExch, DataExchDef.Code, DataExchLineDef.Code, TempBlobUTF8);

        // Execute
        asserterror CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", DataExch);

        // Verify
        Assert.ExpectedError(StrSubstNo(IncorrectNamespaceErr, IncorrectNamespaceTxt, NamespaceTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertFieldRecWithLongXMLNodeValue()
    var
        DataExchField: Record "Data Exch. Field";
        LongValue: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 124068] InsertRecXMLField with long XML Node Value

        // [GIVEN] Long text with length more that max length of the DataExchField.Value
        LongValue := PadStr(LibraryUtility.GenerateGUID(), MaxStrLen(DataExchField.Value), '0') + '0';

        // [WHEN] Run InsertRecXMLField function
        DataExchField.InsertRecXMLField(0, 0, 0, '', LongValue, '');
        DataExchField.Get(0, 0, 0, '');

        // [THEN] Extra symbols cut in DataExchField.Value
        Assert.AreEqual(
          CopyStr(LongValue, 1, MaxStrLen(DataExchField.Value)),
          DataExchField.Value,
          LongValueIncorrectlyProcessedErr);
    end;

    local procedure WriteCAMTFile(OutStream: OutStream; Encoding: Text; Namespace: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + Namespace + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithBigXmlData(TempBlobBigXml: Codeunit "Temp Blob"; OutStream: OutStream; Encoding: Text; Namespace: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
    begin
        TempBlobBigXml.CreateInStream(InStream);
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + Namespace + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>' + Base64Convert.ToBase64(InStream) + '</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithReference(OutStream: OutStream; Encoding: Text; Reference: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '        <NtryRef>' + Reference + '</NtryRef>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithMultiLineBankStatement(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="DKK">216789.61</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>PDNG</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithRepeatedElement(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">500000</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Bal>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">435678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '      </Bal>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithNamedNamespace(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:ns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <ns:BkToCstmrStmt>');
        WriteLine(OutStream, '    <ns:GrpHdr>');
        WriteLine(OutStream, '      <ns:MsgId>AAAASESS-FP-STAT001</ns:MsgId>');
        WriteLine(OutStream, '    </ns:GrpHdr>');
        WriteLine(OutStream, '    <ns:Stmt>');
        WriteLine(OutStream, '      <ns:Id>AAAASESS-FP-STAT001</ns:Id>');
        WriteLine(OutStream, '      <ns:Ntry>');
        WriteLine(OutStream, '        <ns:Amt Ccy="SEK">105678.50</ns:Amt>');
        WriteLine(OutStream, '        <ns:CdtDbtInd>CRDT</ns:CdtDbtInd>');
        WriteLine(OutStream, '        <ns:Sts>BOOK</ns:Sts>');
        WriteLine(OutStream, '      </ns:Ntry>');
        WriteLine(OutStream, '    </ns:Stmt>');
        WriteLine(OutStream, '  </ns:BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithNamespaceOverride(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + IncorrectNamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt xmlns:ns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '    <ns:GrpHdr>');
        WriteLine(OutStream, '      <ns:MsgId>AAAASESS-FP-STAT001</ns:MsgId>');
        WriteLine(OutStream, '    </ns:GrpHdr>');
        WriteLine(OutStream, '    <ns:Stmt>');
        WriteLine(OutStream, '      <ns:Id>AAAASESS-FP-STAT001</ns:Id>');
        WriteLine(OutStream, '      <ns:Ntry>');
        WriteLine(OutStream, '        <ns:Amt Ccy="SEK">105678.50</ns:Amt>');
        WriteLine(OutStream, '        <ns:CdtDbtInd>CRDT</ns:CdtDbtInd>');
        WriteLine(OutStream, '        <ns:Sts>BOOK</ns:Sts>');
        WriteLine(OutStream, '      </ns:Ntry>');
        WriteLine(OutStream, '    </ns:Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithInnerNamedNamespace(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
        WriteLine(OutStream, '  <BkToCstmrStmt xmlns:ns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '    <ns:GrpHdr>');
        WriteLine(OutStream, '      <ns:MsgId>AAAASESS-FP-STAT001</ns:MsgId>');
        WriteLine(OutStream, '    </ns:GrpHdr>');
        WriteLine(OutStream, '    <ns:Stmt>');
        WriteLine(OutStream, '      <ns:Id>AAAASESS-FP-STAT001</ns:Id>');
        WriteLine(OutStream, '      <ns:Ntry>');
        WriteLine(OutStream, '        <ns:Amt Ccy="SEK">105678.50</ns:Amt>');
        WriteLine(OutStream, '        <ns:CdtDbtInd>CRDT</ns:CdtDbtInd>');
        WriteLine(OutStream, '        <ns:Sts>BOOK</ns:Sts>');
        WriteLine(OutStream, '      </ns:Ntry>');
        WriteLine(OutStream, '    </ns:Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithInnerDefaultNamespace(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
        WriteLine(OutStream, '  <BkToCstmrStmt xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithDataTypeMismatch(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">Hello, World!</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithPreHeaderComment(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream, '<?Hello World?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt>');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteCAMTFileWithTextValueInParentElement(OutStream: OutStream; Encoding: Text)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="' + Encoding + '"?>');
        WriteLine(OutStream,
          '<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="' + NamespaceTxt + '">');
        WriteLine(OutStream, '  <BkToCstmrStmt>');
        WriteLine(OutStream, '    <GrpHdr>');
        WriteLine(OutStream, '      <MsgId>AAAASESS-FP-STAT001</MsgId>');
        WriteLine(OutStream, '    </GrpHdr>');
        WriteLine(OutStream, '    <Stmt> Hello, World! ');
        WriteLine(OutStream, '      <Id>AAAASESS-FP-STAT001</Id>');
        WriteLine(OutStream, '      <Ntry>');
        WriteLine(OutStream, '        <Amt Ccy="SEK">105678.50</Amt>');
        WriteLine(OutStream, '        <CdtDbtInd>CRDT</CdtDbtInd>');
        WriteLine(OutStream, '        <Sts>BOOK</Sts>');
        WriteLine(OutStream, '      </Ntry>');
        WriteLine(OutStream, '    </Stmt>');
        WriteLine(OutStream, '  </BkToCstmrStmt>');
        WriteLine(OutStream, '</Document>');
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    local procedure ConvertEncoding(TempBlobSource: Codeunit "Temp Blob"; var TempBlobDestination: Codeunit "Temp Blob"; Encoding: DotNet Encoding)
    var
        Writer: DotNet StreamWriter;
        InStream: InStream;
        OutStream: OutStream;
        EncodedText: Text;
    begin
        TempBlobSource.CreateInStream(InStream);
        TempBlobDestination.CreateOutStream(OutStream);

        Writer := Writer.StreamWriter(OutStream, Encoding);

        while 0 <> InStream.ReadText(EncodedText) do
            Writer.WriteLine(EncodedText);

        Writer.Close();
    end;

    local procedure SetupSourceMock(var DataExchDef: Record "Data Exch. Def"; TempBlob: Codeunit "Temp Blob")
    begin
        AddTempBlobToList(TempBlob);

        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef.Modify();
    end;

    local procedure SetupEmptySourceMoq(var DataExchDef: Record "Data Exch. Def")
    var
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
    begin
        ErmPeSourceTestMock.ClearTempBlobList();
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Empty Source Test mock";
        DataExchDef.Modify();
    end;

    local procedure CreateFormatDefinition(var DataExch: Record "Data Exch."; var DataExchDef: Record "Data Exch. Def"; TempBlob: Codeunit "Temp Blob"; Path: Text[250])
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        CreateDataExchDef(DataExchDef);
        CreateDataExchLineDef(DataExchLineDef, DataExchDef.Code, NamespaceTxt);
        CreateDataExch(DataExch, DataExchDef.Code, DataExchLineDef.Code, TempBlob);
        DataExchColumnDef.InsertRecordForImport(
            DataExchDef.Code, DataExchLineDef.Code, 1,
            LibraryUtility.GenerateGUID(), '', false, DataExchColumnDef."Data Type"::Text, '', '');
        DataExchColumnDef.Path := Path;
        DataExchColumnDef.Modify(true);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def")
    begin
        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def");
        DataExchDef.Type := DataExchDef.Type::"Bank Statement Import";
        DataExchDef."File Encoding" := DataExchDef."File Encoding"::"UTF-8";
        DataExchDef."File Type" := DataExchDef."File Type"::Xml;
        DataExchDef."Reading/Writing Codeunit" := CODEUNIT::"Import Bank Statement";
        DataExchDef.Insert();
    end;

    local procedure CreateDataExchLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDefCode: Code[20]; ExpectedNamespace: Text[250])
    begin
        DataExchLineDef.InsertRec(DataExchDefCode, LibraryUtility.GenerateGUID(), '', 0);
        DataExchLineDef."Data Line Tag" := '/Document/BkToCstmrStmt/Stmt/Ntry';
        DataExchLineDef.Namespace := ExpectedNamespace;
        DataExchLineDef.Modify(true);
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDefCode);
        DataExch."Data Exch. Line Def Code" := DataExchLineDefCode;
        DataExch.Modify(true);
    end;

    local procedure CreateDataExchMapping(var DataExchMapping: Record "Data Exch. Mapping"; DataExchDef: Record "Data Exch. Def"; TableId: Integer; FieldId: Integer; ColumnNo: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.FindFirst();
        DataExchMapping.InsertRecForImport(DataExchDef.Code, DataExchLineDef.Code,
          TableId, DataExchDef.Code, 0, 0);
        DataExchFieldMapping.InsertRec(DataExchDef.Code, DataExchLineDef.Code,
          TableId, ColumnNo, FieldId, false, 0);
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

    local procedure AddTempBlobToList(var TempBlob: Codeunit "Temp Blob")
    var
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
        TempBlobList: Codeunit "Temp Blob List";
    begin
        ErmPeSourceTestMock.GetTempBlobList(TempBlobList);
        TempBlobList.Add(TempBlob);
    end;
}

