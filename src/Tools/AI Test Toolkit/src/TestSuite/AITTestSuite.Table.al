// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

#pragma warning disable AS0002
table 149030 "AIT Test Suite"
#pragma warning restore AS0002
{
    Caption = 'AI Test Suite';
    DataClassification = SystemMetadata;
    Extensible = false;
    ReplicateData = false;
    Access = Internal;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the Code for the test suite.';
        }
        field(2; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description for the test suite.';
        }
        field(4; Status; Enum "AIT Test Suite Status")
        {
            Caption = 'Status';
            Editable = false;
            ToolTip = 'Specifies the status of the test suite.';
        }
        field(5; "Started at"; DateTime)
        {
            Caption = 'Started at';
            Editable = false;
            ToolTip = 'Specifies when the test suite was started.';
        }
        field(7; "Input Dataset"; Code[100])
        {
            Caption = 'Input Dataset';
            TableRelation = "Test Input Group".Code;
            ValidateTableRelation = true;
            ToolTip = 'Specifies the dataset to be used by the test suite.';
        }
        field(8; "Ended at"; DateTime)
        {
            Caption = 'Ended at';
            Editable = false;
            ToolTip = 'Specifies the end time of the test suite execution.';
        }
        field(10; "No. of Tests Running"; Integer)
        {
            Caption = 'No. of tests running';
            ToolTip = 'Specifies the number of tests running in the test suite.';

            trigger OnValidate()
            var
                AITTestMethodLine: Record "AIT Test Method Line";
                AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
            begin
                if "No. of Tests Running" < 0 then
                    "No. of Tests Running" := 0;

                if "No. of Tests Running" <> 0 then
                    exit;

                case Status of
                    Status::Running:
                        begin
                            AITTestMethodLine.SetRange("Test Suite Code", "Code");
                            AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
                            if not AITTestMethodLine.IsEmpty then
                                exit;
                            AITTestSuiteMgt.SetRunStatus(Rec, Rec.Status::Completed);
                            AITTestMethodLine.SetRange("Test Suite Code", "Code");
                            AITTestMethodLine.SetRange(Status);
                            AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Completed, true);
                        end;
                    Status::Cancelled:
                        begin
                            AITTestMethodLine.SetRange("Test Suite Code", "Code");
                            AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Cancelled, true);
                        end;
                end;
            end;
        }
        field(11; Tag; Text[20])
        {
            Caption = 'Tag';
            ToolTip = 'Specifies the tag for a test run. The Tag will be transferred to the log entries and enables easier comparison between the tests.';
            DataClassification = CustomerContent;
        }
#pragma warning disable AA0232
        field(12; "Total Duration (ms)"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'Total Duration (ms)';
            ToolTip = 'Specifies the time taken for executing the tests in the test suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(13; Version; Integer)
        {
            Caption = 'Version';
            Editable = false;
            ToolTip = 'Specifies the version of the current test run. It is used for comparing the results of the current test run with the results of the previous test run. The version will be stored in the Log entries.';
        }
        field(16; "Base Version"; Integer)
        {
            Caption = 'Base Version';
            DataClassification = CustomerContent;
            MinValue = 0;
            trigger OnValidate()
            begin
                if "Base Version" > Version then
                    Error(BaseVersionMustBeLessThanVersionErr)
            end;
        }
        field(19; RunID; Guid)
        {
            Caption = 'Unique RunID';
            Editable = false;
        }
        field(21; "No. of Tests Executed"; Integer)
        {
            Caption = 'No. of Tests Executed';
            ToolTip = 'Specifies the number of tests executed for the test suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(22; "No. of Tests Passed"; Integer)
        {
            Caption = 'No. of Tests Passed';
            ToolTip = 'Specifies the number of tests passed for the test suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(23; "No. of Operations"; Integer)
        {
            Caption = 'No. of Operations';
            ToolTip = 'Specifies the number of operations executed including "Run Procedure" operation for the test suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version")));
        }
        field(24; "Tokens Consumed"; Integer)
        {
            Caption = 'Total Tokens Consumed';
            ToolTip = 'Specifies the aggregated number of tokens consumed by the test in the current version. This is applicable only when using Microsoft AI Module.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Tokens Consumed" where("Test Suite Code" = field("Code"), Version = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(25; Accuracy; Decimal)
        {
            Caption = 'Accuracy';
            ToolTip = 'Specifies the average accuracy of the test suite. The accuracy is calculated as the percentage of turns that passed or can be set manually by the test.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = average("AIT Log Entry"."Test Method Line Accuracy" where("Test Suite Code" = field("Code"), Version = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(50; "Test Runner Id"; Integer)
        {
            Caption = 'Test Runner Id';
            Editable = false;

            trigger OnValidate()
            var
                ALTestSuite: Record "AL Test Suite";
            begin
                if ALTestSuite.Get(Rec.Code) then begin
                    ALTestSuite."Test Runner Id" := Rec."Test Runner Id";
                    ALTestSuite.Modify(true);
                end;
            end;
        }
        field(60; "Imported by AppId"; Guid)
        {
            Caption = 'Imported from AppId';
            ToolTip = 'Specifies the application id from which the test suite was created.';
        }
        field(70; "Imported XML's MD5"; Code[32])
        {
            Caption = 'Imported XML''s MD5';
            ToolTip = 'Specifies the MD5 hash of the XML file from which the test suite was imported.';
        }
    }
    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Dataset; "Input Dataset")
        {
        }
    }

    trigger OnInsert()
    begin
        if Rec."Test Runner Id" = 0 then
            AssignDefaultTestRunner();
    end;

    internal procedure AssignDefaultTestRunner()
    var
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
    begin
        Rec."Test Runner Id" := TestRunnerMgt.GetDefaultTestRunner();
    end;

    var
        BaseVersionMustBeLessThanVersionErr: Label 'Base Version must be less than or equal to Version';
}
