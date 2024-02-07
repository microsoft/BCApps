// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 309 "No. Series Line"
{
    Caption = 'No. Series Line';
    DataClassification = CustomerContent;
    DrillDownPageId = "No. Series Lines";
    LookupPageId = "No. Series Lines";
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
    InherentEntitlements = rX;
    InherentPermissions = rX;

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

            trigger OnValidate()
            var
                NoSeriesSetup: Codeunit "No. Series - Setup";
            begin
                NoSeriesSetup.UpdateNoSeriesLine(Rec, "Starting No.", CopyStr(FieldCaption("Starting No."), 1, 100));
            end;
        }
        field(5; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';

            trigger OnValidate()
            var
                NoSeriesSetup: Codeunit "No. Series - Setup";
            begin
                if "Ending No." = '' then
                    "Warning No." := '';
                NoSeriesSetup.UpdateNoSeriesLine(Rec, "Ending No.", CopyStr(FieldCaption("Ending No."), 1, 100));
                Validate(Open);
            end;
        }
        field(6; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';

            trigger OnValidate()
            var
                NoSeriesSetup: Codeunit "No. Series - Setup";
            begin
                TestField("Ending No.");
                NoSeriesSetup.UpdateNoSeriesLine(Rec, "Warning No.", CopyStr(FieldCaption("Warning No."), 1, 100));
            end;
        }
        field(7; "Increment-by No."; Integer)
        {
            Caption = 'Increment-by No.';
            InitValue = 1;
            MinValue = 1;

            trigger OnValidate()
            begin
                Validate(Open);
            end;
        }
        field(8; "Last No. Used"; Code[20])
        {
            Caption = 'Last No. Used';

            trigger OnValidate()
            var
                NoSeriesSetup: Codeunit "No. Series - Setup";
            begin
                NoSeriesSetup.UpdateNoSeriesLine(Rec, "Last No. Used", CopyStr(FieldCaption("Last No. Used"), 1, 100));
                Validate(Open);
            end;
        }
        field(9; Open; Boolean)
        {
            Caption = 'Open';
            Editable = false;
            InitValue = true;

            trigger OnValidate()
            var
                NoSeriesSetup: Codeunit "No. Series - Setup";
            begin
                Open := NoSeriesSetup.CalculateOpen(Rec);
            end;
        }
        field(10; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
        field(11; "Allow Gaps in Nos."; Boolean)
        {
            Caption = 'Allow Gaps in Nos.';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The specific implementation is defined by the Implementation field and whether the implementation may produce gaps can be determined through the implementation interface or the procedure MayProduceGaps.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
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
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(14; Implementation; Enum "No. Series Implementation")
        {
            Caption = 'Implementation';
            DataClassification = SystemMetadata;

        }
        field(10000; Series; Code[10]) // NA (MX) Functionality
        {
            Caption = 'Series';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
        }
        field(10001; "Authorization Code"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
        }
        field(10002; "Authorization Year"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Year';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
#if CLEAN24
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#endif
        }
    }

    keys
    {
        key(Key1; "Series Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Series Code", "Starting Date", "Starting No.", Open)
        {
        }
        key(Key3; "Starting No.")
        {
        }
        key(Key4; "Last Date Used")
        {
        }
    }
}