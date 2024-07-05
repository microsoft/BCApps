// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

table 149030 "AIT Test Suite"
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
        }
        field(2; "Description"; Text[250])
        {
            Caption = 'Description';
        }
        field(4; Status; Enum "AIT Test Suite Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(5; "Started at"; DateTime)
        {
            Caption = 'Started at';
            Editable = false;
        }
        field(7; "Input Dataset"; Code[100])
        {
            Caption = 'Input Dataset';
            TableRelation = "Test Input Group".Code;
            ValidateTableRelation = true;
        }
        field(8; "Ended at"; DateTime)
        {
            Caption = 'Ended at';
            Editable = false;
        }
        field(10; "No. of tests running"; Integer)
        {
            Caption = 'No. of tests running';
            trigger OnValidate()
            var
                AITTestMethodLine: Record "AIT Test Method Line";
                AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
            begin
                if "No. of tests running" < 0 then
                    "No. of tests running" := 0;

                if "No. of tests running" <> 0 then
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
            DataClassification = CustomerContent;
        }
        field(12; "Total Duration (ms)"; Integer)
        {
            Caption = 'Total Duration (ms)';
            ToolTip = 'Specifies the Total Duration (ms) for executing all the tests in the current version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Code"), Version = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(13; Version; Integer)
        {
            Caption = 'Version';
            Editable = false;
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
        field(20; ModelVersion; Option)
        {
            Caption = 'AOAI Model Version';
            OptionMembers = Latest,Preview;
        }
        field(21; "No. of Tests Executed"; Integer)
        {
            Caption = 'No. of Tests Executed';
            ToolTip = 'Specifies the number of tests executed in the current version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(22; "No. of Tests Passed"; Integer)
        {
            Caption = 'No. of Tests Passed';
            ToolTip = 'Specifies the number of tests passed in the current version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(23; "No. of Operations"; Integer)
        {
            Caption = 'No. of Operations';
            ToolTip = 'Specifies the number of operations executed including "Run Procedure" operation for the current version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version")));
        }
        field(31; "No. of Tests Executed - Base"; Integer)
        {
            Caption = 'No. of Tests Executed';
            ToolTip = 'Specifies the number of tests executed in the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Base Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(32; "No. of Tests Passed - Base"; Integer)
        {
            Caption = 'No. of Tests Passed';
            ToolTip = 'Specifies the number of tests passed in the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Base Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(33; "No. of Operations - Base"; Integer)
        {
            Caption = 'No. of Operations';
            ToolTip = 'Specifies the number of operations executed including "Run Procedure" operation for the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Base Version")));
        }
        field(34; "Total Duration (ms) - Base"; Integer)
        {
            Caption = 'Total Duration (ms) - Base';
            ToolTip = 'Specifies the Total Duration (ms) for executing all the tests in the base version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Code"), Version = field("Base Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
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
