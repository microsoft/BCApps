// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Manages VAT statement templates and names including creation, selection, and navigation functionality.
/// Provides centralized management for VAT statement setup and user interface operations.
/// </summary>
codeunit 340 VATStmtManagement
{
    Permissions = TableData "VAT Statement Template" = rimd,
                  TableData "VAT Statement Name" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'VAT';
        Text001: Label 'VAT Statement';
        Text002: Label 'DEFAULT';
        Text003: Label 'Default Statement';
#pragma warning restore AA0074
        OpenFromBatch: Boolean;

    /// <summary>
    /// Handles VAT statement template selection for a specific page and applies filtering.
    /// Creates default template if none exists or shows template selection if multiple templates available.
    /// </summary>
    /// <param name="PageID">Page ID to filter templates by</param>
    /// <param name="VATStmtLine">VAT statement line record to apply template filtering</param>
    /// <param name="StmtSelected">Returns true if template was successfully selected</param>
    procedure TemplateSelection(PageID: Integer; var VATStmtLine: Record "VAT Statement Line"; var StmtSelected: Boolean)
    var
        VATStmtTmpl: Record "VAT Statement Template";
    begin
        StmtSelected := true;

        VATStmtTmpl.Reset();
        VATStmtTmpl.SetRange("Page ID", PageID);

        case VATStmtTmpl.Count of
            0:
                begin
                    VATStmtTmpl.Init();
                    VATStmtTmpl.Name := Text000;
                    VATStmtTmpl.Description := Text001;
                    VATStmtTmpl.Validate("Page ID");
                    VATStmtTmpl.Insert();
                    Commit();
                end;
            1:
                VATStmtTmpl.FindFirst();
            else
                StmtSelected := PAGE.RunModal(0, VATStmtTmpl) = ACTION::LookupOK;
        end;
        if StmtSelected then begin
            VATStmtLine.FilterGroup(2);
            VATStmtLine.SetRange("Statement Template Name", VATStmtTmpl.Name);
            VATStmtLine.FilterGroup(0);
            if OpenFromBatch then begin
                VATStmtLine."Statement Template Name" := '';
                PAGE.Run(VATStmtTmpl."Page ID", VATStmtLine);
            end;
        end;
    end;

    /// <summary>
    /// Opens VAT statement page from batch selection with template-specific page configuration.
    /// Applies template and statement name filters before launching the statement page.
    /// </summary>
    /// <param name="VATStmtName">VAT statement name record containing template and name information</param>
    procedure TemplateSelectionFromBatch(var VATStmtName: Record "VAT Statement Name")
    var
        VATStmtLine: Record "VAT Statement Line";
        VATStmtTmpl: Record "VAT Statement Template";
    begin
        OpenFromBatch := true;
        VATStmtTmpl.Get(VATStmtName."Statement Template Name");
        VATStmtTmpl.TestField("Page ID");
        VATStmtName.TestField(Name);

        VATStmtLine.FilterGroup := 2;
        VATStmtLine.SetRange("Statement Template Name", VATStmtTmpl.Name);
        VATStmtLine.FilterGroup := 0;

        VATStmtLine."Statement Template Name" := '';
        VATStmtLine."Statement Name" := VATStmtName.Name;
        PAGE.Run(VATStmtTmpl."Page ID", VATStmtLine);
    end;

    /// <summary>
    /// Opens VAT statement with specified name and applies proper filtering.
    /// Validates template name and sets statement name filter for VAT statement lines.
    /// </summary>
    /// <param name="CurrentStmtName">Current statement name to open and filter by</param>
    /// <param name="VATStmtLine">VAT statement line record to apply filtering</param>
    procedure OpenStmt(var CurrentStmtName: Code[10]; var VATStmtLine: Record "VAT Statement Line")
    begin
        OnBeforeOpenStmt(CurrentStmtName, VATStmtLine);

        CheckTemplateName(VATStmtLine.GetRangeMax("Statement Template Name"), CurrentStmtName);
        VATStmtLine.FilterGroup(2);
        VATStmtLine.SetRange("Statement Name", CurrentStmtName);
        VATStmtLine.FilterGroup(0);
    end;

    /// <summary>
    /// Opens VAT statement batch with template selection and proper filtering setup.
    /// Handles template selection when multiple templates exist and creates default statement names.
    /// </summary>
    /// <param name="VATStmtName">VAT statement name record to open in batch mode</param>
    procedure OpenStmtBatch(var VATStmtName: Record "VAT Statement Name")
    var
        VATStmtTmpl: Record "VAT Statement Template";
        VATStmtLine: Record "VAT Statement Line";
        JnlSelected: Boolean;
    begin
        if VATStmtName.GetFilter("Statement Template Name") <> '' then
            exit;
        VATStmtName.FilterGroup(2);
        if VATStmtName.GetFilter("Statement Template Name") <> '' then begin
            VATStmtName.FilterGroup(0);
            exit;
        end;
        VATStmtName.FilterGroup(0);

        if not VATStmtName.Find('-') then begin
            if not VATStmtTmpl.FindFirst() then
                TemplateSelection(0, VATStmtLine, JnlSelected);
            if VATStmtTmpl.FindFirst() then
                CheckTemplateName(VATStmtTmpl.Name, VATStmtName.Name);
        end;
        VATStmtName.Find('-');
        JnlSelected := true;
        if VATStmtName.GetFilter("Statement Template Name") <> '' then
            VATStmtTmpl.SetRange(Name, VATStmtName.GetFilter("Statement Template Name"));
        case VATStmtTmpl.Count of
            1:
                VATStmtTmpl.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, VATStmtTmpl) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        VATStmtName.FilterGroup(0);
        VATStmtName.SetRange("Statement Template Name", VATStmtTmpl.Name);
        VATStmtName.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentStmtTemplateName: Code[10]; var CurrentStmtName: Code[10])
    var
        VATStmtTmpl: Record "VAT Statement Template";
        VATStmtName: Record "VAT Statement Name";
    begin
        VATStmtName.SetRange("Statement Template Name", CurrentStmtTemplateName);
        if not VATStmtName.Get(CurrentStmtTemplateName, CurrentStmtName) then begin
            if not VATStmtName.FindFirst() then begin
                VATStmtTmpl.Get(CurrentStmtTemplateName);
                VATStmtName.Init();
                VATStmtName."Statement Template Name" := VATStmtTmpl.Name;
                VATStmtName.Name := Text002;
                VATStmtName.Description := Text003;
                VATStmtName.Insert();
                Commit();
            end;
            CurrentStmtName := VATStmtName.Name;
        end;
    end;

    /// <summary>
    /// Validates that the specified statement name exists for the current template.
    /// Ensures statement name is valid for the current VAT statement line context.
    /// </summary>
    /// <param name="CurrentStmtName">Statement name to validate</param>
    /// <param name="VATStmtLine">VAT statement line providing template context</param>
    procedure CheckName(CurrentStmtName: Code[10]; var VATStmtLine: Record "VAT Statement Line")
    var
        VATStmtName: Record "VAT Statement Name";
    begin
        VATStmtName.Get(VATStmtLine.GetRangeMax("Statement Template Name"), CurrentStmtName);
    end;

    /// <summary>
    /// Sets the statement name filter on VAT statement lines and positions to first record.
    /// Applies statement name filtering and navigates to the first matching line.
    /// </summary>
    /// <param name="CurrentStmtName">Statement name to set as filter</param>
    /// <param name="VATStmtLine">VAT statement line record to apply filtering and positioning</param>
    procedure SetName(CurrentStmtName: Code[10]; var VATStmtLine: Record "VAT Statement Line")
    begin
        VATStmtLine.FilterGroup(2);
        VATStmtLine.SetRange("Statement Name", CurrentStmtName);
        VATStmtLine.FilterGroup(0);
        if VATStmtLine.Find('-') then;
    end;

    /// <summary>
    /// Opens lookup page for VAT statement names within the specified template.
    /// Allows user selection of VAT statement name and returns the selected name.
    /// </summary>
    /// <param name="CurrentStmtTemplateName">Template name to filter statement names</param>
    /// <param name="CurrentStmtName">Current statement name for initial positioning</param>
    /// <param name="EntrdStmtName">Returns the selected statement name</param>
    /// <returns>True if statement name was selected, false if cancelled</returns>
    procedure LookupName(CurrentStmtTemplateName: Code[10]; CurrentStmtName: Code[10]; var EntrdStmtName: Text[10]): Boolean
    var
        VATStmtName: Record "VAT Statement Name";
    begin
        VATStmtName."Statement Template Name" := CurrentStmtTemplateName;
        VATStmtName.Name := CurrentStmtName;
        VATStmtName.FilterGroup(2);
        VATStmtName.SetRange("Statement Template Name", CurrentStmtTemplateName);
        VATStmtName.FilterGroup(0);
        if PAGE.RunModal(0, VATStmtName) <> ACTION::LookupOK then
            exit(false);

        EntrdStmtName := VATStmtName.Name;
        exit(true);
    end;

    /// <summary>
    /// Integration event raised before opening a VAT statement to allow customization.
    /// Enables modification of statement name or VAT statement line before opening.
    /// </summary>
    /// <param name="CurrentStmtName">Current statement name being opened</param>
    /// <param name="VATStatementLine">VAT statement line record being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenStmt(var CurrentStmtName: Code[10]; var VATStatementLine: Record "VAT Statement Line")
    begin
    end;
}

