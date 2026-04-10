// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Stores error records from failed reminder automation actions with error type, message, and related document details.
/// </summary>
table 6754 "Reminder Automation Error"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "Reminder Aut. Error Overview";
    LookupPageId = "Reminder Aut. Error Overview";

    fields
    {
        /// <summary>
        /// Specifies the unique auto-incrementing identifier for this error record.
        /// </summary>
        field(1; Id; Integer)
        {
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        /// <summary>
        /// Specifies the reminder action code where the error occurred.
        /// </summary>
        field(2; ReminderActionId; Code[50])
        {
            ToolTip = 'Specifies the id of the reminder action that caused the error.';
        }
        /// <summary>
        /// Contains the full error message text.
        /// </summary>
        field(3; "Error Text"; Blob)
        {
        }
        /// <summary>
        /// Contains the error call stack for debugging purposes.
        /// </summary>
        field(4; "Error Call Stack"; Blob)
        {
        }
        /// <summary>
        /// Contains a shortened version of the error text for display purposes.
        /// </summary>
        field(5; "Error Text Short"; Text[1024])
        {
            ToolTip = 'Specifies the error message. Invoke the error message to see the full error message.';
        }
        /// <summary>
        /// Specifies the automation run ID during which this error occurred.
        /// </summary>
        field(6; "Run Id"; Integer)
        {
            ToolTip = 'Specifies the id of the reminder action job that caused the error.';
        }
        /// <summary>
        /// Specifies the type of error that occurred during automation processing.
        /// </summary>
        field(7; "Error Type"; Enum "Reminder Automation Error Type")
        {
        }
        /// <summary>
        /// Specifies the reminder action group code where the error occurred.
        /// </summary>
        field(8; "Reminder Action Group Code"; Code[50])
        {
        }
        /// <summary>
        /// Indicates whether this error has been dismissed by the user.
        /// </summary>
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

    /// <summary>
    /// Gets the full error message text from the blob field.
    /// </summary>
    /// <returns>The complete error message text.</returns>
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

    /// <summary>
    /// Sets the error message text in both the blob field and the short text field.
    /// </summary>
    /// <param name="NewErrorMessage">The error message text to store.</param>
    procedure SetErrorMessage(NewErrorMessage: Text)
    var
        ErrorMessageOutStream: OutStream;
    begin
        Rec."Error Text Short" := CopyStr(NewErrorMessage, 1, MaxStrLen(Rec."Error Text Short"));
        Rec."Error Text".CreateOutStream(ErrorMessageOutStream, GetDefaultEncoding());
        ErrorMessageOutStream.WriteText(NewErrorMessage);
        Rec.Modify();
    end;

    /// <summary>
    /// Gets the error call stack text from the blob field.
    /// </summary>
    /// <returns>The error call stack text for debugging.</returns>
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

    /// <summary>
    /// Sets the error call stack text in the blob field.
    /// </summary>
    /// <param name="NewErrorCallStack">The error call stack text to store.</param>
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