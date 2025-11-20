// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using System.Environment;
using System.IO;
using System.Telemetry;

table 333 "Column Layout Name"
{
    Caption = 'Financial Report Column Definition';
    DataCaptionFields = Name, Description;
    LookupPageID = "Column Layout Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            ToolTip = 'Specifies the unique name (code) of the financial report column definition. You can use up to 10 characters.';
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the financial report columns definition. The description is not shown on the final report but is used to provide more context when using the definition.';
        }
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";
            ToolTip = 'Specifies the name of the analysis view you want the column definition to use. This field is optional.';
        }
        field(5; "Internal Description"; Text[250])
        {
            Caption = 'Internal Description';
            ToolTip = 'Specifies the internal description of the column definition. The internal description is not shown on the final report but is used to provide more context when using the definition.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name, Description, "Analysis View Name")
        {
        }
    }

    trigger OnDelete()
    begin
        ColumnLayout.SetRange("Column Layout Name", Name);
        ColumnLayout.DeleteAll();
    end;

    var
        ColumnLayout: Record "Column Layout";
        PackageImportErr: Label 'The imported package is not valid.';
        TelemetryEventTxt: Label 'Financial Report Column Definition %1: %2', Comment = '%1 = event type, %2 = column definition', Locked = true;

    procedure XMLExchangeExport()
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        ConfigPackageCode: Code[20];
    begin
        ConfigPackageCode := AddColumnDefinitionToPackage(Rec.Name);
        ConfigPackage.Get(ConfigPackageCode);
        ConfigXMLExchange.ExportPackage(ConfigPackage);
        LogImportExportTelemetry(Name, 'exported');
    end;

    procedure XMLExchangeImport()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageCode: Code[20];
    begin
        if ConfigXMLExchange.ImportPackageXMLFromClient() then begin
            PackageCode := ConfigXMLExchange.GetImportedPackageCode();
            ApplyPackage(PackageCode);
        end;
    end;

    local procedure ApplyPackage(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        NewName: Code[10];
    begin
        if not ConfigPackage.Get(PackageCode) then
            Error(PackageImportErr);

        NewName := GetNewColumnDefinitionName(PackageCode);
        if NewName = '' then
            Error(PackageImportErr);

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, false);
        LogImportExportTelemetry(NewName, 'imported');
    end;

    local procedure GetNewColumnDefinitionName(PackageCode: Code[20]): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        NewFinancialReport: Page "New Financial Report";
        ColumnDefinitionNameFromPackage: Code[10];
        NewName: Code[10];
    begin
        ColumnDefinitionNameFromPackage := GetColumnDefinitionNameFromImportedPackage(PackageCode);
        if ColumnDefinitionNameFromPackage = '' then
            exit('');
        if not ColumnLayoutName.Get(ColumnDefinitionNameFromPackage) then
            exit(ColumnDefinitionNameFromPackage);
        NewFinancialReport.Set('', '', ColumnDefinitionNameFromPackage);
        if NewFinancialReport.RunModal() = Action::OK then begin
            NewName := NewFinancialReport.GetColumnLayoutName();
            if NewName <> '' then
                FinancialReportMgt.RenameColumnLayoutInPackage(PackageCode, ColumnDefinitionNameFromPackage, NewName);
            exit(NewName);
        end;
    end;

    local procedure GetColumnDefinitionNameFromImportedPackage(PackageCode: Code[20]): Code[10]
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
    begin
        if not ConfigPackageField.Get(PackageCode, Database::"Column Layout Name", Rec.FieldNo(Name)) then
            exit('');

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Column Layout Name");
        ConfigPackageData.SetRange("Field ID", Rec.FieldNo(Name));
        if ConfigPackageData.FindFirst() then
            exit(CopyStr(ConfigPackageData.Value, 1, 10));
    end;

    local procedure AddColumnDefinitionToPackage(ColumnLayoutNameCode: Code[10]) PackageCode: Code[20]
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageManagement: Codeunit "Config. Package Management";
        PackageNameTxt: Label 'Column Definition - %1', Comment = '%1 - The name of the exported column definition';
        PackageCodeTok: Label 'COL.DEF.%1', Locked = true;
    begin
        PackageCode := CopyStr(StrSubstNo(PackageCodeTok, ColumnLayoutNameCode), 1, MaxStrLen(PackageCode));
        if ConfigPackage.Get(PackageCode) then
            ConfigPackage.Delete(true);

        ConfigPackageManagement.InsertPackage(ConfigPackage, PackageCode, StrSubstNo(PackageNameTxt, ColumnLayoutNameCode), true);

        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Column Layout Name");
        ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Column Layout Name", 0, Rec.FieldNo(Name), ColumnLayoutNameCode);
        ConfigPackageManagement.InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Column Layout");
        ConfigPackageManagement.InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Column Layout", 0, ColumnLayout.FieldNo("Column Layout Name"), ColumnLayoutNameCode);
        if ConfigPackageField.Get(PackageCode, Database::"Column Layout Name", Rec.FieldNo("Analysis View Name")) then
            ConfigPackageField.Delete();
    end;

    local procedure LogImportExportTelemetry(DefinitionName: Text; Action: Text)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        TelemetryDimensions.Add('ColumnDefinitionCode', DefinitionName);
        FeatureTelemetry.LogUsage('0000ONQ', 'Financial Report', StrSubstNo(TelemetryEventTxt, Action, DefinitionName), TelemetryDimensions);
    end;

}

