#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 309 "No. Series Line"
{
    Caption = 'No. Series Line';
    DataClassification = CustomerContent;
    ObsoleteReason = 'No. Series is moved to Business Foundation';
    ObsoleteState = Moved;
    ObsoleteTag = '24.0';
    MovedTo = 'f3552374-a1f2-4356-848e-196002525837';

    fields
    {
        field(1; "Series Code"; Code[20])
        {
            Caption = 'Series Code';
            NotBlank = true;
            TableRelation = "No. Series";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; "Starting No."; Code[20])
        {
            Caption = 'Starting No.';
        }
        field(5; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';
        }
        field(6; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';
        }
        field(7; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
            InitValue = 1;
            MinValue = 1;
        }
        field(8; "Last No. Used"; Code[20])
        {
            Caption = 'Last No. Used';
        }
        field(9; Open; Boolean)
        {
            Caption = 'Open';
            Editable = false;
            InitValue = true;
        }
        field(10; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
        field(11; "Allow Gaps in Nos."; Boolean)
        {
            Caption = 'Allow Gaps in Nos.';
        }
        field(12; "Sequence Name"; Code[40])
        {
            Caption = 'Sequence Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(13; "Starting Sequence No."; BigInteger)
        {
            Caption = 'Starting Sequence No.';
            Editable = false;
        }
#if not CLEANSCHEMA27
        field(10000; Series; Code[10]) // NA (MX) Functionality
        {
            Caption = 'Series';
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
#if not CLEANSCHEMA27
        field(10001; "Authorization Code"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Code';
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
#if not CLEANSCHEMA27
        field(10002; "Authorization Year"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Year';
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Series Code", "Line No.")
        {
            Clustered = true;
        }
    }
}
#endif