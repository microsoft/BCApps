// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

using Microsoft.Finance.Dimension;

page 5885 "Posted Phys. Invt. Order Subf."
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    Editable = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Pstd. Phys. Invt. Order Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item number.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies an additional part of the description of the item.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location where the item must be counted.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Bin Code of the table physical inventory order line.';
                    Visible = false;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                    Visible = false;
                }
                field("Base Unit of Measure Code"; Rec."Base Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the base unit of measure that is set up for the item.';
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number where the item is placed.';
                    Visible = false;
                }
                field("Qty. Expected (Base)"; Rec."Qty. Expected (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item''s current expected inventory quantity in the base unit of measure.';
                }
                field("Qty. Exp. Tracking (Base)"; Rec."Qty. Exp. Tracking (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item''s current expected inventory of serial, lot and package numbers in the base unit of measure.';
                }
                field("Use Item Tracking"; Rec."Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the counting of the item is done by counting its serial, lot and package numbers.';
                }
                field("Qty. Recorded (Base)"; Rec."Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the counted quantity in the base unit of measure.';
                }
                field("No. Finished Rec.-Lines"; Rec."No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    ToolTip = 'Specifies how many of the related physical inventory recordings are closed.';
                }
                field("Recorded Without Order"; Rec."Recorded Without Order")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that no physical inventory order lines existed for the recorded item, and that the line was generated based on the related recording.';
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the difference in the Quantity (Base) field on the related closed recording is positive or negative.';
                    Visible = false;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                    Visible = false;
                }
                field("Pos. Qty. (Base)"; Rec."Pos. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    ToolTip = 'Specifies the positive difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                }
                field("Neg. Qty. (Base)"; Rec."Neg. Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
                    ToolTip = 'Specifies the negative difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                }
                field("Unit Amount"; Rec."Unit Amount")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the sum of unit costs for the item quantity on the line.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item''s unit cost.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(RecordingLines)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Recording Lines';
                    ToolTip = 'View one or more physical inventory recording lines where the selected item exists.';

                    trigger OnAction()
                    begin
                        Rec.ShowPostPhysInvtRecordingLines();
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as a project or department, that are assigned to the physical inventory order line for financial analysis.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                group("Item &Tracking Lines")
                {
                    Caption = 'Item &Tracking Lines';
                    Image = AllLines;
                    action(ExpectedTrackingLines)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'E&xpected Tracking Lines';
                        ToolTip = 'View the serial, lot or package numbers that are currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            Rec.ShowPostExpPhysInvtTrackLines();
                        end;
                    }
                    action(ItemTrackingEntries)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Item &Tracking Entries';
                        Image = ItemTrackingLedger;
                        ToolTip = 'View the item ledger entries that originate from serial, lot and package number posting for the item on the line.';

                        trigger OnAction()
                        begin
                            Rec.ShowPostedItemTrackingLines();
                        end;
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
    end;

    protected var
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;
}

