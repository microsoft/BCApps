// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

pageextension 99000900 "Mfg. Item Tracking Code Card" extends "Item Tracking Code Card"
{
    layout
    {
        addafter("SN Neg. Adjmt. Inb. Tracking")
        {
            field("SN Manuf. Inbound Tracking"; Rec."SN Manuf. Inbound Tracking")
            {
                ApplicationArea = Manufacturing;
                Caption = 'SN Manufacturing Tracking';
                ToolTip = 'Specifies that serial numbers are required with inbound posting from production - typically output.';
            }
        }
        addafter("SN Neg. Adjmt. Outb. Tracking")
        {
            field("SN Manuf. Outbound Tracking"; Rec."SN Manuf. Outbound Tracking")
            {
                ApplicationArea = Manufacturing;
                Caption = 'SN Manufacturing Tracking';
                ToolTip = 'Specifies that serial numbers are required with outbound posting from production - typically consumption.';
            }
        }
        addafter("Lot Neg. Adjmt. Inb. Tracking")
        {
            field("Lot Manuf. Inbound Tracking"; Rec."Lot Manuf. Inbound Tracking")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Lot Manufacturing Tracking';
                ToolTip = 'Specifies that lot numbers are required with outbound posting from production - typically output.';
            }
        }
        addafter("Lot Neg. Adjmt. Outb. Tracking")
        {
            field("Lot Manuf. Outbound Tracking"; Rec."Lot Manuf. Outbound Tracking")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Lot Manufacturing Tracking';
                ToolTip = 'Specifies that lot numbers are required with outbound posting from production - typically consumption.';
            }
        }
        addafter("Package Neg. Inb. Tracking")
        {
            field("Package Manuf. Inb. Tracking"; Rec."Package Manuf. Inb. Tracking")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Package Manufacturing Tracking';
                ToolTip = 'Specifies that package numbers are required with outbound posting from production - typically output.';
            }
        }
        addafter("Package Neg. Outb. Tracking")
        {
            field("Package Manuf. Outb. Tracking"; Rec."Package Manuf. Outb. Tracking")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Package Manufacturing Tracking';
                ToolTip = 'Specifies that package numbers are required with outbound posting from production - typically consumption.';
            }
        }
    }
}
