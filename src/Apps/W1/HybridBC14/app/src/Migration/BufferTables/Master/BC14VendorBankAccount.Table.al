// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46933 "BC14 Vendor Bank Account"
{
    Caption = 'Vendor Bank Account Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Vendor No."; Code[20]) { Caption = 'Vendor No.'; }
        field(2; "Code"; Code[20]) { Caption = 'Code'; }
        field(3; "Name"; Text[100]) { Caption = 'Name'; }
        field(5; "Address"; Text[100]) { Caption = 'Address'; }
        field(6; "Address 2"; Text[50]) { Caption = 'Address 2'; }
        field(7; "City"; Text[30]) { Caption = 'City'; }
        field(8; "Contact"; Text[100]) { Caption = 'Contact'; DataClassification = EndUserIdentifiableInformation; }
        field(9; "Phone No."; Text[30]) { Caption = 'Phone No.'; DataClassification = EndUserIdentifiableInformation; }
        field(13; "Bank Branch No."; Text[20]) { Caption = 'Bank Branch No.'; }
        field(14; "Bank Account No."; Text[30]) { Caption = 'Bank Account No.'; MaskType = Concealed; }
        field(15; "Transit No."; Text[20]) { Caption = 'Transit No.'; }
        field(20; "Currency Code"; Code[10]) { Caption = 'Currency Code'; }
        field(35; "Country/Region Code"; Code[10]) { Caption = 'Country/Region Code'; }
        field(91; "Post Code"; Code[20]) { Caption = 'Post Code'; }
        field(102; "E-Mail"; Text[80]) { Caption = 'Email'; DataClassification = EndUserIdentifiableInformation; }
        field(103; "Home Page"; Text[80]) { Caption = 'Home Page'; }
        field(11000; "IBAN"; Code[50]) { Caption = 'IBAN'; MaskType = Concealed; }
        field(11001; "SWIFT Code"; Code[20]) { Caption = 'SWIFT Code'; }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code") { Clustered = true; }
    }
}
