// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Captures the outcome of every test method executed during a stability run, for each preset
/// combination. Both passing and failing results are stored so per-combination pass rates and the
/// failure details (error message and call stack) are available for troubleshooting.
/// </summary>
table 130467 "Stability Run Result"
{
    DataClassification = CustomerContent;
    ReplicateData = false;
    Caption = 'Stability Run Result';
    LookupPageId = "Stability Run Results";
    DrillDownPageId = "Stability Run Results";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Base Suite"; Code[10])
        {
            Caption = 'Base Suite';
        }
        field(3; "Configuration"; Text[250])
        {
            Caption = 'Configuration';
        }
        field(4; "Generated Suite"; Code[10])
        {
            Caption = 'Generated Suite';
        }
        field(5; "Test Codeunit"; Integer)
        {
            Caption = 'Test Codeunit';
        }
        field(6; "Codeunit Name"; Text[128])
        {
            Caption = 'Codeunit Name';
        }
        field(7; "Method"; Text[128])
        {
            Caption = 'Method';
        }
        field(8; "Result"; Option)
        {
            Caption = 'Result';
            OptionMembers = " ",Failure,Success,Skipped;
        }
        field(9; "Seed"; Integer)
        {
            Caption = 'Seed';
        }
        field(10; "Seed Overridden"; Boolean)
        {
            Caption = 'Seed Overridden';
        }
        field(11; "WorkDate Offset"; Text[30])
        {
            Caption = 'WorkDate Offset';
        }
        field(12; "WorkDate"; Date)
        {
            Caption = 'WorkDate';
        }
        field(13; "Reverse Codeunits"; Boolean)
        {
            Caption = 'Reverse Codeunits';
        }
        field(14; "Reverse Methods"; Boolean)
        {
            Caption = 'Reverse Methods';
        }
        field(15; "One By One"; Boolean)
        {
            Caption = 'One By One';
        }
        field(16; "Duration"; Duration)
        {
            Caption = 'Duration';
        }
        field(17; "Executed At"; DateTime)
        {
            Caption = 'Executed At';
        }
        field(18; "Error Message Preview"; Text[2048])
        {
            Caption = 'Error Message Preview';
        }
        field(19; "Error Message"; Blob)
        {
            Caption = 'Error Message';
        }
        field(20; "Error Call Stack"; Blob)
        {
            Caption = 'Error Call Stack';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Base Suite", "Configuration")
        {
        }
        key(Key3; "Result")
        {
        }
    }

    procedure SetErrorMessage(ErrorMessage: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Error Message");
        "Error Message".CreateOutStream(OutStr, TextEncoding::UTF16);
        OutStr.WriteText(ErrorMessage);
    end;

    procedure GetErrorMessage(): Text
    var
        InStr: InStream;
        ErrorMessage: Text;
    begin
        CalcFields("Error Message");
        if not "Error Message".HasValue() then
            exit('');
        "Error Message".CreateInStream(InStr, TextEncoding::UTF16);
        InStr.ReadText(ErrorMessage);
        exit(ErrorMessage);
    end;

    procedure SetErrorCallStack(CallStack: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Error Call Stack");
        "Error Call Stack".CreateOutStream(OutStr, TextEncoding::UTF16);
        OutStr.WriteText(CallStack);
    end;

    procedure GetErrorCallStack(): Text
    var
        InStr: InStream;
        CallStack: Text;
    begin
        CalcFields("Error Call Stack");
        if not "Error Call Stack".HasValue() then
            exit('');
        "Error Call Stack".CreateInStream(InStr, TextEncoding::UTF16);
        InStr.ReadText(CallStack);
        exit(CallStack);
    end;
}
