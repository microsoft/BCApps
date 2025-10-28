// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing.Routing;

using Microsoft.Manufacturing.Routing;

page 20463 "Qlty. Routing Line Lookup"
{
    Caption = 'Routing Line Lookup';
    PageType = List;
    SourceTable = "Routing Line";
    UsageCategory = None;
    ApplicationArea = Manufacturing;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Operation No."; Rec."Operation No.")
                {
                    ToolTip = 'Specifies the operation number for this routing line.';
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    ToolTip = 'Specifies the previous operation number, which is automatically assigned.';
                    Visible = false;
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    ToolTip = 'Specifies the next operation number. You use this field if you use parallel routings.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the type of capacity type to use for the actual operation.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    ToolTip = 'Specifies a standard task.';
                    Visible = false;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ToolTip = 'Specifies the routing link code.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Setup Time"; Rec."Setup Time")
                {
                    ToolTip = 'Specifies the setup time of the operation.';
                    AutoFormatType = 0;
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    ToolTip = 'Specifies the unit of measure code that applies to the setup time of the operation.';
                    Visible = false;
                }
                field("Run Time"; Rec."Run Time")
                {
                    ToolTip = 'Specifies the run time of the operation.';
                    AutoFormatType = 0;
                }
                field("Run Time Unit of Meas. Code"; Rec."Run Time Unit of Meas. Code")
                {
                    ToolTip = 'Specifies the unit of measure code that applies to the run time of the operation.';
                    Visible = false;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    ToolTip = 'Specifies the wait time according to the value in the Wait Time Unit of Measure field.';
                    AutoFormatType = 0;
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    ToolTip = 'Specifies the unit of measure code that applies to the wait time.';
                    Visible = false;
                }
                field("Move Time"; Rec."Move Time")
                {
                    ToolTip = 'Specifies the move time according to the value in the Move Time Unit of Measure field.';
                    AutoFormatType = 0;
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    ToolTip = 'Specifies the unit of measure code that applies to the move time.';
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    ToolTip = 'Specifies the fixed scrap quantity.';
                    AutoFormatType = 0;
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    ToolTip = 'Specifies the scrap factor in percent.';
                    AutoFormatType = 0;
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    ToolTip = 'Specifies a minimum process time.';
                    AutoFormatType = 0;
                    Visible = false;
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    ToolTip = 'Specifies a maximum process time.';
                    AutoFormatType = 0;
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    ToolTip = 'Specifies the number of machines or persons that are working concurrently.';
                    AutoFormatType = 0;
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    ToolTip = 'Specifies the send-ahead quantity.';
                    AutoFormatType = 0;
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    ToolTip = 'Specifies the unit cost for this operation if it is different than the unit cost on the work center or machine center card.';
                    AutoFormatType = 0;
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    ToolTip = 'Specifies the number of items that are included in the same operation at the same time. The run time on routing lines is reduced proportionally to the lot size. For example, if the lot size is two pieces, the run time will be reduced by half.';
                    AutoFormatType = 0;
                    Visible = false;
                }
            }
        }
    }
}
