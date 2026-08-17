// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46927 "BC14 Reminder Text"
{
    Caption = 'Reminder Text Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10]) { Caption = 'Reminder Terms Code'; }
        field(2; "Reminder Level"; Integer) { Caption = 'Reminder Level'; }
        field(3; "Position"; Option) { Caption = 'Position'; OptionMembers = Beginning,Ending; }
        field(4; "Line No."; Integer) { Caption = 'Line No.'; }
        field(5; "Text"; Text[100]) { Caption = 'Text'; }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "Reminder Level", "Position", "Line No.") { Clustered = true; }
    }
}
