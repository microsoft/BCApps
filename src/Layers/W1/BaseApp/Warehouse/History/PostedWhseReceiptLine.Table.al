// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

table 7319 "Posted Whse. Receipt Line"
{
    Caption = 'Posted Whse. Receipt Line';
    LookupPageID = "Posted Whse. Receipt Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the line in the posted receipt.';
            Editable = false;
        }
        field(3; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(4; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            ToolTip = 'Specifies the number of the source document that the entry originates from.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            ToolTip = 'Specifies the line number of the source document that the entry originates from.';
            Editable = false;
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            Caption = 'Source Document';
            ToolTip = 'Specifies the type of document that the line relates to.';
            Editable = false;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code of the location where the items were received.';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            ToolTip = 'Specifies the shelf number of the item for informational use.';
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            ToolTip = 'Specifies the code of the zone on this posted receipt line.';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item that was received and posted.';
            Editable = false;
            TableRelation = Item;
        }
        field(15; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity that was received.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Qty. Put Away"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Put Away';
            ToolTip = 'Specifies the quantity that is put away.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(26; "Qty. Put Away (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Put Away (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Put-away Qty."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = const("Put-away"),
                                                                                  "Whse. Document Type" = const(Receipt),
                                                                                  "Whse. Document No." = field("No."),
                                                                                  "Whse. Document Line No." = field("Line No."),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Take),
                                                                                  "Original Breakbulk" = const(false)));
            Caption = 'Put-away Qty.';
            ToolTip = 'Specifies the quantity on put-away instructions in the process of being put away.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Put-away Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = const("Put-away"),
                                                                                         "Whse. Document Type" = const(Receipt),
                                                                                         "Whse. Document No." = field("No."),
                                                                                         "Whse. Document Line No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Take),
                                                                                         "Original Breakbulk" = const(false)));
            Caption = 'Put-away Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            ToolTip = 'Specifies the number of base units of measure, in the unit of measure, specified for the item on the line.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item in the line.';
            Editable = false;
        }
        field(33; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies a second description of the item in the line, if any.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date that the receipt line was due.';
        }
        field(37; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(50; "Qty. Cross-Docked"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Cross-Docked';
            ToolTip = 'Specifies the quantity of items that was in the Qty. To Cross-Dock field on the warehouse receipt line when it was posted.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(51; "Qty. Cross-Docked (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Cross-Docked (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(52; "Cross-Dock Zone Code"; Code[10])
        {
            Caption = 'Cross-Dock Zone Code';
            ToolTip = 'Specifies the zone code used to create the cross-dock put-away for this line when the receipt was posted.';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(53; "Cross-Dock Bin Code"; Code[20])
        {
            Caption = 'Cross-Dock Bin Code';
            ToolTip = 'Specifies the bin code used to create the cross-dock put-away for this line when the receipt was posted.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(55; "Qty. Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(56; "Qty. Rounding Precision (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(60; "Posted Source Document"; Enum "Warehouse Shipment Posted Source Document")
        {
            Caption = 'Posted Source Document';
            ToolTip = 'Specifies the type of posted source document referred to by the receipt line.';
        }
        field(61; "Posted Source No."; Code[20])
        {
            Caption = 'Posted Source No.';
            ToolTip = 'Specifies the document number of the posted source document.';
        }
        field(62; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(63; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Vendor Shipment No.';
        }
        field(64; "Whse. Receipt No."; Code[20])
        {
            Caption = 'Whse. Receipt No.';
            Editable = false;
        }
        field(65; "Whse Receipt Line No."; Integer)
        {
            Caption = 'Whse Receipt Line No.';
            Editable = false;
        }
        field(66; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            Editable = false;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            Editable = false;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Posted Source No.", "Posting Date")
        {
        }
        key(Key3; "Item No.", "Location Code", "Variant Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. (Base)", "Qty. Put Away (Base)";
        }
        key(Key4; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Posted Source Document", "Posted Source No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if Location.RequirePutaway("Location Code") then
            TestField(Quantity, "Qty. Put Away");
    end;

    var
        Location: Record Location;
#pragma warning disable AA0074
        Text000: Label 'Nothing to handle.';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetLineStatus(): Integer
    begin
        if "Qty. Put Away" > 0 then
            if "Qty. Put Away" < Quantity then
                Status := Status::"Partially Put Away"
            else
                Status := Status::"Completely Put Away";

        exit(Status);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure CreatePutAwayDoc(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; AssignedID: Code[50])
    var
        WhseSetup: Record "Warehouse Setup";
        CreatePutAwayFromWhseSource: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePutAwayDoc(PostedWhseRcptLine, AssignedID, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        GetLocation(PostedWhseRcptLine."Location Code");
        if not Location."Require Put-away" then
            if Location.Code = '' then begin
                WhseSetup.Get();
                WhseSetup.TestField("Require Put-away");
            end else
                Location.TestField("Require Put-away");
        PostedWhseRcptLine.SetFilter(Quantity, '>0');
        PostedWhseRcptLine.SetFilter(
          Status, '<>%1', PostedWhseRcptLine.Status::"Completely Put Away");
        if PostedWhseRcptLine.Find('-') then begin
            CreatePutAwayFromWhseSource.SetPostedWhseReceiptLine(PostedWhseRcptLine, AssignedID);
            CreatePutAwayFromWhseSource.SetHideValidationDialog(HideValidationDialog);
            CreatePutAwayFromWhseSource.UseRequestPage(not HideValidationDialog);
            OnCreatePutAwayDocOnBeforeCreatePutAwayFromWhseSourceRunModal(PostedWhseRcptLine, AssignedID, HideValidationDialog, CreatePutAwayFromWhseSource);
            CreatePutAwayFromWhseSource.RunModal();
            CreatePutAwayFromWhseSource.GetResultMessage(1);
            Clear(CreatePutAwayFromWhseSource);
        end else
            if not HideValidationDialog then
                Message(Text000);
    end;

    procedure CopyTrackingFromWhseItemEntryRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        "Serial No." := WhseItemEntryRelation."Serial No.";
        "Lot No." := WhseItemEntryRelation."Lot No.";

        OnAfterCopyTrackingFromWhseItemEntryRelation(rec, WhseItemEntryRelation);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterSetTrackingFilterFromItemLedgEntry(rec, ItemLedgEntry);
    end;

    procedure SetTrackingFilterFromRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        SetRange("Serial No.", WhseItemEntryRelation."Serial No.");
        SetRange("Lot No.", WhseItemEntryRelation."Lot No.");

        OnAfterSetTrackingFilterFromRelation(Rec, WhseItemEntryRelation);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemEntryRelation(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgEntry(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromRelation(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayDoc(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; AssignedID: Code[50]; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayDocOnBeforeCreatePutAwayFromWhseSourceRunModal(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; AssignedID: Code[50]; HideValidationDialog: Boolean; var CreatePutAwayFromWhseSource: Report "Whse.-Source - Create Document")
    begin
    end;
}

