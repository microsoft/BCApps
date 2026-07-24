namespace Microsoft.SubscriptionBilling;

/// <summary>
/// Reusable progress dialog helper for long-running batch processes.
/// Shows elapsed time, progress (processed/total), estimated time remaining (ETA) and throughput.
/// All dialog interaction is guarded by GuiAllowed, so callers are safe to use it from background
/// Job Queue sessions without additional guards.
/// </summary>
codeunit 8035 "Progress Tracker"
{
    var
        Window: Dialog;
        StartTime: DateTime;
        LastUpdateTime: DateTime;
        TotalCount: Integer;
        LastDetail: Text;
        IsOpen: Boolean;
        UpdateIntervalMs: Integer;
        DialogTxt: Label '#1#################################\Processing  #2###############################\Progress    #3###############################\Elapsed     #4###############################\Est. remaining #5############################\Throughput  #6###############################', Comment = '%1 = activity caption, %2 = current item detail, %3 = progress (processed of total), %4 = elapsed time, %5 = estimated time remaining, %6 = throughput';
        ProgressLbl: Label '%1 of %2 (%3%)', Comment = '%1 = processed count, %2 = total count, %3 = percentage';
        PerMinuteLbl: Label '%1 / min', Comment = '%1 = number of items processed per minute';

    /// <summary>
    /// Opens the progress dialog (only when GuiAllowed) and starts the elapsed-time clock.
    /// </summary>
    /// <param name="ActivityText">Caption describing the running activity.</param>
    /// <param name="NewTotalCount">Total number of items to process; used for ETA and percentage. Pass 0 if unknown.</param>
    procedure StartActivity(ActivityText: Text; NewTotalCount: Integer)
    begin
        StartTime := CurrentDateTime();
        LastUpdateTime := StartTime;
        TotalCount := NewTotalCount;
        LastDetail := '';
        UpdateIntervalMs := 1000; // Redraw the dialog at most once per second.
        if not GuiAllowed() then
            exit;
        Window.Open(DialogTxt);
        Window.Update(1, ActivityText);
        IsOpen := true;
    end;

    /// <summary>
    /// Updates the dialog. Redraws are throttled (at most once per second, plus whenever the detail
    /// text changes or the last item is reached) to avoid excessive flicker.
    /// </summary>
    /// <param name="ProcessedCount">Number of items processed so far.</param>
    /// <param name="DetailText">Detail about the current item (e.g. contract no., partner, step).</param>
    procedure UpdateProgress(ProcessedCount: Integer; DetailText: Text)
    begin
        if not IsOpen then
            exit;
        if not ShouldUpdate(ProcessedCount, DetailText) then
            exit;
        LastDetail := DetailText;
        LastUpdateTime := CurrentDateTime();
        Window.Update(2, DetailText);
        Window.Update(3, FormatProgress(ProcessedCount));
        Window.Update(4, FormatDurationText(CurrentDateTime() - StartTime));
        Window.Update(5, FormatEta(ProcessedCount));
        Window.Update(6, FormatThroughput(ProcessedCount));
    end;

    /// <summary>
    /// Closes the progress dialog if it is open.
    /// </summary>
    procedure Finish()
    begin
        if IsOpen then
            Window.Close();
        IsOpen := false;
    end;

    local procedure ShouldUpdate(ProcessedCount: Integer; DetailText: Text): Boolean
    begin
        if DetailText <> LastDetail then
            exit(true);
        if (TotalCount > 0) and (ProcessedCount >= TotalCount) then
            exit(true);
        exit((CurrentDateTime() - LastUpdateTime) >= UpdateIntervalMs);
    end;

    local procedure FormatProgress(ProcessedCount: Integer): Text
    var
        Percentage: Integer;
    begin
        if TotalCount <= 0 then
            exit(Format(ProcessedCount));
        Percentage := Round(ProcessedCount / TotalCount * 100, 1);
        exit(StrSubstNo(ProgressLbl, ProcessedCount, TotalCount, Percentage));
    end;

    local procedure FormatEta(ProcessedCount: Integer): Text
    var
        Elapsed: Duration;
    begin
        if (ProcessedCount <= 0) or (TotalCount <= 0) or (ProcessedCount >= TotalCount) then
            exit('-');
        Elapsed := CurrentDateTime() - StartTime;
        exit(FormatDurationText(Round(Elapsed / ProcessedCount * (TotalCount - ProcessedCount), 1)));
    end;

    local procedure FormatThroughput(ProcessedCount: Integer): Text
    var
        Elapsed: Duration;
        PerMinute: Decimal;
    begin
        Elapsed := CurrentDateTime() - StartTime;
        if Elapsed <= 0 then
            exit('-');
        PerMinute := Round(ProcessedCount / (Elapsed / 60000), 0.1);
        exit(StrSubstNo(PerMinuteLbl, Format(PerMinute, 0, '<Precision,1:1><Standard Format,0>')));
    end;

    local procedure FormatDurationText(DurationValue: Duration): Text
    var
        TotalSeconds: Integer;
        Days: Integer;
        Hours: Integer;
        Minutes: Integer;
        Seconds: Integer;
        HH: Text;
        MM: Text;
        SS: Text;
    begin
        if DurationValue <= 0 then
            exit('0s');
        if DurationValue < 1000 then
            exit('<1s');
        TotalSeconds := Round(DurationValue / 1000, 1);
        Days := TotalSeconds div 86400;
        TotalSeconds := TotalSeconds mod 86400;
        Hours := TotalSeconds div 3600;
        TotalSeconds := TotalSeconds mod 3600;
        Minutes := TotalSeconds div 60;
        Seconds := TotalSeconds mod 60;
        HH := PadStr('', 2 - StrLen(Format(Hours)), '0') + Format(Hours);
        MM := PadStr('', 2 - StrLen(Format(Minutes)), '0') + Format(Minutes);
        SS := PadStr('', 2 - StrLen(Format(Seconds)), '0') + Format(Seconds);
        if Days > 0 then
            exit(Format(Days) + 'd ' + HH + ':' + MM + ':' + SS);
        exit(HH + ':' + MM + ':' + SS);
    end;
}
