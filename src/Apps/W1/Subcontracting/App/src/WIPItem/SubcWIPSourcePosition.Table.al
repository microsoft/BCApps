// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

table 20583 "Subc. WIP Source Position"
{
    Access = Internal;
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Lineage ID"; Guid) { }
        field(3; "Prod. Order Line No."; Integer) { }
        field(4; "Routing Reference No."; Integer) { }
        field(5; "Routing No."; Code[20]) { }
        field(6; "Operation No."; Code[10]) { }
        field(7; "Item No."; Code[20]) { }
        field(8; "Variant Code"; Code[10]) { }
        field(9; "Location Code"; Code[10]) { }
        field(10; "In Transit"; Boolean) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Position; "Lineage ID", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Item No.", "Variant Code", "Location Code", "In Transit") { Unique = true; }
    }
}
