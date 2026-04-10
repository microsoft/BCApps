// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity.History;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

table 5773 "Registered Whse. Activity Line"
{
    Caption = 'Registered Whse. Activity Line';
    DrillDownPageID = "Registered Whse. Act.-Lines";
    LookupPageID = "Registered Whse. Act.-Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Activity Type"; Enum "Warehouse Activity Type")
        {
            Caption = 'Activity Type';
            ToolTip = 'Specifies the type of activity that the warehouse performed on the line, such as put-away, pick, or movement.';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the number of the registered warehouse activity line.';
        }
        field(4; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            ToolTip = 'Specifies the type of transaction the source document is associated with, such as sales, purchase, and production.';
        }
        field(5; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            ToolTip = 'Specifies the source subtype of the document related to the registered activity line.';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            ToolTip = 'Specifies the number of the source document that the entry originates from.';
        }
        field(7; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            ToolTip = 'Specifies the line number of the source document that the entry originates from.';
        }
        field(8; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            ToolTip = 'Specifies the number of the source document subline related to this activity line.';
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
            ToolTip = 'Specifies the type of document that the line relates to.';
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code for the location at which the activity occurs.';
            TableRelation = Location;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            ToolTip = 'Specifies the shelf number of the item on the line for information use.';
        }
        field(13; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number of the item to be handled, such as picked or put away.';
            TableRelation = Item;
        }
        field(15; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            ToolTip = 'Specifies the quantity per unit of measure of the item on the line.';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(18; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item on the line.';
        }
        field(19; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies a description of the item on the line.';
        }
        field(20; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity of the item that was put-away, picked or moved.';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(31; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies the shipping advice about whether a partial delivery was acceptable to the order recipient.';
        }
        field(34; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the date when the warehouse activity must be completed.';
        }
        field(39; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(41; "Whse. Activity No."; Code[20])
        {
            Caption = 'Whse. Activity No.';
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(44; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number that was handled.';

            trigger OnLookup()
            begin
                ItemTrackingManagement.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number that was handled.';

            trigger OnLookup()
            begin
                ItemTrackingManagement.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            ToolTip = 'Specifies the expiration date of the serial number that was handled.';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnLookup()
            begin
                ItemTrackingManagement.LookupTrackingNoInfo("Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
        field(7300; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the items are picked or put away.';
            TableRelation = if ("Action Type" = filter(<> Take)) Bin.Code where("Location Code" = field("Location Code"),
                                                                              "Zone Code" = field("Zone Code"))
            else
            if ("Action Type" = filter(<> Take),
                                                                                       "Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Action Type" = const(Take)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                           "Zone Code" = field("Zone Code"))
            else
            if ("Action Type" = const(Take),
                                                                                                                                                                    "Zone Code" = filter('')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"));
        }
        field(7301; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            ToolTip = 'Specifies the code of the zone in which the bin on this line is located.';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(7305; "Action Type"; Enum "Warehouse Action Type")
        {
            Caption = 'Action Type';
            ToolTip = 'Specifies the action you must perform for the items on the line.';
            Editable = false;
        }
        field(7306; "Whse. Document Type"; Enum "Warehouse Activity Document Type")
        {
            Caption = 'Whse. Document Type';
            ToolTip = 'Specifies the type of document that the line originated from.';
            Editable = false;
        }
        field(7307; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            ToolTip = 'Specifies the number of the warehouse document that is the basis for the action on the line.';
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Assembly)) "Assembly Header"."No." where("Document Type" = const(Order),
                                                                                                           "No." = field("Whse. Document No."));
        }
        field(7308; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
            ToolTip = 'Specifies the number of the line in the warehouse document that is the basis for the action on the line.';
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                    "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                                                                                                                "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                            "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Assembly)) "Assembly Line"."Line No." where("Document Type" = const(Order),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         "Document No." = field("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         "Line No." = field("Whse. Document Line No."));
        }
        field(7310; Cubage; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Cubage';
            ToolTip = 'Specifies the total cubage of items on the line, calculated based on the Quantity field.';
            DecimalPlaces = 0 : 5;
        }
        field(7311; Weight; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Weight';
            ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
            DecimalPlaces = 0 : 5;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            ToolTip = 'Specifies the code of the equipment required when you perform the action on the line.';
            TableRelation = "Special Equipment";
        }
    }

    keys
    {
        key(Key1; "Activity Type", "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Line No.", "Activity Type")
        {
        }
        key(Key3; "Activity Type", "No.", "Sorting Sequence No.")
        {
        }
        key(Key4; "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
        {
        }
        key(Key5; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Whse. Document No.", "Serial No.", "Lot No.", "Action Type")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. (Base)";
        }
    }

    fieldgroups
    {
    }

    var
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ItemTrackingType: Enum "Item Tracking Type";

    procedure ShowRegisteredActivityDoc()
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        RegisteredPickCard: Page "Registered Pick";
        RegisteredPutAwayCard: Page "Registered Put-away";
        RegisteredMovement: Page "Registered Movement";
    begin
        RegisteredWhseActivityHdr.SetRange(Type, "Activity Type");
        RegisteredWhseActivityHdr.SetRange("No.", "No.");
        RegisteredWhseActivityHdr.FindFirst();
        case "Activity Type" of
            "Activity Type"::Pick:
                begin
                    RegisteredPickCard.SetRecord(RegisteredWhseActivityHdr);
                    RegisteredPickCard.SetTableView(RegisteredWhseActivityHdr);
                    RegisteredPickCard.RunModal();
                end;
            "Activity Type"::"Put-away":
                begin
                    RegisteredPutAwayCard.SetRecord(RegisteredWhseActivityHdr);
                    RegisteredPutAwayCard.SetTableView(RegisteredWhseActivityHdr);
                    RegisteredPutAwayCard.RunModal();
                end;
            "Activity Type"::Movement:
                begin
                    RegisteredMovement.SetRecord(RegisteredWhseActivityHdr);
                    RegisteredMovement.SetTableView(RegisteredWhseActivityHdr);
                    RegisteredMovement.RunModal();
                end;
        end;
    end;

    procedure ShowWhseDoc()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPutawayHeader: Record "Whse. Internal Put-away Header";
        AssemblyHeader: Record "Assembly Header";
        WarehouseShipment: Page "Warehouse Shipment";
        PostedWhseReceipt: Page "Posted Whse. Receipt";
        WhseInternalPickCard: Page "Whse. Internal Pick";
        WhseInternalPutawayCard: Page "Whse. Internal Put-away";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowWhseDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Whse. Document Type" of
            "Whse. Document Type"::Shipment:
                begin
                    WarehouseShipmentHeader.SetRange("No.", "Whse. Document No.");
                    WarehouseShipment.SetTableView(WarehouseShipmentHeader);
                    WarehouseShipment.RunModal();
                end;
            "Whse. Document Type"::Receipt:
                begin
                    PostedWhseReceiptHeader.SetRange("No.", "Whse. Document No.");
                    PostedWhseReceipt.SetTableView(PostedWhseReceiptHeader);
                    PostedWhseReceipt.RunModal();
                end;
            "Whse. Document Type"::"Internal Pick":
                begin
                    WhseInternalPickHeader.SetRange("No.", "Whse. Document No.");
                    WhseInternalPickHeader.FindFirst();
                    WhseInternalPickCard.SetRecord(WhseInternalPickHeader);
                    WhseInternalPickCard.SetTableView(WhseInternalPickHeader);
                    WhseInternalPickCard.RunModal();
                end;
            "Whse. Document Type"::"Internal Put-away":
                begin
                    WhseInternalPutawayHeader.SetRange("No.", "Whse. Document No.");
                    WhseInternalPutawayHeader.FindFirst();
                    WhseInternalPutawayCard.SetRecord(WhseInternalPutawayHeader);
                    WhseInternalPutawayCard.SetTableView(WhseInternalPutawayHeader);
                    WhseInternalPutawayCard.RunModal();
                end;
            "Whse. Document Type"::Assembly:
                begin
                    AssemblyHeader.SetRange("Document Type", "Source Subtype");
                    AssemblyHeader.SetRange("No.", "Source No.");
                    PAGE.Run(PAGE::"Assembly Order", AssemblyHeader);
                end;
            else
                OnShowWhseDoc(Rec);
        end;
    end;

    procedure ShowWhseEntries(RegisterDate: Date)
    var
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseEntries: Page "Warehouse Entries";
    begin
        WarehouseEntry.SetCurrentKey("Reference No.", "Registering Date");
        WarehouseEntry.SetRange("Reference No.", "No.");
        WarehouseEntry.SetRange("Registering Date", RegisterDate);
        case "Activity Type" of
            "Activity Type"::"Put-away":
                WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::"Put-away");
            "Activity Type"::Pick:
                WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::Pick);
            "Activity Type"::Movement:
                WarehouseEntry.SetRange("Reference Document", WarehouseEntry."Reference Document"::Movement);
        end;
        WarehouseEntries.SetTableView(WarehouseEntry);
        WarehouseEntries.RunModal();
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; SetKey: Boolean)
    var
        Item: Record Item;
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        if SetKey then
            SetCurrentKey(Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", Rec."Source Subline No.");
        SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            SetRange("Source Subtype", SourceSubType);
        SetRange("Source No.", SourceNo);
        SetRange("Source Line No.", SourceLineNo);
        if SourceSubLineNo >= 0 then
            SetRange("Source Subline No.", SourceSubLineNo);

        PostedWhseReceiptLine.SetLoadFields("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Item No.");
        PostedWhseReceiptLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Posted Source Document", "Posted Source No.");
        PostedWhseReceiptLine.SetRange("Source Type", SourceType);
        PostedWhseReceiptLine.SetRange("Source Subtype", SourceSubType);
        PostedWhseReceiptLine.SetRange("Source No.", SourceNo);
        PostedWhseReceiptLine.SetRange("Source Line No.", SourceLineNo);
        if PostedWhseReceiptLine.FindFirst() then begin
            Item.SetLoadFields("Put-away Unit of Measure Code");
            Item.Get(PostedWhseReceiptLine."Item No.");
            if Item."Put-away Unit of Measure Code" <> '' then
                SetRange("Unit of Measure Code", Item."Put-away Unit of Measure Code");
        end;
        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSubLineNo, SetKey);
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source No.");
        SetRange("Source Line No.");
        SetRange("Source Subline No.");
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure SetTrackingFilterFromRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        SetRange("Serial No.", WhseItemEntryRelation."Serial No.");
        SetRange("Lot No.", WhseItemEntryRelation."Lot No.");

        OnAfterSetTrackingFilterFromRelation(Rec, WhseItemEntryRelation);
    end;

    procedure SetTrackingFilterFromItemLedgerEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgEntry."Serial No.");
        SetRange("Lot No.", ItemLedgEntry."Lot No.");
        SetRange("Package No.", ItemLedgEntry."Package No.");
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WarehouseActivityLine."Serial No.");
        SetRange("Lot No.", WarehouseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WarehouseActivityLine);
    end;

    procedure SetTrackingFilterFromWhseSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        SetRange("Lot No.", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseSpec(Rec, WhseItemTrackingLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromSpec(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromRelation(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseSpec(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWhseDoc(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowWhseDoc(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
    end;
}

