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
            Caption = 'Buffer Entry No.';
            ToolTip = 'Specifies the unique entry no. for the buffer record.';
        }
        field(2; "Qty. To Handle (Base)"; Decimal)
        {
            Caption = 'Qty. To Handle (Base)';
            ToolTip = 'Specifies the quantity to use to fulfill the disposition. Only necessary with specific quantity is used.';
            AutoFormatType = 0;
            DecimalPlaces = 0 : 5;
        }
        field(3; "Quantity Behavior"; Enum "Qlty. Quantity Behavior")
        {
            Caption = 'Quantity Behavior';
            ToolTip = 'Specifies the type of quantity to use to fulfill the disposition.';
        }
        field(4; "Location Filter"; Text[2048])
        {
            Caption = 'Location Filter';
            ToolTip = 'Specifies the from location filter date for dispositions that need a from location.';
        }
        field(5; "Bin Filter"; Text[2048])
        {
            Caption = 'Bin Filter';
            ToolTip = 'Specifies the from bin filter date for dispositions that need a from location.';
        }
        field(6; "Entry Behavior"; Enum "Qlty. Item Adj. Post Behavior")
        {
            Caption = 'Entry Behavior';
            ToolTip = 'Specifies whether to just create entries or post immediately after.';
        }
        field(7; "Disposition Action"; Enum "Qlty. Disposition Action")
        {
            Caption = 'Disposition Action';
            ToolTip = 'Specifies the type of disposition action this buffer is intended for.';
        }
        field(10; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
            ToolTip = 'Specifies the new lot for dispositions that change the lot no.';
        }
        field(11; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
            ToolTip = 'Specifies the new serial for dispositions that change the serial no.';
        }
        field(12; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            ToolTip = 'Specifies the new package for dispositions that change the package no.';
        }
        field(13; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';
            ToolTip = 'Specifies the new expiration date for dispositions that change the expiration date.';
        }
        field(14; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code';
            ToolTip = 'Specifies the new location code for dispositions that moves the location.';
        }
        field(15; "New Bin Code"; Code[20])
        {
            Caption = 'New Bin Code';
            ToolTip = 'Specifies the new bin code for dispositions that moves the bin.';
        }
        field(16; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code for the change.';
        }
        field(17; "In-Transit Location Code"; Code[10])
        {
            Caption = 'In-Transit Location Code';
            ToolTip = 'Specifies the in-transit location code for use with documents such as transfer orders..';
        }
        field(18; "External Document No."; Code[40])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies an external document no to be used in dispositions such as purchase returns for the credit memo no.';
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
