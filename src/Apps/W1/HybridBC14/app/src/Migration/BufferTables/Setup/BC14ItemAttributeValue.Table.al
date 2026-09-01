// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46931 "BC14 Item Attribute Value"
{
    Caption = 'Item Attribute Value Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Attribute ID"; Integer) { Caption = 'Attribute ID'; }
        field(2; "ID"; Integer) { Caption = 'ID'; }
        field(3; "Value"; Text[250]) { Caption = 'Value'; }
        field(4; "Numeric Value"; Decimal) { Caption = 'Numeric Value'; }
        field(5; "Date Value"; Date) { Caption = 'Date Value'; }
        field(6; "Blocked"; Boolean) { Caption = 'Blocked'; }
    }

    keys
    {
        key(Key1; "Attribute ID", "ID") { Clustered = true; }
    }
}
