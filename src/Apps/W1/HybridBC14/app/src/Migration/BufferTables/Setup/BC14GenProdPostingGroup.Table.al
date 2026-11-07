// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46907 "BC14 Gen. Prod. Posting Group"
{
    Caption = 'Gen. Product Posting Group Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Def. VAT Prod. Posting Group"; Code[20]) { Caption = 'Def. VAT Prod. Posting Group'; }
        field(4; "Auto Insert Default"; Boolean) { Caption = 'Auto Insert Default'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
