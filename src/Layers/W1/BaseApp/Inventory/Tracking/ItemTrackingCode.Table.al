// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Ledger;

table 6502 "Item Tracking Code"
{
    Caption = 'Item Tracking Code';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "Item Tracking Codes";
    LookupPageID = "Item Tracking Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Warranty Date Formula"; DateFormula)
        {
            Caption = 'Warranty Date Formula';
        }
        field(5; "Man. Warranty Date Entry Reqd."; Boolean)
        {
            Caption = 'Man. Warranty Date Entry Reqd.';
        }
        field(6; "Man. Expir. Date Entry Reqd."; Boolean)
        {
            Caption = 'Man. Expir. Date Entry Reqd.';

            trigger OnValidate()
            begin
                if (not "Use Expiration Dates") and "Man. Expir. Date Entry Reqd." then
                    Validate("Use Expiration Dates", true);
            end;
        }
        field(8; "Strict Expiration Posting"; Boolean)
        {
            Caption = 'Strict Expiration Posting';

            trigger OnValidate()
            begin
                if (not "Use Expiration Dates") and "Strict Expiration Posting" then
                    Validate("Use Expiration Dates", true);
            end;
        }
        field(9; "Use Expiration Dates"; Boolean)
        {
            Caption = 'Use Expiration Dates';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Use Expiration Dates" then
                    exit;

                ValidateUseExpirationDates();
            end;
        }
        field(11; "SN Specific Tracking"; Boolean)
        {
            Caption = 'SN Specific Tracking';

            trigger OnValidate()
            begin
                if "SN Specific Tracking" = xRec."SN Specific Tracking" then
                    exit;

                if "SN Specific Tracking" then begin
                    TestSetSpecific(FieldCaption("SN Specific Tracking"));
                    Validate("SN Warehouse Tracking", true);
                    "SN Purchase Inbound Tracking" := true;
                    "SN Purchase Outbound Tracking" := true;
                    "SN Sales Inbound Tracking" := true;
                    "SN Sales Outbound Tracking" := true;
                    "SN Pos. Adjmt. Inb. Tracking" := true;
                    "SN Pos. Adjmt. Outb. Tracking" := true;
                    "SN Neg. Adjmt. Inb. Tracking" := true;
                    "SN Neg. Adjmt. Outb. Tracking" := true;
                    "SN Transfer Tracking" := true;
                    OnValidateSNSpecificTrackingOnAfterSet(Rec);
                end else begin
                    TestRemoveSpecificSN(FieldCaption("SN Specific Tracking"));
                    "SN Warehouse Tracking" := false;
                end;
            end;
        }
        field(13; "SN Info. Inbound Must Exist"; Boolean)
        {
            Caption = 'SN Info. Inbound Must Exist';
        }
        field(14; "SN Info. Outbound Must Exist"; Boolean)
        {
            Caption = 'SN Info. Outbound Must Exist';
        }
        field(15; "SN Warehouse Tracking"; Boolean)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'SN Warehouse Tracking';

            trigger OnValidate()
            begin
                if "SN Warehouse Tracking" then begin
                    TestField("SN Specific Tracking", true);
                    TestSetSpecific(FieldCaption("SN Warehouse Tracking"));
                end else
                    TestRemoveSpecificSN(FieldCaption("SN Warehouse Tracking"));

                TestNoWhseEntriesExist(FieldCaption("SN Warehouse Tracking"));
            end;
        }
        field(21; "SN Purchase Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'SN Purchase Inbound Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(22; "SN Purchase Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'SN Purchase Outbound Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(23; "SN Sales Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'SN Sales Inbound Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(24; "SN Sales Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'SN Sales Outbound Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(25; "SN Pos. Adjmt. Inb. Tracking"; Boolean)
        {
            Caption = 'SN Pos. Adjmt. Inb. Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(26; "SN Pos. Adjmt. Outb. Tracking"; Boolean)
        {
            Caption = 'SN Pos. Adjmt. Outb. Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(27; "SN Neg. Adjmt. Inb. Tracking"; Boolean)
        {
            Caption = 'SN Neg. Adjmt. Inb. Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(28; "SN Neg. Adjmt. Outb. Tracking"; Boolean)
        {
            Caption = 'SN Neg. Adjmt. Outb. Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(29; "SN Transfer Tracking"; Boolean)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'SN Transfer Tracking';

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(34; "Create SN Info on Posting"; Boolean)
        {
            Caption = 'Create SN Info. on posting';
        }
        field(41; "Lot Specific Tracking"; Boolean)
        {
            Caption = 'Lot Specific Tracking';

            trigger OnValidate()
            begin
                if "Lot Specific Tracking" = xRec."Lot Specific Tracking" then
                    exit;

                if "Lot Specific Tracking" then begin
                    TestSetSpecific(FieldCaption("Lot Specific Tracking"));
                    Validate("Lot Warehouse Tracking", true);
                    "Lot Purchase Inbound Tracking" := true;
                    "Lot Purchase Outbound Tracking" := true;
                    "Lot Sales Inbound Tracking" := true;
                    "Lot Sales Outbound Tracking" := true;
                    "Lot Pos. Adjmt. Inb. Tracking" := true;
                    "Lot Pos. Adjmt. Outb. Tracking" := true;
                    "Lot Neg. Adjmt. Inb. Tracking" := true;
                    "Lot Neg. Adjmt. Outb. Tracking" := true;
                    "Lot Transfer Tracking" := true;
                    OnValidateLotSpecificTrackingOnAfterSet(Rec)
                end else begin
                    TestRemoveSpecific(FieldCaption("Lot Specific Tracking"));
                    "Lot Warehouse Tracking" := false;
                end;
            end;
        }
        field(43; "Lot Info. Inbound Must Exist"; Boolean)
        {
            Caption = 'Lot Info. Inbound Must Exist';
        }
        field(44; "Lot Info. Outbound Must Exist"; Boolean)
        {
            Caption = 'Lot Info. Outbound Must Exist';
        }
        field(45; "Lot Warehouse Tracking"; Boolean)
        {
            Caption = 'Lot Warehouse Tracking';

            trigger OnValidate()
            begin
                if "Lot Warehouse Tracking" then begin
                    TestField("Lot Specific Tracking", true);
                    TestSetSpecific(FieldCaption("Lot Warehouse Tracking"));
                end else
                    TestRemoveSpecific(FieldCaption("Lot Warehouse Tracking"));

                TestNoWhseEntriesExist(FieldCaption("Lot Warehouse Tracking"));
            end;
        }
        field(51; "Lot Purchase Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lot Purchase Inbound Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(52; "Lot Purchase Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lot Purchase Outbound Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(53; "Lot Sales Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Lot Sales Inbound Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(54; "Lot Sales Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Lot Sales Outbound Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(55; "Lot Pos. Adjmt. Inb. Tracking"; Boolean)
        {
            Caption = 'Lot Pos. Adjmt. Inb. Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(56; "Lot Pos. Adjmt. Outb. Tracking"; Boolean)
        {
            Caption = 'Lot Pos. Adjmt. Outb. Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(57; "Lot Neg. Adjmt. Inb. Tracking"; Boolean)
        {
            Caption = 'Lot Neg. Adjmt. Inb. Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(58; "Lot Neg. Adjmt. Outb. Tracking"; Boolean)
        {
            Caption = 'Lot Neg. Adjmt. Outb. Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(59; "Lot Transfer Tracking"; Boolean)
        {
            Caption = 'Lot Transfer Tracking';

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(64; "Create Lot No. Info on posting"; Boolean)
        {
            Caption = 'Create Lot No. Info. on posting';
        }
        field(70; "Package Specific Tracking"; Boolean)
        {
            Caption = 'Package Specific Tracking';
            CaptionClass = '6,70';

            trigger OnValidate()
            begin
                if "Package Specific Tracking" = xRec."Package Specific Tracking" then
                    exit;

                if "Package Specific Tracking" then begin
                    TestSetSpecific(FieldCaption("Package Specific Tracking"));
                    Validate("Package Warehouse Tracking", true);
                    "Package Purchase Inb. Tracking" := true;
                    "Package Purch. Outb. Tracking" := true;
                    "Package Sales Inbound Tracking" := true;
                    "Package Sales Outb. Tracking" := true;
                    "Package Pos. Inb. Tracking" := true;
                    "Package Pos. Outb. Tracking" := true;
                    "Package Neg. Inb. Tracking" := true;
                    "Package Neg. Outb. Tracking" := true;
                    "Package Transfer Tracking" := true;
                    OnValidatePackageSpecificTrackingOnAfterSet(Rec);
                end else begin
                    TestRemoveSpecific(FieldCaption("Package Specific Tracking"));
                    "Package Warehouse Tracking" := false;
                end;
            end;
        }
        field(71; "Package Warehouse Tracking"; Boolean)
        {
            Caption = 'Package Warehouse Tracking';
            CaptionClass = '6,71';

            trigger OnValidate()
            begin
                if "Package Warehouse Tracking" then begin
                    TestField("Package Specific Tracking", true);
                    TestSetSpecific(FieldCaption("Package Warehouse Tracking"));
                end else
                    TestRemoveSpecific(FieldCaption("Package Warehouse Tracking"));

                TestNoWhseEntriesExist(FieldCaption("Package Warehouse Tracking"));
            end;
        }
        field(73; "Package Info. Inb. Must Exist"; Boolean)
        {
            Caption = 'Package Info. Inb. Must Exist';
            CaptionClass = '6,73';
        }
        field(74; "Package Info. Outb. Must Exist"; Boolean)
        {
            Caption = 'Lot Info. Outb. Must Exist';
            CaptionClass = '6,74';
        }
        field(75; "Package Purchase Inb. Tracking"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Package Purchase Inb. Tracking';
            CaptionClass = '6,75';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(76; "Package Purch. Outb. Tracking"; Boolean)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Package Purch. Outb. Tracking';
            CaptionClass = '6,76';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(77; "Package Sales Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Package Sales Inbound Tracking';
            CaptionClass = '6,77';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(78; "Package Sales Outb. Tracking"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Package Sales Outb. Tracking';
            CaptionClass = '6,78';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(79; "Package Pos. Inb. Tracking"; Boolean)
        {
            Caption = 'Package Pos. Inb. Tracking';
            CaptionClass = '6,79';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(80; "Package Pos. Outb. Tracking"; Boolean)
        {
            Caption = 'Package Pos. Outb. Tracking';
            CaptionClass = '6,80';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(81; "Package Neg. Inb. Tracking"; Boolean)
        {
            Caption = 'Package Neg. Inb. Tracking';
            CaptionClass = '6,81';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(82; "Package Neg. Outb. Tracking"; Boolean)
        {
            Caption = 'Package Neg. Outb. Tracking';
            CaptionClass = '6,82';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(83; "Package Transfer Tracking"; Boolean)
        {
            Caption = 'Package Transfer Tracking';
            CaptionClass = '6,83';

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestDelete();
    end;

    var
        Item: Record Item;
#pragma warning disable AA0470
        EntriesExistErr: Label 'Entries exist for item %1. The field %2 cannot be changed.';
#pragma warning restore AA0470
        CostingMethodErr: Label 'Costing Method is %1 for item %2. The field %3 cannot be changed.', Comment = '%1 = Costing Method, %2 = Item No., %3 - field caption.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'You cannot delete %1 %2 because it is used on one or more items.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        IgnoreExpirationDateErr: Label 'You cannot stop using expiration dates because item ledger entries with expiration dates exist for item %1.', Comment = '%1 is the item number';
        ExpDateCalcSetOnItemsQst: Label 'You cannot stop using expiration dates because they are set up for %1 item(s). Do you want to see a list of these items, and decide whether to remove the expiration dates?', Comment = '%1 is the number of items';
        ExpDateCalcSetOnItemsErr: Label 'You cannot stop using expiration dates because they are set up for %1 item(s).', Comment = '%1 is the number of items';
        IgnoreButManExpirDateReqdErr: Label 'You cannot stop using expiration dates if you require manual expiration date entry on the item tracking code.';
        IgnoreButStrictExpirationPostingErr: Label 'You cannot stop using expiration dates if you require strict expiration posting on the item tracking code.';
        WhseEntriesExistErr: Label 'You cannot change %1 because there are one or more warehouse entries for item %2.', Comment = '%1: Changed field name; %2: Item No.';

    local procedure EnsureNoExpirationDatesExistInRelatedItemLedgerEntries()
    var
        ItemsWithExpirationDate: Query "Items With Expiration Date";
    begin
        // find items using this tracking code
        ItemsWithExpirationDate.SetRange(Item_Tracking_Code, Code);

        // join with item ledger entries for these items that have an expiration date
        ItemsWithExpirationDate.SetFilter(Expiration_Date, '<>%1', 0D);
        if ItemsWithExpirationDate.Open() then
            if ItemsWithExpirationDate.Read() then // found some problematic data
                Error(IgnoreExpirationDateErr, ItemsWithExpirationDate.Item_No);
    end;

    local procedure EnsureRelatedItemsHaveNoExpirationDate()
    var
        EmptyDateFormula: DateFormula;
    begin
        Item.SetRange("Item Tracking Code", Code);
        Item.SetFilter("Expiration Calculation", '<>%1', EmptyDateFormula);
        if Item.FindSet() then begin
            if GuiAllowed then
                if Confirm(StrSubstNo(ExpDateCalcSetOnItemsQst, Item.Count)) then begin
                    PAGE.RunModal(PAGE::"Item List", Item);
                    Validate("Use Expiration Dates");
                    exit;
                end;

            Error(ExpDateCalcSetOnItemsErr, Item.Count);
        end;
    end;

    procedure TestSetSpecific(CurrentFieldName: Text[100])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Item.Reset();
        Item.SetRange("Item Tracking Code", Code);
        if Item.Find('-') then
            repeat
                ItemLedgEntry.SetRange("Item No.", Item."No.");
                if not ItemLedgEntry.IsEmpty() then
                    Error(EntriesExistErr, Item."No.", CurrentFieldName);
            until Item.Next() = 0;
    end;

    procedure TestRemoveSpecific(CurrentFieldName: Text)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Item.Reset();
        Item.SetRange("Item Tracking Code", Code);
        if Item.Find('-') then
            repeat
                ItemLedgEntry.SetRange("Item No.", Item."No.");
                if not ItemLedgEntry.IsEmpty() then
                    Error(EntriesExistErr, Item."No.", CurrentFieldName);
            until Item.Next() = 0;
    end;

    local procedure TestRemoveSpecificSN(CurrentFieldName: Text)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Item.Reset();
        Item.SetRange("Item Tracking Code", Code);
        if Item.Find('-') then
            repeat
                if Item."Costing Method" = Item."Costing Method"::Specific then
                    Error(CostingMethodErr, Item."Costing Method", Item."No.", CurrentFieldName);
                ItemLedgEntry.SetRange("Item No.", Item."No.");
                if not ItemLedgEntry.IsEmpty() then
                    Error(EntriesExistErr, Item."No.", CurrentFieldname);
            until Item.Next() = 0;
    end;

    local procedure TestDelete()
    begin
        Item.Reset();
        Item.SetRange("Item Tracking Code", Code);
        if not Item.IsEmpty() then
            Error(Text002, TableCaption(), Code);
    end;

    local procedure ValidateUseExpirationDates()
    begin
        // 1. check if it is possible to ignore expiration dates
        EnsureNoExpirationDatesExistInRelatedItemLedgerEntries();

        // 2. Check for inconsistencies that may be fixed
        // a. Items with expiration calculation not empty, suggesting these items expire
        EnsureRelatedItemsHaveNoExpirationDate();

        // b. Manual expiration date entry is required, which implies items using this tracking code should expire
        if "Man. Expir. Date Entry Reqd." then
            Error(IgnoreButManExpirDateReqdErr);

        // c. Strict expiration posting, which implies expiration dates matter
        if "Strict Expiration Posting" then
            Error(IgnoreButStrictExpirationPostingErr);
    end;

    procedure IsSpecific() Specific: Boolean
    begin
        Specific := "SN Specific Tracking" or "Lot Specific Tracking";

        OnAfterIsSpecific(Rec, Specific);
    end;

    procedure IsSpecificTrackingChanged(ItemTrackingCode2: Record "Item Tracking Code") TrackingChanged: Boolean
    begin
        TrackingChanged :=
            ("SN Specific Tracking" <> ItemTrackingCode2."SN Specific Tracking") or
            ("Lot Specific Tracking" <> ItemTrackingCode2."Lot Specific Tracking");

        OnAfterIsSpecificTrackingChanged(Rec, ItemTrackingCode2, TrackingChanged);
    end;

    procedure IsWarehouseTracking() WarehouseTracking: Boolean
    begin
        WarehouseTracking := "SN Warehouse Tracking" or "Lot Warehouse Tracking";

        OnAfterIsWarehouseTracking(Rec, WarehouseTracking);
    end;

    procedure IsWarehouseTrackingChanged(ItemTrackingCode2: Record "Item Tracking Code") TrackingChanged: Boolean
    begin
        TrackingChanged :=
            ("SN Warehouse Tracking" <> ItemTrackingCode2."SN Warehouse Tracking") or
            ("Lot Warehouse Tracking" <> ItemTrackingCode2."Lot Warehouse Tracking");

        OnAfterIsWarehouseTrackingChanged(Rec, ItemTrackingCode2, TrackingChanged);
    end;

    local procedure TestNoWhseEntriesExist(CurrentFieldName: Text)
    var
        TrackedItem: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        TrackedItem.SetRange("Item Tracking Code", Code);
        if TrackedItem.FindSet() then
            repeat
                WarehouseEntry.SetRange("Item No.", TrackedItem."No.");
                if not WarehouseEntry.IsEmpty() then
                    Error(WhseEntriesExistErr, CurrentFieldName, TrackedItem."No.");
            until TrackedItem.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSpecific(ItemTrackingCode: Record "Item Tracking Code"; var Specific: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSpecificTrackingChanged(ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingCode2: Record "Item Tracking Code"; var TrackingChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsWarehouseTracking(ItemTrackingCode: Record "Item Tracking Code"; var WarehouseTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsWarehouseTrackingChanged(ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingCode2: Record "Item Tracking Code"; var TrackingChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSNSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLotSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePackageSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;
}

