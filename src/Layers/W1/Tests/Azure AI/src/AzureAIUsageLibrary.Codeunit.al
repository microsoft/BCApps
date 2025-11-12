/// <summary>
/// Common functions to initialize Azure AI Usage data.
/// </summary>
codeunit 135204 "Azure AI Usage Library"
{
    Access = Internal;

    procedure DeleteAll()
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        AzureAIUsage.DeleteAll();
    end;

    procedure InsertEntry(AzureAIService: Enum "Azure AI Service"; TotalProcessingTime: Decimal; ResourceLimit: Decimal; LimitPeriod: Option; LastUpdated: DateTime)
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        AzureAIUsage.Service := AzureAIService.AsInteger();
        AzureAIUsage."Total Resource Usage" := TotalProcessingTime;
        AzureAIUsage."Original Resource Limit" := ResourceLimit;
        AzureAIUsage."Limit Period" := LimitPeriod;
        AzureAIUsage."Last DateTime Updated" := LastUpdated;

        AzureAIUsage.Insert();
    end;
}