// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 307 "No. Series - Sequence Impl." implements "No. Series - Single"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "No. Series" = r,
        tabledata "No. Series Line" = rimd;

    var
        NoOverFlowErr: Label 'Number series can only use up to 18 digit numbers. %1 has %2 digits.', Comment = '%1 is a string that also contains digits. %2 is a number.';
        NoSeriesSequenceTxt: Label 'No. Series - Sequence', Locked = true;
        UpdatingSequenceBasedOnTempValueTxt: Label 'Updating sequence based on temporary value.', Locked = true;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(GetNextNoInternal(NoSeriesLine, false, UsageDate, false));
    end;

    /// <remarks>
    /// Whenever the Last Date Used Changes, the No. Series Line will be modified. The UpdateLock is only set in cases where the No. Series Line will be modified.
    /// The "Temp Current Sequence No." must be preserved in case we use UpdLock as the Find() will reset it.
    /// </remarks>
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        TempCurrentSequenceNo: Integer;
    begin
        if (not NoSeriesLine.IsTemporary()) and (NoSeriesLine."Last Date Used" <> UsageDate) then begin
            NoSeriesLine.ReadIsolation(IsolationLevel::UpdLock);
            TempCurrentSequenceNo := NoSeriesLine."Temp Current Sequence No.";
            NoSeriesLine.Find();
            NoSeriesLine."Temp Current Sequence No." := TempCurrentSequenceNo;
        end;

        exit(GetNextNoInternal(NoSeriesLine, true, UsageDate, HideErrorsAndWarnings));
    end;

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        LastSeqNoUsed: BigInteger;
    begin
        LastSeqNoUsed := GetCurrentSequenceNo(NoSeriesLine);
        if LastSeqNoUsed >= NoSeriesLine."Starting Sequence No." then
            exit(GetFormattedNo(NoSeriesLine, LastSeqNoUsed));
        exit(''); // No. Series has not been used yet, so there is no last no. used
    end;

    procedure MayProduceGaps(): Boolean
    begin
        exit(true);
    end;

    local procedure GetCurrentSequenceNo(var NoSeriesLine: Record "No. Series Line") LastSeqNoUsed: BigInteger
    begin
        if NoSeriesLine."Temp Current Sequence No." <> 0 then
            exit(NoSeriesLine."Temp Current Sequence No.");

        if not TryGetCurrentSequenceNo(NoSeriesLine."Sequence Name", LastSeqNoUsed) then begin
            if not NumberSequence.Exists(NoSeriesLine."Sequence Name") then
                CreateNewSequence(NoSeriesLine);
            TryGetCurrentSequenceNo(NoSeriesLine."Sequence Name", LastSeqNoUsed);
        end;
    end;

    [TryFunction]
    local procedure TryGetCurrentSequenceNo(SequenceName: Code[40]; var LastSeqNoUsed: BigInteger)
    begin
        LastSeqNoUsed := NumberSequence.Current(SequenceName);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'm')]
    local procedure GetNextNoInternal(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesLine2: Record "No. Series Line";
        NoSeriesStatelessImpl: Codeunit "No. Series - Stateless Impl.";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
#pragma warning restore AL0432
#endif
        NewNo: BigInteger;
    begin
        if NoSeriesLine.IsTemporary() or (NoSeriesLine."Temp Current Sequence No." <> 0) then begin // Do not update the database for temporary records, if Temp Current Sequence No. is set that means we are emulating the next numbers
            if NoSeriesLine."Temp Current Sequence No." = 0 then
                NoSeriesLine."Temp Current Sequence No." := GetCurrentSequenceNo(NoSeriesLine);

            NewNo := NoSeriesLine."Temp Current Sequence No." + NoSeriesLine."Increment-by No.";

            if ModifySeries then
                NoSeriesLine."Temp Current Sequence No." := NewNo;
        end else
            if not TryGetNextSequenceNo(NoSeriesLine, ModifySeries, NewNo) then begin
                if not NumberSequence.Exists(NoSeriesLine."Sequence Name") then
                    CreateNewSequence(NoSeriesLine);
                TryGetNextSequenceNo(NoSeriesLine, ModifySeries, NewNo);
            end;

        NoSeriesLine2 := NoSeriesLine;
        NoSeriesLine2."Last No. Used" := GetFormattedNo(NoSeriesLine, NewNo);
        NoSeriesLine2.Validate(Open);

        if not NoSeriesStatelessImpl.EnsureLastNoUsedIsWithinValidRange(NoSeriesLine2, HideErrorsAndWarnings) then
            exit('');

        if ModifySeries and ((NoSeriesLine."Last Date Used" <> UsageDate) or (NoSeriesLine.Open <> NoSeriesLine2.Open) or NoSeriesLine.IsTemporary()) then begin // Only modify the series if either the date or the open status has changed. Otherwise avoid locking the record.
            NoSeriesLine."Last Date Used" := UsageDate;
            NoSeriesLine.Open := NoSeriesLine2.Open;
#if not CLEAN24
#pragma warning disable AL0432
            NoSeriesManagement.RaiseObsoleteOnBeforeModifyNoSeriesLine(NoSeriesLine, IsHandled);
            if not IsHandled then
#pragma warning restore AL0432
#endif
            NoSeriesLine.Modify(true);
        end;

        exit(NoSeriesLine2."Last No. Used");
    end;

    [TryFunction]
    local procedure TryGetNextSequenceNo(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; var NewNo: BigInteger)
    begin
        if ModifySeries then begin
            NewNo := NumberSequence.Next(NoSeriesLine."Sequence Name");
            if NewNo < NoSeriesLine."Starting Sequence No." then
                NewNo := NumberSequence.Next(NoSeriesLine."Sequence Name");
        end else begin
            NewNo := NumberSequence.Current(NoSeriesLine."Sequence Name");
            NewNo += NoSeriesLine."Increment-by No.";
        end;
    end;

#if not CLEAN24
    internal procedure CreateNewSequence(var NoSeriesLine: Record "No. Series Line")
#else
    local procedure CreateNewSequence(var NoSeriesLine: Record "No. Series Line")
#endif
    begin
        CreateNewSequence(NoSeriesLine, NoSeriesLine."Starting Sequence No.");
    end;

    local procedure CreateNewSequence(var NoSeriesLine: Record "No. Series Line"; StartingSequenceNo: BigInteger)
    begin
        if NoSeriesLine."Sequence Name" = '' then
            NoSeriesLine."Sequence Name" := Format(CreateGuid(), 0, 4);

        NoSeriesLine."Starting Sequence No." := StartingSequenceNo;
        NumberSequence.Insert(NoSeriesLine."Sequence Name", StartingSequenceNo - NoSeriesLine."Increment-by No.", NoSeriesLine."Increment-by No.");
        if NumberSequence.Next(NoSeriesLine."Sequence Name") = 0 then; // Get a number to make sure LastNoUsed is set correctly
    end;

#if not CLEAN24
    internal procedure GetFormattedNo(NoSeriesLine: Record "No. Series Line"; Number: BigInteger): Code[20]
#else
    local procedure GetFormattedNo(NoSeriesLine: Record "No. Series Line"; Number: BigInteger): Code[20]
#endif
    var
        NumberCode: Code[20];
        i: Integer;
        j: Integer;
    begin
        if Number < NoSeriesLine."Starting Sequence No." then
            exit('');
        NumberCode := Format(Number);
        if NoSeriesLine."Starting No." = '' then
            exit(NumberCode);
        i := StrLen(NoSeriesLine."Starting No.");
        while (i > 1) and not (NoSeriesLine."Starting No."[i] in ['0' .. '9']) do
            i -= 1;
        j := i - StrLen(NumberCode);
        if (j > 0) and (i < MaxStrLen(NoSeriesLine."Starting No.")) then
            exit(CopyStr(NoSeriesLine."Starting No.", 1, j) + NumberCode + CopyStr(NoSeriesLine."Starting No.", i + 1));
        if (j > 0) then
            exit(CopyStr(NoSeriesLine."Starting No.", 1, j) + NumberCode);
        while (i > 1) and (NoSeriesLine."Starting No."[i] in ['0' .. '9']) do
            i -= 1;
        if (i > 0) and (i + StrLen(NumberCode) <= MaxStrLen(NumberCode)) then
            if (i = 1) and (NoSeriesLine."Starting No."[i] in ['0' .. '9']) then
                exit(NumberCode)
            else
                exit(CopyStr(NoSeriesLine."Starting No.", 1, i) + NumberCode);
        exit(NumberCode);
    end;

    procedure ExtractNoFromCode(NumberCode: Code[20]; NoSeriesCode: Code[20]): BigInteger
    var
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
        i: Integer;
        j: Integer;
        Number: BigInteger;
        NoCodeSnip: Code[20];
    begin
        if NumberCode = '' then
            exit(0);
        i := StrLen(NumberCode);
        while (i > 1) and not (NumberCode[i] in ['0' .. '9']) do
            i -= 1;
        if i = 1 then begin
            if Evaluate(Number, Format(NumberCode[1])) then
                exit(Number);
            exit(0);
        end;
        j := i;
        while (i > 1) and (NumberCode[i] in ['0' .. '9']) do
            i -= 1;
        if (i = 1) and (NumberCode[i] in ['0' .. '9']) then
            i -= 1;
        NoCodeSnip := CopyStr(CopyStr(NumberCode, i + 1, j - i), 1, MaxStrLen(NoCodeSnip));
        if StrLen(NoCodeSnip) > 18 then
            NoSeriesErrorsImpl.Throw(StrSubstNo(NoOverFlowErr, NoCodeSnip, StrLen(NoCodeSnip)), NoSeriesCode, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
        Evaluate(Number, NoCodeSnip);
        exit(Number);
    end;

    local procedure DeleteSequence(SequenceName: Code[40])
    begin
        if SequenceName = '' then
            exit;

        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Delete(SequenceName);
    end;

    local procedure RecreateNoSeries(var NoSeriesLine: Record "No. Series Line"; SequenceNumber: BigInteger)
    begin
        DeleteSequence(NoSeriesLine."Sequence Name");
        CreateNewSequence(NoSeriesLine, SequenceNumber);
    end;

    local procedure RecreateNoSeriesWithLastUsedNo(var NoSeriesLine: Record "No. Series Line"; SequenceNumber: BigInteger)
    begin
        RecreateNoSeries(NoSeriesLine, SequenceNumber);
        if NumberSequence.Next(NoSeriesLine."Sequence Name") = 0 then; // The number we set was already used, hence we need to use it here as well.
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeValidateEvent', 'Starting No.', false, false)]
    local procedure OnValidateNoSeriesLine(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line"; CurrFieldNo: Integer)
    begin
        if Rec.Implementation <> "No. Series Implementation"::Sequence then
            exit;

        Rec."Starting Sequence No." := ExtractNoFromCode(Rec."Starting No.", Rec."Series Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeValidateEvent', 'Increment-by No.', false, false)]
    local procedure OnValidateIncrementByNo(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line"; CurrFieldNo: Integer)
    var
        LastNoUsed: Code[20];
    begin
        if Rec.Implementation <> "No. Series Implementation"::Sequence then
            exit;

        // Make sure to keep the last used No. if the No. Series is already in use
        LastNoUsed := GetLastNoUsed(Rec);
        if LastNoUsed <> '' then
            RecreateNoSeriesWithLastUsedNo(Rec, ExtractNoFromCode(LastNoUsed, Rec."Series Code"))
        else
            RecreateNoSeries(Rec, Rec."Starting Sequence No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeValidateEvent', 'Last No. Used', false, false)]
    local procedure OnValidateLastNoUsed(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line"; CurrFieldNo: Integer)
    var
        SequenceNumber: BigInteger;
    begin
        if Rec.Implementation <> "No. Series Implementation"::Sequence then
            exit;

        if Rec."Last No. Used" = '' then
            exit;

        SequenceNumber := ExtractNoFromCode(Rec."Last No. Used", Rec."Series Code");
        Rec."Last No. Used" := '';
        RecreateNoSeriesWithLastUsedNo(Rec, SequenceNumber);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeValidateEvent', 'Implementation', false, false)]
    local procedure OnValidateImplementation(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line"; CurrFieldNo: Integer)
    var
        NoSeries: Codeunit "No. Series";
        LastNoUsed: Code[20];
    begin
        if Rec.Implementation = xRec.Implementation then
            exit; // No change

        if Rec.Implementation = "No. Series Implementation"::Sequence then begin
            LastNoUsed := NoSeries.GetLastNoUsed(xRec);
            if LastNoUsed <> '' then
                RecreateNoSeriesWithLastUsedNo(Rec, ExtractNoFromCode(LastNoUsed, Rec."Series Code"))
            else
                RecreateNoSeries(Rec, ExtractNoFromCode(Rec."Starting No.", Rec."Series Code"));
            Rec."Last No. Used" := '';
        end else
            if xRec.Implementation = "No. Series Implementation"::Sequence then begin
                DeleteSequence(Rec."Sequence Name");
                Rec."Starting Sequence No." := 0;
                Rec."Sequence Name" := '';
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Sequence Name" <> '' then
            if NumberSequence.Exists(Rec."Sequence Name") then
                NumberSequence.Delete(Rec."Sequence Name");
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnModifyNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        EnsureTempCurrentSequenceNoIsReset(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnInsertNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        EnsureTempCurrentSequenceNoIsReset(Rec);
    end;

    local procedure EnsureTempCurrentSequenceNoIsReset(var NoSeriesLine: Record "No. Series Line")
    begin
        if NoSeriesLine."Temp Current Sequence No." = 0 then
            exit;

        if NoSeriesLine.Implementation = "No. Series Implementation"::Sequence then begin
            Session.LogMessage('0000MI6', UpdatingSequenceBasedOnTempValueTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesSequenceTxt);
            RecreateNoSeriesWithLastUsedNo(NoSeriesLine, NoSeriesLine."Temp Current Sequence No.");
        end;


        NoSeriesLine."Temp Current Sequence No." := 0; // Always reset the temporary sequence number!
    end;
}