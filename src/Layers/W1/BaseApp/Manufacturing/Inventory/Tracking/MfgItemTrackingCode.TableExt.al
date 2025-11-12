// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Manufacturing.Document;

tableextension 99000900 "Mfg. Item Tracking Code" extends "Item Tracking Code"
{
    fields
    {
        field(30; "SN Manuf. Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'SN Manuf. Inbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(31; "SN Manuf. Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'SN Manuf. Outbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(60; "Lot Manuf. Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Lot Manuf. Inbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(61; "Lot Manuf. Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Lot Manuf. Outbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(84; "Package Manuf. Inb. Tracking"; Boolean)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Package Manuf. Inbound Tracking';
            CaptionClass = '6,84';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(85; "Package Manuf. Outb. Tracking"; Boolean)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Package Manuf. Outbound Tracking';
            CaptionClass = '6,85';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
    }
}
