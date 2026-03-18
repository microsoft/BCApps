namespace System.AI;

using System;
using System.Azure.KeyVault;
using System.Environment;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 2020 "Image Analysis Management"
{
    var
        [NonDebuggable]
        "Key": SecretText;
        Uri: Text;
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
        ImagePath: Text;
        SetMediaErr: Label 'There was a problem uploading the image file. Please try again.';
        NoApiKeyUriErr: Label 'To analyze images, you must provide an API key and an API URI for Computer Vision.';
        NoImageErr: Label 'You haven''t uploaded an image to analyze.';
        LastError: Text;
        IsLastErrorUsageLimitError: Boolean;
        GenericErrorErr: Label 'There was an error in contacting the Computer Vision API. Please try again or contact an administrator.';
        IsInitialized: Boolean;
        ChangingLimitAfterInitErr: Label 'You cannot change the limit setting after initialization.';
        ImageAnalysisSecretTxt: Label 'cognitive-vision-params', Locked = true;
        MissingImageAnalysisSecretErr: Label 'There is a missing configuration value on our end. Try again later.';
        ImageAnalysisProvider: Interface "Image Analysis Provider";
        ImageAnalysisTelemetryCategoryTxt: Label 'AL Image Analysis', Locked = true;
        StartingImageAnalysisTelemetryMsg: Label 'Starting image analysis. Key empty: %1, Url empty: %2, Path empty: %3, Limit reached: %4.', Locked = true;

    [NonDebuggable]
    procedure Initialize()
    begin
        Initialize(Enum::"Image Analysis Provider"::"v1.0");
    end;

    [NonDebuggable]
    procedure Initialize(InputImageAnalysisProvider: Enum "Image Analysis Provider")
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        EnvironmentInformation: Codeunit "Environment Information";
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
    begin
        if IsInitialized then
            exit;
        if not ImageAnalysisSetup.Get() then begin
            ImageAnalysisSetup.Init();
            ImageAnalysisSetup.Insert();
        end;

        if Key.IsEmpty() or (Uri = '') then begin
            Key := ImageAnalysisSetup.GetApiKeyAsSecret();
            Uri := ImageAnalysisSetup."Api Uri";
            AzureAIUsage.SetImageAnalysisIsSetup(false);
        end else
            AzureAIUsage.SetImageAnalysisIsSetup(true);

        if LimitValue = 0 then begin
            AzureAIService := AzureAIService::"Computer Vision";
            LimitType := AzureAIUsage.GetLimitPeriod(AzureAIService);
            LimitValue := AzureAIUsage.GetResourceLimit(AzureAIService);
        end;

        if LimitValue = 0 then
            SetLimitInYears(999);

        if (Key.IsEmpty() or (Uri = '')) and EnvironmentInformation.IsSaaS() then
            GetImageAnalysisCredentials(Key, Uri, LimitType, LimitValue);

        ImageAnalysisProvider := InputImageAnalysisProvider;

        IsInitialized := true;
    end;

    procedure SetMedia(MediaId: Guid)
    var
        TenantMedia: Record "Tenant Media";
        FileManagement: Codeunit "File Management";
    begin
        if TenantMedia.Get(MediaId) then begin
            ImageAnalysisProvider.IsMediaSupported(MediaId);
            ImagePath := FileManagement.ServerTempFileName('');
            TenantMedia.CalcFields(Content);
            TenantMedia.Content.Export(ImagePath);
        end else
            Error(SetMediaErr);
    end;

    procedure SetImagePath(Path: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.IsAllowedPath(Path, false);
        ImagePath := Path;
    end;

    procedure SetBlob(TempBlob: Codeunit "Temp Blob")
    var
        FileManagement: Codeunit "File Management";
    begin
        ImagePath := FileManagement.ServerTempFileName('');
        FileManagement.BLOBExportToServerFile(TempBlob, ImagePath);
    end;


    procedure SetUriAndKey(UriValue: Text; KeyValue: SecretText)
    begin
        Uri := UriValue;
        Key := KeyValue;
    end;

    procedure SetLimitInYears(Value: Integer)
    begin
        if IsInitialized then
            Error(ChangingLimitAfterInitErr);
        if Value <= 0 then
            exit;
        LimitType := LimitType::Year;
        LimitValue := Value;
    end;

    procedure SetLimitInMonths(Value: Integer)
    begin
        if IsInitialized then
            Error(ChangingLimitAfterInitErr);
        if Value <= 0 then
            exit;
        LimitType := LimitType::Month;
        LimitValue := Value;
    end;

    procedure SetLimitInDays(Value: Integer)
    begin
        if IsInitialized then
            Error(ChangingLimitAfterInitErr);
        if Value <= 0 then
            exit;
        LimitType := LimitType::Day;
        LimitValue := Value;
    end;

    procedure SetLimitInHours(Value: Integer)
    begin
        if IsInitialized then
            Error(ChangingLimitAfterInitErr);
        if Value <= 0 then
            exit;
        LimitType := LimitType::Hour;
        LimitValue := Value;
    end;

    procedure AnalyzeTags(var ImageAnalysisResult: Codeunit "Image Analysis Result"): Boolean
    begin
        exit(Analyze(ImageAnalysisResult, Enum::"Image Analysis Type"::Tags));
    end;

    procedure AnalyzeColors(var ImageAnalysisResult: Codeunit "Image Analysis Result"): Boolean
    begin
        exit(Analyze(ImageAnalysisResult, Enum::"Image Analysis Type"::Color));
    end;

    procedure AnalyzeFaces(var ImageAnalysisResult: Codeunit "Image Analysis Result"): Boolean
    begin
        exit(Analyze(ImageAnalysisResult, Enum::"Image Analysis Type"::Faces));
    end;

    procedure Analyze(var ImageAnalysisResult: Codeunit "Image Analysis Result"; AnalysisType: Enum "Image Analysis Type"): Boolean
    var
        AnalysisTypes: List of [Enum "Image Analysis Type"];
    begin
        AnalysisTypes.Add(AnalysisType);
        exit(Analyze(ImageAnalysisResult, AnalysisTypes));
    end;

    procedure Analyze(var ImageAnalysisResult: Codeunit "Image Analysis Result"; AnalysisTypes: List of [Enum "Image Analysis Type"]): Boolean
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ResultJSONManagement: Codeunit "JSON Management";
        UsageLimitError: Text;
    begin
        Initialize();
        SetLastError('', false);
        OnBeforeImageAnalysis();

        Session.LogMessage('0000JYW',
            StrSubstNo(StartingImageAnalysisTelemetryMsg, Key.IsEmpty(), Uri = '', ImagePath = '', ImageAnalysisSetup.IsUsageLimitReached(UsageLimitError, LimitValue, LimitType)),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ImageAnalysisTelemetryCategoryTxt);

        if (Key.IsEmpty()) or (Uri = '') then
            SetLastError(NoApiKeyUriErr, false)
        else
            if ImagePath = '' then
                SetLastError(NoImageErr, false)
            else
                if ImageAnalysisSetup.IsUsageLimitReached(UsageLimitError, LimitValue, LimitType) then
                    SetLastError(UsageLimitError, true)
                else
                    if ImageAnalysisProvider.InvokeAnalysis(ResultJSONManagement, Uri, Key, ImagePath, AnalysisTypes, GlobalLanguage()) then
                        ImageAnalysisSetup.Increment()
                    else
                        if ImageAnalysisProvider.GetLastError() <> '' then
                            SetLastError(ImageAnalysisProvider.GetLastError(), false)
                        else
                            SetLastError(GenericErrorErr, false);

        ImageAnalysisResult.SetResult(ResultJSONManagement, AnalysisTypes);
        OnAfterImageAnalysis(ImageAnalysisResult);

        exit(not HasError());
    end;

    [Scope('OnPrem')]
    procedure SetHttpMessageHandler(NewHttpMessageHandler: DotNet HttpMessageHandler)
    var
        ImageAnalysisWrapperV10: Codeunit "Image Analysis Wrapper V1.0";
    begin
        // This should only be used for testing.
        ImageAnalysisWrapperV10.SetHttpMessageHandler(NewHttpMessageHandler);
        ImageAnalysisProvider := ImageAnalysisWrapperV10;
    end;

    procedure GetLastError(var Message: Text; var IsUsageLimitError: Boolean): Boolean
    begin
        Message := LastError;
        IsUsageLimitError := IsLastErrorUsageLimitError;
        exit(HasError());
    end;

    local procedure SetLastError(ErrorMsg: Text; IsUsageLimitError: Boolean)
    begin
        LastError := ErrorMsg;
        IsLastErrorUsageLimitError := IsUsageLimitError;
    end;

    procedure GetTelemetryCategory(): Text
    begin
        exit(ImageAnalysisTelemetryCategoryTxt);
    end;

    procedure GetNoImageErr(): Text
    begin
        exit(NoImageErr);
    end;

    procedure HasError(): Boolean
    begin
        exit(LastError <> '');
    end;

    procedure GetLimitParams(var LimitTypeOut: Option Year,Month,Day,Hour; var LimitValueOut: Integer)
    begin
        LimitTypeOut := LimitType;
        LimitValueOut := LimitValue;
    end;

    procedure IsCurrentUserLanguageSupported(AnalysisTypes: List of [Enum "Image Analysis Type"]): Boolean
    begin
        exit(ImageAnalysisProvider.IsLanguageSupported(AnalysisTypes, GlobalLanguage()));
    end;


    [NonDebuggable]
    local procedure ExtractParameterValue(Parameters: JsonObject; ParameterName: Text; IsMandatory: Boolean): Text
    var
        ParameterValue: JsonToken;
        ParameterValueText: Text;
    begin
        if not Parameters.Get(ParameterName, ParameterValue) then begin
            if IsMandatory then
                Error(MissingImageAnalysisSecretErr);
            exit('');
        end;

        ParameterValueText := ParameterValue.AsValue().AsText();
        if (ParameterValueText = '') and IsMandatory then
            Error(MissingImageAnalysisSecretErr);

        exit(ParameterValueText);
    end;

    [NonDebuggable]
    [TryFunction]
    [Scope('OnPrem')]
    procedure GetImageAnalysisCredentials(var ApiKey: SecretText; var ApiUri: Text; var LocalLimitType: Option; var LocalLimitValue: Integer)
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        MachineLearningKeyVaultMgmt: Codeunit "Machine Learning KeyVaultMgmt.";
        ImageAnalysisParametersList: JsonArray;
        ImageAnalysisParameters: JsonObject;
        JToken: JsonToken;
        ImageAnalysisParametersText: Text;
        LimitTypeTxt: Text;
        LimitValueTxt: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(ImageAnalysisSecretTxt, ImageAnalysisParametersText) then
            Error(MissingImageAnalysisSecretErr);

        // Check if the value is a proper JSON array
        if not ImageAnalysisParametersList.ReadFrom(ImageAnalysisParametersText) then
            exit;

        // Check if the JSON array has values
        if not (ImageAnalysisParametersList.Count > 0) then
            exit;

        if not ImageAnalysisParametersList.Get(Random(ImageAnalysisParametersList.Count()) - 1, JToken) then
            exit;

        ImageAnalysisParameters := JToken.AsObject();

        ApiKey := ExtractParameterValue(ImageAnalysisParameters, 'key', false);
        ApiUri := ExtractParameterValue(ImageAnalysisParameters, 'endpoint', false);
        LimitTypeTxt := ExtractParameterValue(ImageAnalysisParameters, 'limittype', true);
        LimitValueTxt := ExtractParameterValue(ImageAnalysisParameters, 'limitvalue', true);

        LocalLimitType := MachineLearningKeyVaultMgmt.GetLimitTypeOptionFromText(LimitTypeTxt);
        Evaluate(LocalLimitValue, LimitValueTxt);
    end;

    internal procedure ToCommaSeparatedList(ImageAnalysisTypes: List of [Enum "Image Analysis Type"]) ListAsText: Text
    var
        ImageAnalysisType: Enum "Image Analysis Type";
        UntranslatedTypeName: Text;
    begin
        foreach ImageAnalysisType in ImageAnalysisTypes do begin
            UntranslatedTypeName := ImageAnalysisType.Names().Get(ImageAnalysisType.Ordinals().IndexOf(ImageAnalysisType.AsInteger()));
            ListAsText += ',' + UntranslatedTypeName;
        end;

        if StrLen(ListAsText) > 1 then
            ListAsText := CopyStr(ListAsText, 2); // Remove comma
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeImageAnalysis()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterImageAnalysis(ImageAnalysisResult: Codeunit "Image Analysis Result")
    begin
    end;

    [InternalEvent(false)]
    internal procedure OnBeforeSendImageAnalysisRequest(HttpContent: HttpContent; RequestUrl: Text; var HttpStatusCode: Integer; var HttpResponseContentText: Text; var Handled: Boolean)
    begin
    end;
}