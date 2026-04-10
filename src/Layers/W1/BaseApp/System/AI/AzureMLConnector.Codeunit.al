namespace System.AI;

using System;

codeunit 2001 "Azure ML Connector"
{

    trigger OnRun()
    begin
        // Set default timeout if not already set
        if DefaultTimeoutSeconds = 0 then
            DefaultTimeoutSeconds := 300; // 5 minutes default
    end;

    var
        [NonDebuggable]
        [WithEvents]
        AzureMLRequest: DotNet AzureMLRequest;
        [WithEvents]
        AzureMLParametersBuilder: DotNet AzureMLParametersBuilder;
        [WithEvents]
        AzureMLInputBuilder: DotNet AzureMLInputBuilder;
        HttpMessageHandler: DotNet HttpMessageHandler;
        ProcessingTime: Decimal;
        OutputNameTxt: Label 'Output1', Locked = true;
        InputNameTxt: Label 'input1', Locked = true;
        ParametersNameTxt: Label 'Parameters', Locked = true;
        InputName: Text;
        OutputName: Text;
        ParametersName: Text;
        InvalidURIErr: Label 'Provided API URL (%1) is not a valid AzureML URL.', Comment = '%1 = custom URL';
        DefaultTimeoutSeconds: Integer;


    [NonDebuggable]
    [TryFunction]
    procedure Initialize(ApiKey: SecretText; ApiUri: Text; TimeOutSeconds: Integer)
    begin
        // Default timeout to a higher value (5 minutes) to prevent task cancellation errors
        if TimeOutSeconds = 0 then
            TimeOutSeconds := DefaultTimeoutSeconds;
        AzureMLRequest := AzureMLRequest.AzureMLRequest(ApiKey.Unwrap(), ApiUri, TimeOutSeconds);

        // To set HttpMessageHandler first call SetMessageHandler
        AzureMLRequest.SetHttpMessageHandler(HttpMessageHandler);

        AzureMLInputBuilder := AzureMLInputBuilder.AzureMLInputBuilder();

        AzureMLParametersBuilder := AzureMLParametersBuilder.AzureMLParametersBuilder();

        OutputName := OutputNameTxt;
        InputName := InputNameTxt;
        ParametersName := ParametersNameTxt;

        AzureMLRequest.SetInput(InputName, AzureMLInputBuilder);
        AzureMLRequest.SetParameter(ParametersName, AzureMLParametersBuilder);
    end;

    procedure IsInitialized(): Boolean
    begin
        exit(not IsNull(AzureMLRequest) and not IsNull(AzureMLInputBuilder) and not IsNull(AzureMLParametersBuilder));
    end;

    procedure SetDefaultTimeoutSeconds(TimeoutSeconds: Integer)
    begin
        DefaultTimeoutSeconds := TimeoutSeconds;
    end;

    [Scope('OnPrem')]
    procedure SendToAzureMLInternal(TrackUsage: Boolean): Boolean
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
    begin
        AzureMLRequest.SetUsingStandardCredentials(TrackUsage);

        if not SendRequestToAzureML() then
            exit(false);

        if TrackUsage then begin
            // Convert to seconds
            ProcessingTime := ProcessingTime / 1000;
            AzureAIUsage.IncrementTotalProcessingTime(AzureAIService::"Machine Learning",
              ProcessingTime);
        end;
        exit(true);
    end;

    procedure SendToAzureML(): Boolean
    begin
        exit(SendToAzureMLInternal(true));
    end;

    [TryFunction]
    procedure ValidateApiUrl(ApiUrl: Text)
    var
        AzureMLHelper: DotNet AzureMLHelper;
    begin
        if ApiUrl <> '' then
            if not AzureMLHelper.ValidateUri(ApiUrl) then
                Error(InvalidURIErr, ApiUrl);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SendRequestToAzureML()
    begin
        AzureMLRequest.SetHttpMessageHandler(HttpMessageHandler);
        ProcessingTime := AzureMLRequest.InvokeRequestResponseService();
    end;

    [Scope('OnPrem')]
    procedure SetMessageHandler(MessageHandler: DotNet HttpMessageHandler)
    begin
        HttpMessageHandler := MessageHandler;
    end;

    [TryFunction]
    procedure SetInputName(Name: Text)
    begin
        InputName := Name;
        AzureMLRequest.SetInput(InputName, AzureMLInputBuilder);
    end;

    [TryFunction]
    procedure AddInputColumnName(ColumnName: Text)
    begin
        AzureMLInputBuilder.AddColumnName(ColumnName);
    end;

    [TryFunction]
    procedure AddInputRow()
    begin
        AzureMLInputBuilder.AddRow();
    end;

    [TryFunction]
    procedure AddInputValue(Value: Text)
    begin
        AzureMLInputBuilder.AddValue(Value);
    end;

    [TryFunction]
    procedure AddParameter(Name: Text; Value: Text)
    begin
        AzureMLParametersBuilder.AddParameter(Name, Value);
    end;

    [TryFunction]
    procedure SetParameterName(Name: Text)
    begin
        ParametersName := Name;
        AzureMLRequest.SetParameter(ParametersName, AzureMLParametersBuilder);
    end;

    [TryFunction]
    procedure SetOutputName(Name: Text)
    begin
        OutputName := Name;
    end;

    [TryFunction]
    procedure GetOutput(LineNo: Integer; ColumnNo: Integer; var OutputValue: Text)
    begin
        OutputValue := AzureMLRequest.GetOutputValue(OutputName, LineNo - 1, ColumnNo - 1);
    end;

    [TryFunction]
    procedure GetOutputLength(var Length: Integer)
    begin
        Length := AzureMLRequest.GetOutputLength(OutputName);
    end;

    [TryFunction]
    procedure GetInput(LineNo: Integer; ColumnNo: Integer; var InputValue: Text)
    begin
        InputValue := AzureMLInputBuilder.GetValue(LineNo - 1, ColumnNo - 1);
    end;

    [TryFunction]
    procedure GetInputLength(var Length: Integer)
    begin
        Length := AzureMLInputBuilder.GetLength();
    end;

    [TryFunction]
    procedure GetParameter(Name: Text; var ParameterValue: Text)
    begin
        ParameterValue := AzureMLParametersBuilder.GetParameter(Name);
    end;
}
