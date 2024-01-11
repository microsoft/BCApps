// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// This object contains the obsoleted elements of the "No. Series" table.
/// </summary>
tableextension 309 NoSeriesLineObsolete extends "No. Series Line"
{
    fields
    {
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

#if not CLEAN24
    var
        ShouldBeValidYearErr: Label 'Should be a valid year.';

    [Obsolete('Use the field Last Date Used instead.', '24.0')]
    procedure GetLastDateUsed(): Date
    begin
        exit("Last Date Used");
    end;

    [Obsolete('Moved to No. Series codeunit.', '24.0')]
    procedure GetLastNoUsed(): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.GetLastNoUsed(Rec));
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