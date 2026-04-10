namespace System.AI;

/// <summary>
/// Retrieves information about the usage of the Azure AI services.
/// </summary>
codeunit 2006 "Azure AI Usage"
{
    Access = Public;

    var
        AzureAIUsageImpl: Codeunit "Azure AI Usage Impl.";

    /// <summary>
    /// Increments the processing time for the provided Azure AI service with <paramref name="ProcessingTime"/>.
    /// </summary>
    /// <error>If <paramref name="ProcessingTime"/> is less or equal to zero.</error>
    /// <param name="Service">The Azure AI service for which to increment the processing time.</param>
    /// <param name="ProcessingTime">The value with which to increment the total processing time of the Azure AI service.</param>
    procedure IncrementTotalProcessingTime(Service: Enum "Azure AI Service"; ProcessingTime: Decimal)
    begin
        AzureAIUsageImpl.IncrementTotalProcessingTime(Service, ProcessingTime);
    end;

    /// <summary>
    /// Checks whether the total processing time of a provided Azure AI service has reached a certain limit.
    /// </summary>
    /// <param name="Service">The Azure AI service for which to check.</param>
    /// <param name="UsageLimit">The limit for which to check if it was reached.</param>
    /// <returns>True if the limit was reached; otherwise - false.</returns>
    procedure IsLimitReached(Service: Enum "Azure AI Service"; UsageLimit: Decimal): Boolean
    begin
        exit(AzureAIUsageImpl.IsLimitReached(Service, UsageLimit));
    end;

    /// <summary>
    /// Gets the total processing time of an Azure AI service.
    /// </summary>
    /// <param name="Service">The Azure AI service for which to retrieve the processing time.</param>
    /// <returns>The processing time that the service has used so far.</returns>
    procedure GetTotalProcessingTime(Service: Enum "Azure AI Service"): Decimal
    begin
        exit(AzureAIUsageImpl.GetTotalProcessingTime(Service));
    end;

    /// <summary>
    /// Gets the limit of an Azure AI service.
    /// </summary>
    /// <param name="Service">The Azure AI service for which to retrieve the resource limit.</param>
    /// <returns>The resource limit for the provided service.</returns>
    procedure GetResourceLimit(Service: Enum "Azure AI Service"): Decimal
    begin
        exit(AzureAIUsageImpl.GetResourceLimit(Service));
    end;

    /// <summary>
    /// Gets the type of limit period of an Azure AI service.
    /// </summary>
    /// <param name="Service">The Azure AI service for which to retrieve the limit period.</param>
    /// <returns>An option: Year,Month,Day,Hour.</returns>
    procedure GetLimitPeriod(Service: Enum "Azure AI Service"): Option
    begin
        exit(AzureAIUsageImpl.GetLimitPeriod(Service));
    end;

    /// <summary>
    /// Gets the last time the provided Azure AI service was updated.
    /// </summary>
    /// <param name="Service">The Azure AI service for which to retrieve the last time it was updated.</param>
    /// <returns>A datetime that notes the last time the Azure AI service was updated.</returns>
    procedure GetLastTimeUpdated(Service: Enum "Azure AI Service"): DateTime
    begin
        exit(AzureAIUsageImpl.GetLastTimeUpdated(Service));
    end;

    /// <summary>
    /// Sets a value that denotes whether the Image Analysis service was setup.
    /// </summary>
    /// <remarks>The function will be discontinued as it should not be part of the this API.</remarks>
    /// <param name="NewValue">The value to set.</param>
    procedure SetImageAnalysisIsSetup(NewValue: Boolean)
    begin
        AzureAIUsageImpl.SetImageAnalysisIsSetup(NewValue);
    end;
}