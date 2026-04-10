codeunit 132576 "OpenXML Management UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [OpenXML] [Spreadsheet] [UT]
    end;

    var
        Assert: Codeunit Assert;
        FileCannotBeSizeZeroErr: Label 'file cannot be size 0.';
        FileIsCorruptedErr: Label 'File contains corrupted data.';
        MissingXMLMapErr: Label 'The Excel workbook must contain an XML map.';
        VmlShapeAnchorTxt: Label '%1,15,%2,10,%3,31,%4,9', Locked = true;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure AddTable()
    var
        TempBlob: Codeunit "Temp Blob";
        OpenXMLManagement: Codeunit "OpenXML Management";
        WrkBkReader: DotNet WorkbookReader;
        WrkBkWriter: DotNet WorkbookWriter;
        WrkShtReader: DotNet WorksheetReader;
        WorksheetWriter: DotNet WorksheetWriter;
        "Table": DotNet Table;
        TableParts: DotNet TableParts;
        StartFromRowNo: Integer;
        ColumnsCount: Integer;
        RowsCount: Integer;
    begin
        // [GIVEN] The book with one sheet 'A'
        OpenXMLManagement.CreateBook(TempBlob, WrkBkWriter);
        WorksheetWriter := WrkBkWriter.FirstWorksheet;
        Assert.AreEqual('Sheet1', WorksheetWriter.Name, 'xml');

        // [WHEN] AddTable() of 5 columns and 10 rows starting from row 3
        StartFromRowNo := 3;
        ColumnsCount := 5;
        RowsCount := 10;
        OpenXMLManagement.AddTable(WorksheetWriter, StartFromRowNo, ColumnsCount, RowsCount, Table);
        OpenXMLManagement.CloseBook(WrkBkWriter);

        // [THEN] Table exists in the sheet 'A', where Name = 'Table1', ConnectionId = 1, Reference = 'A3:E13'
        OpenXMLManagement.OpenBook(TempBlob, WrkBkReader);
        WrkShtReader := WrkBkReader.GetWorksheetByName(WorksheetWriter.Name);
        Assert.IsTrue(OpenXMLManagement.FindTableDefinition(WrkShtReader, Table), 'FindTable');
        Assert.AreEqual('Table1', Format(Table.Name), 'Table.Name');
        Assert.AreEqual('1', Format(Table.ConnectionId), 'ConnectionId');
        Assert.AreEqual('A3:E13', Format(Table.Reference), 'Reference');
        // [THEN] AutoFilter with table's reference, TableStyleInfo='TableStyleMedium2', TableParts with one TablePart.
        Assert.IsFalse(IsNull(Table.AutoFilter), 'AutoFilter is null');
        Assert.AreEqual(Format(Table.Reference), Format(Table.AutoFilter.Reference), 'AutoFilter.Reference');
        Assert.IsFalse(IsNull(Table.TableStyleInfo), 'TableStyleInfo is null');
        Assert.AreEqual('TableStyleMedium2', Format(Table.TableStyleInfo.Name), 'TableStyleInfo.Name');
        TableParts := WrkShtReader.Worksheet.LastChild;
        Assert.AreEqual('1', Format(TableParts.Count), 'TableParts is null');
        Assert.IsFalse(IsNull(TableParts.FirstChild), 'TablePart is null');
        // [THEN] TableColumns, where Count = 5.
        Assert.IsFalse(IsNull(Table.TableColumns), 'TableColumns is null');
        Assert.AreEqual(Format(ColumnsCount), Format(Table.TableColumns.Count), 'TableColumns.count');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddTableWithTwoColumns()
    var
        TempBlob: Codeunit "Temp Blob";
        OpenXMLManagement: Codeunit "OpenXML Management";
        TableColumn: DotNet TableColumn;
        WrkBkReader: DotNet WorkbookReader;
        WrkBkWriter: DotNet WorkbookWriter;
        WrkShtReader: DotNet WorksheetReader;
        WorksheetWriter: DotNet WorksheetWriter;
        XmlColumnProperties: DotNet XmlColumnProperties;
        "Table": DotNet Table;
    begin
        // [GIVEN] The book with one sheet 'A'
        OpenXMLManagement.CreateBook(TempBlob, WrkBkWriter);
        WorksheetWriter := WrkBkWriter.FirstWorksheet;

        // [GIVEN] Table with 1 column
        OpenXMLManagement.AddTable(WorksheetWriter, 1, 1, 1, Table);
        // [WHEN] AddColumnHeader() with Name 'X'
        OpenXMLManagement.AddColumnHeader(WorksheetWriter, Table, 1, 'ColumnName1', TableColumn);
        OpenXMLManagement.AddColumnHeaderWithXPath(WorksheetWriter, Table, 1, 'ColumnName2', 'xsd:integer', '/x/y/z');
        OpenXMLManagement.CloseBook(WrkBkWriter);

        // [THEN] Table 'A' contains 1 column 'X'
        OpenXMLManagement.OpenBook(TempBlob, WrkBkReader);
        WrkShtReader := WrkBkReader.GetWorksheetByName(WorksheetWriter.Name);
        Assert.IsTrue(OpenXMLManagement.FindTableDefinition(WrkShtReader, Table), 'FindTable');
        TableColumn := Table.TableColumns.FirstChild;
        Assert.AreEqual('ColumnName1', Format(TableColumn.Name), 'Name of Col1');
        Assert.IsTrue(IsNull(TableColumn.XmlColumnProperties), 'XmlColumnProperties of Col1');
        TableColumn := Table.TableColumns.LastChild;
        Assert.AreEqual('ColumnName2', Format(TableColumn.Name), 'Name of Col2');
        XmlColumnProperties := TableColumn.XmlColumnProperties;
        Assert.AreEqual('/x/y/z', Format(XmlColumnProperties.XPath), 'XPath');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtractXMLSchemaIfNoMap()
    var
        TempBlob: Codeunit "Temp Blob";
        OpenXMLManagement: Codeunit "OpenXML Management";
        WrkBkWriter: DotNet WorkbookWriter;
    begin
        // [SCENARIO] Workbook must contain CustomXMLMappingsPart and MapInfo
        // [GIVEN] The book without CustomXMLMappingsPart
        OpenXMLManagement.CreateBook(TempBlob, WrkBkWriter);
        // [WHEN] ExtractXMLSchema()
        asserterror OpenXMLManagement.ExtractXMLSchema(WrkBkWriter.Workbook.WorkbookPart);
        // [THEN] Error: "The Excel workbook must contain an XML Map."
        Assert.ExpectedError(MissingXMLMapErr);

        // [GIVEN] Add CustomXMLMappingsPart, but without XML Map
        WrkBkWriter.AddCustomXmlMappingsPart();
        // [WHEN] ExtractXMLSchema()
        asserterror OpenXMLManagement.ExtractXMLSchema(WrkBkWriter.Workbook.WorkbookPart);
        // [THEN] Error: "The Excel workbook must contain an XML Map."
        Assert.ExpectedError(MissingXMLMapErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindTableDefinitionEmptyFile()
    var
        TempBlob: Codeunit "Temp Blob";
        OpenXMLManagement: Codeunit "OpenXML Management";
        WrkBkReader: DotNet WorkbookReader;
        WrkBkWriter: DotNet WorkbookWriter;
        WrkShtReader: DotNet WorksheetReader;
        WorksheetWriter: DotNet WorksheetWriter;
        "Table": DotNet Table;
    begin
        // [GIVEN] The book with one sheet 'A', no table
        OpenXMLManagement.CreateBook(TempBlob, WrkBkWriter);
        WorksheetWriter := WrkBkWriter.FirstWorksheet;
        OpenXMLManagement.CloseBook(WrkBkWriter);
        // [GIVEN] Open the book
        OpenXMLManagement.OpenBook(TempBlob, WrkBkReader);
        WrkShtReader := WrkBkReader.GetWorksheetByName(WorksheetWriter.Name);
        // [WHEN] FindTableDefinition() does fail
        Assert.IsFalse(OpenXMLManagement.FindTableDefinition(WrkShtReader, Table), 'FindTable should fail');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenBookZeroSize()
    var
        TempBlob: Codeunit "Temp Blob";
        OpenXMLManagement: Codeunit "OpenXML Management";
        WrkBkReader: DotNet WorkbookReader;
    begin
        Clear(TempBlob);
        asserterror OpenXMLManagement.OpenBook(TempBlob, WrkBkReader);
        Assert.ExpectedError(FileCannotBeSizeZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenBookCorruptedFile()
    var
        TempBlob: Codeunit "Temp Blob";
        OpenXMLManagement: Codeunit "OpenXML Management";
        WrkBkReader: DotNet WorkbookReader;
        OStream: OutStream;
    begin
        TempBlob.CreateOutStream(OStream);
        OStream.WriteText('<x:worksheet></x:worksheet>');
        asserterror OpenXMLManagement.OpenBook(TempBlob, WrkBkReader);
        Assert.ExpectedError(FileIsCorruptedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCommentAnchor()
    var
        OpenXMLManagement: Codeunit "OpenXML Management";
        VmlShapeXml: Text;
        ColumnID: Integer;
        RowID: Integer;
    begin
        // [SCENARIO 302111] Open XML Management creates VmlShapeXml with anchor for cell comment with bottom border coordinate
        ColumnID := LibraryRandom.RandIntInRange(5, 10);
        RowID := LibraryRandom.RandIntInRange(5, 10);
        VmlShapeXml := OpenXMLManagement.CreateCommentVmlShapeXml(ColumnID, RowID);
        Assert.IsSubstring(VmlShapeXml, StrSubstNo(VmlShapeAnchorTxt, ColumnID, RowID - 2, ColumnID + 2, RowID + 5));
    end;
}

