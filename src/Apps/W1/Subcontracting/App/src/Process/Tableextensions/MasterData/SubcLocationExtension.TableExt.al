// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;

tableextension 99001529 "Subc. Location Extension" extends Location
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        modify("Require Put-away")
        {
            trigger OnAfterValidate()
            begin
                TestField("Direct Transfer Posting", "Direct Transfer Post. Type"::Empty);
            end;
        }
        modify("Require Receive")
        {
            trigger OnAfterValidate()
            begin
                TestField("Direct Transfer Posting", "Direct Transfer Post. Type"::Empty);
            end;
        }
        modify("Use As In-Transit")
        {
            trigger OnAfterValidate()
            begin
                TestField("Direct Transfer Posting", "Direct Transfer Post. Type"::Empty);
            end;
        }
        modify("Use Cross-Docking")
        {
            trigger OnAfterValidate()
            begin
                TestField("Direct Transfer Posting", "Direct Transfer Post. Type"::Empty);
            end;
        }
        field(99001553; "Direct Transfer Posting"; Enum "Direct Transfer Post. Type")
        {
            Caption = 'Direct Transfer Posting';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if Direct Transfer should be posted separately as Shipment and Receipt or as single Direct Transfer document.';
            trigger OnValidate()
            begin
                CheckDirectTransferType();
            end;
        }
    }
    procedure CheckDirectTransferType()
    begin
        if "Direct Transfer Posting" = "Direct Transfer Post. Type"::Empty then
            exit;
        if "Direct Transfer Posting" = "Direct Transfer Post. Type"::"Direct Transfer" then
            CheckOutboundWarehouseHandling();
        CheckInboundWarehouseHandling();
    end;

    procedure CheckInboundWarehouseHandling()
    begin
        TestField("Require Put-away", false);
        TestField("Use Cross-Docking", false);
        TestField("Require Receive", false);
    end;

    procedure CheckOutboundWarehouseHandling()
    begin
        TestField("Require Pick", false);
        TestField("Use Cross-Docking", false);
        TestField("Require Shipment", false);
    end;
}