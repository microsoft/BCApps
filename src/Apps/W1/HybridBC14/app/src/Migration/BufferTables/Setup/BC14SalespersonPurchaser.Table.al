// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46912 "BC14 Salesperson/Purchaser"
{
    Caption = 'Salesperson/Purchaser Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20]) { Caption = 'Code'; }
        field(2; "Name"; Text[50]) { Caption = 'Name'; }
        field(3; "Commission %"; Decimal) { Caption = 'Commission %'; DecimalPlaces = 0 : 5; }
        field(5; "Phone No."; Text[30]) { Caption = 'Phone No.'; DataClassification = EndUserIdentifiableInformation; }
        field(7; "E-Mail"; Text[80]) { Caption = 'Email'; DataClassification = EndUserIdentifiableInformation; }
        field(9; "Job Title"; Text[100]) { Caption = 'Job Title'; }
        field(10; "Privacy Blocked"; Boolean) { Caption = 'Privacy Blocked'; }
        field(11; "Global Dimension 1 Code"; Code[20]) { Caption = 'Global Dimension 1 Code'; }
        field(12; "Global Dimension 2 Code"; Code[20]) { Caption = 'Global Dimension 2 Code'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
