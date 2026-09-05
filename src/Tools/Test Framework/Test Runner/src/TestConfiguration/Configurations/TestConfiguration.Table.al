// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// A named test configuration. A configuration is a container for a set of providers (its lines).
/// An empty set of lines means nothing is applied. Stability mode runs every enabled configuration
/// against a base suite so flaky, order dependent and data dependent tests surface.
/// </summary>
table 130467 "Test Configuration"
{
    DataClassification = CustomerContent;
    ReplicateData = false;
    Caption = 'Test Configuration';
    LookupPageId = "Test Configurations";
    DrillDownPageId = "Test Configurations";

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
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        TestConfigurationLine: Record "Test Configuration Line";
    begin
        TestConfigurationLine.SetRange("Configuration Code", "Code");
        TestConfigurationLine.DeleteAll(true);
    end;
}
