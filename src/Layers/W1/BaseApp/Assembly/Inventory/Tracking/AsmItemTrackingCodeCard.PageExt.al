// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

pageextension 935 "Asm. Item Tracking Code Card" extends "Item Tracking Code Card"
{
    layout
    {
        addafter("SN Neg. Adjmt. Inb. Tracking")
        {
            field("SN Assembly Inbound Tracking"; Rec."SN Assembly Inbound Tracking")
            {
                ApplicationArea = Assembly;
                Caption = 'SN Assembly Tracking';
                ToolTip = 'Specifies that serial numbers are required with inbound posting from assembly orders.';
            }
        }
        addafter("SN Neg. Adjmt. Outb. Tracking")
        {
            field("SN Assembly Outbound Tracking"; Rec."SN Assembly Outbound Tracking")
            {
                ApplicationArea = Assembly;
                Caption = 'SN Assembly Tracking';
                ToolTip = 'Specifies that serial numbers are required with outbound posting from assembly orders.';
            }
        }
        addafter("Lot Neg. Adjmt. Inb. Tracking")
        {
            field("Lot Assembly Inbound Tracking"; Rec."Lot Assembly Inbound Tracking")
            {
                ApplicationArea = Assembly;
                Caption = 'Lot Assembly Tracking';
                ToolTip = 'Specifies that lot numbers are required with inbound posting from assembly orders.';
            }
        }
        addafter("Lot Neg. Adjmt. Outb. Tracking")
        {
            field("Lot Assembly Outbound Tracking"; Rec."Lot Assembly Outbound Tracking")
            {
                ApplicationArea = Assembly;
                Caption = 'Lot Assembly Tracking';
                ToolTip = 'Specifies that lot numbers are required with outbound posting from assembly orders.';
            }
        }
        addafter("Package Neg. Inb. Tracking")
        {
            field("Package Assembly Inb. Tracking"; Rec."Package Assembly Inb. Tracking")
            {
                ApplicationArea = Assembly;
                Caption = 'Package Assembly Tracking';
                ToolTip = 'Specifies that package numbers are required with inbound posting from assembly orders.';
            }
        }
        addafter("Package Neg. Outb. Tracking")
        {
            field("Package Assembly Out. Tracking"; Rec."Package Assembly Out. Tracking")
            {
                ApplicationArea = Assembly;
                Caption = 'Package Assembly Tracking';
                ToolTip = 'Specifies that package numbers are required with outbound posting from assembly orders.';
            }
        }
    }
}
