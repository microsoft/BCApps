// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;

page 5407 "Prod. Order Comp. Line List"
{
    ApplicationArea = Manufacturing;
    Caption = 'Prod. Order Comp. Lines';
    Editable = false;
    PageType = List;
    AboutTitle = 'About Production Order Component Lines';
    AboutText = 'View and manage the materials required for production orders, including component quantities, locations, due dates, and consumption status, to track progress and ensure timely availability of resources for manufacturing.';
    SourceTable = "Prod. Order Component";
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
                field("Prod. Order Line No."; Rec."Prod. Order Line No.")
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
                field("Quantity per"; Rec."Quantity per")
                {
                    AutoFormatType = 0;
                    ApplicationArea = Manufacturing;
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    AutoFormatType = 0;
                    ApplicationArea = Manufacturing;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    AutoFormatType = 0;
                    ApplicationArea = Manufacturing;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
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
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    protected var
        ShortcutDimCode: array[8] of Code[20];
}

