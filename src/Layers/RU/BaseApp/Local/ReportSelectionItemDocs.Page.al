#pragma warning disable AA0247
page 12454 "Report Selection - Item. Docs"
{
    AboutTitle = 'About report selection for item documents';
    AboutText = 'On this page, you set up the default reports that are used when printing item documents such as shipments, receipts, physical inventory, and reclassifications. Use the Usage field to select the type of document, then specify which reports to use in the list below.';
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Item Documents';
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
                OptionCaption = 'Unposted Item Shipment,Unposted Item Receipt,Item Shipment,Item Receipt,Phys. Inventory,Item Reclassification';

                trigger OnValidate()
                begin
                    SetUsageFilter();
                    ReportUsage2OnAfterValidate();
                end;
            }
            repeater(Control1)
            {
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
        SetUsageFilter();
    end;

    var
        ReportUsage2: Option "Unposted Item Shipment","Unposted Item Receipt","Item Shipment","Item Receipt","Phys. Inventory","Item Reclassification";

    local procedure SetUsageFilter()
    begin
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Unposted Item Shipment":
                Rec.SetRange(Usage, Rec.Usage::"Inventory Shipment");
            ReportUsage2::"Unposted Item Receipt":
                Rec.SetRange(Usage, Rec.Usage::"Inventory Receipt");
            ReportUsage2::"Item Shipment":
                Rec.SetRange(Usage, Rec.Usage::"P.Inventory Shipment");
            ReportUsage2::"Item Receipt":
                Rec.SetRange(Usage, Rec.Usage::"P.Inventory Receipt");
            ReportUsage2::"Phys. Inventory":
                Rec.SetRange(Usage, Rec.Usage::PIJ);
            ReportUsage2::"Item Reclassification":
                Rec.SetRange(Usage, Rec.Usage::IRJ);
        end;
        Rec.FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

