// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

table 46924 "BC14 Finance Charge Terms"
{
    Caption = 'Finance Charge Terms Migration Data';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[10]) { Caption = 'Code'; }
        field(2; "Interest Rate"; Decimal) { Caption = 'Interest Rate'; DecimalPlaces = 0 : 5; AutoFormatType = 0; }
        field(3; "Minimum Amount (LCY)"; Decimal) { Caption = 'Minimum Amount (LCY)'; AutoFormatType = 1; AutoFormatExpression = ''; }
        field(4; "Additional Fee (LCY)"; Decimal) { Caption = 'Additional Fee (LCY)'; AutoFormatType = 1; AutoFormatExpression = ''; }
        field(5; "Interest Calculation Method"; Option) { Caption = 'Interest Calculation Method'; OptionMembers = "Average Daily Balance","Balance Due"; }
        field(6; "Grace Period"; DateFormula) { Caption = 'Grace Period'; }
        field(7; "Due Date Calculation"; DateFormula) { Caption = 'Due Date Calculation'; }
        field(8; "Interest Period (Days)"; Integer) { Caption = 'Interest Period (Days)'; }
        field(11; "Description"; Text[100]) { Caption = 'Description'; }
        field(12; "Post Interest"; Boolean) { Caption = 'Post Interest'; }
        field(13; "Post Additional Fee"; Boolean) { Caption = 'Post Additional Fee'; }
        field(14; "Line Description"; Text[100]) { Caption = 'Line Description'; }
        field(15; "Detailed Lines Description"; Text[100]) { Caption = 'Detailed Lines Description'; }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}
