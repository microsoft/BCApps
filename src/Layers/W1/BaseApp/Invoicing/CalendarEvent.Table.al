#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 2160 "Calendar Event"
{
    Caption = 'Calendar Event';
    Permissions = TableData "Calendar Event" = rimd;
    ReplicateData = false;
    ObsoleteReason = 'Invoicing';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Scheduled Date"; Date)
        {
            Caption = 'Scheduled Date';
        }
        field(3; Archived; Boolean)
        {
            Caption = 'Archived';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run';
        }
        field(6; "Record ID to Process"; RecordID)
        {
            Caption = 'Record ID to Process';
            DataClassification = CustomerContent;
        }
        field(7; State; Option)
        {
            Caption = 'State';
            OptionCaption = 'Queued,In Progress,Completed,Failed,On Hold';
            OptionMembers = Queued,"In Progress",Completed,Failed,"On Hold";
        }
        field(8; Result; Text[250])
        {
            Caption = 'Result';
        }
        field(9; User; Code[50])
        {
            Caption = 'User';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'User,System';
            OptionMembers = User,System;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Scheduled Date", Archived, User)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Scheduled Date", Description, State)
        {
        }
    }

}
#endif