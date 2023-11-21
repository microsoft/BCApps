// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Provides an interface for interacting with number series.
/// This codeunit batches requests until SaveState() is called (The database is not updated in the meantime but locked instead). For more direct database interactions, see codeunit "No. Series".
/// </summary>
codeunit 308 "No. Series - Batch"
{
    Access = Public;

    var
        NoSeriesBatchImpl: Codeunit "No. Series - Batch Impl."; // Required to keep state

    procedure TestManual(NoSeriesCode: Code[20])
    var
        NoSeries: Codeunit "No. Series";
    begin
        NoSeries.TestManual(NoSeriesCode);
    end;

    procedure TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20])
    var
        NoSeries: Codeunit "No. Series";
    begin
        NoSeries.TestManual(NoSeriesCode, DocumentNo);
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode));
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode, UsageDate));
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeries));
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeries, UsageDate));
    end;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesLine, UsageDate));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode, UsageDate));
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeries));
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeries, UsageDate));
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; LastDateUsed: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesLine, LastDateUsed));
    end;

    procedure SimulateGetNextNo(NoSeriesCode: Code[20]; UsageDate: Date; PrevDocumentNo: Code[20]): Code[20]
    var
        NoSeriesBatchImplSim: Codeunit "No. Series - Batch Impl.";
    begin
        exit(NoSeriesBatchImplSim.SimulateGetNextNo(NoSeriesCode, UsageDate, PrevDocumentNo));
    end;

    procedure GetLastNoUsed(var NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetLastNoUsed(NoSeriesLine));
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