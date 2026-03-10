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
#pragma warning disable AA0218
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
                field("Setup Time"; Rec."Setup Time")
                {
                    AutoFormatType = 0;
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
                    AutoFormatType = 0;
                }
                field("Move Time Unit of Meas. Code"; Rec."Move Time Unit of Meas. Code")
                {
                    Visible = false;
                }
                field("Fixed Scrap Quantity"; Rec."Fixed Scrap Quantity")
                {
                    AutoFormatType = 0;
                }
                field("Scrap Factor %"; Rec."Scrap Factor %")
                {
                    AutoFormatType = 0;
                }
                field("Minimum Process Time"; Rec."Minimum Process Time")
                {
                    AutoFormatType = 0;
                    Visible = false;
                }
                field("Maximum Process Time"; Rec."Maximum Process Time")
                {
                    AutoFormatType = 0;
                    Visible = false;
                }
                field("Concurrent Capacities"; Rec."Concurrent Capacities")
                {
                    AutoFormatType = 0;
                }
                field("Send-Ahead Quantity"; Rec."Send-Ahead Quantity")
                {
                    AutoFormatType = 0;
                }
                field("Unit Cost per"; Rec."Unit Cost per")
                {
                    AutoFormatType = 0;
                }
                field("Lot Size"; Rec."Lot Size")
                {
                    AutoFormatType = 0;
                    Visible = false;
                }
            }
        }
    }
#pragma warning restore AA0218
}
