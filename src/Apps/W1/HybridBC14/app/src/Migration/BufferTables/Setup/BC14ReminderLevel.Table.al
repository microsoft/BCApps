// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46926 "BC14 Reminder Level"
{
    Caption = 'Reminder Level Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Reminder Terms Code"; Code[10]) { Caption = 'Reminder Terms Code'; }
        field(2; "No."; Integer) { Caption = 'No.'; }
        field(3; "Grace Period"; DateFormula) { Caption = 'Grace Period'; }
        field(4; "Due Date Calculation"; DateFormula) { Caption = 'Due Date Calculation'; }
        field(5; "Calculate Interest"; Boolean) { Caption = 'Calculate Interest'; }
        field(6; "Additional Fee (LCY)"; Decimal) { Caption = 'Additional Fee (LCY)'; }
        field(7; "Add. Fee per Line Amount (LCY)"; Decimal) { Caption = 'Add. Fee per Line Amount (LCY)'; }
        field(8; "Min. Amount of Add. Fee (LCY)"; Decimal) { Caption = 'Min. Amount of Add. Fee (LCY)'; }
        field(9; "Max. Amount of Add. Fee (LCY)"; Decimal) { Caption = 'Max. Amount of Add. Fee (LCY)'; }
    }

    keys
    {
        key(Key1; "Reminder Terms Code", "No.") { Clustered = true; }
    }
}
