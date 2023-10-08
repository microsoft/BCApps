// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 309 "No. Series - Batch Impl."
{
    Access = Internal;

    var
        NoSeriesBatch: Interface "No. Series - Batch";

    procedure SetImpl(NoSeriesBatch2: Interface "No. Series - Batch")
    begin
        NoSeriesBatch := NoSeriesBatch2;
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(PeekNextNo(NoSeriesCode, WorkDate()))
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        exit(PeekNextNo(NoSeries, SeriesDate))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(PeekNextNo(NoSeries, WorkDate()))
    end;

    procedure PeekNextNo(NoSeries: Record "No. Series"; UsageDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.GetNoSeriesLine(NoSeriesLine, NoSeries, UsageDate);
        exit(PeekNextNo(NoSeriesLine, UsageDate))
    end;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        TempNoSeriesLine := NoSeriesLine;
        exit(NoSeriesBatch.PeekNextNo(TempNoSeriesLine, UsageDate));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        exit(GetNextNo(NoSeriesCode, WorkDate()))
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(NoSeriesCode);
        exit(GetNextNo(NoSeries, SeriesDate))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"): Code[20]
    begin
        exit(GetNextNo(NoSeries, WorkDate()))
    end;

    procedure GetNextNo(NoSeries: Record "No. Series"; SeriesDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesImpl: Codeunit "No. Series - Impl.";
    begin
        NoSeriesImpl.GetNoSeriesLine(NoSeriesLine, NoSeries, SeriesDate);
        exit(GetNextNo(NoSeriesLine, SeriesDate))
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    var
        TempNoSeriesLine: Record "No. Series Line" temporary;
    begin
        TempNoSeriesLine := NoSeriesLine;
        exit(NoSeriesBatch.GetNextNo(TempNoSeriesLine, UsageDate));
    end;

}