// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.WorkCenter;

page 99000817 "Prod. Order Routing"
{
    Caption = 'Prod. Order Routing';
    DataCaptionExpression = Rec.Caption();
    PageType = List;
    SourceTable = "Prod. Order Routing Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = ProdOrderNoVisible;
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
                    Editable = NextOperationNoEditable;
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

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the starting time of the routing line (operation).';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Starting Date"; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date of the routing line (operation).';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Starting Date", StartingDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the ending time of the routing line (operation).';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date"; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the ending date of the routing line (operation).';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Ending Date", EndingDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
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

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
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

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
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
                    Editable = UnitCostPerEditable;
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
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
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

    trigger OnAfterGetRecord()
    begin
        NextOperationNoEditable := not Rec.IsSerial();
        Rec.GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UnitCostPerEditable := Rec.Type = Rec.Type::"Work Center";
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.CheckPreviousAndNext();
    end;

    trigger OnInit()
    begin
        ProdOrderNoVisible := true;
        NextOperationNoEditable := true;
        DateAndTimeFieldVisible := false;
    end;

    trigger OnOpenPage()
    begin
        ProdOrderNoVisible := true;
        if Rec.GetFilter("Prod. Order No.") <> '' then
            ProdOrderNoVisible := Rec.GetRangeMin("Prod. Order No.") <> Rec.GetRangeMax("Prod. Order No.");
        DateAndTimeFieldVisible := false;
    end;

    var
        ProdOrderNoVisible: Boolean;
        NextOperationNoEditable: Boolean;
        UnitCostPerEditable: Boolean;
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;
        DateAndTimeFieldVisible: Boolean;

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

    procedure Initialize(NewCaption: Text)
    begin
        CurrPage.Caption(NewCaption);
    end;
}

