// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 309 "No. Series - Batch Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "No. Series Line" = rm;

    var
        TempGlobalNoSeriesLine: Record "No. Series Line" temporary;
        SimulationMode: Boolean;
        CannotSaveNonExistingNoSeriesErr: Label 'Cannot save No. Series Line that does not exist: %1, %2', Comment = '%1 = No. Series Code, %2 = Line No.';
        CannotSaveWhileSimulatingNumbersErr: Label 'No. Series state cannot be saved while simulating numbers.';
        NoSeriesBatchTxt: Label 'No. Series - Batch', Locked = true;
        SimulationModeStartedTxt: Label 'No. Series simulation mode started.', Locked = true;
        SavingSingleNoSeriesStateTxt: Label 'Saving single No. Series state.', Locked = true;
        SavingAllNoSeriesStatesTxt: Label 'Saving all No. Series states.', Locked = true;
        UpdatingNoSeriesLinesFromDbTxt: Label 'Updating No. Series lines from database.', Locked = true;

    procedure SetInitialState(TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        if IsSameNoSeriesLine(TempNoSeriesLine) then begin
            TempGlobalNoSeriesLine := TempNoSeriesLine;
            exit;
        end;

        if TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then
            exit;

        CopyNoSeriesLinesToTemp(TempNoSeriesLine."Series Code");
        if not TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then begin
            TempGlobalNoSeriesLine := TempNoSeriesLine;
            TempGlobalNoSeriesLine.Insert();
        end;
    end;

    local procedure IsSameNoSeriesLine(TempNoSeriesLine: Record "No. Series Line" temporary): Boolean
    begin
        exit((TempGlobalNoSeriesLine."Series Code" = TempNoSeriesLine."Series Code") and
             (TempGlobalNoSeriesLine."Line No." = TempNoSeriesLine."Line No."));
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(PeekNextNo(NoSeriesCode, WorkDate()));
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, UsageDate);
        exit(PeekNextNo(TempNoSeriesLine, UsageDate));
    end;

    procedure PeekNextNo(TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SyncGlobalLineWithProvidedLine(TempNoSeriesLine, UsageDate);
        exit(NoSeries.PeekNextNo(TempGlobalNoSeriesLine, UsageDate));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, UsageDate, HideErrorsAndWarnings);
        exit(GetNextNo(TempNoSeriesLine, UsageDate, HideErrorsAndWarnings));
    end;

    procedure GetNextNo(var TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeries: Codeunit "No. Series";
        NextNo: Code[20];
    begin
        SyncGlobalLineWithProvidedLine(TempNoSeriesLine, UsageDate);
        NextNo := NoSeries.GetNextNo(TempGlobalNoSeriesLine, UsageDate, HideErrorsAndWarnings);
        TempNoSeriesLine := TempGlobalNoSeriesLine;
        exit(NextNo);
    end;

    procedure SimulateGetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; PrevDocumentNo: Code[20]): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
        NoSeries: Codeunit "No. Series";
        NoSeriesStatelessImpl: Codeunit "No. Series - Stateless Impl.";
    begin
        if NoSeriesCode = '' then
            exit(IncStr(PrevDocumentNo));

        SetSimulationMode();

        GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, UsageDate);
        if NoSeries.MayProduceGaps(TempNoSeriesLine) then
            TempNoSeriesLine.Implementation := TempNoSeriesLine.Implementation::Normal;
        TempNoSeriesLine."Last No. Used" := PrevDocumentNo;

        if not NoSeriesStatelessImpl.EnsureLastNoUsedIsWithinValidRange(TempNoSeriesLine, true) then
            exit(IncStr(PrevDocumentNo));

        TempNoSeriesLine.Modify(false);
        exit(GetNextNo(TempNoSeriesLine, UsageDate, false));
    end;

    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
        NoSeries: Codeunit "No. Series";
    begin
        if not GetNoSeriesLine(TempNoSeriesLine, NoSeriesCode, WorkDate(), true) then
            exit('');
        exit(NoSeries.GetLastNoUsed(TempGlobalNoSeriesLine));
    end;

    procedure GetLastNoUsed(TempNoSeriesLine: Record "No. Series Line" temporary): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        SyncGlobalLineWithProvidedLine(TempNoSeriesLine, TempNoSeriesLine."Starting Date");
        exit(NoSeries.GetLastNoUsed(TempGlobalNoSeriesLine));
    end;

    procedure SetSimulationMode()
    begin
        if SimulationMode then
            exit;

        Session.LogMessage('0000MI2', SimulationModeStartedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesBatchTxt);
        SimulationMode := true;
    end;

    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary)
    begin
        if SimulationMode then
            Error(CannotSaveWhileSimulatingNumbersErr);
        if not TempGlobalNoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.") then
            Error(CannotSaveNonExistingNoSeriesErr, TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.");
        Session.LogMessage('0000MI3', SavingSingleNoSeriesStateTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesBatchTxt);
        UpdateNoSeriesLine(TempGlobalNoSeriesLine);
    end;

    procedure SaveState();
    begin
        if SimulationMode then
            Error(CannotSaveWhileSimulatingNumbersErr);
        Session.LogMessage('0000MI4', SavingAllNoSeriesStatesTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesBatchTxt);
        TempGlobalNoSeriesLine.Reset();
        if TempGlobalNoSeriesLine.FindSet() then
            repeat
                UpdateNoSeriesLine(TempGlobalNoSeriesLine);
            until TempGlobalNoSeriesLine.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'm')]
    local procedure UpdateNoSeriesLine(var TempNoSeriesLine: Record "No. Series Line" temporary)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        Session.LogMessage('0000MI5', UpdatingNoSeriesLinesFromDbTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NoSeriesBatchTxt);
        NoSeriesLine.Get(TempNoSeriesLine."Series Code", TempNoSeriesLine."Line No.");
        NoSeriesLine.TransferFields(TempNoSeriesLine);
        NoSeriesLine.Modify(true);
        TempNoSeriesLine := NoSeriesLine;
        TempNoSeriesLine.Modify();
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line" temporary; NoSeriesCode: Code[20]; UsageDate: Date)
    begin
        GetNoSeriesLine(NoSeriesLine, NoSeriesCode, UsageDate, false);
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line" temporary; NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean) LineFound: Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        LineFound := true; // Assume success
        if not NoSeries.GetNoSeriesLine(TempGlobalNoSeriesLine, NoSeriesCode, UsageDate, true) then begin
            CopyNoSeriesLinesToTemp(NoSeriesCode);

            if not NoSeries.GetNoSeriesLine(TempGlobalNoSeriesLine, NoSeriesCode, UsageDate, HideErrorsAndWarnings) then begin
                LineFound := false;
                ClearGlobalLine();
            end;
        end;

        NoSeriesLine.Copy(TempGlobalNoSeriesLine, true);
        exit(LineFound);
    end;

    local procedure CopyNoSeriesLinesToTemp(NoSeriesCode: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if not IsNoSeriesCopied(NoSeriesCode) then begin
            NoSeriesLine.SetRange("Series Code", NoSeriesCode);
            NoSeriesLine.SetRange(Open, true);
            if NoSeriesLine.FindSet() then
                repeat
                    TempGlobalNoSeriesLine := NoSeriesLine;
                    TempGlobalNoSeriesLine.Insert();
                until NoSeriesLine.Next() = 0;
        end;
        ClearGlobalLine();
    end;

    local procedure IsNoSeriesCopied(NoSeriesCode: Code[20]): Boolean
    begin
        TempGlobalNoSeriesLine.Reset();
        TempGlobalNoSeriesLine.SetRange("Series Code", NoSeriesCode);
        exit(not TempGlobalNoSeriesLine.IsEmpty());
    end;

    local procedure ClearGlobalLine()
    var
        TempBlankNoSeriesLine: Record "No. Series Line" temporary;
    begin
        TempGlobalNoSeriesLine := TempBlankNoSeriesLine; // Init + primary key
    end;

    local procedure SyncGlobalLineWithProvidedLine(var TempNoSeriesLine: Record "No. Series Line" temporary; UsageDate: Date)
    var
        NoSeries: Codeunit "No. Series";
    begin
        TempGlobalNoSeriesLine := TempNoSeriesLine;
        if not NoSeries.GetNoSeriesLine(TempGlobalNoSeriesLine, TempNoSeriesLine."Series Code", UsageDate, true) then begin
            ClearGlobalLine();
            SetInitialState(TempNoSeriesLine);
        end;
    end;
}