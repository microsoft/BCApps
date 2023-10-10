// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 308 "No. Series - Batch"
{
    Access = Public;

    var
        NoSeriesBatchImpl: Codeunit "No. Series - Batch Impl."; // needs to keep state

    procedure SetImplementation(NoSeriesBatch: Interface "No. Series - Batch")
    begin
        NoSeriesBatchImpl.SetImplementation(NoSeriesBatch);
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode))
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode, UsageDate))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeries))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeries, UsageDate))
    end;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesLine, UsageDate))
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode))
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode, UsageDate))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeries))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeries, UsageDate))
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; LastDateUsed: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesLine, LastDateUsed))
    end;

    /// <summary>
    /// Puts the codeunit in simulation mode which disables the ability to save state.
    /// </summary>
    procedure SetSimulationMode()
    begin
        NoSeriesBatchImpl.SetSimulationMode();
    end;

    procedure SaveState(TempNoSeriesLine: Record "No. Series Line" temporary);
    begin
        NoSeriesBatchImpl.SaveState(TempNoSeriesLine);
    end;

    procedure SaveState();
    begin
        NoSeriesBatchImpl.SaveState();
    end;
}