// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46925 "BC14 Reminder Terms"
{
    Caption = 'Reminder Terms Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Description"; Text[100]) { Caption = 'Description'; }
        field(3; "Max. No. of Reminders"; Integer) { Caption = 'Max. No. of Reminders'; }
        field(4; "Post Interest"; Boolean) { Caption = 'Post Interest'; }
        field(5; "Post Additional Fee"; Boolean) { Caption = 'Post Additional Fee'; }
        field(6; "Minimum Amount (LCY)"; Decimal) { Caption = 'Minimum Amount (LCY)'; }
        field(7; "Note About Line Fee on Report"; Boolean) { Caption = 'Note About Line Fee on Report'; }
        field(8; "Post Add. Fee per Line"; Boolean) { Caption = 'Post Add. Fee per Line'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
