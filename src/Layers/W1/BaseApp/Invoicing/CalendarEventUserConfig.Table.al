#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AS0001,AS0115,AA0247
table 2161 "Calendar Event User Config."
{
    Caption = 'Calendar Event User Config.';
    ReplicateData = false;
    DataClassification = CustomerContent;
    ObsoleteReason = 'Invoicing';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';

    fields
    {
        field(1; User; Code[50])
        {
            Caption = 'User';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Default Execute Time"; Time)
        {
            Caption = 'Default Execute Time';
            InitValue = 000000T;

            trigger OnValidate()
            begin
                if "Default Execute Time" = 0T then
                    "Default Execute Time" := 000000T
            end;
        }
        field(3; "Current Job Queue Entry"; Guid)
        {
            Caption = 'Current Job Queue Entry';
        }
    }

    keys
    {
        key(Key1; User)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif