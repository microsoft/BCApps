// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

table 149036 "AIT Run History"
{
    Caption = 'AI Eval Run History';
    DataClassification = SystemMetadata;
    Extensible = false;
    Access = Internal;
    ReplicateData = false;

    fields
    {
        field(1; "Test Suite Code"; Code[100])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the Code for the eval suite.';
        }
        field(2; Version; Integer)
        {
            Caption = 'Version';
            NotBlank = true;
            ToolTip = 'Specifies the version for the eval suite.';
        }
        field(3; Tag; Text[20])
        {
            Caption = 'Tag';
            NotBlank = true;
            ToolTip = 'Specifies the tag for the eval suite.';
        }
        field(5; "Line No. Filter"; Integer)
        {
            Caption = 'Line No. Filter';
            ToolTip = 'Specifies the line to filter results to.';
            FieldClass = FlowFilter;
        }
        field(10; "No. of Tests Executed"; Integer)
        {
            Caption = 'No. of Evals Executed';
            ToolTip = 'Specifies the number of evals executed for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Version" = field("Version"), "Test Method Line No." = field("Line No. Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(11; "No. of Tests Passed"; Integer)
        {
            Caption = 'No. of Evals Passed';
            ToolTip = 'Specifies the number of evals passed for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), "Version" = field("Version"), "Test Method Line No." = field("Line No. Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
#pragma warning disable AA0232
        field(12; "Total Duration (ms)"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'Total Duration (ms)';
            ToolTip = 'Specifies the time taken for executing the evals in the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Test Suite Code"), "Version" = field("Version"), "Test Method Line No." = field("Line No. Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(13; "Tokens Consumed"; Integer)
        {
            Caption = 'Total Tokens Consumed';
            ToolTip = 'Specifies the aggregated number of tokens consumed by the eval in the current version. This is applicable only when using Microsoft AI Module.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Tokens Consumed" where("Test Suite Code" = field("Test Suite Code"), Version = field("Version"), "Test Method Line No." = field("Line No. Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(14; "Accuracy Per Version"; Decimal)
        {
            Caption = 'Accuracy';
            ToolTip = 'Specifies the average accuracy of the version.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = average("AIT Log Entry"."Test Method Line Accuracy" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No. Filter"), Version = field("Version"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
            AutoFormatType = 0;
        }
        field(20; "No. of Tests Executed - By Tag"; Integer)
        {
            Caption = 'No. of Evals Executed';
            ToolTip = 'Specifies the number of evals executed for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), Tag = field(Tag), "Test Method Line No." = field("Line No. Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(21; "No. of Tests Passed - By Tag"; Integer)
        {
            Caption = 'No. of Evals Passed';
            ToolTip = 'Specifies the number of evals passed for the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("AIT Log Entry" where("Test Suite Code" = field("Test Suite Code"), Tag = field(Tag), "Test Method Line No." = field("Line No. Filter"), Operation = const('Run Procedure'), "Procedure Name" = filter(<> ''), Status = const(0)));
        }
        field(22; "Total Duration (ms) - By Tag"; Integer)
        {
            Caption = 'Total Duration (ms)';
            ToolTip = 'Specifies the time taken for executing the evals in the eval suite.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Duration (ms)" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No. Filter"), Tag = field(Tag), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(23; "Tokens Consumed - By Tag"; Integer)
        {
            Caption = 'Total Tokens Consumed';
            ToolTip = 'Specifies the aggregated number of tokens consumed by the eval in the current version. This is applicable only when using Microsoft AI Module.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("AIT Log Entry"."Tokens Consumed" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No. Filter"), Tag = field(Tag), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
        }
        field(24; "Accuracy - By Tag"; Decimal)
        {
            Caption = 'Accuracy';
            ToolTip = 'Specifies the average accuracy of the tag.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = average("AIT Log Entry"."Test Method Line Accuracy" where("Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No. Filter"), Tag = field(Tag), Operation = const('Run Procedure'), "Procedure Name" = filter(<> '')));
            AutoFormatType = 0;
        }
    }

    keys
    {
        key(Key1; "Test Suite Code", Version, Tag)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Version, Tag)
        {
        }
    }
}