// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using System.Environment;
using System.Text;

table 5801 "Cost Adj. Item Bucket"
{
    DataClassification = CustomerContent;
    Caption = 'Cost Adj. Item Bucket';
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Item Filter"; Text[2048])
        {
            Caption = 'Item Filter';
            TableRelation = Item where("Cost is Adjusted" = const(false));
            ValidateTableRelation = false;
        }
        field(3; Status; Enum "Cost Adjustment Run Status")
        {
            Caption = 'Status';
        }
        field(4; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';
        }
        field(5; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';
        }
        field(6; "Timeout (Minutes)"; Integer)
        {
            Caption = 'Timeout (Minutes)';
            MinValue = 0;
            MaxValue = 720;
            InitValue = 60;
            BlankZero = true;
        }
        field(7; Company; Text[30])
        {
            Caption = 'Company';
            TableRelation = Company;
            ValidateTableRelation = false;
        }
        field(8; "Post to G/L"; Boolean)
        {
            Caption = 'Post to G/L';
        }
        field(9; Trace; Boolean)
        {
            Caption = 'Trace';
        }
        field(11; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
        field(12; "Last Error Call Stack"; Text[2048])
        {
            Caption = 'Last Error Call Stack';
        }
        field(13; "Failed Item No."; Code[20])
        {
            Caption = 'Failed Item No.';
            TableRelation = Item;
        }
        field(20; "Reschedule Count"; Integer)
        {
            Caption = 'Reschedule Count';
            MinValue = 0;
            MaxValue = 100;
            InitValue = 10;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }

    procedure CancelBucket(Cancel: Boolean)
    begin
        if Cancel then
            ModifyAll(Status, Status::"Canceled")
        else
            ModifyAll(Status, Status::"Not started");
    end;

    procedure GetLastLineNo(): Integer
    var
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
    begin
        CostAdjItemBucket.SetLoadFields("Line No.");
        if CostAdjItemBucket.FindLast() then
            exit(CostAdjItemBucket."Line No.");

        exit(0);
    end;

    procedure AddItemsToBucket(var Item: Record Item)
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        ItemFilter: Text;
    begin
        if Item.GetFilters() = '' then
            ItemFilter := '*'
        else
            ItemFilter := SelectionFilterManagement.GetSelectionFilterForItem(Item);

        InsertNotStartedCostAdjItemBucket(ItemFilter);
    end;

    procedure AddMissingItems()
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        Item.SetLoadFields("No.");
        if Item.FindSet() then
            repeat
                TempItem."No." := Item."No.";
                TempItem.Insert()
            until Item.Next() = 0;

        if CostAdjItemBucket.FindSet() then
            repeat
                TempItem.SetFilter("No.", CostAdjItemBucket."Item Filter");
                TempItem.DeleteAll();
            until CostAdjItemBucket.Next() = 0;

        TempItem.Reset();
        if TempItem.FindSet() then
            repeat
                Item.Get(TempItem."No.");
                Item.Mark(true);
            until TempItem.Next() = 0;

        Item.MarkedOnly(true);
        if not Item.IsEmpty() then
            InsertNotStartedCostAdjItemBucket(SelectionFilterManagement.GetSelectionFilterForItem(Item));
    end;

    local procedure InsertNotStartedCostAdjItemBucket(ItemFilter: Text)
    var
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.SetLoadFields("Automatic Cost Posting");
        InventorySetup.Get();

        CostAdjItemBucket.Init();
        CostAdjItemBucket."Line No." := CostAdjItemBucket.GetLastLineNo() + 10000;
        CostAdjItemBucket."Item Filter" := CopyStr(ItemFilter, 1, MaxStrLen(CostAdjItemBucket."Item Filter"));
        CostAdjItemBucket.Status := CostAdjItemBucket.Status::"Not started";
        CostAdjItemBucket."Timeout (Minutes)" := 60;
        CostAdjItemBucket."Reschedule Count" := 10;
        CostAdjItemBucket.Company := CopyStr(CompanyName(), 1, MaxStrLen(CostAdjItemBucket.Company));
        CostAdjItemBucket."Post to G/L" := InventorySetup."Automatic Cost Posting";
        CostAdjItemBucket.Insert();
    end;
}
