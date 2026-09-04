// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Guided dialog to assign the theme and header/footer part for a report layout. The assignment is stored in the
/// platform Tenant Report Layout Cfg table keyed by report and body layout (an empty Layout Name applies to every
/// layout of the report) with an empty Company Name, so it is administered per company/tenant — it is not a per-user
/// selection.
/// </summary>
page 9667 "Header/Footer Theme Assignment"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Set theme and header-footer';
    PageType = StandardDialog;
    SourceTable = "Tenant Report Layout Cfg";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    Permissions = tabledata "Tenant Report Layout Cfg" = RIMD;

    layout
    {
        area(content)
        {
            field("Report ID"; Rec."Report ID")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the report these defaults apply to, stored per company/tenant (not per user). Report 0 is the global default that applies to all reports.';
            }
            field(LayoutNameDisplay; LayoutNameDisplay)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Layout Name';
                Editable = false;
                ToolTip = 'Specifies the body layout these defaults apply to, so different layouts of the same report can use different themes and header/footer parts. Empty applies to all layouts of the report.';
            }
            group(CompanyOverrideGroup)
            {
                ShowCaption = false;
                Visible = CompanyOverrideExists;

                field(CompanyOverrideDisplay; CompanyOverrideDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company override';
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Style = Ambiguous;
                    ToolTip = 'Specifies a company that sets its own theme and header/footer for this layout. That setting is more specific than the one on this page, so it keeps applying in that company. Change it on the Report defaults for theme and header-footer page.';
                }
            }
            field(HeaderPartDisplay; HeaderPartDisplay)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Header/Footer Part';
                ToolTip = 'Specifies the header/footer part applied to this report''s layouts. Leave empty for none.';

                trigger OnAssistEdit()
                begin
                    SetHeaderPart();
                end;

                trigger OnValidate()
                begin
                    if HeaderPartDisplay = '' then
                        Rec."Header Part Name" := '';
                end;
            }
            field(ThemePartDisplay; ThemePartDisplay)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Theme Part';
                ToolTip = 'Specifies the theme part applied to this report''s layouts. Leave empty for none.';

                trigger OnAssistEdit()
                begin
                    SetThemePart();
                end;

                trigger OnValidate()
                begin
                    if ThemePartDisplay = '' then
                        Rec."Theme Part Name" := '';
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
#if not CLEAN29
        FeatureKeyManagement: Codeunit "Feature Key Management";
#endif
    begin
#if not CLEAN29
        if not FeatureKeyManagement.IsDocumentReportExperienceEnabled() then
            Error(FeatureNotEnabledErr);
#endif

        if (LayoutName <> '') and (not LookupHelper.IsBodyLayout(ReportID, LayoutName)) then
            Error(NotBodyLayoutErr, LookupHelper.DecodeLayoutName(LayoutName));

        DetectCompanyOverride();

        // Stage the current report-level configuration (empty Layout Name and Company Name) in a temporary record.
        // Nothing is written to the persisted Tenant Report Layout Cfg table until the dialog is closed with OK
        // (see OnQueryClosePage), so cancelling never changes the effective theme/header-footer.
        Rec.Reset();
        Rec.DeleteAll();
        Rec.Init();
        Rec."Report ID" := ReportID;
        Rec."Layout Name" := CopyStr(LookupHelper.DecodeLayoutName(LayoutName), 1, MaxStrLen(Rec."Layout Name"));
        LayoutNameDisplay := Rec."Layout Name";
        if TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '') then begin
            Rec."Header Part Name" := TenantReportLayoutCfg."Header Part Name";
            Rec."Theme Part Name" := TenantReportLayoutCfg."Theme Part Name";
        end;
        Rec.Insert();

        // Pin the card to exactly this report/layout configuration row so it opens on it and shows no prev/next navigation.
        Rec.SetRecFilter();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LayoutNameDisplay := Rec."Layout Name";
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Rec."Header Part Name");
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Rec."Theme Part Name");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        BothPartsEmpty: Boolean;
    begin
        // Persist the staged selection only when the dialog is confirmed. On Cancel the temporary record is
        // discarded and the effective configuration is left unchanged.
        if CloseAction <> Action::OK then
            exit(true);

        if CompanyOverrideExists then
            if not Confirm(OutrankedQst, false, CompanyName(), LookupHelper.DecodeLayoutName(LayoutName)) then
                exit(false);

        BothPartsEmpty := (Rec."Header Part Name" = '') and (Rec."Theme Part Name" = '');
        if TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '') then begin
            // Do not leave an empty per-report configuration row behind if the user cleared both parts.
            if BothPartsEmpty then
                TenantReportLayoutCfg.Delete(true)
            else begin
                TenantReportLayoutCfg."Header Part Name" := Rec."Header Part Name";
                TenantReportLayoutCfg."Theme Part Name" := Rec."Theme Part Name";
                TenantReportLayoutCfg.Modify(true);
            end;
        end else
            if not BothPartsEmpty then begin
                TenantReportLayoutCfg.Init();
                TenantReportLayoutCfg."Report ID" := ReportID;
                TenantReportLayoutCfg."Layout Name" := CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name"));
                TenantReportLayoutCfg."Header Part Name" := Rec."Header Part Name";
                TenantReportLayoutCfg."Theme Part Name" := Rec."Theme Part Name";
                TenantReportLayoutCfg.Insert(true);
            end;
        exit(true);
    end;

    local procedure SetHeaderPart()
    var
        Composite: Text;
    begin
        if not LookupHelper.LookupCompositePart(Enum::"Report Layout Subtype"::HeaderFooter, Composite) then
            exit;
        Rec."Header Part Name" := CopyStr(Composite, 1, MaxStrLen(Rec."Header Part Name"));
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Composite);
        Rec.Modify();
        CurrPage.Update(false);
    end;

    local procedure SetThemePart()
    var
        Composite: Text;
    begin
        if not LookupHelper.LookupCompositePart(Enum::"Report Layout Subtype"::Theme, Composite) then
            exit;
        Rec."Theme Part Name" := CopyStr(Composite, 1, MaxStrLen(Rec."Theme Part Name"));
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Composite);
        Rec.Modify();
        CurrPage.Update(false);
    end;

    local procedure DetectCompanyOverride()
    var
        Cfg: Record "Tenant Report Layout Cfg";
        HeaderText: Text;
        ThemeText: Text;
    begin
        CompanyOverrideExists := false;
        CompanyOverrideDisplay := '';

        if LayoutName = '' then
            exit;

        if not Cfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(Cfg."Layout Name")), CopyStr(CompanyName(), 1, MaxStrLen(Cfg."Company Name"))) then
            exit;

        HeaderText := LookupHelper.DecodeLayoutName(Cfg."Header Part Name");
        if HeaderText = '' then
            HeaderText := OverrideNoHeaderTxt
        else
            HeaderText := StrSubstNo(OverrideHeaderLbl, HeaderText);

        ThemeText := LookupHelper.DecodeLayoutName(Cfg."Theme Part Name");
        if ThemeText = '' then
            ThemeText := OverrideNoThemeTxt
        else
            ThemeText := StrSubstNo(OverrideThemeLbl, ThemeText);

        CompanyOverrideExists := true;
        CompanyOverrideDisplay := StrSubstNo(CompanyOverrideLbl, CompanyName(), HeaderText, ThemeText);
    end;

    internal procedure SetLayout(NewReportID: Integer; NewLayoutName: Text)
    begin
        ReportID := NewReportID;
        LayoutName := NewLayoutName;
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        ReportID: Integer;
        LayoutName: Text;
        LayoutNameDisplay: Text;
        CompanyOverrideDisplay: Text;
        CompanyOverrideExists: Boolean;
        HeaderPartDisplay: Text;
        ThemePartDisplay: Text;
#if not CLEAN29
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
#endif
        NotBodyLayoutErr: Label 'A theme and header/footer can only be set on a body layout, and "%1" is not one. They are merged onto a body layout when the report renders, so there is nothing to merge them onto here.', Comment = '%1 = layout name';
        CompanyOverrideLbl: Label '%1 sets its own theme and header/footer for this layout: %2 and %3. That is more specific than the setting below, so it keeps applying in %1 whatever you choose here.', Comment = '%1 = company name; %2 = header/footer part name; %3 = theme part name';
        OverrideHeaderLbl: Label 'header/footer %1', Comment = '%1 = header/footer part name';
        OverrideThemeLbl: Label 'theme %1', Comment = '%1 = theme part name';
        OverrideNoHeaderTxt: Label 'no header/footer';
        OverrideNoThemeTxt: Label 'no theme';
        OutrankedQst: Label 'In %1, "%2" has its own theme and header/footer, set for that company only. That setting is more specific, so it keeps applying there whatever you choose here. Save this setting for all other companies anyway?', Comment = '%1 = company name; %2 = layout name';
}
