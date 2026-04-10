codeunit 132538 "Metrics Collection Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        ExpectedMeasureName: Text;
        ExpectedNoOfMeasures: Integer;
        ExpectedCount: Integer;
        ExpectedTotal: Decimal;
        ExpectedAverage: Decimal;
        ExpectedMin: Decimal;
        ExpectedMax: Decimal;
        ExpectedDelta: Decimal;

    [Test]
    procedure VerifyEmptyMetrics()
    var
        TelemetryLogMetrics: codeunit "Telemetry Log Metrics";
    begin
        Init();
        BindSubscription(this);
        TelemetryLogMetrics.FlushMetricsToTelemetry();  // should be empty
        UnBindSubscription(this);
    end;

    [Test]
    procedure SimpleMetrics()
    var
        TelemetryLogMetrics: codeunit "Telemetry Log Metrics";
    begin
        Init();

        ExpectedMeasureName := 'Test';
        TelemetryLogMetrics.LogMeasure(ExpectedMeasureName, 1);
        TelemetryLogMetrics.LogMeasure(ExpectedMeasureName, 5);
        ExpectedNoOfMeasures := 1;
        ExpectedCount := 2;
        ExpectedTotal := 6;
        ExpectedAverage := 3;
        ExpectedMin := 1;
        ExpectedMax := 5;

        BindSubscription(this);
        TelemetryLogMetrics.FlushMetricsToTelemetry();  // should be empty
        UnBindSubscription(this);
    end;

    [Test]
    procedure TimerMetrics()
    var
        TelemetryLogMetrics: Codeunit "Telemetry Log Metrics";
    begin
        Init();

        ExpectedMeasureName := 'Timer';
        TelemetryLogMetrics.StartMeasureTime(ExpectedMeasureName);
        Sleep(1000);
        TelemetryLogMetrics.StopMeasureTime(ExpectedMeasureName);

        ExpectedNoOfMeasures := 1;
        ExpectedCount := 1;
        ExpectedTotal := 1000;
        ExpectedAverage := 1000;
        ExpectedMin := 1000;
        ExpectedMax := 1000;
        ExpectedDelta := 500; // ms. Sleep is not precise and there are other factors involved.

        BindSubscription(this);
        TelemetryLogMetrics.FlushMetricsToTelemetry();  // should be empty
        UnBindSubscription(this);
    end;

    local procedure Init()
    var
        TelemetryLogMetrics: codeunit "Telemetry Log Metrics";
    begin
        Clear(TelemetryLogMetrics);
        ExpectedNoOfMeasures := 0;
        ExpectedCount := 0;
        ExpectedTotal := 0;
        ExpectedAverage := 0;
        ExpectedMin := 0;
        ExpectedMax := 0;
        ExpectedDelta := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Log Metrics", OnBeforeFlushMetricsToTelemetry, '', false, false)]
    local procedure OnBeforeFlushMetricsToTelemetry(var SkipTelemetry: Boolean; SumOfMeasurements: Dictionary of [Text, Decimal]; NoOfMeasurements: Dictionary of [Text, Decimal]; MinMeasurements: Dictionary of [Text, Decimal]; MaxMeasurements: Dictionary of [Text, Decimal])
    begin
        Assert.AreEqual(ExpectedNoOfMeasures, NoOfMeasurements.Count(), 'Unexpected number of NoOfMeasurements dictionary.');
        Assert.AreEqual(ExpectedNoOfMeasures, SumOfMeasurements.Count(), 'Unexpected number of SumOfMeasurements dictionary.');
        Assert.AreEqual(ExpectedNoOfMeasures, MaxMeasurements.Count(), 'Unexpected number of MaxMeasurements dictionary.');
        Assert.AreEqual(ExpectedNoOfMeasures, MinMeasurements.Count(), 'Unexpected number of MinMeasurements dictionary.');
        if ExpectedCount = 0 then
            exit;
        Assert.AreNotEqual('', ExpectedMeasureName, 'Ooops - programming error in test code!');

        Assert.AreEqual(ExpectedCount, NoOfMeasurements.Get(ExpectedMeasureName), 'Unexpected number of NoOfMeasurements dictionary.');
        Assert.AreNearlyEqual(ExpectedTotal, SumOfMeasurements.Get(ExpectedMeasureName), ExpectedDelta, 'Unexpected SumOfMeasurements.');
        Assert.AreNearlyEqual(ExpectedAverage, Round(SumOfMeasurements.Get(ExpectedMeasureName) / NoOfMeasurements.Get(ExpectedMeasureName), 0.001), ExpectedDelta, 'Unexpected Average.');
        Assert.AreNearlyEqual(ExpectedMin, MinMeasurements.Get(ExpectedMeasureName), ExpectedDelta, 'Unexpected MinMeasurements.');
        Assert.AreNearlyEqual(ExpectedMax, MaxMeasurements.Get(ExpectedMeasureName), ExpectedDelta, 'Unexpected MaxMeasurements.');

        SkipTelemetry := false; // clear buffers before next run
    end;
}