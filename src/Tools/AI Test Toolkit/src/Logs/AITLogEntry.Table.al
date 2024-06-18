// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;

table 149034 "AIT Log Entry"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "AIT Log Entries";
    Extensible = false;
    Access = Internal;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Test Suite Code"; Code[100])
        {
            Caption = 'Test Suite Code';
            NotBlank = true;
            TableRelation = "AIT Test Suite";
        }
        field(3; "Test Method Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Start Time"; DateTime)
        {
            Caption = 'Start Time';
        }
        field(5; "End Time"; DateTime)
        {
            Caption = 'End Time';
        }
        field(6; Message; Blob)
        {
            Caption = 'Message';
        }
        field(7; "Codeunit ID"; Integer)
        {
            Caption = 'Codeunit ID';
        }
        field(8; "Codeunit Name"; Text[250])
        {
            Caption = 'Codeunit Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit), "Object ID" = field("Codeunit ID")));
        }
        field(9; "Duration (ms)"; integer)
        {
            Caption = 'DurationInMs (ms)';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Success,Error;
        }
        field(11; Operation; Text[100])
        {
            Caption = 'Operation';
        }
        field(13; Version; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Version';
        }
        field(15; Tag; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Tag';
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
        }
        field(18; "Run ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Run ID';
        }
        field(20; "Original Operation"; Text[100])
        {
            Caption = 'Original Operation';
        }
        /// <summary>
        /// Contains the original status of the test if any event subscribers modifies the status of the test
        /// </summary>
        field(21; "Original Status"; Option)
        {
            Caption = 'Original Status';
            OptionMembers = Success,Error;
        }
        /// <summary>
        /// Contains the original message of the test if any event subscribers modifies the message of the test
        /// </summary>
        field(22; "Original Message"; Text[250])
        {
            Caption = 'Original Message';
        }
        /// <summary>
        /// Is true if any event subscribers has modified the log entry
        /// </summary>
        field(23; "Log was Modified"; Boolean)
        {
            Caption = 'Log was Modified';
        }
        field(24; "Test Input Group Code"; Code[100])
        {
            Caption = 'Test Input Group Code';
            TableRelation = "Test Input Group".Code;
        }
        field(25; "Test Input Code"; Code[100])
        {
            Caption = 'Test Input Code';
            TableRelation = "Test Input".Code where("Test Input Group Code" = field("Test Input Group Code"));
        }
        field(26; "Test Input Description"; Text[2048])
        {
            Caption = 'Test Input Description';
            TableRelation = "Test Input Group"."Description" where("Code" = field("Test Input Group Code"));
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
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Suite Code", Version, "Test Method Line No.", Operation, "Duration (ms)", "Test Input Code")
        {
            // Instead of a SIFT index. This will make both inserts and calculations faster - and non-blocking
            IncludedFields = "Procedure Name", Status;
        }
        key(Key4; "Test Suite Code", Version, Operation, "Duration (ms)")
        {
            // Instead of a SIFT index. This will make both inserts and calculations faster - and non-blocking
        }
        key(Key3; "Duration (ms)")
        {
            SumIndexFields = "Duration (ms)";
        }
    }


    procedure SetInputBlob(NewInput: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Input Data");
        "Input Data".CreateOutStream(OutStream, this.GetDefaultTextEncoding());
        OutStream.Write(NewInput);
    end;

    procedure GetInputBlob(): Text
    var
        InStream: InStream;
        InputContent: Text;
    begin
        this.CalcFields("Input Data");
        "Input Data".CreateInStream(InStream, this.GetDefaultTextEncoding());
        InStream.Read(InputContent);
        exit(InputContent);
    end;

    procedure SetOutputBlob(NewOutput: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Output Data");
        "Output Data".CreateOutStream(OutStream, this.GetDefaultTextEncoding());
        OutStream.Write(NewOutput);
    end;

    procedure GetOutputBlob(): Text
    var
        InStream: InStream;
        OutputContent: Text;
    begin
        this.CalcFields("Output Data");
        "Output Data".CreateInStream(InStream, this.GetDefaultTextEncoding());
        InStream.Read(OutputContent);
        exit(OutputContent);
    end;

    procedure SetMessage(Msg: Text)
    var
        MessageOutStream: OutStream;
    begin
        Clear(Message);
        Message.CreateOutStream(MessageOutStream, this.GetDefaultTextEncoding());
        MessageOutStream.WriteText(Msg);
    end;

    procedure GetMessage(): Text
    var
        MessageInStream: InStream;
        MessageText: Text;
    begin
        this.CalcFields(Message);
        Message.CreateInStream(MessageInStream, this.GetDefaultTextEncoding());
        MessageInStream.ReadText(MessageText);
        exit(MessageText);
    end;

    procedure SetErrorCallStack(ErrorCallStack: Text)
    var
        ErrorCallStackOutStream: OutStream;
    begin
        Clear("Error Call Stack");
        "Error Call Stack".CreateOutStream(ErrorCallStackOutStream, this.GetDefaultTextEncoding());
        ErrorCallStackOutStream.WriteText(ErrorCallStack);
    end;

    procedure GetErrorCallStack(): Text
    var
        ErrorCallStackInStream: InStream;
        ErrorCallStackText: Text;
    begin
        this.CalcFields("Error Call Stack");
        "Error Call Stack".CreateInStream(ErrorCallStackInStream, this.GetDefaultTextEncoding());
        ErrorCallStackInStream.ReadText(ErrorCallStackText);
        exit(ErrorCallStackText);
    end;

    local procedure GetDefaultTextEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    trigger OnInsert()
    begin
        if "End Time" = 0DT then
            "End Time" := CurrentDateTime;
        if "Start Time" = 0DT then
            "Start Time" := "End Time" - "Duration (ms)";
        if "Duration (ms)" = 0 then
            "Duration (ms)" := "End Time" - "Start Time";
    end;

    internal procedure SetFilterForFailedTestProcedures()
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        Rec.SetRange(Operation, AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
        Rec.SetFilter("Procedure Name", '<> %1', '');
        Rec.SetRange(Status, Rec.Status::Error);
    end;
}