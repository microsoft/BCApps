// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 347 "Report Selection - Purchase"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Purchase';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';

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
                    ApplicationArea = Basic, Suite;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                }
                field("Use for Email Body"; Rec."Use for Email Body")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Use for Email Attachment"; Rec."Use for Email Attachment")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(EmailBodyName; Rec."Email Body Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(EmailBodyPublisher; Rec."Email Body Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(ReportLayoutName; Rec."Report Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(EmailLayoutCaption; Rec."Email Body Layout Caption")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToSelectLayout(Rec."Email Body Layout Name", Rec."Email Body Layout AppID");
                        CurrPage.Update(true);
                    end;
                }
                field(ReportLayoutCaption; Rec."Report Layout Caption")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToSelectLayout(Rec."Report Layout Name", Rec."Report Layout AppID");
                        CurrPage.Update(true);
                    end;
                }
                field(ReportLayoutPublisher; Rec."Report Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Email Body Layout Code"; Rec."Email Body Layout Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Email Body Layout Description"; Rec."Email Body Layout Description")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        CustomReportLayout: Record "Custom Report Layout";
                    begin
                        if CustomReportLayout.LookupLayoutOK(Rec."Report ID") then
                            Rec.Validate("Email Body Layout Code", CustomReportLayout.Code);
                    end;
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
        ReportUsage2: Enum "Report Selection Usage Purchase";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::Quote:
                Rec.SetRange(Usage, Rec.Usage::"P.Quote");
            ReportUsage2::"Blanket Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Blanket");
            ReportUsage2::Order:
                Rec.SetRange(Usage, Rec.Usage::"P.Order");
            ReportUsage2::Invoice:
                Rec.SetRange(Usage, Rec.Usage::"P.Invoice");
            ReportUsage2::"Return Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Return");
            ReportUsage2::"Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::"P.Cr.Memo");
            ReportUsage2::Receipt:
                Rec.SetRange(Usage, Rec.Usage::"P.Receipt");
            ReportUsage2::"Return Shipment":
                Rec.SetRange(Usage, Rec.Usage::"P.Ret.Shpt.");
            ReportUsage2::"Purchase Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"P.Test");
            ReportUsage2::"Prepayment Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"P.Test Prepmt.");
            ReportUsage2::"Archived Quote":
                Rec.SetRange(Usage, Rec.Usage::"P.Arch.Quote");
            ReportUsage2::"Archived Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Arch.Order");
            ReportUsage2::"Archived Return Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Arch.Return");
            ReportUsage2::"Archived Blanket Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Arch.Blanket");
            ReportUsage2::"Vendor Remittance":
                Rec.SetRange(Usage, Rec.Usage::"V.Remittance");
            ReportUsage2::"Vendor Remittance - Posted Entries":
                Rec.SetRange(Usage, Rec.Usage::"P.V.Remit.");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        NewReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(NewReportUsage, Rec.GetFilter(Usage)) then
                case NewReportUsage of
                    NewReportUsage::"P.Quote":
                        ReportUsage2 := ReportUsage2::Quote;
                    NewReportUsage::"P.Blanket":
                        ReportUsage2 := ReportUsage2::"Blanket Order";
                    NewReportUsage::"P.Order":
                        ReportUsage2 := ReportUsage2::Order;
                    NewReportUsage::"P.Invoice":
                        ReportUsage2 := ReportUsage2::Invoice;
                    NewReportUsage::"P.Return":
                        ReportUsage2 := ReportUsage2::"Return Order";
                    NewReportUsage::"P.Cr.Memo":
                        ReportUsage2 := ReportUsage2::"Credit Memo";
                    NewReportUsage::"P.Receipt":
                        ReportUsage2 := ReportUsage2::Receipt;
                    NewReportUsage::"P.Ret.Shpt.":
                        ReportUsage2 := ReportUsage2::"Return Shipment";
                    NewReportUsage::"P.Test":
                        ReportUsage2 := ReportUsage2::"Purchase Document - Test";
                    NewReportUsage::"P.Test Prepmt.":
                        ReportUsage2 := ReportUsage2::"Prepayment Document - Test";
                    NewReportUsage::"P.Arch.Quote":
                        ReportUsage2 := ReportUsage2::"Archived Quote";
                    NewReportUsage::"P.Arch.Order":
                        ReportUsage2 := ReportUsage2::"Archived Order";
                    NewReportUsage::"P.Arch.Return":
                        ReportUsage2 := ReportUsage2::"Archived Return Order";
                    NewReportUsage::"P.Arch.Blanket",
                    NewReportUsage::"S.Arch.Blanket": // Wrong enum case kept here to avoid semantically breaking change (BUG 448278)
                        ReportUsage2 := ReportUsage2::"Archived Blanket Order";
                    NewReportUsage::"V.Remittance":
                        ReportUsage2 := ReportUsage2::"Vendor Remittance";
                    NewReportUsage::"P.V.Remit.":
                        ReportUsage2 := ReportUsage2::"Vendor Remittance";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Purchase")
    begin
    end;
}

