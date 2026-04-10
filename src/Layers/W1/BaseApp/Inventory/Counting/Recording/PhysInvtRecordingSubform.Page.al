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
                field("Use Item Tracking"; Rec."Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    Editable = true;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
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
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
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

