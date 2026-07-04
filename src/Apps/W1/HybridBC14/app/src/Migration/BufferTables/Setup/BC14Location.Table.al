// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46918 "BC14 Location"
{
    Caption = 'Location Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Name"; Text[100]) { Caption = 'Name'; }
        field(3; "Address"; Text[100]) { Caption = 'Address'; }
        field(4; "Address 2"; Text[50]) { Caption = 'Address 2'; }
        field(5; "City"; Text[30]) { Caption = 'City'; }
        field(7; "Phone No."; Text[30]) { Caption = 'Phone No.'; }
        field(11; "Contact"; Text[100]) { Caption = 'Contact'; }
        field(35; "Country/Region Code"; Code[10]) { Caption = 'Country/Region Code'; }
        field(54; "Post Code"; Code[20]) { Caption = 'Post Code'; }
        field(55; "County"; Text[30]) { Caption = 'County'; }
        field(80; "Use As In-Transit"; Boolean) { Caption = 'Use As In-Transit'; }
        field(91; "Require Receive"; Boolean) { Caption = 'Require Receive'; }
        field(92; "Require Shipment"; Boolean) { Caption = 'Require Shipment'; }
        field(93; "Require Put-away"; Boolean) { Caption = 'Require Put-away'; }
        field(94; "Require Pick"; Boolean) { Caption = 'Require Pick'; }
        field(190; "Bin Mandatory"; Boolean) { Caption = 'Bin Mandatory'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
