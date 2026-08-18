// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

/// <summary>
/// Lists report layouts with the theme and header/footer that effectively apply to each, including the level each
/// resolves from (this layout, report default, company, or global). Opened filtered to one report from the Report
/// Layouts page, or to the reports that assign one part from the Report themes and header-footer setup page, in which
/// case SetPartContext names that part in the caption. The theme/header-footer of a layout is changed in place via the
/// Manage action, which writes a layout-level Tenant Report Layout Cfg entry; unset layouts keep showing the inherited
/// company/global default.
/// </summary>
page 9670 "Layout Theme and Header/Footer"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Layout Themes and Header/Footers';
    PageType = List;
    SourceTable = "Report Layout List";
    SourceTableView = sorting("Report ID", "Layout Format");
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report No.';
                    ToolTip = 'Specifies the report the layout belongs to.';
                }
                field(LayoutCaption; Rec."Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Name';
                    ToolTip = 'Specifies the body layout.';
                }
                field(ThemeField; ThemeDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme';
                    ToolTip = 'Specifies the theme applied to the layout. None = no theme applies at any level; otherwise the resolved theme name.';
                }
                field(ThemeSourceField; ThemeSource)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme source';
                    ToolTip = 'Specifies where the theme resolves from: This layout, Report default, Company (Company Information), or Global default.';
                }
                field(HeaderFooterField; HeaderDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer';
                    ToolTip = 'Specifies the header/footer applied to the layout. None = none applies at any level; otherwise the resolved part name.';
                }
                field(HeaderSourceField; HeaderSource)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer source';
                    ToolTip = 'Specifies where the header/footer resolves from: This layout, Report default, Company (Company Information), or Global default.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ManageThemeHeaderFooter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage theme/header-footer';
                Image = Setup;
                ToolTip = 'Change the theme and header/footer applied to the selected layout. The assignment is stored for this layout (per company/tenant), overriding any company or global default.';

                trigger OnAction()
                begin
                    ManageRow();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ManageThemeHeaderFooter_Promoted; ManageThemeHeaderFooter)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Opened as a where-used list for one part, the caption says which part rather than describing the page.
        if PartContextName <> '' then
            CurrPage.Caption := StrSubstNo(PartUsageCaptionLbl, PartContextName);
    end;

    trigger OnAfterGetRecord()
    var
        HeaderResolved: Boolean;
        ThemeResolved: Boolean;
    begin
        // The layout-independent report/global defaults are identical for every layout of one report, so they are
        // resolved once per report instead of once per row. The rows are sorted by Report ID, so a list covering
        // several reports - the where-used case - still only resolves once as it moves from one report to the next.
        if (not ReportLevelResolved) or (ResolvedForReportID <> Rec."Report ID") then begin
            LookupHelper.GetReportLevelPartDisplays(Rec."Report ID", ReportHeaderDisplay, ReportHeaderSource, ReportThemeDisplay, ReportThemeSource);
            ResolvedForReportID := Rec."Report ID";
            ReportLevelResolved := true;
        end;

        LookupHelper.GetLayoutLevelPartDisplays(Rec."Report ID", Rec.Name, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
        if not HeaderResolved then begin
            HeaderDisplay := ReportHeaderDisplay;
            HeaderSource := ReportHeaderSource;
        end;
        if not ThemeResolved then begin
            ThemeDisplay := ReportThemeDisplay;
            ThemeSource := ReportThemeSource;
        end;
    end;

    local procedure ManageRow()
    var
        HeaderFooterThemeAssignment: Page "Header/Footer Theme Assignment";
    begin
        HeaderFooterThemeAssignment.SetLayout(Rec."Report ID", Rec.Name);
        HeaderFooterThemeAssignment.RunModal();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Names the theme or header/footer part the page was opened for, so the caption states which part's usage is
    /// listed. Call before Run when opening the page filtered to the reports that assign one specific part.
    /// </summary>
    internal procedure SetPartContext(PartName: Text)
    begin
        PartContextName := PartName;
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        PartContextName: Text;
        ResolvedForReportID: Integer;
        ReportLevelResolved: Boolean;
        ThemeDisplay: Text;
        ThemeSource: Text;
        HeaderDisplay: Text;
        HeaderSource: Text;
        ReportHeaderDisplay: Text;
        ReportHeaderSource: Text;
        ReportThemeDisplay: Text;
        ReportThemeSource: Text;
        PartUsageCaptionLbl: Label 'Reports using %1', Comment = '%1 = theme or header/footer part name';
}
