// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;

page 99001020 "Temp Prod. Ord. Rtng List"
{
    PageType = ListPart;
    SourceTable = "Prod. Order Routing Line";
    SourceTableTemporary = true;
    Caption = 'Production Order Routing Lines';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of the production order to which the routing list belongs.';
                    Editable = false;
                    Visible = false;
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the production order number.';
                    Editable = false;
                    Visible = false;
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the routing number.';
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the routing reference number.';
                }
                field("Schedule Manually"; Rec."Schedule Manually")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies whether to schedule the operation manually.';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation number for the routing line.';
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the previous operation number in the routing.';
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the next operation number in the routing.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of the routing operation (Work Center or Machine Center).';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the work center or machine center.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description of the routing operation.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies additional description of the routing operation.';
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies how consumption is flushed for this operation.';
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date and time of the operation.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the starting time of the operation.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the starting date of the operation.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending date and time of the operation.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the ending time of the operation.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the ending date of the operation.';
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the setup time for the operation.';
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the unit of measure code that applies to the setup time of the operation.';
                }
                field("Run Time"; Rec."Run Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the run time per unit for the operation.';
                }
                field("Run Time Unit of Meas. Code"; Rec."Run Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the unit of measure code that applies to the run time of the operation.';
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the wait time after the operation.';
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the unit of measure code for the wait time.';
                }
                field("Move Time"; Rec."Move Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the move time after the operation.';
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the unit of measure code for the move time.';
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the fixed scrap quantity for the operation.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing link code to connect this operation to BOM components.';
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the scrap factor percentage for the operation.';
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the send-ahead quantity for the operation.';
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the number of concurrent capacities for the operation.';
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the unit cost per for the operation.';
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the number of items that are included in the same operation at the same time.';
                }
                field("Expected Operation Cost Amt."; Rec."Expected Operation Cost Amt.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the expected operation cost amount.';
                }
                field("Expected Capacity Ovhd. Cost"; Rec."Expected Capacity Ovhd. Cost")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the expected capacity overhead cost.';
                }
                field("Expected Capacity Need"; Rec."Expected Capacity Need")
                {
                    ApplicationArea = Manufacturing;
                    AutoFormatType = 0;
                    DecimalPlaces = 0 : 5;
                    Visible = false;
                    ToolTip = 'Specifies the expected capacity need for the production order.';
                }
                field("Routing Status"; Rec."Routing Status")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the routing status of the operation.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                    ToolTip = 'Specifies the location code for the operation.';
                }
                field("Open Shop Floor Bin Code"; Rec."Open Shop Floor Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the open shop floor bin code.';
                }
                field("To-Production Bin Code"; Rec."To-Production Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the to-production bin code.';
                }
                field("From-Production Bin Code"; Rec."From-Production Bin Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the from-production bin code.';
                }
                field("Posted Output Quantity"; Rec."Posted Output Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the posted output quantity for the operation.';
                }
                field("Posted Scrap Quantity"; Rec."Posted Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the posted scrap quantity for the operation.';
                }
                field("Posted Run Time"; Rec."Posted Run Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the posted run time for the operation.';
                }
                field("Posted Setup Time"; Rec."Posted Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the posted setup time for the operation.';
                }
            }
        }
    }
    trigger OnDeleteRecord(): Boolean
    begin
        Rec.CheckPreviousAndNextForTemp();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Prod. Order No." := xRec."Prod. Order No.";
        Rec."Routing Reference No." := xRec."Routing Reference No.";
        Rec."Routing No." := xRec."Routing No.";
        Rec.Status := xRec.Status;

        GetManufacturingSetup();
        Rec."Flushing Method" := ManufacturingSetup."Def. Wiz. Flushing Method";
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
    end;

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ManufacturingSetupRead: Boolean;

    /// <summary>
    /// Binds the page list to the provided temporary production order routing line records.
    /// </summary>
    /// <param name="TempProdOrdRtngLine">The temporary production order routing lines to display and edit on the page.</param>
    internal procedure SetTempProdOrdRtngLine(var TempProdOrdRtngLine: Record "Prod. Order Routing Line" temporary)
    begin
        Rec.Copy(TempProdOrdRtngLine, true);
        CurrPage.Update(false);
    end;

    local procedure GetManufacturingSetup()
    begin
        if not ManufacturingSetupRead then begin
            ManufacturingSetup.SetLoadFields("Def. Wiz. Flushing method");
            ManufacturingSetup.Get();
            ManufacturingSetupRead := true;
        end;
    end;
}