// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.AITestToolkit;

table 149038 "AIT Column Mapping"
{
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    DrillDownPageId = "AIT Column Mappings";

    fields
    {
        field(1; "Test Suite Code"; Code[10])
        {
            Caption = 'Test Suite Code';
            ToolTip = 'Specifies the code of the test suite.';
            DataClassification = SystemMetadata;
            TableRelation = "AIT Test Suite".Code;
            ValidateTableRelation = true;
        }

        field(2; "Test Method Line"; Integer)
        {
            Caption = 'Test Suite Code';
            ToolTip = 'Specifies the code of the test suite.';
            DataClassification = SystemMetadata;
            TableRelation = "AIT Test Method Line"."Line No.";
            ValidateTableRelation = true;
        }

        field(10; "Column"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Column';
            ToolTip = 'Specifies the column from the test output data to use in evaluation.';
        }

        field(11; "Target Column"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Target Column';
            ToolTip = 'Specifies the target column from the test output data to use in evaluation.';
        }

    }

    keys
    {
        key(PK; "Test Suite Code", "Test Method Line", Column, "Target Column")
        {
            Clustered = true;
        }
    }
}