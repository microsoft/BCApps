// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46900 "BC14 Country/Region"
{
    Caption = 'Country/Region Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Name"; Text[50]) { Caption = 'Name'; }
        field(4; "ISO Code"; Code[2]) { Caption = 'ISO Code'; }
        field(5; "ISO Numeric Code"; Code[3]) { Caption = 'ISO Numeric Code'; }
        field(7; "EU Country/Region Code"; Code[10]) { Caption = 'EU Country/Region Code'; }
        field(8; "Intrastat Code"; Code[10]) { Caption = 'Intrastat Code'; }
        field(9; "Address Format"; Option) { Caption = 'Address Format'; OptionMembers = "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City"; }
        field(10; "Contact Address Format"; Option) { Caption = 'Contact Address Format'; OptionMembers = First,"After Company Name",Last; }
        field(11; "VAT Scheme"; Code[10]) { Caption = 'VAT Scheme'; }
        field(12; "County Name"; Text[30]) { Caption = 'County Name'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
