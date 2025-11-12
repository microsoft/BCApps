// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

table 6752 "Reminder Action Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Run Id"; Integer)
        {
        }
        field(3; "Reminder Action Group ID"; Code[50])
        {
        }
        field(4; "Reminder Action ID"; Code[50])
        {
        }
        field(5; "Total Records Processed"; Integer)
        {
        }
#if not CLEANSCHEMA28
        field(6; "Total Errors"; Integer)
        {
#if not CLEAN26
            ObsoleteState = Pending;
            ObsoleteReason = 'This field is obsolete and should not be used.';
#pragma warning disable AS0074
            ObsoleteTag = '26.0';
#pragma warning restore AS0074
#else
            ObsoleteState = Removed;
            ObsoleteReason = 'This field is obsolete and should not be used.';
            ObsoleteTag = '28.0';
#endif
        }
#endif
        field(7; "Last Record Processed"; RecordId)
        {
        }
        field(10; Status; Enum "Reminder Log Status")
        {
        }
        field(11; "Status summary"; Text[1024])
        {
        }
        field(12; "Details"; Blob)
        {
        }
        field(13; JobQueueID; Guid)
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
}