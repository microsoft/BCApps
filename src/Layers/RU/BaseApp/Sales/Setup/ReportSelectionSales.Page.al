// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

/// <summary>
/// Configures default report selections for sales document types. Allows users to specify which reports to use for printing, emailing, and other output operations.
/// </summary>
page 306 "Report Selection - Sales"
{
    AboutTitle = 'About report selection for sales';
    AboutText = 'On this page, you set up the default reports that are used when printing or emailing sales documents such as quotes, orders, invoices, and credit memos. Use the Usage field to select the type of document, then specify which reports to use in the list below.';
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Sales';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage; ReportUsage2)
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
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the report ID is the default for the report selection.';
                }
                field("Excel Export"; Rec."Excel Export")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the report selection will be exported.';
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
        ReportUsage2: Enum "Report Selection Usage Sales";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Sales"::Quote:
                Rec.SetRange(Usage, Rec.Usage::"S.Quote");
            "Report Selection Usage Sales"::"Blanket Order":
                Rec.SetRange(Usage, Rec.Usage::"S.Blanket");
            "Report Selection Usage Sales"::Order:
                Rec.SetRange(Usage, Rec.Usage::"S.Order");
            "Report Selection Usage Sales"::"Work Order":
                Rec.SetRange(Usage, Rec.Usage::"S.Work Order");
            "Report Selection Usage Sales"::"Pick Instruction":
                Rec.SetRange(Usage, Rec.Usage::"S.Order Pick Instruction");
            "Report Selection Usage Sales"::Invoice:
                Rec.SetRange(Usage, Rec.Usage::"S.Invoice");
            "Report Selection Usage Sales"::"Draft Invoice":
                Rec.SetRange(Usage, Rec.Usage::"S.Invoice Draft");
            "Report Selection Usage Sales"::"Return Order":
                Rec.SetRange(Usage, Rec.Usage::"S.Return");
            "Report Selection Usage Sales"::"Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::"S.Cr.Memo");
            "Report Selection Usage Sales"::Shipment:
                Rec.SetRange(Usage, Rec.Usage::"S.Shipment");
            "Report Selection Usage Sales"::"Return Receipt":
                Rec.SetRange(Usage, Rec.Usage::"S.Ret.Rcpt.");
            "Report Selection Usage Sales"::"Sales Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"S.Test");
            "Report Selection Usage Sales"::"Prepayment Document - Test":
                Rec.SetRange(Usage, Rec.Usage::"S.Test Prepmt.");
            "Report Selection Usage Sales"::"Archived Quote":
                Rec.SetRange(Usage, Rec.Usage::"S.Arch.Quote");
            "Report Selection Usage Sales"::"Archived Order":
                Rec.SetRange(Usage, Rec.Usage::"S.Arch.Order");
            "Report Selection Usage Sales"::"Archived Return Order":
                Rec.SetRange(Usage, Rec.Usage::"S.Arch.Return");
            "Report Selection Usage Sales"::"Customer Statement":
                Rec.SetRange(Usage, Rec.Usage::"C.Statement");
            "Report Selection Usage Sales"::"Pro Forma Invoice":
                Rec.SetRange(Usage, Rec.Usage::"Pro Forma S. Invoice");
            "Report Selection Usage Sales"::"Archived Blanket Order":
                Rec.SetRange(Usage, Rec.Usage::"S.Arch.Blanket");
            "Report Selection Usage Sales"::"UnPosted Invoice":
                Rec.SetRange(Usage, Rec.Usage::USI);
            "Report Selection Usage Sales"::"UnPosted Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::USCM);
            "Report Selection Usage Sales"::"UnPosted Corr. Invoice":
                Rec.SetRange(Usage, Rec.Usage::UCSD);
            "Report Selection Usage Sales"::"Corr. Invoice":
                Rec.SetRange(Usage, Rec.Usage::CSI);
            "Report Selection Usage Sales"::"Corr. Credit Memo":
                Rec.SetRange(Usage, Rec.Usage::CSCM);
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2.AsInteger());
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
                    NewReportUsage::"S.Quote":
                        ReportUsage2 := "Report Selection Usage Sales"::Quote;
                    NewReportUsage::"S.Blanket":
                        ReportUsage2 := "Report Selection Usage Sales"::"Blanket Order";
                    NewReportUsage::"S.Order":
                        ReportUsage2 := "Report Selection Usage Sales"::Order;
                    NewReportUsage::"S.Work Order":
                        ReportUsage2 := "Report Selection Usage Sales"::"Work Order";
                    NewReportUsage::"S.Order Pick Instruction":
                        ReportUsage2 := "Report Selection Usage Sales"::"Pick Instruction";
                    NewReportUsage::"S.Invoice":
                        ReportUsage2 := "Report Selection Usage Sales"::Invoice;
                    NewReportUsage::"S.Invoice Draft":
                        ReportUsage2 := "Report Selection Usage Sales"::"Draft Invoice";
                    NewReportUsage::"S.Return":
                        ReportUsage2 := "Report Selection Usage Sales"::"Return Order";
                    NewReportUsage::"S.Cr.Memo":
                        ReportUsage2 := "Report Selection Usage Sales"::"Credit Memo";
                    NewReportUsage::"S.Shipment":
                        ReportUsage2 := "Report Selection Usage Sales"::Shipment;
                    NewReportUsage::"S.Ret.Rcpt.":
                        ReportUsage2 := "Report Selection Usage Sales"::"Return Receipt";
                    NewReportUsage::"S.Test":
                        ReportUsage2 := "Report Selection Usage Sales"::"Sales Document - Test";
                    NewReportUsage::"S.Test Prepmt.":
                        ReportUsage2 := "Report Selection Usage Sales"::"Prepayment Document - Test";
                    NewReportUsage::"S.Arch.Quote":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Quote";
                    NewReportUsage::"S.Arch.Order":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Order";
                    NewReportUsage::"S.Arch.Return":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Return Order";
                    NewReportUsage::"C.Statement":
                        ReportUsage2 := "Report Selection Usage Sales"::"Customer Statement";
                    NewReportUsage::"Pro Forma S. Invoice":
                        ReportUsage2 := "Report Selection Usage Sales"::"Pro Forma Invoice";
                    NewReportUsage::"S.Arch.Blanket":
                        ReportUsage2 := "Report Selection Usage Sales"::"Archived Blanket Order";
                    NewReportUsage::USI:
                        ReportUsage2 := "Report Selection Usage Sales"::"UnPosted Invoice";
                    NewReportUsage::USCM:
                        ReportUsage2 := "Report Selection Usage Sales"::"UnPosted Credit Memo";
                    NewReportUsage::UCSD:
                        ReportUsage2 := "Report Selection Usage Sales"::"UnPosted Corr. Invoice";
                    NewReportUsage::CSI:
                        ReportUsage2 := "Report Selection Usage Sales"::"Corr. Invoice";
                    NewReportUsage::CSCM:
                        ReportUsage2 := "Report Selection Usage Sales"::"Corr. Credit Memo";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Sales")
    begin
    end;
}

