namespace System.Xml;

using System;
using System.IO;
using System.Utilities;

codeunit 6223 "OpenXML Management"
{

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        WrkShtHelper: DotNet WorksheetHelper;
        UID: Integer;
        CreateWrkBkFailedErr: Label 'Could not create the Excel workbook.';
        OpenWrkBkFailedErr: Label 'Could not open the Excel workbook.';
        MissingXMLMapErr: Label 'The Excel workbook must contain an XML map.';
        VmlShapeAnchorTxt: Label '%1,15,%2,10,%3,31,%4,9', Locked = true;
        CommentVmlShapeXmlTxt: Label '<v:shape id="%1" type="#_x0000_t202" style=''position:absolute;  margin-left:59.25pt;margin-top:1.5pt;width:96pt;height:55.5pt;z-index:1;  visibility:hidden'' fillcolor="#ffffe1" o:insetmode="auto"><v:fill color2="#ffffe1"/><v:shadow color="black" obscured="t"/><v:path o:connecttype="none"/><v:textbox style=''mso-direction-alt:auto''><div style=''text-align:left''/></v:textbox><x:ClientData ObjectType="Note"><x:MoveWithCells/><x:SizeWithCells/><x:Anchor>%2</x:Anchor><x:AutoFill>False</x:AutoFill><x:Row>%3</x:Row><x:Column>%4</x:Column></x:ClientData></v:shape>', Locked = true;
        CopyDataProgressTxt: Label 'Writing to Excel';
        ProgressStatusTxt: Label '%1: %2 records out of %3', Comment = '%1 = table name; %2 = number of processed records (integer); %3 = total number records (integer).';

    [Scope('OnPrem')]
    procedure AddAndInitializeCommentsPart(WorksheetWriter: DotNet WorksheetWriter; var VmlDrawingPart: DotNet VmlDrawingPart)
    var
        WorkSheetCommentsPart: DotNet WorksheetCommentsPart;
        Comments: DotNet Comments;
    begin
        WorkSheetCommentsPart := WorksheetWriter.Worksheet.WorksheetPart.WorksheetCommentsPart;
        if IsNull(WorkSheetCommentsPart) then
            WorkSheetCommentsPart := WorksheetWriter.CreateWorksheetCommentsPart();

        AddVmlDrawingPart(WorksheetWriter, VmlDrawingPart);

        WorkSheetCommentsPart.Comments := Comments.Comments();

        AddWorkSheetAuthor(WorkSheetCommentsPart.Comments, UserId);

        WorksheetWriter.CreateCommentList(WorkSheetCommentsPart.Comments);
    end;

    local procedure AddVmlDrawingPart(WorksheetWriter: DotNet WorksheetWriter; var VmlDrawingPart: DotNet VmlDrawingPart)
    var
        StringValue: DotNet StringValue;
        LegacyDrawing: DotNet LegacyDrawing;
        LocalWorksheet: DotNet Worksheet;
        LastChild: DotNet OpenXmlElement;
        VmlPartId: Text;
    begin
        VmlDrawingPart := WorksheetWriter.CreateVmlDrawingPart();
        VmlPartId := WorksheetWriter.Worksheet.WorksheetPart.GetIdOfPart(VmlDrawingPart);
        LegacyDrawing := LegacyDrawing.LegacyDrawing();
        LegacyDrawing.Id := StringValue.FromString(VmlPartId);
        LocalWorksheet := WorksheetWriter.Worksheet.WorksheetPart.Worksheet;
        LastChild := LocalWorksheet.LastChild();
        if LastChild.GetType().Equals(LegacyDrawing.GetType()) then
            LastChild.Remove();

        WrkShtHelper.AppendElementToOpenXmlElement(WorksheetWriter.Worksheet.WorksheetPart.Worksheet, LegacyDrawing);
    end;

    [Scope('OnPrem')]
    procedure AddColumnHeader(WorksheetWriter: DotNet WorksheetWriter; var "Table": DotNet Table; ColumnID: Integer; ColumnName: Text; var TableColumn: DotNet TableColumn)
    var
        TableColumns: DotNet TableColumns;
    begin
        TableColumns := Table.TableColumns;
        TableColumn := WorksheetWriter.CreateTableColumn(ColumnID, ColumnName, GetElementName(ColumnName));
        WrkShtHelper.AppendElementToOpenXmlElement(TableColumns, TableColumn);
    end;

    [Scope('OnPrem')]
    procedure AddColumnHeaderWithXPath(WorksheetWriter: DotNet WorksheetWriter; var "Table": DotNet Table; ColumnID: Integer; ColumnName: Text; Type: Text; XPath: Text)
    var
        TableColumn: DotNet TableColumn;
        XmlColumnProperties: DotNet XmlColumnProperties;
    begin
        AddColumnHeader(WorksheetWriter, Table, ColumnID, ColumnName, TableColumn);
        XmlColumnProperties :=
          WorksheetWriter.CreateXmlColumnProperties(1, XPath, WorksheetWriter.XmlDataType2XmlDataValues(Type));
        TableColumn.XmlColumnProperties(XmlColumnProperties);
    end;

    [Scope('OnPrem')]
    procedure AddSingleXMLCellProperties(var SingleXMLCell: DotNet SingleXmlCell; CellReference: Text; XPath: Text; Mapid: Integer; ConnectionId: Integer)
    var
        XMLCellProperties: DotNet XmlCellProperties;
        XMLProperties: DotNet XmlProperties;
        UInt32Value: DotNet UInt32Value;
        StringValue: DotNet StringValue;
        XmlDataValues: DotNet XmlDataValues;
        WrkShtWriter2: DotNet WorksheetWriter;
    begin
        StringValue := StringValue.StringValue(CellReference);
        SingleXMLCell.CellReference := StringValue;
        UInt32Value := UInt32Value.UInt32Value();
        UInt32Value.Value := ConnectionId;
        SingleXMLCell.ConnectionId := UInt32Value;

        XMLCellProperties := XMLCellProperties.XmlCellProperties();
        WrkShtHelper.AppendElementToOpenXmlElement(SingleXMLCell, XMLCellProperties);
        UInt32Value.Value := 1;
        XMLCellProperties.Id := UInt32Value;
        StringValue := StringValue.StringValue(Format(SingleXMLCell.Id));
        XMLCellProperties.UniqueName := StringValue;

        XMLProperties := XMLProperties.XmlProperties();
        WrkShtHelper.AppendElementToOpenXmlElement(XMLCellProperties, XMLProperties);
        UInt32Value.Value := Mapid;
        XMLProperties.MapId := UInt32Value;
        StringValue := StringValue.StringValue(XPath);
        XMLProperties.XPath := StringValue;
        XmlDataValues := XmlDataValues.String;

        XMLProperties.XmlDataType := WrkShtWriter2.GetEnumXmlDataValues(XmlDataValues);
    end;

    [Scope('OnPrem')]
    procedure AddTable(WorksheetWriter: DotNet WorksheetWriter; StartFromRow: Integer; ColumnCount: Integer; RowCount: Integer; var "Table": DotNet Table)
    var
        TableColumns: DotNet TableColumns;
        TablePart: DotNet TablePart;
        TableParts: DotNet TableParts;
        TableDefinitionPart: DotNet TableDefinitionPart;
        Reference: Text;
    begin
        Reference := 'A' + Format(StartFromRow) + ':' + GetXLColumnID(ColumnCount) + Format(RowCount + StartFromRow);

        InitTable(WorksheetWriter, Table, Reference, 1);
        AppendAutoFilter(Table);
        AppendTableStyleInfo(Table);
        TableColumns := WorksheetWriter.CreateTableColumns(ColumnCount);
        Table.TableColumns(TableColumns);

        TableDefinitionPart := WorksheetWriter.CreateTableDefinitionPart();
        TableDefinitionPart.Table := Table;

        TableParts := WorksheetWriter.CreateTableParts(1);
        WrkShtHelper.AppendElementToOpenXmlElement(WorksheetWriter.Worksheet, TableParts);
        TablePart := WorksheetWriter.CreateTablePart(WorksheetWriter.Worksheet.WorksheetPart.GetIdOfPart(TableDefinitionPart));
        WrkShtHelper.AppendElementToOpenXmlElement(TableParts, TablePart);
    end;

    [Scope('OnPrem')]
    procedure AddWorkSheetAuthor(Comments: DotNet Comments; AuthorText: Text)
    var
        Author: DotNet Author;
        Authors: DotNet Authors;
    begin
        Authors := Authors.Authors();
        WrkShtHelper.AppendElementToOpenXmlElement(Comments, Authors);
        Author := Author.Author();
        Author.Text := AuthorText;
        WrkShtHelper.AppendElementToOpenXmlElement(Authors, Author);
    end;

    [Scope('OnPrem')]
    procedure AppendAutoFilter(var "Table": DotNet Table)
    var
        AutoFilter: DotNet AutoFilter;
        StringValue: DotNet StringValue;
    begin
        AutoFilter := AutoFilter.AutoFilter();
        AutoFilter.Reference := StringValue.StringValue(Table.Reference.Value);
        WrkShtHelper.AppendElementToOpenXmlElement(Table, AutoFilter);
    end;

    [Scope('OnPrem')]
    procedure AppendTableStyleInfo(var "Table": DotNet Table)
    var
        BooleanValue: DotNet BooleanValue;
        StringValue: DotNet StringValue;
        TableStyleInfo: DotNet TableStyleInfo;
    begin
        TableStyleInfo := TableStyleInfo.TableStyleInfo();
        TableStyleInfo.Name := StringValue.StringValue('TableStyleMedium2');
        TableStyleInfo.ShowFirstColumn := BooleanValue.BooleanValue(false);
        TableStyleInfo.ShowLastColumn := BooleanValue.BooleanValue(false);
        TableStyleInfo.ShowRowStripes := BooleanValue.BooleanValue(true);
        TableStyleInfo.ShowColumnStripes := BooleanValue.BooleanValue(false);
        WrkShtHelper.AppendElementToOpenXmlElement(Table, TableStyleInfo);
    end;

    [Scope('OnPrem')]
    procedure CleanMapInfo(MapInfo: DotNet MapInfo)
    var
        MapInfoString: Text;
    begin
        MapInfoString :=
          ReplaceSubString(
            Format(MapInfo.OuterXml),
            '<x:MapInfo SelectionNamespaces="" xmlns:x="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
            '');
        MapInfoString := ReplaceSubString(MapInfoString, '</x:MapInfo>', '');
        MapInfoString := ReplaceSubString(MapInfoString, 'x:', '');
        MapInfo.InnerXml(MapInfoString);
    end;

    procedure CreateBook(var TempBlob: Codeunit "Temp Blob"; var WrkBkWriter: DotNet WorkbookWriter)
    var
        IStream: InStream;
    begin
        Clear(WrkBkWriter);
        TempBlob.CreateInStream(IStream);
        WrkBkWriter := WrkBkWriter.Create(IStream);
        if IsNull(WrkBkWriter) then
            Error(CreateWrkBkFailedErr);
    end;

    [Scope('OnPrem')]
    procedure CreateSchemaConnection(var WrkbkWriter: DotNet WorkbookWriter; SetupDataFileName: Text)
    var
        ConnectionsPart: DotNet ConnectionsPart;
        Connections: DotNet Connections;
        Connection: DotNet Connection;
        UInt32Value: DotNet UInt32Value;
        StringValue: DotNet StringValue;
        BooleanTrueValue: DotNet BooleanValue;
        WebQueryProperties: DotNet WebQueryProperties;
        ByteValue: DotNet ByteValue;
    begin
        ConnectionsPart := WrkbkWriter.AddConnectionsPart();
        Connections := Connections.Connections();
        Connection := WrkbkWriter.CreateConnection(1);
        UInt32Value := UInt32Value.UInt32Value();
        Connection.Name := StringValue.StringValue(FileMgt.GetFileName(SetupDataFileName));
        UInt32Value.Value := 4;
        Connection.Type := UInt32Value;
        BooleanTrueValue := BooleanTrueValue.BooleanValue(true);
        Connection.Background := BooleanTrueValue;
        ByteValue := ByteValue.ByteValue();
        ByteValue.Value := 0;
        Connection.RefreshedVersion := ByteValue;
        WebQueryProperties := WebQueryProperties.WebQueryProperties();
        WebQueryProperties.XmlSource := BooleanTrueValue;
        WebQueryProperties.SourceData := BooleanTrueValue;
        WebQueryProperties.Url := StringValue.StringValue(SetupDataFileName);
        WebQueryProperties.HtmlTables := BooleanTrueValue;
        WrkShtHelper.AppendElementToOpenXmlElement(Connection, WebQueryProperties);
        WrkShtHelper.AppendElementToOpenXmlElement(Connections, Connection);
        ConnectionsPart.Connections := Connections;
    end;

    [Scope('OnPrem')]
    procedure CreateTableStyles(Workbook: DotNet Workbook)
    var
        Stylesheet: DotNet Stylesheet;
        Tablestyles: DotNet TableStyles;
        UInt32Value: DotNet UInt32Value;
        StringValue: DotNet StringValue;
    begin
        Tablestyles := Tablestyles.TableStyles();
        UInt32Value := UInt32Value.UInt32Value();
        UInt32Value.Value := 0;
        Tablestyles.Count := UInt32Value;
        Tablestyles.DefaultTableStyle := StringValue.StringValue('TableStyleMedium2');
        Tablestyles.DefaultPivotStyle := StringValue.StringValue('PivotStyleLight16');

        Stylesheet := Workbook.WorkbookPart.WorkbookStylesPart.Stylesheet;
        WrkShtHelper.AppendElementToOpenXmlElement(Stylesheet, Tablestyles);
    end;

    [Scope('OnPrem')]
    procedure CloseBook(var WrkBkWriter: DotNet WorkbookWriter)
    begin
        WrkBkWriter.Workbook.Save();
        WrkBkWriter.Close();
        Clear(WrkBkWriter);
    end;

    /// <summary>
    /// A CopyDataToExcelTable function overload with HideDialog parameter set to true.
    /// </summary>
    [Scope('OnPrem')]
    procedure CopyDataToExcelTable(WorksheetWriter: DotNet WorksheetWriter; DataTable: DotNet DataTable)
    begin
        CopyDataToExcelTable(WorksheetWriter, DataTable, true);
    end;

    [Scope('OnPrem')]
    procedure CopyDataToExcelTable(WorksheetWriter: DotNet WorksheetWriter; DataTable: DotNet DataTable; HideDialog: Boolean)
    var
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        DataColumn: DotNet DataColumn;
        DataRow: DotNet DataRow;
        DataTableRowsCount: Integer;
        RowsCount: Integer;
        ColumnsCount: Integer;
        DataTableColumnsCount: Integer;
        StepCount: Integer;
        ShowDialog: Boolean;
    begin
        DataTableRowsCount := DataTable.Rows.Count();
        RowsCount := 0;
        DataTableColumnsCount := DataTable.Columns.Count();

        ShowDialog := (not HideDialog) and (DataTableRowsCount > 1000);
        if ShowDialog then begin
            StepCount := Round(DataTableRowsCount / 100, 1);
            ConfigProgressBar.Init(DataTableRowsCount, StepCount, CopyDataProgressTxt);
        end;

        repeat
            DataRow := DataTable.Rows.Item(RowsCount);
            ColumnsCount := 0;
            repeat
                DataColumn := DataTable.Columns.Item(ColumnsCount);
                WriteCellValue(WorksheetWriter, Format(DataColumn.DataType), DataRow, RowsCount, ColumnsCount);
                ColumnsCount += 1;
            until ColumnsCount = DataTableColumnsCount - 1;
            RowsCount += 1;

            if ShowDialog then
                ConfigProgressBar.Update(StrSubstNo(ProgressStatusTxt, WorksheetWriter.Name, RowsCount, DataTableRowsCount));
        until RowsCount = DataTableRowsCount;

        if ShowDialog then
            ConfigProgressBar.Close();
    end;

    [Scope('OnPrem')]
    procedure ExtractXMLSchema(WorkBookPart: DotNet WorkbookPart) XMLSchemaDataFile: Text
    var
        XMLWriter: DotNet XmlWriter;
    begin
        if IsNull(WorkBookPart.CustomXmlMappingsPart) then
            Error(MissingXMLMapErr);
        if IsNull(WorkBookPart.CustomXmlMappingsPart.MapInfo) then
            Error(MissingXMLMapErr);
        XMLSchemaDataFile := FileMgt.ServerTempFileName('');
        FileMgt.IsAllowedPath(XMLSchemaDataFile, false);
        XMLWriter := XMLWriter.Create(XMLSchemaDataFile);
        WorkBookPart.CustomXmlMappingsPart.MapInfo.FirstChild.FirstChild.WriteTo(XMLWriter);
        XMLWriter.Close();
    end;

    [Scope('OnPrem')]
    procedure FindTableDefinition(WrkShtReader: DotNet WorksheetReader; var "Table": DotNet Table): Boolean
    var
        TableDefinitionPart: DotNet TableDefinitionPart;
        Enumerable: DotNet IEnumerable;
        Enumerator: DotNet IEnumerator;
    begin
        Enumerable := WrkShtReader.Worksheet.WorksheetPart.TableDefinitionParts;
        Enumerator := Enumerable.GetEnumerator();
        Enumerator.MoveNext();
        TableDefinitionPart := Enumerator.Current;
        if IsNull(TableDefinitionPart) then
            exit(false);

        Table := TableDefinitionPart.Table;
        exit(true);
    end;

    procedure GetElementName(NameIn: Text): Text
    begin
        NameIn := DelChr(NameIn, '=', '?''`');
        NameIn := ConvertStr(NameIn, '<>,./\+&()%:', '            ');
        NameIn := ConvertStr(NameIn, '-', '_');
        NameIn := DelChr(NameIn, '=', ' ');
        exit(NameIn);
    end;

    procedure GetXLColumnID(ColumnNo: Integer): Text[10]
    var
        ExcelBuf: Record "Excel Buffer";
    begin
        ExcelBuf.Init();
        ExcelBuf.Validate("Column No.", ColumnNo);
        exit(ExcelBuf.xlColID);
    end;

    [Scope('OnPrem')]
    procedure ImportSchema(var WrkbkWriter: DotNet WorkbookWriter; SchemaFileName: Text; MapId: BigInteger; RootElementName: Text)
    var
        CustomXMLMappingsPart: DotNet CustomXmlMappingsPart;
        MapInfo: DotNet MapInfo;
        "Schema": DotNet Schema;
        StreamReader: DotNet StreamReader;
        Map: DotNet Map;
        DataBinding: DotNet DataBinding;
        UInt32Value: DotNet UInt32Value;
        StringValue: DotNet StringValue;
        BooleanValue: DotNet BooleanValue;
        StreamText: Text;
    begin
        StreamReader := StreamReader.StreamReader(SchemaFileName);
        StreamReader.ReadLine();
        StreamText := StreamReader.ReadToEnd();
        StreamReader.Close();
        Schema := WrkbkWriter.CreateSchemaFromText(StreamText);
        Schema.Id := StringValue.StringValue('Schema1');

        MapInfo := MapInfo.MapInfo();
        MapInfo.SelectionNamespaces := StringValue.StringValue('');
        WrkShtHelper.AppendElementToOpenXmlElement(MapInfo, Schema);
        Map := Map.Map();
        UInt32Value := UInt32Value.UInt32Value();
        UInt32Value.Value := MapId;
        Map.ID := UInt32Value;
        Map.Name := StringValue.StringValue(RootElementName + '_Map');
        Map.RootElement := StringValue.StringValue(RootElementName);
        Map.SchemaId := Schema.Id;
        Map.ShowImportExportErrors := BooleanValue.BooleanValue(false);
        Map.AutoFit := BooleanValue.BooleanValue(true);
        Map.AppendData := BooleanValue.BooleanValue(false);
        Map.PreserveAutoFilterState := BooleanValue.BooleanValue(true);
        Map.PreserveFormat := BooleanValue.BooleanValue(true);

        DataBinding := DataBinding.DataBinding();
        DataBinding.FileBinding := BooleanValue.BooleanValue(true);
        DataBinding.ConnectionId := Map.ID;
        UInt32Value.Value := 1;
        DataBinding.DataBindingLoadMode := UInt32Value;
        WrkShtHelper.AppendElementToOpenXmlElement(MapInfo, Map);
        WrkShtHelper.AppendElementToOpenXmlElement(Map, DataBinding);

        CustomXMLMappingsPart := WrkbkWriter.AddCustomXmlMappingsPart();
        CustomXMLMappingsPart.MapInfo := MapInfo;
    end;

    local procedure InitTable(var WorksheetWriter: DotNet WorksheetWriter; var "Table": DotNet Table; Reference: Text; ConnectionId: Integer)
    var
        BooleanValue: DotNet BooleanValue;
        StringValue: DotNet StringValue;
        UInt32Value: DotNet UInt32Value;
    begin
        UID += 1;
        Table := WorksheetWriter.CreateTable(UID);
        Table.Name := StringValue.StringValue('Table' + Format(UID));
        Table.DisplayName := StringValue.StringValue('Table' + Format(UID));
        Table.Reference := StringValue.StringValue(Reference);
        Table.TotalsRowShown := BooleanValue.BooleanValue(false);

        UInt32Value := UInt32Value.UInt32Value();
        UInt32Value.Value := ConnectionId;
        Table.ConnectionId := UInt32Value;
    end;

    procedure OpenBook(var TempBlob: Codeunit "Temp Blob"; var WrkBkReader: DotNet WorkbookReader)
    var
        IStream: InStream;
    begin
        Clear(WrkBkReader);
        TempBlob.CreateInStream(IStream);
        WrkBkReader := WrkBkReader.Open(IStream);
        if IsNull(WrkBkReader) then
            Error(OpenWrkBkFailedErr);
    end;

    local procedure ReplaceSubString(String: Text; Old: Text; New: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(String, Old);
        while Pos <> 0 do begin
            String := DelStr(String, Pos, StrLen(Old));
            String := InsStr(String, New, Pos);
            Pos := StrPos(String, Old);
        end;
        exit(String);
    end;

    [Scope('OnPrem')]
    procedure SetCellComment(WrkShtWriter: DotNet WorksheetWriter; CellReference: Text; CommentValue: Text)
    var
        Comment: DotNet Comment;
        CommentText: DotNet CommentText;
        Run: DotNet Run;
        UInt32Value: DotNet UInt32Value;
        StringValue: DotNet StringValue;
        Int32Value: DotNet Int32Value;
        CommentList: DotNet CommentList;
        Comments: DotNet Comments;
        SpreadsheetText: DotNet Text;
        RunProperties: DotNet RunProperties;
        CommentsPart: DotNet WorksheetCommentsPart;
        Bold: DotNet Bold;
        FontSize: DotNet FontSize;
        DoubleValue: DotNet DoubleValue;
        Color: DotNet "Spreadsheet.Color";
        RunFont: DotNet RunFont;
        RunPropCharSet: DotNet RunPropertyCharSet;
    begin
        CommentsPart := WrkShtWriter.Worksheet.WorksheetPart.WorksheetCommentsPart;
        Comments := CommentsPart.Comments;

        if IsNull(Comments) then begin
            Comments := Comments.Comments();
            CommentsPart.Comments := Comments;
        end;

        CommentList := Comments.CommentList;

        if IsNull(CommentList) then
            CommentList := WrkShtWriter.CreateCommentList(Comments);

        Comment := Comment.Comment();
        Comment.AuthorId := UInt32Value.FromUInt32(0);
        Comment.Reference := StringValue.StringValue(CellReference);

        CommentText := CommentText.CommentText();

        Run := Run.Run();

        RunProperties := RunProperties.RunProperties();
        Bold := Bold.Bold();

        FontSize := FontSize.FontSize();
        FontSize.Val := DoubleValue.FromDouble(9);

        Color := Color.Color();
        Color.Indexed := UInt32Value.FromUInt32(81);

        RunFont := RunFont.RunFont();
        RunFont.Val := StringValue.FromString('Tahoma');

        RunPropCharSet := RunPropCharSet.RunPropertyCharSet();
        RunPropCharSet.Val := Int32Value.FromInt32(1);

        WrkShtHelper.AppendElementToOpenXmlElement(RunProperties, Bold);
        WrkShtHelper.AppendElementToOpenXmlElement(RunProperties, FontSize);
        WrkShtHelper.AppendElementToOpenXmlElement(RunProperties, Color);
        WrkShtHelper.AppendElementToOpenXmlElement(RunProperties, RunFont);
        WrkShtHelper.AppendElementToOpenXmlElement(RunProperties, RunPropCharSet);

        SpreadsheetText := WrkShtWriter.AddText(CommentValue);
        SpreadsheetText.Text := CommentValue;

        WrkShtHelper.AppendElementToOpenXmlElement(Run, RunProperties);
        WrkShtHelper.AppendElementToOpenXmlElement(Run, SpreadsheetText);

        WrkShtHelper.AppendElementToOpenXmlElement(CommentText, Run);
        Comment.CommentText := CommentText;

        WrkShtWriter.AppendComment(CommentList, Comment);

        CommentsPart.Comments.Save();
        WrkShtWriter.Worksheet.Save();
    end;

    [Scope('OnPrem')]
    procedure SetSingleCellValue(var WrkShtWriter: DotNet WorksheetWriter; var SingleXMLCells: DotNet SingleXmlCells; RowNo: Integer; ColumnNo: Text; Value: Text; XPath: Text)
    var
        SingleXMLCell: DotNet SingleXmlCell;
    begin
        UID += 1;
        SingleXMLCell := WrkShtWriter.AddSingleXmlCell(UID);
        WrkShtHelper.AppendElementToOpenXmlElement(SingleXMLCells, SingleXMLCell);
        AddSingleXMLCellProperties(SingleXMLCell, ColumnNo + Format(RowNo), XPath, 1, 1);
        WrkShtWriter.SetCellValueText(RowNo, ColumnNo, Value, WrkShtWriter.DefaultCellDecorator);
    end;

    [Scope('OnPrem')]
    procedure SetupWorksheetHelper(WorkbookWriter: DotNet WorkbookWriter)
    begin
        WrkShtHelper := WrkShtHelper.WorksheetHelper(WorkbookWriter.FirstWorksheet.Worksheet);
    end;

    [Scope('OnPrem')]
    procedure WriteCellValue(var WrkShtWriter: DotNet WorksheetWriter; DataColumnDataType: Text; var DataRow: DotNet DataRow; RowsCount: Integer; ColumnsCount: Integer)
    begin
        OnBeforeWriteCellValue(RowsCount);

        case DataColumnDataType of
            'System.DateTime':
                WrkShtWriter.SetCellValueDate(
                  RowsCount + 4, GetXLColumnID(ColumnsCount + 1), DataRow.Item(ColumnsCount), '',
                  WrkShtWriter.DefaultCellDecorator);
            'System.Time':
                WrkShtWriter.SetCellValueTime(
                  RowsCount + 4, GetXLColumnID(ColumnsCount + 1), DataRow.Item(ColumnsCount), '',
                  WrkShtWriter.DefaultCellDecorator);
            'System.Boolean':
                WrkShtWriter.SetCellValueBoolean(
                  RowsCount + 4, GetXLColumnID(ColumnsCount + 1), DataRow.Item(ColumnsCount),
                  WrkShtWriter.DefaultCellDecorator);
            'System.Integer', 'System.Int32':
                WrkShtWriter.SetCellValueNumber(
                  RowsCount + 4, GetXLColumnID(ColumnsCount + 1), Format(DataRow.Item(ColumnsCount)), '',
                  WrkShtWriter.DefaultCellDecorator);
            else
                WrkShtWriter.SetCellValueText(
                  RowsCount + 4, GetXLColumnID(ColumnsCount + 1), DataRow.Item(ColumnsCount),
                  WrkShtWriter.DefaultCellDecorator);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateCommentVmlShapeXml(ColId: Integer; RowId: Integer) CommentShape: Text
    var
        Guid: Guid;
        Anchor: Text;
    begin
        Guid := CreateGuid();

        Anchor := CreateCommentVmlAnchor(ColId, RowId);

        CommentShape := StrSubstNo(CommentVmlShapeXmlTxt, Guid, Anchor, RowId - 1, ColId - 1);
    end;

    local procedure CreateCommentVmlAnchor(ColId: Integer; RowId: Integer): Text
    begin
        exit(StrSubstNo(VmlShapeAnchorTxt, ColId, RowId - 2, ColId + 2, RowId + 5));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWriteCellValue(var RowsCount: Integer)
    begin
    end;
}

