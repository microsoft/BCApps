namespace System.IO;

using Microsoft.Finance.Dimension;
using Microsoft.Utilities;
using System;
using System.Reflection;
using System.Telemetry;
using System.Text;
using System.Threading;
using System.Utilities;
using System.Xml;

codeunit 8614 "Config. XML Exchange"
{

    trigger OnRun()
    begin
    end;

    var
        FileManagement: Codeunit "File Management";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigMgt: Codeunit "Config. Management";
        ConfigPckgCompressionMgt: Codeunit "Config. Pckg. Compression Mgt.";
        TypeHelper: Codeunit "Type Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ErrorTypeEnum: Option General,TableRelation;
        ImportedPackageCode: Code[20];
        Advanced: Boolean;
        CalledFromCode: Boolean;
        PackageAllreadyContainsDataQst: Label 'Package %1 already contains data that will be overwritten by the import. Do you want to continue?', Comment = '%1 - Package name';
        TableContainsRecordsQst: Label 'Table %1 in the package %2 contains %3 records that will be overwritten by the import. Do you want to continue?', Comment = '%1=The ID of the table being imported. %2=The Config Package Code. %3=The number of records in the config package.';
        MissingInExcelFileErr: Label '%1 is missing in the Excel file.', Comment = '%1=The Package Code field caption.';
        ExportPackageTxt: Label 'Exporting package';
        ImportPackageTxt: Label 'Importing package';
        RapidStartTxt: Label 'RapidStart', Locked = true;
        PackageFileNameTxt: Label 'Package%1.rapidstart', Locked = true;
        DownloadTxt: Label 'Download';
        ImportFileTxt: Label 'Import File';
        FileDialogFilterTxt: Label 'RapidStart file (*.rapidstart)|*.rapidstart|All Files (*.*)|*.*', Comment = 'Only translate ''RapidStart Files'' {Split=r"[\|\(]\*\.[^ |)]*[|) ]?"}';
        ExcelMode: Boolean;
        HideDialog: Boolean;
        DataListTxt: Label 'DataList', Locked = true;
#pragma warning disable AA0470
        TableDoesNotExistErr: Label 'An error occurred while importing the %1 table. The table does not exist in the database.';
#pragma warning restore AA0470
        WrongFileTypeErr: Label 'The specified file could not be imported because it is not a valid RapidStart package file.';
        RecordProgressTxt: Label 'Import %1 records', Comment = '%1=The name of the table being imported.';
        AddPrefixMode: Boolean;
        WorkingFolder: Text;
        PackageCodesMustMatchErr: Label 'The package code specified on the configuration package must be the same as the package name in the imported package.';
        ProgressStatusTxt: Label '%1: %2 records out of %3', Comment = '%1 = table name; %2 = number of processed records (integer); %3 = total number records (integer).';
        ImportedTableContentTxt: Label 'Table: %1, records: %2, total table fields: %3, imported fields: %4.', Locked = true;
        ExportedTableContentTxt: Label 'Table: %1, records: %2, exported fields: %3.', Locked = true;
        PackageImportStartScopeAllMsg: Label 'Configuration package import started: %1', Comment = '%1 - package code', Locked = true;
        PackageImportFinishScopeAllMsg: Label 'Configuration package imported successfully: %1', Comment = '%1 - package code', Locked = true;
        PackageExportStartScopeAllMsg: Label 'Configuration package export started: %1', Comment = '%1 - package code', Locked = true;
        PackageExportFinishScopeAllMsg: Label 'Configuration package exported successfully: %1', Comment = '%1 - package code', Locked = true;
        ImportingIsNotAllowedDuringUpgradeOrInstallationErr: Label 'Importing configuration packages is not allowed during upgrade or installation. Importing configuration packages requires multiple threads and sessions which is not supported.';

    local procedure AddXMLComment(var PackageXML: DotNet XmlDocument; var Node: DotNet XmlNode; Comment: Text[250])
    var
        CommentNode: DotNet XmlNode;
    begin
        CommentNode := PackageXML.CreateComment(Comment);
        Node.AppendChild(CommentNode);
    end;

    local procedure AddTableAttributes(ConfigPackageTable: Record "Config. Package Table"; var PackageXML: DotNet XmlDocument; var TableNode: DotNet XmlNode)
    var
        FieldNode: DotNet XmlNode;
    begin
        if ConfigPackageTable."Page ID" > 0 then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Page ID")));
            FieldNode.InnerText := Format(ConfigPackageTable."Page ID");
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Package Processing Order" > 0 then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Package Processing Order")));
            FieldNode.InnerText := Format(ConfigPackageTable."Package Processing Order");
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Processing Order" > 0 then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Processing Order")));
            FieldNode.InnerText := Format(ConfigPackageTable."Processing Order");
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Data Template" <> '' then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Data Template")));
            FieldNode.InnerText := Format(ConfigPackageTable."Data Template");
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable.Comments <> '' then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName(Comments)));
            FieldNode.InnerText := Format(ConfigPackageTable.Comments);
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Created by User ID" <> '' then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Created by User ID")));
            FieldNode.InnerText := Format(ConfigPackageTable."Created by User ID");
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Skip Table Triggers" then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Skip Table Triggers")));
            FieldNode.InnerText := '1';
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Parent Table ID" > 0 then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Parent Table ID")));
            FieldNode.InnerText := Format(ConfigPackageTable."Parent Table ID");
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Delete Recs Before Processing" then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Delete Recs Before Processing")));
            FieldNode.InnerText := '1';
            TableNode.AppendChild(FieldNode);
        end;
        if ConfigPackageTable."Dimensions as Columns" then begin
            FieldNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Dimensions as Columns")));
            FieldNode.InnerText := '1';
            TableNode.AppendChild(FieldNode);
        end;

        OnAfterAddTableAttributes(ConfigPackageTable, PackageXML, TableNode);
    end;

    local procedure AddFieldAttributes(ConfigPackageField: Record "Config. Package Field"; var FieldNode: DotNet XmlNode)
    begin
        if ConfigPackageField."Primary Key" then
            XMLDOMMgt.AddAttribute(FieldNode, GetElementName(ConfigPackageField.FieldName("Primary Key")), '1');
        if ConfigPackageField."Validate Field" then
            XMLDOMMgt.AddAttribute(FieldNode, GetElementName(ConfigPackageField.FieldName("Validate Field")), '1');
        if ConfigPackageField."Create Missing Codes" then
            XMLDOMMgt.AddAttribute(FieldNode, GetElementName(ConfigPackageField.FieldName("Create Missing Codes")), '1');
        if ConfigPackageField."Processing Order" <> 0 then
            XMLDOMMgt.AddAttribute(
              FieldNode, GetElementName(ConfigPackageField.FieldName("Processing Order")), Format(ConfigPackageField."Processing Order"));

        OnAfterAddFieldAttributes(ConfigPackageField, FieldNode);
    end;

    local procedure AddDimensionFields(var ConfigPackageField: Record "Config. Package Field"; var RecRef: RecordRef; var PackageXML: DotNet XmlDocument; var RecordNode: DotNet XmlNode; var FieldNode: DotNet XmlNode; ExportValue: Boolean)
    var
        DimCode: Code[20];
    begin
        ConfigPackageField.SetRange(Dimension, true);
        if ConfigPackageField.FindSet() then
            repeat
                FieldNode :=
                  PackageXML.CreateElement(
                    GetElementName(CopyStr(ConfigValidateMgt.CheckName(ConfigPackageField."Field Name"), 1, 250)));
                if ExportValue then begin
                    DimCode := CopyStr(ConfigPackageField."Field Name", 1, 20);
                    FieldNode.InnerText := GetDimValueFromTable(RecRef, DimCode);
                    RecordNode.AppendChild(FieldNode);
                end else begin
                    FieldNode.InnerText := '';
                    RecordNode.AppendChild(FieldNode);
                end;
            until ConfigPackageField.Next() = 0;
    end;

    local procedure AddDimPackageFields(var ConfigPackageTable: Record "Config. Package Table"; RecordNode: DotNet XmlNode)
    var
        ConfigPackageField: Record "Config. Package Field";
        TempConfigPackageField: Record "Config. Package Field" temporary;
        Dimension: Record Dimension;
        i: Integer;
        DimsAsColumns: Boolean;
    begin
        if not (ConfigMgt.IsDimSetIDTable(ConfigPackageTable."Table ID") or ConfigMgt.IsDefaultDimTable(ConfigPackageTable."Table ID")) then
            exit;
        i := 1;
        if Dimension.FindSet() then
            repeat
                ConfigPackageMgt.InsertPackageField(
                  TempConfigPackageField, ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", ConfigMgt.DimensionFieldID() + i,
                  Dimension.Code, Dimension."Code Caption", true, false, false, true);
                if FieldNodeExists(RecordNode, GetElementName(TempConfigPackageField."Field Name")) then begin
                    ConfigPackageField := TempConfigPackageField;
                    ConfigPackageField.Insert();
                    DimsAsColumns := true;
                    i := i + 1;
                end;
            until Dimension.Next() = 0;

        if DimsAsColumns then begin
            ConfigPackageTable."Dimensions as Columns" := true;
            ConfigPackageTable.Modify();
        end;
    end;

    procedure ApplyPackageFilter(ConfigPackageTable: Record "Config. Package Table"; var RecRef: RecordRef)
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        FieldRef: FieldRef;
    begin
        OnBeforeApplyPackageFilter(ConfigPackageTable, RecRef);

        if ConfigPackageTable."Cross-Column Filter" then
            RecRef.FilterGroup(-1);

        ConfigPackageFilter.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageFilter.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", 0);
        if ConfigPackageFilter.FindSet() then
            repeat
                if ConfigPackageFilter."Field Filter" <> '' then begin
                    FieldRef := RecRef.Field(ConfigPackageFilter."Field ID");
                    FieldRef.SetFilter(StrSubstNo('%1', ConfigPackageFilter."Field Filter"));
                end;
            until ConfigPackageFilter.Next() = 0;

        if ConfigPackageTable."Cross-Column Filter" then
            RecRef.FilterGroup(0);
    end;

    local procedure CreateRecordNodes(var PackageXML: DotNet XmlDocument; ConfigPackageTable: Record "Config. Package Table")
    var
        "Field": Record "Field";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackage: Record "Config. Package";
        ConfigProgressBarRecord: Codeunit "Config. Progress Bar";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        DocumentElement: DotNet XmlNode;
        FieldNode: DotNet XmlNode;
        RecordNode: DotNet XmlNode;
        TableNode: DotNet XmlNode;
        TableIDNode: DotNet XmlNode;
        PackageCodeNode: DotNet XmlNode;
        RecordCount: Integer;
        ProcessedRecordCount: Integer;
        StepCount: Integer;
        ExportMetadata: Boolean;
        ShowDialog: Boolean;
        IsHandled: Boolean;
        FieldNameLookup: Dictionary of [Integer, Text];
        FieldElementName: Text;
    begin
        IsHandled := false;
        OnBeforeCreateRecordNodes(ConfigPackageTable, ConfigPackageField, TypeHelper, XMLDOMMgt, WorkingFolder, ExcelMode, Advanced, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if ConfigMgt.IsSystemTable(ConfigPackageTable."Table ID") then
            exit;

        ConfigPackageTable.TestField("Package Code");
        ConfigPackageTable.TestField("Table ID");
        ConfigPackage.Get(ConfigPackageTable."Package Code");
        ExcludeRemovedFields(ConfigPackageTable);
        DocumentElement := PackageXML.DocumentElement;
        TableNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable."Table Name" + 'List'));
        DocumentElement.AppendChild(TableNode);

        TableIDNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Table ID")));
        TableIDNode.InnerText := Format(ConfigPackageTable."Table ID");
        TableNode.AppendChild(TableIDNode);

        if ExcelMode then begin
            PackageCodeNode := PackageXML.CreateElement(GetElementName(ConfigPackageTable.FieldName("Package Code")));
            PackageCodeNode.InnerText := Format(ConfigPackageTable."Package Code");
            TableNode.AppendChild(PackageCodeNode);
        end else
            AddTableAttributes(ConfigPackageTable, PackageXML, TableNode);

        ExportMetadata := true;
        RecRef.Open(ConfigPackageTable."Table ID");
        IsHandled := false;
        OnCreateRecordNodesOnBeforeApplyPackageFilter(ConfigPackageTable, RecRef, IsHandled);
        if not IsHandled then
            ApplyPackageFilter(ConfigPackageTable, RecRef);
        OnCreateRecordNodesOnAfterApplyPackageFilter(ConfigPackageTable, ConfigPackage, RecRef);
        if RecRef.FindSet() then begin
            RecordCount := RecRef.Count();
            ShowDialog := (not HideDialog) and (RecordCount > 1000);
            if ShowDialog then begin
                StepCount := Round(RecordCount / 100, 1);
                ConfigProgressBarRecord.Init(RecordCount, StepCount, ExportPackageTxt);
            end;
            repeat
                IsHandled := false;
                OnCreateRecordNodesOnBeforeRecRefLoopIteration(ConfigPackageTable, ConfigPackage, RecRef, ConfigProgressBar, IsHandled);
                if not IsHandled then begin
                    RecordNode := PackageXML.CreateElement(GetTableElementName(ConfigPackageTable."Table Name"));
                    TableNode.AppendChild(RecordNode);

                    ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
                    ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
                    ConfigPackageField.SetRange("Include Field", true);
                    ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
                    OnCreateRecordNodesOnAfterConfigPackageFieldSetFilters(ConfigPackageTable, ConfigPackageField);
                    if ConfigPackageField.FindSet() then
                        repeat
                            if ConfigPackageField.Dimension then begin
                                if ConfigPackageTable."Dimensions as Columns" and ExcelMode then
                                    AddDimensionFieldsWhenProcessingOrder(ConfigPackageField, RecRef, PackageXML, RecordNode, FieldNode, true);
                            end else begin
                                FieldRef := RecRef.Field(ConfigPackageField."Field ID");

                                // Reuse validated field name. Validating and creating field names is expensive when done many times.
                                if not (FieldNameLookup.Get(FieldRef.Number, FieldElementName)) then
                                    if TypeHelper.GetField(RecRef.Number, FieldRef.Number, Field) then begin
                                        FieldElementName := GetFieldElementName(ConfigPackageField.GetValidatedElementName());
                                        FieldNameLookup.Add(FieldRef.Number, FieldElementName);
                                    end;

                                if (FieldElementName <> '') then begin
                                    FieldNode := PackageXML.CreateElement(FieldElementName);
                                    FieldNode.InnerText := FormatFieldValue(FieldRef, ConfigPackage);
                                    if Advanced and ConfigPackageField."Localize Field" then
                                        AddXMLComment(PackageXML, FieldNode, '_locComment_text="{MaxLength=' + Format(Field.Len) + '}"');
                                    RecordNode.AppendChild(FieldNode); // must be after AddXMLComment and before AddAttribute.
                                    if not ExcelMode and ExportMetadata then
                                        AddFieldAttributes(ConfigPackageField, FieldNode);
                                    if Advanced then
                                        if ConfigPackageField."Localize Field" then
                                            XMLDOMMgt.AddAttribute(FieldNode, '_loc', 'locData')
                                        else
                                            XMLDOMMgt.AddAttribute(FieldNode, '_loc', 'locNone');
                                end;
                            end;
                        until ConfigPackageField.Next() = 0;

                    OnCreateRecordNodesOnAfterRecordProcessed(ConfigPackageTable, ConfigPackageField, RecRef, PackageXML, RecordNode, FieldNode, ExcelMode);
                    ExportMetadata := false;
                    ProcessedRecordCount += 1;

                    if ShowDialog then
                        ConfigProgressBarRecord.Update(StrSubstNo(ProgressStatusTxt, ConfigPackageTable."Table Name", ProcessedRecordCount, RecordCount));
                end;
            until RecRef.Next() = 0;
            // Tag used for analytics
            Session.LogMessage('0000BV0', StrSubstNo(ExportedTableContentTxt, RecRef.Name, RecordCount, ConfigPackageField.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
            if ShowDialog then
                ConfigProgressBarRecord.Close();
        end else begin
            RecordNode := PackageXML.CreateElement(GetTableElementName(ConfigPackageTable."Table Name"));
            TableNode.AppendChild(RecordNode);

            ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
            ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
            ConfigPackageField.SetRange("Include Field", true);
            ConfigPackageField.SetRange(Dimension, false);
            OnCreateRecordNodesOnNotFoundOnAfterConfigPackageFieldSetFilters(ConfigPackageTable, ConfigPackageField);
            if ConfigPackageField.FindSet() then
                repeat
                    FieldRef := RecRef.Field(ConfigPackageField."Field ID");
                    FieldNode :=
                      PackageXML.CreateElement(GetFieldElementName(ConfigPackageField.GetValidatedElementName()));
                    FieldNode.InnerText := '';
                    RecordNode.AppendChild(FieldNode);
                    if not ExcelMode then
                        AddFieldAttributes(ConfigPackageField, FieldNode);
                until ConfigPackageField.Next() = 0;

            if ConfigPackageTable."Dimensions as Columns" and ExcelMode then
                AddDimensionFields(ConfigPackageField, RecRef, PackageXML, RecordNode, FieldNode, false);
            OnCreateRecordNodesOnAfterNotFoundRecordProcessed(ConfigPackageTable, ConfigPackageField, RecRef, PackageXML, RecordNode, FieldNode, ExcelMode);
        end;
    end;

    /// <summary>
    /// Export the provided configuration package to an OutStream.
    /// </summary>
    /// <param name="ConfigPackage">Configuration package to export.</param>
    /// <param name="PackageOutStream">OutStream object that the content of the package will be written to.</param>
    procedure ExportPackageXMLToStream(ConfigPackage: Record "Config. Package"; PackageOutStream: OutStream)
    var
        ConfigPackageTable: Record "Config. Package Table";
        XMLDataFile: File;
        XMLDataFileName: Text;
        XMLDataFileInStream: InStream;
        OriginalCalledFromCode: Boolean;
    begin
        ConfigPackage.TestField(ConfigPackage.Code);
        ConfigPackage.TestField(ConfigPackage."Package Name");
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);

        XMLDataFileName := FileManagement.ServerTempFileName('');

        OriginalCalledFromCode := CalledFromCode;
        SetCalledFromCode(true);
        ExportPackageXML(ConfigPackageTable, XMLDataFileName);
        CalledFromCode := OriginalCalledFromCode;

        XMLDataFile.Open(XMLDataFileName);
        XMLDataFile.CreateInStream(XMLDataFileInStream);
        CopyStream(PackageOutStream, XMLDataFileInStream);
        XMLDataFile.Close();
    end;

    [Scope('OnPrem')]
    procedure ExportPackage(ConfigPackage: Record "Config. Package")
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackage.TestField(Code);
        ConfigPackage.TestField("Package Name");
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ExportPackageXML(ConfigPackageTable, '');
    end;

    [Scope('OnPrem')]
    procedure ExportPackageXML(var ConfigPackageTable: Record "Config. Package Table"; XMLDataFile: Text): Boolean
    var
        ConfigPackage: Record "Config. Package";
        PackageXML: DotNet XmlDocument;
        FileFilter: Text;
        ToFile: Text[50];
        CompressedFileName: Text;
        PackageExportStartMsg: Label 'Export of RS package started.', Locked = true;
        PackageExportFinishMsg: Label 'Export of RS package finished. Duration: %1 milliseconds.', Locked = true;
        DurationAsInt: BigInteger;
        StartTime: DateTime;
        ExecutionId: Guid;
        Dimensions: Dictionary of [Text, Text];
    begin
        StartTime := CurrentDateTime();
        Session.LogMessage('00009Q4', PackageExportStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

        ConfigPackageTable.FindFirst();
        ConfigPackage.Get(ConfigPackageTable."Package Code");
        ConfigPackage.TestField(Code);
        ConfigPackage.TestField("Package Name");

        ExecutionId := CreateGuid();
        Dimensions.Add('Category', RapidStartTxt);
        Dimensions.Add('PackageCode', ConfigPackage.SystemId);
        Dimensions.Add('ExecutionId', Format(ExecutionId, 0, 4));
        Session.LogMessage('0000E3F', StrSubstNo(PackageExportStartScopeAllMsg, ConfigPackage.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        if not ConfigPackage."Exclude Config. Tables" and not ExcelMode then
            ConfigPackageMgt.AddConfigTables(ConfigPackage.Code);

        if not CalledFromCode then
            XMLDataFile := FileManagement.ServerTempFileName('');
        FileFilter := GetFileDialogFilter();
        if ToFile = '' then
            ToFile := StrSubstNo(PackageFileNameTxt, ConfigPackage.Code);
        OnExportPackageXMLOnAfterAssignToFile(ConfigPackage, ToFile);

        SetWorkingFolder(FileManagement.GetDirectoryName(XMLDataFile));
        PackageXML := PackageXML.XmlDocument();
        ExportPackageXMLDocument(PackageXML, ConfigPackageTable, ConfigPackage, Advanced);

        PackageXML.Save(XMLDataFile);

        DurationAsInt := CurrentDateTime() - StartTime;
        Dimensions.Add('ExecutionTimeInMs', Format(DurationAsInt));
        Session.LogMessage('0000E3G', StrSubstNo(PackageExportFinishScopeAllMsg, ConfigPackage.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        // Tag used for analytics
        Session.LogMessage('00009Q5', StrSubstNo(PackageExportFinishMsg, DurationAsInt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

        if not CalledFromCode then begin
            CompressedFileName := FileManagement.ServerTempFileName('');
            OnOnExportPackageXMLOnAfterAssignToFileOnAfterSetCompressedFileName(CompressedFileName, XMLDataFile);
            ConfigPckgCompressionMgt.ServersideCompress(XMLDataFile, CompressedFileName);

            FileManagement.DownloadHandler(CompressedFileName, DownloadTxt, '', FileFilter, ToFile);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ExportPackageXMLDocument(var PackageXML: DotNet XmlDocument; var ConfigPackageTable: Record "Config. Package Table"; ConfigPackage: Record "Config. Package"; Advanced: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DocumentElement: DotNet XmlElement;
        LocXML: Text[1024];
    begin
        FeatureTelemetry.LogUptake('0000E3X', 'Configuration packages', Enum::"Feature Uptake Status"::"Used");
        ConfigPackage.TestField(Code);
        ConfigPackage.TestField("Package Name");

        if Advanced then
            LocXML := '<_locDefinition><_locDefault _loc="locNone"/></_locDefinition>';
        XMLDOMMgt.LoadXMLDocumentFromText(
          StrSubstNo(
            '<?xml version="1.0" encoding="UTF-16" standalone="yes"?><%1>%2</%1>',
            GetPackageTag(),
            LocXML),
          PackageXML);

        CleanUpConfigPackageData(ConfigPackage);

        if not ExcelMode then begin
            InitializeMediaTempFolder();
            DocumentElement := PackageXML.DocumentElement();
            XMLDOMMgt.AddAttribute(
              DocumentElement, GetElementName(ConfigPackage.FieldName("Min. Count For Async Import")),
              Format(ConfigPackage."Min. Count For Async Import"));
            if ConfigPackage."Exclude Config. Tables" then
                XMLDOMMgt.AddAttribute(DocumentElement, GetElementName(ConfigPackage.FieldName("Exclude Config. Tables")), '1');
            if ConfigPackage."Processing Order" > 0 then
                XMLDOMMgt.AddAttribute(
                  DocumentElement, GetElementName(ConfigPackage.FieldName("Processing Order")), Format(ConfigPackage."Processing Order"));
            if ConfigPackage."Language ID" > 0 then
                XMLDOMMgt.AddAttribute(
                  DocumentElement, GetElementName(ConfigPackage.FieldName("Language ID")), Format(ConfigPackage."Language ID"));
            XMLDOMMgt.AddAttribute(
              DocumentElement, GetElementName(ConfigPackage.FieldName("Product Version")), ConfigPackage."Product Version");
            XMLDOMMgt.AddAttribute(DocumentElement, GetElementName(ConfigPackage.FieldName("Package Name")), ConfigPackage."Package Name");
            XMLDOMMgt.AddAttribute(DocumentElement, GetElementName(ConfigPackage.FieldName(Code)), ConfigPackage.Code);
            OnExportPackageXMLDocumentOnAfterSetAttributes(ConfigPackage, XMLDOMMgt, DocumentElement);
        end;

        OnExportPackageXMLDocumentOnBeforeConfigProgressBarInit(ConfigPackageTable, ConfigPackage, XMLDOMMgt, Advanced, HideDialog);

        if not HideDialog then
            ConfigProgressBar.Init(ConfigPackageTable.Count, 1, ExportPackageTxt);
        ConfigPackageTable.SetAutoCalcFields("Table Name");
        if ConfigPackageTable.FindSet() then
            repeat
                if not HideDialog then
                    ConfigProgressBar.Update(ConfigPackageTable."Table Name");

                ExportConfigTableToXML(ConfigPackageTable, PackageXML);
            until ConfigPackageTable.Next() = 0;

        if not ExcelMode then begin
            UpdateConfigPackageMediaSet(ConfigPackage);
            ExportConfigPackageMediaSetToXML(PackageXML, ConfigPackage);
        end;

        if not HideDialog then
            ConfigProgressBar.Close();

        OnAfterExportPackageXMLDocument(ConfigPackage, HideDialog);
    end;

    local procedure ExportConfigTableToXML(var ConfigPackageTable: Record "Config. Package Table"; var PackageXML: DotNet XmlDocument)
    begin
        CreateRecordNodes(PackageXML, ConfigPackageTable);
        ConfigPackageTable."Exported Date and Time" := CreateDateTime(Today, Time);
        ConfigPackageTable.Modify();
    end;

    procedure GetImportedPackageCode(): Code[20]
    begin
        exit(ImportedPackageCode);
    end;

    [Scope('OnPrem')]
    procedure ImportPackageXMLFromClient(): Boolean
    var
        FileMgmt: Codeunit "File Management";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        ServerFileName: Text;
        DecompressedFileName: Text;
        DummyModifyDate: Date;
        DummyModifyTime: Time;
        FileSize: BigInteger;
    begin
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        if not UploadXMLPackage(ServerFileName) then
            exit(false);

        if FileMgmt.GetServerFileProperties(ServerFileName, DummyModifyDate, DummyModifyTime, FileSize) then;
        if GuiAllowed() then
            if ConfigPackageManagement.ShowWarningOnImportingBigConfPackageFromRapidStart(FileSize) = Action::Cancel then
                exit(false);
        DecompressedFileName := DecompressPackage(ServerFileName);

        exit(ImportPackageXML(DecompressedFileName));
    end;

    procedure ImportPackageXML(XMLDataFile: Text): Boolean
    var
        PackageXML: DotNet XmlDocument;
    begin
        XMLDOMMgt.LoadXMLDocumentFromFile(XMLDataFile, PackageXML);

        exit(ImportPackageXMLDocument(PackageXML, ''));
    end;

    procedure ImportPackageXMLFromStream(InStream: InStream): Boolean
    var
        PackageXML: DotNet XmlDocument;
    begin
        XMLDOMMgt.LoadXMLDocumentFromInStream(InStream, PackageXML);

        exit(ImportPackageXMLDocument(PackageXML, ''));
    end;

    procedure ImportPackageXMLWithCodeFromStream(InStream: InStream; PackageCode: Code[20]): Boolean
    var
        PackageXML: DotNet XmlDocument;
    begin
        XMLDOMMgt.LoadXMLDocumentFromInStream(InStream, PackageXML);
        if PackageCode <> '' then
            if PackageCode <> GetPackageCode(PackageXML) then
                Error(PackageCodesMustMatchErr);

        exit(ImportPackageXMLDocument(PackageXML, PackageCode));
    end;

    [Scope('OnPrem')]
    procedure ImportPackageXMLDocument(PackageXML: DotNet XmlDocument; PackageCode: Code[20]) Result: Boolean
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageData: Record "Config. Package Data";
        TempBlob: Codeunit "Temp Blob";
        ParallelSessionManagement: Codeunit "Parallel Session Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DurationAsInt: BigInteger;
        DocumentElement: DotNet XmlElement;
        TableNodes: DotNet XmlNodeList;
        TableNode: DotNet XmlNode;
        OutStream: OutStream;
        Value: Text;
        PackageImportStartMsg: Label 'Import of RS package started.', Locked = true;
        PackageImportFinishMsg: Label 'Import of RS package finished. Duration: %1 milliseconds. File size: %2.', Locked = true;
        StartTime: DateTime;
        TableID: Integer;
        NodeCount: Integer;
        Confirmed: Boolean;
        NoOfChildNodes: Integer;
        FileSize: Integer;
        CurrTableName: Text;
        CurrRecordCount: Integer;
        TotalTableFields: Integer;
        ImportedTableFields: Integer;
        ExecutionId: Guid;
        Dimensions: Dictionary of [Text, Text];
        IsHandled: Boolean;
    begin
        VerifyCanImportConfigurationPackage();
        StartTime := CurrentDateTime();
        Session.LogMessage('00009Q6', PackageImportStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
        FeatureTelemetry.LogUptake('0000E3D', 'Configuration packages', Enum::"Feature Uptake Status"::"Set up");

        FileSize := PackageXML.OuterXml.Length() * 2; // due to UTF-16 encoding
        DocumentElement := PackageXML.DocumentElement;

        if not ExcelMode then begin
            if PackageCode = '' then begin
                PackageCode := GetPackageCode(PackageXML);
                if ConfigPackage.Get(PackageCode) then begin
                    ConfigPackage.CalcFields("No. of Records");
                    Confirmed := true;
                    if not HideDialog then
                        if ConfigPackage."No. of Records" > 0 then
                            if not Confirm(PackageAllreadyContainsDataQst, true, PackageCode) then
                                Confirmed := false;
                    if not Confirmed then
                        exit(false);
                    ConfigPackage.Delete(true);
                    Commit();
                end;
                ConfigPackage.Init();
                ConfigPackage.Code := PackageCode;
                ConfigPackage.Insert();
            end else
                ConfigPackage.Get(PackageCode);
            ImportedPackageCode := PackageCode;

            ConfigPackage."Package Name" :=
              CopyStr(
                GetAttribute(GetElementName(ConfigPackage.FieldName("Package Name")), DocumentElement), 1,
                MaxStrLen(ConfigPackage."Package Name"));
            Value := GetAttribute(GetElementName(ConfigPackage.FieldName("Language ID")), DocumentElement);
            if Value <> '' then
                Evaluate(ConfigPackage."Language ID", Value);
            ConfigPackage."Product Version" :=
              CopyStr(
                GetAttribute(GetElementName(ConfigPackage.FieldName("Product Version")), DocumentElement), 1,
                MaxStrLen(ConfigPackage."Product Version"));
            Value := GetAttribute(GetElementName(ConfigPackage.FieldName("Processing Order")), DocumentElement);
            if Value <> '' then
                Evaluate(ConfigPackage."Processing Order", Value);
            Value := GetAttribute(GetElementName(ConfigPackage.FieldName("Exclude Config. Tables")), DocumentElement);
            if Value <> '' then
                Evaluate(ConfigPackage."Exclude Config. Tables", Value);
            Value := GetAttribute(GetElementName(ConfigPackage.FieldName("Min. Count For Async Import")), DocumentElement);
            if Value <> '' then begin
                IsHandled := false;
                OnBeforeEvaluateMinCountForAsyncImport(ConfigPackage, Value, IsHandled);
                if not IsHandled then
                    Evaluate(ConfigPackage."Min. Count For Async Import", Value);
            end;
            OnImportPackageXMLDocumentOnBeforeModify(ConfigPackage, DocumentElement);
            ConfigPackage.Modify();
        end;

        ExecutionId := CreateGuid();
        Dimensions.Add('Category', RapidStartTxt);
        Dimensions.Add('ExecutionId', Format(ExecutionId, 0, 4));
        Session.LogMessage('0000E3H', StrSubstNo(PackageImportStartScopeAllMsg, ConfigPackage.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);

        Commit(); // to enable background processes to reference the ConfigPackage

        TableNodes := DocumentElement.ChildNodes;
        if not HideDialog then
            ConfigProgressBar.Init(TableNodes.Count, 1, ImportPackageTxt);
        for NodeCount := 0 to (TableNodes.Count - 1) do begin
            TableNode := TableNodes.Item(NodeCount);
            if Evaluate(TableID, Format(TableNode.FirstChild.InnerText)) then begin
                if GetTableStatisticsForTelemetry(TableNode, CurrTableName, CurrRecordCount, TotalTableFields, ImportedTableFields) then
                    Session.LogMessage('0000BV1', StrSubstNo(ImportedTableContentTxt, CurrTableName, CurrRecordCount, TotalTableFields, ImportedTableFields), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

                NoOfChildNodes := TableNode.ChildNodes.Count();
                if (NoOfChildNodes < ConfigPackage."Min. Count For Async Import") or ExcelMode then
                    ImportTableFromXMLNode(TableNode, PackageCode)
                else begin
                    // Send to background
                    Clear(TempBlob);
                    TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
                    OutStream.WriteText('<doc>' + TableNode.OuterXml + '</doc>');
                    ParallelSessionManagement.NewSessionRunCodeunitWithBlob(
                      CODEUNIT::"Config. Import Table in Backgr", PackageCode, TempBlob);
                end;
                if ExcelMode then
                    case true of // Dimensions
                        ConfigMgt.IsDefaultDimTable(TableID):
                            begin
                                ConfigPackageRecord.SetRange("Package Code", PackageCode);
                                ConfigPackageRecord.SetRange("Table ID", TableID);
                                OnImportPackageXMLDocumentOnDefaultDimOnAfterConfigPackageRecordSetFilters(ConfigPackageRecord, ConfigPackageData, PackageCode);
                                if ConfigPackageRecord.FindSet() then
                                    repeat
                                        ConfigPackageData.Get(
                                          ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID",
                                          ConfigPackageRecord."No.", GetDefaultDimensionNoLinkFieldNumber(TableID));
                                        ConfigPackageMgt.UpdateDefaultDimValues(ConfigPackageRecord, CopyStr(ConfigPackageData.Value, 1, 20));
                                    until ConfigPackageRecord.Next() = 0;
                            end;
                        ConfigMgt.IsDimSetIDTable(TableID):
                            begin
                                ConfigPackageRecord.SetRange("Package Code", PackageCode);
                                ConfigPackageRecord.SetRange("Table ID", TableID);
                                if ConfigPackageRecord.FindSet() then
                                    repeat
                                        ConfigPackageMgt.HandlePackageDataDimSetIDForRecord(ConfigPackageRecord);
                                    until ConfigPackageRecord.Next() = 0;
                            end;
                    end;
            end;
        end;

        Commit(); // to ensure no deadlock occurs when waiting for background processes

        if not HideDialog then
            ConfigProgressBar.Close();
        if not ExcelMode then
            ParallelSessionManagement.WaitForAllToFinish(0);

        ConfigPackageMgt.UpdateConfigLinePackageData(ConfigPackage.Code);
        DurationAsInt := CurrentDateTime() - StartTime;

        Dimensions.Add('ExecutionTimeInMs', Format(DurationAsInt));
        Dimensions.Add('FileSizeInBytes', Format(FileSize));
        Session.LogMessage('0000E3I', StrSubstNo(PackageImportFinishScopeAllMsg, ConfigPackage.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        Session.LogMessage('00009Q7', StrSubstNo(PackageImportFinishMsg, DurationAsInt, FileSize), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

        // autoapply configuration lines
        ConfigPackageMgt.ApplyConfigTables(ConfigPackage);

        ConfigPackageMgt.SentPackageImportedNotification(PackageCode);

        Result := true;
        OnAfterImportPackageXMLDocument(PackageCode, ExcelMode, Result);
    end;

    [TryFunction]
    internal procedure GetTableStatisticsForTelemetry(TableNode: DotNet XmlNode; var TableName: Text; var RecordCount: Integer; var TotalTableFields: Integer; var ImportedTableFields: Integer)
    var
        CurrTableRecordRef: RecordRef;
        TableNodeList: DotNet XmlNodeList;
        TableChildNode: DotNet XmlNode;
        NoOfChildNodes: Integer;
        TableID: Integer;
        NonRecordNodeCount: Integer;
        TableElementName: Text;
    begin
        Evaluate(TableID, Format(TableNode.FirstChild().InnerText()));
        CurrTableRecordRef.Open(TableID);
        TableName := CurrTableRecordRef.Name();
        TotalTableFields := CurrTableRecordRef.FieldCount();
        CurrTableRecordRef.Close();

        TableNodeList := TableNode.ChildNodes();
        NoOfChildNodes := TableNodeList.Count();

        // ignore TableID, PageID, SkipTableTriggers etc child nodes for the table
        TableElementName := GetElementName(CopyStr(TableName, 1, 250));
        NonRecordNodeCount := 0;
        foreach TableChildNode in TableNodeList do begin
            if TableChildNode.Name().Contains(TableElementName) then
                break;
            NonRecordNodeCount += 1;
        end;

        RecordCount := NoOfChildNodes - NonRecordNodeCount;
        if RecordCount > 0 then
            ImportedTableFields := TableNode.LastChild().ChildNodes().Count();
    end;

    [Scope('OnPrem')]
    procedure ImportTableFromXMLNode(var TableNode: DotNet XmlNode; var PackageCode: Code[20])
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageTable: Record "Config. Package Table";
        TableID: Integer;
    begin
        if Evaluate(TableID, Format(TableNode.FirstChild.InnerText)) then begin
            FillPackageMetadataFromXML(PackageCode, TableID, TableNode);
            if not TableObjectExists(TableID) then begin
                ConfigPackageMgt.InsertPackageTableWithoutValidation(ConfigPackageTable, PackageCode, TableID);
                ConfigPackageMgt.InitPackageRecord(ConfigPackageRecord, PackageCode, TableID);
                ConfigPackageMgt.RecordError(ConfigPackageRecord, 0, CopyStr(StrSubstNo(TableDoesNotExistErr, TableID), 1, 250));
            end else
                if PackageDataExistsInXML(PackageCode, TableID, TableNode) then
                    FillPackageDataFromXML(PackageCode, TableID, TableNode);
        end;
    end;

    local procedure PackageDataExistsInXML(PackageCode: Code[20]; TableID: Integer; var TableNode: DotNet XmlNode): Boolean
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        RecRef: RecordRef;
        RecordNodes: DotNet XmlNodeList;
        RecordNode: DotNet XmlNode;
        I: Integer;
    begin
        if not ConfigPackageTable.Get(PackageCode, TableID) then
            exit(false);

        ConfigPackageTable.CalcFields("Table Name");
        RecordNodes := TableNode.SelectNodes(GetElementName(ConfigPackageTable."Table Name"));

        if RecordNodes.Count = 0 then
            exit(false);

        for I := 0 to RecordNodes.Count - 1 do begin
            RecordNode := RecordNodes.Item(I);
            if RecordNode.HasChildNodes then begin
                RecRef.Open(ConfigPackageTable."Table ID");
                ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
                ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
                if ConfigPackageField.FindSet() then
                    repeat
                        if ConfigPackageField."Include Field" and FieldNodeExists(RecordNode, GetElementName(ConfigPackageField."Field Name")) then
                            if GetNodeValue(RecordNode, GetElementName(ConfigPackageField."Field Name")) <> '' then
                                exit(true);
                    until ConfigPackageField.Next() = 0;
                RecRef.Close();
            end;
        end;

        exit(false);
    end;

    [TryFunction]
    local procedure TryOpenTable(TableId: Integer)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableId);
    end;

    local procedure FillPackageMetadataFromXML(var PackageCode: Code[20]; TableID: Integer; var TableNode: DotNet XmlNode)
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        "Field": Record "Field";
        ConfigMgt: Codeunit "Config. Management";
        RecordNodes: DotNet XmlNodeList;
        RecordNode: DotNet XmlNode;
        FieldNode: DotNet XmlNode;
        Value: Text;
        IsTableInserted: Boolean;
    begin
        if ExcelMode then begin
            PackageCode :=
              CopyStr(GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Package Code"))), 1, MaxStrLen(PackageCode));
            if PackageCode = '' then
                Error(MissingInExcelFileErr, ConfigPackageTable.FieldCaption("Package Code"));
        end;
        if (TableID > 0) and (not ConfigPackageTable.Get(PackageCode, TableID)) and TryOpenTable(TableID) then begin
            if not ExcelMode then begin
                ConfigPackageTable.Init();
                ConfigPackageTable."Package Code" := PackageCode;
                ConfigPackageTable."Table ID" := TableID;
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Page ID")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Page ID", Value);
                if ConfigPackageTable."Page ID" = 0 then
                    ConfigPackageTable."Page ID" := ConfigMgt.FindPage(TableID);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Package Processing Order")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Package Processing Order", Value);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Processing Order")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Processing Order", Value);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Dimensions as Columns")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Dimensions as Columns", Value);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Skip Table Triggers")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Skip Table Triggers", Value);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Parent Table ID")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Parent Table ID", Value);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Delete Recs Before Processing")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Delete Recs Before Processing", Value);
                Value := GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Created by User ID")));
                if Value <> '' then
                    Evaluate(ConfigPackageTable."Created by User ID", CopyStr(Value, 1, 50));
                OnFillPackageMetadataFromXMLOnAfterGetPackageTableValueFromXML(ConfigPackageTable, TableNode);
                ConfigPackageTable."Data Template" :=
                  CopyStr(
                    GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName("Data Template"))), 1,
                    MaxStrLen(ConfigPackageTable."Data Template"));
                ConfigPackageTable.Comments :=
                  CopyStr(
                    GetNodeValue(TableNode, GetElementName(ConfigPackageTable.FieldName(Comments))),
                    1, MaxStrLen(ConfigPackageTable.Comments));
                ConfigPackageTable."Imported Date and Time" := CreateDateTime(Today, Time);
                ConfigPackageTable."Imported by User ID" := UserId;
                ConfigPackageTable.Insert(true);
                ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
                ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
                ConfigPackageMgt.SelectAllPackageFields(ConfigPackageField, false);
            end else begin // Excel import
                if not ConfigPackage.Get(PackageCode) then begin
                    ConfigPackage.Init();
                    ConfigPackage.Validate(Code, PackageCode);
                    ConfigPackage.Insert(true);
                end;
                ConfigPackageTable.Init();
                ConfigPackageTable."Package Code" := PackageCode;
                ConfigPackageTable."Table ID" := TableID;
                ConfigPackageTable.Insert(true);
                IsTableInserted := true;
            end;

            ConfigPackageTable.CalcFields("Table Name");
            if ConfigPackageTable."Table Name" <> '' then begin
                RecordNodes := TableNode.SelectNodes(GetElementName(ConfigPackageTable."Table Name"));
                if RecordNodes.Count > 0 then begin
                    RecordNode := RecordNodes.Item(0);
                    if RecordNode.HasChildNodes then begin
                        ConfigPackageMgt.SetFieldFilter(Field, TableID, 0);
                        if Field.FindSet() then
                            repeat
                                if FieldNodeExists(RecordNode, GetElementName(Field.FieldName)) then begin
                                    ConfigPackageField.Get(PackageCode, TableID, Field."No.");
                                    ConfigPackageField."Primary Key" := ConfigValidateMgt.IsKeyField(TableID, Field."No.");
                                    ConfigPackageField."Include Field" := true;
                                    FieldNode := RecordNode.SelectSingleNode(GetElementName(Field.FieldName));
                                    if not IsNull(FieldNode) and not ExcelMode then begin
                                        Value := GetAttribute(GetElementName(ConfigPackageField.FieldName("Primary Key")), FieldNode);
                                        ConfigPackageField."Primary Key" := Value = '1';
                                        Value := GetAttribute(GetElementName(ConfigPackageField.FieldName("Validate Field")), FieldNode);
                                        ConfigPackageField."Validate Field" := (Value = '1') and
                                          not ConfigPackageMgt.ValidateException(TableID, Field."No.");
                                        Value := GetAttribute(GetElementName(ConfigPackageField.FieldName("Create Missing Codes")), FieldNode);
                                        ConfigPackageField."Create Missing Codes" := (Value = '1') and
                                          not ConfigPackageMgt.ValidateException(TableID, Field."No.");
                                        Value := GetAttribute(GetElementName(ConfigPackageField.FieldName("Processing Order")), FieldNode);
                                        if Value <> '' then
                                            Evaluate(ConfigPackageField."Processing Order", Value);

                                        OnFillPackageMetadataFromXMLOnBeforeConfigPackageFieldModify(ConfigPackageField, Value, FieldNode);
                                    end;
                                    ConfigPackageField.Modify();
                                end;
                            until Field.Next() = 0;
                        if IsTableInserted then
                            AddDimPackageFields(ConfigPackageTable, RecordNode);
                    end;
                end;
            end;
        end;
    end;

    local procedure FillPackageDataFromXML(PackageCode: Code[20]; TableID: Integer; var TableNode: DotNet XmlNode)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageField: Record "Config. Package Field";
        TempConfigPackageField: Record "Config. Package Field" temporary;
        ConfigProgressBarRecord: Codeunit "Config. Progress Bar";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        RecordNodes: DotNet XmlNodeList;
        RecordNode: DotNet XmlNode;
        NodeCount: Integer;
        RecordCount: Integer;
        StepCount: Integer;
        ErrorText: Text[250];
        ShouldAssignValue: Boolean;
        ShouldShowTableContainsRecordsQst: Boolean;
    begin
        if ConfigMgt.IsSystemTable(TableID) then
            exit;

        if ConfigPackageTable.Get(PackageCode, TableID) then begin
            ExcludeRemovedFields(ConfigPackageTable);
            if ExcelMode then begin
                ConfigPackageTable.CalcFields("No. of Package Records");
                ShouldShowTableContainsRecordsQst := ConfigPackageTable."No. of Package Records" > 0;
                OnFillPackageDataFromXMLOnAfterCalcShouldShowTableContainsRecordsQst(ConfigPackageTable, PackageCode, TableID, HideDialog, ShouldShowTableContainsRecordsQst);
                if ShouldShowTableContainsRecordsQst then
                    if Confirm(TableContainsRecordsQst, true, TableID, PackageCode, ConfigPackageTable."No. of Package Records") then
                        ConfigPackageTable.DeletePackageData()
                    else
                        exit;
            end;
            ConfigPackageTable.CalcFields("Table Name");
            if not HideDialog then
                ConfigProgressBar.Update(ConfigPackageTable."Table Name");
            RecordNodes := TableNode.SelectNodes(GetElementName(ConfigPackageTable."Table Name"));
            RecordCount := RecordNodes.Count();

            if not HideDialog and (RecordCount > 1000) then begin
                StepCount := Round(RecordCount / 100, 1);
                ConfigProgressBarRecord.Init(RecordCount, StepCount,
                  StrSubstNo(RecordProgressTxt, ConfigPackageTable."Table Name"));
            end;

            ConfigPackageField.SetRange("Package Code", ConfigPackageTable."Package Code");
            ConfigPackageField.SetRange("Table ID", ConfigPackageTable."Table ID");
            ConfigPackageField.SetRange("Include Field", true);
            if ConfigPackageField.FindSet() then
                repeat
                    TempConfigPackageField := ConfigPackageField;
                    TempConfigPackageField.Insert();
                until ConfigPackageField.Next() = 0;

            for NodeCount := 0 to RecordCount - 1 do begin
                RecordNode := RecordNodes.Item(NodeCount);
                if RecordNode.HasChildNodes then begin
                    ConfigPackageMgt.InitPackageRecord(ConfigPackageRecord, PackageCode, ConfigPackageTable."Table ID");

                    RecRef.Close();
                    RecRef.Open(ConfigPackageTable."Table ID");
                    if TempConfigPackageField.FindSet() then
                        repeat
                            ConfigPackageData.Init();
                            OnFillPackageDataFromXMLOnAfterConfigPackageDataInit(ConfigPackageData, TempConfigPackageField);
                            ConfigPackageData."Package Code" := TempConfigPackageField."Package Code";
                            ConfigPackageData."Table ID" := TempConfigPackageField."Table ID";
                            ConfigPackageData."Field ID" := TempConfigPackageField."Field ID";
                            ConfigPackageData."No." := ConfigPackageRecord."No.";
                            if FieldNodeExists(RecordNode, TempConfigPackageField.GetElementName()) or
                               TempConfigPackageField.Dimension
                            then
                                GetConfigPackageDataValue(ConfigPackageData, RecordNode, TempConfigPackageField.GetElementName());
                            OnFillPackageDataFromXMLOnAfterConfigPackageDataInsert(ConfigPackageData, TempConfigPackageField, ExcelMode);
                            ConfigPackageData.Insert();

                            ShouldAssignValue := not TempConfigPackageField.Dimension;
                            OnFillPackageDataFromXMLOnAfterCalcShouldAssignValue(ConfigPackageField, ConfigPackageData, ConfigPackageRecord, TempConfigPackageField, ShouldAssignValue);
                            if ShouldAssignValue then begin
                                FieldRef := RecRef.Field(ConfigPackageData."Field ID");
                                if ConfigPackageData.Value <> '' then begin
                                    ErrorText := CopyStr(ConfigValidateMgt.EvaluateValue(FieldRef, ConfigPackageData.Value, not ExcelMode), 1, MaxStrLen(ErrorText));
                                    if ErrorText <> '' then
                                        ConfigPackageMgt.FieldError(ConfigPackageData, ErrorText, ErrorTypeEnum::General)
                                    else
                                        ConfigPackageData.Value := Format(FieldRef.Value);

                                    ConfigPackageData.Modify();
                                end;
                            end;
                        until TempConfigPackageField.Next() = 0;
                    ConfigPackageTable."Imported Date and Time" := CurrentDateTime;
                    ConfigPackageTable."Imported by User ID" := UserId;
                    ConfigPackageTable.Modify();
                    if not HideDialog and (RecordCount > 1000) then
                        ConfigProgressBarRecord.Update(
                          StrSubstNo('Records: %1 of %2', ConfigPackageRecord."No.", RecordCount));
                end;
            end;
            if not HideDialog and (RecordCount > 1000) then
                ConfigProgressBarRecord.Close();
        end;
    end;

    local procedure ExcludeRemovedFields(ConfigPackageTable: Record "Config. Package Table")
    var
        "Field": Record "Field";
        ConfigPackageField: Record "Config. Package Field";
    begin
        Field.SetRange(TableNo, ConfigPackageTable."Table ID");
        Field.SetRange(ObsoleteState, Field.ObsoleteState::Removed);
        if Field.FindSet() then
            repeat
                if ConfigPackageField.Get(ConfigPackageTable."Package Code", Field.TableNo, Field."No.") then begin
                    ConfigPackageField.Validate("Include Field", false);
                    ConfigPackageField.Modify();
                end;
            until Field.Next() = 0;
    end;

    local procedure FieldNodeExists(var RecordNode: DotNet XmlNode; FieldNodeName: Text[250]): Boolean
    var
        FieldNode: DotNet XmlNode;
    begin
        FieldNode := RecordNode.SelectSingleNode(FieldNodeName);

        if not IsNull(FieldNode) then
            exit(true);
    end;

    local procedure FormatFieldValue(var FieldRef: FieldRef; ConfigPackage: Record "Config. Package") InnerText: Text
    var
        TypeHelper: Codeunit "Type Helper";
        Date: Date;
    begin
        if not ((FieldRef.Type in [FieldType::Integer, FieldType::BLOB]) and
                (FieldRef.Relation <> 0) and (Format(FieldRef.Value) = '0'))
        then
            InnerText := Format(FieldRef.Value, 0, ConfigValidateMgt.XMLFormat());

        if not ExcelMode then
            case FieldRef.Type of
                FieldType::Boolean, FieldType::Option:
                    InnerText := Format(FieldRef.Value, 0, 2);
                FieldType::DateFormula:
                    if Format(FieldRef.Value) <> '' then
                        InnerText := '<' + Format(FieldRef.Value, 0, ConfigValidateMgt.XMLFormat()) + '>';
                FieldType::Blob:
                    InnerText := ConvertBlobToBase64String(FieldRef);
                FieldType::MediaSet:
                    InnerText := ExportMediaSet(FieldRef);
                FieldType::Media:
                    InnerText := ExportMedia(FieldRef, ConfigPackage);
            end
        else
            case FieldRef.Type of
                FieldType::Option:
                    InnerText := Format(FieldRef.Value);
                FieldType::Date:
                    if (ConfigPackage."Language ID" <> 0) and (InnerText <> '') then begin
                        Evaluate(Date, Format(FieldRef.Value));
                        InnerText := TypeHelper.FormatDate(Date, ConfigPackage."Language ID");
                    end;
                FieldType::Blob:
                    InnerText := ConvertBlobToBase64String(FieldRef);
            end;

        OnFormatFieldValueOnBeforeExitInnerText(FieldRef, ConfigPackage, InnerText);

        exit(InnerText);
    end;

    [Scope('OnPrem')]
    procedure GetAttribute(AttributeName: Text[1024]; var XMLNode: DotNet XmlNode): Text[1000]
    var
        XMLAttributes: DotNet XmlNamedNodeMap;
        XMLAttributeNode: DotNet XmlNode;
    begin
        XMLAttributes := XMLNode.Attributes;
        XMLAttributeNode := XMLAttributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttributeNode) then
            exit('');
        exit(Format(XMLAttributeNode.InnerText));
    end;

    local procedure GetDimValueFromTable(var RecRef: RecordRef; DimCode: Code[20]): Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
        DefaultDim: Record "Default Dimension";
        ConfigMgt: Codeunit "Config. Management";
        FieldRef: FieldRef;
        DimSetID: Integer;
        MasterNo: Code[20];
    begin
        if RecRef.FieldExist(480) then begin // Dimension Set ID
            FieldRef := RecRef.Field(480);
            DimSetID := FieldRef.Value();
            if DimSetID > 0 then begin
                DimSetEntry.SetRange("Dimension Set ID", DimSetID);
                DimSetEntry.SetRange("Dimension Code", DimCode);
                if DimSetEntry.FindFirst() then
                    exit(DimSetEntry."Dimension Value Code");
            end;
        end else
            if ConfigMgt.IsDefaultDimTable(RecRef.Number) then begin // Default Dimensions
                FieldRef := RecRef.Field(GetDefaultDimensionNoLinkFieldNumber(RecRef.Number));
                DefaultDim.SetRange("Table ID", RecRef.Number);
                MasterNo := Format(FieldRef.Value);
                DefaultDim.SetRange("No.", MasterNo);
                DefaultDim.SetRange("Dimension Code", DimCode);
                if DefaultDim.FindFirst() then
                    exit(DefaultDim."Dimension Value Code");
            end;
    end;

    procedure GetElementName(NameIn: Text[250]): Text[250]
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        OnBeforeGetElementName(NameIn);

        if not XMLDOMManagement.IsValidXMLNameStartCharacter(NameIn[1]) then
            NameIn := '_' + NameIn;
        NameIn := CopyStr(XMLDOMManagement.ReplaceXMLInvalidCharacters(NameIn, ' '), 1, MaxStrLen(NameIn));
        NameIn := DelChr(NameIn, '=', '?''`');
        NameIn := ConvertStr(NameIn, '<>,./\+&()%:', '            ');
        NameIn := ConvertStr(NameIn, '-', '_');
        NameIn := DelChr(NameIn, '=', ' ');
        exit(NameIn);
    end;

    procedure GetFieldElementName(NameIn: Text[250]): Text[250]
    begin
        if AddPrefixMode then
            NameIn := CopyStr('Field_' + NameIn, 1, MaxStrLen(NameIn));

        exit(GetElementName(NameIn));
    end;

    procedure GetTableElementName(NameIn: Text[250]): Text[250]
    begin
        if AddPrefixMode then
            NameIn := CopyStr('Table_' + NameIn, 1, MaxStrLen(NameIn));

        exit(GetElementName(NameIn));
    end;

    local procedure GetNodeValue(var RecordNode: DotNet XmlNode; FieldNodeName: Text[250]): Text
    var
        FieldNode: DotNet XmlNode;
    begin
        FieldNode := RecordNode.SelectSingleNode(FieldNodeName);
        if not IsNull(FieldNode) then
            exit(FieldNode.InnerText);
    end;

    local procedure GetPackageTag(): Text
    begin
        exit(DataListTxt);
    end;

    [Scope('OnPrem')]
    procedure GetPackageCode(PackageXML: DotNet XmlDocument): Code[20]
    var
        ConfigPackage: Record "Config. Package";
        DocumentElement: DotNet XmlElement;
    begin
        DocumentElement := PackageXML.DocumentElement;
        exit(CopyStr(GetAttribute(GetElementName(ConfigPackage.FieldName(Code)), DocumentElement), 1, MaxStrLen(ConfigPackage.Code)));
    end;

    local procedure GetDefaultDimensionNoLinkFieldNumber(TableID: Integer): Integer
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        FieldNumber: Integer;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        FieldRef := KeyRef.FieldIndex(1);
        FieldNumber := FieldRef.Number;
        OnAfterGetDefaultDimensionNoLinkFieldNumber(TableID, FieldNumber);
        exit(FieldNumber);
    end;

    local procedure InitializeMediaTempFolder()
    var
        MediaFolder: Text;
    begin
        if ExcelMode then
            exit;

        if WorkingFolder = '' then
            exit;

        MediaFolder := GetCurrentMediaFolderPath();
        if FileManagement.ServerDirectoryExists(MediaFolder) then
            FileManagement.ServerRemoveDirectory(MediaFolder, true);

        FileManagement.ServerCreateDirectory(MediaFolder);
    end;

    local procedure GetCurrentMediaFolderPath(): Text
    begin
        exit(FileManagement.CombinePath(WorkingFolder, GetMediaFolderName()));
    end;

    [Scope('OnPrem')]
    procedure GetMediaFolder(var MediaFolderPath: Text; SourcePath: Text): Boolean
    var
        SourceDirectory: Text;
    begin
        if FileManagement.ServerFileExists(SourcePath) then
            SourceDirectory := FileManagement.GetDirectoryName(SourcePath)
        else
            if FileManagement.ServerDirectoryExists(SourcePath) then
                SourceDirectory := SourcePath;

        if SourceDirectory = '' then
            exit(false);

        MediaFolderPath := FileManagement.CombinePath(SourceDirectory, GetMediaFolderName());
        exit(FileManagement.ServerDirectoryExists(MediaFolderPath));
    end;

    procedure GetMediaFolderName(): Text
    begin
        exit('Media');
    end;

    procedure GetXSDType(TableID: Integer; FieldID: Integer) Result: Text[30]
    var
        "Field": Record "Field";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetXSDType(TableID, FieldID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Field.Get(TableID, FieldID) then
            case Field.Type of
                Field.Type::Integer:
                    exit('xsd:integer');
                Field.Type::Date:
                    exit('xsd:date');
                Field.Type::Time:
                    exit('xsd:time');
                Field.Type::Boolean:
                    exit('xsd:boolean');
                Field.Type::DateTime:
                    exit('xsd:dateTime');
                else
                    exit('xsd:string');
            end;

        exit('xsd:string');
    end;

    procedure SetAdvanced(NewAdvanced: Boolean)
    begin
        Advanced := NewAdvanced;
    end;

    procedure SetCalledFromCode(NewCalledFromCode: Boolean)
    begin
        CalledFromCode := NewCalledFromCode;
    end;

    local procedure SetWorkingFolder(NewWorkingFolder: Text)
    begin
        WorkingFolder := NewWorkingFolder;
    end;

    procedure SetExcelMode(NewExcelMode: Boolean)
    begin
        ExcelMode := NewExcelMode;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetExportFromWksht(NewExportFromWksht: Boolean)
    begin
        // Obsolete method
        Clear(NewExportFromWksht);
    end;

    procedure SetPrefixMode(PrefixMode: Boolean)
    begin
        AddPrefixMode := PrefixMode;
    end;

    procedure TableObjectExists(TableId: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        exit(TableMetadata.Get(TableId) and (TableMetadata.ObsoleteState <> TableMetadata.ObsoleteState::Removed));
    end;

    [Scope('OnPrem')]
    procedure DecompressPackage(ServerFileName: Text) DecompressedFileName: Text
    begin
        DecompressedFileName := FileManagement.ServerTempFileName('');
        if not ConfigPckgCompressionMgt.ServersideDecompress(ServerFileName, DecompressedFileName) then
            Error(WrongFileTypeErr);
    end;

    procedure DecompressPackageToBlob(var TempBlob: Codeunit "Temp Blob"; var TempBlobUncompressed: Codeunit "Temp Blob")
    var
        InStream: InStream;
        OutStream: OutStream;
        CompressionMode: DotNet CompressionMode;
        CompressedStream: DotNet GZipStream;
    begin
        TempBlob.CreateInStream(InStream);
        CompressedStream := CompressedStream.GZipStream(InStream, CompressionMode.Decompress); // Decompress the stream
        TempBlobUncompressed.CreateOutStream(OutStream);  // Creates outstream to enable you to write data to the blob.
        CopyStream(OutStream, CompressedStream); // Copy contents from the CompressedStream to the OutStream, this populates the blob with the decompressed file.
    end;

    local procedure UploadXMLPackage(ServerFileName: Text): Boolean
    begin
        exit(Upload(ImportFileTxt, '', GetFileDialogFilter(), '', ServerFileName));
    end;

    procedure GetFileDialogFilter(): Text
    begin
        exit(FileDialogFilterTxt);
    end;

    local procedure ConvertBlobToBase64String(var FieldRef: FieldRef): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromFieldRef(FieldRef);
        TempBlob.CreateInStream(InStream);
        exit(Base64Convert.ToBase64(InStream));
    end;

    local procedure ExportMediaSet(var FieldRef: FieldRef): Text
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        FilesExported: Integer;
        ItemPrefixPath: Text;
        MediaFolder: Text;
    begin
        if ExcelMode then
            exit;

        if not GetMediaFolder(MediaFolder, WorkingFolder) then
            exit('');

        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer."Media Set" := FieldRef.Value();
        TempConfigMediaBuffer.Insert();
        if TempConfigMediaBuffer."Media Set".Count = 0 then
            exit;

        ItemPrefixPath := MediaFolder + '\' + Format(TempConfigMediaBuffer."Media Set");
        FilesExported := TempConfigMediaBuffer."Media Set".ExportFile(ItemPrefixPath);
        if FilesExported <= 0 then
            exit('');

        exit(Format(FieldRef.Value));
    end;

    local procedure ExportMedia(var FieldRef: FieldRef; ConfigPackage: Record "Config. Package"): Text
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        MediaOutStream: OutStream;
        MediaIDGuidText: Text;
        BlankGuid: Guid;
    begin
        if ExcelMode then
            exit;

        MediaIDGuidText := Format(FieldRef.Value);
        if (MediaIDGuidText = '') or (MediaIDGuidText = Format(BlankGuid)) then
            exit;

        ConfigMediaBuffer.Init();
        ConfigMediaBuffer."Package Code" := ConfigPackage.Code;
        ConfigMediaBuffer."Media ID" := MediaIDGuidText;
        ConfigMediaBuffer."No." := ConfigMediaBuffer.GetNextNo();
        ConfigMediaBuffer.Insert();

        ConfigMediaBuffer."Media Blob".CreateOutStream(MediaOutStream);

        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer.Media := FieldRef.Value();
        TempConfigMediaBuffer.Insert();
        TempConfigMediaBuffer.Media.ExportStream(MediaOutStream);

        ConfigMediaBuffer.Modify();

        exit(MediaIDGuidText);
    end;

    local procedure GetConfigPackageDataValue(var ConfigPackageData: Record "Config. Package Data"; var RecordNode: DotNet XmlNode; FieldNodeName: Text[250])
    var
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
    begin
        if ConfigPackageMgt.IsBLOBField(ConfigPackageData."Table ID", ConfigPackageData."Field ID") then begin
            ConfigPackageData."BLOB Value".CreateOutStream(OutStream);
            Base64Convert.FromBase64(GetNodeValue(RecordNode, FieldNodeName), OutStream);
        end else
            ConfigPackageData.Value := CopyStr(GetNodeValue(RecordNode, FieldNodeName), 1, MaxStrLen(ConfigPackageData.Value));
    end;

    local procedure UpdateConfigPackageMediaSet(ConfigPackage: Record "Config. Package")
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
        MediaFolder: Text;
    begin
        if not GetMediaFolder(MediaFolder, WorkingFolder) then
            exit;

        FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, MediaFolder);
        if not TempNameValueBuffer.FindSet() then
            exit;

        repeat
            ImportMediaSetFromFile(ConfigPackage, TempNameValueBuffer.Name);
        until TempNameValueBuffer.Next() = 0;

        FileManagement.ServerRemoveDirectory(MediaFolder, true);
    end;

    local procedure ExportConfigPackageMediaSetToXML(var PackageXML: DotNet XmlDocument; ConfigPackage: Record "Config. Package")
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageManagement: Codeunit "Config. Package Management";
    begin
        ConfigMediaBuffer.SetRange("Package Code", ConfigPackage.Code);
        if ConfigMediaBuffer.IsEmpty() then
            exit;

        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, ConfigPackage.Code, DATABASE::"Config. Media Buffer");
        ConfigPackageManagement.InsertPackageFilter(
            ConfigPackageFilter, ConfigPackage.Code, DATABASE::"Config. Media Buffer", 0,
            ConfigMediaBuffer.FieldNo("Package Code"), ConfigPackage.Code);
        ConfigPackageTable.CalcFields("Table Name");
        ExportConfigTableToXML(ConfigPackageTable, PackageXML);
    end;

    local procedure ImportMediaSetFromFile(ConfigPackage: Record "Config. Package"; FileName: Text)
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        RecordRef: RecordRef;
        DummyGuid: Guid;
    begin
        ConfigMediaBuffer.Init();
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);

        RecordRef.GetTable(ConfigMediaBuffer);
        TempBlob.ToRecordRef(RecordRef, ConfigMediaBuffer.FieldNo("Media Blob"));
        RecordRef.SetTable(ConfigMediaBuffer);

        ConfigMediaBuffer."Package Code" := ConfigPackage.Code;
        ConfigMediaBuffer."Media Set ID" := CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, StrLen(Format(DummyGuid)));
        ConfigMediaBuffer."No." := ConfigMediaBuffer.GetNextNo();
        ConfigMediaBuffer.Insert();
    end;

    local procedure CleanUpConfigPackageData(ConfigPackage: Record "Config. Package")
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
    begin
        ConfigMediaBuffer.SetRange("Package Code", ConfigPackage.Code);
        ConfigMediaBuffer.DeleteAll();
    end;

    local procedure AddDimensionFieldsWhenProcessingOrder(var ConfigPackageField: Record "Config. Package Field"; var RecRef: RecordRef; var PackageXML: DotNet XmlDocument; var RecordNode: DotNet XmlNode; var FieldNode: DotNet XmlNode; ExportValue: Boolean)
    var
        DimCode: Code[20];
    begin
        FieldNode :=
          PackageXML.CreateElement(
            GetElementName(CopyStr(ConfigValidateMgt.CheckName(ConfigPackageField."Field Name"), 1, 250)));
        if ExportValue then begin
            DimCode := CopyStr(ConfigPackageField."Field Name", 1, 20);
            FieldNode.InnerText := GetDimValueFromTable(RecRef, DimCode);
            RecordNode.AppendChild(FieldNode);
        end else begin
            FieldNode.InnerText := '';
            RecordNode.AppendChild(FieldNode);
        end;
    end;

    local procedure VerifyCanImportConfigurationPackage()
    var
        CanImportConfigurationPackage: Boolean;
    begin
        OnVerifyCanImportConfigurationPackage(CanImportConfigurationPackage);
        if CanImportConfigurationPackage then
            exit;

        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            Error(ImportingIsNotAllowedDuringUpgradeOrInstallationErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddFieldAttributes(var ConfigPackageField: Record "Config. Package Field"; var FieldNode: DotNet XmlNode)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddTableAttributes(ConfigPackageTable: Record "Config. Package Table"; var PackageXML: DotNet XmlDocument; var TableNode: DotNet XmlNode)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExportPackageXMLDocument(var ConfigPackage: Record "Config. Package"; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportPackageXMLDocument(PackageCode: Code[20]; ExcelMode: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyPackageFilter(ConfigPackageTable: Record "Config. Package Table"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRecordNodes(var ConfigPackageTable: Record "Config. Package Table"; var ConfigPackageField: Record "Config. Package Field"; var TypeHelper: Codeunit "Type Helper"; var XMLDOMManagement: Codeunit "XML DOM Management"; var WorkingFolder: Text; var ExcelMode: Boolean; var Advanced: Boolean; var HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateMinCountForAsyncImport(var ConfigPackage: Record "Config. Package"; var Value: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetXSDType(TableID: Integer; FieldID: Integer; var Result: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetElementName(var NameIn: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnAfterConfigPackageFieldSetFilters(ConfigPackageTable: Record "Config. Package Table"; var ConfigPackageField: Record "Config. Package Field")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnBeforeRecRefLoopIteration(ConfigPackageTable: Record "Config. Package Table"; ConfigPackage: Record "Config. Package"; var RecRef: RecordRef; var ConfigProgressBar: Codeunit "Config. Progress Bar"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnAfterApplyPackageFilter(ConfigPackageTable: Record "Config. Package Table"; ConfigPackage: Record "Config. Package"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnAfterRecordProcessed(ConfigPackageTable: Record "Config. Package Table"; var ConfigPackageField: Record "Config. Package Field"; var RecRef: RecordRef; var PackageXML: DotNet XmlDocument; var RecordNode: DotNet XmlNode; var FieldNode: DotNet XmlNode; ExcelMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnNotFoundOnAfterConfigPackageFieldSetFilters(ConfigPackageTable: Record "Config. Package Table"; var ConfigPackageField: Record "Config. Package Field")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnAfterNotFoundRecordProcessed(ConfigPackageTable: Record "Config. Package Table"; var ConfigPackageField: Record "Config. Package Field"; var RecRef: RecordRef; var PackageXML: DotNet XmlDocument; var RecordNode: DotNet XmlNode; var FieldNode: DotNet XmlNode; ExcelMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportPackageXMLDocumentOnAfterSetAttributes(var ConfigPackage: Record "Config. Package"; var XMLDOMMgt: Codeunit "XML DOM Management"; var DocumentElement: DotNet XmlElement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportPackageXMLDocumentOnBeforeConfigProgressBarInit(var ConfigPackageTable: Record "Config. Package Table"; var ConfigPackage: Record "Config. Package"; var XMLDOMMgt: Codeunit "XML DOM Management"; Advanced: Boolean; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportPackageXMLOnAfterAssignToFile(ConfigPackage: Record "Config. Package"; var ToFile: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnExportPackageXMLOnAfterAssignToFileOnAfterSetCompressedFileName(var CompressedFileName: Text; XMLDataFile: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillPackageMetadataFromXMLOnAfterGetPackageTableValueFromXML(ConfigPackageTable: Record "Config. Package Table"; var TableNode: DotNet XmlNode)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillPackageDataFromXMLOnAfterConfigPackageDataInit(var ConfigPackageData: Record "Config. Package Data"; var ConfigPackageField: Record "Config. Package Field")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillPackageDataFromXMLOnAfterCalcShouldShowTableContainsRecordsQst(var ConfigPackageTable: Record "Config. Package Table"; PackageCode: Code[20]; TableID: Integer; var HideDialog: Boolean; var ShouldShowTableContainsRecordsQst: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillPackageDataFromXMLOnAfterCalcShouldAssignValue(var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageData: Record "Config. Package Data"; var ConfigPackageRecord: Record "Config. Package Record"; var TempConfigPackageField: Record "Config. Package Field" temporary; var ShouldAssignValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillPackageDataFromXMLOnAfterConfigPackageDataInsert(var ConfigPackageData: Record "Config. Package Data"; var ConfigPackageField: Record "Config. Package Field"; ExcelMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportPackageXMLDocumentOnDefaultDimOnAfterConfigPackageRecordSetFilters(var ConfigPackageRecord: Record "Config. Package Record"; ConfigPackageData: Record "Config. Package Data"; PackageCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateRecordNodesOnBeforeApplyPackageFilter(var ConfigPackageTable: Record "Config. Package Table"; var RecordReference: RecordRef; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportPackageXMLDocumentOnBeforeModify(var ConfigPackage: Record "Config. Package"; var DocumentElement: DotNet XmlElement)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillPackageMetadataFromXMLOnBeforeConfigPackageFieldModify(var ConfigPackageField: Record "Config. Package Field"; var Value: Text; var FieldNode: DotNet XmlNode)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatFieldValueOnBeforeExitInnerText(var FieldRef: FieldRef; ConfigPackage: Record "Config. Package"; var InnerText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultDimensionNoLinkFieldNumber(TableID: Integer; var FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyCanImportConfigurationPackage(var CanImportConfigurationPackage: Boolean)
    begin
    end;
}
