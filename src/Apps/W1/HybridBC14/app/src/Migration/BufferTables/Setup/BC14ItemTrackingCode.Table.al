// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46916 "BC14 Item Tracking Code"
{
    Caption = 'Item Tracking Code Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(10; "SN Specific Tracking"; Boolean) { Caption = 'SN Specific Tracking'; }
        field(11; "SN Sales Inbound Tracking"; Boolean) { Caption = 'SN Sales Inbound Tracking'; }
        field(12; "SN Sales Outbound Tracking"; Boolean) { Caption = 'SN Sales Outbound Tracking'; }
        field(13; "SN Purchase Inbound Tracking"; Boolean) { Caption = 'SN Purchase Inbound Tracking'; }
        field(14; "SN Purchase Outbound Tracking"; Boolean) { Caption = 'SN Purchase Outbound Tracking'; }
        field(15; "SN Pos. Adjmt. Inb. Tracking"; Boolean) { Caption = 'SN Pos. Adjmt. Inb. Tracking'; }
        field(16; "SN Pos. Adjmt. Outb. Tracking"; Boolean) { Caption = 'SN Pos. Adjmt. Outb. Tracking'; }
        field(17; "SN Neg. Adjmt. Inb. Tracking"; Boolean) { Caption = 'SN Neg. Adjmt. Inb. Tracking'; }
        field(18; "SN Neg. Adjmt. Outb. Tracking"; Boolean) { Caption = 'SN Neg. Adjmt. Outb. Tracking'; }
        field(20; "SN Transfer Tracking"; Boolean) { Caption = 'SN Transfer Tracking'; }
        field(40; "Lot Specific Tracking"; Boolean) { Caption = 'Lot Specific Tracking'; }
        field(41; "Lot Sales Inbound Tracking"; Boolean) { Caption = 'Lot Sales Inbound Tracking'; }
        field(42; "Lot Sales Outbound Tracking"; Boolean) { Caption = 'Lot Sales Outbound Tracking'; }
        field(43; "Lot Purchase Inbound Tracking"; Boolean) { Caption = 'Lot Purchase Inbound Tracking'; }
        field(44; "Lot Purchase Outbound Tracking"; Boolean) { Caption = 'Lot Purchase Outbound Tracking'; }
        field(50; "Lot Transfer Tracking"; Boolean) { Caption = 'Lot Transfer Tracking'; }
        field(80; "SN Warehouse Tracking"; Boolean) { Caption = 'SN Warehouse Tracking'; }
        field(81; "Lot Warehouse Tracking"; Boolean) { Caption = 'Lot Warehouse Tracking'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
