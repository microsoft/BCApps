// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools;

using System.Utilities;

table 130415 "Semi-Manual Test Wizard"
{
    Caption = 'Semi-Manual Test Wizard';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Codeunit number"; Integer)
        {
            BlankZero = true;
            Caption = 'Codeunit number';
        }
        field(2; "Codeunit name"; Text[250])
        {
            Caption = 'Codeunit name';
        }
        field(3; "Step number"; Integer)
        {
            Caption = 'Step number';
        }
        field(4; "Step heading"; Text[250])
        {
            Caption = 'Step heading';
        }
        field(5; "Manual detailed steps"; BLOB)
        {
            Caption = 'Manual detailed steps';
        }
        field(6; "Total steps"; Integer)
        {
            Caption = 'Total steps';
        }
        field(7; "Skip current step"; Boolean)
        {
            Caption = 'Skip current step';
        }
    }

    keys
    {
        key(Key1; "Codeunit name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        InvalidCodeunitErr: Label 'Codeunit %1 does not seem to be valid for a manual test.', Locked = true;

    [Scope('OnPrem')]
    procedure Initialize(CodeunitId: Integer; CodeunitName: Text[250])
    var
        FailureCondition: Boolean;
    begin
        Init();
        "Codeunit number" := CodeunitId;
        "Codeunit name" := CodeunitName;
        FailureCondition := not CODEUNIT.Run("Codeunit number", Rec);
        FailureCondition := FailureCondition or ("Total steps" = 0);
        if FailureCondition then
            Error(InvalidCodeunitErr, "Codeunit number");
    end;

    [Scope('OnPrem')]
    procedure SetManualSteps(Steps: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(Steps);
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Manual detailed steps"));
        RecordRef.SetTable(Rec);
    end;

    [Scope('OnPrem')]
    procedure GetManualSteps() Content: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo("Manual detailed steps"));
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(Content);
    end;
}

