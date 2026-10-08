// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46913 "BC14 Shipment Method"
{
    Caption = 'Shipment Method Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
