// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

/// <summary>
/// Stores incoming notification records for intercompany transaction processing via API data exchange.
/// Tracks notification status, error handling, and operation progress for cross-partner communication.
/// </summary>
table 613 "IC Incoming Notification"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Unique identifier linking this notification to a specific intercompany operation.
        /// </summary>
        field(1; "Operation ID"; Guid)
        {
            Caption = 'Operation ID';
        }
        /// <summary>
        /// Code of the intercompany partner that sent this notification.
        /// </summary>
        field(2; "Source IC Partner Code"; Code[20])
        {
            Caption = 'Source Intercompany Partner Code';
        }
        /// <summary>
        /// Code of the intercompany partner that should receive this notification.
        /// </summary>
        field(3; "Target IC Partner Code"; Code[20])
        {
            Caption = 'Target Intercompany Partner Code';
        }
        /// <summary>
        /// Date and time when the notification was created or last updated.
        /// </summary>
        field(10; "Notified DateTime"; DateTime)
        {
            Caption = 'Notified DateTime';
        }
        /// <summary>
        /// Current processing status of the incoming notification.
        /// </summary>
        field(20; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Failed,Processed,Scheduled for deletion failed';
            OptionMembers = Created,Failed,Processed,"Scheduled for deletion failed";
        }
        /// <summary>
        /// Error message details for failed notification processing stored as BLOB for extended text.
        /// </summary>
        field(21; "Error Message"; Blob)
        {
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(Key1; "Operation ID")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Stores error message text in the BLOB field for detailed error tracking.
    /// Handles extended error messages that exceed standard text field limits.
    /// </summary>
    /// <param name="value">Error message text to store in the notification record</param>
    procedure SetErrorMessage(value: Text)
    var
        outStr: OutStream;
    begin
        Rec."Error Message".CreateOutStream(outStr);
        outStr.WriteText(value);
    end;

    /// <summary>
    /// Retrieves error message text from the BLOB field for display or processing.
    /// Returns empty string if no error message is stored.
    /// </summary>
    /// <param name="value">Variable to receive the error message text</param>
    procedure GetErrorMessage(value: Text)
    var
        inStr: InStream;
    begin
        CalcFields(Rec."Error Message");
        if Rec."Error Message".HasValue() then begin
            Rec."Error Message".CreateInStream(inStr);
            inStr.ReadText(value);
        end
        else
            value := '';
    end;
}
