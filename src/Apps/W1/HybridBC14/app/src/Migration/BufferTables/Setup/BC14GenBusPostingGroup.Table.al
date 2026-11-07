// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46906 "BC14 Gen. Bus. Posting Group"
{
    Caption = 'Gen. Business Posting Group Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Def. VAT Bus. Posting Group"; Code[20]) { Caption = 'Def. VAT Bus. Posting Group'; }
        field(4; "Auto Insert Default"; Boolean) { Caption = 'Auto Insert Default'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
