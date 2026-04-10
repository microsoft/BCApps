// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.WorkCenter;

page 5408 "Prod. Order Routing Lines"
{
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order Routing Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Prod. Order Routing Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production order to which the routing list belongs.';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Schedule Manually"; Rec."Schedule Manually")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the setup time of the operation.';
                    Visible = false;
                }
                field("Run Time"; Rec."Run Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Run Time Unit of Meas. Code"; Rec."Run Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit of measure code that applies to the run time of the operation.';
                    Visible = false;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of items that are included in the same operation at the same time. The run time on routing lines is reduced proportionally to the lot size. For example, if the lot size is two pieces, the run time will be reduced by half.';
                    Visible = false;
                }
                field("Expected Operation Cost Amt."; Rec."Expected Operation Cost Amt.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Expected Capacity Ovhd. Cost"; Rec."Expected Capacity Ovhd. Cost")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Expected Capacity Need"; Rec."Expected Capacity Need" / ExpCapacityNeed())
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 0;
                    Caption = 'Expected Capacity Need';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the expected capacity need for the production order.';
                    Visible = false;
                }
                field("Routing Status"; Rec."Routing Status")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field("Open Shop Floor Bin Code"; Rec."Open Shop Floor Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("To-Production Bin Code"; Rec."To-Production Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("From-Production Bin Code"; Rec."From-Production Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Posted Output Quantity"; Rec."Posted Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Posted Scrap Quantity"; Rec."Posted Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Posted Run Time"; Rec."Posted Run Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Posted Setup Time"; Rec."Posted Setup Time")
                {
                    ApplicationArea = Manufacturing;
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

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ShowDocument)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        ProdOrder.Get(Rec.Status, Rec."Prod. Order No.");
                        case Rec.Status of
                            Rec.Status::Planned:
                                PAGE.Run(PAGE::"Planned Production Order", ProdOrder);
                            Rec.Status::"Firm Planned":
                                PAGE.Run(PAGE::"Firm Planned Prod. Order", ProdOrder);
                            Rec.Status::Released:
                                PAGE.Run(PAGE::"Released Production Order", ProdOrder);
                        end;
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Rtng. Cmt. Sh.";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("Prod. Order No."),
                                  "Routing Reference No." = field("Routing Reference No."),
                                  "Routing No." = field("Routing No."),
                                  "Operation No." = field("Operation No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Tools)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Tools';
                    Image = Tools;
                    RunObject = Page "Prod. Order Routing Tools";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("Prod. Order No."),
                                  "Routing Reference No." = field("Routing Reference No."),
                                  "Routing No." = field("Routing No."),
                                  "Operation No." = field("Operation No.");
                    ToolTip = 'View or edit information about tools that apply to operations that represent the standard task.';
                }
                action(Personnel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Personnel';
                    Image = User;
                    RunObject = Page "Prod. Order Routing Personnel";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("Prod. Order No."),
                                  "Routing Reference No." = field("Routing Reference No."),
                                  "Routing No." = field("Routing No."),
                                  "Operation No." = field("Operation No.");
                    ToolTip = 'View or edit information about personnel that applies to operations that represent the standard task.';
                }
                action("Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Quality Measures';
                    Image = TaskQualityMeasure;
                    RunObject = Page "Prod. Order Rtng Qlty Meas.";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("Prod. Order No."),
                                  "Routing Reference No." = field("Routing Reference No."),
                                  "Routing No." = field("Routing No."),
                                  "Operation No." = field("Operation No.");
                    ToolTip = 'View or edit information about quality measures that apply to operations that represent the standard task.';
                }
                action("Allocated Capacity")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Allocated Capacity';
                    Image = AllocatedCapacity;
                    ToolTip = 'View the capacity need, which is the sum of the setup time and the run time. The run time is equal to the run time per piece multiplied by the number of pieces in the production order.';

                    trigger OnAction()
                    var
                        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                    begin
                        if Rec.Status = Rec.Status::Finished then
                            exit;
                        ProdOrderCapNeed.SetCurrentKey(Type, "No.", "Starting Date-Time");
                        ProdOrderCapNeed.SetRange(Type, Rec.Type);
                        ProdOrderCapNeed.SetRange("No.", Rec."No.");
                        ProdOrderCapNeed.SetRange(Date, Rec."Starting Date", Rec."Ending Date");
                        ProdOrderCapNeed.SetRange("Prod. Order No.", Rec."Prod. Order No.");
                        ProdOrderCapNeed.SetRange(Status, Rec.Status);
                        ProdOrderCapNeed.SetRange("Routing Reference No.", Rec."Routing Reference No.");
                        ProdOrderCapNeed.SetRange("Operation No.", Rec."Operation No.");

                        PAGE.RunModal(0, ProdOrderCapNeed);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Order &Tracking")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        ProdOrderLine: Record "Prod. Order Line";
                        OrderTracking: Page "Order Tracking";
                    begin
                        ProdOrderLine.SetRange(Status, Rec.Status);
                        ProdOrderLine.SetRange("Prod. Order No.", Rec."Prod. Order No.");
                        ProdOrderLine.SetRange("Routing No.", Rec."Routing No.");
                        if ProdOrderLine.FindFirst() then begin
                            OrderTracking.SetVariantRec(
                                ProdOrderLine, ProdOrderLine."Item No.", ProdOrderLine."Remaining Qty. (Base)",
                                ProdOrderLine."Starting Date", ProdOrderLine."Ending Date");
                            OrderTracking.RunModal();
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category4)
                {
                    Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';

                    actionref("Allocated Capacity_Promoted"; "Allocated Capacity")
                    {
                    }
                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                    actionref(Tools_Promoted; Tools)
                    {
                    }
                    actionref(Personnel_Promoted; Personnel)
                    {
                    }
                    actionref("Quality Measures_Promoted"; "Quality Measures")
                    {
                    }
                }
                actionref(ShowDocument_Promoted; ShowDocument)
                {
                }
                actionref("Order &Tracking_Promoted"; "Order &Tracking")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    local procedure ExpCapacityNeed(): Decimal
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
    begin
        if Rec."Work Center No." = '' then
            exit(1);
        WorkCenter.Get(Rec."Work Center No.");
        exit(CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code"));
    end;
}