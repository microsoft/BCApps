// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46903 "BC14 Unit of Measure"
{
    Caption = 'Unit of Measure Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Description"; Text[50]) { Caption = 'Description'; }
        field(3; "International Standard Code"; Code[10]) { Caption = 'International Standard Code'; }
        field(4; "Symbol"; Text[10]) { Caption = 'Symbol'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
