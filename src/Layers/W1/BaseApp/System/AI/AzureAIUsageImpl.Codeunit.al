namespace System.AI;

using System.Environment;

codeunit 2005 "Azure AI Usage Impl."
{
    Access = Internal;
    Permissions = TableData "Azure AI Usage" = rimd;

    var
        AzureMLCategoryTxt: Label 'AzureMLCategory', Locked = true;
        AzureMLLimitReachedTxt: Label 'The Azure ML usage limit has been reached', Locked = true;
        ProcessingTimeLessThanZeroErr: Label 'The available Azure Machine Learning processing time is less than or equal to zero.';
        CannotSetInfiniteAccessErr: Label 'Cannot set infinite access for user''s own service because the API key or API URI is empty.';
        ImageAnalysisIsSetup: Boolean;
        TestMode: Boolean;
        CurrentDateTimeMock: DateTime;

    internal procedure SetInfiniteImageAnalysisAccess(ImageAnalysisSetupRec: Record "Image Analysis Setup")
    var
        AzureAIUsageRec: Record "Azure AI Usage";
    begin
        if (ImageAnalysisSetupRec.GetApiKeyAsSecret().IsEmpty()) or (ImageAnalysisSetupRec."Api Uri" = '') then
            Error(CannotSetInfiniteAccessErr);

        SetImageAnalysisIsSetup(true);
        if (GetSingleInstance("Azure AI Service"::"Computer Vision", AzureAIUsageRec)) then begin
            AzureAIUsageRec."Limit Period" := AzureAIUsageRec."Limit Period"::Year;
            AzureAIUsageRec."Original Resource Limit" := 999;
            AzureAIUsageRec.Modify();
        end;
    end;

    procedure IncrementTotalProcessingTime(Service: Enum "Azure AI Service"; ProcessingTime: Decimal)
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        IncrementTotalProcessingTime(Service, ProcessingTime, AzureAIUsage);
    end;

    procedure IncrementTotalProcessingTime(Service: Enum "Azure AI Service"; ProcessingTime: Decimal; var AzureAIUsage: Record "Azure AI Usage")
    begin
        if ProcessingTime <= 0 then
            Error(ProcessingTimeLessThanZeroErr);

        if GetSingleInstance(Service, AzureAIUsage) then begin
            AzureAIUsage."Total Resource Usage" += ProcessingTime;
            AzureAIUsage."Last DateTime Updated" := GetCurrentDateTime();
            AzureAIUsage.Modify(true);
        end;
    end;

    procedure IsLimitReached(Service: Enum "Azure AI Service"; UsageLimit: Decimal): Boolean
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        if GetSingleInstance(Service, AzureAIUsage) then
            if GetTotalProcessingTime(Service) >= UsageLimit then begin
                Session.LogMessage('00001T1', AzureMLLimitReachedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AzureMLCategoryTxt);
                exit(true);
            end;
        exit(false);
    end;

    procedure GetTotalProcessingTime(Service: Enum "Azure AI Service"): Decimal
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        if GetSingleInstance(Service, AzureAIUsage) then
            exit(AzureAIUsage."Total Resource Usage");
    end;

    procedure GetLimitPeriod(Service: Enum "Azure AI Service"): Option
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        if GetSingleInstance(Service, AzureAIUsage) then
            exit(AzureAIUsage."Limit Period");
    end;

    procedure GetResourceLimit(Service: Enum "Azure AI Service"): Decimal
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        if GetSingleInstance(Service, AzureAIUsage) then
            exit(AzureAIUsage."Original Resource Limit");
    end;

    procedure GetLastTimeUpdated(Service: Enum "Azure AI Service"): DateTime
    var
        AzureAIUsage: Record "Azure AI Usage";
    begin
        if GetSingleInstance(Service, AzureAIUsage) then
            exit(AzureAIUsage."Last DateTime Updated");
    end;

    procedure GetSingleInstance(Service: Enum "Azure AI Service"; var AzureAIUsage: Record "Azure AI Usage"): Boolean
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        MLPredictionManagement: Codeunit "ML Prediction Management";
        EnvironmentInfo: Codeunit "Environment Information";
        ApiUri: Text;
        ApiKey: SecretText;
        ApiUri250: Text[250];
        ApiKey200: SecretText;
        LimitType: Option;
        LimitValue: Decimal;
        LimitValueInt: Integer;
        CallModify: Boolean;
        ResetTotalProcessingTime: Boolean;
    begin
        if (Service = Service::"Machine Learning") and (not EnvironmentInfo.IsSaaS()) then
            exit(false);

        AzureAIUsage.SetRange(Service, Service);
        if not AzureAIUsage.FindFirst() then begin
            AzureAIUsage.Init();
            AzureAIUsage.Service := Service.AsInteger();
            AzureAIUsage."Last DateTime Updated" := GetCurrentDateTime();
            AzureAIUsage.Insert();
        end;

        case Service of
            Service::"Computer Vision":
                begin
                    if AzureAIUsage."Original Resource Limit" = 0 then begin
                        AzureAIUsage."Original Resource Limit" := 999;
                        AzureAIUsage."Limit Period" := AzureAIUsage."Limit Period"::Year;
                    end;

                    if not ImageAnalysisSetup.Get() then begin
                        ImageAnalysisSetup.Init();
                        ImageAnalysisSetup.Insert();
                    end;

                    if (not ImageAnalysisIsSetup) and
                       ImageAnalysisSetup.GetApiKeyAsSecret().IsEmpty() and (ImageAnalysisSetup."Api Uri" = '') and
                       EnvironmentInfo.IsSaaS()
                    then
                        if ImageAnalysisManagement.GetImageAnalysisCredentials(ApiKey, ApiUri, LimitType, LimitValueInt) then begin
                            AzureAIUsage."Original Resource Limit" := LimitValueInt;
                            AzureAIUsage."Limit Period" := LimitType;
                            CallModify := true;
                        end;
                end;
            Service::"Machine Learning":
                if MLPredictionManagement.GetMachineLearningCredentials(ApiUri250, ApiKey200, LimitType, LimitValue) then begin
                    AzureAIUsage."Original Resource Limit" := LimitValue;
                    AzureAIUsage."Limit Period" := LimitType;
                    CallModify := true;
                end;
        end;

        case AzureAIUsage."Limit Period" of
            AzureAIUsage."Limit Period"::Year:
                ResetTotalProcessingTime := HasChangedYear(AzureAIUsage."Last DateTime Updated");
            AzureAIUsage."Limit Period"::Month:
                ResetTotalProcessingTime := HasChangedMonth(AzureAIUsage."Last DateTime Updated");
            AzureAIUsage."Limit Period"::Day:
                ResetTotalProcessingTime := HasChangedDay(AzureAIUsage."Last DateTime Updated");
            AzureAIUsage."Limit Period"::Hour:
                ResetTotalProcessingTime := HasChangedHour(AzureAIUsage."Last DateTime Updated");
        end;

        if ResetTotalProcessingTime then begin
            AzureAIUsage."Total Resource Usage" := 0;
            CallModify := true;
        end;

        if CallModify then
            AzureAIUsage.Modify();

        exit(true);
    end;

    procedure SetImageAnalysisIsSetup(NewValue: Boolean)
    begin
        ImageAnalysisIsSetup := NewValue;
    end;

    internal procedure HasChangedYear(PreviousDateTime: DateTime): Boolean
    begin
        exit(HasChangedPeriod(PreviousDateTime, 3));
    end;

    internal procedure HasChangedMonth(PreviousDateTime: DateTime): Boolean
    begin
        exit(HasChangedPeriod(PreviousDateTime, 2) or HasChangedYear(PreviousDateTime));
    end;

    internal procedure HasChangedDay(PreviousDateTime: DateTime): Boolean
    begin
        exit(HasChangedPeriod(PreviousDateTime, 1) or HasChangedMonth(PreviousDateTime));
    end;

    internal procedure HasChangedPeriod(PreviousDateTime: DateTime; What: Integer): Boolean
    begin
        exit(Date2DMY(DT2Date(GetCurrentDateTime()), What) <> Date2DMY(DT2Date(PreviousDateTime), What));
    end;

    internal procedure HasChangedHour(PreviousDateTime: DateTime): Boolean
    var
        PreviousRounded: DateTime;
        CurrentRounded: DateTime;
    begin
        PreviousRounded := RoundDateTime(PreviousDateTime, 1000 * 3600, '<');
        CurrentRounded := RoundDateTime(GetCurrentDateTime(), 1000 * 3600, '<');
        exit(CurrentRounded <> PreviousRounded);
    end;

    internal procedure GetCurrentDateTime() Result: DateTime
    begin
        Result := CurrentDateTime();

        if TestMode then
            Result := CurrentDateTimeMock;

        OnAfterGetCurrentDateTime(Result);
    end;

    procedure SetTestMode(NewCurrentDatetime: DateTime)
    begin
        TestMode := true;
        CurrentDateTimeMock := NewCurrentDatetime;
    end;

    [InternalEvent(false)]
    local procedure OnAfterGetCurrentDateTime(var CurrentDateTime: DateTime)
    begin
    end;
}