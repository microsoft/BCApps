// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit.Test;

using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;

codeunit 149060 "AIT Log Entry Blob Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        InputBlobMismatchErr: Label 'Input blob roundtrip should return the value passed to SetInputBlob.';
        OutputBlobMismatchErr: Label 'Output blob roundtrip should return the value passed to SetOutputBlob.';

    [Test]
    procedure InputBlobRoundtripSimpleText()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
        Expected: Text;
    begin
        // [SCENARIO 621544] Reading back a short text from "Input Data" must not crash the page.
        Expected := 'hello';

        EntryNo := CreatePersistedLogEntry(Expected, '');
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual(Expected, AITLogEntry.GetInputBlob(), InputBlobMismatchErr);
    end;

    [Test]
    procedure OutputBlobRoundtripSimpleText()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
        Expected: Text;
    begin
        // [SCENARIO 621544] Reading back a short text from "Output Data" must not crash the page.
        Expected := 'world';

        EntryNo := CreatePersistedLogEntry('', Expected);
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual(Expected, AITLogEntry.GetOutputBlob(), OutputBlobMismatchErr);
    end;

    [Test]
    procedure InputBlobRoundtripEmptyText()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
    begin
        // [SCENARIO] An entry persisted without input data returns an empty string.
        EntryNo := CreatePersistedLogEntry('', '');
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual('', AITLogEntry.GetInputBlob(), InputBlobMismatchErr);
        Assert.AreEqual('', AITLogEntry.GetOutputBlob(), OutputBlobMismatchErr);
    end;

    [Test]
    procedure InputBlobRoundtripMultilineText()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
        CRLF: Text[2];
        Expected: Text;
    begin
        // [SCENARIO 621544] Multi-line content (CR/LF) must roundtrip without being split or truncated.
        CRLF[1] := 13;
        CRLF[2] := 10;
        Expected := 'line1' + CRLF + 'line2' + CRLF + 'line3';

        EntryNo := CreatePersistedLogEntry(Expected, Expected);
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual(Expected, AITLogEntry.GetInputBlob(), InputBlobMismatchErr);
        Assert.AreEqual(Expected, AITLogEntry.GetOutputBlob(), OutputBlobMismatchErr);
    end;

    [Test]
    procedure InputBlobRoundtripUnicodeText()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
        Expected: Text;
    begin
        // [SCENARIO] Non-ASCII characters must roundtrip without corruption when stored in the UTF-8 BLOB.
        Expected := 'Grønbech 漢字 emoji 🚀 ümlaut';

        EntryNo := CreatePersistedLogEntry(Expected, Expected);
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual(Expected, AITLogEntry.GetInputBlob(), InputBlobMismatchErr);
        Assert.AreEqual(Expected, AITLogEntry.GetOutputBlob(), OutputBlobMismatchErr);
    end;

    [Test]
    procedure InputBlobRoundtripJsonPayload()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
        Expected: Text;
    begin
        // [SCENARIO 621544] A realistic JSON payload (which the AI Test Data Compare page parses) must roundtrip intact.
        Expected := '{"question":"What is the answer?","context":"Some context.","ground_truth":"42","test_setup":{"foo":"bar","nested":{"baz":1}}}';

        EntryNo := CreatePersistedLogEntry(Expected, Expected);
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual(Expected, AITLogEntry.GetInputBlob(), InputBlobMismatchErr);
        Assert.AreEqual(Expected, AITLogEntry.GetOutputBlob(), OutputBlobMismatchErr);
    end;

    [Test]
    procedure InputBlobRoundtripLargeText()
    var
        AITLogEntry: Record "AIT Log Entry";
        EntryNo: Integer;
        Expected: Text;
        i: Integer;
    begin
        // [SCENARIO] Content larger than a typical Read default length must roundtrip without truncation or error.
        for i := 1 to 200 do
            Expected += 'The quick brown fox jumps over the lazy dog. ';

        EntryNo := CreatePersistedLogEntry(Expected, Expected);
        AITLogEntry.Get(EntryNo);

        Assert.AreEqual(Expected, AITLogEntry.GetInputBlob(), InputBlobMismatchErr);
        Assert.AreEqual(Expected, AITLogEntry.GetOutputBlob(), OutputBlobMismatchErr);
    end;

    local procedure CreatePersistedLogEntry(InputText: Text; OutputText: Text): Integer
    var
        AITLogEntry: Record "AIT Log Entry";
    begin
        AITLogEntry.Init();
        AITLogEntry."Test Suite Code" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(AITLogEntry."Test Suite Code"));
        AITLogEntry.SetInputBlob(InputText);
        AITLogEntry.SetOutputBlob(OutputText);
        AITLogEntry.Insert(false);
        exit(AITLogEntry."Entry No.");
    end;
}
