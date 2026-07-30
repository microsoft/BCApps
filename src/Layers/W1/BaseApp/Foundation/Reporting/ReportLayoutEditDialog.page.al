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
                    // the Layout Name so the forked copy can be given a distinct name, and unlocks the
                    // layout-availability field — the copy is a normal tenant layout, so its company
                    // scope is chosen there (not by the override-scope control).
                    // The two scope toggles are mutually exclusive: a copy writes a tenant layout and
                    // NO override, so the override-scope control must not stay live (it would do
                    // nothing); conversely an in-place override does not create a layout, so the
                    // availability field stays read-only there.
                    if OverrideMode then begin
                        LayoutNameEditable := CreateCopy;
                        AvailableInAllCompaniesEditable := CreateCopy;
                    end else
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
                // For an extension layout this states the (true) fact that the layout is available
                // everywhere; it is read-only until the user opts into a copy, whose company scope it
                // then controls. Editing an extension layout in place never changes availability — it
                // writes an override for the CURRENT company only, with no scope choice to make.
                Editable = AvailableInAllCompaniesEditable;
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
            // No scope choice is offered here: an in-place edit of an extension layout always writes a
            // CURRENT-COMPANY override. Tenant-wide (global) overrides are a governance act — see the
            // task notes — and are deliberately kept out of this dialog.
            // Keep the shipped default for the copy escape hatch: a copy of an extension layout is
            // created for all companies unless the user says otherwise (unlocked once Copy is ticked).
            AvailableInAllCompanies := true;
            AvailableInAllCompaniesEditable := false;

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
