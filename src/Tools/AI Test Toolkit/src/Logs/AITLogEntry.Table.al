// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;

table 149034 "AIT Log Entry"
{
    Caption = 'AI Log Entry';
    DataClassification = SystemMetadata;
    DrillDownPageId = "AIT Log Entries";
    LookupPageId = "AIT Log Entries";
    DataCaptionFields = "Codeunit Name", "Procedure Name", "Test Input Code";
    Extensible = false;
    Access = Internal;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the Log Entry No..';
        }
        field(2; "Test Suite Code"; Code[100])
        {
            Caption = 'Test Suite Code';
            NotBlank = true;
            TableRelation = "AIT Test Suite";
            ToolTip = 'Specifies the Test Suite Code.';
        }
        field(3; "Test Method Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the Test Method Line No.';
        }
        field(4; "Start Time"; DateTime)
        {
            Caption = 'Start Time';
        }
        field(5; "End Time"; DateTime)
        {
            Caption = 'End Time';
        }
        field(6; "Message Text"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Message';
        }
        field(7; "Codeunit ID"; Integer)
        {
            Caption = 'Codeunit ID';
            ToolTip = 'Specifies the test codeunit id.';
        }
        field(8; "Codeunit Name"; Text[250])
        {
            Caption = 'Codeunit Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit), "Object ID" = field("Codeunit ID")));
            Editable = false;
            ToolTip = 'Specifies the test codeunit name.';
        }
        field(9; "Duration (ms)"; Integer)
        {
            Caption = 'DurationInMs (ms)';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Success,Error;
            ToolTip = 'Specifies the status of the iteration.';
        }
        field(11; Operation; Text[100])
        {
            Caption = 'Operation';
            ToolTip = 'Specifies the operation.';
        }
        field(13; Version; Integer)
        {
            Caption = 'Version';
            ToolTip = 'Specifies the Version No. of the test run.';
        }
        field(15; Tag; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Tag';
            ToolTip = 'Specifies the Tag that we entered in the AI Test Suite.';
        }
        field(16; "Error Call Stack"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Error Call Stack';
        }
        field(17; "Procedure Name"; Text[128])
        {
            Caption = 'Procedure Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the procedure being executed.';
        }
        field(18; "Run ID"; Guid)
        {
            Caption = 'Run ID';
            ToolTip = 'Specifies the Run ID.';
        }
        field(20; "Original Operation"; Text[100])
        {
            Caption = 'Original Operation';
            ToolTip = 'Specifies the original operation.';
        }
        field(21; "Original Status"; Option)
        {
            Caption = 'Original Status';
            OptionMembers = Success,Error;
            ToolTip = 'Specifies the original status of the test if any event subscribers modifies the status of the test';
        }
        field(22; "Original Message"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Original Message';
            ToolTip = 'Specifies the original message of the test if any event subscribers modifies the message of the test';
        }
        field(23; "Log was Modified"; Boolean)
        {
            Caption = 'Log was Modified';
            ToolTip = 'Specifies if any event subscribers has modified the log entry';
        }
        field(24; "Test Input Group Code"; Code[100])
        {
            Caption = 'Test Input Group Code';
            TableRelation = "Test Input Group".Code;
            ToolTip = 'Specifies the dataset that is used by the test.';
        }
        field(25; "Test Input Code"; Code[100])
        {
            Caption = 'Test Input Code';
            TableRelation = "Test Input".Code where("Test Input Group Code" = field("Test Input Group Code"));
            ToolTip = 'Specifies the Line No. of the dataset.';
        }
        field(26; "Test Input Description"; Text[2048])
        {
            Caption = 'Test Input Description';
            TableRelation = "Test Input Group"."Description" where("Code" = field("Test Input Group Code"));
            ToolTip = 'Specifies the description of the input dataset.';
        }
        field(27; Sensitive; Boolean)
        {
            Caption = 'Sensitive';
        }
        field(28; "Input Data"; Blob)
        {
            Caption = 'Input Data';
        }
        field(29; "Output Data"; Blob)
        {
            Caption = 'Output Data';
        }
        field(40; "No. of Turns"; Integer)
        {
            Caption = 'Total number of turns';
            ToolTip = 'Specifies the total number of turns.';
        }
        field(41; "No. of Turns Passed"; Integer)
        {
            Caption = 'Number of turns passed';
            ToolTip = 'Specifies the number of turns passed.';
        }
        field(45; "Test Method Line Accuracy"; Decimal)
        {
            Caption = 'Test Method Line Accuracy';
            ToolTip = 'Specifies the accuracy of the test line. The accuracy is calculated as the percentage of turns that passed or can be set manually in the test.';
        }
        field(50; "Tokens Consumed"; Integer)
        {
            Caption = 'Total Tokens Consumed';
            ToolTip = 'Specifies the aggregated number of tokens consumed by the test. This is applicable only when using Microsoft AI Module.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Suite Code", Version, "Test Method Line No.", Operation, "Procedure Name")
        {
            IncludedFields = Status;
            SumIndexFields = "Duration (ms)";
        }
        key(Key3; Tag)
        {
        }
        key(Key4; Version)
        {
        }
    }

    trigger OnInsert()
    begin
        if "End Time" = 0DT then
            "End Time" := CurrentDateTime();
        if "Start Time" = 0DT then
            "Start Time" := "End Time" - "Duration (ms)";
        if "Duration (ms)" = 0 then
            "Duration (ms)" := "End Time" - "Start Time";
    end;

    procedure SetInputBlob(NewInput: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Input Data");
        "Input Data".CreateOutStream(OutStream, GetDefaultTextEncoding());
        OutStream.Write(NewInput);
    end;

    procedure GetInputBlob(): Text
    var
        InStream: InStream;
        InputContent: Text;
    begin
        CalcFields("Input Data");
        "Input Data".CreateInStream(InStream, GetDefaultTextEncoding());
        InStream.Read(InputContent);
        exit(InputContent);
    end;

    procedure SetOutputBlob(NewOutput: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Output Data");
        "Output Data".CreateOutStream(OutStream, GetDefaultTextEncoding());
        OutStream.Write(NewOutput);
    end;

    procedure GetOutputBlob(): Text
    var
        InStream: InStream;
        OutputContent: Text;
    begin
        CalcFields("Output Data");
        "Output Data".CreateInStream(InStream, GetDefaultTextEncoding());
        InStream.Read(OutputContent);
        exit(OutputContent);
    end;

    procedure SetMessage(NewMessageText: Text)
    var
        MessageOutStream: OutStream;
    begin
        Clear("Message Text");
        "Message Text".CreateOutStream(MessageOutStream, GetDefaultTextEncoding());
        MessageOutStream.WriteText(NewMessageText);
    end;

    procedure GetMessage(): Text
    var
        MessageInStream: InStream;
        MessageText: Text;
    begin
        CalcFields("Message Text");
        "Message Text".CreateInStream(MessageInStream, GetDefaultTextEncoding());
        MessageInStream.ReadText(MessageText);
        exit(MessageText);
    end;

    procedure SetErrorCallStack(ErrorCallStack: Text)
    var
        ErrorCallStackOutStream: OutStream;
    begin
        Clear("Error Call Stack");
        "Error Call Stack".CreateOutStream(ErrorCallStackOutStream, GetDefaultTextEncoding());
        ErrorCallStackOutStream.WriteText(ErrorCallStack);
    end;

    procedure GetErrorCallStack(): Text
    var
        ErrorCallStackInStream: InStream;
        ErrorCallStackText: Text;
    begin
        CalcFields("Error Call Stack");
        "Error Call Stack".CreateInStream(ErrorCallStackInStream, GetDefaultTextEncoding());
        ErrorCallStackInStream.ReadText(ErrorCallStackText);
        exit(ErrorCallStackText);
    end;

    local procedure GetDefaultTextEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    internal procedure SetFilterForFailedTestProcedures()
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        Rec.SetRange(Operation, AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
        Rec.SetFilter("Procedure Name", '<>%1', '');
        Rec.SetRange(Status, Rec.Status::Error);
    end;

    internal procedure GetSuiteDescription(): Text[250]
    var
        AITTestSuite: Record "AIT Test Suite";
    begin
        AITTestSuite.SetLoadFields("Description");
        if AITTestSuite.Get(Rec."Test Suite Code") then
            exit(AITTestSuite."Description");
        exit('');
    end;

    internal procedure GetTestMethodLineDescription(): Text[250]
    var
        AITTestMethodLine: Record "AIT Test Method Line";
    begin
        AITTestMethodLine.SetLoadFields("Description");
        if AITTestMethodLine.Get(Rec."Test Suite Code", Rec."Test Method Line No.") then
            exit(AITTestMethodLine."Description");
        exit('');
    end;
}