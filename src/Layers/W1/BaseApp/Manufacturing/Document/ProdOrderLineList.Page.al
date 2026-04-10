// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;

page 5406 "Prod. Order Line List"
{
    Caption = 'Prod. Order Line List';
    Editable = false;
    PageType = List;
    AboutTitle = 'About Production Order Line List';
    AboutText = 'Review and manage individual production order lines, including item details, quantities, status, scheduling dates, costs, and related production BOM information for each step in the manufacturing process.';
    SourceTable = "Prod. Order Line";
    ApplicationArea = Manufacturing;
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
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Finished Quantity"; Rec."Finished Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Starting Date"; StartingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the entry''s starting date, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the entry''s starting time, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Ending Date"; EndingDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the entry''s ending date, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the entry''s ending time, which is retrieved from the production order routing.';
                    Visible = DateAndTimeFieldVisible;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the entry''s starting date and starting time, which is retrieved from the production order routing.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the entry''s ending date and ending time, which is retrieved from the production order routing.';
                }
                field("Production BOM No."; Rec."Production BOM No.")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Manufacturing;
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

                        OnAfterShowDocument(Rec, ProdOrder);
                    end;
                }
                action(ShowReservEntries)
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
                action(ShowTrackingLines)
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
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ShowDocument_Promoted; ShowDocument)
                {
                }
                actionref(ShowTrackingLines_Promoted; ShowTrackingLines)
                {
                }
                actionref(ShowReservEntries_Promoted; ShowReservEntries)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        Rec.GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);
    end;

    trigger OnInit()
    begin
        DateAndTimeFieldVisible := false;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        DateAndTimeFieldVisible := false;
    end;

    var
        ShortcutDimCode: array[8] of Code[20];
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;
        DateAndTimeFieldVisible: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocument(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order")
    begin
    end;
}

