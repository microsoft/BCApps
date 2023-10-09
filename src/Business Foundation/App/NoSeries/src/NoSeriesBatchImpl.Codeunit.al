// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 309 "No. Series - Batch Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        NoSeriesBatch: Interface "No. Series - Batch";
        ImplementationSet: Boolean;
        SimulationMode: Boolean;

    procedure SetImplementation(NoSeriesBatch2: Interface "No. Series - Batch")
    begin
        if ImplementationSet then
            exit;

        NoSeriesBatch := NoSeriesBatch2;
        ImplementationSet := true;
    end;

    local procedure SetDefaultImplementation()
    var
        NoSeriesStatefulImpl: Codeunit "No. Series - Stateful Impl.";
    begin
        SetImplementation(NoSeriesStatefulImpl);
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(PeekNextNo(NoSeriesCode, WorkDate()))
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        exit(PeekNextNo(NoSeries, UsageDate))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(PeekNextNo(NoSeries, WorkDate()))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        GetNoSeriesLine(NoSeriesLine, NoSeries, UsageDate);
        exit(PeekNextNo(NoSeriesLine))
    end;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        TempNoSeriesLine := NoSeriesLine;
        SetDefaultImplementation();
        exit(NoSeriesBatch.PeekNextNo(TempNoSeriesLine));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(GetNextNo(NoSeriesCode, WorkDate()))
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        exit(GetNextNo(NoSeries, UsageDate))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(GetNextNo(NoSeries, WorkDate()))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        GetNoSeriesLine(NoSeriesLine, NoSeries, UsageDate);
        exit(GetNextNo(NoSeriesLine, UsageDate))
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; LastDateUsed: Date): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        TempNoSeriesLine := NoSeriesLine;
        SetDefaultImplementation();
        exit(NoSeriesBatch.GetNextNo(TempNoSeriesLine, LastDateUsed));
    end;

    procedure SetSimulationMode()
    begin
        SimulationMode := true;
    end;

    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary);
    begin
        if SimulationMode then
            exit;
        SetDefaultImplementation();
        NoSeriesBatch.SaveState(TempNoSeriesLine);
    end;

    procedure SaveState();
    begin
        if SimulationMode then
            exit;
        SetDefaultImplementation();
        NoSeriesBatch.SaveState();
    end;

    local procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"; UsageDate: Date)
    begin
        SetDefaultImplementation();
        NoSeriesBatch.GetNoSeriesLine(NoSeriesLine, NoSeries, UsageDate);
    end;
}