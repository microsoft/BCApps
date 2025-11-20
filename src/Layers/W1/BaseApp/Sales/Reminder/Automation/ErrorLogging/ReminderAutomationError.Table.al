// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

table 6754 "Reminder Automation Error"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "Reminder Aut. Error Overview";
    LookupPageId = "Reminder Aut. Error Overview";

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; ReminderActionId; Code[50])
        {
        }
        field(3; "Error Text"; Blob)
        {
        }
        field(4; "Error Call Stack"; Blob)
        {
        }
        field(5; "Error Text Short"; Text[1024])
        {
        }
        field(6; "Run Id"; Integer)
        {
        }
        field(7; "Error Type"; Enum "Reminder Automation Error Type")
        {
        }
        field(8; "Reminder Action Group Code"; Code[50])
        {
        }
        field(10; Dismissed; Boolean)
        {
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    procedure GetErrorMessage(): Text
    var
        ErrorMessageInStream: InStream;
        ErrorMessage: Text;
    begin
        CalcFields(Rec."Error Text");
        Rec."Error Text".CreateInStream(ErrorMessageInStream, GetDefaultEncoding());
        ErrorMessageInStream.ReadText(ErrorMessage);
        exit(ErrorMessage);
    end;

    procedure SetErrorMessage(NewErrorMessage: Text)
    var
        ErrorMessageOutStream: OutStream;
    begin
        Rec."Error Text Short" := CopyStr(NewErrorMessage, 1, MaxStrLen(Rec."Error Text Short"));
        Rec."Error Text".CreateOutStream(ErrorMessageOutStream, GetDefaultEncoding());
        ErrorMessageOutStream.WriteText(NewErrorMessage);
        Rec.Modify();
    end;

    procedure GetErrorCallstack(): Text
    var
        ErrorCallstackInStream: InStream;
        ErrorCallstack: Text;
    begin
        CalcFields(Rec."Error Call Stack");
        Rec."Error Call Stack".CreateInStream(ErrorCallstackInStream, GetDefaultEncoding());
        ErrorCallstackInStream.ReadText(ErrorCallstack);
        exit(ErrorCallstack);
    end;

    procedure SetErrorCallStack(NewErrorCallStack: Text)
    var
        ErrorCallstackOutStream: OutStream;
    begin
        Rec."Error Call Stack".CreateOutStream(ErrorCallstackOutStream, GetDefaultEncoding());
        ErrorCallstackOutStream.WriteText(NewErrorCallStack);
        Rec.Modify();
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF16);
    end;
}