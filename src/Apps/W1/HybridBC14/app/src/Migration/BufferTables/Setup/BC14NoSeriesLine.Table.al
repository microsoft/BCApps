// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46929 "BC14 No. Series Line"
{
    Caption = 'No. Series Line Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Series Code"; Code[20]) { Caption = 'Series Code'; }
        field(2; "Line No."; Integer) { Caption = 'Line No.'; }
        field(3; "Starting Date"; Date) { Caption = 'Starting Date'; }
        field(4; "Starting No."; Code[20]) { Caption = 'Starting No.'; }
        field(5; "Ending No."; Code[20]) { Caption = 'Ending No.'; }
        field(6; "Warning No."; Code[20]) { Caption = 'Warning No.'; }
        field(7; "Increment-by No."; Integer) { Caption = 'Increment-by No.'; }
        field(8; "Last No. Used"; Code[20]) { Caption = 'Last No. Used'; }
        field(9; "Open"; Boolean) { Caption = 'Open'; }
        field(10; "Last Date Used"; Date) { Caption = 'Last Date Used'; }
    }

    keys
    {
        key(Key1; "Series Code", "Line No.") { Clustered = true; }
    }
}
