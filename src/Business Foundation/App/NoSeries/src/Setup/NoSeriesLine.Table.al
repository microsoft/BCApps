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
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeriesMgt.UpdateNoSeriesLine(Rec, "Starting No.", CopyStr(FieldCaption("Starting No."), 1, 100));
            end;
        }
        field(5; "Ending No."; Code[20])
        {
            Caption = 'Ending No.';

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                if "Ending No." = '' then
                    "Warning No." := '';
                NoSeriesMgt.UpdateNoSeriesLine(Rec, "Ending No.", CopyStr(FieldCaption("Ending No."), 1, 100));
                Validate(Open);
            end;
        }
        field(6; "Warning No."; Code[20])
        {
            Caption = 'Warning No.';

            trigger OnValidate()
            var
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                TestField("Ending No.");
                NoSeriesMgt.UpdateNoSeriesLine(Rec, "Warning No.", CopyStr(FieldCaption("Warning No."), 1, 100));
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
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeriesMgt.UpdateNoSeriesLine(Rec, "Last No. Used", CopyStr(FieldCaption("Last No. Used"), 1, 100));
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
                NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
            begin
                Open := NoSeriesSetupImpl.CalculateOpen(Rec);
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

            trigger OnValidate()
            var
                NoSeries: Record "No. Series";
            begin
                NoSeries.Get("Series Code");
                if Rec."Allow Gaps in Nos." = xRec."Allow Gaps in Nos." then
                    exit;
                if SkipAllowGapsValidationTrigger then begin
                    SkipAllowGapsValidationTrigger := false;
                    exit;
                end;

                if "Allow Gaps in Nos." then // Keep the implementation in sync with the Allow Gaps field
                    Validate(Implementation, Enum::"No. Series Implementation"::Sequence)
                else
                    Validate(Implementation, Enum::"No. Series Implementation"::Normal);

                if "Line No." <> 0 then
                    Modify();
            end;
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

#if not CLEAN24
#pragma warning disable AL0432
            trigger OnValidate()
            var
                NoSeriesSetupImpl: Codeunit "No. Series - Setup Impl.";
            begin
                if Rec.Implementation = xRec.Implementation then
                    exit;

#pragma warning disable AA0206
                SkipAllowGapsValidationTrigger := true;
#pragma warning restore AA0206

                Validate("Allow Gaps in Nos.", NoSeriesSetupImpl.MayProduceGaps(Rec)); // Keep the Allow Gaps field in sync with the implementation
            end;
#pragma warning restore AL0432
#endif
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

            trigger OnValidate()
            begin
                if StrLen(Format("Authorization Year")) <> 4 then
                    Message(ShouldBeValidYearErr);
            end;
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

#if not CLEAN24
    var
        ShouldBeValidYearErr: Label 'Should be a valid year.';
        SkipAllowGapsValidationTrigger: Boolean;
#endif
}