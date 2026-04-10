namespace System.AI;

codeunit 2002 "Azure AI Tracing"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        AzureAICategoryTxt: Label 'AL Azure AI', Locked = true;
        TraceImageAnalysisSuccessTagsTxt: Label 'Number of Image Analysis calls: %1;Limit: %2;Period type: %3;Execution time: %4 ms;Confidence: %5.', Locked = true;
        AnalysisStartTime: DateTime;
        TraceImageAnalysisSuccessTxt: Label 'Number of Image Analysis calls: %1;Limit: %2;Period type: %3;Execution time: %4 ms.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Image Analysis Management", 'OnBeforeImageAnalysis', '', false, false)]
    local procedure TraceImageAnalysisStart(var Sender: Codeunit "Image Analysis Management")
    begin
        AnalysisStartTime := CurrentDateTime;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Image Analysis Management", 'OnAfterImageAnalysis', '', false, false)]
    local procedure TraceImageAnalysisEnd(var Sender: Codeunit "Image Analysis Management"; ImageAnalysisResult: Codeunit "Image Analysis Result")
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
        LastError: Text;
        IsUsageLimitError: Boolean;
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
        Message: Text;
        AnalysisDuration: Integer;
        AnalysisTypes: List of [Enum "Image Analysis Type"];
        NoOfCalls: Integer;
    begin
        if Sender.GetLastError(LastError, IsUsageLimitError) then
            Session.LogMessage('000015X', LastError, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureAICategoryTxt)
        else begin
            Sender.GetLimitParams(LimitType, LimitValue);

            AnalysisDuration := CurrentDateTime - AnalysisStartTime;
            ImageAnalysisResult.GetLatestImageAnalysisTypes(AnalysisTypes);
            NoOfCalls := AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Computer Vision");
            if AnalysisTypes.Contains(Enum::"Image Analysis Type"::Tags) then
                Message := StrSubstNo(TraceImageAnalysisSuccessTagsTxt,
                    NoOfCalls, LimitValue, LimitType, AnalysisDuration,
                    ImageAnalysisResult.TagConfidence(1))
            else
                Message := StrSubstNo(TraceImageAnalysisSuccessTxt,
                    NoOfCalls, LimitValue, LimitType, AnalysisDuration);

            Session.LogMessage('000015Y', Message, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureAICategoryTxt);
        end;
    end;
}

