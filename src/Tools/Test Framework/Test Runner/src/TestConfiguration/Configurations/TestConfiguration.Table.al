// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Settings for a stability suite generated from a parent test suite.
/// </summary>
table 130467 "Test Configuration"
{
    DataClassification = CustomerContent;
    ReplicateData = false;
    Caption = 'Test Configuration';
    LookupPageId = "Test Configurations";
    DrillDownPageId = "Test Configurations";
    Access = Public;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Description"; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(4; "Test Suite"; Code[10])
        {
            Caption = 'Test Suite';
            NotBlank = true;
            TableRelation = "AL Test Suite".Name where("Created From Suite" = const(''));
        }
        field(5; "Use Random Seed"; Boolean)
        {
            Caption = 'Use Random Seed';
        }
        field(6; "Random Seed"; Integer)
        {
            Caption = 'Random Seed';
        }
        field(7; "WorkDate Offset"; DateFormula)
        {
            Caption = 'WorkDate Offset';
        }
        field(8; "One By One"; Boolean)
        {
            Caption = 'One By One';
        }
        field(9; "Reverse Order"; Boolean)
        {
            Caption = 'Reverse Order';
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Code")
        {
            Clustered = true;
        }
        key(EnabledConfigurations; "Test Suite", Enabled, Code)
        {
        }
    }

}
