// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46935 "BC14 BOM Component"
{
    Caption = 'BOM Component Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Parent Item No."; Code[20]) { Caption = 'Parent Item No.'; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Type"; Option) { Caption = 'Type'; OptionMembers = " ",Item,Resource; }
        field(4; "No."; Code[20]) { Caption = 'No.'; }
        field(7; "Description"; Text[100]) { Caption = 'Description'; }
        field(8; "Unit of Measure Code"; Code[10]) { Caption = 'Unit of Measure Code'; }
        field(9; "Quantity per"; Decimal) { Caption = 'Quantity per'; DecimalPlaces = 0 : 5; }
        field(10; "Position"; Code[10]) { Caption = 'Position'; }
        field(11; "Position 2"; Code[10]) { Caption = 'Position 2'; }
        field(12; "Position 3"; Code[10]) { Caption = 'Position 3'; }
        field(15; "Variant Code"; Code[10]) { Caption = 'Variant Code'; }
    }

    keys
    {
        key(Key1; "Parent Item No.", "Line No.") { Clustered = true; }
    }
}
