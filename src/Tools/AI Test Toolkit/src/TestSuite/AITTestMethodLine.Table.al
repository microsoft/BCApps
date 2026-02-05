// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;

table 149032 "AIT Test Method Line"
{
    Caption = 'AI Eval Method Line';
    DataClassification = SystemMetadata;
    Extensible = true;
    Access = Public;
    ReplicateData = false;

    fields
    {
        field(1; "Test Suite Code"; Code[100])
        {
            Caption = 'Eval Suite Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "AIT Test Suite";
            ToolTip = 'Specifies the Eval Suite Code for the eval line.';
        }
        field(2; "Line No."; Integer)
        {
            Editable = false;
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number for the eval line.';
        }
        field(3; "Codeunit ID"; Integer)
        {
            Caption = 'Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
            ToolTip = 'Specifies the codeunit id to run for the eval line.';
            trigger OnLookup()
            var
                AllObjWithCaption: Record AllObjWithCaption;
                SelectTests: Page "Select Tests";
            begin
                SelectTests.LookupMode := true;
                if SelectTests.RunModal() = Action::LookupOK then begin
                    SelectTests.GetRecord(AllObjWithCaption);
                    Validate("Codeunit ID", AllObjWithCaption."Object ID");
                end;
            end;

            trigger OnValidate()
            var
                CodeunitMetadata: Record "CodeUnit Metadata";
            begin
                CodeunitMetadata.Get("Codeunit ID");
                CalcFields("Codeunit Name");

                if ("Codeunit ID" = Codeunit::"AIT Test Run Iteration") or not (CodeunitMetadata.TableNo in [0, Database::"AIT Test Method Line"]) then
                    if not (CodeunitMetadata.SubType = CodeunitMetadata.SubType::Test) then
                        Error(NotSupportedCodeunitErr, "Codeunit Name");
            end;
        }
        field(4; "Codeunit Name"; Text[249])
        {
            Caption = 'Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit), "Object ID" = field("Codeunit ID")));
            ToolTip = 'Specifies the name of the codeunit for the eval line.';
        }

        field(6; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the description for the eval line.';
        }
        field(7; "Input Dataset"; Code[100])
        {
            Caption = 'Input Dataset';
            DataClassification = CustomerContent;
            TableRelation = "Test Input Group" where("Parent Group Code" = const(''));
            ValidateTableRelation = false;
            ToolTip = 'Specifies a dataset that overrides the default dataset for the suite.';

            trigger OnValidate()
            var
                AITTestSuiteLanguage: Codeunit "AIT Test Suite Language";
            begin
                if (Rec."Input Dataset" = '') or (Rec."Test Suite Code" = '') then
                    exit;

                AITTestSuiteLanguage.UpdateLanguagesFromDataset(Rec."Test Suite Code", Rec."Input Dataset");
            end;
        }
        field(9; "Status"; Enum "AIT Line Status")
        {
            Caption = 'Status';
            Editable = false;
            ToolTip = 'Specifies the status for the eval line.';
        }
        field(14; "Version Filter"; Integer)
        {
            Caption = 'Version Filter';
            FieldClass = FlowFilter;
        }
        field(15; "No. of Tests Executed"; Integer)
        {
            Caption = 'No. of Evals Executed';
            ToolTip = 'Specifies the number of evals executed for the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
#pragma warning disable AA0232
        field(16; "Total Duration (ms)"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'Total Duration (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
            ToolTip = 'Specifies the time taken to execute the eval line.';
        }
        field(25; "Base Version Filter"; Integer)
        {
            Caption = 'Base Version Filter';
            FieldClass = FlowFilter;
        }
        field(26; "No. of Tests Executed - Base"; Integer)
        {
            Caption = 'No. of Evals Executed - Base';
            ToolTip = 'Specifies the number of evals executed for the base version of the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(27; "Total Duration - Base (ms)"; Integer)
        {
            Caption = 'Total Duration - Base (ms)';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
            ToolTip = 'Specifies the time taken to execute the base version of the eval line.';
        }
        field(22; "No. of Tests Passed"; Integer)
        {
            Caption = 'No. of Evals Passed';
            ToolTip = 'Specifies the number of evals passed for the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(23; "No. of Operations"; Integer)
        {
            Caption = 'No. of Operations';
            ToolTip = 'Specifies the number of operations executed including "Run Procedure" operation for the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter")));
        }
        field(30; "No. of Tests Passed - Base"; Integer)
        {
            Caption = 'No. of Evals Passed - Base';
            ToolTip = 'Specifies the number of evals passed for the base version of the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(31; "No. of Operations - Base"; Integer)
        {
            Caption = 'No. of Operations - Base';
            ToolTip = 'Specifies the number of operations executed including "Run Procedure" operation for the base version of the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Base Version Filter")));
        }
        field(40; "No. of Turns"; Integer)
        {
            Caption = 'No. of Turns Executed';
            ToolTip = 'Specifies the total number of turns for the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."No. of Turns" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(41; "No. of Turns Passed"; Integer)
        {
            Caption = 'No. of Turns Passed';
            ToolTip = 'Specifies the total number of passed turns for the eval line.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."No. of Turns Passed" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(45; "Test Method Line Accuracy"; Decimal)
        {
            Caption = 'Accuracy';
            ToolTip = 'Specifies the average accuracy of the eval line. The accuracy is calculated as the percentage of turns that passed or can be set manually by the eval.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = average("AIT Log Entry"."Test Method Line Accuracy" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
            AutoFormatType = 0;
        }
        field(101; "AL Test Suite"; Code[10])
        {
            Caption = 'AL Test Suite';
            Editable = false;
        }
        field(120; "Tokens Consumed"; Integer)
        {
            Caption = 'Total Tokens Consumed';
            ToolTip = 'Specifies the number of tokens consumed by the eval in the current version. This is applicable only when using Microsoft AI Module.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Tokens Consumed" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(121; "Tokens Consumed - Base"; Integer)
        {
            Caption = 'Tokens Consumed - Base';
            ToolTip = 'Specifies the number of tokens consumed by the eval in the base version. This is applicable only when using Microsoft AI Module.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Tokens Consumed" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Base Version Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
    }

    keys
    {
        key(Key1; "Test Suite Code", "Line No.")
        {
            Clustered = true;
        }

        key(Key3; "Test Suite Code", "Codeunit ID")
        {
            IncludedFields = "Input Dataset";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Line No.", "Codeunit ID", "Codeunit Name", "Input Dataset", Description)
        {
        }
    }

    internal procedure GetTestInputCode(): Code[100]
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteLanguage: Codeunit "AIT Test Suite Language";
        InputDatasetCode: Code[100];
    begin
        AITTestSuite.Get(Rec."Test Suite Code");

        if Rec."Input Dataset" <> '' then
            InputDatasetCode := Rec."Input Dataset"
        else
            InputDatasetCode := AITTestSuite."Input Dataset";

        exit(AITTestSuiteLanguage.GetLanguageDataset(InputDatasetCode, AITTestSuite."Run Language ID"));
    end;

    trigger OnInsert()
    var
        AITTestSuite: Record "AIT Test Suite";
    begin
        if Rec."Input Dataset" = '' then
            if AITTestSuite.Get(Rec."Test Suite Code") then
                Rec.Validate("Input Dataset", AITTestSuite."Input Dataset");
    end;

    trigger OnDelete()
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if Rec."AL Test Suite" <> '' then
            if ALTestSuite.Get(Rec."AL Test Suite") then
                ALTestSuite.Delete(true);
    end;

    var
        NotSupportedCodeunitErr: Label 'Codeunit %1 can not be used for evaluation.', Comment = '%1 = codeunit name';

}