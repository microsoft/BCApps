codeunit 131002 "Library - Report Validation"
{
    // // Contains all functions related to report Validation.


    trigger OnRun()
    begin
    end;

    var
        ColumnNotFoundError: Label 'Column %1 not found in report.';
        RowNotFoundForColumnValueError: Label 'Row not found for Column %1 and Value %2 in report.';
        ValueNotFoundError: Label 'Value not found.';
        Assert: Codeunit Assert;
        FileMgt: Codeunit "File Management";
        FileNameTo: Text;
        FileOpened: Boolean;
        FilterColumnCaption: Text[250];
        FilterColumnValue: Text[250];
        FullFileName: Text;
        ColumnCaption: Text[250];
        RowNumber: Integer;
        RowNotFoundError: Label 'No rows exist within the specified filter.';
        FixedColumnNo: Integer;
        WorksheetCount: Integer;
        IncorrectValueInCellErr: Label 'Incorrect value in cell R%1 C%2', Comment = '%1 - row % 2 - column';
        IncorrectNumFormatCellErr: Label 'Incorrect NumberFormat in cell R%1 C%2. Expected - %3, Actual - %4';

    procedure OpenFile()
    var
        FilePath: Text;
    begin
        FilePath := GetFileName();
        OpenFileAsExcel(FilePath);
        FileOpened := true;
    end;

    procedure OpenExcelFile()
    var
        FilePath: Text;
    begin
        FilePath := GetFileName();
        OpenFileAsExcel(FilePath);
        FileOpened := true;
    end;

    local procedure OpenFileAsExcel(FilePath: Text)
    begin
        OpenBookAsExcel(FilePath);
    end;

    procedure CheckIfValueExists(ColumnValue: Text): Boolean
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        FilterExcelBuffer(ExcelBuffer, ColumnValue);
        exit(not ExcelBuffer.IsEmpty());
    end;

    procedure CheckIfDecimalValueExists(Value: Decimal): Boolean
    begin
        exit(CheckIfValueExists(FormatDecimalValue(Value)));
    end;

    procedure CheckIfValueExistsInSpecifiedColumn(Column: Text[250]; ColumnValue: Text[250]): Boolean
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange(xlColID, Column);
        ExcelBuffer.SetRange("Cell Value as Text", ColumnValue);

        exit(not ExcelBuffer.IsEmpty());
    end;

    procedure CheckIfValueExistsOnSpecifiedWorksheet(WorksheetNo: Integer; ColumnValue: Text[250]): Boolean
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange(Comment, Format(WorksheetNo));
        ExcelBuffer.SetRange("Cell Value as Text", ColumnValue);

        exit(not ExcelBuffer.IsEmpty());
    end;

    procedure CountDistinctRows(var ExcelBuffer: Record "Excel Buffer"): Integer
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        if not FileOpened then
            OpenFile();

        if ExcelBuffer.FindSet() then
            repeat
                TempExcelBuffer.Init();
                TempExcelBuffer."Row No." := ExcelBuffer."Row No.";
                if TempExcelBuffer.Insert() then;
            until ExcelBuffer.Next() = 0;
        exit(TempExcelBuffer.Count);
    end;

    procedure CountRowsBetweenColumnCaptions(ColumnCaptionFrom: Text[250]; ColumnCaptionTo: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetFilter(
          "Row No.", '>%1 & <%2', FindRowNoFromColumnCaption(ColumnCaptionFrom), FindRowNoFromColumnCaption(ColumnCaptionTo));
        exit(CountDistinctRows(ExcelBuffer));
    end;

    procedure CountRows(): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Count the number of rows for where a given Column has the value specified.
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange("Column No.", FindColumnNoFromColumnCaption(FilterColumnCaption));
        ExcelBuffer.SetRange("Cell Value as Text", FilterColumnValue);
        exit(CountDistinctRows(ExcelBuffer));
    end;

    procedure CountColumns(): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        // Count the number of Columns.
        if not FileOpened then
            OpenFile();

        if ExcelBuffer.FindSet() then
            repeat
                TempExcelBuffer.Init();
                TempExcelBuffer."Column No." := ExcelBuffer."Column No.";
                if TempExcelBuffer.Insert() then;
            until ExcelBuffer.Next() = 0;
        exit(TempExcelBuffer.Count);
    end;

    procedure CountWorksheets(): Integer
    begin
        // Count the number of Worksheets.
        if not FileOpened then
            OpenFile();

        exit(WorksheetCount);
    end;

    procedure DownloadFile()
    begin
        SetFullFileName(GetFileName());
    end;

    local procedure FilterExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; ColumnCaption: Text)
    begin
        ExcelBuffer.SetRange("Cell Value as Text", ColumnCaption);
    end;

    procedure FindColumnNoFromColumnCaption(ColumnCaption: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        if FixedColumnNo <> 0 then
            exit(FixedColumnNo);

        FilterExcelBuffer(ExcelBuffer, ColumnCaption);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Column No.");
        Error(ColumnNotFoundError, ColumnCaption);
    end;

    procedure FindFirstColumnNoByValue(Value: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        if FixedColumnNo <> 0 then
            exit(FixedColumnNo);

        ExcelBuffer.SetRange("Cell Value as Text", Value);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Column No.");
        Error(ColumnNotFoundError, Value);
    end;

    procedure FindRowNoFromColumnCaption(ColumnCaption: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        FilterExcelBuffer(ExcelBuffer, ColumnCaption);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Row No.");
        Error(ColumnNotFoundError, ColumnCaption);
    end;

    procedure FindRowNoFromColumnNoAndValue(ColumnNo: Integer; ColumnValue: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange("Column No.", ColumnNo);
        ExcelBuffer.SetRange("Cell Value as Text", ColumnValue);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Row No.");
        Error(RowNotFoundForColumnValueError, ColumnNo, ColumnValue);
    end;

    procedure FindColumnNoFromColumnCaptionInsideArea(ColumnCaption: Text[250]; FilterRowNo: Text[250]; FilterColumnNo: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        if FixedColumnNo <> 0 then
            exit(FixedColumnNo);

        ExcelBuffer.SetFilter("Row No.", FilterRowNo);
        ExcelBuffer.SetFilter("Column No.", FilterColumnNo);
        FilterExcelBuffer(ExcelBuffer, ColumnCaption);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Column No.");
        Error(ColumnNotFoundError, ColumnCaption);
    end;

    procedure FindRowNoFromColumnNoAndValueInsideArea(ColumnNo: Integer; ColumnValue: Text[250]; FilterRowNo: Text[250]): Integer
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetFilter("Row No.", FilterRowNo);
        ExcelBuffer.SetRange("Column No.", ColumnNo);
        ExcelBuffer.SetRange("Cell Value as Text", ColumnValue);
        if ExcelBuffer.FindFirst() then
            exit(ExcelBuffer."Row No.");
        Error(RowNotFoundForColumnValueError, ColumnNo, ColumnValue);
    end;

    procedure FindFirstRow(var RowValueSet: array[50] of Text[250])
    var
        ExcelBuffer: Record "Excel Buffer";
        ExcelBuffer2: Record "Excel Buffer";
        Counter: Integer;
    begin
        // Retrieve the first row.
        if not FileOpened then
            OpenFile();

        Counter := 1;
        if FilterColumnCaption <> '' then begin
            ExcelBuffer.SetRange("Column No.", FindColumnNoFromColumnCaption(FilterColumnCaption));
            ExcelBuffer.SetRange("Cell Value as Text", FilterColumnValue);
        end;
        if ExcelBuffer.FindFirst() then begin
            ExcelBuffer2.SetRange("Row No.", ExcelBuffer."Row No.");
            if ExcelBuffer2.FindSet() then
                repeat
                    RowValueSet[Counter] := ExcelBuffer2."Cell Value as Text";
                    Counter += 1;
                until ExcelBuffer2.Next() = 0;
            RowNumber := ExcelBuffer."Row No.";
        end;
        if Counter = 1 then
            Error(RowNotFoundError);
    end;

    procedure FindNextRow(var RowValueSet: array[50] of Text[250])
    var
        ExcelBuffer: Record "Excel Buffer";
        ExcelBuffer2: Record "Excel Buffer";
        Counter: Integer;
    begin
        // Retrieve the next row.
        if not FileOpened then
            OpenFile();

        Counter := 1;
        if FilterColumnCaption <> '' then begin
            ExcelBuffer.SetRange("Column No.", FindColumnNoFromColumnCaption(FilterColumnCaption));
            ExcelBuffer.SetRange("Cell Value as Text", FilterColumnValue);
        end;

        ExcelBuffer.SetFilter("Row No.", '>%1', RowNumber);
        if ExcelBuffer.FindFirst() then begin
            ExcelBuffer2.SetRange("Row No.", ExcelBuffer."Row No.");
            if ExcelBuffer2.FindSet() then
                repeat
                    RowValueSet[Counter] := ExcelBuffer2."Cell Value as Text";
                    Counter += 1;
                until ExcelBuffer2.Next() = 0;
            RowNumber := ExcelBuffer."Row No.";
        end;
        if Counter = 1 then
            Error(RowNotFoundError);
    end;

    procedure FindSet(var ColumnValueSet: array[250] of Text[250])
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Retrieve all the values in a Column where another given Column has the value specified.
        if not FileOpened then
            OpenFile();

        if FilterColumnCaption <> '' then begin
            ExcelBuffer.SetRange("Column No.", FindColumnNoFromColumnCaption(FilterColumnCaption));
            ExcelBuffer.SetRange("Cell Value as Text", FilterColumnValue);
        end;

        FindSetByFilters(ExcelBuffer, FindColumnNoFromColumnCaption(ColumnCaption), ColumnValueSet);
    end;

    procedure FindSetByColumnNo(ColumnNo: Integer; var ColumnValueSet: array[250] of Text[250])
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange("Column No.", ColumnNo);
        FindSetByFilters(ExcelBuffer, ColumnNo, ColumnValueSet);
    end;

    local procedure FindSetByFilters(var ExcelBuffer: Record "Excel Buffer"; ColumnNo: Integer; var ColumnValueSet: array[250] of Text[250])
    var
        ExcelBuffer2: Record "Excel Buffer";
        Counter: Integer;
    begin
        Counter := 1;
        if ExcelBuffer.FindSet() then
            repeat
                if ExcelBuffer2.Get(ExcelBuffer."Row No.", ColumnNo) then
                    ColumnValueSet[Counter] := ExcelBuffer2."Cell Value as Text"
                else
                    ColumnValueSet[Counter] := '';
                Counter += 1;
            until ExcelBuffer.Next() = 0;
        if Counter = 1 then
            Error(ValueNotFoundError);
    end;

    procedure FindRowNoColumnNoByValueOnWorksheet(Value: Text[250]; WorksheetNo: Integer; var RowNo: Integer; var ColumnNo: Integer)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        RowNo := 0;
        ColumnNo := 0;
        ExcelBuffer.SetRange("Cell Value as Text", Value);
        ExcelBuffer.SetRange(Comment, Format(WorksheetNo));
        ExcelBuffer.FindFirst();
        RowNo := ExcelBuffer."Row No.";
        ColumnNo := ExcelBuffer."Column No.";
    end;

    procedure FormatDecimalValue(Value: Decimal): Text
    begin
        exit(Format(Value, 0, GetDefaultDecimalFormat()));
    end;

    local procedure GetDefaultDecimalFormat(): Text
    begin
        exit('<Precision,0:2><Standard Format,1>');
    end;

    procedure GetFileName(): Text[1024]
    begin
        if FullFileName = '' then
            exit(TemporaryPath + FileNameTo + '.xlsx');
        exit(FullFileName);
    end;

    procedure GetValue(): Text[250]
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Retrieve the value of a Column where another given Column has the value specified.
        // Throws an error if the cell doesnt contain a value
        // To check whether a cell contains a value or not, use function IsEmptyCell()

        if not FileOpened then
            OpenFile();

        if ExcelBuffer.Get(
             FindRowNoFromColumnNoAndValue(FindColumnNoFromColumnCaption(FilterColumnCaption), FilterColumnValue),
             FindColumnNoFromColumnCaption(ColumnCaption))
        then
            exit(ExcelBuffer."Cell Value as Text");

        Error(ValueNotFoundError);
    end;

    procedure GetValue2(var FoundValue: Boolean; FilterRowNo: Text[250]; FilterColumnNo: Text[250]): Text[250]
    var
        ExcelBuffer: Record "Excel Buffer";
        ColumnNo: Integer;
        RowNo: Integer;
    begin
        // Retrieve the value of a Column where another given Column has the value specified.

        if not FileOpened then
            OpenFile();

        ColumnNo := FindColumnNoFromColumnCaptionInsideArea(ColumnCaption, FilterRowNo, FilterColumnNo);
        RowNo := FindRowNoFromColumnNoAndValueInsideArea(FindColumnNoFromColumnCaptionInsideArea(
              FilterColumnCaption, FilterRowNo, FilterColumnNo), FilterColumnValue, FilterRowNo);

        FoundValue := true;
        if ExcelBuffer.Get(RowNo, ColumnNo)
        then
            exit(ExcelBuffer."Cell Value as Text");

        FoundValue := false;
        exit('');
    end;

    procedure GetValueAt(var FoundValue: Boolean; RowNo: Integer; ColumnNo: Integer): Text[250]
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Retrieve the value of a Column where another given Column has the value specified.
        // Throws an error if the cell doesnt contain a value
        // To check whether a cell contains a value or not, use function IsEmptyCell()

        if not FileOpened then
            OpenFile();

        FoundValue := true;
        if ExcelBuffer.Get(RowNo, ColumnNo)
        then
            exit(ExcelBuffer."Cell Value as Text");

        FoundValue := false;
        exit('');
    end;

    procedure GetValueAtFromWorksheet(RowNo: Integer; ColumnNo: Integer; Worksheet: Text): Text[250]
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Retrieve the value of a Column from a specific worksheet where another given Column has the value specified.
        // Throws an error if the cell doesnt contain a value
        // To check whether a cell contains a value or not, use function IsEmptyCell()

        if not FileOpened then
            OpenFile();

        if ExcelBuffer.Get(RowNo, ColumnNo) and (ExcelBuffer.Comment = Worksheet)
        then
            exit(ExcelBuffer."Cell Value as Text");

        exit('');
    end;

    procedure GetValueFromSpecifiedCellOnWorksheet(WorksheetNo: Integer; RowId: Integer; ColumnId: Integer): Text
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Checks the value in specified cell within specified worksheet (note the function requires row number within worksheet not report).
        if not FileOpened then
            OpenFile();

        if WorksheetNo > 1 then begin
            ExcelBuffer.SetRange(Comment, Format(WorksheetNo - 1));
            ExcelBuffer.FindLast();
            if ExcelBuffer."Row No." > 0 then
                RowId += ExcelBuffer."Row No.";
        end;

        ExcelBuffer.Get(RowId, ColumnId);
        exit(ExcelBuffer."Cell Value as Text");
    end;

    procedure GetValueByRef(ColumnName: Text; RowNo: Integer; WorksheetNo: Integer): Text
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange(xlColID, ColumnName);
        ExcelBuffer.SetRange(xlRowID, Format(RowNo));
        ExcelBuffer.SetRange(Comment, Format(WorksheetNo));
        ExcelBuffer.FindFirst();

        exit(ExcelBuffer."Cell Value as Text");
    end;

    procedure GetValueFromNextColumn(RowNo: Integer; ColumnNo: Integer): Text[250]
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange("Row No.", RowNo);
        ExcelBuffer.Get(RowNo, ColumnNo);
        ExcelBuffer.Next();
        exit(ExcelBuffer."Cell Value as Text");
    end;

    procedure GetNumberFormatAt(var NumberFormat: Text[30]; var FoundValue: Boolean; RowNo: Integer; ColumnNo: Integer)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        NumberFormat := '';
        if ExcelBuffer.Get(RowNo, ColumnNo) then begin
            FoundValue := true;
            NumberFormat := ExcelBuffer.NumberFormat;
        end else
            FoundValue := false;
    end;

    procedure IsEmptyCell(): Boolean
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        // Returns true if a cell, specified by SetRange and SetColumn, is empty,
        // otherwise false.

        if not FileOpened then
            OpenFile();

        exit(
          not ExcelBuffer.Get(FindRowNoFromColumnNoAndValue(FindColumnNoFromColumnCaption(FilterColumnCaption), FilterColumnValue),
            FindColumnNoFromColumnCaption(ColumnCaption)));
    end;

    procedure SetFixedColumn(Index: Integer)
    begin
        FixedColumnNo := Index;
    end;

    procedure SetColumn(ColumnCaptionFrom: Text[250])
    begin
        FixedColumnNo := 0;
        ColumnCaption := ColumnCaptionFrom;
    end;

    procedure SetFileName(FileNameFrom: Text)
    begin
        FileNameTo := FileNameFrom;
        FullFileName := '';
        FileOpened := false; // Force reopen of Excel file
    end;

    procedure SetFullFileName(NewFullFileName: Text)
    begin
        FullFileName := NewFullFileName;
        FileNameTo := '';
        FileOpened := false; // Force reopen of Excel file
    end;

    procedure SetRange(FilterColumnCaptionFrom: Text[250]; FilterColumnValueFrom: Text[250])
    begin
        FilterColumnCaption := FilterColumnCaptionFrom;
        FilterColumnValue := FilterColumnValueFrom;
    end;

    procedure OpenBookAsExcel(ClientFileName: Text)
    var
        ExcelBuffer: Record "Excel Buffer";
        WorkbookReader: DotNet WorkbookReader;
        WorksheetReader: DotNet WorksheetReader;
        CellData: DotNet CellData;
        SheetNames: DotNet Array;
        SheetIndex: Integer;
        RowIndex: Integer;
        RowOffset: Integer;
        ColumnIndex: Integer;
        ValueMaxLength: Integer;
        Value: Text[1024];
        NumberFormat: Text[1024];
    begin
        FileMgt.ServerFileExists(ClientFileName);

        ExcelBuffer.DeleteAll();

        WorkbookReader := WorkbookReader.Open(ClientFileName, false);

        ValueMaxLength := MaxStrLen(Value);
        SheetNames := WorkbookReader.SheetNames();
        WorksheetCount := SheetNames.Length;
        SheetIndex := 0;
        RowOffset := 0;
        while SheetIndex < WorksheetCount do begin
            WorksheetReader := WorkbookReader.GetWorksheetByName(SheetNames.GetValue(SheetIndex));
            foreach CellData in WorksheetReader do begin
                RowIndex := CellData.RowNumber;
                ColumnIndex := CellData.ColumnNumber;
                Value := CopyStr(CellData.Value, 1, ValueMaxLength);
                NumberFormat := CellData.Format;
                InsertIntoExcelBuffer(RowIndex + RowOffset, ColumnIndex, Value, NumberFormat, SheetIndex + 1);
            end;
            RowOffset += RowIndex; // WorksheetReader.RowCount; Excel may have skipped rows in a sheet, so RowCount would be less than RowIndex
            SheetIndex += 1;
        end;
    end;

    local procedure InsertIntoExcelBuffer(Row: Integer; Column: Integer; InputString: Text[1024]; NumberFormatString: Text[1024]; WorksheetNo: Integer)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        InputString := DelChr(InputString, '<>'); // Trim spaces
        InputString := DelChr(InputString, '<>', '"'); // Trim quotes
        if StrLen(InputString) = 0 then
            exit;

        ExcelBuffer.Init();
        ExcelBuffer.Validate("Row No.", Row);
        ExcelBuffer.Validate("Column No.", Column);
        ExcelBuffer.Validate("Cell Value as Text", CopyStr(InputString, 1, 250));
        ExcelBuffer.Validate(NumberFormat, CopyStr(NumberFormatString, 1, MaxStrLen(ExcelBuffer.NumberFormat)));
        ExcelBuffer.Validate(Comment, Format(WorksheetNo)); // Using Comment field to store Worksheet No. since Excel Buffer table doesn't have a field for this purpose
        ExcelBuffer.Insert(true);
    end;

    procedure VerifyCellValue(RowId: Integer; ColumnId: Integer; ExpectedValue: Text)
    var
        ValueFound: Boolean;
    begin
        Assert.AreEqual(
          DelChr(ExpectedValue, '<>'), GetValueAt(ValueFound, RowId, ColumnId),
          StrSubstNo(IncorrectValueInCellErr, RowId, ColumnId));
    end;

    procedure VerifyCellValueOnWorksheet(RowId: Integer; ColumnId: Integer; ExpectedValue: Text; Worksheet: Text)
    begin
        Assert.AreEqual(
          DelChr(ExpectedValue, '<>'), GetValueAtFromWorksheet(RowId, ColumnId, Worksheet),
          StrSubstNo(IncorrectValueInCellErr, RowId, ColumnId));
    end;

    procedure VerifyCellContainsValueOnWorksheet(RowId: Integer; ColumnId: Integer; ExpectedValue: Text; Worksheet: Text)
    begin
        Assert.IsTrue(
          StrPos(GetValueAtFromWorksheet(RowId, ColumnId, Worksheet), ExpectedValue) > 0,
          StrSubstNo(IncorrectValueInCellErr, RowId, ColumnId));
    end;

    procedure VerifyCellValueByRef(ColumnName: Text; RowNo: Integer; WorksheetNo: Integer; ExpectedValue: Text)
    var
        Value: Text;
    begin
        Value := GetValueByRef(ColumnName, RowNo, WorksheetNo);
        Assert.AreEqual(
          DelChr(ExpectedValue, '<>'),
          Value,
          StrSubstNo(IncorrectValueInCellErr, ColumnName, RowNo));
    end;

    procedure VerifyEmptyCellByRef(ColumnName: Text; RowNo: Integer; WorksheetNo: Integer)
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        if not FileOpened then
            OpenFile();

        ExcelBuffer.SetRange(xlColID, ColumnName);
        ExcelBuffer.SetRange(xlRowID, Format(RowNo));
        ExcelBuffer.SetRange(Comment, Format(WorksheetNo));
        Assert.RecordIsEmpty(ExcelBuffer);
    end;

    procedure VerifyCellNumberFormat(RowId: Integer; ColumnId: Integer; ExpectedValue: Text)
    var
        ValueFound: Boolean;
        CellNumberFormat: Text[30];
    begin
        GetNumberFormatAt(CellNumberFormat, ValueFound, RowId, ColumnId);
        Assert.IsTrue(
          StrPos(CellNumberFormat, ExpectedValue) > 0,
          StrSubstNo(IncorrectNumFormatCellErr, RowId, ColumnId, ExpectedValue, CellNumberFormat));
    end;

    procedure DeleteObjectOptions(var CurrentSaveValuesId: Integer)
    var
        ObjectOptions: Record "Object Options";
    begin
        if CurrentSaveValuesId <= 0 then
            exit;

        ObjectOptions.SetFilter("Object ID", Format(CurrentSaveValuesId));
        ObjectOptions.SetFilter("Object Type", Format(ObjectOptions."Object Type"::Report));
        ObjectOptions.SetFilter("User Name", UserId);
        ObjectOptions.DeleteAll();

        CurrentSaveValuesId := 0;
    end;
}

