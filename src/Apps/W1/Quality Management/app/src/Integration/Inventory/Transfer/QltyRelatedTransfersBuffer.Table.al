// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer;

using Microsoft.Inventory.Location;

table 20423 "Qlty. Related Transfers Buffer"
{
    Caption = 'Quality Related Transfer Orders Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Buffer Entry No."; Integer)
        {
            Caption = 'Buffer Entry  No.';
        }
        field(2; "Transfer Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the transfer document number.';
        }
        field(3; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(4; "Transfer Document Type"; Enum "Qlty. Transfer Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of transfer document.';
        }
        field(5; Status; Enum "Qlty. Transfer Buffer Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the transfer document.';
        }
        field(6; "Transfer-from Code"; Code[10])
        {
            TableRelation = Location.Code;
            Caption = 'Transfer From';
            ToolTip = 'Specifies the location from which the items are being transferred.';
        }
        field(7; "Transfer-to Code"; Code[10])
        {
            TableRelation = Location.Code;
            Caption = 'Transfer To';
            ToolTip = 'Specifies the location to which the items are being transferred.';
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date of the transfer.';
        }
    }

    keys
    {
        key(Key1; "Buffer Entry No.")
        {
            Clustered = true;
        }
    }
}
