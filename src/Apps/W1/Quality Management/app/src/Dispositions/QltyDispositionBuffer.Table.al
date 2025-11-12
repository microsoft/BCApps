// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions;

table 20424 "Qlty. Disposition Buffer"
{
    Caption = 'Quality Disposition Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Buffer Entry No."; Integer)
        {
            Description = 'Specifies the unique entry no. for the buffer record.';
            Caption = 'Buffer Entry No.';
        }
        field(2; "Qty. To Handle (Base)"; Decimal)
        {
            Description = 'Specifies the quantity to use to fulfill the disposition. Only necessary with specific quantity is used.';
            Caption = 'Qty. To Handle (Base)';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(3; "Quantity Behavior"; Enum "Qlty. Quantity Behavior")
        {
            Description = 'Specifies the type of quantity to use to fulfill the disposition.';
            Caption = 'Quantity Behavior';
        }
        field(4; "Location Filter"; Text[2048])
        {
            Description = 'Specifies the from location filter date for dispositions that need a from location.';
            Caption = 'Location Filter';
        }
        field(5; "Bin Filter"; Text[2048])
        {
            Description = 'Specifies the from bin filter date for dispositions that need a from location.';
            Caption = 'Bin Filter';
        }
        field(6; "Entry Behavior"; Enum "Qlty. Item Adj. Post Behavior")
        {
            Description = 'Specifies whether to just create entries or post immediately after.';
            Caption = 'Entry Behavior';
        }
        field(7; "Disposition Action"; Enum "Qlty. Disposition Action")
        {
            Description = 'Specifies the type of disposition action this buffer is intended for.';
            Caption = 'Disposition Action';
        }
        field(10; "New Lot No."; Code[50])
        {
            Description = 'Specifies the new lot for dispositions that change the lot no.';
            Caption = 'New Lot No.';
        }
        field(11; "New Serial No."; Code[50])
        {
            Description = 'Specifies the new serial for dispositions that change the serial no.';
            Caption = 'New Serial No.';
        }
        field(12; "New Package No."; Code[50])
        {
            Description = 'Specifies the new package for dispositions that change the package no.';
            Caption = 'New Package No.';
        }
        field(13; "New Expiration Date"; Date)
        {
            Description = 'Specifies the new expiration date for dispositions that change the expiration date.';
            Caption = 'New Expiration Date';
        }
        field(14; "New Location Code"; Code[10])
        {
            Description = 'Specifies the new location code for dispositions that moves the location.';
            Caption = 'New Location Code';
        }
        field(15; "New Bin Code"; Code[20])
        {
            Description = 'Specifies the new bin code for dispositions that moves the bin.';
            Caption = 'New Bin Code';
        }
        field(16; "Reason Code"; Code[10])
        {
            Description = 'Specifies the reason code for the change.';
            Caption = 'Reason Code';
        }
        field(17; "In-Transit Location Code"; Code[10])
        {
            Description = 'Specifies the in-transit location code for use with documents such as transfer orders..';
            Caption = 'In-Transit Location Code';
        }
        field(18; "External Document No."; Code[40])
        {
            Description = 'Specifies an external document no to be used in dispositions such as purchase returns for the credit memo no.';
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(Key1; "Buffer Entry No.")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the 'from' location code.
    /// </summary>
    /// <returns></returns>
    procedure GetFromLocationCode(): Code[10]
    begin
        exit(CopyStr(Rec."Location Filter", 1, 10));
    end;

    /// <summary>
    /// Gets the 'from' bin code.
    /// </summary>
    /// <returns></returns>
    procedure GetFromBinCode(): Code[20]
    begin
        exit(CopyStr(Rec."Bin Filter", 1, 20));
    end;
}
