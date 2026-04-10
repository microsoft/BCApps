namespace System.AI;

using System;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 2024 "Image Analysis Wrapper V1.0" implements "Image Analysis Provider"
{
    Access = Internal;

    var
        CognitiveServicesErr: Label 'Could not contact the %1. %2 Status code: %3.', Comment = '%1: Error returned from called API. %2: the error message. %3: HTTP status code of error';
        OnlyOneAnalysisSupportedErr: Label 'The current implementation of Image Analysis supports only one analysis type at a time.';
        ComputerVisionApiTxt: Label 'Computer Vision API';
        CustomVisionServiceTxt: Label 'Custom Vision Service';
        UrlPatternTxt: Label '?visualFeatures=%1', Locked = true;
        LastError: Text;
        HttpMessageHandler: DotNet HttpMessageHandler;

    procedure InvokeAnalysis(var JSONManagement: Codeunit "JSON Management"; BaseUrl: Text; ImageAnalysisKey: SecretText; ImagePath: Text; ImageAnalysisTypes: List of [Enum "Image Analysis Type"]; LanguageId: Integer): Boolean
    begin
        if ImageAnalysisTypes.Count() > 1 then
            Error(OnlyOneAnalysisSupportedErr);

        exit(TryInvokeAnalysisInternal(JSONManagement, BaseUrl, ImageAnalysisKey, ImagePath, ImageAnalysisTypes.Get(1)));
    end;

    [TryFunction]
    local procedure TryInvokeAnalysisInternal(var JSONManagement: Codeunit "JSON Management"; BaseUrl: Text; ImageAnalysisKey: SecretText; ImagePath: Text; ImageAnalysisType: Enum "Image Analysis Type")
    var
        FileManagement: Codeunit "File Management";
        HttpClient: DotNet HttpClient;
        StreamContent: DotNet StreamContent;
        HttpResponseMessage: DotNet HttpResponseMessage;
        HttpRequestHeaders: DotNet HttpRequestHeaders;
        MediaTypeWithQualityHeaderValue: DotNet MediaTypeWithQualityHeaderValue;
        HttpContent: DotNet HttpContent;
        HttpContentHeaders: DotNet HttpContentHeaders;
        HttpHeaderValueCollection: DotNet HttpHeaderValueCollection1;
        ApiUri: DotNet Uri;
        Task: DotNet Task1;
        File: DotNet File;
        FileStream: DotNet FileStream;
        JsonResult: DotNet JObject;
        MessageText: Text;
        PostParameters: Text;
    begin
        if IsNull(HttpMessageHandler) then
            HttpClient := HttpClient.HttpClient()
        else
            HttpClient := HttpClient.HttpClient(HttpMessageHandler);

        HttpClient.BaseAddress := ApiUri.Uri(BaseUrl);

        HttpRequestHeaders := HttpClient.DefaultRequestHeaders;
        if HasCustomVisionUri(BaseUrl) then
            AddRequestHeader(HttpRequestHeaders, 'Prediction-Key', ImageAnalysisKey)
        else begin
            AddRequestHeader(HttpRequestHeaders, 'Ocp-Apim-Subscription-Key', ImageAnalysisKey);
            PostParameters := StrSubstNo(UrlPatternTxt, Format(ImageAnalysisType));
        end;
        HttpHeaderValueCollection := HttpRequestHeaders.Accept();
        MediaTypeWithQualityHeaderValue :=
          MediaTypeWithQualityHeaderValue.MediaTypeWithQualityHeaderValue('application/json');
        HttpHeaderValueCollection.Add(MediaTypeWithQualityHeaderValue);

        FileManagement.IsAllowedPath(ImagePath, false);

        FileStream := File.OpenRead(ImagePath);
        StreamContent := StreamContent.StreamContent(FileStream);
        HttpContentHeaders := StreamContent.Headers;
        HttpContentHeaders.Add('Content-Type', 'application/octet-stream');

        Task := HttpClient.PostAsync(PostParameters, StreamContent);

        HttpResponseMessage := Task.Result;
        HttpContent := HttpResponseMessage.Content;
        Task := HttpContent.ReadAsStringAsync();
        JSONManagement.InitializeObject(Task.Result);

        FileStream.Dispose();
        StreamContent.Dispose();
        HttpClient.Dispose();

        if not HttpResponseMessage.IsSuccessStatusCode then begin
            JSONManagement.GetJSONObject(JsonResult);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JsonResult, 'message', MessageText);
            if HasCustomVisionUri(BaseUrl) then
                LastError := StrSubstNo(CognitiveServicesErr, CustomVisionServiceTxt, MessageText, HttpResponseMessage.StatusCode)
            else
                LastError := StrSubstNo(CognitiveServicesErr, ComputerVisionApiTxt, MessageText, HttpResponseMessage.StatusCode);
            Error('');
        end;
    end;

    [NonDebuggable]
    local procedure AddRequestHeader(var HttpRequestHeaders: DotNet HttpRequestHeaders; Name: Text; Value: SecretText)
    begin
        HttpRequestHeaders.TryAddWithoutValidation(Name, Value.Unwrap());
    end;

    procedure IsLanguageSupported(AnalysisTypes: List of [Enum "Image Analysis Type"]; LanguageId: Integer): Boolean
    begin
        exit(true);
    end;

    procedure IsMediaSupported(MediaID: Guid): Boolean
    begin
        exit(true);
    end;

    procedure GetLastError(): Text
    begin
        exit(LastError);
    end;

    local procedure HasCustomVisionUri(Uri: Text): Boolean
    begin
        exit(StrPos(Uri, '/customvision/') <> 0);
    end;

    internal procedure SetHttpMessageHandler(NewHttpMessageHandler: DotNet HttpMessageHandler)
    begin
        HttpMessageHandler := NewHttpMessageHandler;
    end;
}