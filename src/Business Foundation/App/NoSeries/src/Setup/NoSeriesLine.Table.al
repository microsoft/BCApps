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
                if Implementation = Enum::"No. Series Implementation"::Sequence then begin
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
                if Implementation = Enum::"No. Series Implementation"::Sequence then begin
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
                Open := CalculateOpen();
            end;
        }
        field(10; "Last Date Used"; Date)
        {
            Caption = 'Last Date Used';
        }
        field(11; "Allow Gaps in Nos."; Boolean)
        {
            Caption = 'Allow Gaps in Nos.';
            ObsoleteTag = '24.0';
            ObsoleteReason = 'The specific implementation is defined by the Implementation field and whether the implementation may produce gaps can be determined through the implementation interface or the procedure MayProduceGaps.';
#if not CLEAN24
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif

#if not CLEAN24
            trigger OnValidate()
            var
                NoSeries: Record "No. Series";
                NoSeriesMgt: Codeunit NoSeriesMgt;
            begin
                NoSeries.Get("Series Code");
                if Rec."Allow Gaps in Nos." = xRec."Allow Gaps in Nos." then
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

                if "Allow Gaps in Nos." then // Keep the implementation in sync with the Allow Gaps field
                    Validate(Implementation, Enum::"No. Series Implementation"::Sequence)
                else
                    Validate(Implementation, Enum::"No. Series Implementation"::Normal);
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
                NoSeriesSingle: Interface "No. Series - Single";
            begin
                NoSeriesSingle := Implementation;
                "Allow Gaps in Nos." := NoSeriesSingle.MayProduceGaps(); // Keep the Allow Gaps field in sync with the implementation
            end;
#pragma warning restore AL0432
#endif
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
            CalcFormula = lookup("No. Series"."No. Series Type" where(Code = field("Series Code")));
            Caption = 'No. Series Type';
            Editable = false;
            FieldClass = FlowField;
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

    procedure MayProduceGaps(): Boolean
    var
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        NoSeriesSingle := Implementation;
        exit(NoSeriesSingle.MayProduceGaps());
    end;

    local procedure CalculateOpen(): Boolean
    begin
        if "Ending No." = '' then
            exit(true);

        if "Last No. Used" = '' then
            exit(true);

        if "Last No. Used" >= "Ending No." then
            exit(false);

        if "Increment-by No." <> 1 then
            if IncrementNoText("Last No. Used", "Increment-by No.") > "Ending No." then
                exit(false);

        exit(true);
    end;

    local procedure IncrementNoText(No: Code[20]; IncrementByNo: Decimal): Code[20]
    var
        BigIntNo: BigInteger;
        BigIntIncByNo: BigInteger;
        StartPos: Integer;
        EndPos: Integer;
        NewNo: Code[20];
    begin
        GetIntegerPos(No, StartPos, EndPos);
        Evaluate(BigIntNo, CopyStr(No, StartPos, EndPos - StartPos + 1));
        BigIntIncByNo := IncrementByNo;
        NewNo := CopyStr(Format(BigIntNo + BigIntIncByNo, 0, 1), 1, MaxStrLen(NewNo));
        ReplaceNoText(No, NewNo, 0, StartPos, EndPos);
        exit(No);
    end;

    local procedure GetIntegerPos(No: Code[20]; var StartPos: Integer; var EndPos: Integer)
    var
        IsDigit: Boolean;
        i: Integer;
    begin
        StartPos := 0;
        EndPos := 0;
        if No <> '' then begin
            i := StrLen(No);
            repeat
                IsDigit := No[i] in ['0' .. '9'];
                if IsDigit then begin
                    if EndPos = 0 then
                        EndPos := i;
                    StartPos := i;
                end;
                i := i - 1;
            until (i = 0) or (StartPos <> 0) and not IsDigit;
        end;
    end;

    local procedure ReplaceNoText(var No: Code[20]; NewNo: Code[20]; FixedLength: Integer; StartPos: Integer; EndPos: Integer)
    var
        StartNo: Code[20];
        EndNo: Code[20];
        ZeroNo: Code[20];
        NewLength: Integer;
        OldLength: Integer;
    begin
        if StartPos > 1 then
            StartNo := CopyStr(CopyStr(No, 1, StartPos - 1), 1, MaxStrLen(StartNo));
        if EndPos < StrLen(No) then
            EndNo := CopyStr(CopyStr(No, EndPos + 1), 1, MaxStrLen(EndNo));
        NewLength := StrLen(NewNo);
        OldLength := EndPos - StartPos + 1;
        if FixedLength > OldLength then
            OldLength := FixedLength;
        if OldLength > NewLength then
            ZeroNo := CopyStr(PadStr('', OldLength - NewLength, '0'), 1, MaxStrLen(ZeroNo));
        if StrLen(StartNo) + StrLen(ZeroNo) + StrLen(NewNo) + StrLen(EndNo) > 20 then
            Error(NumberLengthErr, No);
        No := CopyStr(StartNo + ZeroNo + NewNo + EndNo, 1, MaxStrLen(No));
    end;

    var
        NumberLengthErr: Label 'The number %1 cannot be extended to more than 20 characters.', Comment = '%1=No.';
#if not CLEAN24
        ShouldBeValidYearErr: Label 'Should be a valid year.';

    [Obsolete('Use the field Last Date Used instead.', '24.0')]
    procedure GetLastDateUsed(): Date
    begin
        exit("Last Date Used");
    end;

    [Obsolete('Moved to No. Series codeunit.', '24.0')]
    procedure GetLastNoUsed(): Code[20]
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        exit(NoSeriesMgt.GetLastNoUsed(Rec));
    end;

    [Obsolete('Use GetNextNo in No. Series codeunit instead.', '24.0')]
    procedure GetNextSequenceNo(ModifySeries: Boolean): Code[20]
    var
        NoSeries: Interface "No. Series - Single";
    begin
        NoSeries := Enum::"No. Series Implementation"::Sequence;
        if ModifySeries then
            exit(NoSeries.GetNextNo(Rec, WorkDate(), false));
        exit(NoSeries.PeekNextNo(Rec, WorkDate()));
    end;

    [Obsolete('This functionality has been removed and getting the number from a string is no longer part of No. Series.', '24.0')]
    procedure ExtractNoFromCode(NumberCode: Code[20]): BigInteger
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        exit(NoSeriesMgt.ExtractNoFromCode(NumberCode));
    end;

    [Obsolete('This functionality has been removed.', '24.0')]
    procedure GetFormattedNo(Number: BigInteger): Code[20]
    var
        NoSeriesMgt: Codeunit NoSeriesMgt;
    begin
        exit(NoSeriesMgt.GetFormattedNo(Rec, Number));
    end;
#endif
}