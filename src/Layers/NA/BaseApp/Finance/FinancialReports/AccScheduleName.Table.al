// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Environment;
using System.IO;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Stores account schedule name configurations defining row definitions for financial reports.
/// Master table linking account schedule lines to analysis views and default column layouts for structured financial reporting.
/// </summary>
/// <remarks>
/// Key relationships: Account Schedule Lines, Column Layout Names, Analysis Views for multi-dimensional financial analysis.
/// Supports export/import functionality for configuration package deployment and account schedule template management.
/// Extensible via standard table extension patterns for custom financial report categorization and analysis view integration.
/// </remarks>
table 84 "Acc. Schedule Name"
{
    Caption = 'Financial Report Row Definition';
    DataCaptionFields = Name, Description;
    LookupPageID = "Account Schedule Names";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the account schedule row definition used across financial reporting.
        /// </summary>
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            ToolTip = 'Specifies the unique name (code) of the financial report row definition. You can use up to 10 characters.';
        }
        /// <summary>
        /// Descriptive text explaining the purpose and content of the account schedule row definition.
        /// </summary>
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the financial report row definition. The description is not shown on the final report but is used to provide more context when using the definition.';
        }
#if not CLEANSCHEMA25
        /// <summary>
        /// Default column layout name for report formatting (obsolete - replaced by Financial Report table configuration).
        /// </summary>
        field(3; "Default Column Layout"; Code[10])
        {
            Caption = 'Default Column Layout';
            TableRelation = "Column Layout Name";
            ObsoleteReason = 'Use now the Column Group property in the table Financial Report';
            ObsoleteTag = '25.0';
            ObsoleteState = Removed;
        }
#endif
        /// <summary>
        /// Analysis view name providing multi-dimensional analysis capabilities for the account schedule.
        /// </summary>
        field(4; "Analysis View Name"; Code[10])
        {
            Caption = 'Analysis View Name';
            TableRelation = "Analysis View";
            ToolTip = 'Specifies the name of the analysis view you want the row definition to use. This field is optional.';

            trigger OnValidate()
            var
                AnalysisView: Record "Analysis View";
                xAnalysisView: Record "Analysis View";
                ConfirmManagement: Codeunit "Confirm Management";
                AskedUser: Boolean;
                ClearTotaling: Boolean;
                i: Integer;
            begin
                if xRec."Analysis View Name" <> "Analysis View Name" then begin
                    AnalysisViewGet(xAnalysisView, xRec."Analysis View Name");
                    AnalysisViewGet(AnalysisView, "Analysis View Name");

                    ClearTotaling := true;

                    for i := 1 to 4 do
                        if (GetDimCodeByNum(xAnalysisView, i) <> GetDimCodeByNum(AnalysisView, i)) and ClearTotaling then
                            if not DimTotalingLinesAreEmpty(i) then begin
                                if not AskedUser then begin
                                    ClearTotaling := ConfirmManagement.GetResponseOrDefault(ClearDimensionTotalingConfirmTxt, true);
                                    AskedUser := true;
                                end;

                                if ClearTotaling then
                                    ClearDimTotalingLines(i);
                            end;
                    if not ClearTotaling then
                        "Analysis View Name" := xRec."Analysis View Name";
                end;
            end;
        }
        /// <summary>
        /// Extended internal description for detailed documentation of the account schedule row definition purpose and usage.
        /// </summary>
#if not CLEAN28
#pragma warning disable AS0086
#endif
        field(5; "Internal Description"; Text[500])
#if not CLEAN28
#pragma warning restore AS0086
#endif
        {
            Caption = 'Internal Description';
            ToolTip = 'Specifies the internal description of row definition. The internal description is not shown on the final report but is used to provide more context when using the definition.';
        }
        field(6; Status; Code[10])
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            TableRelation = "Financial Report Status";
            ToolTip = 'Specifies the status code for the row definition. The status code helps you organize the lifecycle of your row definitions.';
        }
        field(7; "Status Blocked"; Boolean)
        {
            CalcFormula = exist("Financial Report Status" where("Code" = field(Status), "Blocked" = const(true)));
            Caption = 'Status Blocked';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the status code is a blocked status.';
        }
        field(10000; "Financial Period Description"; Text[80])
        {
            Caption = 'Financial Period Description';
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
    }

    trigger OnRename()
    var
        GLSetup: Record "General Ledger Setup";
        FinancialReportUserFilters: Record "Financial Report User Filters";
        GLSetupModified: Boolean;
    begin
        if GLSetup.Get() then begin
            if GLSetup."Fin. Rep. Bal. Sheet Row" = xRec.Name then begin
                GLSetup."Fin. Rep. Bal. Sheet Row" := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetup."Fin. Rep. Income Stmt. Row" = xRec.Name then begin
                GLSetup."Fin. Rep. Income Stmt. Row" := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetup."Fin. Rep. Cash Flow Stmt. Row" = xRec.Name then begin
                GLSetup."Fin. Rep. Cash Flow Stmt. Row" := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetup."Fin. Rep. Retained Earn. Row" = xRec.Name then begin
                GLSetup."Fin. Rep. Retained Earn. Row" := Rec.Name;
                GLSetupModified := true;
            end;
            if GLSetupModified then
                GLSetup.Modify();
        end;
        FinancialReportUserFilters.SetRange("Row Definition", xRec.Name);
        FinancialReportUserFilters.ModifyAll("Row Definition", Rec.Name);
    end;

    trigger OnDelete()
    begin
        AccSchedLine.SetRange("Schedule Name", Name);
        AccSchedLine.DeleteAll();
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        AccSchedPrefixTxt: Label 'ROW.DEF.', MaxLength = 10, Comment = 'Part of the name for the confguration package, stands for Row Definition';
        TwoPosTxt: Label '%1%2', Locked = true;
        PackageNameTxt: Label 'Row Definition - %1', MaxLength = 40, Comment = '%1 - Rows definition name';
        ClearDimensionTotalingConfirmTxt: Label 'Changing Analysis View will clear differing dimension totaling columns of Account Schedule Lines. \Do you want to continue?';
        PackageImportErr: Label 'The row definitions could not be imported.';
        TelemetryEventTxt: Label 'Financial Report Row Definition %1: %2', Comment = '%1 = event type, %2 = row definition', Locked = true;

    local procedure AnalysisViewGet(var AnalysisView: Record "Analysis View"; AnalysisViewName: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if not AnalysisView.Get(AnalysisViewName) then
            if "Analysis View Name" = '' then begin
                GLSetup.Get();
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    /// <summary>
    /// Checks whether dimension totaling lines are empty for the specified dimension number.
    /// Validates if any account schedule lines contain dimension totaling values for the given dimension.
    /// </summary>
    /// <param name="DimNumber">Dimension number (1-4) to check for empty totaling lines</param>
    /// <returns>True if all dimension totaling lines are empty, false if any contain values</returns>
    procedure DimTotalingLinesAreEmpty(DimNumber: Integer): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        AccSchedLine.Reset();
        AccSchedLine.SetRange("Schedule Name", Name);
        RecRef.GetTable(AccSchedLine);
        FieldRef := RecRef.Field(AccSchedLine.FieldNo("Dimension 1 Totaling") + DimNumber - 1);
        FieldRef.SetFilter('<>%1', '');
        RecRef := FieldRef.Record();
        exit(RecRef.IsEmpty());
    end;

    /// <summary>
    /// Clears dimension totaling values for all account schedule lines for the specified dimension number.
    /// Removes dimension totaling filters when analysis view dimensions are changed to maintain data consistency.
    /// </summary>
    /// <param name="DimNumber">Dimension number (1-4) to clear totaling values for</param>
    procedure ClearDimTotalingLines(DimNumber: Integer)
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
    begin
        AccSchedLine.Reset();
        AccSchedLine.SetRange("Schedule Name", Name);
        RecRef.GetTable(AccSchedLine);
        if RecRef.FindSet() then
            repeat
                FieldRef := RecRef.Field(AccSchedLine.FieldNo("Dimension 1 Totaling") + DimNumber - 1);
                FieldRef.Value := '';
                RecRef.Modify();
            until RecRef.Next() = 0;
    end;

    local procedure GetDimCodeByNum(AnalysisView: Record "Analysis View"; DimNumber: Integer) DimensionCode: Code[20]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(AnalysisView);
        FieldRef := RecRef.Field(AnalysisView.FieldNo("Dimension 1 Code") + DimNumber - 1);
        Evaluate(DimensionCode, Format(FieldRef.Value));
    end;

    /// <summary>
    /// Exports the account schedule definition to an XML configuration package for deployment and backup purposes.
    /// Creates configuration package with account schedule name, lines, and related setup for import/export functionality.
    /// </summary>
    procedure Export()
    var
        ConfigPackage: Record "Config. Package";
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageCode: Code[20];
    begin
        PackageCode := StrSubstNo(TwoPosTxt, AccSchedPrefixTxt, Name);
        if ConfigPackage.Get(PackageCode) then
            ConfigPackage.Delete(true);

        ConfigPackage.Code := PackageCode;
        ConfigPackage."Package Name" := StrSubstNo(PackageNameTxt, Name);
        ConfigPackage."Exclude Config. Tables" := true;
        ConfigPackage.Insert(true);
        AddRowDefinitionToConfigPackage(Name, ConfigPackage, PackageCode);
        Commit();
        ConfigXMLExchange.ExportPackage(ConfigPackage);
        LogImportExportTelemetry(Name, 'exported');
    end;

    /// <summary>
    /// Adds account schedule row definition tables to configuration package for export processing.
    /// Includes account schedule name, lines, and related analysis view configuration in the package.
    /// </summary>
    /// <param name="AccScheduleName">Account schedule name to include in the configuration package</param>
    /// <param name="ConfigPackage">Configuration package record to add tables to</param>
    /// <param name="PackageCode">Package code for configuration package management</param>
    procedure AddRowDefinitionToConfigPackage(AccScheduleName: Code[10]; var ConfigPackage: Record "Config. Package"; PackageCode: Code[20])
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AnalysisView: Record "Analysis View";
    begin
        AddConfigPackageTable(PackageCode, Database::"Acc. Schedule Name", FieldNo(Name), AccScheduleName);
        AddConfigPackageTable(
            PackageCode, Database::"Acc. Schedule Line", AccScheduleLine.FieldNo("Schedule Name"), AccScheduleName);
        if "Analysis View Name" <> '' then
            AddConfigPackageTable(
                PackageCode, Database::"Analysis View", AnalysisView.FieldNo(Code), "Analysis View Name");
    end;

    local procedure AddConfigPackageTable(PackageCode: Code[20]; TableID: Integer; FieldID: Integer; AccScheduleName: Code[10])
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable."Package Code" := PackageCode;
        ConfigPackageTable.Validate("Table ID", TableID);
        ConfigPackageTable.Insert(true);
        AddConfigPackageFilter(ConfigPackageTable, FieldID, AccScheduleName);
    end;

    local procedure AddConfigPackageFilter(ConfigPackageTable: Record "Config. Package Table"; FieldNumber: Integer; FieldFilter: Text[250])
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageFilter.Init();
        ConfigPackageFilter."Package Code" := ConfigPackageTable."Package Code";
        ConfigPackageFilter."Table ID" := ConfigPackageTable."Table ID";
        ConfigPackageFilter."Field ID" := FieldNumber;
        ConfigPackageFilter."Processing Rule No." := 0;
        ConfigPackageFilter."Field Filter" := FieldFilter;
        ConfigPackageFilter.Insert(true);
    end;

    /// <summary>
    /// Imports account schedule definition from XML configuration package file selected by user.
    /// Processes XML import and applies configuration package to create account schedule with lines and settings.
    /// </summary>
    procedure Import()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        PackageCode: Code[20];
    begin
        if ConfigXMLExchange.ImportPackageXMLFromClient() then begin
            PackageCode := ConfigXMLExchange.GetImportedPackageCode();
            Commit();
            ApplyPackage(PackageCode);
        end;
    end;

    /// <summary>
    /// Applies imported configuration package to create account schedule definition with validation and naming.
    /// Processes package data, validates account schedule name, and applies configuration to Business Central.
    /// </summary>
    /// <param name="PackageCode">Configuration package code to apply for account schedule creation</param>
    procedure ApplyPackage(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        NewName: Code[10];
    begin
        if not ConfigPackage.Get(PackageCode) then
            Error(PackageImportErr);

        NewName := GetPackageAccSchedName(PackageCode);
        if NewName = '' then
            Error(PackageImportErr);

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, false);
        LogImportExportTelemetry(NewName, 'imported');
    end;

    local procedure GetPackageAccSchedName(PackageCode: Code[20]) NewName: Code[10]
    var
        OldName: Code[10];
        AccScheduleExists: Boolean;
    begin
        NewName := GetAccountScheduleName(PackageCode, AccScheduleExists);
        if NewName = '' then
            exit('');

        if not AccScheduleExists then
            exit(NewName);

        OldName := NewName;
        if not GetNewAccScheduleName(NewName) then
            exit('');

        RenameAccountScheduleInPackage(PackageCode, OldName, NewName);
    end;

    local procedure GetNewAccScheduleName(var AccScheduleName: Code[10]): Boolean
    var
        NewAccountScheduleName: Page "New Account Schedule Name";
    begin
        NewAccountScheduleName.Set(AccScheduleName);
        if NewAccountScheduleName.RunModal() = Action::OK then begin
            AccScheduleName := NewAccountScheduleName.GetName();
            exit(true);
        end;
        exit(false)
    end;

    /// <summary>
    /// Renames account schedule references within configuration package data to avoid naming conflicts during import.
    /// Updates account schedule name and related line references in package data before applying configuration.
    /// </summary>
    /// <param name="PackageCode">Configuration package code containing the account schedule data</param>
    /// <param name="OldName">Original account schedule name to replace in package data</param>
    /// <param name="NewName">New account schedule name to use in package data</param>
    procedure RenameAccountScheduleInPackage(PackageCode: Code[20]; OldName: Code[10]; NewName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
        AccScheduleLine: Record "Acc. Schedule Line";
        ConfigPackageData: Record "Config. Package Data";
    begin
        if OldName = NewName then
            exit;

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange(Value, OldName);

        ConfigPackageData.SetRange("Table ID", Database::"Acc. Schedule Name");
        ConfigPackageData.SetRange("Field ID", AccScheduleName.FieldNo(Name));
        ConfigPackageData.ModifyAll(Value, NewName);

        ConfigPackageData.SetRange("Table ID", Database::"Acc. Schedule Line");
        ConfigPackageData.SetRange("Field ID", AccScheduleLine.FieldNo("Schedule Name"));
        ConfigPackageData.ModifyAll(Value, NewName);
    end;

    local procedure GetAccountScheduleName(PackageCode: Code[20]; var AccScheduleExists: Boolean) Name: Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
    begin
        AccScheduleExists := false;
        if not ConfigPackageField.Get(PackageCode, Database::"Acc. Schedule Name", AccScheduleName.FieldNo(Name)) then
            exit('');

        ConfigPackageData.SetLoadFields(Value);
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Acc. Schedule Name");
        ConfigPackageData.SetRange("Field ID", AccScheduleName.FieldNo(Name));
        if ConfigPackageData.FindFirst() then begin
            Name := CopyStr(ConfigPackageData.Value, 1, MaxStrLen(AccScheduleName.Name));
            AccScheduleExists := AccScheduleName.Get(Name);
        end;
    end;

    local procedure LogImportExportTelemetry(DefinitionName: Text; Action: Text)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        TelemetryDimensions.Add('RowDefinitionCode', DefinitionName);
        FeatureTelemetry.LogUsage('0000ONP', 'Financial Report', StrSubstNo(TelemetryEventTxt, Action, DefinitionName), TelemetryDimensions);
    end;
}

