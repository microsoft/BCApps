// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;
using System.TestTools.TestRunner;

table 149034 "BCCT Log Entry"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "BCCT Log Entries";
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
        field(2; "BCCT Code"; Code[100])
        {
            Caption = 'BCCT Code';
            NotBlank = true;
            TableRelation = "BCCT Header";
        }
        field(3; "BCCT Line No."; Integer)
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
        field(6; "Message"; text[250])
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
        field(16; "Error Call Stack"; Text[2048]) //TODO: Consider changing this to blob
        {
            DataClassification = CustomerContent;
            Caption = 'Error Call Stack';
        }
        field(17; "Procedure Name"; Text[128])
        {
            Caption = 'Procedure Name';
            DataClassification = CustomerContent;
        }
        field(18; RunID; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'RunID';
        }
        field(20; "Orig. Operation"; Text[100])
        {
            Caption = 'Orig. Operation';
        }
        /// <summary>
        /// Contains the original status of the test if any event subscribers modifies the status of the test
        /// </summary>
        field(21; "Orig. Status"; Option)
        {
            Caption = 'Orig. Status';
            OptionMembers = Success,Error;
        }
        /// <summary>
        /// Contains the original message of the test if any event subscribers modifies the message of the test
        /// </summary>
        field(22; "Orig. Message"; Text[250])
        {
            Caption = 'Orig. Message';
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
        field(26; "Test Input Desc."; Text[2048])
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
        key(Key2; "BCCT Code", Version, "BCCT Line No.", Operation, "Duration (ms)", "Test Input Code")
        {
            // Instead of a SIFT index. This will make both inserts and calculations faster - and non-blocking
            IncludedFields = "Procedure Name", Status;
        }
        key(Key4; "BCCT Code", Version, Operation, "Duration (ms)")
        {
            // Instead of a SIFT index. This will make both inserts and calculations faster - and non-blocking
        }
        key(Key3; "Duration (ms)")
        {
            SumIndexFields = "Duration (ms)";
        }
    }


    procedure SetInputBlob(P: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Input Data");
        "Input Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(P);
    end;

    procedure GetInputBlob(): Text
    var
        InStream: InStream;
        P: Text;
    begin
        this.CalcFields("Input Data");
        "Input Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(P);
        exit(P);
    end;

    procedure SetOutputBlob(P: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Output Data");
        "Output Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(P);
    end;

    procedure GetOutputBlob(): Text
    var
        InStream: InStream;
        P: Text;
    begin
        this.CalcFields("Output Data");
        "Output Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(P);
        exit(P);
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
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        Rec.SetRange(Operation, AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
        Rec.SetFilter("Procedure Name", '<> %1', '');
        Rec.SetRange(Status, Rec.Status::Error);
    end;
}