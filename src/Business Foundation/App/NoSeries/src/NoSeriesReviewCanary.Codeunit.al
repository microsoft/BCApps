// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 3987 "No. Series Review Canary"
{
    Access = Internal;

    procedure GetAverageLinesPerSeries(): Decimal
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SeriesCount: Integer;
        TotalLines: Integer;
    begin
        if NoSeries.FindSet(true) then
            repeat
                NoSeriesLine.SetRange("Series Code", NoSeries.Code);
                TotalLines += NoSeriesLine.Count();
                SeriesCount += 1;
            until NoSeries.Next() = 0;

        exit(TotalLines / SeriesCount);
    end;

    procedure GetNextLineNumber(SeriesCode: Code[20]): Integer
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        if NoSeriesLine.FindFirst() then
            exit(NoSeriesLine."Line No." + 10000);

        exit(10000);
    end;

    procedure HasLines(SeriesCode: Code[20]): Boolean
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        exit(NoSeriesLine.Count() > 0);
    end;
}
