// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.BOM;

tableextension 910 "Asm. Item Tracking Code" extends "Item Tracking Code"
{
    fields
    {
        field(32; "SN Assembly Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'SN Assembly Inbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(33; "SN Assembly Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'SN Assembly Outbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("SN Specific Tracking", false);
            end;
        }
        field(62; "Lot Assembly Inbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Lot Assembly Inbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(63; "Lot Assembly Outbound Tracking"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Lot Assembly Outbound Tracking';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Lot Specific Tracking", false);
            end;
        }
        field(86; "Package Assembly Inb. Tracking"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Package Assembly Inbound Tracking';
            CaptionClass = '6,86';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
        field(87; "Package Assembly Out. Tracking"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Package Assembly Outbound Tracking';
            CaptionClass = '6,87';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                TestField("Package Specific Tracking", false);
            end;
        }
    }
}