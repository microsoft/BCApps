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
    Caption = 'Assign Theme and Header/Footer';
    PageType = StandardDialog;
    SourceTable = "Tenant Report Layout Cfg";
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
            field("Layout Name"; Rec."Layout Name")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the body layout these defaults apply to, so different layouts of the same report can use different themes and header/footer parts. Empty applies to all layouts of the report.';
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
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if not FeatureKeyManagement.IsDocumentReportExperienceEnabled() then
            Error(FeatureNotEnabledErr);

        // Get-or-create the report-level configuration row (empty Layout Name and Company Name). This page declares
        // RIMD on the Cfg table, so the privileged insert happens here rather than in the calling page.
        if not Rec.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(Rec."Layout Name")), '') then begin
            Rec.Init();
            Rec."Report ID" := ReportID;
            Rec."Layout Name" := CopyStr(LayoutName, 1, MaxStrLen(Rec."Layout Name"));
            Rec.Insert(true);
        end;

        // Pin the card to exactly this report/layout configuration row so it opens on it and shows no prev/next navigation.
        Rec.SetRecFilter();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HeaderPartDisplay := LookupHelper.DecodeLayoutName(Rec."Header Part Name");
        ThemePartDisplay := LookupHelper.DecodeLayoutName(Rec."Theme Part Name");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        // Do not leave an empty per-report configuration row behind if the user cleared both parts.
        if (Rec."Header Part Name" = '') and (Rec."Theme Part Name" = '') then
            if Rec.Find() then
                Rec.Delete(true);
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

    internal procedure SetLayout(NewReportID: Integer; NewLayoutName: Text)
    begin
        ReportID := NewReportID;
        LayoutName := NewLayoutName;
    end;

    var
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        ReportID: Integer;
        LayoutName: Text;
        HeaderPartDisplay: Text;
        ThemePartDisplay: Text;
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
}
