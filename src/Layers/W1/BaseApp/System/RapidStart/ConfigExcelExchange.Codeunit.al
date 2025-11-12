namespace System.IO;

using Microsoft.Finance.Dimension;
using System;
using System.Reflection;
using System.Utilities;
using System.Xml;

codeunit 8618 "Config. Excel Exchange"
{

    trigger OnRun()
    begin
    end;

    var
        SelectedConfigPackage: Record "Config. Package";
        TempSelectedTable: Record "Integer" temporary;
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        FileMgt: Codeunit "File Management";
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        OpenXMLManagement: Codeunit "OpenXML Management";
        TypeHelper: Codeunit "Type Helper";
        WrkbkReader: DotNet WorkbookReader;
        WrkbkWriter: DotNet WorkbookWriter;
        WrkShtWriter: DotNet WorksheetWriter;
        Worksheet: DotNet Worksheet;
        Workbook: DotNet Workbook;
        WorkBookPart: DotNet WorkbookPart;
        CreateWrkBkFailedErr: Label 'Could not create the Excel workbook.';
        WrkShtHelper: DotNet WorksheetHelper;
        DataSet: DotNet DataSet;
        DataTable: DotNet DataTable;
        DataColumn: DotNet DataColumn;
        StringBld: DotNet StringBuilder;
        id: BigInteger;
        HideDialog: Boolean;
        FileOnServer: Boolean;

        CannotCreateXmlSchemaErr: Label 'Could not create XML Schema.';
        CreatingExcelMsg: Label 'Creating Excel worksheet';
        VmlDrawingXmlTxt: Label '<xml xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel"><o:shapelayout v:ext="edit"><o:idmap v:ext="edit" data="1"/></o:shapelayout><v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202"  path="m,l,21600r21600,l21600,xe"><v:stroke joinstyle="miter"/><v:path gradientshapeok="t" o:connecttype="rect"/></v:shapetype>', Locked = true;
        EndXmlTokenTxt: Label '</xml>', Locked = true;
        FileExtensionFilterTok: Label 'Excel Files (*.xlsx)|*.xlsx|All Files (*.*)|*.*';
        ExcelFileNameTok: Label '*%1.xlsx', Comment = '%1 = String generated from current datetime to make sure file names are unique ';
        ExcelFileExtensionTok: Label '.xlsx';
        InvalidDataInSheetMsg: Label 'Data in sheet ''%1'' could not be imported, because the sheet has an unexpected format.', Comment = '%1=excel sheet name';
        ImportFromExcelMsg: Label 'Import from Excel';
        RapidStartTxt: Label 'RapidStart', Locked = true;

    procedure ExportExcelFromConfig(var ConfigLine: Record "Config. Line"): Text
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigMgt: Codeunit "Config. Management";
        FileName: Text;
        "Filter": Text;
    begin
        ConfigLine.FindFirst();
        ConfigPackageTable.SetRange("Package Code", ConfigLine."Package Code");
        Filter := ConfigMgt.MakeTableFilter(ConfigLine, true);
        if Filter <> '' then
            ConfigPackageTable.SetFilter("Table ID", Filter);

        ConfigPackageTable.SetRange("Dimensions as Columns", true);
        if ConfigPackageTable.FindSet() then
            repeat
                if not (ConfigPackageTable.DimensionPackageDataExist() or (ConfigPackageTable.DimensionFieldsCount() > 0)) then
                    ConfigPackageTable.InitDimensionFields();
            until ConfigPackageTable.Next() = 0;
        ConfigPackageTable.SetRange("Dimensions as Columns");
        OnExportExcelFromConfigOnBeforeExportExcel(ConfigLine, ConfigPackageTable);
        ExportExcel(FileName, ConfigPackageTable, true, false);
        exit(FileName);
    end;

    procedure ExportExcelFromPackage(ConfigPackage: Record "Config. Package"): Boolean
    var
        ConfigPackageTable: Record "Config. Package Table";
        FileName: Text;
    begin
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        exit(ExportExcel(FileName, ConfigPackageTable, false, false));
    end;

    procedure ExportExcelFromTables(var ConfigPackageTable: Record "Config. Package Table"): Boolean
    var
        FileName: Text;
    begin
        exit(ExportExcel(FileName, ConfigPackageTable, false, false));
    end;

    procedure ExportExcelTemplateFromTables(var ConfigPackageTable: Record "Config. Package Table") Result: Boolean
    var
        FileName: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportExcelTemplateFromTables(ConfigPackageTable, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ExportExcel(FileName, ConfigPackageTable, false, true));
    end;

    procedure ExportExcel(var FileName: Text; var ConfigPackageTable: Record "Config. Package Table"; ExportFromWksht: Boolean; SkipData: Boolean): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        VmlDrawingPart: DotNet VmlDrawingPart;
        TableDefinitionPart: DotNet TableDefinitionPart;
        TableParts: DotNet TableParts;
        TablePart: DotNet TablePart;
        SingleXMLCells: DotNet SingleXmlCells;
        XmlTextWriter: DotNet XmlTextWriter;
        FileMode: DotNet FileMode;
        Encoding: DotNet Encoding;
        Caption: Text;
        RootElementName: Text;
        TempSetupDataFileName: Text;
        TempSchemaFileName: Text;
        ExcelExportStartMsg: Label 'Export of Excel data started.', Locked = true;
        ExcelExportFinishMsg: Label 'Export of Excel data finished. Duration: %1 milliseconds.', Locked = true;
        DurationAsInt: BigInteger;
        StartTime: DateTime;
        DataTableCounter: Integer;
    begin
        StartTime := CurrentDateTime();
        Session.LogMessage('00009QA', ExcelExportStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

        OnBeforeExportExcel(ConfigPackageTable);

        Clear(ExportFromWksht); // Obsolete parameter
        TempSchemaFileName := CreateSchemaFile(ConfigPackageTable, RootElementName);
        TempSetupDataFileName := BuildDataSetForPackageTable(ConfigPackageTable);

        CreateBook(TempBlob);
        WrkShtHelper := WrkShtHelper.WorksheetHelper(WrkbkWriter.FirstWorksheet.Worksheet);
        OpenXMLManagement.ImportSchema(WrkbkWriter, TempSchemaFileName, 1, RootElementName);
        OpenXMLManagement.CreateSchemaConnection(WrkbkWriter, TempSetupDataFileName);

        DataTableCounter := 1;

        if not HideDialog then
            ConfigProgressBar.Init(ConfigPackageTable.Count, 1, CreatingExcelMsg);

        DataTable := DataSet.Tables.Item(1);

        if ConfigPackageTable.FindSet() then
            repeat
                if IsNull(StringBld) then begin
                    StringBld := StringBld.StringBuilder();
                    StringBld.Append(VmlDrawingXmlTxt);
                end;

                ConfigPackageTable.CalcFields("Table Caption");
                if not HideDialog then
                    ConfigProgressBar.Update(ConfigPackageTable."Table Caption");

                // Initialize WorkSheetWriter
                Caption := DelChr(ConfigPackageTable."Table Caption", '=', '/');
                if id < 1 then begin
                    WrkShtWriter := WrkbkWriter.FirstWorksheet;
                    WrkShtWriter.Name := Caption;
                end else
                    WrkShtWriter := WrkbkWriter.AddWorksheet(GetExcelWorksheetName(Caption, Format(ConfigPackageTable."Table ID")));
                Worksheet := WrkShtWriter.Worksheet;

                // Add and initialize SingleCellTable part
                WrkShtWriter.AddSingleCellTablePart();
                SingleXMLCells := SingleXMLCells.SingleXmlCells();
                Worksheet.WorksheetPart.SingleCellTablePart.SingleXmlCells := SingleXMLCells;
                id += 3;

                OpenXMLManagement.AddAndInitializeCommentsPart(WrkShtWriter, VmlDrawingPart);
                AddPackageAndTableInformation(ConfigPackageTable, SingleXMLCells);
                AddAndInitializeTableDefinitionPart(ConfigPackageTable, DataTableCounter, TableDefinitionPart, SkipData);
                if not SkipData then
                    OpenXMLManagement.CopyDataToExcelTable(WrkShtWriter, DataTable, HideDialog);

                DataTableCounter += 2;

                OnExportExcelOnBeforeWrkShtWriterCreateTableParts(ConfigPackageTable, DataTableCounter);

                TableParts := WrkShtWriter.CreateTableParts(1);
                WrkShtHelper.AppendElementToOpenXmlElement(Worksheet, TableParts);
                TablePart := WrkShtWriter.CreateTablePart(Worksheet.WorksheetPart.GetIdOfPart(TableDefinitionPart));
                WrkShtHelper.AppendElementToOpenXmlElement(TableParts, TablePart);

                StringBld.Append(EndXmlTokenTxt);

                XmlTextWriter := XmlTextWriter.XmlTextWriter(VmlDrawingPart.GetStream(FileMode.Create), Encoding.UTF8);
                XmlTextWriter.WriteRaw(StringBld.ToString());
                XmlTextWriter.Flush();
                XmlTextWriter.Close();

                Clear(StringBld);

            until ConfigPackageTable.Next() = 0;

        FILE.Erase(TempSchemaFileName);
        FILE.Erase(TempSetupDataFileName);

        OpenXMLManagement.CleanMapInfo(WrkbkWriter.Workbook.WorkbookPart.CustomXmlMappingsPart.MapInfo);
        WrkbkWriter.Workbook.Save();
        WrkbkWriter.Close();
        ClearOpenXmlVariables();

        if not HideDialog then
            ConfigProgressBar.Close();

        if FileName = '' then
            FileName :=
              StrSubstNo(ExcelFileNameTok, Format(CurrentDateTime, 0, '<Day,2>_<Month,2>_<Year4>_<Hours24>_<Minutes,2>_<Seconds,2>'));

        DurationAsInt := CurrentDateTime() - StartTime;

        Session.LogMessage('00009QB', StrSubstNo(ExcelExportFinishMsg, DurationAsInt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

        OnBeforeBLOBExport(TempBlob);
        if not FileOnServer then
            FileName := FileMgt.BLOBExport(TempBlob, FileName, not HideDialog)
        else
            FileMgt.BLOBExportToServerFile(TempBlob, FileName);

        exit(FileName <> '');
    end;

    procedure ImportExcelFromConfig(ConfigLine: Record "Config. Line")
    var
        ConfigPackage: Record "Config. Package";
        TempBlob: Codeunit "Temp Blob";
    begin
        ConfigLine.TestField("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.TestField("Table ID");
        if ConfigPackage.Get(ConfigLine."Package Code") and IsFileImportedToBLOB(TempBlob) then
            ImportExcel(TempBlob);
    end;

    procedure ImportExcelFromPackage(): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        if not IsFileImportedToBLOB(TempBlob) then
            exit(false);
        if GuiAllowed() then
            if ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromExcel(TempBlob.Length()) = Action::Cancel then
                exit(false);
        exit(ImportExcel(TempBlob));
    end;

    procedure ImportExcelFromSelectedPackage(PackageCode: Code[20]): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        SelectedConfigPackage.Get(PackageCode);
        if IsFileImportedToBLOB(TempBlob) then
            exit(ImportExcel(TempBlob));
        exit(false)
    end;

    procedure SetSelectedTables(var ConfigPackageTable: Record "Config. Package Table")
    begin
        if ConfigPackageTable.FindSet() then
            repeat
                TempSelectedTable.Number := ConfigPackageTable."Table ID";
                if TempSelectedTable.Insert() then;
            until ConfigPackageTable.Next() = 0;
    end;

    local procedure IsTableSelected(TableId: Integer): Boolean
    begin
        if TempSelectedTable.IsEmpty() then
            exit(true);
        exit(TempSelectedTable.Get(TableId));
    end;

    local procedure IsWorksheetSelected(var TempConfigPackageTable: Record "Config. Package Table" temporary; WrksheetId: Integer): Boolean
    begin
        TempConfigPackageTable.Reset();
        TempConfigPackageTable.SetRange("Processing Order", WrksheetId);
        exit(not TempConfigPackageTable.IsEmpty);
    end;

    local procedure IsImportFromExcelConfirmed(var TempConfigPackageTable: Record "Config. Package Table" temporary): Boolean
    var
        ConfigPackageImportPreview: Page "Config. Package Import Preview";
        ShowDialog, Result, IsHandled : Boolean;
    begin
        ShowDialog := GuiAllowed() and not HideDialog;
        if ReadPackageTableKeysFromExcel(TempConfigPackageTable, ShowDialog) and ShowDialog then begin
            OnIsImportFromExcelConfirmedOnAfterReadFromExcel(Result, IsHandled);
            if IsHandled then
                exit(Result);
            ConfigPackageImportPreview.SetData(SelectedConfigPackage.Code, TempConfigPackageTable);
            ConfigPackageImportPreview.RunModal();
            exit(ConfigPackageImportPreview.IsImportConfirmed());
        end;
        exit(true);
    end;

    [TryFunction]
    local procedure ReadPackageTableKeysFromExcel(var TempConfigPackageTable: Record "Config. Package Table" temporary; ShowDialog: Boolean)
    var
        WrkShtReader: DotNet WorksheetReader;
        Enumerator: DotNet IEnumerator;
        CellData: DotNet CellData;
        Window: Dialog;
        WrkSheetId: Integer;
        SheetCount: Integer;
    begin
        if ShowDialog then
            Window.Open(ImportFromExcelMsg);
        WrkSheetId := WrkbkReader.FirstSheetId;
        SheetCount := WrkbkReader.Workbook.Sheets.ChildElements.Count + WrkSheetId;
        repeat
            WrkShtReader := WrkbkReader.GetWorksheetById(Format(WrkSheetId));
            Enumerator := WrkShtReader.GetEnumerator();
            while NextCellInRow(Enumerator, CellData, 1) do
                FillImportPreviewBuffer(TempConfigPackageTable, WrkSheetId, CellData.ColumnNumber, CellData.Value);
            WrkSheetId += 1;
        until WrkSheetId >= SheetCount;
        TempSelectedTable.DeleteAll();
        if TempConfigPackageTable.FindFirst() then;
        if ShowDialog then
            Window.Close();
    end;

    local procedure FillImportPreviewBuffer(var TempConfigPackageTable: Record "Config. Package Table" temporary; WrkSheetId: Integer; ColumnNo: Integer; Value: Text)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
    begin
        case ColumnNo of
            1:
                // first column contains Package Code
                TempConfigPackageTable."Package Code" := CopyStr(Value, 1, MaxStrLen(TempConfigPackageTable."Package Code"));
            3:
                // third column contains Table ID
                begin
                    TempConfigPackageTable."Processing Order" := WrkSheetId;
                    Evaluate(TempConfigPackageTable."Table ID", Value);
                    TempConfigPackageTable."Delayed Insert" := not ConfigPackage.Get(TempConfigPackageTable."Package Code");
                    // New Package flag value
                    TempConfigPackageTable.Validated := not ConfigPackageTable.Get(TempConfigPackageTable."Package Code", TempConfigPackageTable."Table ID");
                    // New Table flag value
                    if IsTableSelected(TempConfigPackageTable."Table ID") then
                        TempConfigPackageTable.Insert();
                end;
        end;
    end;

    local procedure NextCellInRow(Enumerator: DotNet IEnumerator; CellData: DotNet CellData; RowNo: Integer): Boolean
    begin
        if Enumerator.MoveNext() then begin
            CellData := Enumerator.Current;
            exit(CellData.RowNumber = RowNo);
        end;
    end;

    procedure ImportExcel(var TempBlob: Codeunit "Temp Blob") Imported: Boolean
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        WorkBookPart: DotNet WorkbookPart;
        InStream: InStream;
        XMLSchemaDataFile: Text;
        WrkSheetId: Integer;
        DataColumnTableId: Integer;
        SheetCount: Integer;
        ExcelImportStartMsg: Label 'Converting Excel data started.', Locked = true;
        ExcelImportFinishMsg: Label 'Converting Excel data finished. Duration: %1 milliseconds. File size: %2.', Locked = true;
        DurationAsInt: BigInteger;
        StartTime: DateTime;
        FileSize: Integer;
    begin
        TempBlob.CreateInStream(InStream);
        FileSize := TempBlob.Length();
        WrkbkReader := WrkbkReader.Open(InStream);
        if not IsImportFromExcelConfirmed(TempConfigPackageTable) then begin
            Clear(WrkbkReader);
            exit(false);
        end;

        StartTime := CurrentDateTime();
        Session.LogMessage('00009QC', ExcelImportStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
        WorkBookPart := WrkbkReader.Workbook.WorkbookPart;
        XMLSchemaDataFile := OpenXMLManagement.ExtractXMLSchema(WorkBookPart);

        WrkSheetId := WrkbkReader.FirstSheetId;
        SheetCount := WorkBookPart.Workbook.Sheets.ChildElements.Count + WrkSheetId;
        DataSet := DataSet.DataSet();
        DataSet.ReadXmlSchema(XMLSchemaDataFile);

        WrkSheetId := WrkbkReader.FirstSheetId;
        DataColumnTableId := 0;
        repeat
            if IsWorksheetSelected(TempConfigPackageTable, WrkSheetId) then
                ReadWorksheetData(WrkSheetId, DataColumnTableId);
            WrkSheetId += 1;
            DataColumnTableId += 2;
        until WrkSheetId >= SheetCount;

        Clear(TempBlob);
        TempBlob.CreateInStream(InStream);
        DataSet.WriteXml(InStream);
        ConfigXMLExchange.SetExcelMode(true);

        DurationAsInt := CurrentDateTime() - StartTime;

        Session.LogMessage('00009QD', StrSubstNo(ExcelImportFinishMsg, DurationAsInt, FileSize), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
        if ConfigXMLExchange.ImportPackageXMLFromStream(InStream) then
            Imported := true;

        exit(Imported);
    end;

    local procedure ReadWorksheetData(WrkSheetId: Integer; DataColumnTableId: Integer)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        CellData: DotNet CellData;
        DataRow: DotNet DataRow;
        DataRow2: DotNet DataRow;
        Enumerator: DotNet IEnumerator;
        Type: DotNet Type;
        WrkShtReader: DotNet WorksheetReader;
        SheetHeaderRead: Boolean;
        ColumnInt: Integer;
        ColumnCount: Integer;
        TotalColumnCount: Integer;
        RowIn: Integer;
        CurrentRowIndex: Integer;
        RowChanged: Boolean;
        FirstDataRow: Integer;
        CellValueText: Text;
    begin
        WrkShtReader := WrkbkReader.GetWorksheetById(Format(WrkSheetId));
        if InitColumnMapping(WrkShtReader, TempXMLBuffer) then begin
            Enumerator := WrkShtReader.GetEnumerator();
            if GetDataTable(DataColumnTableId) then begin
                DataColumn := DataTable.Columns.Item(1);
                DataColumn.DataType := Type.GetType('System.String');
                DataTable.BeginLoadData();
                DataRow := DataTable.NewRow();
                SheetHeaderRead := false;
                DataColumn := DataTable.Columns.Item(1);
                RowIn := 1;
                ColumnCount := 0;
                TotalColumnCount := 0;
                CurrentRowIndex := 1;
                FirstDataRow := 4;
                while Enumerator.MoveNext() do begin
                    CellData := Enumerator.Current;
                    CellValueText := CellData.Value();
                    RowChanged := CurrentRowIndex <> CellData.RowNumber;
                    if not SheetHeaderRead then begin // Read config and table information
                        if (CellData.RowNumber = 1) and (CellData.ColumnNumber = 1) then begin
                            DataRow.Item(1, CellValueText);
                            OnReadWorksheetDataOnAfterPackageCodeRead(CellValueText, FirstDataRow);
                        end;
                        if (CellData.RowNumber = 1) and (CellData.ColumnNumber = 3) then begin
                            DataColumn := DataTable.Columns.Item(0);
                            DataRow.Item(0, CellValueText);
                            DataTable.Rows.Add(DataRow);
                            DataColumn := DataTable.Columns.Item(2);
                            DataColumn.AllowDBNull(true);
                            DataTable := DataSet.Tables.Item(DataColumnTableId + 1);
                            ColumnCount := 0;
                            TotalColumnCount := DataTable.Columns.Count - 1;
                            repeat
                                DataColumn := DataTable.Columns.Item(ColumnCount);
                                DataColumn.DataType := Type.GetType('System.String');
                                ColumnCount += 1;
                            until ColumnCount = TotalColumnCount;
                            ColumnCount := 0;
                            DataRow2 := DataTable.NewRow();
                            DataRow2.SetParentRow(DataRow);
                            SheetHeaderRead := true;
                        end;
                    end else begin // Read data rows
                        if (RowIn = 1) and (CellData.RowNumber >= FirstDataRow) and (CellData.ColumnNumber = 1) then begin
                            TotalColumnCount := ColumnCount;
                            ColumnCount := 0;
                            RowIn += 1;
                            FirstDataRow := CellData.RowNumber;
                        end;

                        if RowChanged and (CellData.RowNumber > FirstDataRow) and (RowIn <> 1) then begin
                            DataTable.Rows.Add(DataRow2);
                            DataTable.EndLoadData();
                            DataRow2 := DataTable.NewRow();
                            DataRow2.SetParentRow(DataRow);
                            RowIn += 1;
                            ColumnCount := 0;
                        end;

                        if RowIn <> 1 then
                            ColumnInt := CellData.ColumnNumber;
                        if TempXMLBuffer.Get(ColumnInt) then begin
                            DataColumn := DataTable.Columns.Item(TempXMLBuffer."Parent Entry No.");
                            DataColumn.AllowDBNull(true);
                            DataRow2.Item(TempXMLBuffer."Parent Entry No.", CellValueText);
                        end;

                        ColumnCount := CellData.ColumnNumber + 1;
                    end;
                    CurrentRowIndex := CellData.RowNumber;
                end;
                // Add the last row
                DataTable.Rows.Add(DataRow2);
                DataTable.EndLoadData();
            end else
                Message(InvalidDataInSheetMsg, WrkShtReader.Name);
        end;
    end;

    procedure ClearOpenXmlVariables()
    begin
        Clear(WrkbkReader);
        Clear(WrkbkWriter);
        Clear(WrkShtWriter);
        Clear(Workbook);
        Clear(WorkBookPart);
        Clear(WrkShtHelper);
    end;

    procedure CreateBook(var TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        WrkbkWriter := WrkbkWriter.Create(InStream);
        if IsNull(WrkbkWriter) then
            Error(CreateWrkBkFailedErr);

        Workbook := WrkbkWriter.Workbook;
        WorkBookPart := Workbook.WorkbookPart;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure CreateSchemaFile(var ConfigPackageTable: Record "Config. Package Table"; var RootElementName: Text): Text
    var
        ConfigDataSchema: XMLport "Config. Data Schema";
        OStream: OutStream;
        TempSchemaFile: File;
        TempSchemaFileName: Text;
    begin
        TempSchemaFile.CreateTempFile();
        TempSchemaFileName := TempSchemaFile.Name + '.xsd';
        TempSchemaFile.Close();
        TempSchemaFile.Create(TempSchemaFileName);
        TempSchemaFile.CreateOutStream(OStream);
        RootElementName := ConfigDataSchema.GetRootElementName();
        ConfigDataSchema.SetDestination(OStream);
        ConfigDataSchema.SetTableView(ConfigPackageTable);
        if not ConfigDataSchema.Export() then
            Error(CannotCreateXmlSchemaErr);
        TempSchemaFile.Close();
        exit(TempSchemaFileName);
    end;

    local procedure CreateXMLPackage(TempSetupDataFileName: Text; var ConfigPackageTable: Record "Config. Package Table"): Text
    begin
        Clear(ConfigXMLExchange);
        ConfigXMLExchange.SetExcelMode(true);
        ConfigXMLExchange.SetCalledFromCode(true);
        ConfigXMLExchange.SetPrefixMode(true);
        ConfigXMLExchange.ExportPackageXML(ConfigPackageTable, TempSetupDataFileName);
        ConfigXMLExchange.SetExcelMode(false);
        exit(TempSetupDataFileName);
    end;

    local procedure CreateTableColumnNames(var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageTable: Record "Config. Package Table"; TableColumns: DotNet TableColumns)
    var
        "Field": Record "Field";
        Dimension: Record Dimension;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        XmlColumnProperties: DotNet XmlColumnProperties;
        TableColumn: DotNet TableColumn;
        WrkShtWriter2: DotNet WorksheetWriter;
        TableColumnName: Text;
        ColumnID: Integer;
        IsHandled: Boolean;
        ShouldRunIteration: Boolean;
        ShouldSetCellComment: Boolean;
        ColumnNamesRowNo: Integer;
    begin
        ColumnNamesRowNo := 3;
        IsHandled := false;
        OnBeforeCreateTableColumnNames(ConfigPackageField, ConfigPackageTable, TypeHelper, ConfigXMLExchange, OpenXMLManagement, IsHandled, ColumnNamesRowNo);
        if IsHandled then
            exit;

        RecRef.Open(ConfigPackageTable."Table ID");
        ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
        if ConfigPackageField.FindSet() then begin
            ColumnID := 1;
            repeat
                ShouldRunIteration := TypeHelper.GetField(ConfigPackageField."Table ID", ConfigPackageField."Field ID", Field) or ConfigPackageField.Dimension;
                OnCreateTableColumnNamesOnAfterCalcShouldRunIteration(ConfigPackageField, ShouldRunIteration);
                if ShouldRunIteration then begin
                    TableColumnName := GetTableColumnName(ConfigPackageField, Dimension);

                    XmlColumnProperties := WrkShtWriter2.CreateXmlColumnProperties(
                        1,
                        '/DataList/' + (ConfigXMLExchange.GetElementName(ConfigPackageTable."Table Caption") + 'List') +
                        '/' + ConfigXMLExchange.GetElementName(ConfigPackageTable."Table Caption") +
                        '/' + ConfigPackageField.GetElementName(),
                        WrkShtWriter.XmlDataType2XmlDataValues(
                          ConfigXMLExchange.GetXSDType(ConfigPackageTable."Table ID", ConfigPackageField."Field ID")));
                    TableColumn := WrkShtWriter.CreateTableColumn(
                        ColumnID,
                        TableColumnName,
                        ConfigXMLExchange.GetElementName(ConfigPackageField."Field Caption"));
                    WrkShtHelper.AppendElementToOpenXmlElement(TableColumn, XmlColumnProperties);
                    WrkShtHelper.AppendElementToOpenXmlElement(TableColumns, TableColumn);
                    WrkShtWriter.SetCellValueText(
                      ColumnNamesRowNo, OpenXMLManagement.GetXLColumnID(ColumnID), TableColumnName, WrkShtWriter.DefaultCellDecorator);
                    ShouldSetCellComment := not ConfigPackageField.Dimension;
                    OnCreateTableColumnNamesOnAfterCalcShouldSetCellComment(ConfigPackageField, ConfigPackageTable, ShouldSetCellComment);
                    if ShouldSetCellComment then begin
                        FieldRef := RecRef.Field(ConfigPackageField."Field ID");
                        OpenXMLManagement.SetCellComment(
                          WrkShtWriter, OpenXMLManagement.GetXLColumnID(ColumnID) + Format(ColumnNamesRowNo), ConfigValidateMgt.AddComment(FieldRef));
                        StringBld.Append(OpenXMLManagement.CreateCommentVmlShapeXml(ColumnID, ColumnNamesRowNo));
                    end;
                end;
                ColumnID += 1;
            until ConfigPackageField.Next() = 0;
        end;
        RecRef.Close();
    end;

    local procedure GetTableColumnName(ConfigPackageField: Record "Config. Package Field"; Dimension: Record Dimension) TableColumnName: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTableColumnName(ConfigPackageField, Dimension, TableColumnName, IsHandled);
        if IsHandled then
            exit(TableColumnName);

        if ConfigPackageField.Dimension then
            TableColumnName := ConfigPackageField."Field Caption" + ' ' + StrSubstNo('(%1)', Dimension.TableCaption())
        else
            TableColumnName := ConfigPackageField."Field Caption";

        if TableColumnName = '' then
            TableColumnName := ConfigPackageField."Field Name";
    end;

    local procedure AddPackageAndTableInformation(var ConfigPackageTable: Record "Config. Package Table"; var SingleXMLCells: DotNet SingleXmlCells)
    var
        RecRef: RecordRef;
        SingleXMLCell: DotNet SingleXmlCell;
        TableCaptionString: Text;
    begin
        // Add package name
        SingleXMLCell := WrkShtWriter.AddSingleXmlCell(id);
        WrkShtHelper.AppendElementToOpenXmlElement(SingleXMLCells, SingleXMLCell);
        OpenXMLManagement.AddSingleXMLCellProperties(SingleXMLCell, 'A1', '/DataList/' +
          (ConfigXMLExchange.GetElementName(ConfigPackageTable."Table Caption") + 'List') + '/' +
          ConfigXMLExchange.GetElementName(ConfigPackageTable.FieldName("Package Code")), 1, 1);
        WrkShtWriter.SetCellValueText(1, 'A', ConfigPackageTable."Package Code", WrkShtWriter.DefaultCellDecorator);

        // Add Table name
        RecRef.Open(ConfigPackageTable."Table ID");
        TableCaptionString := RecRef.Caption;
        RecRef.Close();
        WrkShtWriter.SetCellValueText(1, 'B', TableCaptionString, WrkShtWriter.DefaultCellDecorator);

        // Add Table id
        id += 1;
        SingleXMLCell := WrkShtWriter.AddSingleXmlCell(id);
        WrkShtHelper.AppendElementToOpenXmlElement(SingleXMLCells, SingleXMLCell);

        OpenXMLManagement.AddSingleXMLCellProperties(SingleXMLCell, 'C1', '/DataList/' +
          (ConfigXMLExchange.GetElementName(ConfigPackageTable."Table Caption") + 'List') + '/' +
          ConfigXMLExchange.GetElementName(ConfigPackageTable.FieldName("Table ID")), 1, 1);
        WrkShtWriter.SetCellValueText(1, 'C', Format(ConfigPackageTable."Table ID"), WrkShtWriter.DefaultCellDecorator);
    end;

    local procedure BuildDataSetForPackageTable(var ConfigPackageTable: Record "Config. Package Table"): Text
    var
        TempSetupDataFileName: Text;
    begin
        TempSetupDataFileName := CreateXMLPackage(FileMgt.ServerTempFileName(''), ConfigPackageTable);
        DataSet := DataSet.DataSet();
        DataSet.ReadXml(TempSetupDataFileName);
        exit(TempSetupDataFileName);
    end;

    local procedure AddAndInitializeTableDefinitionPart(var ConfigPackageTable: Record "Config. Package Table"; DataTableCounter: Integer; var TableDefinitionPart: DotNet TableDefinitionPart; SkipData: Boolean)
    var
        ConfigPackageField: Record "Config. Package Field";
        TableColumns: DotNet TableColumns;
        "Table": DotNet Table;
        BooleanValue: DotNet BooleanValue;
        StringValue: DotNet StringValue;
        RowsCount: Integer;
        ColumnNameAndRowNo: Code[10];
        RowNo: Integer;
    begin
        TableDefinitionPart := WrkShtWriter.CreateTableDefinitionPart();
        ConfigPackageField.Reset();
        ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageField.SetRange("Include Field", true);

        ColumnNameAndRowNo := 'A3:';
        RowNo := 3;
        OnAddAndInitializeTableDefinitionPartOnBeforeGetDataTable(ConfigPackageTable, DataTableCounter, ColumnNameAndRowNo, RowNo);

        DataTable := DataSet.Tables.Item(DataTableCounter);

        id += 1;
        if SkipData then
            RowsCount := 1
        else
            RowsCount := DataTable.Rows.Count();
        Table := WrkShtWriter.CreateTable(id);
        Table.TotalsRowShown := BooleanValue.BooleanValue(false);
        Table.Reference :=
          StringValue.StringValue(
            ColumnNameAndRowNo + OpenXMLManagement.GetXLColumnID(ConfigPackageField.Count) + Format(RowsCount + RowNo));
        Table.Name := StringValue.StringValue('Table' + Format(id));
        Table.DisplayName := StringValue.StringValue('Table' + Format(id));
        OpenXMLManagement.AppendAutoFilter(Table);
        TableColumns := WrkShtWriter.CreateTableColumns(ConfigPackageField.Count);

        CreateTableColumnNames(ConfigPackageField, ConfigPackageTable, TableColumns);
        WrkShtHelper.AppendElementToOpenXmlElement(Table, TableColumns);
        OpenXMLManagement.AppendTableStyleInfo(Table);
        TableDefinitionPart.Table := Table;
    end;

    [TryFunction]
    local procedure GetDataTable(TableId: Integer)
    begin
        DataTable := DataSet.Tables.Item(TableId);
    end;

    local procedure InitColumnMapping(WrkShtReader: DotNet WorksheetReader; var TempXMLBuffer: Record "XML Buffer" temporary): Boolean
    var
        "Table": DotNet Table;
        TableColumn: DotNet TableColumn;
        Enumerable: DotNet IEnumerable;
        Enumerator: DotNet IEnumerator;
        XmlColumnProperties: DotNet XmlColumnProperties;
        TableStartColumnIndex: Integer;
        Index: Integer;
    begin
        TempXMLBuffer.DeleteAll();
        if not OpenXMLManagement.FindTableDefinition(WrkShtReader, Table) then
            exit(false);

        TableStartColumnIndex := GetTableStartColumnIndex(Table);
        Index := 0;
        Enumerable := Table.TableColumns;
        Enumerator := Enumerable.GetEnumerator();
        while Enumerator.MoveNext() do begin
            TableColumn := Enumerator.Current;
            XmlColumnProperties := TableColumn.XmlColumnProperties();
            if not IsNull(XmlColumnProperties) then
                // identifies column to xsd mapping.
                if not IsNull(XmlColumnProperties.XPath) then
                    InsertXMLBuffer(Index + TableStartColumnIndex, TempXMLBuffer);
            Index += 1;
        end;

        // RowCount > 2 means sheet has datarow(s)
        exit(WrkShtReader.RowCount > 2);
    end;

    local procedure GetTableStartColumnIndex("Table": DotNet Table): Integer
    var
        String: DotNet String;
        Index: Integer;
        Length: Integer;
        ColumnIndex: Integer;
    begin
        // <x:table id="5" ... ref="A3:E6" ...>
        // table.Reference = "A3:E6" (A3 - top left table corner, E6 - bottom right corner)
        // we convert "A" - to column index
        String := Table.Reference.Value();
        Length := String.IndexOf(':');
        String := DelChr(String.Substring(0, Length), '=', '0123456789');
        Length := String.Length - 1;
        for Index := 0 to Length do
            ColumnIndex += (String.Chars(Index) - 64) + Index * 26;
        exit(ColumnIndex);
    end;

    local procedure InsertXMLBuffer(ColumnIndex: Integer; var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        TempXMLBuffer.Init();
        TempXMLBuffer."Entry No." := ColumnIndex; // column index in table definition
        TempXMLBuffer."Parent Entry No." := TempXMLBuffer.Count(); // column index in dataset
        TempXMLBuffer.Insert();
    end;

    procedure SetFileOnServer(NewFileOnServer: Boolean)
    begin
        FileOnServer := NewFileOnServer;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportExcel(var ConfigPackageTable: Record "Config. Package Table")
    begin
    end;

    local procedure GetExcelWorksheetName(Caption: Text; TableID: Text): Text
    var
        WorksheetNameMaxLen: Integer;
    begin
        // maximum Worksheet Name length in Excel
        WorksheetNameMaxLen := 31;
        Caption := CopyStr(TableID + ' ' + Caption, 1, WorksheetNameMaxLen);
        exit(Caption);
    end;

    local procedure IsFileImportedToBLOB(var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        IsHandled: Boolean;
    begin
        OnImportExcelFile(TempBlob, IsHandled);
        if IsHandled then
            exit(true);
        exit(FileMgt.BLOBImportWithFilter(TempBlob, ImportFromExcelMsg, '', FileExtensionFilterTok, ExcelFileExtensionTok) <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBLOBExport(var TempBlob: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTableColumnNames(var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageTable: Record "Config. Package Table"; var TypeHelper: Codeunit "Type Helper"; var ConfigXMLExchange: Codeunit "Config. XML Exchange"; var OpenXMLManagement: Codeunit "OpenXML Management"; var IsHandled: Boolean; var ColumnNamesRowNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportExcelTemplateFromTables(var ConfigPackageTable: Record "Config. Package Table"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTableColumnName(ConfigPackageField: Record "Config. Package Field"; Dimension: Record Dimension; var TableColumnName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTableColumnNamesOnAfterCalcShouldRunIteration(var ConfigPackageField: Record "Config. Package Field"; var ShouldRunIteration: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTableColumnNamesOnAfterCalcShouldSetCellComment(var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageTable: Record "Config. Package Table"; var ShouldSetCellComment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportExcelFromConfigOnBeforeExportExcel(var ConfigLine: Record "Config. Line"; var ConfigPackageTable: Record "Config. Package Table")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportExcelFile(var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsImportFromExcelConfirmedOnAfterReadFromExcel(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddAndInitializeTableDefinitionPartOnBeforeGetDataTable(var ConfigPackageTable: Record "Config. Package Table"; var DataTableCounter: Integer; var ColumnNameAndRowNo: Code[10]; var RowNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportExcelOnBeforeWrkShtWriterCreateTableParts(var ConfigPackageTable: Record "Config. Package Table"; var DataTableCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadWorksheetDataOnAfterPackageCodeRead(CellValueText: Text; var FirstDataRow: Integer)
    begin
    end;
}

