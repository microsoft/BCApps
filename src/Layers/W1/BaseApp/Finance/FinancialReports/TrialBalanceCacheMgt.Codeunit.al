// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

codeunit 1331 "Trial Balance Cache Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        RefreshFrequencyErr: Label 'Refresh intervals of less than 10 minutes are not supported.';

    [Scope('OnPrem')]
    procedure IsCacheStale(): Boolean
    var
        TrialBalanceCacheInfo: Record "Trial Balance Cache Info";
    begin
        if not TrialBalanceCacheInfo.Get() then
            exit(true);

        exit(CurrentDateTime - TrialBalanceCacheInfo."Last Modified Date/Time" >= GetCacheRefreshInterval());
    end;

    [Scope('OnPrem')]
    procedure LoadFromCache(var DescriptionsArr: array[9] of Text[100]; var ValuesArr: array[9, 2] of Decimal; var PeriodCaptionTxt: array[2] of Text): Boolean
    var
        TrialBalanceCache: Record "Trial Balance Cache";
        TrialBalanceCacheInfo: Record "Trial Balance Cache Info";
        Index: Integer;
        CaptionsSaved: Boolean;
    begin
        Clear(DescriptionsArr);
        Clear(ValuesArr);
        Clear(PeriodCaptionTxt);

        // If the number of trial balance cached is <> array length means that
        // something went wrong. Reset if thats the case
        if TrialBalanceCache.Count <> ArrayLen(DescriptionsArr) then begin
            TrialBalanceCache.DeleteAll();
            TrialBalanceCacheInfo.DeleteAll();
            exit(false);
        end;

        Index := 1;
        if TrialBalanceCache.FindSet() then
            repeat
                DescriptionsArr[Index] := TrialBalanceCache.Description;
                ValuesArr[Index, 1] := TrialBalanceCache."Period 1 Amount";
                ValuesArr[Index, 2] := TrialBalanceCache."Period 2 Amount";
                if not CaptionsSaved then begin
                    PeriodCaptionTxt[1] := TrialBalanceCache."Period 1 Caption";
                    PeriodCaptionTxt[2] := TrialBalanceCache."Period 2 Caption";
                    CaptionsSaved := true;
                end;
                Index := Index + 1;
            until TrialBalanceCache.Next() = 0;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SaveToCache(DescriptionsArr: array[9] of Text[100]; ValuesArr: array[9, 2] of Decimal; PeriodCaptionTxt: array[2] of Text)
    var
        TrialBalanceCacheInfo: Record "Trial Balance Cache Info";
        TrialBalanceCache: Record "Trial Balance Cache";
        Index: Integer;
        CaptionsSaved: Boolean;
        CacheFound: Boolean;
    begin
        TrialBalanceCache.LockTable();

        CacheFound := TrialBalanceCache.FindSet();

        if not IsCacheStale() then
            exit;

        Index := 1;
        if CacheFound then
            repeat
                TrialBalanceCache.Description := DescriptionsArr[Index];
                TrialBalanceCache."Period 1 Amount" := ValuesArr[Index, 1];
                TrialBalanceCache."Period 2 Amount" := ValuesArr[Index, 2];
                if not CaptionsSaved then begin
                    TrialBalanceCache."Period 1 Caption" := CopyStr(PeriodCaptionTxt[1], 1, MaxStrLen(TrialBalanceCache."Period 1 Caption"));
                    TrialBalanceCache."Period 2 Caption" := CopyStr(PeriodCaptionTxt[2], 1, MaxStrLen(TrialBalanceCache."Period 2 Caption"));
                    CaptionsSaved := true;
                end;
                TrialBalanceCache.Modify();
                Index := Index + 1;
            until TrialBalanceCache.Next() = 0
        else
            for Index := 1 to ArrayLen(DescriptionsArr) do begin
                TrialBalanceCache.Init();
                TrialBalanceCache."Entry No." := Index;
                TrialBalanceCache.Description := DescriptionsArr[Index];
                TrialBalanceCache."Period 1 Amount" := ValuesArr[Index, 1];
                TrialBalanceCache."Period 2 Amount" := ValuesArr[Index, 2];
                if not CaptionsSaved then begin
                    TrialBalanceCache."Period 1 Caption" := CopyStr(PeriodCaptionTxt[1], 1, MaxStrLen(TrialBalanceCache."Period 1 Caption"));
                    TrialBalanceCache."Period 2 Caption" := CopyStr(PeriodCaptionTxt[2], 1, MaxStrLen(TrialBalanceCache."Period 2 Caption"));
                    CaptionsSaved := true;
                end;
                TrialBalanceCache.Insert();
            end;

        if TrialBalanceCacheInfo.Get() then begin
            TrialBalanceCacheInfo."Last Modified Date/Time" := CurrentDateTime;
            TrialBalanceCacheInfo.Modify();
        end else begin
            TrialBalanceCacheInfo.Init();
            TrialBalanceCacheInfo."Last Modified Date/Time" := CurrentDateTime;
            TrialBalanceCacheInfo.Insert();
        end
    end;

    local procedure GetCacheRefreshInterval() Interval: Duration
    var
        MinInterval: Duration;
    begin
        MinInterval := 10 * 60 * 1000; // 10 minutes
        Interval := 60 * 60 * 1000; // 1 hr
        OnGetCacheRefreshInterval(Interval);
        if Interval < MinInterval then
            Error(RefreshFrequencyErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCacheRefreshInterval(var Interval: Duration)
    begin
    end;
}

