// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 309 "No. Series Line"
{
    Caption = 'No. Series Line';
    DrillDownPageID = "No. Series Lines";
    LookupPageID = "No. Series Lines";
    DataClassification = CustomerContent;
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
                NoSeriesMgt.UpdateStartingSequenceNo(Rec);
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
            var
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                Validate(Open);
                if "Allow Gaps in Nos." then begin
                    NoSeriesMgt.RecreateSequence(Rec);
                    if "Line No." <> 0 then
                        if Modify() then;
                end;
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
                if "Allow Gaps in Nos." then begin
                    NoSeriesMgt.RecreateSequence(Rec);
                    if "Line No." <> 0 then
                        if Modify() then;
                end;
            end;
        }
        field(9; Open; Boolean)
        {
            Caption = 'Open';
            Editable = false;
            InitValue = true;

            trigger OnValidate()
            begin
                Open := ("Ending No." = '') or ("Ending No." <> "Last No. Used");
            end;
        }
        field(10; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
        field(11; "Allow Gaps in Nos."; Boolean)
        {
            Caption = 'Allow Gaps in Nos.';

            trigger OnValidate()
            var
                NoSeries: Record "No. Series";
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeries.Get("Series Code");
                if "Allow Gaps in Nos." = xRec."Allow Gaps in Nos." then
                    exit;
                if "Allow Gaps in Nos." then
                    NoSeriesMgt.RecreateSequence(Rec)
                else begin
                    "Last No. Used" := NoSeriesMgt.GetLastNoUsed(xRec);
                    NoSeriesMgt.DeleteSequence(Rec);
                    "Starting Sequence No." := 0;
                    "Sequence Name" := '';
                end;
                if "Line No." <> 0 then
                    Modify();
            end;
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
        field(10000; Series; Code[10]) // NA (MX) Functionality
        {
            Caption = 'Series';
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
#if not CLEAN24
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#endif
        }
        field(10001; "Authorization Code"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Code';
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
#if not CLEAN24
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
#endif
        }
        field(10002; "Authorization Year"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Year';
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
        field(12100; "No. Series Type"; Enum "No. Series Type")
        {
            Caption = 'No. Series Type';
            FieldClass = FlowField;
            CalcFormula = lookup("No. Series"."No. Series Type" where(Code = field("Series Code")));
            Editable = false;
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

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        // A delete trigger (subscriber) is placed in codeunit 396 to clean up NumberSequence
    end;


#if not CLEAN24
    var
        ShouldBeValidYearErr: Label 'Should be a valid year.';

    [Obsolete('Use the field Last Date Used instead.', '24.0')]
    procedure GetLastDateUsed(): Date
    begin
        exit("Last Date Used");
    end;

    [Obsolete('Moved to SequenceNoSeriesManagement.', '24.0')]
    procedure GetLastNoUsed(): Code[20]
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        exit(NoSeriesMgt.GetLastNoUsed(Rec));
    end;

    [Obsolete('Moved to SequenceNoSeriesManagement.', '24.0')]
    procedure GetNextSequenceNo(ModifySeries: Boolean): Code[20]
    var
        NoSeries: Interface "No. Series - Single";
    begin
        NoSeries := Enum::"No. Series Implementation"::Sequence;
        if ModifySeries then
            exit(NoSeries.GetNextNo(Rec));
        exit(NoSeries.PeekNextNo(Rec));
    end;

    [Obsolete('Moved to SequenceNoSeriesManagement.', '24.0')]
    procedure ExtractNoFromCode(NumberCode: Code[20]): BigInteger
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        exit(NoSeriesMgt.ExtractNoFromCode(NumberCode));
    end;

    [Obsolete('Moved to SequenceNoSeriesManagement.', '24.0')]
    procedure GetFormattedNo(Number: BigInteger): Code[20]
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        exit(NoSeriesMgt.GetFormattedNo(Rec, Number));
    end;
#endif
}