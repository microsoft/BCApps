// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000775 "Routing Line List"
{
    Caption = 'Routing Lines';
    PageType = List;
    Editable = false;
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
                }
                field("Previous Operation No."; Rec."Previous Operation No.")
                {
                    Visible = false;
                }
                field("Next Operation No."; Rec."Next Operation No.")
                {
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                }
                field("No."; Rec."No.")
                {
                }
                field("Standard Task Code"; Rec."Standard Task Code")
                {
                    Visible = false;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                }
                field("Description 2"; Rec."Description 2")
                {
                    Visible = false;
                }
                field("Setup Time"; Rec."Setup Time")
                {
                }
                field("Setup Time Unit of Meas. Code"; Rec."Setup Time Unit of Meas. Code")
                {
                    Visible = false;
                }
                field("Run Time"; Rec."Run Time")
                {
                    AutoFormatType = 0;
                }
                field("Run Time Unit of Meas. Code"; Rec."Run Time Unit of Meas. Code")
                {
                    Visible = false;
                }
                field("Wait Time"; Rec."Wait Time")
                {
                    AutoFormatType = 0;
                }
                field("Wait Time Unit of Meas. Code"; Rec."Wait Time Unit of Meas. Code")
                {
                    Visible = false;
                }
                field("Move Time"; Rec."Move Time")
                {
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    Visible = false;
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    Visible = false;
                }
            }
        }
    }
}