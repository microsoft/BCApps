// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46930 "BC14 Item Attribute"
{
    Caption = 'Item Attribute Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "ID"; Integer) { Caption = 'ID'; }
        field(2; "Name"; Text[250]) { Caption = 'Name'; }
        field(3; "Type"; Option) { Caption = 'Type'; OptionMembers = Option,Text,Integer,Decimal,Date; }
        field(4; "Unit of Measure"; Text[100]) { Caption = 'Unit of Measure'; }
        field(5; "Blocked"; Boolean) { Caption = 'Blocked'; }
    }

    keys
    {
        key(Key1; "ID") { Clustered = true; }
    }
}
