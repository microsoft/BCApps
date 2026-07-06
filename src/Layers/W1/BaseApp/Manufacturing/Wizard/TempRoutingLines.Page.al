// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

using Microsoft.Manufacturing.Routing;

page 99001030 "Temp Routing Lines"
{
    PageType = ListPart;
    SourceTable = "Routing Line";
    SourceTableTemporary = true;
    Caption = 'Routing Lines';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
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
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the standard task code for the operation.';
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the routing link code to connect this operation to BOM components.';
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
                field("Setup Time"; Rec."Setup Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the setup time for the operation.';
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the unit of measure for the setup time.';
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
                    ToolTip = 'Specifies the unit of measure for the run time.';
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
                    ToolTip = 'Specifies the unit of measure for the wait time.';
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
                    ToolTip = 'Specifies the unit of measure for the move time.';
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the fixed scrap quantity for the operation.';
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the scrap factor percentage for the operation.';
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the minimum process time for the operation.';
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the maximum process time for the operation.';
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of concurrent capacities for the operation.';
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the send-ahead quantity for the operation.';
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the unit cost per for the operation.';
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ToolTip = 'Specifies the lot size for the operation.';
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
        Rec."Routing No." := xRec."Routing No.";
        Rec."Version Code" := xRec."Version Code";
    end;

    /// <summary>
    /// Binds the page list to the provided temporary routing line records.
    /// </summary>
    /// <param name="TempRoutingLine">The temporary routing lines to display and edit on the page.</param>
    internal procedure SetTemporaryRecords(var TempRoutingLine: Record "Routing Line" temporary)
    begin
        Rec.Copy(TempRoutingLine, true);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Returns the current temporary routing line records from the page by copying them into the provided variable.
    /// </summary>
    /// <param name="TempRoutingLine">The variable to receive the temporary routing lines.</param>
    internal procedure GetTemporaryRecords(var TempRoutingLine: Record "Routing Line" temporary)
    begin
        TempRoutingLine.Copy(Rec, true);
    end;
}