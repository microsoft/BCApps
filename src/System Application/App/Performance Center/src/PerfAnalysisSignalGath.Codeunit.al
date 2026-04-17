// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Gathers "signal" lines (hotspots, missing indexes, telemetry hints) into a Performance
/// Analysis. One codeunit, one method per source. Other apps can add signals through the
/// OnGatherCustomSignals event.
/// </summary>
codeunit 5485 "Perf. Analysis Signal Gath."
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Performance Analysis Line" = RIMD;

    /// <summary>
    /// Gathers all signals. Called by the Mgt. Impl before the AI analysis runs.
    /// </summary>
    procedure GatherAll(var Analysis: Record "Performance Analysis")
    begin
        AddProfilerHotspots(Analysis);
        AddMissingIndexes(Analysis);
        AddTelemetryHints(Analysis);
        OnGatherCustomSignals(Analysis);
    end;

    /// <summary>
    /// Emits top hot methods/objects from the profiles marked relevant on the analysis.
    /// </summary>
    procedure AddProfilerHotspots(var Analysis: Record "Performance Analysis")
    var
        Line: Record "Performance Analysis Line";
        ProfileLine: Record "Performance Analysis Line";
        HotspotCount: Integer;
        TitleLbl: Label 'Top hotspot in relevant profiles';
        DescLbl: Label 'The relevant profiles spend significant time in the captured call tree. Open the filtered profile list to drill in.';
    begin
        ProfileLine.SetRange("Analysis Id", Analysis."Id");
        ProfileLine.SetRange("Line Type", ProfileLine."Line Type"::Profile);
        ProfileLine.SetRange("Marked Relevant", true);
        HotspotCount := ProfileLine.Count();
        if HotspotCount = 0 then
            exit;

        InitSignalLine(Analysis, Line);
        Line."Signal Source" := Line."Signal Source"::Profiler;
        Line."Severity" := Line."Severity"::Info;
        Line."Title" := CopyStr(TitleLbl, 1, MaxStrLen(Line."Title"));
        Line."Description" := CopyStr(DescLbl, 1, MaxStrLen(Line."Description"));
        Line.Insert(true);
    end;

    /// <summary>
    /// Emits a missing-index hint. Platform support for reading missing-index data from AL
    /// varies; when unavailable this method is a no-op. Subscribe to OnProvideMissingIndexes
    /// to plug a platform- or telemetry-based source.
    /// </summary>
    procedure AddMissingIndexes(var Analysis: Record "Performance Analysis")
    var
        Line: Record "Performance Analysis Line";
        TempCustomLines: Record "Performance Analysis Line" temporary;
    begin
        OnProvideMissingIndexes(Analysis, TempCustomLines);
        if not TempCustomLines.FindSet() then
            exit;
        repeat
            InitSignalLine(Analysis, Line);
            Line."Signal Source" := Line."Signal Source"::MissingIndex;
            Line."Severity" := TempCustomLines."Severity";
            Line."Title" := TempCustomLines."Title";
            Line."Description" := TempCustomLines."Description";
            Line."Link" := TempCustomLines."Link";
            Line.Insert(true);
        until TempCustomLines.Next() = 0;
    end;

    /// <summary>
    /// Emits telemetry-derived hints (latency, lock wait, etc.). When there is no hook
    /// available, this is a no-op. Subscribe to OnProvideTelemetryHints to add hints from
    /// an Application Insights query.
    /// </summary>
    procedure AddTelemetryHints(var Analysis: Record "Performance Analysis")
    var
        Line: Record "Performance Analysis Line";
        TempCustomLines: Record "Performance Analysis Line" temporary;
    begin
        OnProvideTelemetryHints(Analysis, TempCustomLines);
        if not TempCustomLines.FindSet() then
            exit;
        repeat
            InitSignalLine(Analysis, Line);
            Line."Signal Source" := Line."Signal Source"::Telemetry;
            Line."Severity" := TempCustomLines."Severity";
            Line."Title" := TempCustomLines."Title";
            Line."Description" := TempCustomLines."Description";
            Line."Link" := TempCustomLines."Link";
            Line.Insert(true);
        until TempCustomLines.Next() = 0;
    end;

    local procedure InitSignalLine(var Analysis: Record "Performance Analysis"; var Line: Record "Performance Analysis Line")
    var
        Existing: Record "Performance Analysis Line";
    begin
        Existing.SetRange("Analysis Id", Analysis."Id");
        if Existing.FindLast() then
            Line."Line No." := Existing."Line No." + 10000
        else
            Line."Line No." := 10000;
        Line."Analysis Id" := Analysis."Id";
        Line."Line Type" := Line."Line Type"::Signal;
    end;

    /// <summary>
    /// Subscribers should populate MissingIndexes (temp) with any missing-index findings
    /// they want to attach to the analysis.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnProvideMissingIndexes(var Analysis: Record "Performance Analysis"; var MissingIndexes: Record "Performance Analysis Line" temporary)
    begin
    end;

    /// <summary>
    /// Subscribers should populate Hints (temp) with any telemetry-derived findings they
    /// want to attach to the analysis.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnProvideTelemetryHints(var Analysis: Record "Performance Analysis"; var Hints: Record "Performance Analysis Line" temporary)
    begin
    end;

    /// <summary>
    /// Raised after the built-in gatherer methods have run so extensions can write
    /// additional signal lines directly on the Performance Analysis Line table.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnGatherCustomSignals(var Analysis: Record "Performance Analysis")
    begin
    end;
}
