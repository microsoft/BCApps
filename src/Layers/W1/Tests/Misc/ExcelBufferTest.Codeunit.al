codeunit 139011 "Excel Buffer Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Excel Buffer]
    end;

    var
        Assert: Codeunit Assert;
        UnknownCellTypeError: Label 'Unknown cell type %1.';
        SheetNotFoundError: Label 'Error does not contain the sheet name %1. Actual: %2.';
        FileNotFoundError: Label 'Error does not contain the file name %1. Actual: %2.';
        FileManagement: Codeunit "File Management";
        SheetNameTok: Label 'Sheet1';
        LibraryUtility: Codeunit "Library - Utility";
        ExcelFile: File;

    [Test]
    [Scope('OnPrem')]
    procedure CloseExcelFileCreatesTheFileTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
    begin
        ExcelFile := CreateExcelFile(TempWriteExcelBuffer, 'Sheet 1');
        TempWriteExcelBuffer.CloseBook();

        Assert.IsTrue(Exists(ExcelFile), 'File ' + ExcelFile + ' not found');

        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultFileHasNoDataTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        TempReadExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        SheetName := 'Test Sheet 1';
        ExcelFile := CreateExcelFile(TempWriteExcelBuffer, SheetName);
        TempWriteExcelBuffer.CloseBook();
        ReadSheet(TempReadExcelBuffer, ExcelFile, SheetName);
        TempReadExcelBuffer.CloseBook();

        Assert.IsTrue(TempReadExcelBuffer.IsEmpty, 'Default file is not empty');

        Clear(TempWriteExcelBuffer);
        Clear(TempReadExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBookWithUnspecifiedSheetNameTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        asserterror TempExcelBuffer.CreateBook('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenFileWithUnspecifiedNameTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        asserterror TempExcelBuffer.OpenBook('', 'Sheet1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenFileWhenFileNotFoundTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        LastError: Text;
    begin
        asserterror TempExcelBuffer.OpenBook('File0023123123', 'Sheet2');

        LastError := GetLastErrorText;

        Assert.IsTrue(StrPos(LastError, 'File0023123123') <> 0, CopyStr(StrSubstNo(FileNotFoundError, 'File0023123123', LastError), 1, 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSheetWithUnspecifiedNameTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
    begin
        ExcelFile := CreateExcelFile(TempExcelBuffer, 'Sheet1');
        TempExcelBuffer.CloseBook();
        asserterror TempExcelBuffer.OpenBook(ExcelFile, '');

        Clear(TempExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenSheetWhenSheetNotFoundTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        LastError: Text;
    begin
        ExcelFile := CreateExcelFile(TempExcelBuffer, 'Sheet1');
        TempExcelBuffer.CloseBook();
        asserterror TempExcelBuffer.OpenBook(ExcelFile, 'Sheet2');

        LastError := GetLastErrorText;
        Assert.IsTrue(StrPos(LastError, 'Sheet2') <> 0, CopyStr(StrSubstNo(SheetNotFoundError, 'Sheet2', LastError), 1, 1024));

        Clear(TempExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SelectSheetNameSingleSheetTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text;
    begin
        ExcelFile := CreateExcelFile(TempExcelBuffer, 'Sheet 1');
        TempExcelBuffer.CloseBook();
        SheetName := TempExcelBuffer.SelectSheetsName(ExcelFile);
        Assert.AreEqual('Sheet 1', SheetName, 'Sheet name is not the expected one.');

        Clear(TempExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [HandlerFunctions('SelectSheetMPH')]
    [Scope('OnPrem')]
    procedure SelectSheetNameMultiSheetTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text;
    begin
        PopulateTableWithTextsAndInfo(TempExcelBuffer);
        ExcelFile := DumpDataToExcelFile(TempExcelBuffer, 'Sheet 1', '');
        TempExcelBuffer.CloseBook();
        SheetName := TempExcelBuffer.SelectSheetsName(ExcelFile);
        Assert.AreNotEqual('Sheet 1', SheetName, 'Sheet name is not the expected one.');

        Clear(TempExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [HandlerFunctions('SelectSheetMPH')]
    [Scope('OnPrem')]
    procedure CreateMultiSheetFromMultiTablesTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempExcelBuffer1: Record "Excel Buffer" temporary;
        TempExcelBuffer2: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text;
    begin
        // Initialize 3 Excel buffer tables.
        // TempExcelBuffer will be the main excel sheet.
        PopulateTableWithNumbers(TempExcelBuffer);
        PopulateTableWithDates(TempExcelBuffer1);
        PopulateTableWithNumbers(TempExcelBuffer2);

        // Save all 3 buffers to different sheets.
        ExcelFile := CreateExcelFile(TempExcelBuffer, 'Sheet 1');

        TempExcelBuffer.WriteSheet('', '', UserId);
        TempExcelBuffer.SelectOrAddSheet('Test Sheet numero due');
        TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer1);
        TempExcelBuffer.SelectOrAddSheet('Sheet 3');
        TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer2);
        TempExcelBuffer.CloseBook();

        // Validate
        SheetName := TempExcelBuffer.SelectSheetsName(ExcelFile);
        Clear(TempExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);

        Assert.AreEqual('Test Sheet numero due', SheetName, 'Sheet name is not the expected one.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNumbersPopulatedExcelIsReadTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        PopulateTableWithNumbers(TempWriteExcelBuffer);
        SheetName := 'Test Sheet Number';
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyDatesPopulatedExcelIsReadTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        PopulateTableWithDates(TempWriteExcelBuffer);
        SheetName := 'Test Sheet Dates';
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyTextsPopulatedExcelIsReadTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        PopulateTableWithTexts(TempWriteExcelBuffer);
        SheetName := 'Test Sheet Text';
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyTextsAndInfoPopulatedExcelIsReadTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        PopulateTableWithTextsAndInfo(TempWriteExcelBuffer);
        SheetName := 'Test Sheet Text and Info';
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyMixAndStylePopulatedExcelIsReadTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        PopulateTableWithMixAndStyling(TempWriteExcelBuffer);
        SheetName := 'Test Sheet Mix Style';
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongUserName()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        User: Record User;
        ExcelFile: Text;
        SheetName: Text[30];
        UserName: Text;
    begin
        PopulateTableWithNumbers(TempWriteExcelBuffer);
        SheetName := 'Test Sheet User Name';
        UserName := PadStr('', MaxStrLen(User."User Name"), '.');
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, UserName);

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        Clear(TempWriteExcelBuffer);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateFilePartialyOverwritesTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        TempUpdateExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
        RowNo: Integer;
        ColumnNo: Integer;
        Value: Decimal;
    begin
        PopulateTableWithNumbers(TempWriteExcelBuffer);
        SheetName := 'Update Test';
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        TempWriteExcelBuffer.FindLast();
        Value := 123.567;
        RowNo := TempWriteExcelBuffer."Row No." + 1;
        ColumnNo := TempWriteExcelBuffer."Column No." + 1;
        InsertColumn(TempUpdateExcelBuffer, RowNo, ColumnNo, Value, TempUpdateExcelBuffer."Cell Type"::Number);

        TempUpdateExcelBuffer.UpdateBook(ExcelFile, SheetName);
        TempUpdateExcelBuffer.WriteSheet('', '', '');
        TempUpdateExcelBuffer.CloseBook();

        Clear(TempUpdateExcelBuffer);
        Clear(TempWriteExcelBuffer);
        InsertColumn(TempWriteExcelBuffer, RowNo, ColumnNo, Value, TempWriteExcelBuffer."Cell Type"::Number);

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateFileWithUnspecifiedNameTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        asserterror TempExcelBuffer.UpdateBook('', 'Sheet1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateFileWhenFileNotFoundTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        LastError: Text;
    begin
        asserterror TempExcelBuffer.UpdateBook('File0023123123', 'Sheet2');

        LastError := GetLastErrorText;
        Assert.IsTrue(StrPos(LastError, 'File0023123123') <> 0, CopyStr(StrSubstNo(FileNotFoundError, 'File0023123123', LastError), 1, 1024));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSheetWithUnspecifiedNameTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
    begin
        ExcelFile := CreateExcelFile(TempExcelBuffer, 'Sheet1');
        TempExcelBuffer.CloseBook();
        asserterror TempExcelBuffer.UpdateBook(ExcelFile, '');
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSheetWhenSheetNotFoundTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        LastError: Text;
    begin
        ExcelFile := CreateExcelFile(TempExcelBuffer, 'Sheet1');
        TempExcelBuffer.CloseBook();
        asserterror TempExcelBuffer.UpdateBook(ExcelFile, 'Sheet2');

        LastError := GetLastErrorText;
        Assert.IsTrue(StrPos(LastError, 'Sheet2') <> 0, CopyStr(StrSubstNo(SheetNotFoundError, 'Sheet2', LastError), 1, 1024));
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateSheetFromStreamTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExcelStream: InStream;
        Value: Variant;
        FileName: Text;
    begin
        // [SCENARIO] An existing Excel File can be updated using Streams

        // [GIVEN] An Excel File as a Stream
        CreateExcelStream(ExcelStream);

        // [THEN] The file can be updated
        TempExcelBuffer.UpdateBookStream(ExcelStream, SheetNameTok, true);
        TempExcelBuffer.AddColumn('New Value', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.WriteSheet('', '', '');
        TempExcelBuffer.QuitExcel();
        TempExcelBuffer.UTgetGlobalValue('ExcelFile', Value);
        FileName := Format(Value);

        // Verify
        TempExcelBuffer.DeleteAll();
        Clear(TempExcelBuffer);
        TempExcelBuffer.OpenBook(FileName, SheetNameTok);
        TempExcelBuffer.ReadSheet();
        TempExcelBuffer.SetRange("Row No.", 1);
        TempExcelBuffer.SetRange("Column No.", 1);
        TempExcelBuffer.FindFirst();
        Assert.AreEqual('New Value', TempExcelBuffer."Cell Value as Text", 'Excel file was not updated');

        // Tear Down
        ExcelFile.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyFormulaValueIsNotReadTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        ExcelFile: Text;
        SheetName: Text[30];
    begin
        SheetName := 'Empty Value Formula Test';
        PopulateTableWithNumbers(TempWriteExcelBuffer);
        TempWriteExcelBuffer.AddColumn('SUM(A1,A2)', true, '', true, true, true, '', TempWriteExcelBuffer."Cell Type"::Number);
        ExcelFile := DumpDataToExcelFile(TempWriteExcelBuffer, SheetName, '');

        Clear(TempWriteExcelBuffer);
        TempWriteExcelBuffer.FindLast();
        TempWriteExcelBuffer.Delete();

        ValidateExcelFile(TempWriteExcelBuffer, ExcelFile, SheetName);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportFormulaToFilterTest()
    var
        TempWriteExcelBuffer: Record "Excel Buffer" temporary;
        HasError: Boolean;
    begin
        PopulateTableWithNumbers(TempWriteExcelBuffer);
        TempWriteExcelBuffer.AddColumn('1..10000000', true, '', true, true, true, '', TempWriteExcelBuffer."Cell Type"::Number);

        HasError := TempWriteExcelBuffer.ExportBudgetFilterToFormula(TempWriteExcelBuffer);
        Assert.IsFalse(HasError, 'The ExportBudgetFilterToFormula failed to export filters');

        Clear(TempWriteExcelBuffer);
        TempWriteExcelBuffer.FindLast();
        TempWriteExcelBuffer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertDateTimeInOADateToText()
    var
        ExcelBuffer: Record "Excel Buffer";
        LocalDateTime: DateTime;
        ExpectedDateTime: DateTime;
    begin
        LocalDateTime := ExcelBuffer.ConvertDateTimeDecimalToDateTime(0.91666666666666663);
        ExpectedDateTime := CreateDateTime(Today, 220000T);
        Assert.AreEqual(Format(DT2Time(ExpectedDateTime)), Format(DT2Time(LocalDateTime)), 'String is not converted correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertDateTimeInOADateToTextFalseUTC()
    var
        ExcelBuffer: Record "Excel Buffer";
        LocalDateTime: DateTime;
        ExpectedDateTime: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 338944] DateTime is read for Local settings, when set SetReadDateTimeInUtc=false
        ExcelBuffer.SetReadDateTimeInUtcDate(false);
        LocalDateTime := ExcelBuffer.ConvertDateTimeDecimalToDateTime(0.91666666666666663);
        ExpectedDateTime := CreateDateTime(Today, 220000T);
        Assert.AreEqual(Format(DT2Time(ExpectedDateTime)), Format(DT2Time(LocalDateTime)), 'String is not converted correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertDateTimeInOADateToTextTrueUTC()
    var
        ExcelBuffer: Record "Excel Buffer";
        UTCDateTime: DateTime;
        ExpectedDateTime: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 338944] DateTime is read in UTC format, when set SetReadDateTimeInUtc=true
        ExcelBuffer.SetReadDateTimeInUtcDate(true);
        UTCDateTime := ExcelBuffer.ConvertDateTimeDecimalToDateTime(0.91666666666666663);
        // The tests are run on a system with UTC time, so UTC time is the same as local time in the previous test
        ExpectedDateTime := CreateDateTime(18991230D, 220000T);
        Assert.AreEqual(ExpectedDateTime, UTCDateTime, 'String is not converted correct');
        ExcelBuffer.SetReadDateTimeInUtcDate(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNameValueLookupIsNotEditableUT()
    var
        NameValueLookupPage: TestPage "Name/Value Lookup";
    begin
        // [FEATURE] [UT] [UI] [Name/Value Lookup]
        // [SCENARIO 363552] "Name/Value Lookup" page should be not editable
        NameValueLookupPage.Trap();
        NameValueLookupPage.OpenNew();
        Assert.IsFalse(NameValueLookupPage.Editable(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateExcelFileWithEmptyValueOfCell()
    var
        ExcelBuffer: Record "Excel Buffer";
        ExcelFile: Text;
    begin
        // [SCENARIO 209190] Value of cell have to be updated if new value is empty ('') if PreserveDataOnUpdate = FALSE

        // [GIVEN] Excel file contains cell with value = 'Some value'
        ExcelBuffer.DeleteAll();
        ExcelBuffer.NewRow();
        PopulateRowWithTexts(ExcelBuffer, 1, 0);
        ExcelFile := DumpDataToExcelFile(ExcelBuffer, SheetNameTok, '');

        // [GIVEN] Updated excel buffer of cell from step above with value = ''
        ExcelBuffer.FindLast();
        ExcelBuffer."Cell Value as Text" := '';
        ExcelBuffer.Modify();

        // [WHEN] Update the cell with value = '' (Invoke UpdateBookExcel with PreserveDataOnUpdate = FALSE)
        ExcelBuffer.UpdateBookExcel(ExcelFile, SheetNameTok, false);
        ExcelBuffer.WriteSheet('', '', '');
        ExcelBuffer.CloseBook();

        // [THEN] Value of cell = ''
        ReadSheet(ExcelBuffer, ExcelFile, SheetNameTok);
        ExcelBuffer.TestField("Cell Value as Text", '');
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotUpdateExcelFileWithEmptyValueOfCell()
    var
        ExcelBuffer: Record "Excel Buffer";
        ExcelFile: Text;
        ExpectedResult: Text;
    begin
        // [SCENARIO 209190] Value of cell have to not be updated if new value is empty ('') if PreserveDataOnUpdate = TRUE

        // [GIVEN] Excel file contains cell with value = 'Some value'
        ExcelBuffer.DeleteAll();
        ExcelBuffer.NewRow();
        PopulateRowWithTexts(ExcelBuffer, 1, 0);
        ExcelFile := DumpDataToExcelFile(ExcelBuffer, SheetNameTok, '');

        // [GIVEN] Updated excel buffer of cell from step above with value = ''
        ExcelBuffer.FindLast();
        ExpectedResult := ExcelBuffer."Cell Value as Text";
        ExcelBuffer."Cell Value as Text" := '';
        ExcelBuffer.Modify();

        // [WHEN] Update the cell with value = '' (Invoke UpdateBookExcel with PreserveDataOnUpdate = TRUE)
        ExcelBuffer.UpdateBookExcel(ExcelFile, SheetNameTok, true);
        ExcelBuffer.WriteSheet('', '', '');
        ExcelBuffer.CloseBook();

        // [THEN] Value of cell = 'Some value'
        ReadSheet(ExcelBuffer, ExcelFile, SheetNameTok);
        ExcelBuffer.TestField("Cell Value as Text", ExpectedResult);
        FileManagement.DeleteServerFile(ExcelFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveAndLoadCellComment()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        WorksheetReader: DotNet WorksheetReader;
        WorkbookReader: DotNet WorkbookReader;
        ExcelFilePath: Text;
        ExpectedResult: array[2] of Text;
        Index: Integer;
    begin
        // [SCENARIO 274548] Stan can see cell's comment when export excel buffer to excel

        // [GIVEN] Excel buffer with two entries.
        // [GIVEN] First entry's comment = 'Hello'
        // [GIVEN] Second entry's comment = ' Stan!'
        for Index := 1 to 2 do begin
            TempExcelBuffer.Init();
            TempExcelBuffer.Validate("Row No.", Index);
            TempExcelBuffer.Validate("Column No.", Index);
            TempExcelBuffer."Cell Value as Text" := LibraryUtility.GenerateGUID();
            ExpectedResult[Index] := LibraryUtility.GenerateGUID();
            TempExcelBuffer.Comment := CopyStr(ExpectedResult[Index], 1, MaxStrLen(TempExcelBuffer.Comment));
            TempExcelBuffer.Insert();
        end;

        // [WHEN] Export excel buffer to excel
        ExcelFilePath := DumpDataToExcelFile(TempExcelBuffer, SheetNameTok, '');

        WorkbookReader := WorkbookReader.Open(ExcelFilePath);
        WorksheetReader := WorkbookReader.GetWorksheetByName(SheetNameTok);
        // remove author information
        WorksheetReader.Worksheet.WorksheetPart.WorksheetCommentsPart.Comments.FirstChild.Remove();

        // [THEN] Worksheet/WorksheetPart/WorksheetCommentsPart/Comments/InnerText = "Hello Stan!"
        // OpenXml path: Worksheet/WorksheetPart/WorksheetCommentsPart/Comments/Comment[i]/CommentText/Run/SpreadsheetText/InnerText
        Assert.AreEqual(
          ExpectedResult[1] + ExpectedResult[2],
          WorksheetReader.Worksheet.WorksheetPart.WorksheetCommentsPart.Comments.InnerText,
          '');

        WorkbookReader.Close();
        FileManagement.DeleteServerFile(ExcelFilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSheetNamesTest()
    var
        TempValueNameBuffer: Record "Name/Value Buffer" temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExcelFileStream: InStream;
    begin
        // [GIVEN] An example Excel file with 2 sheets as a base64 string
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(GetExampleFileBase64(), OutStream);
        TempBlob.CreateInStream(ExcelFileStream);
        // [WHEN] List of all sheet names is read
        TempExcelBuffer.GetSheetsNameListFromStream(ExcelFileStream, TempValueNameBuffer);
        // [THEN] Sheet name count should be 2
        Assert.AreEqual(2, TempValueNameBuffer.Count, 'Sheet count check failed');
        // [THEN] First sheet name should be 'Sheet1'
        TempValueNameBuffer.FindSet();
        Assert.AreEqual('Sheet1', TempValueNameBuffer.Value, 'First sheet name check failed');
        // [THEN] Second sheet name should be 'Sheet2'
        TempValueNameBuffer.Next();
        Assert.AreEqual('Sheet2', TempValueNameBuffer.Value, 'Second sheet name check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReadFromMultipleSheetsTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        ExcelFileStream: InStream;
        OutStream: OutStream;
    begin
        // [GIVEN] An example Excel file with 2 sheets as a base64 string
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(GetExampleFileBase64(), OutStream);
        TempBlob.CreateInStream(ExcelFileStream);
        // [WHEN] First sheet is read
        TempExcelBuffer.OpenBookStream(ExcelFileStream, 'Sheet1');
        TempExcelBuffer.ReadSheetContinous('Sheet1', false);
        // [THEN] Entries count should be 3
        Assert.AreEqual(3, TempExcelBuffer.Count, 'Sheet count check failed');
        // [THEN] First entry value should be 1
        TempExcelBuffer.FindFirst();
        Assert.AreEqual('1', TempExcelBuffer."Cell Value as Text", 'First entry value check failed');
        // [WHEN] Second sheet is read
        TempExcelBuffer.ReadSheetContinous('Sheet2', true);
        // [THEN] Entries count should be 3
        Assert.AreEqual(3, TempExcelBuffer.Count, 'Sheet count check failed');
        // [THEN] First entry value should be 4
        TempExcelBuffer.FindFirst();
        Assert.AreEqual('4', TempExcelBuffer."Cell Value as Text", 'First entry value check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveToStreamTest()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        ExcelFileStream: InStream;
        ExcelResultStream: OutStream;
    begin
        // [WHEN] Simple Excel file with one cell is created
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.CreateNewBook('Sheet1');
        TempExcelBuffer.EnterCell(TempExcelBuffer, 1, 1, 'Test', false, false, false);
        TempExcelBuffer.WriteSheet('', '', '');
        TempBlob.CreateOutStream(ExcelResultStream);
        // [WHEN] and saved to stream
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SaveToStream(ExcelResultStream, true);
        // [WHEN] and then reopened again
        Clear(TempExcelBuffer);
        TempBlob.CreateInStream(ExcelFileStream);
        TempExcelBuffer.OpenBookStream(ExcelFileStream, 'Sheet1');
        TempExcelBuffer.ReadSheet();
        // [THEN] Entries count should be 1
        Assert.AreEqual(1, TempExcelBuffer.Count, 'Sheet count check failed');
        // [THEN] First entry value should be 'Test'
        TempExcelBuffer.FindFirst();
        Assert.AreEqual('Test', TempExcelBuffer."Cell Value as Text", 'First entry value check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SaveToStreamTextWithLongValue()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        ExpectedText: Text;
        ActualText: Text;
        TempBlob: Codeunit "Temp Blob";
        ExcelInStream: InStream;
        ExcelOutStream: OutStream;
    begin
        // [SCENARIO 423217] Stan store, expore and import text in excel cells with length greater than 250 using Excel Buffer.

        ExpectedText := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(TempExcelBuffer."Cell Value as Text") + 1, 0);

        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.CreateNewBook('Sheet1');
        TempExcelBuffer.EnterCell(TempExcelBuffer, 2, 1, CopyStr(ExpectedText, 1, MaxStrLen(TempExcelBuffer."Cell Value as Text")), false, false, false);
        TempExcelBuffer."Cell Value as Blob".CreateOutStream(ExcelOutStream, TEXTENCODING::Windows);
        ExcelOutStream.Write(ExpectedText);
        TempExcelBuffer.Modify(true);
        TempExcelBuffer.WriteSheet('', '', '');
        TempBlob.CreateOutStream(ExcelOutStream);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SaveToStream(ExcelOutStream, false);

        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        Clear(TempExcelBuffer);

        TempBlob.CreateInStream(ExcelInStream);
        TempExcelBuffer.OpenBookStream(ExcelInStream, 'Sheet1');
        TempExcelBuffer.ReadSheet();
        TempExcelBuffer.FindFirst();

        Assert.IsTrue(TempExcelBuffer."Cell Value as Blob".HasValue, '"Cell Value as Blob".HasValue must be true');
        TempExcelBuffer.CalcFields("Cell Value as Blob");
        TempExcelBuffer."Cell Value as Blob".CreateInStream(ExcelInStream, TextEncoding::Windows);
        ExcelInStream.ReadText(ActualText);

        Assert.AreEqual(ActualText, ExpectedText, '');

        Assert.AreEqual(
            CopyStr(ExpectedText, 1, MaxStrLen(TempExcelBuffer."Cell Value as Text")),
            TempExcelBuffer."Cell Value as Text", 'First entry value check failed');
    end;

    local procedure CreateExcelFile(var ExcelBuffer: Record "Excel Buffer"; SheetName: Text): Text
    var
        variant: Variant;
    begin
        ExcelBuffer.CreateBook('', CopyStr(SheetName, 1, 250));
        ExcelBuffer.UTgetGlobalValue('ExcelFile', variant);
        exit(Format(variant))
    end;

    local procedure DumpDataToExcelFile(var ExcelBuffer: Record "Excel Buffer"; SheetName: Text; UserID: Text): Text
    var
        ExcelFile: Text;
    begin
        ExcelFile := CreateExcelFile(ExcelBuffer, SheetName);
        ExcelBuffer.SetUseInfoSheet();
        ExcelBuffer.WriteSheet('', '', UserID);
        ExcelBuffer.CloseBook();
        exit(ExcelFile);
    end;

    local procedure PopulateTableWithNumbers(var ExcelBuffer: Record "Excel Buffer")
    begin
        Clear(ExcelBuffer);
        ExcelBuffer.DeleteAll();

        ExcelBuffer.NewRow();
        PopulateRowWithNumbers(ExcelBuffer, 12, 0);
        ExcelBuffer.NewRow();
        PopulateRowWithNumbers(ExcelBuffer, 12, 2);
        PopulateRowWithNumbers(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
        ExcelBuffer.NewRow();
        PopulateRowWithNumbers(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
    end;

    local procedure PopulateTableWithTexts(var ExcelBuffer: Record "Excel Buffer")
    begin
        Clear(ExcelBuffer);
        ExcelBuffer.DeleteAll();

        ExcelBuffer.NewRow();
        PopulateRowWithTexts(ExcelBuffer, 12, 0);
        ExcelBuffer.NewRow();
        PopulateRowWithTexts(ExcelBuffer, 12, 2);
        PopulateRowWithTexts(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
        ExcelBuffer.NewRow();
        PopulateRowWithTexts(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
    end;

    local procedure PopulateTableWithTextsAndInfo(var ExcelBuffer: Record "Excel Buffer")
    begin
        Clear(ExcelBuffer);
        ExcelBuffer.DeleteAll();

        ExcelBuffer.NewRow();
        PopulateRowWithInfo(ExcelBuffer, 12);
        ExcelBuffer.NewRow();
        PopulateRowWithNumbers(ExcelBuffer, 12, 2);
        ExcelBuffer.NewRow();
    end;

    local procedure PopulateTableWithDates(var ExcelBuffer: Record "Excel Buffer")
    begin
        Clear(ExcelBuffer);
        ExcelBuffer.DeleteAll();

        ExcelBuffer.NewRow();
        PopulateRowWithDates(ExcelBuffer, 12, 0);
        ExcelBuffer.NewRow();
        PopulateRowWithDates(ExcelBuffer, 12, 2);
        PopulateRowWithDates(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
        ExcelBuffer.NewRow();
        PopulateRowWithDates(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
    end;

    local procedure PopulateTableWithMixAndStyling(var ExcelBuffer: Record "Excel Buffer")
    begin
        Clear(ExcelBuffer);
        ExcelBuffer.DeleteAll();

        ExcelBuffer.NewRow();
        PopulateRowWithMixAndStyling(ExcelBuffer, 12, 0);
        ExcelBuffer.NewRow();
        PopulateRowWithMixAndStyling(ExcelBuffer, 12, 2);
        PopulateRowWithMixAndStyling(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
        ExcelBuffer.NewRow();
        PopulateRowWithMixAndStyling(ExcelBuffer, 12, 3);
        ExcelBuffer.NewRow();
    end;

    local procedure PopulateRowWithNumbers(var ExcelBuffer: Record "Excel Buffer"; MaxCellNo: Integer; SkipEvery: Integer)
    var
        i: Integer;
    begin
        ExcelBuffer.NewRow();
        for i := 1 to MaxCellNo do
            if SkipEvery = 0 then
                ExcelBuffer.AddColumn(10000.1234 + i, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number)
            else
                if (i mod SkipEvery) > 0 then
                    ExcelBuffer.AddColumn(10000.1234 + i, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Number)
    end;

    local procedure PopulateRowWithTexts(var ExcelBuffer: Record "Excel Buffer"; MaxCellNo: Integer; SkipEvery: Integer)
    var
        i: Integer;
    begin
        ExcelBuffer.NewRow();
        for i := 1 to MaxCellNo do
            if SkipEvery = 0 then
                ExcelBuffer.AddColumn('Text' + Format(i), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text)
            else
                if (i mod SkipEvery) > 0 then
                    ExcelBuffer.AddColumn('Text' + Format(i), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text)
    end;

    local procedure PopulateRowWithInfo(var ExcelBuffer: Record "Excel Buffer"; MaxCellNo: Integer)
    var
        i: Integer;
    begin
        ExcelBuffer.NewRow();
        for i := 1 to MaxCellNo do
            ExcelBuffer.AddInfoColumn('Text' + Format(i), false, true, false, false, '', ExcelBuffer."Cell Type"::Text)
    end;

    local procedure PopulateRowWithDates(var ExcelBuffer: Record "Excel Buffer"; MaxCellNo: Integer; SkipEvery: Integer)
    var
        i: Integer;
    begin
        ExcelBuffer.NewRow();
        for i := 1 to MaxCellNo do
            if SkipEvery = 0 then
                ExcelBuffer.AddColumn(DMY2Date(24, 12, 1900 + i), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Date)
            else
                if (i mod SkipEvery) > 0 then
                    ExcelBuffer.AddColumn(DMY2Date(24, 12, 1900 + i), false, '', false, false, false, '', ExcelBuffer."Cell Type"::Date)
    end;

    local procedure PopulateRowWithMixAndStyling(var ExcelBuffer: Record "Excel Buffer"; MaxCellNo: Integer; SkipEvery: Integer)
    var
        NumberStyles: array[12] of Text[30];
        DateStyles: array[12] of Text[30];
        i: Integer;
    begin
        Assert.IsTrue(MaxCellNo <= 12, 'MaxCellNo should be less or equal to 12');
        ExcelBuffer.NewRow();
        NumberStyles[1] := '0';
        NumberStyles[2] := '0.00';
        NumberStyles[3] := '#,##0';
        NumberStyles[4] := '#,##0.00';
        NumberStyles[5] := '0%';
        NumberStyles[6] := '0.00%';
        NumberStyles[7] := '#,##0.00;[Red](#,##0.00)';
        NumberStyles[8] := '0_);(0)';   // Custom Style
        NumberStyles[9] := '#,##0.00%'; // Custom Style
        NumberStyles[10] := '#,##0%';   // Custom Style
        NumberStyles[11] := '0.0%';     // Custom Style
        NumberStyles[12] := '#,##0.00;(#,##0.00)';

        DateStyles[1] := 'mm-dd-yy';
        DateStyles[2] := 'd-mmm-yy';
        DateStyles[3] := 'd-mmm';
        DateStyles[4] := 'm/d/yyyy';       // Custom Style
        DateStyles[5] := 'm/d/yy';            // Custom Style
        DateStyles[6] := '[$-F800]dddd, mmmm dd, yyyy';   // Custom Style
        DateStyles[7] := '[$-409]d-mmm-yy';    // Custom Style
        DateStyles[8] := '[$-409]d-mmm';    // Custom Style
        DateStyles[9] := '[$-409]mmmm d, yyyy';    // Custom Style
        DateStyles[10] := '[$-409]m/d/yy';    // Custom Style
        DateStyles[11] := 'm/d/yyyy'; // Custom Style
        DateStyles[12] := 'm/d/yy';  // Custom Style

        for i := 1 to MaxCellNo do
            if SkipEvery = 0 then
                ExcelBuffer.AddColumn(10000.1234 + i, false, '', true, true, true, NumberStyles[i], ExcelBuffer."Cell Type"::Number)
            else
                if (i mod SkipEvery) > 0 then
                    ExcelBuffer.AddColumn(DMY2Date(24, 12, 1900 + i), false, '', true, true, true, DateStyles[i], ExcelBuffer."Cell Type"::Date)
    end;

    local procedure InsertColumn(var ExcelBuffer: Record "Excel Buffer"; RowNo: Integer; ColumnNo: Integer; Value: Variant; CellType: Option)
    begin
        ExcelBuffer.Validate("Row No.", RowNo);
        ExcelBuffer.Validate("Column No.", ColumnNo);
        ExcelBuffer.Validate("Cell Value as Text", Format(Value));
        ExcelBuffer.Validate("Cell Type", CellType);
        ExcelBuffer.Insert();
    end;

    local procedure ReadSheet(var ExcelBuffer: Record "Excel Buffer"; ExcelFile: Text; SheetName: Text)
    begin
        Clear(ExcelBuffer);
        ExcelBuffer.DeleteAll();
        ExcelBuffer.OpenBook(ExcelFile, CopyStr(SheetName, 1, 250));
        ExcelBuffer.ReadSheet();
    end;

    local procedure ValidateExcelFile(var WriteExcelBuffer: Record "Excel Buffer"; ExcelFile: Text; SheetName: Text)
    var
        TempReadExcelBuffer: Record "Excel Buffer" temporary;
        ValueNumber: Decimal;
    begin
        ReadSheet(TempReadExcelBuffer, ExcelFile, SheetName);
        TempReadExcelBuffer.CloseBook();

        Assert.AreEqual(WriteExcelBuffer.Count, TempReadExcelBuffer.Count, 'Both tables should have the same count');

        WriteExcelBuffer.FindFirst();
        TempReadExcelBuffer.FindFirst();
        repeat
            Assert.AreEqual(WriteExcelBuffer."Row No.", TempReadExcelBuffer."Row No.", 'Both Tables should point to the same row');
            Assert.AreEqual(WriteExcelBuffer."Column No.", TempReadExcelBuffer."Column No.", 'Both Tables should point to the same column');
            Assert.AreEqual(WriteExcelBuffer."Cell Type", TempReadExcelBuffer."Cell Type", 'Both Tables should point to the same Cell Type');

            if WriteExcelBuffer."Cell Type" = WriteExcelBuffer."Cell Type"::Number then begin
                Evaluate(ValueNumber, TempReadExcelBuffer."Cell Value as Text");
                Assert.AreEqual(WriteExcelBuffer."Cell Value as Text", Format(ValueNumber), 'Both Tables should point to the same value');
            end else
                Assert.AreEqual(
                  WriteExcelBuffer."Cell Value as Text", TempReadExcelBuffer."Cell Value as Text",
                  'Both Tables should point to the same value');

            Assert.AreEqual(
              GetCellNumberFormat(WriteExcelBuffer), TempReadExcelBuffer.NumberFormat, 'Both Tables should point to the same NumberFormat');

        until (WriteExcelBuffer.Next() = 0) and (TempReadExcelBuffer.Next() = 0);
    end;

    local procedure GetCellNumberFormat(var ExcelBuffer: Record "Excel Buffer"): Text
    begin
        case ExcelBuffer."Cell Type" of
            ExcelBuffer."Cell Type"::Number:
                exit(ExcelBuffer.NumberFormat);
            ExcelBuffer."Cell Type"::Date:
                begin
                    if ExcelBuffer.NumberFormat = '' then
                        exit('mm-dd-yy');

                    exit(ExcelBuffer.NumberFormat);
                end;
            ExcelBuffer."Cell Type"::Text:
                begin
                    if ExcelBuffer.NumberFormat = '' then
                        exit('@');

                    exit(ExcelBuffer.NumberFormat);
                end;
            ExcelBuffer."Cell Type"::Time:
                begin
                    if ExcelBuffer.NumberFormat = '' then
                        exit('h:mm:ss');

                    exit(ExcelBuffer.NumberFormat);
                end;
        end;

        Error(UnknownCellTypeError, Format(ExcelBuffer."Cell Type"))
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSheetMPH(var NameValueLookupPage: TestPage "Name/Value Lookup")
    begin
        NameValueLookupPage.Next();
        NameValueLookupPage.OK().Invoke();
    end;

    local procedure CreateExcelStream(var ExcelStream: InStream)
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileName: Text;
    begin
        FileName := CreateExcelFile(TempExcelBuffer, SheetNameTok);
        PopulateRowWithTexts(TempExcelBuffer, 5, 0);
        PopulateRowWithTexts(TempExcelBuffer, 5, 0);
        PopulateRowWithTexts(TempExcelBuffer, 5, 0);
        TempExcelBuffer.WriteSheet('', '', '');
        TempExcelBuffer.QuitExcel();

        ExcelFile.Open(FileName);
        ExcelFile.CreateInStream(ExcelStream);
    end;

    local procedure GetExampleFileBase64(): Text
    begin
        exit(
          'UEsDBBQABgAIAAAAIQAc/zogVAEAAJAEAAATAAgCW0NvbnRlbnRfVHlwZXNdLnhtbCCiBAIooAACAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADEVMtuwyAQvFfqPyCulU2SQ1VVcXLo49jm' +
          'kH4AhXWMggGxJE3+vmvyOFRuqiiRejEy7M7MLjuMp5vWsjVENN5VfFgOOAOnvDZuUfGP+WvxwBkm6bS03kHFt4B8Orm9Gc+3AZB' +
          'RtsOKNymFRyFQNdBKLH0ARye1j61M9BsXIki1lAsQo8HgXijvErhUpA6DT8bPUMuVTexlQ9s7JREscva0C+y4Ki5DsEbJRErF2u' +
          'kfLMWeoaTMHIONCXhHMrjoZehOfifY571Ta6LRwGYypjfZkgyxseLLx+Wn98vyNEiPSl/XRoH2atVSB0oMEaTGBiC1tsxr2UrjD' +
          'rpP8OdgFHkZXllIV18GPlPH6J90JJo7EPl7eSsyzB+FY9pawGtffwY9xUxzM4s+IDkowvnsB4t02UUgIIjJwNEkfcN2ZCT3XVwu' +
          'dP7WoHu4RX5PJt8AAAD//wMAUEsDBBQABgAIAAAAIQC1VTAj9AAAAEwCAAALAAgCX3JlbHMvLnJlbHMgogQCKKAAAgAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
          'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAArJJNT8MwDIbvSPyHyPfV' +
          '3ZAQQkt3QUi7IVR+gEncD7WNoyQb3b8nHBBUGoMDR3+9fvzK2908jerIIfbiNKyLEhQ7I7Z3rYaX+nF1ByomcpZGcazhxBF21fX' +
          'V9plHSnkodr2PKqu4qKFLyd8jRtPxRLEQzy5XGgkTpRyGFj2ZgVrGTVneYviuAdVCU+2thrC3N6Dqk8+bf9eWpukNP4g5TOzSmR' +
          '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'
          );
    end;
}

