// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Shared.Report;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Reporting;
using System;
using System.Environment.Configuration;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// This code unit supports the 'Report Layouts' page and provides implementations for adding/deleting/editing user and extension defined report layouts.
/// </summary>
codeunit 9660 "Report Layouts Impl."
{
    Access = Internal;
    Permissions = tabledata "Tenant Report Layout" = rimd,
                  tabledata "Tenant Report Layout Selection" = rimd,
                  tabledata "Tenant Report Layout Override" = rimd;

    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SelectedCompany: Text[30];
        EmptyGuid: Guid;
        ImportWordTxt: Label 'Choose Word layout file';
        ImportRdlcTxt: Label 'Choose RDLC layout file';
        ImportExcelTxt: Label 'Choose Excel layout file';
        ImportExternalTxt: Label 'Choose External layout file';
        DefaultLayoutDeleteTxt: Label 'You are about to delete the currently selected default layout "%1", for report "%2". Do you want to continue? A new default layout must be selected manually from the Report Layout Selection page.', Comment = '%1 = Layout Name, %2 = Report Name';
        DefaultLayoutSetTxt: Label '"%1" has been set as the default layout for Report "%2"', Comment = '%1 = Layout Name, %2 = Report Name';
        FileFilterWordTxt: Label 'Word Files (*.docx)|*.docx', Comment = '{Split=r''\|''}{Locked=s''1''}';
        ImportWordTemplateTxt: Label 'Choose Word template file';
        ImportWordHeaderFooterTxt: Label 'Choose header/footer Word file';
        FileFilterWordTemplateTxt: Label 'Word Templates (*.dotx)|*.dotx', Comment = '{Split=r''\|''}{Locked=s''1''}';
        FileFilterRdlcTxt: Label 'SQL Report Builder (*.rdl;*.rdlc)|*.rdl;*.rdlc', Comment = '{Split=r''\|''}{Locked=s''1''}';
        FileFilterExcelTxt: Label 'Excel Files (*.xlsx)|*.xlsx', Comment = '{Split=r''\|''}{Locked=s''1''}';
        FileFilterExternalTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
        EmptyLayoutNameTxt: Label 'A layout name must be specified.';
        CannotUpdateLayoutTxt: Label 'The Layout could not be updated for export. The exported file will contain the original layout.';
        LayoutAlreadyExistsErr: Label 'A layout named "%1" already exists.', Comment = '%1 = Layout Name';
        MixedScopeErr: Label 'The selected layouts have different scopes. Some apply to all companies and some only to the current company. Select layouts of a single scope and try again.';
        GlobalScopeConfirmQst: Label 'One or more of the selected layouts apply to all companies. Changing the status will affect all companies, not only the current one. Do you want to continue?';

    internal procedure SetSelectedCompany(NewCompanyName: Text)
    begin
        SelectedCompany := CopyStr(NewCompanyName, 1, MaxStrLen(SelectedCompany));
    end;

    /// <summary>
    /// Sets the status for a layout.
    /// User-defined layouts are updated in place in "Tenant Report Layout" (table 2000000232).
    /// Extension-installed layouts reside in the read-only App database; their status is set by
    /// writing an override record in "Tenant Report Layout Override" (table 2000000248) instead of
    /// copying the layout into the tenant table.
    /// </summary>
    /// <param name="ReportLayoutList">The layout record from the virtual table</param>
    /// <param name="NewStatus">The new status to set</param>
    /// <returns>True if the status was updated, false if the user-defined layout was not found</returns>
    internal procedure SetLayoutStatus(ReportLayoutList: Record "Report Layout List"; NewStatus: Enum "Report Layout Status"): Boolean
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        if not ReportLayoutList."User Defined" then begin
            // Extension-installed layout: override the status rather than copying the layout.
            // A layout that already has a global override is updated globally; otherwise the status
            // override is company-specific (see CP0529-338 Q1). Mixed-scope selections and the
            // global confirmation are handled by SetLayoutStatusBatch before this point.
            UpsertLayoutOverride(ReportLayoutList, LayoutStatusIsGlobalScope(ReportLayoutList), false, '', true, NewStatus, false, false);
            exit(true);
        end;

        if TenantReportLayout.Get(ReportLayoutList."Report ID", ReportLayoutList."Name", EmptyGuid) then begin
            TenantReportLayout."Layout Status" := NewStatus;
            TenantReportLayout.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Determines whether a status change to an extension-installed layout applies globally.
    /// A company-specific override for the current company takes precedence (company scope); otherwise
    /// an existing global override means the layout is global-scope. A layout with no override defaults
    /// to company scope.
    /// </summary>
    local procedure LayoutStatusIsGlobalScope(ReportLayoutList: Record "Report Layout List"): Boolean
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
    begin
        if TenantReportLayoutOverride.Get(ReportLayoutList."Report ID", ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", SelectedCompany) then
            exit(false);
        exit(TenantReportLayoutOverride.Get(ReportLayoutList."Report ID", ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", ''));
    end;

    /// <summary>
    /// Creates or updates a "Tenant Report Layout Override" record for an extension-installed layout.
    /// Only the fields flagged by the corresponding Apply* parameter are written, together with their
    /// "Override *" flag; unset fields pass through from the layout metadata unchanged. "IsObsolete" is
    /// one-way: it can only ever be set to true and never clears a layout that is obsolete in metadata.
    /// </summary>
    /// <param name="ReportLayoutList">The (extension-installed) layout row from the virtual table</param>
    /// <param name="MakeGlobal">True writes a global override (empty Company Name); false writes one scoped to the selected company</param>
    local procedure UpsertLayoutOverride(ReportLayoutList: Record "Report Layout List"; MakeGlobal: Boolean; ApplyDescription: Boolean; NewDescription: Text[250]; ApplyStatus: Boolean; NewStatus: Enum "Report Layout Status"; ApplyObsolete: Boolean; NewIsObsolete: Boolean)
    var
        TenantReportLayoutOverride: Record "Tenant Report Layout Override";
        OverrideCompanyName: Text[30];
        OverrideExists: Boolean;
    begin
        if MakeGlobal then
            OverrideCompanyName := ''
        else
            OverrideCompanyName := SelectedCompany;

        OverrideExists := TenantReportLayoutOverride.Get(ReportLayoutList."Report ID", ReportLayoutList."Name", ReportLayoutList."Runtime Package ID", OverrideCompanyName);
        if not OverrideExists then begin
            TenantReportLayoutOverride.Init();
            TenantReportLayoutOverride."Report ID" := ReportLayoutList."Report ID";
            TenantReportLayoutOverride."Name" := ReportLayoutList."Name";
            TenantReportLayoutOverride."Runtime Package ID" := ReportLayoutList."Runtime Package ID";
            TenantReportLayoutOverride."Company Name" := OverrideCompanyName;
        end;

        if ApplyDescription then begin
            TenantReportLayoutOverride.Description := NewDescription;
            TenantReportLayoutOverride."Override Description" := true;
        end;

        if ApplyStatus then begin
            TenantReportLayoutOverride."Layout Status" := NewStatus;
            TenantReportLayoutOverride."Override Layout Status" := true;
        end;

        // One-way: only ever mark obsolete; never write false over a metadata-obsolete layout.
        if ApplyObsolete and NewIsObsolete then begin
            TenantReportLayoutOverride.IsObsolete := true;
            TenantReportLayoutOverride."Override IsObsolete" := true;
        end;

        if OverrideExists then
            TenantReportLayoutOverride.Modify(true)
        else
            TenantReportLayoutOverride.Insert(true);
    end;

    /// <summary>
    /// Sets the status for multiple selected layouts.
    /// Use this from page actions when user selects multiple layouts.
    /// </summary>
    /// <param name="ReportLayoutList">Record set with selected layouts (filtered/marked)</param>
    /// <param name="NewStatus">The new status to set</param>
    /// <returns>Number of layouts updated (excludes extension-defined layouts)</returns>
    internal procedure SetLayoutStatusBatch(var ReportLayoutList: Record "Report Layout List"; NewStatus: Enum "Report Layout Status"): Integer
    var
        CustomDimensions: Dictionary of [Text, Text];
        UpdateCount: Integer;
        HasGlobalScope: Boolean;
        HasCompanyScope: Boolean;
    begin
        if not ReportLayoutList.FindSet() then
            exit(0);

        // First pass: classify the scope of the extension-installed layouts in the selection.
        // User-defined layouts update in place and are not part of the scope decision.
        repeat
            if not ReportLayoutList."User Defined" then
                if LayoutStatusIsGlobalScope(ReportLayoutList) then
                    HasGlobalScope := true
                else
                    HasCompanyScope := true;
        until ReportLayoutList.Next() = 0;

        // Keep each run to a single scope so the effect is unambiguous.
        if HasGlobalScope and HasCompanyScope then
            Error(MixedScopeErr);

        // A global-scope change affects every company, so make the user confirm it explicitly.
        if HasGlobalScope then
            if not Confirm(GlobalScopeConfirmQst, false) then
                exit(0);

        // Second pass: apply the status change.
        ReportLayoutList.FindSet();
        repeat
            if SetLayoutStatus(ReportLayoutList, NewStatus) then
                UpdateCount += 1;
        until ReportLayoutList.Next() = 0;

        if UpdateCount > 0 then begin
            CustomDimensions.Add('NewStatus', Format(NewStatus));
            CustomDimensions.Add('UpdateCount', Format(UpdateCount));
            Log('0000RTN', 'Report layout status changed by user', CustomDimensions);
        end;
        exit(UpdateCount);
    end;

    internal procedure RunCustomReport(SelectedReportLayoutList: Record "Report Layout List")
    var
        DesignTimeReportSelection: codeunit "Design-time Report Selection";
    begin
        if SelectedReportLayoutList."Report ID" = 0 then
            exit;

        DesignTimeReportSelection.SetSelectedLayout(SelectedReportLayoutList.Name, SelectedReportLayoutList."Application ID");
        Commit(); // Since we run the report modally, we cannot have any active transactions.
        if TryRunCustomReport(SelectedReportLayoutList) then
            DesignTimeReportSelection.ClearLayoutSelection()
        else begin
            DesignTimeReportSelection.ClearLayoutSelection();
            Error(GetLastErrorText());
        end;
    end;

    [TryFunction]
    local procedure TryRunCustomReport(SelectedReportLayoutList: Record "Report Layout List")
    begin
        Report.RunModal(SelectedReportLayoutList."Report ID");
    end;

    local procedure AddLayoutSelection(SelectedReportLayoutList: Record "Report Layout List"; UserId: Guid): Boolean
    begin
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."App ID" := SelectedReportLayoutList."Application ID";
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."Layout Name" := SelectedReportLayoutList."Name";
        TenantReportLayoutSelection."Report ID" := SelectedReportLayoutList."Report ID";
        TenantReportLayoutSelection."User ID" := UserId;

        if not TenantReportLayoutSelection.Insert(true) then
            TenantReportLayoutSelection.Modify(true);
    end;

    internal procedure CreateNewReportLayout(SelectedReportLayoutList: Record "Report Layout List"; var ReturnReportID: Integer; var ReturnLayoutName: Text)
    begin
        CreateNewReportLayout(SelectedReportLayoutList, Enum::"Report Layout Subtype"::Default, ReturnReportID, ReturnLayoutName);
    end;

    internal procedure CreateNewReportLayout(SelectedReportLayoutList: Record "Report Layout List"; ImpliedSubtype: Enum "Report Layout Subtype"; var ReturnReportID: Integer; var ReturnLayoutName: Text)
    var
        ReportLayoutNewDialog: Page "Report Layout New Dialog";
        EffectiveSubtype: Enum "Report Layout Subtype";
    begin
        ReportLayoutNewDialog.SetReportID(SelectedReportLayoutList."Report ID");
        if ImpliedSubtype <> Enum::"Report Layout Subtype"::Default then
            ReportLayoutNewDialog.SetImpliedSubtype(ImpliedSubtype);
        if ReportLayoutNewDialog.RunModal() = Action::OK then begin
            EffectiveSubtype := ReportLayoutNewDialog.SelectedLayoutSubtype();
            case true of
                ReportLayoutNewDialog.SelectedAddCustomLayout():
                    InsertNewLayout(
                    ReportLayoutNewDialog.SelectedReportID(), ReportLayoutNewDialog.SelectedLayoutName(),
                    ReportLayoutNewDialog.SelectedLayoutDescription(), SelectedReportLayoutList."Layout Format"::Custom,
                    ReportLayoutNewDialog.SelectedLayoutIsGlobal(),
                    ReportLayoutNewDialog.SelectedCreateEmptyLayout(),
                    ReportLayoutNewDialog.SelectedExcelMultipleDataSheets(),
                    EffectiveSubtype,
                    ReturnReportID, ReturnLayoutName);

                ReportLayoutNewDialog.SelectedAddWordLayout():
                    InsertNewLayout(
                    ReportLayoutNewDialog.SelectedReportID(), ReportLayoutNewDialog.SelectedLayoutName(),
                    ReportLayoutNewDialog.SelectedLayoutDescription(), SelectedReportLayoutList."Layout Format"::Word,
                    ReportLayoutNewDialog.SelectedLayoutIsGlobal(),
                    ReportLayoutNewDialog.SelectedCreateEmptyLayout(),
                    ReportLayoutNewDialog.SelectedExcelMultipleDataSheets(),
                    EffectiveSubtype,
                    ReturnReportID, ReturnLayoutName);

                ReportLayoutNewDialog.SelectedAddRDLCLayout():
                    InsertNewLayout(
                    ReportLayoutNewDialog.SelectedReportID(), ReportLayoutNewDialog.SelectedLayoutName(),
                    ReportLayoutNewDialog.SelectedLayoutDescription(), SelectedReportLayoutList."Layout Format"::RDLC,
                    ReportLayoutNewDialog.SelectedLayoutIsGlobal(),
                    ReportLayoutNewDialog.SelectedCreateEmptyLayout(),
                    ReportLayoutNewDialog.SelectedExcelMultipleDataSheets(),
                    Enum::"Report Layout Subtype"::Default,
                    ReturnReportID, ReturnLayoutName);

                ReportLayoutNewDialog.SelectedAddExcelLayout():
                    InsertNewLayout(
                    ReportLayoutNewDialog.SelectedReportID(), ReportLayoutNewDialog.SelectedLayoutName(),
                    ReportLayoutNewDialog.SelectedLayoutDescription(), SelectedReportLayoutList."Layout Format"::Excel,
                    ReportLayoutNewDialog.SelectedLayoutIsGlobal(),
                    ReportLayoutNewDialog.SelectedCreateEmptyLayout(),
                    ReportLayoutNewDialog.SelectedExcelMultipleDataSheets(),
                    Enum::"Report Layout Subtype"::Default,
                    ReturnReportID, ReturnLayoutName);
            end;
        end;
    end;

    internal procedure SetDefaultReportLayoutSelection(SelectedReportLayoutList: Record "Report Layout List"; ShowMessage: Boolean)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Add to TenantReportLayoutSelection table with an Empty Guid.
        AddLayoutSelection(SelectedReportLayoutList, EmptyGuid);

        // Add to the report layout selection table
        if ReportLayoutSelection.get(SelectedReportLayoutList."Report ID", SelectedCompany) then begin
            ReportLayoutSelection.Type := GetReportLayoutSelectionCorrespondingEnum(SelectedReportLayoutList);
            ReportLayoutSelection.Modify(true);
        end else begin
            ReportLayoutSelection."Report ID" := SelectedReportLayoutList."Report ID";
            ReportLayoutSelection."Company Name" := SelectedCompany;
            ReportLayoutSelection."Custom Report Layout Code" := '';
            ReportLayoutSelection.Type := GetReportLayoutSelectionCorrespondingEnum(SelectedReportLayoutList);
            ReportLayoutSelection.Insert(true);
        end;

        InitReportLayoutListDimensions(SelectedReportLayoutList, CustomDimensions);
        AddReportLayoutDimensionsAction('SetDefault', CustomDimensions);
        Log('0000N0D', 'Report layout default changed by user', CustomDimensions);

        if ShowMessage then
            Message(DefaultLayoutSetTxt, SelectedReportLayoutList."Caption", SelectedReportLayoutList."Report Name");
    end;

    internal procedure GetDefaultReportLayoutSelection(ReportId: Integer; var DefaultReportLayoutList: Record "Report Layout List"): Boolean
    var
        ReportMetadata: Record "Report Metadata";
    begin
        TenantReportLayoutSelection.Init();
        DefaultReportLayoutList.Init();

        if TenantReportLayoutSelection.Get(ReportId, SelectedCompany, EmptyGuid) then begin
            // Filter Default Report Layout List by the layout name and application id and report id
            DefaultReportLayoutList.SetRange("Name", TenantReportLayoutSelection."Layout Name");
            DefaultReportLayoutList.SetRange("Application ID", TenantReportLayoutSelection."App ID");
            DefaultReportLayoutList.SetRange("Report ID", ReportId);

            // Retrive the record based on filters
            if DefaultReportLayoutList.FindFirst() then
                exit(true);
        end else
            if ReportMetadata.Get(ReportId) then begin
                DefaultReportLayoutList.SetRange("Name", ReportMetadata."DefaultLayoutName");
                DefaultReportLayoutList.SetFilter("Application ID", '<>%1', EmptyGuid);
                DefaultReportLayoutList.SetRange("Report ID", ReportId);

                if DefaultReportLayoutList.FindFirst() then
                    exit(true);
            end;

        exit(false);
    end;

    internal procedure UpdateDefaultLayoutSelectionName(SelectedReportLayoutList: Record "Report Layout List"; NewLayoutName: Text[250]): Boolean
    begin
        if TenantReportLayoutSelection.Get(SelectedReportLayoutList."Report ID", SelectedCompany, EmptyGuid) then
            if TenantReportLayoutSelection."Layout Name" = SelectedReportLayoutList."Name" then begin
                TenantReportLayoutSelection."Layout Name" := NewLayoutName;
                TenantReportLayoutSelection.Modify(true);
            end;
    end;

    internal procedure ConfirmDeleteDefaultLayoutSelection(SelectedReportLayoutList: Record "Report Layout List"; TenantReportLayoutSelectionParm: Record "Tenant Report Layout Selection"): Boolean
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        if Dialog.Confirm(StrSubstNo(DefaultLayoutDeleteTxt, SelectedReportLayoutList.Caption, SelectedReportLayoutList."Report Name"), false) then begin

            // Clear the selection from the Tenant Report Layout Selection table.
            if (TenantReportLayoutSelectionParm."Layout Name" = SelectedReportLayoutList."Name") then
                TenantReportLayoutSelectionParm.Delete(true);

            // Clear the selection from Report Layout Selection table and let platform set the new default layout for this report.
            if ReportLayoutSelection.get(SelectedReportLayoutList."Report ID", SelectedCompany) then
                ReportLayoutSelection.Delete(true);
            exit(true);
        end;
    end;

    local procedure GetReportLayoutSelectionCorrespondingEnum(SelectedReportLayoutList: Record "Report Layout List"): Integer
    begin
        case SelectedReportLayoutList."Layout Format" of

            SelectedReportLayoutList."Layout Format"::RDLC:
                exit(0);
            SelectedReportLayoutList."Layout Format"::Word:
                exit(1);
            SelectedReportLayoutList."Layout Format"::Excel:
                exit(3);
            SelectedReportLayoutList."Layout Format"::Custom:
                exit(4);
        end
    end;

    internal procedure InsertNewLayout(ReportID: Integer; LayoutName: Text[250]; LayoutDescription: Text[250]; LayoutFormat: Option; LayoutIsGlobal: Boolean; CreateEmptyLayout: Boolean; ExcelSheetConfiguration: Enum "Excel Sheet Configuration"; var ReturnReportID: Integer; var ReturnLayoutName: Text)
    begin
        InsertNewLayout(ReportID, LayoutName, LayoutDescription, LayoutFormat, LayoutIsGlobal, CreateEmptyLayout, ExcelSheetConfiguration, Enum::"Report Layout Subtype"::Default, ReturnReportID, ReturnLayoutName);
    end;

    internal procedure InsertNewLayout(ReportID: Integer; LayoutName: Text[250]; LayoutDescription: Text[250]; LayoutFormat: Option; LayoutIsGlobal: Boolean; CreateEmptyLayout: Boolean; ExcelSheetConfiguration: Enum "Excel Sheet Configuration"; LayoutSubtype: Enum "Report Layout Subtype"; var ReturnReportID: Integer; var ReturnLayoutName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        FileManagement: Codeunit "File Management";
        DocumentReportManagement: Codeunit "Document Report Mgt.";
        TempBlob: Codeunit "Temp Blob";
        FileFilterTxt: Text;
        DialogCaption: Text;
        NVInStream: InStream;
        EmptyLayoutStream: OutStream;
        EmptyLayoutCreated: Boolean;
        UploadResult: Boolean;
        UploadFileName: Text;
        ErrorMessage: Text;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if ReportID = 0 then
            exit;

        if LayoutName = '' then begin
            Message(EmptyLayoutNameTxt);
            exit;
        end;

        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := ReportID;
        TenantReportLayout."Name" := LayoutName;

        if LayoutIsGlobal then
            TenantReportLayout."Company Name" := ''
        else
            TenantReportLayout."Company Name" := SelectedCompany;

        TenantReportLayout."Layout Format" := LayoutFormat;
        TenantReportLayout."Description" := LayoutDescription;
        TenantReportLayout."Layout Subtype" := LayoutSubtype;
        TenantReportLayout.ExcelLayoutMultipleDataSheets := ExcelSheetConfiguration;
        TenantReportLayout."Layout Status" := Enum::"Report Layout Status"::Draft;

        if CreateEmptyLayout then begin
            EmptyLayoutCreated := false;
            // RDLC documents are created with UTF8 encoding.
            if TenantReportLayout."Layout Format" = TenantReportLayout."Layout Format"::RDLC then begin
                EmptyLayoutStream := TempBlob.CreateOutStream(TextEncoding::UTF8);
                NVInStream := TempBlob.CreateInStream(TextEncoding::UTF8);
            end
            else begin
                EmptyLayoutStream := TempBlob.CreateOutStream();
                NVInStream := TempBlob.CreateInStream();
            end;
            case TenantReportLayout."Layout Format" of
                TenantReportLayout."Layout Format"::Word:
                    begin
                        DocumentReportManagement.NewWordLayout(ReportID, EmptyLayoutStream);
                        EmptyLayoutCreated := true;
                        UploadFileName := 'EmptyLayout.docx';
                    end;
                TenantReportLayout."Layout Format"::RDLC:
                    begin
                        EmptyLayoutCreated := false;
                        DocumentReportManagement.NewRDLCLayout(ReportID, EmptyLayoutStream);
                        EmptyLayoutCreated := true;
                        UploadFileName := 'EmptyLayout.rdlc';
                    end;
                TenantReportLayout."Layout Format"::Excel:
                    begin
                        EmptyLayoutCreated := false;
                        DocumentReportManagement.NewExcelLayout(ReportID, ExcelSheetConfiguration, EmptyLayoutStream);
                        EmptyLayoutCreated := true;
                        UploadFileName := 'EmptyLayout.xlsx';
                    end;
            end;

        end;

        if (not EmptyLayoutCreated) then begin
            case TenantReportLayout."Layout Format" of
                TenantReportLayout."Layout Format"::Word:
                    case LayoutSubtype of
                        Enum::"Report Layout Subtype"::Theme:
                            begin
                                DialogCaption := ImportWordTemplateTxt;
                                FileFilterTxt := FileFilterWordTemplateTxt;
                            end;
                        Enum::"Report Layout Subtype"::HeaderFooter:
                            begin
                                DialogCaption := ImportWordHeaderFooterTxt;
                                FileFilterTxt := FileFilterWordTxt;
                            end;
                        else begin
                            DialogCaption := ImportWordTxt;
                            FileFilterTxt := FileFilterWordTxt;
                        end;
                    end;
                TenantReportLayout."Layout Format"::RDLC:
                    begin
                        DialogCaption := ImportRdlcTxt;
                        FileFilterTxt := FileFilterRdlcTxt;
                    end;
                TenantReportLayout."Layout Format"::Excel:
                    begin
                        DialogCaption := ImportExcelTxt;
                        FileFilterTxt := FileFilterExcelTxt;
                    end;
                TenantReportLayout."Layout Format"::Custom:
                    begin
                        DialogCaption := ImportExternalTxt;
                        FileFilterTxt := FileFilterExternalTxt;
                    end;
            end;

            UploadFileName := TenantReportLayout."Name";
            OnBeforeUpload(UploadResult, UploadFileName, NVInStream);

            if (not UploadResult) then begin
                ClearLastError();
                UploadResult := UploadIntoStream(DialogCaption, '', FileFilterTxt, UploadFileName, NVInStream);
            end;

            if not UploadResult then begin
                ErrorMessage := GetLastErrorText();
                //When upload is cancelled by user, don't emit an error.
                if ErrorMessage <> '' then
                    Error(ErrorMessage);
                exit;
            end;

            // Custom layouts files are treated as unknown streams and don't need validation.
            if TenantReportLayout."Layout Format" <> TenantReportLayout."Layout Format"::Custom then
                FileManagement.ValidateFileExtension(UploadFileName, FileFilterTxt);
        end;

        // If the current layout is being replaced using the ReplaceLayout action
        if TenantReportLayout.Get(TenantReportLayout."Report ID", TenantReportLayout."Name", TenantReportLayout."App ID") then
            TenantReportLayout.Delete(true);

        TenantReportLayout."Layout".ImportStream(NVInStream, TenantReportLayout."Description");
        TenantReportLayout."MIME Type" := CreateLayoutMime(UploadFileName);
        TenantReportLayout.Insert(true);

        InitReportLayoutDimensions(TenantReportLayout, CustomDimensions);
        AddReportLayoutDimensionsDescription(LayoutDescription, CustomDimensions);
        AddReportLayoutDimensionsFormat(LayoutFormat, CustomDimensions);
        AddReportLayoutDimensionsAction('New', CustomDimensions);
        AddReportLayoutDimensionsExcelConfiguration(ExcelSheetConfiguration, CustomDimensions);

        Log('0000N0E', 'Report layout added by user', CustomDimensions);

        ReturnReportID := TenantReportLayout."Report ID";
        ReturnLayoutName := TenantReportLayout."Name";
    end;

    internal procedure DeleteReportLayout(TenantReportLayout: Record "Tenant Report Layout")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        TenantReportLayout.Delete(true);

        InitReportLayoutDimensions(TenantReportLayout, CustomDimensions);
        AddReportLayoutDimensionsAction('Delete', CustomDimensions);
        Log('0000N0F', 'Report layout deleted by user', CustomDimensions);
    end;

    internal procedure ReplaceLayout(ReportID: Integer; LayoutName: Text[250]; LayoutDescription: Text[250]; LayoutFormat: Option; var ReturnReportID: Integer; var ReturnLayoutName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        TenantReportLayout."Report ID" := ReportID;
        TenantReportLayout."Name" := LayoutName;

        if TenantReportLayout.Get(ReportID, LayoutName, TenantReportLayout."App ID") then begin
            InsertNewLayout(ReportID, LayoutName, LayoutDescription, LayoutFormat, TenantReportLayout."Company Name" = '', false, TenantReportLayout.ExcelLayoutMultipleDataSheets, TenantReportLayout."Layout Subtype", ReturnReportID, ReturnLayoutName);

            InitReportLayoutDimensions(TenantReportLayout, CustomDimensions);
            AddReportLayoutDimensionsDescription(LayoutDescription, CustomDimensions);
            AddReportLayoutDimensionsFormat(LayoutFormat, CustomDimensions);
            AddReportLayoutDimensionsAction('Replace', CustomDimensions);
            Log('0000N0G', 'Report layout replaced by user', CustomDimensions);
        end;
    end;

    internal procedure ValidateLayout(SelectedReportLayoutList: Record "Report Layout List")
    var
        RdlcReportManager: DotNet RdlcReportManager;
        WordReportManager: DotNet WordReportManager;
        ExcelReportManager: DotNet ExcelReportManager;
        IsValid: Boolean;
        ErrorMessage: Text;
        CompositeWarnings: Text;
        ValidLayoutLbl: Label 'The report layout is valid.';
        ValidLayoutWithWarningsMsg: Label 'The report layout is valid.\%1', Comment = '%1 = composite part warnings';
        LayoutFormatNotSupportedLbl: Label 'Layout validation is not supported for this layout format.';
    begin
        case SelectedReportLayoutList."Layout Format" of
            SelectedReportLayoutList."Layout Format"::RDLC:
                IsValid := RdlcReportManager.ValidateReportLayout(SelectedReportLayoutList."Report ID", SelectedReportLayoutList.SystemId, ErrorMessage);
            SelectedReportLayoutList."Layout Format"::Word:
                IsValid := WordReportManager.ValidateReportLayout(SelectedReportLayoutList."Report ID", SelectedReportLayoutList.SystemId, ErrorMessage);
            SelectedReportLayoutList."Layout Format"::Excel:
                IsValid := ExcelReportManager.ValidateReportLayout(SelectedReportLayoutList."Report ID", SelectedReportLayoutList.SystemId, ErrorMessage);
            else begin
                IsValid := false;
                ErrorMessage := LayoutFormatNotSupportedLbl;
            end;
        end;

        if IsValid then begin
            CompositeWarnings := ValidateCompositePartReferences(SelectedReportLayoutList);
            if CompositeWarnings <> '' then
                Message(ValidLayoutWithWarningsMsg, CompositeWarnings)
            else
                Message(ValidLayoutLbl);
        end else
            Error(ErrorMessage);
    end;

    local procedure ValidateCompositePartReferences(SelectedReportLayoutList: Record "Report Layout List"): Text
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        Warnings: TextBuilder;
        PartNotFoundTxt: Label 'Header/Footer part "%1" was not found in Report Layout List.', Comment = '%1 = composite part name';
        ThemeNotFoundTxt: Label 'Theme part "%1" was not found in Report Layout List.', Comment = '%1 = composite part name';
        PartObsoleteTxt: Label 'Header/Footer part "%1" is marked as obsolete.', Comment = '%1 = composite part name';
        ThemeObsoleteTxt: Label 'Theme part "%1" is marked as obsolete.', Comment = '%1 = composite part name';
    begin
        TenantReportLayoutCfg.SetRange("Report ID", SelectedReportLayoutList."Report ID");
        if not TenantReportLayoutCfg.FindSet() then begin
            TenantReportLayoutCfg.SetRange("Report ID", 0);
            if not TenantReportLayoutCfg.FindSet() then
                exit('');
        end;

        repeat
            if TenantReportLayoutCfg."Header Part Name" <> '' then
                ValidatePartReference(
                    TenantReportLayoutCfg."Header Part Name",
                    Enum::"Report Layout Subtype"::HeaderFooter,
                    PartNotFoundTxt, PartObsoleteTxt, Warnings);
            if TenantReportLayoutCfg."Theme Part Name" <> '' then
                ValidatePartReference(
                    TenantReportLayoutCfg."Theme Part Name",
                    Enum::"Report Layout Subtype"::Theme,
                    ThemeNotFoundTxt, ThemeObsoleteTxt, Warnings);
        until TenantReportLayoutCfg.Next() = 0;

        exit(Warnings.ToText());
    end;

    local procedure ValidatePartReference(CompositeName: Text; ExpectedSubtype: Enum "Report Layout Subtype"; NotFoundFormat: Text; ObsoleteFormat: Text; var Warnings: TextBuilder)
    var
        ReportLayoutList: Record "Report Layout List";
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        AppId: Guid;
        LayoutName: Text;
    begin
        LayoutName := LookupHelper.DecodeLayoutName(CompositeName);
        AppId := LookupHelper.DecodeAppId(CompositeName);
        ReportLayoutList.SetRange("Name", LayoutName);
        ReportLayoutList.SetRange("Layout Subtype", ExpectedSubtype);
        // The composite reference identifies the part by app as well as name; filter on the App ID too so a
        // same-named part of the same subtype in a different app is not matched by mistake.
        if not IsNullGuid(AppId) then
            ReportLayoutList.SetRange("Application ID", AppId);
        if not ReportLayoutList.FindFirst() then begin
            if Warnings.Length > 0 then
                Warnings.Append('\');
            Warnings.Append(StrSubstNo(NotFoundFormat, LayoutName));
            exit;
        end;

        if ReportLayoutList.IsObsolete then begin
            if Warnings.Length > 0 then
                Warnings.Append('\');
            Warnings.Append(StrSubstNo(ObsoleteFormat, LayoutName));
        end;
    end;

    local procedure CreateLayoutMime(FileNameWithExtension: Text) MimeType: Text[255]
    var
        FileManagement: Codeunit "File Management";
        FileExtension: Text;
    begin
        FileExtension := FileManagement.GetExtension(FileNameWithExtension);
        MimeType := 'reportlayout/' + FileExtension;
    end;

    internal procedure EditReportLayout(SelectedReportLayoutList: Record "Report Layout List"; var NewEditedLayoutName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TempBlob: Codeunit "Temp Blob";
        ReportLayoutEditDialog: Page "Report Layout Edit Dialog";
        NewDescription: Text[250];
        NewLayoutName: Text[250];
        CompanyName: Text[30];
        CreateCopy: Boolean;
        NewLayoutInStream: InStream;
        SourceLayoutOutStream: OutStream;
        AllCompaniesTxt: Label '';
        AvailableInAllCompanies: Boolean;
        NewIsObsolete: Boolean;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if SelectedReportLayoutList."User Defined" then begin
            if TenantReportLayout.Get(SelectedReportLayoutList."Report ID", SelectedReportLayoutList.Name, EmptyGuid) then
                CompanyName := TenantReportLayout."Company Name";
        end else
            CompanyName := SelectedCompany;

        ReportLayoutEditDialog.SetupDialog(SelectedReportLayoutList, SelectedCompany);
        if ReportLayoutEditDialog.RunModal() = Action::OK then begin

            NewDescription := ReportLayoutEditDialog.SelectedLayoutDescription();
            NewLayoutName := ReportLayoutEditDialog.SelectedLayoutName();
            CreateCopy := ReportLayoutEditDialog.CopyOperationEnabled();
            AvailableInAllCompanies := ReportLayoutEditDialog.SelectedAvailableInAllCompanies();
            NewIsObsolete := ReportLayoutEditDialog.SelectedIsObsolete();

            // Extension-installed layout, edited in place (not copied): write an override for the
            // mutable properties (Description, IsObsolete) instead of copying the layout. The layout
            // name/identity cannot change here, so NewLayoutName is not used.
            if (not SelectedReportLayoutList."User Defined") and (not CreateCopy) then begin
                UpsertLayoutOverride(SelectedReportLayoutList, AvailableInAllCompanies, true, NewDescription, false, Enum::"Report Layout Status"::Draft, true, NewIsObsolete);
                NewEditedLayoutName := SelectedReportLayoutList.Name;

                CustomDimensions.Add('ReportId', Format(SelectedReportLayoutList."Report ID"));
                CustomDimensions.Add('LayoutName', SelectedReportLayoutList.Name);
                CustomDimensions.Add('NewLayoutDescription', NewDescription);
                AddReportLayoutDimensionsAction('EditOverride', CustomDimensions);
                Log('0000N0H', 'Report layout properties overridden by user', CustomDimensions);
                exit;
            end;

            // Check if a layout having NewLayoutName already exists
            if TenantReportLayout.Get(SelectedReportLayoutList."Report ID", NewLayoutName, EmptyGuid) then
                if CreateCopy or (SelectedReportLayoutList.Name <> NewLayoutName) then
                    Error(LayoutAlreadyExistsErr, NewLayoutName);

            // Check if the layout should be made available for all companies
            if AvailableInAllCompanies then
                CompanyName := AllCompaniesTxt;

            if CreateCopy then begin
                // If create-copy is used to create a layout bound to the current company
                if SelectedReportLayoutList."User Defined" and (not AvailableInAllCompanies) and (CompanyName = '') then
                    CompanyName := SelectedCompany;

                TenantReportLayout.Init();
                TenantReportLayout.Name := NewLayoutName;
                TenantReportLayout.Description := NewDescription;
                TenantReportLayout."Report ID" := SelectedReportLayoutList."Report ID";
                TenantReportLayout."Company Name" := CompanyName;

                // Copy media stream
                SourceLayoutOutStream := TempBlob.CreateOutStream();
                SelectedReportLayoutList."Layout".ExportStream(SourceLayoutOutStream);
                NewLayoutInStream := TempBlob.CreateInStream();
                TenantReportLayout."Layout".ImportStream(NewLayoutInStream, NewDescription);

                TenantReportLayout."Layout Format" := SelectedReportLayoutList."Layout Format";
                TenantReportLayout."MIME Type" := SelectedReportLayoutList."MIME Type";
                TenantReportLayout.IsObsolete := SelectedReportLayoutList.IsObsolete;
                TenantReportLayout.ExcelLayoutMultipleDataSheets := SelectedReportLayoutList.ExcelLayoutMultipleDataSheets;
                TenantReportLayout."Layout Status" := Enum::"Report Layout Status"::Draft;
                TenantReportLayout.Insert(true);
            end else begin
                TenantReportLayout.Get(SelectedReportLayoutList."Report ID", SelectedReportLayoutList."Name", EmptyGuid);
                TenantReportLayout."Company Name" := CompanyName;
                TenantReportLayout.Rename(SelectedReportLayoutList."Report ID", NewLayoutName, EmptyGuid);
                TenantReportLayout.Description := NewDescription;
                TenantReportLayout.IsObsolete := NewIsObsolete;

                TenantReportLayout.Modify(true);
            end;
            NewEditedLayoutName := NewLayoutName;

            // If the layout name was updated, we check if this layout is the default layout
            // and update its reference in the tenant report layout selection table.
            if not CreateCopy then
                if (SelectedReportLayoutList.Name <> NewLayoutName) then
                    UpdateDefaultLayoutSelectionName(SelectedReportLayoutList, NewLayoutName);

            CustomDimensions.Add('ReportId', Format(TenantReportLayout."Report ID"));
            CustomDimensions.Add('OldLayoutName', TenantReportLayout.Name);
            CustomDimensions.Add('OldLayoutDescription', TenantReportLayout.Description);
            CustomDimensions.Add('NewLayoutName', NewLayoutName);
            CustomDimensions.Add('NewLayoutDescription', NewDescription);
            AddReportLayoutDimensionsAction('Edit', CustomDimensions);
            Log('0000N0H', 'Report layout properties changed by user', CustomDimensions);
        end;
    end;

    internal procedure ExportReportLayout(SelectedReportLayoutList: Record "Report Layout List"; UpdateOnOnexport: Boolean): Text
    var
        SourceTempBlob: Codeunit "Temp Blob";
        TargetTempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        FileName: Text;
        MediaOutStream: OutStream;
        LayoutSourceStream: InStream;
        LayoutTargetStream: InStream;
        LayoutTargetOutStream: OutStream;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        MediaOutStream := SourceTempBlob.CreateOutStream(TextEncoding::UTF8);
        SelectedReportLayoutList."Layout".ExportStream(MediaOutStream);
        FileName := GetFileName(SelectedReportLayoutList);

        if UpdateOnOnexport then begin
            LayoutSourceStream := SourceTempBlob.CreateInStream(TextEncoding::UTF8);
            LayoutTargetStream := TargetTempBlob.CreateInStream(TextEncoding::UTF8);
            LayoutTargetOutStream := TargetTempBlob.CreateOutStream(TextEncoding::UTF8);
            if Report.ValidateAndPrepareLayout(SelectedReportLayoutList."Report ID", LayoutSourceStream, LayoutTargetStream, GetLayoutType(SelectedReportLayoutList)) then begin
                CopyStream(LayoutTargetOutStream, LayoutTargetStream);
                exit(FileManagement.BLOBExportWithEncoding(TargetTempBlob, FileName, true, TextEncoding::UTF8));
            end else
                Message(CannotUpdateLayoutTxt);
        end;

        InitReportLayoutListDimensions(selectedReportLayoutList, CustomDimensions);
        if (UpdateOnOnexport) then
            AddReportLayoutDimensionsAction('UpdateAndExport', CustomDimensions)
        else
            AddReportLayoutDimensionsAction('Export', CustomDimensions);

        Log('0000N0I', 'Report layout exported by user', CustomDimensions);

        exit(FileManagement.BLOBExport(SourceTempBlob, FileName, true));
    end;

    internal procedure ShowInfoDialog(SelectedReportLayoutList: Record "Report Layout List")
    var
        InfoDialogLbl: Label 'Report ID: %1\Report Name: %2\Layout Name: %3\Description: %4\Type: %5\System ID: %6\Created Date: %7\Created By: %8\Last Modified Date: %9\Last Modified By: %10',
                       Comment = 'Text to build the message displayed on the layout info dialog. %1 = Repport ID, %2 = Report Name, %3 = Layout Name, %4 = Description, %5 = Layout Type, %6 = System ID, %7 = Created Date, %8 = Created By, %9 = Last Modified Date, %10 = Last Modified By';
    begin

        // We need to use this format with % and variable passed to the Message function so that backslahes in the variables are not replaced with new lines.
        Message(InfoDialogLbl,
            SelectedReportLayoutList."Report ID".ToText(),
            SelectedReportLayoutList."Report Name",
            SelectedReportLayoutList.Caption,
            SelectedReportLayoutList.Description,
            Format(SelectedReportLayoutList."Layout Format"),
            Format(SelectedReportLayoutList.SystemId, 0, 4),
            SelectedReportLayoutList.SystemCreatedAt.ToText(),
            GetUserDisplayName(SelectedReportLayoutList.SystemCreatedBy),
            SelectedReportLayoutList.SystemModifiedAt.ToText(),
            GetUserDisplayName(SelectedReportLayoutList.SystemModifiedBy));
    end;

    local procedure GetUserDisplayName(UserGuid: Guid): Text
    var
        User: Record "User";
    begin
        if not User.ReadPermission() then
            exit('');

        if (UserGuid <> EmptyGuid) and User.Get(UserGuid) then
            exit(User."User Name");

        exit('');
    end;

    internal procedure OpenInOneDrive(SelectedReportLayoutList: Record "Report Layout List")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        DocumentServiceMgt: Codeunit "Document Service Management";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        FileExtension: Text;
        MediaInStream: InStream;
        MediaOutStream: OutStream;
    begin
        if not TenantReportLayout.Get(SelectedReportLayoutList."Report ID", SelectedReportLayoutList."Name", EmptyGuid) then
            exit;

        FileName := GetFileName(SelectedReportLayoutList);
        FileExtension := GetFileExtension(SelectedReportLayoutList);

        MediaOutStream := TempBlob.CreateOutStream();
        TenantReportLayout."Layout".ExportStream(MediaOutStream);

        MediaInStream := TempBlob.CreateInStream();
        DocumentServiceMgt.OpenInOneDrive(FileName, FileExtension, MediaInStream);
    end;

    internal procedure ShareWithOneDrive(SelectedReportLayoutList: Record "Report Layout List")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        DocumentServiceMgt: Codeunit "Document Service Management";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        FileExtension: Text;
        MediaInStream: InStream;
        MediaOutStream: OutStream;
    begin
        if not TenantReportLayout.Get(SelectedReportLayoutList."Report ID", SelectedReportLayoutList."Name", EmptyGuid) then
            exit;

        FileName := GetFileName(SelectedReportLayoutList);
        FileExtension := GetFileExtension(SelectedReportLayoutList);

        MediaOutStream := TempBlob.CreateOutStream();
        TenantReportLayout."Layout".ExportStream(MediaOutStream);

        MediaInStream := TempBlob.CreateInStream();
        DocumentServiceMgt.ShareWithOneDrive(FileName, FileExtension, MediaInStream);
    end;

    internal procedure EditInOneDrive(SelectedReportLayoutList: Record "Report Layout List")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        DocumentServiceMgt: Codeunit "Document Service Management";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        FileExtension: Text;
        MediaInStream: InStream;
        MediaOutStream: OutStream;
    begin
        if not TenantReportLayout.Get(SelectedReportLayoutList."Report ID", SelectedReportLayoutList."Name", EmptyGuid) then
            exit;

        FileName := GetFileName(SelectedReportLayoutList);
        FileExtension := GetFileExtension(SelectedReportLayoutList);

        MediaOutStream := TempBlob.CreateOutStream();
        TenantReportLayout."Layout".ExportStream(MediaOutStream);

        if DocumentServiceMgt.EditInOneDrive(FileName, FileExtension, TempBlob) then begin

            MediaInStream := TempBlob.CreateInStream();
            TenantReportLayout."Layout".ImportStream(MediaInStream, TenantReportLayout."Description");

            if not TenantReportLayout.Insert(true) then
                TenantReportLayout.Modify(true);
        end;
    end;

    procedure ExportReportSchema(SelectedReportLayoutList: Record "Report Layout List"; DefaultFileName: Text; ShowFileDialog: Boolean) Result: Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        if DefaultFileName = '' then
            DefaultFileName := '*.xml';
        GetWordXMLPart(SelectedReportLayoutList."Report ID", TempBlob);
        if TempBlob.HasValue() then
            exit(FileMgt.BLOBExport(TempBlob, DefaultFileName, ShowFileDialog));
    end;

    local procedure GetWordXMLPart(reportId: Integer; var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TEXTENCODING::UTF16);
        OutStr.WriteText(REPORT.WordXmlPart(reportId));
    end;

    local procedure GetFileName(SelectedReportLayoutList: Record "Report Layout List"): Text
    var
        CurrentExt: Text;
        CurrentLayoutName: Text;
    begin
        CurrentLayoutName := SelectedReportLayoutList."Name";
        CurrentExt := GetFileExtension(SelectedReportLayoutList);
        if StrPos(CurrentLayoutName, '.' + CurrentExt) = 0 then
            exit(CurrentLayoutName + '.' + CurrentExt);
        exit(CurrentLayoutName);
    end;

    local procedure GetFileExtension(SelectedReportLayoutList: Record "Report Layout List") FileExt: Text
    begin
        // If MIME Type is present, use that to create file-extension.
        if (SelectedReportLayoutList."MIME Type" <> '') and SelectedReportLayoutList."MIME Type".ToLower().Contains('reportlayout/') then begin
            FileExt := SelectedReportLayoutList."MIME Type".Split('/').Get(2);
            exit;
        end;

        case SelectedReportLayoutList."Layout Format" of
            SelectedReportLayoutList."Layout Format"::Word:
                FileExt := 'docx';
            SelectedReportLayoutList."Layout Format"::RDLC:
                FileExt := 'rdl';
            SelectedReportLayoutList."Layout Format"::Excel:
                FileExt := 'xlsx';
            SelectedReportLayoutList."Layout Format"::Custom:
                FileExt := '';
        end;
    end;

    local procedure GetLayoutType(SelectedReportLayoutList: Record "Report Layout List") LayoutType: ReportLayoutType
    begin
        case SelectedReportLayoutList."Layout Format" of
            SelectedReportLayoutList."Layout Format"::Word:
                LayoutType := ReportLayoutType::Word;
            SelectedReportLayoutList."Layout Format"::RDLC:
                LayoutType := ReportLayoutType::RDLC;
            SelectedReportLayoutList."Layout Format"::Excel:
                LayoutType := ReportLayoutType::Excel;
            SelectedReportLayoutList."Layout Format"::Custom:
                LayoutType := ReportLayoutType::Custom;
        end;
    end;

    local procedure InitReportLayoutDimensions(TenantReportLayout: Record "Tenant Report Layout"; var CustomDimensions: Dictionary of [Text, Text])
    begin
        CustomDimensions.Set('ReportId', Format(TenantReportLayout."Report ID"));
        CustomDimensions.Set('LayoutName', TenantReportLayout."Name");
    end;

    local procedure InitReportLayoutListDimensions(ReportLayoutList: Record "Report Layout List"; var CustomDimensions: Dictionary of [Text, Text])
    begin
        CustomDimensions.Set('ReportId', Format(ReportLayoutList."Report ID"));
        CustomDimensions.Set('LayoutName', ReportLayoutList."Name");
    end;

    local procedure AddReportLayoutDimensionsFormat(LayoutFormat: Option; var CustomDimensions: Dictionary of [Text, Text])
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        TenantReportLayout."Layout Format" := LayoutFormat;
        // Format this option with the correct string value using metadata from the table.
        CustomDimensions.Add('LayoutFormat', format(TenantReportLayout."Layout Format"));
    end;

    local procedure AddReportLayoutDimensionsDescription(Description: Text; var CustomDimensions: Dictionary of [Text, Text])
    begin
        CustomDimensions.Add('LayoutDescription', Description);
    end;

    local procedure AddReportLayoutDimensionsAction(Action: Text; var CustomDimensions: Dictionary of [Text, Text])
    begin
        CustomDimensions.Add('Action', Action);
    end;

    local procedure AddReportLayoutDimensionsExcelConfiguration(Configuration: enum "Excel Sheet Configuration"; var CustomDimensions: Dictionary of [Text, Text])
    begin
        CustomDimensions.Add('ExcelConfiguration', format(Configuration));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Report Layout Selection", 'OnSelectReportLayout', '', false, false)]
    local procedure SelectReportLayout(var ReportLayoutList: Record "Report Layout List"; var Handled: Boolean)
    begin
        if Handled = true then
            exit;

        if Page.RunModal(Page::"Report Layouts", ReportLayoutList) = ACTION::LookupOK then
            Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnSelectReportLayout', '', false, false)]
    local procedure SelectReportLayoutUI(var ReportLayoutList: Record "Report Layout List"; var Handled: Boolean)
    begin
        if Page.RunModal(Page::"Report Layouts", ReportLayoutList) = ACTION::LookupOK then
            Handled := true;
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeUpload(var AlreadyUploaded: Boolean; var UploadFileName: Text; var FileInStream: InStream)
    begin
    end;

    local procedure Log(EventId: Text; AuditMessage: Text; CustomDimensions: Dictionary of [Text, Text])
    var
        AuditLog: Codeunit "Audit Log";
    begin
        Session.LogMessage(EventId, AuditMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        AuditLog.LogAuditMessage(AuditMessage, SecurityOperationResult::Success, AuditCategory::Other, 7, 0, CustomDimensions);
    end;
}