// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.AI;
using System.TestTools.TestRunner;

#pragma warning disable AS0002
table 149030 "AIT Test Suite"
#pragma warning restore AS0002
{
    Caption = 'AI Eval Suite';
    DataClassification = SystemMetadata;
    ReplicateData = false;
    Extensible = true;
    Access = Public;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the Code for the eval suite.';
        }
        field(2; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description for the eval suite.';
        }
        field(4; Status; Enum "AIT Test Suite Status")
        {
            Caption = 'Status';
            Editable = false;
            ToolTip = 'Specifies the status of the eval suite.';
        }
        field(5; "Started at"; DateTime)
        {
            Caption = 'Started at';
            Editable = false;
            ToolTip = 'Specifies when the eval suite was started.';
        }
        field(7; "Input Dataset"; Code[100])
        {
            Caption = 'Input Dataset';
            TableRelation = "Test Input Group".Code where("Parent Group Code" = const(''));
            ValidateTableRelation = false;
            ToolTip = 'Specifies the dataset to be used by the eval suite.';
        }
        field(8; "Ended at"; DateTime)
        {
            Caption = 'Ended at';
            Editable = false;
            ToolTip = 'Specifies the end time of the eval suite execution.';
        }
        field(10; "No. of Tests Running"; Integer)
        {
            Caption = 'No. of evals running';
            ToolTip = 'Specifies the number of evals running in the eval suite.';

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
            ToolTip = 'Specifies the tag for an eval run. The Tag will be transferred to the log entries and enables easier comparison between the evals.';
            DataClassification = CustomerContent;
        }
#pragma warning disable AA0232
        field(12; "Total Duration (ms)"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'Total Duration (ms)';
            ToolTip = 'Specifies the time taken for executing the evals in the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(13; Version; Integer)
        {
            Caption = 'Version';
            Editable = false;
            ToolTip = 'Specifies the version of the current eval run. It is used for comparing the results of the current eval run with the results of the previous eval run. The version will be stored in the Log entries.';
        }
        field(14; "Copilot Capability"; Enum "Copilot Capability")
        {
            Caption = 'Capability';
            ToolTip = 'Specifies the capability that the eval suite evaluates.';
        }
        field(15; "Run Frequency"; Enum "AIT Run Frequency")
        {
            Caption = 'Run Frequency';
            ToolTip = 'Specifies how frequently the eval suite should be run.';
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
            Caption = 'No. of Evals Executed';
            ToolTip = 'Specifies the number of evals executed for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(22; "No. of Tests Passed"; Integer)
        {
            Caption = 'No. of Evals Passed';
            ToolTip = 'Specifies the number of evals passed for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(23; "No. of Operations"; Integer)
        {
            Caption = 'No. of Operations';
            ToolTip = 'Specifies the number of operations executed including "Run Procedure" operation for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Code"), "Version" = field("Version")));
        }
        field(24; "Tokens Consumed"; Integer)
        {
            Caption = 'Total Tokens Consumed';
            ToolTip = 'Specifies the aggregated number of tokens consumed by the eval in the current version. This is applicable only when using Microsoft AI Module.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Tokens Consumed" where("Test Suite Code" = field("Code"), Version = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(25; Accuracy; Decimal)
        {
            Caption = 'Accuracy';
            ToolTip = 'Specifies the average accuracy of the eval suite. The accuracy is calculated as the percentage of turns that passed or can be set manually by the eval.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = average("AIT Log Entry"."Test Method Line Accuracy" where("Test Suite Code" = field("Code"), Version = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
            AutoFormatType = 0;
        }
        field(30; "Number of Evaluators"; Integer)
        {
            Caption = 'Evaluators';
            ToolTip = 'Specifies the number of evaluators to use in the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Evaluator" where("Test Suite Code" = field("Code")));
        }
        field(31; "Number of Column Mappings"; Integer)
        {
            Caption = 'Column Mappings';
            ToolTip = 'Specifies the number of evaluators to use in the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Column Mapping" where("Test Suite Code" = field("Code")));
        }
        field(40; "Run Language ID"; Integer)
        {
            Caption = 'Language ID';
            TableRelation = "AIT Test Suite Language"."Language ID";
            ValidateTableRelation = true;
            ToolTip = 'Specifies the language in which the eval suite should be run.';
        }
        field(41; "Run Language Tag"; Text[80])
        {
            Caption = 'Language Tag';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("AIT Test Suite Language"."Language Tag" where("Test Suite Code" = field("Code"), "Language ID" = field("Run Language ID")));
        }
        field(42; "Run Language Name"; Text[80])
        {
            Caption = 'Language Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("AIT Test Suite Language"."Language Name" where("Test Suite Code" = field("Code"), "Language ID" = field("Run Language ID")));
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
            ToolTip = 'Specifies the application id from which the eval suite was created.';
        }
        field(70; "Imported XML's MD5"; Code[32])
        {
            Caption = 'Imported XML''s MD5';
            ToolTip = 'Specifies the MD5 hash of the XML file from which the eval suite was imported.';
        }
        field(80; Validation; Boolean)
        {
            Caption = 'Validation';
            ToolTip = 'Specifies whether this eval suite is used for validation purposes.';
        }
        field(81; "Test Type"; Enum "AIT Test Type")
        {
            Caption = 'Eval Type';
            ToolTip = 'Specifies the type of AI eval (Copilot, Agent, or MCP).';
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

    internal procedure GetTestInputCode(): Code[100]
    var
        AITTestSuiteLanguage: Codeunit "AIT Test Suite Language";
    begin
        exit(AITTestSuiteLanguage.GetLanguageDataset(Rec."Input Dataset", Rec."Run Language ID"));
    end;

    var
        BaseVersionMustBeLessThanVersionErr: Label 'Base Version must be less than or equal to Version';
}
