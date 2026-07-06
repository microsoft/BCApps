#pragma warning disable AA0247
codeunit 12416 "Excel Management"
{

    trigger OnRun()
    begin
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileMgt: Codeunit "File Management";
        FileStream: InStream;
        ExcelFilesFilterTxt: Label 'Excel Files (*.xlsx;)|*.xlsx;', Comment = '{Split=r''\|''}{Locked=s''1''}';
        ServerFileName: Text;
        ActiveSheetName: Text;

    [Scope('OnPrem')]
    procedure ReadSheet(SheetName: Text)
    begin
        Clear(TempExcelBuffer);
        TempExcelBuffer.OpenBookStream(FileStream, SheetName);
        TempExcelBuffer.ReadSheet();
    end;

    [Scope('OnPrem')]
    procedure GetCellValue(CellName: Text): Text
    var
        CellPosition: DotNet CellPosition;
        RowInt: Integer;
        ColumnInt: Integer;
    begin
        CellPosition := CellPosition.CellPosition(CellName);
        RowInt := CellPosition.Row;
        ColumnInt := CellPosition.Column;
        if TempExcelBuffer.Get(RowInt, ColumnInt) then
            exit(TempExcelBuffer."Cell Value as Text");
    end;

    [Scope('OnPrem')]
    procedure OpenBookForUpdate(FileName: Text)
    begin
        TempExcelBuffer.OpenBookForUpdate(FileName);
        ServerFileName := FileName;
    end;

    [Scope('OnPrem')]
    procedure SetActiveWriterSheet(SheetName: Text)
    begin
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.SetActiveWriterSheet(SheetName);
        ActiveSheetName := SheetName;
    end;

    [Scope('OnPrem')]

    procedure SetActiveWriterSheetById(SheetNo: Integer)
    var
        SheetName: Text;
    begin
        SheetName := TempExcelBuffer.GetWriterSheetNameByNumber(SheetNo);
        SetActiveWriterSheet(SheetName);
    end;

    [Scope('OnPrem')]
    procedure RenameActiveSheet(NewSheetName: Text)
    begin
        CopySheet(ActiveSheetName, ActiveSheetName, NewSheetName);
        DeleteSheet(ActiveSheetName);
        SetActiveWriterSheet(NewSheetName);
    end;

    [Scope('OnPrem')]
    procedure CloseBook()
    begin
        TempExcelBuffer.CloseBook();
    end;

    [Scope('OnPrem')]
    procedure WriteAllToCurrentSheet()
    begin
        TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer);
    end;

    procedure DownloadBook(FileName: Text)
    begin
        TempExcelBuffer.CloseBook();
        FileMgt.DownloadHandler(ServerFileName, 'Export to Excel', '', ExcelFilesFilterTxt, FileName);
    end;

    [Scope('OnPrem')]
    procedure CreateBook()
    begin
        TempExcelBuffer.CreateNewBook('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure OpenSheet(SheetName: Text[30])
    begin
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.SetActiveWriterSheet(SheetName);
        ActiveSheetName := SheetName;
    end;

    [Scope('OnPrem')]
    procedure OpenSheetByNumber(SheetNo: Integer)
    begin
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.GetWriterSheetNameByNumber(SheetNo);
    end;

    [Scope('OnPrem')]
    procedure FillCell(CellName: Text; CellValueAsText: Text)
    begin
        TempExcelBuffer.EnterCellByCellName(CellName, CellValueAsText);
    end;

    [Scope('OnPrem')]
    procedure FillCellWithTextFormat(CellName: Text[30]; CellValueAsText: Text[1024])
    begin
        TempExcelBuffer.EnterCellByCellName(CellName, CellValueAsText);
        TempExcelBuffer."Cell Type" := TempExcelBuffer."Cell Type"::Text;
        TempExcelBuffer.Modify();
    end;

    [Scope('OnPrem')]
    procedure FillCellsGroup(Name: Text[30]; Value: Text[30]; Len: Integer; Align: Option Right,Left; EmptyValue: Text[1])
    var
        K: Integer;
        Diff: Integer;
    begin
        Diff := Len - StrLen(Value);
        if Diff < 0 then
            Diff := 0;
        if Diff = 0 then
            for K := 1 to Len do
                TempExcelBuffer.EnterCellByCellName(Name + Format(K), CopyStr(Value, K, 1))
        else
            for K := 1 to Len do
                case Align of
                    Align::Right:
                        if K <= Diff then
                            TempExcelBuffer.EnterCellByCellName(Name + Format(K), EmptyValue)
                        else
                            TempExcelBuffer.EnterCellByCellName(Name + Format(K), CopyStr(Value, K - Diff, 1));
                    Align::Left:
                        if K > Len - Diff then
                            TempExcelBuffer.EnterCellByCellName(Name + Format(K), EmptyValue)
                        else
                            TempExcelBuffer.EnterCellByCellName(Name + Format(K), CopyStr(Value, K, 1));
                end;
    end;

    [Scope('OnPrem')]
    procedure FillCellsGroup2(ExceCellName: Text[30]; HorizCellsQty: Integer; VertCellsQty: Integer; Value: Text[250]; EmptyCellValue: Text[1]; Align: Option Right,Left)
    begin
        FillCellsArea(
          ExceCellName,
          HorizCellsQty,
          VertCellsQty,
          1,
          Value,
          EmptyCellValue,
          Align);
    end;

    [Scope('OnPrem')]
    procedure FillCellsArea(ExceCellName: Text[30]; HorizCellsQty: Integer; VertCellsQty: Integer; VertCellsDelta: Integer; Value: Text[250]; EmptyCellValue: Text[1]; Align: Option Right,Left)
    var
        CurrCellName: Text[30];
        NextRowFirstCellName: Text[30];
        GroupType: Option Row,Column,"Area";
        CellsQty: Integer;
        index: Integer;
        i: Integer;
        j: Integer;
        delta: Integer;
    begin
        if (HorizCellsQty = 1) and (VertCellsQty = 1) then
            FillCell(ExceCellName, Value);

        case true of
            (HorizCellsQty > 1) and (VertCellsQty = 1):
                GroupType := GroupType::Row;
            (HorizCellsQty = 1) and (VertCellsQty > 1):
                GroupType := GroupType::Column;
            (HorizCellsQty > 1) and (VertCellsQty > 1):
                GroupType := GroupType::Area;
        end;

        CellsQty := HorizCellsQty * VertCellsQty;
        CurrCellName := ExceCellName;

        if CellsQty > StrLen(Value) then
            case Align of
                Align::Right:
                    Value := PadStr('', CellsQty - StrLen(Value), EmptyCellValue) + Value;
                Align::Left:
                    Value := Value + PadStr('', CellsQty - StrLen(Value), EmptyCellValue);
            end;

        case GroupType of
            GroupType::Row:
                for i := 1 to CellsQty do begin
                    if not IsEmptySymbol(Format(Value[i])) then
                        TempExcelBuffer.EnterCellByCellName(CurrCellName, Format(Value[i]));
                    CurrCellName := TempExcelBuffer.GetNextColumnCellName(CurrCellName);
                end;
            GroupType::Column:
                for i := 1 to CellsQty do begin
                    if not IsEmptySymbol(Format(Value[i])) then
                        TempExcelBuffer.EnterCellByCellName(CurrCellName, Format(Value[i]));
                    CurrCellName := TempExcelBuffer.GetNextRowCellName(CurrCellName);
                end;
            GroupType::Area:
                for j := 1 to VertCellsQty do begin
                    if j > 1 then begin
                        NextRowFirstCellName :=
                          CellName2ColumnName(ExceCellName) +
                          Format(CellName2RowNo(CurrCellName));

                        for delta := 1 to VertCellsDelta do
                            NextRowFirstCellName := TempExcelBuffer.GetNextRowCellName(NextRowFirstCellName);

                        CurrCellName := NextRowFirstCellName;
                    end;

                    for i := 1 to HorizCellsQty do begin
                        index := i + (j - 1) * HorizCellsQty;
                        if not IsEmptySymbol(Format(Value[index])) then
                            TempExcelBuffer.EnterCellByCellName(CurrCellName, Format(Value[index]));
                        CurrCellName := TempExcelBuffer.GetNextColumnCellName(CurrCellName);
                    end;
                end;
        end;
    end;

    procedure ErrorExcelProcessing(ErrorMessage: Text[250])
    begin
        CloseBook();
        Error(ErrorMessage);
    end;

    [Scope('OnPrem')]
    procedure CopySheet(Source: Text[30]; Before: Text[30]; NewName: Text[30])
    begin
        TempExcelBuffer.CopySheet(Source, NewName, Before, true);
    end;

    [Scope('OnPrem')]
    procedure CopyCellRangeTo(Source: Text[30]; DestStart: Text[30]; DestEnd: Text[30])
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure CopyRow(RowNo: Integer)
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure CopyRowsTo(FirstRowNo: Integer; LastRowNo: Integer; DestRowNo: Integer)
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure DeleteSheet(SheetName: Text[30])
    begin
        TempExcelBuffer.DeleteWorksheet(SheetName);
    end;

    [Scope('OnPrem')]
    procedure DeleteRows(FirstRowNo: Integer; LastRowNo: Integer)
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure GetSheetsCount(): Integer
    begin
        exit(TempExcelBuffer.GetSheetsCount());
    end;

    [Scope('OnPrem')]
    procedure GetSheetName(): Text[30]
    begin
        exit(ActiveSheetName);
    end;

    [Scope('OnPrem')]
    procedure SetSheetName(NewSheetName: Text[30])
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure ColumnNo2Name(ColumnNo: Integer): Text[10]
    var
        ExcelBuffer: Record "Excel Buffer";
    begin
        ExcelBuffer.Validate("Column No.", ColumnNo);
        exit(ExcelBuffer.xlColID);
    end;

    [Scope('OnPrem')]
    procedure CellName2RowNo(Str: Code[10]) Number: Integer
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Str) do
            if Str[i] in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'] then
                if Evaluate(Number, CopyStr(Str, i)) then
                    exit;
    end;

    [Scope('OnPrem')]
    procedure CellName2ColumnName(Str: Code[10]): Code[10]
    var
        i: Integer;
    begin
        for i := 1 to StrLen(Str) do
            if Str[i] in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'] then
                exit(CopyStr(Str, 1, i - 1));
    end;

    [Scope('OnPrem')]
    procedure GetNextColumn(ColName: Code[10]; Step: Integer): Code[10]
    begin
        exit(ColumnNo2Name(ColNameToInt(ColName) + Step));
    end;

    [Scope('OnPrem')]
    procedure ColNameToInt(ColName: Code[10]) ColumnNumber: Integer
    var
        i: Integer;
    begin
        for i := StrLen(ColName) downto 1 do
            ColumnNumber := ColumnNumber + (ColName[i] - 64) * Power(26, StrLen(ColName) - i);
    end;

    [Scope('OnPrem')]
    procedure ParseSelectionAddress(Address: Text[30]; var FirstColumnName: Code[10]; var LastColumnName: Code[10]; var FirstRowName: Code[10]; var LastRowName: Code[10])
    var
        i: Integer;
    begin
        i := StrPos(Address, ':');

        if i <> 0 then begin
            ParseCellAddress(CopyStr(Address, 1, i - 1), FirstColumnName, FirstRowName);
            ParseCellAddress(CopyStr(Address, i + 1), LastColumnName, LastRowName);
        end else begin
            ParseCellAddress(Address, FirstColumnName, FirstRowName);
            LastColumnName := FirstColumnName;
            LastRowName := FirstRowName;
        end;
    end;

    [Scope('OnPrem')]
    procedure ParseCellAddress(Address: Text[30]; var ColumnName: Code[10]; var RowName: Code[10])
    var
        i: Integer;
    begin
        i := StrPos(Address, '$');
        Address := CopyStr(Address, i + 1);
        i := StrPos(Address, '$');
        ColumnName := CopyStr(Address, 1, i - 1);
        RowName := CopyStr(Address, i + 1);
    end;

    [Scope('OnPrem')]
    procedure GetNextColumnCellName(CellName: Text[30]): Text[30]
    begin
        exit(TempExcelBuffer.GetNextColumnCellName(CellName));
    end;

    [Scope('OnPrem')]
    procedure GetNextRowCellName(CellName: Text[30]): Text[30]
    begin
        exit(TempExcelBuffer.GetNextRowCellName(CellName));
    end;

    [Scope('OnPrem')]
    procedure SetColumnSize(CellName: Text[30]; Size: Integer)
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure BoldRow(RowNo: Integer)
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure MergeCells(StartingCell: Text[30]; EndingCell: Text[30])
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure ClearRow(RowNo: Integer)
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure SetCellNumberFormat(CellName: Text[30]; NumberFormat: Text[30])
    begin
        // To be refactored
    end;

    [Scope('OnPrem')]
    procedure IsEmptySymbol(ElementCharecter: Text[1]): Boolean
    begin
        if ElementCharecter in ['', ' '] then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure BLOBImportSilent(var TempBlob: Codeunit "Temp Blob"; ClientFileName: Text)
    var
        NVInStream: InStream;
        NVOutStream: OutStream;
        ServerFileName: Text;
        ServerFile: File;
    begin
        ServerFile.Open(ServerFileName);
        ServerFile.CreateInStream(NVInStream);
        TempBlob.CreateOutStream(NVOutStream);
        CopyStream(NVOutStream, NVInStream);
    end;

    [Scope('OnPrem')]
    procedure SaveWrkBook(FileName: Text)
    begin
        TempExcelBuffer.CloseBook();
        FileMgt.CopyServerFile(ServerFileName, FileName, true);
    end;
}
