// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Shared.Report;
using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Administrative list over the platform Tenant Report Layout Cfg table, used to configure default header/footer and theme parts that apply to body layouts during the Composite Layout Merge.
/// </summary>
/// <remarks>
/// Report ID 0 acts as a global wildcard. Empty Layout Name applies to all layouts for the given Report ID. Empty Company Name applies to all companies. The platform validates on insert and modify that any Header Part Name resolves to a Header/Footer-subtype layout and any Theme Part Name resolves to a Theme-subtype layout.
/// </remarks>
page 9663 "Tenant Report Layout Cfg"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tenant Report Layout Configuration';
    AdditionalSearchTerms = 'Composite Layout, Document Theme, Header Footer Part';
    PageType = List;
    SourceTable = "Tenant Report Layout Cfg";
    UsageCategory = Administration;
    Editable = true;
    // Rows are created by the Set actions rather than by typing into a blank line. The primary key is Report ID +
    // Layout Name + Company Name, so a blank new row is 0 + empty + empty - which is the global default row, and
    // inserting it a second time fails with a duplicate key before the user has set anything.
    InsertAllowed = false;
    Extensible = false;
    Permissions = tabledata "Tenant Report Layout Cfg" = RIMD;
    AboutTitle = 'Set default themes and header/footer layouts';
    AboutText = 'Set the theme and header/footer a report uses when its own layout specifies neither. Read **Applies to** to see what each row covers. Choose **Set for all reports**, **Set for one report**, or **Set for one layout** to add a scope — you pick the report and layout from a list, so you don''t need to know an ID or a layout name. You can also change an existing row''s scope with the lookups on **Report ID** and **Layout Name**. Where scopes overlap, the most specific one applies.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ScopeDisplay; ScopeDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies to';
                    Editable = false;
                    ToolTip = 'Specifies which reports and layouts this row covers, spelled out. Rows can overlap; the most specific one wins.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report this row applies to. Use the lookup to pick a report rather than entering its ID. Set it to 0 to apply to every report, in which case Layout Name must be empty.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PickedLayout: Record "Report Layout List";
                    begin
                        if not LookupBodyLayout(0, PickedLayout) then
                            exit(false);

                        Rec."Report ID" := PickedLayout."Report ID";
                        // OnValidate does not fire for a value set here, so run the same checks directly.
                        ValidateScopeChange();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateScopeChange();
                    end;
                }
                field(ReportNameDisplay; ReportNameDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report';
                    Editable = false;
                    ToolTip = 'Specifies the name of the report the ID refers to.';
                }
                field("Layout Name"; Rec."Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the body layout this row applies to. Use the lookup to pick one of the report''s layouts. Leave it empty to apply to every layout of the report.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PickedLayout: Record "Report Layout List";
                    begin
                        if Rec."Report ID" = 0 then
                            Error(PickReportFirstErr);

                        if not LookupBodyLayout(Rec."Report ID", PickedLayout) then
                            exit(false);

                        Rec."Layout Name" := CopyStr(PickedLayout.Name, 1, MaxStrLen(Rec."Layout Name"));
                        ValidateScopeChange();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateScopeChange();
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company this configuration applies to. Empty applies to all companies.';

                    trigger OnValidate()
                    begin
                        ValidateScopeChange();
                    end;
                }
                field(HeaderPartDisplay; HeaderPartDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Header/Footer Part';
                    Editable = false;
                    ToolTip = 'Specifies the header/footer layout part. Use the assist-edit (...) to pick an approved part.';

                    trigger OnAssistEdit()
                    begin
                        SetHeaderPart();
                    end;
                }
                field(ThemePartDisplay; ThemePartDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Theme Part';
                    Editable = false;
                    ToolTip = 'Specifies the theme layout part. Use the assist-edit (...) to pick an approved part.';

                    trigger OnAssistEdit()
                    begin
                        SetThemePart();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetForAllReports)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set for all reports';
                Image = New;
                ToolTip = 'Go to the row that applies to every report and every layout, creating it if it does not exist yet. This is the fallback used when nothing more specific is set.';

                trigger OnAction()
                begin
                    EnsureScopeRow(0, '');
                end;
            }
            action(SetForOneReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set for one report';
                Image = NewDocument;
                ToolTip = 'Pick a report and add the row that covers all of its layouts, creating it if it does not exist yet.';

                trigger OnAction()
                var
                    PickedLayout: Record "Report Layout List";
                begin
                    if not LookupBodyLayout(0, PickedLayout) then
                        exit;

                    EnsureScopeRow(PickedLayout."Report ID", '');
                end;
            }
            action(SetForOneLayout)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set for one layout';
                Image = NewDocument;
                ToolTip = 'Pick a single report layout and add the row that covers only that layout, creating it if it does not exist yet.';

                trigger OnAction()
                var
                    PickedLayout: Record "Report Layout List";
                begin
                    if not LookupBodyLayout(0, PickedLayout) then
                        exit;

                    EnsureScopeRow(PickedLayout."Report ID", CopyStr(PickedLayout.Name, 1, MaxStrLen(Rec."Layout Name")));
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetForAllReports_Promoted; SetForAllReports)
            {
            }

            actionref(SetForOneReport_Promoted; SetForOneReport)
            {
            }

            actionref(SetForOneLayout_Promoted; SetForOneLayout)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if not FeatureKeyManagement.IsDocumentReportExperienceEnabled() then
            Error(FeatureNotEnabledErr);
    end;

    trigger OnAfterGetRecord()
    begin
        ScopeDisplay := ScopeDescription();
        ReportNameDisplay := ReportDisplayName(Rec."Report ID");

        // The Header/Theme Part Name columns store the composite reference (<guid>::<name>); decode to the
        // plain layout name for display so the list shows names instead of the raw GUID-prefixed value.
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Rec."Header Part Name");
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Rec."Theme Part Name");
    end;

    /// <summary>
    /// Spells out in words which reports and layouts the row covers, so the wildcard conventions - report ID 0 for
    /// every report, an empty layout name for every layout of one report - do not have to be known to read the list.
    /// </summary>
    local procedure ScopeDescription(): Text
    begin
        exit(ScopeDescriptionFor(Rec."Report ID", Rec."Layout Name"));
    end;

    local procedure ScopeDescriptionFor(ReportID: Integer; LayoutName: Text): Text
    begin
        if ReportID = 0 then
            exit(AllReportsTxt);

        if LayoutName = '' then
            exit(StrSubstNo(AllLayoutsOfReportTxt, ReportDisplayName(ReportID)));

        exit(StrSubstNo(LayoutInReportTxt, LayoutName, ReportDisplayName(ReportID)));
    end;

    /// <summary>
    /// Runs the two rules that a change to the row's scope has to satisfy: report 0 covers every report so it cannot
    /// name a layout, and no two rows may describe the same scope. Called from the key fields rather than left to the
    /// platform so a clash reads as a sentence about scopes instead of a duplicate-key stack trace. Changing a key
    /// field renames the row, which is why the clash has to be caught before the write.
    /// </summary>
    local procedure ValidateScopeChange()
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        if (Rec."Report ID" = 0) and (Rec."Layout Name" <> '') then
            Error(GlobalWildcardCannotHaveLayoutNameErr);

        // xRec still holds the stored key, so an unchanged scope is not a clash with itself.
        if (Rec."Report ID" = xRec."Report ID") and
           (Rec."Layout Name" = xRec."Layout Name") and
           (Rec."Company Name" = xRec."Company Name")
        then
            exit;

        if Cfg.Get(Rec."Report ID", Rec."Layout Name", Rec."Company Name") then
            Error(ScopeExistsErr, ScopeDescriptionFor(Rec."Report ID", Rec."Layout Name"));
    end;

    /// <summary>
    /// The report's caption, falling back to its object name, and to the bare ID for a report that is not installed -
    /// a configuration row outlives the report it points at.
    /// </summary>
    local procedure ReportDisplayName(ReportID: Integer): Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportID = 0 then
            exit('');

        ReportMetadata.SetRange(ID, ReportID);
        if not ReportMetadata.FindFirst() then
            exit(StrSubstNo(UnknownReportTxt, ReportID));

        if ReportMetadata.Caption <> '' then
            exit(ReportMetadata.Caption);
        exit(ReportMetadata.Name);
    end;

    /// <summary>
    /// Opens the Report Layouts page as a lookup so a report and layout can be picked from a list instead of typed.
    /// Restricted to Word body layouts, the only kind a theme or header/footer applies to. Pass a report ID to limit
    /// the pick to that report's layouts, or 0 to allow any.
    /// </summary>
    local procedure LookupBodyLayout(ReportIDFilter: Integer; var PickedLayout: Record "Report Layout List"): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayouts: Page "Report Layouts";
    begin
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", ReportLayoutList."Layout Subtype"::Default);
        if ReportIDFilter <> 0 then
            ReportLayoutList.SetRange("Report ID", ReportIDFilter);

        ReportLayouts.SetTableView(ReportLayoutList);
        ReportLayouts.LookupMode(true);
        if ReportLayouts.RunModal() <> Action::LookupOK then
            exit(false);

        ReportLayouts.GetRecord(PickedLayout);
        exit(true);
    end;

    /// <summary>
    /// Moves to the row for the given scope, inserting it first when the tenant has none. Creating rows here rather
    /// than by typing into a blank line is what keeps the key complete from the start: a partly filled new row
    /// collides with the global default row, whose key is 0 + empty + empty.
    /// </summary>
    /// <param name="ReportID">The report the row covers, or 0 for every report.</param>
    /// <param name="LayoutName">The layout the row covers, or empty for every layout of the report.</param>
    local procedure EnsureScopeRow(ReportID: Integer; LayoutName: Text[250])
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        // Company Name is left empty: the row applies to every company until an administrator narrows it.
        if not Cfg.Get(ReportID, LayoutName, '') then begin
            Cfg.Init();
            Cfg."Report ID" := ReportID;
            Cfg."Layout Name" := LayoutName;
            Cfg."Company Name" := '';
            Cfg.Insert(true);
        end;

        // The page arrives filtered to one report when opened from Report Layouts. Lift that filter so a row created
        // for another report is actually visible, instead of the list appearing not to have changed.
        Rec.SetRange("Report ID");
        Rec := Cfg;
        CurrPage.SetRecord(Rec);
        CurrPage.Update(false);
    end;

    local procedure SetHeaderPart()
    var
        Composite: Text;
    begin
        if not LookupHelper.LookupCompositePart(Enum::"Report Layout Subtype"::HeaderFooter, Composite) then
            exit;
        Rec."Header Part Name" := CopyStr(Composite, 1, MaxStrLen(Rec."Header Part Name"));
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Composite);
        CurrPage.Update(true);
    end;

    local procedure SetThemePart()
    var
        Composite: Text;
    begin
        if not LookupHelper.LookupCompositePart(Enum::"Report Layout Subtype"::Theme, Composite) then
            exit;
        Rec."Theme Part Name" := CopyStr(Composite, 1, MaxStrLen(Rec."Theme Part Name"));
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Composite);
        CurrPage.Update(true);
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        HeaderPartDisplay: Text;
        ThemePartDisplay: Text;
        ScopeDisplay: Text;
        ReportNameDisplay: Text;
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
        GlobalWildcardCannotHaveLayoutNameErr: Label 'When Report ID is 0, the row applies to every report, so Layout Name must be empty.';
        ScopeExistsErr: Label 'A row for %1 already exists. Change that row instead of pointing this one at the same scope.', Comment = '%1 = scope description, for example All layouts of Sales Invoice';
        PickReportFirstErr: Label 'Choose a report first. A layout belongs to one report, so there is nothing to pick from until Report ID is set.';
        AllReportsTxt: Label 'All reports';
        AllLayoutsOfReportTxt: Label 'All layouts of %1', Comment = '%1 = report name';
        LayoutInReportTxt: Label '%1 in %2', Comment = '%1 = layout name; %2 = report name';
        UnknownReportTxt: Label 'Report %1 (not installed)', Comment = '%1 = report ID';
}
