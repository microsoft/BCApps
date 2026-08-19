// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46936 "BC14 Resource"
{
    Caption = 'Resource Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "No."; Code[20]) { Caption = 'No.'; }
        field(2; Type; Option) { Caption = 'Type'; OptionMembers = Person,Machine,Tool; }
        field(3; Name; Text[100]) { Caption = 'Name'; }
        field(4; "Search Name"; Code[100]) { Caption = 'Search Name'; }
        field(5; "Name 2"; Text[50]) { Caption = 'Name 2'; }
        field(14; "Resource Group No."; Code[20]) { Caption = 'Resource Group No.'; }
        field(16; "Base Unit of Measure"; Code[10]) { Caption = 'Base Unit of Measure'; }
        field(17; "Direct Unit Cost"; Decimal) { Caption = 'Direct Unit Cost'; MinValue = 0; }
        field(18; "Indirect Cost %"; Decimal) { Caption = 'Indirect Cost %'; MinValue = 0; }
        field(19; "Unit Cost"; Decimal) { Caption = 'Unit Cost'; MinValue = 0; }
        field(20; "Last Date Modified"; Date) { Caption = 'Last Date Modified'; Editable = false; }
        field(22; "Unit Price"; Decimal) { Caption = 'Unit Price'; MinValue = 0; }
        field(38; "Gen. Prod. Posting Group"; Code[20]) { Caption = 'Gen. Prod. Posting Group'; }
        field(50; Blocked; Boolean) { Caption = 'Blocked'; }
        field(51; "Privacy Blocked"; Boolean) { Caption = 'Privacy Blocked'; }
        field(89; "VAT Prod. Posting Group"; Code[20]) { Caption = 'VAT Prod. Posting Group'; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
