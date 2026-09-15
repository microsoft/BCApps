// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46917 "BC14 Tariff Number"
{
    Caption = 'Tariff Number Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Supplementary Units"; Boolean) { Caption = 'Supplementary Units'; }
    }

    keys
    {
        key(Key1; "No.") { Clustered = true; }
    }
}
