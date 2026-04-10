// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;

page 99000863 "Planning Routing"
{
    Caption = 'Planning Routing';
    DataCaptionExpression = Rec.Caption();
    DataCaptionFields = "Worksheet Batch Name", "Worksheet Line No.";
    PageType = List;
    SourceTable = "Planning Routing Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Planning;
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    ApplicationArea = Planning;
                    Editable = NextOperationNoEditable;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Planning;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Planning;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Planning;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Planning;
                }
                field("Run Time"; Rec."Run Time")
                {
                    ApplicationArea = Planning;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ApplicationArea = Planning;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Planning;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Lot Size"; Rec."Lot Size")
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
            group("&Routing")
            {
                Caption = '&Routing';
                Image = Route;
                action("Allocated Capacity")
                {
                    ApplicationArea = Planning;
                    Caption = 'Allocated Capacity';
                    Image = AllocatedCapacity;
                    ToolTip = 'View the capacity need, which is the sum of the setup time and the run time. The run time is equal to the run time per piece multiplied by the number of pieces in the production order.';

                    trigger OnAction()
                    var
                        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                    begin
                        ProdOrderCapNeed.SetCurrentKey(Type, "No.", "Starting Date-Time");
                        ProdOrderCapNeed.SetRange(Type, Rec.Type);
                        ProdOrderCapNeed.SetRange("No.", Rec."No.");
                        ProdOrderCapNeed.SetRange(Date, Rec."Starting Date", Rec."Ending Date");
                        ProdOrderCapNeed.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                        ProdOrderCapNeed.SetRange("Worksheet Batch Name", Rec."Worksheet Batch Name");
                        ProdOrderCapNeed.SetRange("Worksheet Line No.", Rec."Worksheet Line No.");
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
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        ReqLine: Record "Requisition Line";
                        TrackingForm: Page "Order Tracking";
                    begin
                        ReqLine.Get(
                          Rec."Worksheet Template Name",
                          Rec."Worksheet Batch Name",
                          Rec."Worksheet Line No.");

                        TrackingForm.SetReqLine(ReqLine);
                        TrackingForm.RunModal();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NextOperationNoEditable := not Rec.IsSerial();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        if Rec.IsSerial() then
            Rec.SetPreviousAndNext();
    end;

    trigger OnInit()
    begin
        NextOperationNoEditable := true;
    end;

    var
        NextOperationNoEditable: Boolean;
}

