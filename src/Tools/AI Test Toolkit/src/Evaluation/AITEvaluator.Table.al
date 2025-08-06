// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.AITestToolkit;

table 149039 "AIT Evaluator"
{
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;
    DrillDownPageId = "AIT Evaluators";

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
            Caption = 'Test Method Line';
            ToolTip = 'Specifies the line number of the test method.';
            DataClassification = SystemMetadata;
            TableRelation = "AIT Test Method Line"."Line No.";
            ValidateTableRelation = true;
        }

        field(3; "Evaluator Type"; Enum "AIT Evaluator Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Evaluator Type';
            ToolTip = 'Specifies the type of evaluator.';
        }

        field(10; Evaluator; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Evaluator';
            ToolTip = 'Specifies the evaluator to use in the test suite.';
        }


    }

    keys
    {
        key(PK; "Test Suite Code", "Test Method Line", Evaluator)
        {
            Clustered = true;
        }
    }
}