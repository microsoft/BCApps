// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 5754 "Report Selection - Inventory"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Inventory';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Tasks;

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
        ReportUsage2: Enum "Report Selection Usage Inventory";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Inventory"::"Transfer Order":
                Rec.SetRange(Usage, Rec.Usage::Inv1);
            "Report Selection Usage Inventory"::"Transfer Shipment":
                Rec.SetRange(Usage, Rec.Usage::Inv2);
            "Report Selection Usage Inventory"::"Transfer Receipt":
                Rec.SetRange(Usage, Rec.Usage::Inv3);
            "Report Selection Usage Inventory"::"Inventory Period Test":
                Rec.SetRange(Usage, Rec.Usage::"Invt.Period Test");
            "Report Selection Usage Inventory"::"Assembly Order":
                Rec.SetRange(Usage, Rec.Usage::"Asm.Order");
            "Report Selection Usage Inventory"::"Posted Assembly Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Asm.Order");
            "Report Selection Usage Inventory"::"Phys. Invt. Order":
                Rec.SetRange(Usage, Rec.Usage::"Phys.Invt.Order");
            "Report Selection Usage Inventory"::"Phys. Invt. Order Test":
                Rec.SetRange(Usage, Rec.Usage::"Phys.Invt.Order Test");
            "Report Selection Usage Inventory"::"Phys. Invt. Recording":
                Rec.SetRange(Usage, Rec.Usage::"Phys.Invt.Rec.");
            "Report Selection Usage Inventory"::"Posted Phys. Invt. Order":
                Rec.SetRange(Usage, Rec.Usage::"P.Phys.Invt.Order");
            "Report Selection Usage Inventory"::"Posted Phys. Invt. Recording":
                Rec.SetRange(Usage, Rec.Usage::"P.Phys.Invt.Rec.");
            "Report Selection Usage Inventory"::"Direct Transfer":
                Rec.SetRange(Usage, Rec.Usage::"P.Direct Transfer");
            "Report Selection Usage Inventory"::"Inventory Receipt":
                Rec.SetRange(Usage, Rec.Usage::"Inventory Receipt");
            "Report Selection Usage Inventory"::"Inventory Shipment":
                Rec.SetRange(Usage, Rec.Usage::"Inventory Shipment");
            "Report Selection Usage Inventory"::"Posted Inventory Receipt":
                Rec.SetRange(Usage, Rec.Usage::"P.Inventory Receipt");
            "Report Selection Usage Inventory"::"Posted Inventory Shipment":
                Rec.SetRange(Usage, Rec.Usage::"P.Inventory Shipment");
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
                    NewReportUsage::"Inv1":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Transfer Order";
                    NewReportUsage::"Inv2":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Transfer Shipment";
                    NewReportUsage::"Inv3":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Transfer Receipt";
                    NewReportUsage::"Invt.Period Test":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Inventory Period Test";
                    NewReportUsage::"Asm.Order":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Assembly Order";
                    NewReportUsage::"P.Asm.Order":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Posted Assembly Order";
                    NewReportUsage::"Phys.Invt.Order":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Phys. Invt. Order";
                    NewReportUsage::"Phys.Invt.Order Test":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Phys. Invt. Order Test";
                    NewReportUsage::"Phys.Invt.Rec.":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Phys. Invt. Recording";
                    NewReportUsage::"P.Phys.Invt.Order":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Posted Phys. Invt. Order";
                    NewReportUsage::"P.Phys.Invt.Rec.":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Posted Phys. Invt. Recording";
                    NewReportUsage::"P.Direct Transfer":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Direct Transfer";
                    NewReportUsage::"Inventory Receipt":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Inventory Receipt";
                    NewReportUsage::"Inventory Shipment":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Inventory Shipment";
                    NewReportUsage::"P.Inventory Receipt":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Posted Inventory Receipt";
                    NewReportUsage::"P.Inventory Shipment":
                        ReportUsage2 := "Report Selection Usage Inventory"::"Posted Inventory Shipment";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Inventory")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Inventory")
    begin
    end;
}

