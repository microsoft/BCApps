// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46928 "BC14 No. Series"
{
    Caption = 'No. Series Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Default Nos."; Boolean) { Caption = 'Default Nos.'; }
        field(4; "Manual Nos."; Boolean) { Caption = 'Manual Nos.'; }
        field(5; "Date Order"; Boolean) { Caption = 'Date Order'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
