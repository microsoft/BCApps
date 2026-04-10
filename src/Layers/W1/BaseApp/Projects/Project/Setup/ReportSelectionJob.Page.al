// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 307 "Report Selection - Job"
{
    AboutTitle = 'About report selection for projects';
    AboutText = 'On this page, you set up the default reports that are used when printing or emailing project documents such as quotes. Use the Usage field to select the type of document, then specify which reports to use in the list below.';
    AdditionalSearchTerms = 'Report Selection - Job';
    Caption = 'Report Selection - Project';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;
    ApplicationArea = Jobs;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';
                ApplicationArea = Jobs;

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                FreezeColumn = "Report Caption";
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Jobs;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Jobs;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related document will be attached to the email.';
                }
                field(EmailBodyName; Rec."Email Body Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the email body layout that is used.';
                    Visible = false;
                }
                field(EmailBodyPublisher; Rec."Email Body Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the publisher of the email body layout that is used.';
                    Visible = false;
                }
                field(ReportLayoutName; Rec."Report Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the report layout that is used.';
                    Visible = false;
                }
                field(EmailLayoutCaption; Rec."Email Body Layout Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the email body layout that is used.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToSelectLayout(Rec."Email Body Layout Name", Rec."Email Body Layout AppID");
                        CurrPage.Update(true);
                    end;
                }
                field(ReportLayoutCaption; Rec."Report Layout Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report layout that is used.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToSelectLayout(Rec."Report Layout Name", Rec."Report Layout AppID");
                        CurrPage.Update(true);
                    end;
                }
                field(ReportLayoutPublisher; Rec."Report Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the publisher of the report layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the custom email body layout that is used.';
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the custom email body layout that is used.';
                    Visible = false;

#if not CLEAN28
                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
#pragma warning disable AL0432
                        if CustomReportLayout.LookupLayoutOK(Rec."Report ID") then
#pragma warning restore AL0432
                            Rec.Validate("Email Body Layout Code", CustomReportLayout.Code);
                    end;
#endif
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Job";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                Rec.SetRange(Usage, Rec.Usage::JQ);
            ReportUsage2::"Task Quote":
                Rec.SetRange(Usage, Rec.Usage::"Job Task Quote");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        ReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(ReportUsage, Rec.GetFilter(Usage)) then
                case ReportUsage of
                    ReportUsage::JQ:
                        ReportUsage2 := ReportUsage2::Quote;
                    ReportUsage::"Job Task Quote":
                        ReportUsage2 := ReportUsage2::"Task Quote";
                    else
                        OnInitUsageFilterOnElseCase(ReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Job")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Job")
    begin
    end;
}
