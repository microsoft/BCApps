namespace System.AI;

using System;
using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;

codeunit 2003 "ML Prediction Management"
{

    trigger OnRun()
    begin
    end;

    var
        AzureMLConnector: Codeunit "Azure ML Connector";
        NotInitializedErr: Label 'The request has not been properly initialized.';
        RecordVar: Variant;
        LabelNo: Integer;
        ConfidenceNo: Integer;
        FeatureNumbers: array[25] of Integer;
        LastFeatureIndex: Integer;
        UsingKeyvaultCredentials: Boolean;
        NotRecordVariantErr: Label 'The variant must be a record variant.';
        FieldDoesNotExistErr: Label 'A field with the ID %1 does not exist.', Comment = '%1 = field ID';
        TooManyFeaturesErr: Label 'Cannot train or predict because you have added more than %1 features to the model.', Comment = '%1 = max number of features';
        LabelCannotBeFeatureErr: Label 'You have used the same field as the feature and as the label. A field can be either the label or feature, but not both.';
        FeatureRepeatedErr: Label 'You can add a field as a feature only one time.';
        TrainingPercent: Decimal;
        ApiUri: Text[250];
        ApiKey: SecretText;
        ApiTimeout: Integer;
        TrainingPercentageErr: Label 'The training percentage must be a decimal number between 0 and 1.';
        SomethingWentWrongErr: Label 'Oops, something went wrong when connecting to the Azure Machine Learning endpoint. Please contact your system administrator. %1.', Comment = '%1 = detailed error';
        DetailedErrorErr: Label 'Details: ';
        ErrorResponseTxt: Label 'Error code: ', Locked = true;
        AzureMachineLearningLimitReachedErr: Label 'The Microsoft Azure Machine Learning limit has been reached. Please contact your system administrator.';
        DownloadModelPlotLbl: Label 'Download model visualization in pdf format.';
        MachineLearningSecretNameTxt: Label 'machinelearning', Locked = true;
        NoCredentialsInKeyVaultErr: Label 'There were no machine learning credentials in the key vault or the credentials were corrupted.';

    procedure DefaultInitialize()
    begin
        LabelNo := 0;
        ConfidenceNo := 0;
        LastFeatureIndex := 0;
        TrainingPercent := 0.8;
    end;

    procedure Initialize(Uri: Text[250]; "Key": SecretText; TimeOutSeconds: Integer)
    begin
        ApiUri := Uri;
        ApiKey := Key;
        ApiTimeout := TimeOutSeconds;
        UsingKeyvaultCredentials := false;
        DefaultInitialize();
    end;

    [NonDebuggable]
    procedure InitializeWithKeyVaultCredentials(TimeOutSeconds: Integer)
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
        LimitType: Option;
        LimitValue: Decimal;
    begin
        AzureAIService := AzureAIService::"Machine Learning";

        if AzureAIUsage.GetTotalProcessingTime(AzureAIService) > AzureAIUsage.GetResourceLimit(AzureAIService) then
            Error(AzureMachineLearningLimitReachedErr);

        GetMachineLearningCredentials(ApiUri, ApiKey, LimitType, LimitValue);
        ApiTimeout := TimeOutSeconds;
        UsingKeyvaultCredentials := true;
        DefaultInitialize();
    end;

    [Scope('OnPrem')]
    procedure SetMessageHandler(MessageHandler: DotNet HttpMessageHandler)
    begin
        AzureMLConnector.SetMessageHandler(MessageHandler);
    end;

    procedure SetRecord(RecordVariant: Variant)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(RecordVariant, RecRef) then
            Error(NotRecordVariantErr);
        RecordVar := RecordVariant;
    end;

    procedure GetRecord(var RecordVariant: Variant)
    begin
        RecordVariant := RecordVar;
    end;

    procedure AddFeature(FeatureFieldNo: Integer)
    var
        FeatureIndex: Integer;
    begin
        if LastFeatureIndex >= MaxNoFeatures() then
            Error(TooManyFeaturesErr, MaxNoFeatures());

        if FeatureFieldNo = LabelNo then
            Error(LabelCannotBeFeatureErr);

        TestFieldNumber(FeatureFieldNo);

        for FeatureIndex := 1 to LastFeatureIndex do
            if FeatureNumbers[FeatureIndex] = FeatureFieldNo then
                Error(FeatureRepeatedErr);

        LastFeatureIndex := LastFeatureIndex + 1;
        FeatureNumbers[LastFeatureIndex] := FeatureFieldNo;
    end;

    procedure SetLabel(LabelFieldNo: Integer)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVar, RecRef);
        TestFieldNumber(LabelFieldNo);
        LabelNo := LabelFieldNo;
    end;

    procedure SetConfidence(ConfidenceFieldNo: Integer)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVar, RecRef);
        TestFieldNumber(ConfidenceFieldNo);
        ConfidenceNo := ConfidenceFieldNo;
    end;

    procedure SetTrainingPercent(TrainingPercentValue: Decimal)
    begin
        if (TrainingPercentValue <= 0) or (TrainingPercentValue >= 1) then
            Error(TrainingPercentageErr);

        TrainingPercent := TrainingPercentValue;
    end;

    procedure GetTrainingPercent(): Decimal
    begin
        exit(TrainingPercent);
    end;

    procedure Train(var Model: Text; var Quality: Decimal)
    var
        OutputValue: Text;
        CallAzureEndPoint: Boolean;
    begin
        CallAzureEndPoint := true;
        OnBeforeTrain(Model, Quality, CallAzureEndPoint);
        if not CallAzureEndPoint then
            exit;

        InitializeAzureMLConnector();

        TestFeatureLabelInitialized();
        AzureMLConnector.AddParameter('method', 'train');
        AzureMLConnector.AddParameter('train_percent', Format(TrainingPercent, 0, 9));
        CreateInput();
        if not AzureMLConnector.SendToAzureMLInternal(UsingKeyvaultCredentials) then
            Error(SomethingWentWrongErr, GetLastDetailedError());

        AzureMLConnector.GetOutput(1, 1, OutputValue);
        Model := OutputValue;
        AzureMLConnector.GetOutput(1, 2, OutputValue);
        SYSTEM.Evaluate(Quality, OutputValue, 9);
    end;

    procedure Predict(Model: Text)
    var
        CallAzureEndPoint: Boolean;
    begin
        CallAzureEndPoint := true;
        OnBeforePredict(RecordVar, CallAzureEndPoint);
        if not CallAzureEndPoint then
            exit;

        InitializeAzureMLConnector();

        TestFeatureLabelInitialized();
        AzureMLConnector.AddParameter('method', 'predict');
        AzureMLConnector.AddParameter('model', Model);
        CreateInput();
        if not AzureMLConnector.SendToAzureMLInternal(UsingKeyvaultCredentials) then
            Error(SomethingWentWrongErr, GetLastDetailedError());

        LoadPrediction();
    end;

    procedure Evaluate(Model: Text; var Quality: Decimal)
    var
        OutputValue: Text;
        CallAzureEndPoint: Boolean;
    begin
        CallAzureEndPoint := true;
        OnBeforeEvaluate(Model, Quality, RecordVar, CallAzureEndPoint);
        if not CallAzureEndPoint then
            exit;

        InitializeAzureMLConnector();

        TestFeatureLabelInitialized();
        AzureMLConnector.AddParameter('method', 'evaluate');
        AzureMLConnector.AddParameter('model', Model);
        if CreateInput() then begin
            if not AzureMLConnector.SendToAzureMLInternal(UsingKeyvaultCredentials) then
                Error(SomethingWentWrongErr, GetLastDetailedError());

            AzureMLConnector.GetOutput(1, 1, OutputValue);
            SYSTEM.Evaluate(Quality, OutputValue);
        end;
    end;

    procedure PlotModel(Model: Text; Features: Text; Labels: Text): Text
    var
        Result: Text;
    begin
        InitializeAzureMLConnector();

        AzureMLConnector.AddParameter('method', 'plotmodel');
        AzureMLConnector.AddParameter('model', Model);
        if Features <> '' then
            AzureMLConnector.AddParameter('captions', StrSubstNo('"%1"', Features));
        if Labels <> '' then
            AzureMLConnector.AddParameter('labels', StrSubstNo('"%1"', Labels));

        CreateDummyInput();

        if not AzureMLConnector.SendToAzureMLInternal(UsingKeyvaultCredentials) then
            Error(SomethingWentWrongErr, GetLastDetailedError());

        AzureMLConnector.GetOutput(1, 1, Result);
        exit(Result);
    end;

    procedure DownloadPlot(PdfDataBase64: Text; ModelName: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(PdfDataBase64, OutStream);
        TempBlob.CreateInStream(InStr);
        ModelName := StrSubstNo('%1.pdf', ModelName);
        DownloadFromStream(InStr, DownloadModelPlotLbl, '', '*.pdf', ModelName);
    end;

    procedure IsDataSufficientForClassification(): Boolean
    var
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        LabelDict: DotNet GenericDictionary2;
        TotalRecordCount: Integer;
        LabelDictKey: Text;
        LabelDictValue: Integer;
        Element: Integer;
        MinLabelCount: Integer;
        MinLabelCountInitialized: Boolean;
    begin
        if not IsDataSufficientBase(RecRef) then
            exit(false);

        CreateLabelDictionary(LabelDict);
        repeat
            FieldRef := RecRef.Field(LabelNo);
            LabelDictKey := Format(FieldRef.Value, 0, 9);
            if LabelDict.TryGetValue(LabelDictKey, LabelDictValue) then begin
                LabelDict.Remove(LabelDictKey);
                LabelDict.Add(LabelDictKey, LabelDictValue + 1);
            end else
                LabelDict.Add(LabelDictKey, 1);
            TotalRecordCount += 1;
        until RecRef.Next() = 0;

        MinLabelCountInitialized := false;
        foreach Element in LabelDict.Values do
            if not MinLabelCountInitialized then begin
                MinLabelCount := Element;
                MinLabelCountInitialized := true;
            end else
                if Element < MinLabelCount then
                    MinLabelCount := Element;

        if MinLabelCount = TotalRecordCount then
            exit(false); // there is only one label in the dataset

        // The certainity needed for at least one of the labels to be in the training set should be 99%
        exit(TotalRecordCount >= (TypeHelper.CalculateLog(1 - 0.99) /
                                  TypeHelper.CalculateLog(1 - (MinLabelCount / TotalRecordCount)) /
                                  TrainingPercent));
    end;

    procedure IsDataSufficientForRegression(): Boolean
    var
        RecRef: RecordRef;
    begin
        exit(IsDataSufficientBase(RecRef));
    end;

    procedure IsDataSufficientBase(var RecRef: RecordRef): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        TestFeatureLabelInitialized();
        DataTypeManagement.GetRecordRef(RecordVar, RecRef);

        if not RecRef.FindSet() then
            exit(false);

        // 20 is the minimum number of data points for which the decision
        // tree algorithm we are using will create a model with multiple nodes
        exit(TrainingPercent * RecRef.Count >= 20);
    end;

    [NonDebuggable]
    local procedure InitializeAzureMLConnector()
    begin
        if not AzureMLConnector.Initialize(ApiKey, ApiUri, ApiTimeout) then
            Error(NotInitializedErr, GetLastDetailedError());
    end;

    local procedure CreateLabelDictionary(var LabelDict: DotNet GenericDictionary2)
    var
        Type: DotNet Type;
        Activator: DotNet Activator;
        Arr: DotNet Array;
        DummyString: DotNet String;
        DummyInt: Integer;
    begin
        // A new object of type dictionary<String, int> is created. This object holds the Label as the key and the
        // value as the number of records in the dataset with that label.
        Arr := Arr.CreateInstance(GetDotNetType(Type), 2);
        Arr.SetValue(GetDotNetType(DummyString), 0);
        Arr.SetValue(GetDotNetType(DummyInt), 1);

        Type := GetDotNetType(LabelDict);
        Type := Type.MakeGenericType(Arr);

        LabelDict := Activator.CreateInstance(Type);
    end;

    local procedure TestFieldNumber(FieldNumber: Integer)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        DataTypeManagement.GetRecordRef(RecordVar, RecRef);
        if not RecRef.FieldExist(FieldNumber) then
            Error(FieldDoesNotExistErr, FieldNumber);
    end;

    local procedure TestFeatureLabelInitialized()
    var
        Initialized: Boolean;
    begin
        Initialized := true;
        if Format(RecordVar) = '' then
            Initialized := false;
        if LabelNo = 0 then
            Initialized := false;
        if LastFeatureIndex = 0 then
            Initialized := false;
        if not Initialized then
            Error(NotInitializedErr);
    end;

    local procedure CreateInput(): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ColumnNo: Integer;
    begin
        for ColumnNo := 1 to MaxNoFeatures() do
            AzureMLConnector.AddInputColumnName(StrSubstNo('feature%1', ColumnNo));
        AzureMLConnector.AddInputColumnName('label');

        DataTypeManagement.GetRecordRef(RecordVar, RecRef);
        if not RecRef.FindSet() then
            exit(false);

        repeat
            AzureMLConnector.AddInputRow();
            for ColumnNo := 1 to MaxNoFeatures() do
                if ColumnNo <= LastFeatureIndex then begin
                    FieldRef := RecRef.Field(FeatureNumbers[ColumnNo]);
                    if FieldRef.Class = FieldClass::FlowField then
                        FieldRef.CalcField();
                    AzureMLConnector.AddInputValue(Format(FieldRef.Value, 0, 9));
                    AzureMLConnector.AddParameter(StrSubstNo('featuretype%1', ColumnNo), Format(FieldRef.Type));
                end else
                    AzureMLConnector.AddInputValue('');

            FieldRef := RecRef.Field(LabelNo);
            if FieldRef.Class = FieldClass::FlowField then
                FieldRef.CalcField();
            AzureMLConnector.AddInputValue(Format(FieldRef.Value, 0, 9));
            AzureMLConnector.AddParameter('labeltype', Format(FieldRef.Type));
        until RecRef.Next() = 0;

        exit(true);
    end;

    local procedure CreateDummyInput()
    var
        ColumnNo: Integer;
    begin
        for ColumnNo := 1 to MaxNoFeatures() do
            AzureMLConnector.AddInputColumnName(StrSubstNo('feature%1', ColumnNo));
        AzureMLConnector.AddInputColumnName('label');

        AzureMLConnector.AddInputRow();
        for ColumnNo := 1 to MaxNoFeatures() + 1 do
            AzureMLConnector.AddInputValue('0');
    end;

    procedure GetParameter(Name: Text): Text
    var
        ParameterValue: Text;
    begin
        AzureMLConnector.GetParameter(Name, ParameterValue);
        exit(ParameterValue);
    end;

    procedure GetInput(RowNo: Integer; ColumnNo: Integer): Text
    var
        InputValue: Text;
    begin
        AzureMLConnector.GetInput(RowNo, ColumnNo, InputValue);
        exit(InputValue);
    end;

    procedure GetInputLength(): Integer
    var
        Length: Integer;
    begin
        AzureMLConnector.GetInputLength(Length);
        exit(Length);
    end;

    local procedure GetLastDetailedError(): Text
    var
        DetailedErrorTxt: Text;
        DetailedErrorStart: Integer;
    begin
        DetailedErrorStart := StrPos(GetLastErrorText, ErrorResponseTxt);
        if DetailedErrorStart > 0 then begin
            DetailedErrorTxt := CopyStr(GetLastErrorText, StrPos(GetLastErrorText, ErrorResponseTxt));
            DetailedErrorTxt := CopyStr(DetailedErrorTxt, 1, StrPos(DetailedErrorTxt, '\') - 1);
            exit('\' + DetailedErrorErr + DetailedErrorTxt);
        end;
        exit('\' + DetailedErrorErr + GetLastErrorText);
    end;

    local procedure LoadPrediction()
    var
        DataTypeManagement: Codeunit "Data Type Management";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        LabelColumnNumber: Integer;
        ConfidenceColumnNumber: Integer;
        RowNumber: Integer;
        Label: Text[250];
        Confidence: Text[250];
        OutputValue: Text;
    begin
        RowNumber := 1;
        LabelColumnNumber := MaxNoFeatures() + 1;
        ConfidenceColumnNumber := LabelColumnNumber + 1;
        DataTypeManagement.GetRecordRef(RecordVar, RecRef);
        if RecRef.FindSet() then
            repeat
                if ConfidenceNo <> 0 then begin
                    AzureMLConnector.GetOutput(RowNumber, ConfidenceColumnNumber, OutputValue);
                    Confidence := CopyStr(OutputValue, 1, MaxStrLen(Confidence));
                    FieldRef := RecRef.Field(ConfidenceNo);
                    ConfigValidateManagement.EvaluateValueWithValidate(FieldRef, Confidence, true);
                end;

                AzureMLConnector.GetOutput(RowNumber, LabelColumnNumber, OutputValue);
                Label := CopyStr(OutputValue, 1, MaxStrLen(Label));
                FieldRef := RecRef.Field(LabelNo);
                ConfigValidateManagement.EvaluateValueWithValidate(FieldRef, Label, true);
                RecRef.Modify(true);
                RowNumber := RowNumber + 1;
            until RecRef.Next() = 0;
        if RecRef.FindSet() then
            RecRef.SetTable(RecordVar);
    end;

    procedure MaxNoFeatures(): Integer
    begin
        exit(ArrayLen(FeatureNumbers));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetMachineLearningCredentials(var MLApiUri: Text[250]; var MLApiKey: SecretText; var LimitType: Option; var Limit: Decimal)
    var
        MachineLearningKeyVaultMgmt: Codeunit "Machine Learning KeyVaultMgmt.";
    begin
        MachineLearningKeyVaultMgmt.GetMachineLearningCredentials(MachineLearningSecretNameTxt, MLApiUri, MLApiKey, LimitType, Limit);

        if MLApiUri = '' then
            Error(NoCredentialsInKeyVaultErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrain(var Model: Text; var Quality: Decimal; var CallAzureEndPoint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePredict(var RecordVariant: Variant; var CallAzureEndPoint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluate(Model: Text; var Quality: Decimal; var RecordVariant: Variant; var CallAzureEndPoint: Boolean)
    begin
    end;
}
