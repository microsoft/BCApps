// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;

page 5877 "Physical Inventory Order Subf."
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Phys. Invt. Order Line";

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

                    trigger OnValidate()
                    begin
                        SetVariantCodeMandatory();
                    end;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    QuickEntry = false;
                    Visible = ItemReferenceVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemReferenceManagement: Codeunit "Item Reference Management";
                    begin
                        ItemReferenceManagement.PhysicalInventoryOrderReferenceNoLookup(Rec);
                        SetVariantCodeMandatory();
                        OnReferenceNoOnAfterLookup(Rec);
                    end;

                    trigger OnValidate()
                    begin
                        SetVariantCodeMandatory();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    begin
                        SetVariantCodeMandatory();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
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
                    Visible = false;
                }
                field("Qty. Expected (Base)"; Rec."Qty. Expected (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the expected inventory quantity in the base unit of measure.';
                }
                field("Qty. Exp. Calculated"; Rec."Qty. Exp. Calculated")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Exp. Tracking (Base)"; Rec."Qty. Exp. Tracking (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the item''s expected inventory of serial, lot and package numbers in the base unit of measure.';
                }
                field("Use Item Tracking"; Rec."Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Recorded (Base)"; Rec."Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the counted quantity in the base unit of measure on the physical inventory order line.';
                }
                field("On Recording Lines"; Rec."On Recording Lines")
                {
                    ApplicationArea = Warehouse;
                }
                field("No. Finished Rec.-Lines"; Rec."No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                    BlankZero = true;
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
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
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

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
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
                action("Recording Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Recording Lines';
                    ToolTip = 'View one or more physical inventory recording lines where the selected item exists';

                    trigger OnAction()
                    begin
                        Rec.ShowPhysInvtRecordingLines();
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
                    action("E&xpected Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'E&xpected Tracking Lines';
                        ToolTip = 'View the serial, lot or package numbers that are currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            Rec.ShowExpectPhysInvtTrackLines();
                        end;
                    }
                    action("&All Diff. Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&All Diff. Tracking Lines';
                        ToolTip = 'View the serial, lot or package numbers that are different on the related recording than currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            Rec.ShowItemTrackingLines(0);
                        end;
                    }
                    action("&Pos. Diff. Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Pos. Diff. Tracking Lines';
                        ToolTip = 'View the serial, lot or package numbers that are counted as more on the related recording than currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            Rec.ShowItemTrackingLines(1);
                        end;
                    }
                    action("&Neg. Diff. Tracking Lines")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Neg. Diff. Tracking Lines';
                        ToolTip = 'View the serial, lot or package numbers that are counted as less on the related recording than currently recorded (expected) for the item on the line.';

                        trigger OnAction()
                        begin
                            Rec.ShowItemTrackingLines(2);
                        end;
                    }
                }
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Ledger E&ntries';
                        ToolTip = 'View the item''s item ledger entries.';

                        trigger OnAction()
                        begin
                            Rec.ShowItemLedgerEntries();
                        end;
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        ToolTip = 'View the item''s physical inventory ledger entries, meaning the history of the item''s ledger entry changes from counting.';

                        trigger OnAction()
                        begin
                            Rec.ShowPhysInvtLedgerEntries();
                        end;
                    }
                }
                action("Bin Content (&Item)")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Content (&Item)';
                    ToolTip = 'View the item''s content in bins.';

                    trigger OnAction()
                    begin
                        Rec.ShowBinContentItem();
                    end;
                }
                action("Bin Content (&Bin)")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Content (&Bin)';
                    ToolTip = 'View the content of the bins where the item exists.';

                    trigger OnAction()
                    begin
                        Rec.ShowBinContentBin();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Expected &Qty.")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Calculate Expected &Qty.';
                    Ellipsis = true;
                    Image = Line;
                    ToolTip = 'Update the value in the Qty. Expected (Base) field on the line with any inventory changes made since you created the order. When you have used this function, the Qty. Exp. Calculated check box is selected.';

                    trigger OnAction()
                    begin
                        CalculateQtyExpected();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        SetVariantCodeMandatory();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
        SetItemReferenceVisibility();
    end;

    var
        ItemReferenceVisible: Boolean;
        VariantCodeMandatory: Boolean;

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

    procedure CalculateQtyExpected()
    var
        PhysInvtCalcQtyOne: Codeunit "Phys. Invt.-Calc. Qty. One";
    begin
        PhysInvtCalcQtyOne.Run(Rec);
        Clear(PhysInvtCalcQtyOne);
    end;

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

    local procedure SetItemReferenceVisibility()
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReferenceVisible := not ItemReference.IsEmpty();
    end;

    local procedure SetVariantCodeMandatory()
    var
        Item: Record Item;
    begin
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReferenceNoOnAfterLookup(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
}

