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
#pragma warning disable AS0004
        field(15; "Temp Current Sequence No."; BigInteger)
        {
            Caption = 'Temporary Sequence Number';
            DataClassification = SystemMetadata;
            Access = Internal;
        }
#pragma warning restore AS0004
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