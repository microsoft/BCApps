// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Shared.Report;

using System.Environment.Configuration;
using System.Reflection;
/// <summary>
/// A dialog page for editting report layout information.
/// </summary>
page 9661 "Report Layout Edit Dialog"
{
    Caption = 'Edit Report Layout';
    PageType = StandardDialog;
    Extensible = false;
    Permissions = tabledata "Tenant Report Layout" = r;

    layout
    {
        area(content)
        {
            field(ReportID; ReportID)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report ID';
                Enabled = false;
                ToolTip = 'Specifies the ID of the report.';
            }
            field(ReportName; ReportName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Name';
                Enabled = false;
                ToolTip = 'Specifies the name of the report.';
            }
            field(LayoutName; NewLayoutName)
            {
                ApplicationArea = Basic, Suite;
                NotBlank = true;
                ShowMandatory = true;
                Editable = LayoutNameEditable;
                Caption = 'Layout Name';
                ToolTip = 'Specifies the name of the layout.';

                trigger OnValidate()
                begin
                    NewLayoutName := NewLayoutName.Trim();
                    if NewLayoutName = '' then
                        Error(LayoutNameEmptyErr);

                    if TenantReportLayout.Get(ReportID, NewLayoutName, emptyGuid) then
                        if CreateCopy or (OldLayoutName <> NewLayoutName) then
                            Error(LayoutAlreadyExistsErr, NewLayoutName);
                end;
            }
            field(Description; Description)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Description';
                ToolTip = 'Specifies a description for the layout.';

                trigger OnValidate()
                begin
                    Description := Description.Trim();
                end;
            }
            field(CreateCopy; CreateCopy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Save Changes to a Copy';
                ToolTip = 'Create a copy of the selected layout with the specified changes.';
                Editable = CreateCopyEditable;

                trigger OnValidate()
                begin
                    // In override mode (extension layout) checking "Save Changes to a Copy" re-enables
                    // the Layout Name so the forked copy can be given a distinct name.
                    if OverrideMode then
                        LayoutNameEditable := CreateCopy
                    else
                        if (CreateCopy) then
                            AvailableInAllCompaniesEditable := true
                        else
                            if (IsLayoutOwnedByCurrentCompany) then begin
                                AvailableInAllCompaniesEditable := true;
                                AvailableInAllCompanies := false;
                            end else begin
                                AvailableInAllCompaniesEditable := false;
                                AvailableInAllCompanies := true;
                            end;
                end;
            }
            field(AvailableInAllCompanies; AvailableInAllCompanies)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Available in All Companies';
                ToolTip = 'Specifies whether the layout should be available in all companies or just the current company.';
                Editable = AvailableInAllCompaniesEditable;
                Visible = not OverrideMode;
            }
            field(OverrideForAllCompanies; OverrideForAllCompanies)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Override for all companies';
                ToolTip = 'Specifies whether this override applies to all companies (global) or only the current company. The layout itself stays available everywhere; this controls only the scope of the override.';
                Visible = OverrideMode;
                Editable = OverrideMode;
            }
            field(IsObsolete; IsObsolete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark layout as obsolete';
                ToolTip = 'Specifies whether the layout is obsolete.';
                Editable = IsObsoleteEditable;
            }
        }
    }

    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportID: Integer;
        OldLayoutName: Text[250];
        NewLayoutName: Text[250];
        ReportName: Text;
        Description: Text[250];
        LayoutAlreadyExistsErr: Label 'A layout named %1 already exists.', Comment = '%1 = Layout Name';
        LayoutNameEmptyErr: Label 'The layout name cannot be an empty value.';
        emptyGuid: Guid;
        CreateCopy: Boolean;
        CreateCopyEditable: Boolean;
        AvailableInAllCompanies: Boolean;
        AvailableInAllCompaniesEditable: Boolean;
        IsLayoutOwnedByCurrentCompany: Boolean;
        IsObsolete: Boolean;
        LayoutNameEditable: Boolean;
        IsObsoleteEditable: Boolean;
        OverrideMode: Boolean;
        OverrideForAllCompanies: Boolean;

    internal procedure SelectedLayoutDescription(): Text[250]
    begin
        exit(Description);
    end;

    internal procedure SelectedLayoutName(): Text[250]
    begin
        exit(NewLayoutName);
    end;

    internal procedure SelectedAvailableInAllCompanies(): Boolean
    begin
        exit(AvailableInAllCompanies);
    end;

    internal procedure SelectedOverrideForAllCompanies(): Boolean
    begin
        exit(OverrideForAllCompanies);
    end;

    /// <summary>
    /// Re-seeds the dialog when it is reopened after the user declined an all-companies override, so
    /// their entries survive and only the scope is reset. Does not re-run SetupDialog (which would
    /// discard the edits).
    /// </summary>
    internal procedure SetOverrideValues(NewDescription: Text[250]; NewIsObsolete: Boolean; ScopeIsGlobal: Boolean)
    begin
        Description := NewDescription;
        if IsObsoleteEditable then
            IsObsolete := NewIsObsolete;
        OverrideForAllCompanies := ScopeIsGlobal;
    end;

    internal procedure SelectedIsObsolete(): Boolean
    begin
        exit(IsObsolete);
    end;

    internal procedure CopyOperationEnabled(): Boolean
    begin
        exit(CreateCopy);
    end;

    internal procedure SetupDialog(ReportLayoutList: Record "Report Layout List"; CurrentSelectedCompany: Text[30]): Text
    begin
        ReportID := ReportLayoutList."Report ID";
        ReportName := ReportLayoutList."Report Name";
        Description := ReportLayoutList."Description";
        OldLayoutName := ReportLayoutList."Caption";
        NewLayoutName := OldLayoutName;
        IsObsolete := ReportLayoutList.IsObsolete;
        LayoutNameEditable := true;
        IsObsoleteEditable := true;
        OverrideMode := false;

        if not ReportLayoutList."User Defined" then begin
            // Override mode: edit the extension layout's Description / IsObsolete via a
            // Tenant Report Layout Override record. The name/identity is fixed, and IsObsolete is
            // one-way (a layout already obsolete in metadata cannot be un-obsoleted). Copy remains
            // available as an opt-in escape hatch to fork the layout content into a user layout.
            OverrideMode := true;
            CreateCopy := false;
            CreateCopyEditable := true;
            LayoutNameEditable := false;
            IsObsoleteEditable := not ReportLayoutList.IsObsolete;
            // Override scope uses its own control and defaults to the CURRENT company (ask-first
            // before global) — NOT the "Available in All Companies" layout-availability field.
            OverrideForAllCompanies := false;

        end else begin
            CreateCopy := false;
            CreateCopyEditable := true;

            TenantReportLayout.Get(ReportID, ReportLayoutList.Name, emptyGuid);
            if (TenantReportLayout."Company Name" = CurrentSelectedCompany) then begin
                AvailableInAllCompaniesEditable := true;
                AvailableInAllCompanies := false;
                IsLayoutOwnedByCurrentCompany := true;
            end else begin
                AvailableInAllCompaniesEditable := false;
                AvailableInAllCompanies := true;
            end;
        end;
    end;
}
