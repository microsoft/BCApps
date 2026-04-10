namespace System.Telemetry;

/// <summary>
/// This codeunit collects metrics that will be emitted as telemetry when the session ends.
/// </summary>
codeunit 1352 "Telemetry Log Metrics"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = internal;

    var
        Metrics: List of [Text];
        NoOfMeasurements: Dictionary of [Text, Decimal];
        SumOfMeasurements: Dictionary of [Text, Decimal];
        MinMeasurements: Dictionary of [Text, Decimal];
        MaxMeasurements: Dictionary of [Text, Decimal];
        StartTimes: Dictionary of [Text, DateTime];

    /// <summary>
    /// Registers the start time of a process, labeled by MeasureName
    /// </summary>
    /// <param name="MeasureName">A name that indicates the scope of what is being measured, e.g. a function name or some process. NB! Must not contain user data!</param>
    [TryFunction]
    procedure StartMeasureTime(MeasureName: Text)
    begin
        if EnsureEntryExists(MeasureName, StartTimes) then
            StartTimes.Set(MeasureName, CurrentDateTime());
    end;

    /// <summary>
    /// Stores the elapsed time for MeasureName
    /// </summary>
    /// <param name="MeasureName">A name that indicates the scope of what is being measured, e.g. a function name or some process. NB! Must not contain user data!</param>
    [TryFunction]
    procedure StopMeasureTime(MeasureName: Text)
    begin
        if EnsureEntryExists(MeasureName, StartTimes) then
            if LogMeasure(MeasureName, CurrentDateTime() - StartTimes.Get(MeasureName)) then
                StartTimes.Set(MeasureName, CurrentDateTime());
    end;

    /// <summary>
    /// Stores the AddedValue for MeasureName
    /// </summary>
    /// <param name="MeasureName">A name that indicates the scope of what is being measured, e.g. a function name or some process. NB! Must not contain user data!</param>
    [TryFunction]
    procedure LogMeasure(MeasureName: Text; AddedValue: Decimal)
    var
        CurrentValue: Decimal;
    begin
        EnsureEntryExists(MeasureName, NoOfMeasurements, 0);
        EnsureEntryExists(MeasureName, SumOfMeasurements, 0);
        EnsureEntryExists(MeasureName, MinMeasurements, 999999999999999.9);
        EnsureEntryExists(MeasureName, MaxMeasurements, -999999999999999.9);

        CurrentValue := NoOfMeasurements.Get(MeasureName);
        NoOfMeasurements.Set(MeasureName, CurrentValue + 1);

        CurrentValue := SumOfMeasurements.Get(MeasureName);
        SumOfMeasurements.Set(MeasureName, CurrentValue + AddedValue);

        CurrentValue := MinMeasurements.Get(MeasureName);
        if AddedValue < CurrentValue then
            MinMeasurements.Set(MeasureName, AddedValue);

        CurrentValue := MaxMeasurements.Get(MeasureName);
        if AddedValue > CurrentValue then
            MaxMeasurements.Set(MeasureName, AddedValue);
    end;

    /// <summary>
    /// Sends collected metrics to telemetry and clears variables
    /// </summary>
    [TryFunction]
    internal procedure FlushMetricsToTelemetry()
    var
        CustomDimensions: Dictionary of [Text, Text];
        MetricName: Text;
        AverageTxt: Text;
        SkipTelemetry: Boolean;
    begin
        OnBeforeFlushMetricsToTelemetry(SkipTelemetry, SumOfMeasurements, NoOfMeasurements, MinMeasurements, MaxMeasurements);
        if SkipTelemetry then
            exit;

        foreach MetricName in Metrics do
            if NoOfMeasurements.Get(MetricName) > 0 then begin
                Clear(CustomDimensions);
                AverageTxt := Format(Round(SumOfMeasurements.Get(MetricName) / NoOfMeasurements.Get(MetricName), 0.001), 0, 9);
                CustomDimensions.Add('MetricName', MetricName);
                CustomDimensions.Add('NoOfMeasures', Format(NoOfMeasurements.Get(MetricName), 0, 9));
                CustomDimensions.Add('SumOfMeasurements', Format(SumOfMeasurements.Get(MetricName), 0, 9));
                CustomDimensions.Add('Average', AverageTxt);
                CustomDimensions.Add('MinValue', Format(MinMeasurements.Get(MetricName), 0, 9));
                CustomDimensions.Add('MaxValue', Format(MaxMeasurements.Get(MetricName), 0, 9));
                Session.LogMessage('0000REN', 'Metric: ' + MetricName + ' Average=' + AverageTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
            end;
        ClearAll();
    end;

    [TryFunction]
    local procedure EnsureEntryExists(MeasureName: Text; var Measurements: Dictionary of [Text, Decimal]; InitValue: Decimal)
    begin
        if not Metrics.Contains(MeasureName) then
            Metrics.Add(MeasureName);
        if not Measurements.ContainsKey(MeasureName) then
            Measurements.Add(MeasureName, InitValue);
    end;

    [TryFunction]
    local procedure EnsureEntryExists(MeasureName: Text; var Measurements: Dictionary of [Text, DateTime])
    begin
        if Metrics.Contains(MeasureName) then
            exit;
        Metrics.Add(MeasureName);
        if not Measurements.ContainsKey(MeasureName) then
            Measurements.Add(MeasureName, CurrentDateTime());
    end;

    /// <summary>
    /// This event is mainly intended for test to verify that we collect the expected metrics.
    /// </summary>
    /// <param name="SkipTelemetry">Set this variable to true to avoid sending telemetry</param>
    /// <param name="SumOfMeasurements">Dictionary of [Text, Decimal]</param>
    /// <param name="NoOfMeasurements">Dictionary of [Text, Decimal]</param>
    /// <param name="MinMeasurements">Dictionary of [Text, Decimal]</param>
    /// <param name="MaxMeasurements">Dictionary of [Text, Decimal]</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushMetricsToTelemetry(var SkipTelemetry: Boolean; SumOfMeasurements: Dictionary of [Text, Decimal]; NoOfMeasurements: Dictionary of [Text, Decimal]; MinMeasurements: Dictionary of [Text, Decimal]; MaxMeasurements: Dictionary of [Text, Decimal])
    begin
    end;
}