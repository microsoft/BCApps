// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46934 "BC14 Ship-to Address"
{
    Caption = 'Ship-to Address Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Customer No."; Code[20]) { Caption = 'Customer No.'; }
        field(2; "Code"; Code[10]) { Caption = 'Code'; }
        field(3; "Name"; Text[100]) { Caption = 'Name'; }
        field(4; "Name 2"; Text[50]) { Caption = 'Name 2'; }
        field(5; "Address"; Text[100]) { Caption = 'Address'; }
        field(6; "Address 2"; Text[50]) { Caption = 'Address 2'; }
        field(7; "City"; Text[30]) { Caption = 'City'; }
        field(8; "Contact"; Text[100]) { Caption = 'Contact'; DataClassification = EndUserIdentifiableInformation; }
        field(9; "Phone No."; Text[30]) { Caption = 'Phone No.'; DataClassification = EndUserIdentifiableInformation; }
        field(11; "Telex No."; Text[20]) { Caption = 'Telex No.'; }
        field(13; "Location Code"; Code[10]) { Caption = 'Location Code'; }
        field(15; "Shipment Method Code"; Code[10]) { Caption = 'Shipment Method Code'; }
        field(35; "Country/Region Code"; Code[10]) { Caption = 'Country/Region Code'; }
        field(84; "Fax No."; Text[30]) { Caption = 'Fax No.'; DataClassification = EndUserIdentifiableInformation; }
        field(91; "Post Code"; Code[20]) { Caption = 'Post Code'; }
        field(92; "County"; Text[30]) { Caption = 'County'; }
        field(102; "E-Mail"; Text[80]) { Caption = 'Email'; DataClassification = EndUserIdentifiableInformation; }
        field(103; "Home Page"; Text[80]) { Caption = 'Home Page'; }
        field(108; "Tax Area Code"; Code[20]) { Caption = 'Tax Area Code'; }
        field(109; "Tax Liable"; Boolean) { Caption = 'Tax Liable'; }
    }

    keys
    {
        key(Key1; "Customer No.", "Code") { Clustered = true; }
    }
}
