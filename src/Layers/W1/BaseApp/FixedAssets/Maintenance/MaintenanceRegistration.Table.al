// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Vendor;

table 5616 "Maintenance Registration"
{
    Caption = 'Maintenance Registration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            ToolTip = 'Specifies the number of the related fixed asset.';
            NotBlank = true;
            TableRelation = "Fixed Asset";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Service Date"; Date)
        {
            Caption = 'Service Date';
            ToolTip = 'Specifies the date when the fixed asset is being serviced.';
        }
        field(4; "Maintenance Vendor No."; Code[20])
        {
            Caption = 'Maintenance Vendor No.';
            ToolTip = 'Specifies the number of the vendor who services the fixed asset for this entry.';
            TableRelation = Vendor;
        }
        field(5; Comment; Text[50])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies a comment for the service, repairs or maintenance to be performed on the fixed asset.';
        }
        field(6; "Service Agent Name"; Text[30])
        {
            Caption = 'Service Agent Name';
            ToolTip = 'Specifies the name of the service agent who is servicing the fixed asset.';
        }
        field(7; "Service Agent Phone No."; Text[30])
        {
            Caption = 'Service Agent Phone No.';
            ToolTip = 'Specifies the phone number of the service agent who is servicing the fixed asset.';
            ExtendedDatatype = PhoneNo;
        }
        field(8; "Service Agent Mobile Phone"; Text[30])
        {
            Caption = 'Service Agent Mobile Phone';
            ToolTip = 'Specifies the mobile phone number of the service agent who is servicing the fixed asset.';
            ExtendedDatatype = PhoneNo;
        }
    }

    keys
    {
        key(Key1; "FA No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FA.LockTable();
        FA.Get("FA No.");
    end;

    var
        FA: Record "Fixed Asset";
}

