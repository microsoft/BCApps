// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46898 "BC14 Inventory Posting Setup"
{
    Caption = 'Inventory Posting Setup Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Location Code"; Code[10]) { Caption = 'Location Code'; }
        field(2; "Invt. Posting Group Code"; Code[20]) { Caption = 'Invt. Posting Group Code'; }
        field(6; "Inventory Account"; Code[20]) { Caption = 'Inventory Account'; }
        field(20; Description; Text[100]) { Caption = 'Description'; }
        field(5800; "Inventory Account (Interim)"; Code[20]) { Caption = 'Inventory Account (Interim)'; }
#pragma warning disable AS0099 // Accepted: Migration buffer field IDs mirror the legacy BC14 source schema; renumbering would break source-data mapping.
        field(99000750; "WIP Account"; Code[20]) { Caption = 'WIP Account'; }
        field(99000753; "Material Variance Account"; Code[20]) { Caption = 'Material Variance Account'; }
        field(99000754; "Capacity Variance Account"; Code[20]) { Caption = 'Capacity Variance Account'; }
        field(99000755; "Mfg. Overhead Variance Account"; Code[20]) { Caption = 'Mfg. Overhead Variance Account'; }
        field(99000756; "Cap. Overhead Variance Account"; Code[20]) { Caption = 'Cap. Overhead Variance Account'; }
        field(99000757; "Subcontracted Variance Account"; Code[20]) { Caption = 'Subcontracted Variance Account'; }
        field(99000758; "Mat. Non-Inv. Variance Acc."; Code[20]) { Caption = 'Mat. Non-Inv. Variance Acc.'; }
#pragma warning restore AS0099
    }

    keys
    {
        key(Key1; "Location Code", "Invt. Posting Group Code") { Clustered = true; }
    }
}
