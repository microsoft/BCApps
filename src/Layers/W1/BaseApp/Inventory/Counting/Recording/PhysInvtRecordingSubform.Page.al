// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;

page 5881 "Phys. Invt. Recording Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Phys. Invt. Record Line";

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
                    ToolTip = 'Specifies the number of the item that was counted when taking the physical inventory.';

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
                    ToolTip = 'Specifies a reference to the item number as defined by the item''s barcode.';
                    Visible = ItemReferenceVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemReferenceManagement: Codeunit "Item Reference Management";
                    begin
                        ItemReferenceManagement.PhysicalInventoryRecordReferenceNoLookup(Rec);
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
                    ToolTip = 'Specifies the variant of the item on the line.';
                    ShowMandatory = VariantCodeMandatory;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SetVariantCodeMandatory();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the additional description of the item.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the location where the item was counted during taking the physical inventory.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin where the item was counted while performing the physical inventory.';
                    Visible = false;
                }
                field("Use Item Tracking"; Rec."Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    Editable = true;
                    ToolTip = 'Specifies if it is necessary to record the item using serial, lot or package numbers.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the serial number of the entered item.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the lot number of the entered item.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the package number of the entered item.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item of the physical inventory recording line.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity on the line, expressed in base units of measure.';
                    Visible = false;
                }
                field(Recorded; Rec.Recorded)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if a value was entered in Quantity of the physical inventory recording line.';
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the physical inventory was taken.';
                    Visible = false;
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time when the physical inventory was taken.';
                    Visible = false;
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who performed the physical inventory.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyLineAction)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Copy Line';
                    ToolTip = 'Copy Line.';

                    trigger OnAction()
                    begin
                        CopyLine();
                    end;
                }
            }
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action("Serial No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Serial No. Information Card';
                    Image = SNInfo;
                    RunObject = Page "Serial No. Information List";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Serial No." = field("Serial No.");
                    ToolTip = 'Show Serial No. Information Card.';
                }
                action("Lot No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Lot No. Information Card';
                    Image = LotInfo;
                    RunObject = Page "Lot No. Information List";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Lot No." = field("Lot No.");
                    ToolTip = 'Show Lot No. Information Card.';
                }
                action("Package No. Information Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Package No. Information Card';
                    Image = LotInfo;
                    RunObject = Page "Package No. Information List";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Package No." = field("Package No.");
                    ToolTip = 'Show Package No. Information Card.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetItemReferenceVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        SetVariantCodeMandatory();
    end;

    var
        CopyPhysInvtRecording: Report "Copy Phys. Invt. Recording";
        VariantCodeMandatory: Boolean;
        ItemReferenceVisible: Boolean;

    procedure CopyLine()
    begin
        CopyPhysInvtRecording.SetPhysInvtRecordLine(Rec);
        CopyPhysInvtRecording.RunModal();
        Clear(CopyPhysInvtRecording);
    end;

    local procedure SetVariantCodeMandatory()
    var
        Item: Record Item;
    begin
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
    end;

    local procedure SetItemReferenceVisibility()
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReferenceVisible := not ItemReference.IsEmpty();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReferenceNoOnAfterLookup(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
}

