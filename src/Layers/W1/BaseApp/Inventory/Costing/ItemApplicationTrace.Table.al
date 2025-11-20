// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using Microsoft.Foundation.Enums;

table 5812 "Item Application Trace"
{
    Caption = 'Item Application Trace';
    TableType = Temporary;

    fields
    {
        field(1; "From Entry No."; Integer)
        {

        }
        field(2; "Entry No."; Integer)
        {

        }
        field(3; Level; Integer)
        {

        }
        field(100; "Item No."; Code[20])
        {

        }
        field(101; "Location Code"; Code[10])
        {

        }
        field(102; "Variant Code"; Code[10])
        {

        }
        field(103; "Posting Date"; Date)
        {

        }
        field(104; Positive; Boolean)
        {

        }
        field(110; "Order Type"; Enum "Inventory Order Type")
        {

        }
        field(111; "Order No."; Code[20])
        {

        }
        field(112; "Order Line No."; Integer)
        {

        }
    }

    keys
    {
        key(PK; "From Entry No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure CreateChain(FromItemLedgerEntry: Record "Item Ledger Entry"; var AppliedItemLedgerEntry: Record "Item Ledger Entry")
    begin
        // parent entry
        Rec.Init();
        Rec."From Entry No." := FromItemLedgerEntry."Entry No.";
        Rec."Entry No." := Rec."From Entry No.";
        Rec.Level := 0;
        Rec."Item No." := FromItemLedgerEntry."Item No.";
        Rec."Location Code" := FromItemLedgerEntry."Location Code";
        Rec."Variant Code" := FromItemLedgerEntry."Variant Code";
        Rec.Positive := FromItemLedgerEntry.Positive;
        Rec."Order Type" := FromItemLedgerEntry."Order Type";
        Rec."Order No." := FromItemLedgerEntry."Order No.";
        Rec."Order Line No." := FromItemLedgerEntry."Order Line No.";
        Rec.Insert();

        // child entries
        if AppliedItemLedgerEntry.FindSet() then
            repeat
                Rec.Init();
                Rec."From Entry No." := FromItemLedgerEntry."Entry No.";
                Rec."Entry No." := AppliedItemLedgerEntry."Entry No.";
                Rec.Level := 1;
                Rec."Item No." := AppliedItemLedgerEntry."Item No.";
                Rec."Location Code" := AppliedItemLedgerEntry."Location Code";
                Rec."Variant Code" := AppliedItemLedgerEntry."Variant Code";
                Rec.Positive := AppliedItemLedgerEntry.Positive;
                Rec."Order Type" := AppliedItemLedgerEntry."Order Type";
                Rec."Order No." := AppliedItemLedgerEntry."Order No.";
                Rec."Order Line No." := AppliedItemLedgerEntry."Order Line No.";
                if Rec.Insert() then;
            until AppliedItemLedgerEntry.Next() = 0;
    end;

    procedure AddChain(FromItemLedgerEntryNo: Integer; var ItemApplicationTrace: Record "Item Application Trace")
    begin
        if ItemApplicationTrace.FindSet() then
            repeat
                Rec := ItemApplicationTrace;
                Rec."From Entry No." := FromItemLedgerEntryNo;
                if Rec.Insert() then;
            until ItemApplicationTrace.Next() = 0;
    end;
}
