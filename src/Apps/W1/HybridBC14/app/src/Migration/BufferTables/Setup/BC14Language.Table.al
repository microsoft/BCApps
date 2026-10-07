// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46902 "BC14 Language"
{
    Caption = 'Language Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Name"; Text[50]) { Caption = 'Name'; }
        field(3; "Windows Language ID"; Integer) { Caption = 'Windows Language ID'; }
        field(4; "Language ID"; Integer) { Caption = 'Language ID'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
