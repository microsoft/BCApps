// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46901 "BC14 Post Code"
{
    Caption = 'Post Code Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "City"; Text[30]) { Caption = 'City'; }
        field(3; "Search City"; Code[30]) { Caption = 'Search City'; }
        field(4; "Country/Region Code"; Code[10]) { Caption = 'Country/Region Code'; }
        field(5; "County"; Text[30]) { Caption = 'County'; }
        field(6; "Time Zone"; Text[180]) { Caption = 'Time Zone'; }
    }

    keys
    {
        key(Key1; "Code", "City") { Clustered = true; }
    }
}
