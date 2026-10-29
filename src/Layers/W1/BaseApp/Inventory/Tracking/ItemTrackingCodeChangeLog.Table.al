// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;

table 7047 "Item Tracking Code Change Log"
{
    Caption = 'Item Tracking Code Change Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "Item Tracking Code Change Log";
    LookupPageId = "Item Tracking Code Change Log";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item."No.";
            ToolTip = 'Specifies the item whose item tracking code was changed.';
        }
        field(2; "Change DateTime"; DateTime)
        {
            Caption = 'Change DateTime';
            ToolTip = 'Specifies the actual date and time when the item tracking code was changed.';
        }
        field(3; "Previous Item Tracking Code"; Code[10])
        {
            Caption = 'Previous Item Tracking Code';
            TableRelation = "Item Tracking Code".Code;
            ToolTip = 'Specifies the item tracking code before the change.';
        }
        field(4; "New Item Tracking Code"; Code[10])
        {
            Caption = 'New Item Tracking Code';
            TableRelation = "Item Tracking Code".Code;
            ToolTip = 'Specifies the item tracking code after the change.';
        }
    }

    keys
    {
        key(PK; "Item No.", "Change DateTime")
        {
            Clustered = true;
        }
        key(PreviousItemTrackingCode; "Previous Item Tracking Code")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Item No.");
        if "Change DateTime" = 0DT then
            "Change DateTime" := CurrentDateTime();
        if "Previous Item Tracking Code" = "New Item Tracking Code" then
            Error(TrackingCodesMustDifferErr);
    end;

    trigger OnModify()
    begin
        Error(ChangeLogImmutableErr);
    end;

    trigger OnDelete()
    begin
        Error(ChangeLogImmutableErr);
    end;

    trigger OnRename()
    begin
        Error(ChangeLogImmutableErr);
    end;

    var
        ChangeLogImmutableErr: Label 'Item tracking code change log entries cannot be modified or deleted.';
        TrackingCodesMustDifferErr: Label 'The previous and new item tracking codes must be different.';
}
