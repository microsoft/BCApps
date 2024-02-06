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
#if not CLEAN24
#pragma warning disable AL0432
        modify(Implementation)
        {
            trigger OnAfterValidate()
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
        }
        modify("Allow Gaps in Nos.")
        {
            trigger OnAfterValidate()
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
        }
        modify("Authorization Year")
        {
            trigger OnAfterValidate()
            begin
                if StrLen(Format("Authorization Year")) <> 4 then
                    Message(ShouldBeValidYearErr);
            end;
        }
#pragma warning restore AL0432
#endif
    }

#if not CLEAN24
    var
        ShouldBeValidYearErr: Label 'Should be a valid year.';

    protected var
        [Obsolete('Use the Implementation field instead.', '24.0')]
        SkipAllowGapsValidationTrigger: Boolean;

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

    [Obsolete('This functionality will be removed without public replacement.', '24.0')]
    procedure ExtractNoFromCode(NumberCode: Code[20]): BigInteger
    var
        NoSeriesSequenceImpl: Codeunit "No. Series - Sequence Impl.";
    begin
        exit(NoSeriesSequenceImpl.ExtractNoFromCode(NumberCode));
    end;

    [Obsolete('This functionality will be removed without public replacement.', '24.0')]
    procedure GetFormattedNo(Number: BigInteger): Code[20]
    var
        NoSeriesSequenceImpl: Codeunit "No. Series - Sequence Impl.";
    begin
        exit(NoSeriesSequenceImpl.GetFormattedNo(Rec, Number));
    end;
#endif

}