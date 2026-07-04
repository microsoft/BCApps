// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft.Foundation.Reporting;
using System.Reflection;

/// <summary>
/// Configures default report selections for cash desk. Allows users to specify which reports to use for printing, emailing, and other output operations.
/// </summary>
page 31222 "Report Sel. - Cash Desk CZP"
{
    AboutTitle = 'About report selection for cash desk';
    AboutText = 'On this page, you set up the default reports that are used when printing or emailing cash desk documents. Use the Usage field to select the type of document, then specify which reports to use in the list below.';
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Cash Desk';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage; ReportUsage)
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
                }
            }
        }
        area(factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
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
        ReportUsage: Enum "Cash Desk Rep. Sel. Usage CZP";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage of
            Enum::"Cash Desk Rep. Sel. Usage CZP"::"Cash Receipt":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Cash Receipt CZP");
            Enum::"Cash Desk Rep. Sel. Usage CZP"::"Cash Withdrawal":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Cash Withdrawal CZP");
            Enum::"Cash Desk Rep. Sel. Usage CZP"::"Posted Cash Receipt":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Posted Cash Receipt CZP");
            Enum::"Cash Desk Rep. Sel. Usage CZP"::"Posted Cash Withdrawal":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage.AsInteger());
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
                    Enum::"Report Selection Usage"::"Cash Receipt CZP":
                        ReportUsage := Enum::"Cash Desk Rep. Sel. Usage CZP"::"Cash Receipt";
                    Enum::"Report Selection Usage"::"Cash Withdrawal CZP":
                        ReportUsage := Enum::"Cash Desk Rep. Sel. Usage CZP"::"Cash Withdrawal";
                    Enum::"Report Selection Usage"::"Posted Cash Receipt CZP":
                        ReportUsage := Enum::"Cash Desk Rep. Sel. Usage CZP"::"Posted Cash Receipt";
                    Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP":
                        ReportUsage := Enum::"Cash Desk Rep. Sel. Usage CZP"::"Posted Cash Withdrawal";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Cash Desk Rep. Sel. Usage CZP")
    begin
    end;
}

