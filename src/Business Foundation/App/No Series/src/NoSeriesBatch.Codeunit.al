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

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode))
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesCode, SeriesDate))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeries))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; SeriesDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeries, SeriesDate))
    end;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(NoSeriesBatchImpl.PeekNextNo(NoSeriesLine))
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode))
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesCode, SeriesDate))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeries))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"; SeriesDate: Date): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeries, SeriesDate))
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(NoSeriesBatchImpl.GetNextNo(NoSeriesLine))
    end;
}