// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46911 "BC14 VAT Posting Setup"
{
    Caption = 'VAT Posting Setup Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "VAT Bus. Posting Group"; Code[20]) { Caption = 'VAT Bus. Posting Group'; }
        field(2; "VAT Prod. Posting Group"; Code[20]) { Caption = 'VAT Prod. Posting Group'; }
        field(3; "VAT %"; Decimal) { Caption = 'VAT %'; DecimalPlaces = 0 : 5; }
        field(4; "VAT Calculation Type"; Option) { Caption = 'VAT Calculation Type'; OptionMembers = "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax"; }
        field(5; "Unrealized VAT Type"; Option) { Caption = 'Unrealized VAT Type'; OptionMembers = " ",Percentage,First,Last,"First (Fully Paid)","Last (Fully Paid)","Cash Basis"; }
        field(6; "Adjust for Payment Discount"; Boolean) { Caption = 'Adjust for Payment Discount'; }
        field(7; "Sales VAT Account"; Code[20]) { Caption = 'Sales VAT Account'; }
        field(8; "Sales VAT Unreal. Account"; Code[20]) { Caption = 'Sales VAT Unreal. Account'; }
        field(9; "Purchase VAT Account"; Code[20]) { Caption = 'Purchase VAT Account'; }
        field(10; "Purch. VAT Unreal. Account"; Code[20]) { Caption = 'Purch. VAT Unreal. Account'; }
        field(11; "Reverse Chrg. VAT Acc."; Code[20]) { Caption = 'Reverse Chrg. VAT Acc.'; }
        field(12; "Reverse Chrg. VAT Unreal. Acc."; Code[20]) { Caption = 'Reverse Chrg. VAT Unreal. Acc.'; }
        field(13; "VAT Identifier"; Code[20]) { Caption = 'VAT Identifier'; }
        field(14; "EU Service"; Boolean) { Caption = 'EU Service'; }
        field(15; "VAT Clause Code"; Code[20]) { Caption = 'VAT Clause Code'; }
        field(16; "Description"; Text[250]) { Caption = 'Description'; }
        field(17; "Description 2"; Text[250]) { Caption = 'Description 2'; }
        field(18; "Tax Category"; Code[10]) { Caption = 'Tax Category'; }
        field(19; "Certificate of Supply Required"; Boolean) { Caption = 'Certificate of Supply Required'; }
        field(20; "Tax Group Code"; Code[20]) { Caption = 'Tax Group Code'; }
    }

    keys
    {
        key(Key1; "VAT Bus. Posting Group", "VAT Prod. Posting Group") { Clustered = true; }
    }
}
