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
    Caption = 'Report defaults for theme and header-footer';
    AdditionalSearchTerms = 'Composite Layout, Document Theme, Header Footer Part, Tenant Report Layout Configuration';
    PageType = List;
    SourceTable = "Tenant Report Layout Cfg";
    UsageCategory = Administration;
    Editable = true;
    InsertAllowed = false;
    Extensible = false;
    Permissions = tabledata "Tenant Report Layout Cfg" = RIMD;
    AboutTitle = 'Report defaults for theme and header-footer';
    AboutText = 'Set the theme and header/footer a report uses when its own layout specifies neither. Read **Applies to** to see what each row covers. Choose **Set for one report** or **Set for one layout** to add a scope — you pick from a list of body layouts, so you don''t need to know an ID or a layout name. **Add global default** adds the row that covers everything, and is available only while that row is missing. Fill in **Company Name** to limit a row to one company. Where scopes overlap, the most specific one applies.';

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

                        if Rec."Report ID" <> PickedLayout."Report ID" then begin
                            Rec."Layout Name" := '';
                            LayoutNameDisplay := '';
                        end;
                        Rec."Report ID" := PickedLayout."Report ID";
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
                field(LayoutNameDisplay; LayoutNameDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Layout Name';
                    Editable = false;
                    ToolTip = 'Specifies the body layout this row applies to. Empty applies to every layout of the report. Use the assist-edit (...) to pick one of the report''s body layouts.';

                    trigger OnAssistEdit()
                    var
                        PickedLayout: Record "Report Layout List";
                    begin
                        if Rec."Report ID" = 0 then
                            Error(PickReportFirstErr);

                        if not LookupBodyLayout(Rec."Report ID", PickedLayout) then
                            exit;

                        Rec."Layout Name" := CopyStr(LookupHelper.CompositeLayoutKey(PickedLayout), 1, MaxStrLen(Rec."Layout Name"));
                        LayoutNameDisplay := LookupHelper.DecodeLayoutName(Rec."Layout Name");
                        ValidateScopeChange();
                        CurrPage.Update(true);
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
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
                Caption = 'Add global default';
                Image = New;
                ToolTip = 'Add the row that applies to every report and every layout, the fallback used when nothing more specific is set. Goes to that row when it already exists.';

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
            action(WidenToAllLayouts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply to all layouts';
                Image = ExpandAll;
                Enabled = LayoutScopeSet;
                ToolTip = 'Widen this row so it applies to every layout of the report instead of the one named. Available when the row names a layout.';

                trigger OnAction()
                var
                    Cfg: Record "Tenant Report Layout Cfg";
                begin
                    if Rec."Layout Name" = '' then
                        exit;

                    if Cfg.Get(Rec."Report ID", '', Rec."Company Name") then
                        RaiseScopeExistsError(Cfg);

                    Rec.Rename(Rec."Report ID", '', Rec."Company Name");
                    CurrPage.Update(false);
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

                    EnsureScopeRow(PickedLayout."Report ID", CopyStr(LookupHelper.CompositeLayoutKey(PickedLayout), 1, MaxStrLen(Rec."Layout Name")));
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

    trigger OnAfterGetCurrRecord()
    begin
        LayoutScopeSet := Rec."Layout Name" <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        ScopeDisplay := ScopeDescription();
        LayoutNameDisplay := LookupHelper.DecodeLayoutName(Rec."Layout Name");
        ReportNameDisplay := ReportDisplayName(Rec."Report ID");

        // The Header/Theme Part Name columns store the composite reference (<guid>::<name>); decode to the
        // plain layout name for display so the list shows names instead of the raw GUID-prefixed value.
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Rec."Header Part Name");
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Rec."Theme Part Name");
    end;

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

        exit(StrSubstNo(LayoutInReportTxt, LookupHelper.DecodeLayoutName(LayoutName), ReportDisplayName(ReportID)));
    end;

    local procedure ValidateScopeChange()
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        if (Rec."Report ID" = 0) and (Rec."Layout Name" <> '') then
            Error(GlobalWildcardCannotHaveLayoutNameErr);

        if (Rec."Layout Name" <> '') and (not LookupHelper.IsBodyLayout(Rec."Report ID", Rec."Layout Name")) then
            Error(
                LayoutNotOnReportErr,
                LookupHelper.DecodeLayoutName(Rec."Layout Name"),
                ReportDisplayName(Rec."Report ID"));

        if (Rec."Report ID" = xRec."Report ID") and
           (Rec."Layout Name" = xRec."Layout Name") and
           (Rec."Company Name" = xRec."Company Name")
        then
            exit;

        if Cfg.Get(Rec."Report ID", Rec."Layout Name", Rec."Company Name") then
            RaiseScopeExistsError(Cfg);
    end;

    local procedure RaiseScopeExistsError(ExistingRow: Record "Tenant Report Layout Cfg")
    var
        ScopeError: ErrorInfo;
    begin
        ScopeError.Message := StrSubstNo(ScopeExistsErr, ScopeDescriptionFor(ExistingRow."Report ID", ExistingRow."Layout Name"));
        ScopeError.DataClassification := DataClassification::SystemMetadata;
        ScopeError.RecordId := ExistingRow.RecordId();
        ScopeError.PageNo := Page::"Tenant Report Layout Cfg";
        Error(ScopeError);
    end;

    local procedure ReportDisplayName(ReportID: Integer): Text
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportID = 0 then
            exit('');

        if not ReportMetadata.Get(ReportID) then
            exit(StrSubstNo(UnknownReportTxt, ReportID));

        if ReportMetadata.Caption <> '' then
            exit(ReportMetadata.Caption);
        exit(ReportMetadata.Name);
    end;

    local procedure LookupBodyLayout(ReportIDFilter: Integer; var PickedLayout: Record "Report Layout List"): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayouts: Page "Report Layouts";
    begin
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", ReportLayoutList."Layout Subtype"::Body);
        if ReportIDFilter <> 0 then
            ReportLayoutList.SetRange("Report ID", ReportIDFilter);

        if ReportLayoutList.IsEmpty() then begin
            if ReportIDFilter = 0 then
                Message(NoBodyLayoutsAtAllMsg)
            else
                Message(NoBodyLayoutsForReportMsg, ReportDisplayName(ReportIDFilter));
            exit(false);
        end;

        ReportLayouts.SetTableView(ReportLayoutList);
        ReportLayouts.SetIncludeUnapproved();
        ReportLayouts.LookupMode(true);
        if ReportLayouts.RunModal() <> Action::LookupOK then
            exit(false);

        ReportLayouts.GetRecord(PickedLayout);
        exit(true);
    end;

    local procedure EnsureScopeRow(ReportID: Integer; LayoutName: Text[250])
    var
        Cfg: Record "Tenant Report Layout Cfg";
    begin
        if not Cfg.Get(ReportID, LayoutName, '') then begin
            Cfg.Init();
            Cfg."Report ID" := ReportID;
            Cfg."Layout Name" := LayoutName;
            Cfg."Company Name" := '';
            Cfg.Insert(true);
        end;

        if not RowPassesReportFilter(ReportID) then
            Rec.SetRange("Report ID");

        Rec := Cfg;
        CurrPage.SetRecord(Rec);
        CurrPage.Update(false);
    end;

    local procedure RowPassesReportFilter(ReportID: Integer): Boolean
    var
        Probe: Record "Tenant Report Layout Cfg";
    begin
        if Rec.GetFilter("Report ID") = '' then
            exit(true);

        Probe.SetView(Rec.GetView());
        Probe.FilterGroup(4);
        Probe.SetRange("Report ID", ReportID);
        Probe.FilterGroup(0);
        exit(not Probe.IsEmpty());
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
        LayoutNameDisplay: Text;
        LayoutScopeSet: Boolean;
        ReportNameDisplay: Text;
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
        GlobalWildcardCannotHaveLayoutNameErr: Label 'When Report ID is 0, the row applies to every report, so Layout Name must be empty.';
        ScopeExistsErr: Label 'A row for %1 already exists. Change that row instead of pointing this one at the same scope.', Comment = '%1 = scope description, for example All layouts of Sales Invoice';
        PickReportFirstErr: Label 'Choose a report first. A layout belongs to one report, so there is nothing to pick from until Report ID is set.';
        LayoutNotOnReportErr: Label '"%1" is not a body layout of %2. Clear Layout Name to cover every layout of that report, or use the assist-edit to pick one of its body layouts.', Comment = '%1 = layout name; %2 = report name';
        NoBodyLayoutsForReportMsg: Label 'There are no body layouts on %1, so there is nothing to set a theme or header/footer on. A Word layout has to be created with the Body subtype to carry them.', Comment = '%1 = report name';
        NoBodyLayoutsAtAllMsg: Label 'There are no body layouts on this tenant, so there is nothing to set a theme or header/footer on. A Word layout has to be created with the Body subtype to carry them.';
        AllReportsTxt: Label 'All reports';
        AllLayoutsOfReportTxt: Label 'All layouts of %1', Comment = '%1 = report name';
        LayoutInReportTxt: Label '%1 in %2', Comment = '%1 = layout name; %2 = report name';
        UnknownReportTxt: Label 'Report %1 (not installed)', Comment = '%1 = report ID';
}
