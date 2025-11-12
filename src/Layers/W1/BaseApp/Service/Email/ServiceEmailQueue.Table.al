// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Email;

using System.Threading;

table 5935 "Service Email Queue"
{
    Caption = 'Service Email Queue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "To Address"; Text[80])
        {
            Caption = 'To Address';
        }
        field(3; "Copy-to Address"; Text[80])
        {
            Caption = 'Copy-to Address';
        }
        field(4; "Subject Line"; Text[250])
        {
            Caption = 'Subject Line';
        }
        field(5; "Body Line"; Text[250])
        {
            Caption = 'Body Line';
        }
        field(6; "Attachment Filename"; Text[80])
        {
            Caption = 'Attachment Filename';
        }
        field(7; "Sending Date"; Date)
        {
            Caption = 'Sending Date';
        }
        field(8; "Sending Time"; Time)
        {
            Caption = 'Sending Time';
        }
        field(9; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Processed,Error';
            OptionMembers = " ",Processed,Error;
        }
        field(10; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Service Order';
            OptionMembers = " ","Service Order";
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Status, "Sending Date", "Document Type", "Document No.")
        {
        }
        key(Key3; "Document Type", "Document No.", Status, "Sending Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ServEmailQueue: Record "Service Email Queue";
    begin
        if "Entry No." = 0 then begin
            ServEmailQueue.Reset();
            if ServEmailQueue.FindLast() then
                "Entry No." := ServEmailQueue."Entry No." + 1
            else
                "Entry No." := 1;
        end;

        "Sending Date" := Today;
        "Sending Time" := Time;
    end;

    procedure ScheduleInJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.Validate("Object ID to Run", CODEUNIT::"Process Service Email Queue");
        JobQueueEntry.Validate("Record ID to Process", RecordId);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;
}

