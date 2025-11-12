// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;

table 6506 "Item Tracking Comment"
{
    Caption = 'Item Tracking Comment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Item Tracking Comment Type")
        {
            Caption = 'Type';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(3; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(4; "Serial/Lot No."; Code[50])
        {
            Caption = 'Serial/Lot No.';
            NotBlank = true;
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; Date; Date)
        {
            Caption = 'Date';
        }
        field(13; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; Type, "Item No.", "Variant Code", "Serial/Lot No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CopyComments(CommentType: Enum "Item Tracking Comment Type"; ItemNo: Code[20]; VariantCode: Code[10]; TrackingNo: Code[50]; NewTrackingNo: Code[50])
    var
        ItemTrackingComment: Record "Item Tracking Comment";
        NewItemTrackingComment: Record "Item Tracking Comment";
    begin
        if TrackingNo = NewTrackingNo then
            exit;

        ItemTrackingComment.SetRange(Type, CommentType);
        ItemTrackingComment.SetRange("Item No.", ItemNo);
        ItemTrackingComment.SetRange("Variant Code", VariantCode);
        ItemTrackingComment.SetRange("Serial/Lot No.", TrackingNo);
        if ItemTrackingComment.IsEmpty() then
            exit;

        NewItemTrackingComment.SetRange(Type, CommentType);
        NewItemTrackingComment.SetRange("Item No.", ItemNo);
        NewItemTrackingComment.SetRange("Variant Code", VariantCode);
        NewItemTrackingComment.SetRange("Serial/Lot No.", NewTrackingNo);
        if not NewItemTrackingComment.IsEmpty() then
            NewItemTrackingComment.DeleteAll();

        if ItemTrackingComment.FindSet() then
            repeat
                NewItemTrackingComment := ItemTrackingComment;
                NewItemTrackingComment."Serial/Lot No." := NewTrackingNo;
                NewItemTrackingComment.Insert();
            until ItemTrackingComment.Next() = 0;
    end;
}

