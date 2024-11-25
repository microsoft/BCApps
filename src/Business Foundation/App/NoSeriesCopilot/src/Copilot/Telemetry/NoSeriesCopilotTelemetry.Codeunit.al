// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;
using System.Telemetry;
using System.AI;

codeunit 389 "No. Series Copilot Telemetry"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        StartDateTime: DateTime;
        Durations: List of [Duration]; // Generate action can be triggered multiple times
        TotalSuggestedLines: List of [Integer]; // Generate action can be triggered multiple times
        TotalAppliedLines: Integer;

    procedure LogFeatureDiscovery()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        FeatureTelemetry.LogUptake('0000LF4', NoSeriesCopilotImpl.FeatureName(), Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000O9D', NoSeriesCopilotImpl.FeatureName(), Enum::"Feature Uptake Status"::"Set up");
    end;

    procedure LogApply(GeneratedNoSeries: Record "No. Series Generation Detail")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        TotalAppliedLines := GeneratedNoSeries.Count();
        if TotalAppliedLines = 0 then
            exit;

        FeatureTelemetry.LogUptake('0000O9E', NoSeriesCopilotImpl.FeatureName(), Enum::"Feature Uptake Status"::Used, GetFeatureUsedTelemetryCustomDimensions(GeneratedNoSeries));
    end;

    procedure LogCreateNewNumberSeriesToolUsage(TotalUserSpecifiedEntities: Integer; CustomPatternsUsed: Boolean; TotalBatches: Integer; TotalFoundTables: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesCopAddIntent: Codeunit "No. Series Cop. Add Intent";
    begin
        FeatureTelemetry.LogUsage('0000O9F', NoSeriesCopilotImpl.FeatureName(), NoSeriesCopAddIntent.GetName(), GetToolUsageTelemetryCustomDimensions(TotalUserSpecifiedEntities, CustomPatternsUsed, TotalBatches, TotalFoundTables));
    end;

    procedure LogModifyExistingNumberSeriesToolUsage(TotalUserSpecifiedEntities: Integer; CustomPatternsUsed: Boolean; TotalBatches: Integer; TotalFoundTables: Integer; UpdateForNextYear: Boolean)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesCopChangeIntent: Codeunit "No. Series Cop. Change Intent";
        NoSeriesCopNxtYrIntent: Codeunit "No. Series Cop. Nxt Yr. Intent";
    begin
        if UpdateForNextYear then
            FeatureTelemetry.LogUsage('0000O9G', NoSeriesCopilotImpl.FeatureName(), NoSeriesCopNxtYrIntent.GetName(), GetToolUsageTelemetryCustomDimensions(TotalUserSpecifiedEntities, CustomPatternsUsed, TotalBatches, TotalFoundTables))
        else
            FeatureTelemetry.LogUsage('0000O9H', NoSeriesCopilotImpl.FeatureName(), NoSeriesCopChangeIntent.GetName(), GetToolUsageTelemetryCustomDimensions(TotalUserSpecifiedEntities, CustomPatternsUsed, TotalBatches, TotalFoundTables));
    end;

    local procedure GetToolUsageTelemetryCustomDimensions(TotalUserSpecifiedEntities: Integer; CustomPatternsUsed: Boolean; TotalBatches: Integer; TotalFoundTables: Integer) CustomDimension: Dictionary of [Text, Text]
    begin
        CustomDimension.Add('TotalUserSpecifiedEntities', Format(TotalUserSpecifiedEntities));
        CustomDimension.Add('CustomPatternsUsed', Format(CustomPatternsUsed));
        CustomDimension.Add('TotalBatches', Format(TotalBatches));
        CustomDimension.Add('TotalFoundTables', Format(TotalFoundTables));
    end;

    procedure LogFeatureUsage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        // TotalAppliedLines will be zero in case none of the lines were inserted.
        // We don't want to log telemetry in case the user did not generate any suggestions.
        if Durations.Count() = 0 then
            exit;

        FeatureTelemetry.LogUsage('0000O9I', NoSeriesCopilotImpl.FeatureName(), 'Statistics', GetFeatureTelemetryCustomDimensions());
    end;

    procedure LogGenerationCompletion(TotalGeneratedLines: Integer; TotalExpectedLines: Integer; Attempt: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        TelemetryCD: Dictionary of [Text, Text];
    begin
        TelemetryCD.Add('TotalGeneratedLines', Format(TotalGeneratedLines));
        TelemetryCD.Add('TotalExpectedLines', Format(TotalExpectedLines));
        TelemetryCD.Add('Attempt', Format(Attempt));
        TelemetryCD.Add('Response time', ConvertListOfDurationToString(Durations));

        FeatureTelemetry.LogUsage('0000O9J', NoSeriesCopilotImpl.FeatureName(), 'Call Chat Completion API', TelemetryCD);
    end;


    local procedure GetFeatureTelemetryCustomDimensions() CustomDimension: Dictionary of [Text, Text]
    begin
        CustomDimension.Add('Durations', ConvertListOfDurationToString(Durations));
        CustomDimension.Add('TotalSuggestedLines', ConvertListOfIntegerToString(TotalSuggestedLines));
        CustomDimension.Add('TotalAppliedLines', Format(TotalAppliedLines));
    end;

    local procedure GetFeatureUsedTelemetryCustomDimensions(GeneratedNoSeries: Record "No. Series Generation Detail") CustomDimension: Dictionary of [Text, Text]
    var
        AppliedValues: Text;
        TotalApplied: Integer;
    begin
        GetAppliedAreas(GeneratedNoSeries, AppliedValues, TotalApplied);
        CustomDimension.Add('AppliedAreas', AppliedValues);
        CustomDimension.Add('TotalAppliedAreas', Format(TotalApplied));

        GetAppliedEntities(GeneratedNoSeries, AppliedValues, TotalApplied);
        CustomDimension.Add('AppliedEntities', AppliedValues);
        CustomDimension.Add('TotalAppliedEntities', Format(TotalApplied));
    end;

    local procedure GetAppliedAreas(GeneratedNoSeries: Record "No. Series Generation Detail"; var AppliedAreas: Text; var TotalAppliedAreas: Integer)
    var
        AppliedArea: List of [Text];
    begin
        Clear(AppliedArea);
        Clear(TotalAppliedAreas);
        if GeneratedNoSeries.FindSet() then
            repeat
                if not AppliedArea.Contains(GeneratedNoSeries."Setup Table Name") then
                    AppliedArea.Add(GeneratedNoSeries."Setup Table Name");
            until GeneratedNoSeries.Next() = 0;

        AppliedAreas := ConvertListOfTextToString(AppliedArea);
        TotalAppliedAreas := AppliedArea.Count();
    end;

    local procedure GetAppliedEntities(GeneratedNoSeries: Record "No. Series Generation Detail"; var AppliedEntities: Text; var TotalAppliedEntities: Integer)
    var
        AppliedEntity: List of [Text];
    begin
        Clear(AppliedEntity);
        Clear(TotalAppliedEntities);
        if GeneratedNoSeries.FindSet() then
            repeat
                if not AppliedEntity.Contains(GeneratedNoSeries."Setup Field Name") then
                    AppliedEntity.Add(GeneratedNoSeries."Setup Field Name");
            until GeneratedNoSeries.Next() = 0;

        AppliedEntities := ConvertListOfTextToString(AppliedEntity);
        TotalAppliedEntities := AppliedEntity.Count();
    end;

    local procedure ConvertListOfDurationToString(ListOfDuration: List of [Duration]) Result: Text
    var
        Dur: Duration;
        DurationAsBigInt: BigInteger;
    begin
        foreach Dur in ListOfDuration do begin
            DurationAsBigInt := Dur;
            Result += Format(DurationAsBigInt) + ', ';
        end;
        Result := Result.TrimEnd(', ');
    end;

    local procedure ConvertListOfIntegerToString(ListOfInteger: List of [Integer]) Result: Text
    var
        Int: Integer;
    begin
        foreach Int in ListOfInteger do
            Result += Format(Int) + ', ';
        Result := Result.TrimEnd(', ');
    end;

    local procedure ConvertListOfTextToString(ListOfText: List of [Text]) Result: Text
    var
        Text: Text;
    begin
        foreach Text in ListOfText do
            Result += Text + ', ';
        Result := Result.TrimEnd(', ');
    end;

    procedure LogToolNotInvoked(AOAIOperationResponse: Codeunit "AOAI Operation Response")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        TelemetryCD: Dictionary of [Text, Text];
    begin
        if Durations.Count() <> 0 then
            TelemetryCD.Add('Response time', ConvertListOfDurationToString(Durations));

        if AOAIOperationResponse.GetResult() = '' then
            FeatureTelemetry.LogError('0000O9B', NoSeriesCopilotImpl.FeatureName(), 'Call Chat Completion API', 'Completion answer is empty', '', TelemetryCD)
        else
            FeatureTelemetry.LogError('0000O9C', NoSeriesCopilotImpl.FeatureName(), 'Process function_call', 'function_call not found in the completion answer');
    end;

    procedure ResetDurationTracking()
    begin
        Clear(Durations);
    end;

    procedure StartDurationTracking()
    begin
        StartDateTime := CurrentDateTime();
    end;

    procedure StopDurationTracking() Duration: Duration
    begin
        Durations.Add(CurrentDateTime() - StartDateTime);
    end;

    procedure SaveTotalSuggestedLines(Total: Integer)
    begin
        TotalSuggestedLines.Add(Total);
    end;

}