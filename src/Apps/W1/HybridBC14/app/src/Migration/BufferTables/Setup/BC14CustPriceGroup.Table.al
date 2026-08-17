// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46921 "BC14 Cust. Price Group"
{
    Caption = 'BC14 Cust. Price Group Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Allow Invoice Disc."; Boolean) { Caption = 'Allow Invoice Disc.'; }
        field(4; "Price Includes VAT"; Boolean) { Caption = 'Price Includes VAT'; }
        field(5; "VAT Bus. Posting Gr. (Price)"; Code[20]) { Caption = 'VAT Bus. Posting Gr. (Price)'; }
        field(6; "Allow Line Disc."; Boolean) { Caption = 'Allow Line Disc.'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
