// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Helper for looking up Composite Layout header/footer and theme parts and translating between the user-facing layout name and the platform composite reference format <c>&lt;AppId&gt;::&lt;LayoutName&gt;</c> used in Tenant Report Layout Selection and Tenant Report Layout Cfg.
/// </summary>
codeunit 9665 "Composite Layout Lookup Helper"
{
    Access = Internal;
    Permissions = tabledata "Tenant Report Layout Cfg" = RIMD;

    /// <summary>
    /// Opens the Report Themes and Header/Footers registry as a lookup filtered to the given subtype. Non-approved
    /// parts (Draft, Pending Approval, Retired) are shown so they can be reviewed, but only an approved part may be
    /// picked: selecting a non-approved part raises an error and nothing is returned. On a successful pick the part's
    /// composite reference is encoded and returned via <paramref name="Composite"/>.
    /// </summary>
    /// <param name="Subtype">The subtype to filter the lookup to.</param>
    /// <param name="Composite">The encoded composite reference of the picked approved part on success.</param>
    /// <returns>True when an approved part was picked; false when the user cancelled.</returns>
    procedure LookupCompositePart(Subtype: Enum "Report Layout Subtype"; var Composite: Text): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        ReportThemeHeaderFooter: Page "Report Theme and Header/Footer";
    begin
        ReportLayoutList.SetRange("Layout Subtype", Subtype);
        ReportThemeHeaderFooter.SetTableView(ReportLayoutList);
        ReportThemeHeaderFooter.LookupMode(true);
        if ReportThemeHeaderFooter.RunModal() <> Action::LookupOK then
            exit(false);

        ReportThemeHeaderFooter.GetRecord(ReportLayoutList);

        // Draft and other non-approved parts are visible in the lookup so they can be reviewed, but only approved
        // parts may actually be assigned.
        if ReportLayoutList."Layout Status" <> ReportLayoutList."Layout Status"::Approved then
            Error(PartNotApprovedErr, ReportLayoutList.Name);

        Composite := this.EncodeCompositeName(ReportLayoutList."Application ID", ReportLayoutList.Name);
        exit(true);
    end;

    /// <summary>
    /// Returns the plain layout name embedded in a composite reference. Returns the input unchanged when no <c>::</c> separator is present so legacy or hand-edited values still display sensibly.
    /// </summary>
    procedure DecodeLayoutName(CompositeName: Text): Text
    var
        SeparatorPos: Integer;
    begin
        SeparatorPos := StrPos(CompositeName, '::');
        if SeparatorPos = 0 then
            exit(CompositeName);
        exit(CopyStr(CompositeName, SeparatorPos + 2));
    end;

    /// <summary>
    /// Returns the application ID embedded in a composite reference (the <c>&lt;guid&gt;</c> before the <c>::</c>
    /// separator). Returns an empty GUID when there is no separator or the segment is not a valid GUID, so callers
    /// can fall back to matching by name alone.
    /// </summary>
    internal procedure DecodeAppId(CompositeName: Text) AppId: Guid
    var
        SeparatorPos: Integer;
        GuidPart: Text;
    begin
        SeparatorPos := StrPos(CompositeName, '::');
        if SeparatorPos <= 1 then
            exit;
        GuidPart := CopyStr(CompositeName, 1, SeparatorPos - 1);
        // EncodeCompositeName writes the GUID in the dashed, braceless form; accept the braced form too in case a
        // value was hand-edited. On failure AppId stays the empty GUID.
        if Evaluate(AppId, GuidPart) then
            exit;
        if Evaluate(AppId, '{' + GuidPart + '}') then
            exit;
        Clear(AppId);
    end;

    /// <summary>
    /// Counts how many Tenant Report Layout Cfg entries currently assign the given part (matched by its composite
    /// reference in the Header Part Name column for header/footer parts, or the Theme Part Name column for theme parts).
    /// </summary>
    /// <param name="PartLayout">The theme or header/footer part.</param>
    /// <returns>The number of configuration rows that reference the part.</returns>
    procedure CountPartAssignments(PartLayout: Record "Report Layout List"): Integer
    var
        Cfg: Record "Tenant Report Layout Cfg";
        Composite: Text;
    begin
        Composite := this.EncodeCompositeName(PartLayout."Application ID", PartLayout.Name);
        case PartLayout."Layout Subtype" of
            PartLayout."Layout Subtype"::HeaderFooter:
                Cfg.SetRange("Header Part Name", CopyStr(Composite, 1, MaxStrLen(Cfg."Header Part Name")));
            PartLayout."Layout Subtype"::Theme:
                Cfg.SetRange("Theme Part Name", CopyStr(Composite, 1, MaxStrLen(Cfg."Theme Part Name")));
            else
                exit(0);
        end;
        exit(Cfg.Count());
    end;

    /// <summary>
    /// Clears every Tenant Report Layout Cfg assignment of the given part, blanking the composite reference in the
    /// Header Part Name column for header/footer parts, or the Theme Part Name column for theme parts. Call before
    /// deleting a part so no configuration is left pointing at — or able to silently re-bind to — a part that no
    /// longer exists.
    /// </summary>
    /// <param name="PartLayout">The theme or header/footer part being removed.</param>
    /// <returns>The number of configuration rows that were cleared.</returns>
    procedure ClearPartAssignments(PartLayout: Record "Report Layout List"): Integer
    var
        Cfg: Record "Tenant Report Layout Cfg";
        Composite: Text;
        ClearedCount: Integer;
    begin
        Composite := this.EncodeCompositeName(PartLayout."Application ID", PartLayout.Name);
        case PartLayout."Layout Subtype" of
            PartLayout."Layout Subtype"::HeaderFooter:
                begin
                    Cfg.SetRange("Header Part Name", CopyStr(Composite, 1, MaxStrLen(Cfg."Header Part Name")));
                    ClearedCount := Cfg.Count();
                    Cfg.ModifyAll("Header Part Name", '');
                end;
            PartLayout."Layout Subtype"::Theme:
                begin
                    Cfg.SetRange("Theme Part Name", CopyStr(Composite, 1, MaxStrLen(Cfg."Theme Part Name")));
                    ClearedCount := Cfg.Count();
                    Cfg.ModifyAll("Theme Part Name", '');
                end;
        end;
        exit(ClearedCount);
    end;

    /// <summary>
    /// Builds the canonical composite part reference (&lt;guid&gt;::&lt;layoutname&gt;) used to store and match header/footer and theme parts.
    /// </summary>
    /// <param name="AppId">The application ID of the layout part.</param>
    /// <param name="LayoutName">The name of the layout part.</param>
    /// <returns>The encoded composite reference.</returns>
    internal procedure EncodeCompositeName(AppId: Guid; LayoutName: Text): Text
    begin
        // Mirrors CompositeLayoutPartName.Encode on the platform side: <guid>::<layoutname>, where the guid is the
        // canonical dashed form lowercased (the platform writes it lowercase via Guid.ToString("D")). Format(_, 0, 4)
        // on a Guid produces the dashed form in AL but uppercase, so lowercase it to match exactly.
        exit(LowerCase(Format(AppId, 0, 4)) + '::' + LayoutName);
    end;

    /// <summary>
    /// Returns the platform Tenant Report Defaults report ID, under which reusable composite layout parts (themes and
    /// header/footer layouts) are stored so they can be assigned as defaults for any report.
    /// </summary>
    /// <returns>The Tenant Report Defaults report ID.</returns>
    internal procedure GetTenantReportDefaultsReportID(): Integer
    begin
        exit(2000000001); // The platform's virtual "Tenant Report Defaults" report.
    end;

    /// <summary>
    /// Resolves the header/footer and theme parts that effectively apply to a report layout and reports both the part
    /// name and where it resolved from. Mirrors the platform resolver (Stage 2 of ReportLayoutSelection), walking the
    /// same six Tenant Report Layout Cfg precedence levels — most specific first — with header and theme resolved
    /// independently, so the FactBox shows what will actually render rather than only the layout-level assignment.
    /// </summary>
    /// <param name="ReportID">The report.</param>
    /// <param name="LayoutName">The body layout name.</param>
    /// <param name="HeaderDisplay">Out: the resolved header/footer name, or 'None' when nothing applies.</param>
    /// <param name="HeaderSource">Out: where the header/footer resolved from, or blank when 'None'.</param>
    /// <param name="ThemeDisplay">Out: the resolved theme name, or 'None' when nothing applies.</param>
    /// <param name="ThemeSource">Out: where the theme resolved from, or blank when 'None'.</param>
    procedure GetResolvedPartDisplays(ReportID: Integer; LayoutName: Text; var HeaderDisplay: Text; var HeaderSource: Text; var ThemeDisplay: Text; var ThemeSource: Text)
    var
        ReportHeaderDisplay: Text;
        ReportHeaderSource: Text;
        ReportThemeDisplay: Text;
        ReportThemeSource: Text;
        HeaderResolved: Boolean;
        ThemeResolved: Boolean;
    begin
        this.GetLayoutLevelPartDisplays(ReportID, LayoutName, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
        if HeaderResolved and ThemeResolved then
            exit;

        // Whatever the layout level did not resolve falls back to the layout-independent report/global defaults.
        this.GetReportLevelPartDisplays(ReportID, ReportHeaderDisplay, ReportHeaderSource, ReportThemeDisplay, ReportThemeSource);
        if not HeaderResolved then begin
            HeaderDisplay := ReportHeaderDisplay;
            HeaderSource := ReportHeaderSource;
        end;
        if not ThemeResolved then begin
            ThemeDisplay := ReportThemeDisplay;
            ThemeSource := ReportThemeSource;
        end;
    end;

    /// <summary>
    /// Resolves the header/footer and theme parts assigned at the layout level (this report + this layout) — the two most
    /// specific precedence levels. Reports whether each part was resolved so the caller can fall back to the
    /// layout-independent report/global defaults only for the parts not assigned at the layout level.
    /// </summary>
    /// <param name="ReportID">The report.</param>
    /// <param name="LayoutName">The body layout name.</param>
    /// <param name="HeaderDisplay">Out: the resolved header/footer name, or 'None' when not assigned at the layout level.</param>
    /// <param name="HeaderSource">Out: where the header/footer resolved from, or blank when not assigned.</param>
    /// <param name="ThemeDisplay">Out: the resolved theme name, or 'None' when not assigned at the layout level.</param>
    /// <param name="ThemeSource">Out: where the theme resolved from, or blank when not assigned.</param>
    /// <param name="HeaderResolved">Out: true when the header/footer was assigned at the layout level.</param>
    /// <param name="ThemeResolved">Out: true when the theme was assigned at the layout level.</param>
    internal procedure GetLayoutLevelPartDisplays(ReportID: Integer; LayoutName: Text; var HeaderDisplay: Text; var HeaderSource: Text; var ThemeDisplay: Text; var ThemeSource: Text; var HeaderResolved: Boolean; var ThemeResolved: Boolean)
    var
        CompanyFilter: Text;
    begin
        HeaderDisplay := NoneTxt;
        ThemeDisplay := NoneTxt;
        HeaderSource := '';
        ThemeSource := '';
        HeaderResolved := false;
        ThemeResolved := false;
        CompanyFilter := CompanyName();

        // Precedence mirrors ReportLayoutSelection.FillEmptyPartsFromCfg on the platform, most specific first.
        // Level 1: this report + this layout + this company.
        this.TryApplyCfgLevel(ReportID, LayoutName, CompanyFilter, ThisLayoutTxt, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
        // Level 2: this report + this layout, all companies.
        this.TryApplyCfgLevel(ReportID, LayoutName, '', ThisLayoutTxt, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
    end;

    /// <summary>
    /// Resolves the header/footer and theme parts from the layout-independent precedence levels: the report default (all
    /// layouts) and the company/global wildcard defaults. These do not depend on the body layout, so a page listing the
    /// layouts of a single report can resolve them once and reuse the result for every row.
    /// </summary>
    /// <param name="ReportID">The report.</param>
    /// <param name="HeaderDisplay">Out: the resolved header/footer name, or 'None' when nothing applies.</param>
    /// <param name="HeaderSource">Out: where the header/footer resolved from, or blank when 'None'.</param>
    /// <param name="ThemeDisplay">Out: the resolved theme name, or 'None' when nothing applies.</param>
    /// <param name="ThemeSource">Out: where the theme resolved from, or blank when 'None'.</param>
    internal procedure GetReportLevelPartDisplays(ReportID: Integer; var HeaderDisplay: Text; var HeaderSource: Text; var ThemeDisplay: Text; var ThemeSource: Text)
    var
        CompanyFilter: Text;
        HeaderResolved: Boolean;
        ThemeResolved: Boolean;
    begin
        HeaderDisplay := NoneTxt;
        ThemeDisplay := NoneTxt;
        HeaderSource := '';
        ThemeSource := '';
        CompanyFilter := CompanyName();

        // Level 3: this report (all layouts) + this company.
        this.TryApplyCfgLevel(ReportID, '', CompanyFilter, ReportDefaultTxt, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
        // Level 4: this report (all layouts), all companies.
        this.TryApplyCfgLevel(ReportID, '', '', ReportDefaultTxt, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
        // Level 5: global wildcard report + this company.
        this.TryApplyCfgLevel(0, '', CompanyFilter, CompanyTxt, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
        // Level 6: global wildcard report, all companies.
        this.TryApplyCfgLevel(0, '', '', GlobalTxt, HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource, HeaderResolved, ThemeResolved);
    end;

    local procedure TryApplyCfgLevel(ReportID: Integer; LayoutName: Text; CompanyFilter: Text; SourceLabel: Text; var HeaderDisplay: Text; var HeaderSource: Text; var ThemeDisplay: Text; var ThemeSource: Text; var HeaderResolved: Boolean; var ThemeResolved: Boolean)
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        if HeaderResolved and ThemeResolved then
            exit;
        if not Cfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(Cfg."Layout Name")), CopyStr(CompanyFilter, 1, MaxStrLen(Cfg."Company Name"))) then
            exit;
        if (not HeaderResolved) and (Cfg."Header Part Name" <> '') then begin
            HeaderDisplay := this.DecodeLayoutName(Cfg."Header Part Name");
            HeaderSource := SourceLabel;
            HeaderResolved := true;
        end;
        if (not ThemeResolved) and (Cfg."Theme Part Name" <> '') then begin
            ThemeDisplay := this.DecodeLayoutName(Cfg."Theme Part Name");
            ThemeSource := SourceLabel;
            ThemeResolved := true;
        end;
    end;

    /// <summary>
    /// Returns the decoded company-default header/footer and theme part names (the Tenant Report Layout Cfg row with
    /// Report ID 0 and the current company), or empty when no company default is configured.
    /// </summary>
    procedure GetCompanyDefaultDisplays(var HeaderDisplay: Text; var ThemeDisplay: Text)
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        HeaderDisplay := '';
        ThemeDisplay := '';
        if Cfg.Get(0, '', CopyStr(CompanyName(), 1, MaxStrLen(Cfg."Company Name"))) then begin
            HeaderDisplay := this.DecodeLayoutName(Cfg."Header Part Name");
            ThemeDisplay := this.DecodeLayoutName(Cfg."Theme Part Name");
        end;
    end;

    /// <summary>
    /// Prompts the user to pick a part of the given subtype and stores it as this company's default (Report ID 0,
    /// empty layout, current company). Returns true and the decoded display name when a part was picked.
    /// </summary>
    procedure AssignCompanyDefaultPart(Subtype: Enum "Report Layout Subtype"; var Display: Text): Boolean
    var
        Cfg: Record "Tenant Report Layout Cfg";
        Composite: Text;
    begin
        if not this.LookupCompositePart(Subtype, Composite) then
            exit(false);

        this.GetOrCreateCompanyCfg(Cfg);
        if Subtype = Enum::"Report Layout Subtype"::HeaderFooter then
            Cfg."Header Part Name" := CopyStr(Composite, 1, MaxStrLen(Cfg."Header Part Name"))
        else
            Cfg."Theme Part Name" := CopyStr(Composite, 1, MaxStrLen(Cfg."Theme Part Name"));
        Cfg.Modify(true);

        Display := this.DecodeLayoutName(Composite);
        exit(true);
    end;

    /// <summary>
    /// Clears this company's default part of the given subtype, removing the configuration row when both parts are empty.
    /// </summary>
    procedure ClearCompanyDefaultPart(Subtype: Enum "Report Layout Subtype")
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        if not Cfg.Get(0, '', CopyStr(CompanyName(), 1, MaxStrLen(Cfg."Company Name"))) then
            exit;

        if Subtype = Enum::"Report Layout Subtype"::HeaderFooter then
            Cfg."Header Part Name" := ''
        else
            Cfg."Theme Part Name" := '';

        if (Cfg."Header Part Name" = '') and (Cfg."Theme Part Name" = '') then
            Cfg.Delete(true)
        else
            Cfg.Modify(true);
    end;

    local procedure GetOrCreateCompanyCfg(var Cfg: Record "Tenant Report Layout Cfg")
    begin
        if Cfg.Get(0, '', CopyStr(CompanyName(), 1, MaxStrLen(Cfg."Company Name"))) then
            exit;

        Cfg.Init();
        Cfg."Report ID" := 0;
        Cfg."Layout Name" := '';
        Cfg."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Cfg."Company Name"));
        Cfg.Insert(true);
    end;

    var
        PartNotApprovedErr: Label 'The part %1 is not approved. Only approved themes and header/footer parts can be assigned. Approve it in Report themes and header-footer setup first.', Comment = '%1 = part name';
        NoneTxt: Label 'None';
        ThisLayoutTxt: Label 'This layout';
        ReportDefaultTxt: Label 'Report default';
        CompanyTxt: Label 'Company';
        GlobalTxt: Label 'Global default';
}
