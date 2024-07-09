// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 306 "No. Series - Stateless Impl." implements "No. Series - Single"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "No. Series" = r,
        tabledata "No. Series Line" = rimd;

    var
        CannotAssignNumbersGreaterThanErr: Label 'You cannot assign numbers greater than %1 from the number series %2. No. assigned: %3', Comment = '%1=Last No.,%2=No. Series Code, %3=the new no.';
        WarnNoSeriesRunningOutMsg: Label 'The No. Series %1 is soon running out. The current number is %2 and the last allowed number of the sequence is %3.', Comment = '%1=No. Series code,%2=Current No.,%3=Last No. of the sequence';
        NoSeriesTxt: Label 'No. Series', Locked = true;
        NoSeriesOutOfRangeTxt: Label 'The last number used is outside range.', Locked = true;
        NoSeriesWarningTxt: Label 'The No. Series is running out of numbers.', Locked = true;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(GetNextNoInternal(NoSeriesLine, false, UsageDate, false));
    end;

    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    begin
        if not NoSeriesLine.IsTemporary() then begin
            NoSeriesLine.ReadIsolation(IsolationLevel::UpdLock);
            NoSeriesLine.Find();
        end;
        exit(GetNextNoInternal(NoSeriesLine, true, UsageDate, HideErrorsAndWarnings));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'm')]
    local procedure GetNextNoInternal(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesSetup: Codeunit "No. Series - Setup";
    begin
        if NoSeriesLine."Last No. Used" = '' then begin
            if HideErrorsAndWarnings and (NoSeriesLine."Starting No." = '') then
                exit('');
            NoSeriesLine.TestField("Starting No.");
            NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
        end else
            if NoSeriesLine."Increment-by No." <= 1 then
                NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used")
            else
                NoSeriesLine."Last No. Used" := NoSeriesSetup.IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.");

        if not EnsureLastNoUsedIsWithinValidRange(NoSeriesLine, HideErrorsAndWarnings) then
            exit('');

        if ModifySeries then begin
            NoSeriesLine."Last Date Used" := UsageDate;
            NoSeriesLine.Validate(Open);
            NoSeriesLine.Modify();
        end;

        exit(NoSeriesLine."Last No. Used");
    end;

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(NoSeriesLine."Last No. Used");
    end;

    procedure MayProduceGaps(): Boolean
    begin
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnBeforeValidateEvent', 'Implementation', false, false)]
    local procedure OnValidateImplementation(var Rec: Record "No. Series Line"; var xRec: Record "No. Series Line"; CurrFieldNo: Integer)
    var
        NoSeries: Codeunit "No. Series";
    begin
        if Rec.Implementation = xRec.Implementation then
            exit; // No change

        if Rec.Implementation <> "No. Series Implementation"::Normal then
            exit;

        Rec."Last No. Used" := NoSeries.GetLastNoUsed(xRec);
    end;

    procedure EnsureLastNoUsedIsWithinValidRange(NoSeriesLine: Record "No. Series Line"; NoErrorsOrWarnings: Boolean): Boolean
    var
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
    begin
        if not NoIsWithinValidRange(NoSeriesLine."Last No. Used", NoSeriesLine."Starting No.", NoSeriesLine."Ending No.") then begin
            Session.LogMessage('0000MI7', NoSeriesOutOfRangeTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesTxt);
            if NoErrorsOrWarnings then
                exit(false);
            NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignNumbersGreaterThanErr, NoSeriesLine."Ending No.", NoSeriesLine."Series Code", NoSeriesLine."Last No. Used"), NoSeriesLine, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
        end;

        if (NoSeriesLine."Ending No." <> '') and (NoSeriesLine."Warning No." <> '') and (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.") then begin
            Session.LogMessage('0000MI8', NoSeriesWarningTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesTxt);
            if NoErrorsOrWarnings then
                exit(false);
            if GuiAllowed() then
                Message(WarnNoSeriesRunningOutMsg, NoSeriesLine."Series Code", NoSeriesLine."Last No. Used", NoSeriesLine."Ending No.");
        end;
        exit(true);
    end;

    local procedure NoIsWithinValidRange(CurrentNo: Code[20]; StartingNo: Code[20]; EndingNo: Code[20]): Boolean
    begin
        if CurrentNo = '' then
            exit(false);
        if (StartingNo <> '') and (CurrentNo < StartingNo) then
            exit(false);
        if (EndingNo <> '') and (CurrentNo > EndingNo) then
            exit(false);

        if DelChr(StartingNo, '=', '0123456789') <> (DelChr(CurrentNo, '=', '0123456789')) then
            exit(false);

        if (StartingNo <> '') and (StrLen(CurrentNo) < StrLen(StartingNo)) then
            exit(false);
        if (EndingNo <> '') and (StrLen(CurrentNo) > StrLen(EndingNo)) then
            exit(false);

        exit(true)
    end;
}