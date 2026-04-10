// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;

page 517 "Requisition Lines"
{
    Caption = 'Requisition Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Requisition Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Worksheet Template Name"; Rec."Worksheet Template Name")
                {
                    ApplicationArea = Planning;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Planning;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Planning;
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
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                    Visible = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Planning;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                }
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the method that will be used for price calculation in the requisition line.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                }
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
                action("Show Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Show Worksheet';
                    Image = ViewWorksheet;
                    ToolTip = 'Open the requisition worksheet that the lines come from. ';

                    trigger OnAction()
                    begin
                        ReqWkshTmpl.Get(Rec."Worksheet Template Name");
                        ReqLine := Rec;
                        ReqLine.FilterGroup(2);
                        ReqLine.SetRange("Worksheet Template Name", Rec."Worksheet Template Name");
                        ReqLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        ReqLine.FilterGroup(0);
                        PAGE.Run(ReqWkshTmpl."Page ID", ReqLine);
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Worksheet_Promoted"; "Show Worksheet")
                {
                }
                actionref("Reservation Entries_Promoted"; "Reservation Entries")
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ReqLine: Record "Requisition Line";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ExtendedPriceEnabled: Boolean;

    protected var
        ShortcutDimCode: array[8] of Code[20];
}

