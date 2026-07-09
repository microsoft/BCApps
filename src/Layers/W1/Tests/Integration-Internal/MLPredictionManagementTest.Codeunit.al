codeunit 135208 "ML Prediction Management Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "Azure AI Usage" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [Prediction]
    end;

    var
        Assert: Codeunit Assert;
        MockServicePredictionUriTxt: Label 'https://localhost:8080/services.azureml.net/workspaces/predict', Locked = true;
        MockServiceTrainingUriTxt: Label 'https://localhost:8080/services.azureml.net/workspaces/train', Locked = true;
        MockServicePlotUriTxt: Label 'https://localhost:8080/services.azureml.net/workspaces/Plot', Locked = true;
        NotInitializedErr: Label 'The request has not been properly initialized.';
        NotRecordVariantErr: Label 'The variant must be a record variant.';
        FieldDoesNotExistErr: Label 'A field with the ID %1 does not exist.', Comment = '%1 = field ID';
        TooManyFeaturesErr: Label 'Cannot train or predict because you have added more than %1 features to the model.', Comment = '%1 = max number of features';
        LabelCannotBeFeatureErr: Label 'You have used the same field as the feature and as the label. A field can be either the label or feature, but not both.';
        FeatureRepeatedErr: Label 'You can add a field as a feature only one time.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        AzureMLTask: Option Training,Prediction,Evaluation,Error,Plot;
        TrainingPercentageErr: Label 'The training percentage must be a decimal number between 0 and 1.';
        SomethingWentWrongErr: Label 'Oops, something went wrong when connecting to the Azure Machine Learning endpoint. Please contact your system administrator. %1.';
        AzureMachineLearningLimitReachedErr: Label 'The Microsoft Azure Machine Learning limit has been reached. Please contact your system administrator.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestNotInitialized()
    var
        MLPredictionManagement: Codeunit "ML Prediction Management";
        ApiUri: Text[250];
        ApiKey: Text[200];
    begin
        // [SCENARIO] ML Prediction Management throws an error when Uri is not initialized.

        // [WHEN] The Prediction Library is not properly initialized
        // [THEN] An error is thrown
        LibraryLowerPermissions.SetO365Basic();
        ApiUri := '';
        ApiKey := '123';
        MLPredictionManagement.Initialize(ApiUri, ApiKey, 12);
        asserterror MLPredictionManagement.Predict('');
        Assert.ExpectedError(NotInitializedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNonRecordVariantGivesError()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
    begin
        // [SCENARIO] Using ML Prediction Management with a non record variant leads to an error.

        // [GIVEN] The Prediction Library is initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Prediction, false);

        // [WHEN] A non-record is given to the Prediction Library
        // [THEN] An error is thrown
        asserterror MLPredictionManagement.SetRecord(true);
        Assert.ExpectedError(NotRecordVariantErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFeaturesAndLabelsSet()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        I: Integer;
    begin
        // [SCENARIO] When features and labels are set, correctness of indices are checked.

        // [GIVEN] The Prediction Library has a record set
        LibraryLowerPermissions.SetO365Basic();
        MLPredictionManagement.SetRecord(TempPredictionData);

        // [WHEN] Features/labels are set

        // [THEN] The label number has to be less than the total number of fields and greater than 0
        asserterror MLPredictionManagement.SetLabel(1234);
        Assert.ExpectedError(StrSubstNo(FieldDoesNotExistErr, 1234));
        asserterror MLPredictionManagement.SetLabel(0);
        Assert.ExpectedError(StrSubstNo(FieldDoesNotExistErr, 0));

        MLPredictionManagement.SetLabel(1);

        // [THEN] A feature number has to be less than the total number of fields and greater than 0
        asserterror MLPredictionManagement.AddFeature(1235);
        Assert.ExpectedError(StrSubstNo(FieldDoesNotExistErr, 1235));
        asserterror MLPredictionManagement.AddFeature(-1);
        Assert.ExpectedError(StrSubstNo(FieldDoesNotExistErr, -1));

        // [THEN] A feature number cannot be equal to the label number
        asserterror MLPredictionManagement.AddFeature(1);
        Assert.ExpectedError(LabelCannotBeFeatureErr);

        // [THEN] Two features cannot refer to the same field
        MLPredictionManagement.AddFeature(2);
        asserterror MLPredictionManagement.AddFeature(2);
        Assert.ExpectedError(FeatureRepeatedErr);

        // [THEN] Only MaxNoFeatures features can be added
        DataTypeManagement.GetRecordRef(TempPredictionData, RecRef);
        for I := 3 to MLPredictionManagement.MaxNoFeatures() + 1 do begin
            FieldRef := RecRef.FieldIndex(I);
            MLPredictionManagement.AddFeature(FieldRef.Number);
        end;

        FieldRef := RecRef.FieldIndex(RecRef.FieldCount);
        asserterror MLPredictionManagement.AddFeature(FieldRef.Number);
        Assert.ExpectedError(StrSubstNo(TooManyFeaturesErr, MLPredictionManagement.MaxNoFeatures()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestInitializationChecked()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
        ApiUri: Text[250];
        ApiKey: Text[200];
    begin
        // [SCENARIO] When initialization is not performed, errors are thrown.

        // [GIVEN] A prediction library
        LibraryLowerPermissions.SetO365Basic();

        // [WHEN] The library has not been initialized
        // [THEN] An error is thrown
        asserterror MLPredictionManagement.Train(Model, Quality);
        Assert.ExpectedError(NotInitializedErr);

        // [WHEN] No record has been set
        ApiUri := 'https://services.azureml.net';
        ApiKey := '12';
        MLPredictionManagement.Initialize(ApiUri, ApiKey, 12);
        // [THEN] An error is thrown
        asserterror MLPredictionManagement.Train(Model, Quality);
        Assert.ExpectedError(NotInitializedErr);

        // [WHEN] No label has been set
        MLPredictionManagement.SetRecord(TempPredictionData);
        // [THEN] An error is thrown
        asserterror MLPredictionManagement.Train(Model, Quality);
        Assert.ExpectedError(NotInitializedErr);

        // [WHEN] No feature has been set
        MLPredictionManagement.SetLabel(1);
        // [THEN] An error is thrown
        asserterror MLPredictionManagement.Train(Model, Quality);
        Assert.ExpectedError(NotInitializedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrainingDataWritten()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
    begin
        // [SCENARIO] When training is performed, training data is written correctly.

        // [GIVEN] A data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Training, false);

        // [WHEN] Training data has been built (and training performed)
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] The input contains the right values in the right order
        TempPredictionData.Get('K2');
        Assert.AreEqual(Format(TempPredictionData."Feature A"), MLPredictionManagement.GetInput(2, 1), 'Input contains wrong values');
        Assert.AreEqual(Format(TempPredictionData."Feature C"), MLPredictionManagement.GetInput(2, 2), 'Input contains wrong values');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTraining()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
    begin
        // [SCENARIO] Training returns a model and quality.

        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Training, false);

        // [WHEN] Training percent is set
        MLPredictionManagement.SetTrainingPercent(0.9);

        // [THEN] The correct value is used/retrived
        Assert.IsTrue(MLPredictionManagement.GetTrainingPercent() = 0.9, 'Training percent is not correctly set.');

        // [WHEN] Training is performed
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] Parameters contain the right names and values
        Assert.AreEqual('train', MLPredictionManagement.GetParameter('method'), 'Wrong training parameter');

        // [THEN] Then no errors are thrown. The quality is correct
        Assert.IsTrue(Quality = 0.75, 'Quality is not correctly retrieved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPrediction()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
    begin
        // [SCENARIO] A trained model can be used for prediction and the prediction is in correct format.

        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Training, false);

        // [WHEN] Training is performed
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] Training can be performed again without reinitializing

        // [THEN] Then the model can be used for prediction
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServicePredictionUriTxt,
          AzureMLTask::Prediction, false);
        MLPredictionManagement.Predict(Model);

        // [THEN] Parameters contain the right names and values
        Assert.AreEqual('predict', MLPredictionManagement.GetParameter('method'), 'Wrong prediction parameter');
        Assert.AreEqual(Model, MLPredictionManagement.GetParameter('model'), 'Wrong prediction parameter');

        // [THEN] The output (from AML) is parsed correctly
        TempPredictionData.Get('K1');
        Assert.IsTrue(TempPredictionData.Label, 'Prediction output parsed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEvaluation()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
    begin
        // [SCENARIO] A trained model can be used for evaluation.
        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Training, false);

        // [WHEN] Training is performed
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] Training can be performed again without reinitializing

        // [THEN] Then the model can be used for prediction
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServicePredictionUriTxt,
          AzureMLTask::Evaluation, false);
        MLPredictionManagement.Evaluate(Model, Quality);

        // [THEN] Parameters contain the right names and values
        Assert.AreEqual('evaluate', MLPredictionManagement.GetParameter('method'), 'Wrong prediction parameter');
        Assert.AreEqual(Model, MLPredictionManagement.GetParameter('model'), 'Wrong prediction parameter');

        // [THEN] A quality is returned
        Assert.AreEqual(0.75, Quality, 'Evaluation output parsed incorrectly');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestModelPlot()
    var
        MLPredictionManagement: Codeunit "ML Prediction Management";
        MockHttpResponseMessageHandler: DotNet MockHttpMessageHandler;
        Model: Text;
        Counter: Integer;
        ApiUri: Text[250];
        ApiKey: Text[200];
    begin
        // [SCENARIO] A trained model can be ploted.
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] A Trained model and an initialized library
        Model := GetTrainedModel();
        MLPredictionManagement.SetMessageHandler(
          MockHttpResponseMessageHandler.MockHttpMessageHandler(GetResponseFileName(AzureMLTask)));
        ApiUri := MockServicePlotUriTxt;
        ApiKey := '';
        MLPredictionManagement.Initialize(ApiUri, ApiKey, 0);

        // [WHEN] PlotModel method is called
        MLPredictionManagement.PlotModel(Model, 'A,B,C,D', 'A,B');

        // [THEN] The Input is created correctly
        Assert.AreEqual('plotmodel', MLPredictionManagement.GetParameter('method'), 'A different method parameter was expected');
        Assert.AreEqual(Model, MLPredictionManagement.GetParameter('model'), 'A different model parameter was expected');
        Assert.AreEqual('"A,B,C,D"', MLPredictionManagement.GetParameter('captions'), 'A different captions parameter was expected');
        Assert.AreEqual('"A,B"', MLPredictionManagement.GetParameter('labels'), 'A different labels parameter was expected');
        for Counter := 1 to 26 do
            Assert.AreEqual(Format(0), MLPredictionManagement.GetInput(1, Counter), 'Dummy Input check failed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetTraininingPercent()
    var
        MLPredictionManagement: Codeunit "ML Prediction Management";
        ApiUri: Text[250];
        ApiKey: Text[200];
    begin
        // [SCENARIO] An error is thrown when an incorrect training percentage is set.

        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        ApiUri := '';
        ApiKey := '';
        MLPredictionManagement.Initialize(ApiUri, ApiKey, 0);

        // [WHEN] A too low training percentage is set
        asserterror MLPredictionManagement.SetTrainingPercent(0);

        // [THEN] An appropriate error is thrown
        Assert.ExpectedError(TrainingPercentageErr);

        // [WHEN] A too high training percentage is set
        asserterror MLPredictionManagement.SetTrainingPercent(1);

        // [THEN] An appropriate error is thrown
        Assert.ExpectedError(TrainingPercentageErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDetailedError()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
        ExpectedErrorText: Text;
    begin
        // [SCENARIO] An error from the Azure ML Experiment is parsed correctly.
        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Error, false);

        ExpectedErrorText := StrSubstNo(SomethingWentWrongErr,
            '\Details: Error code: 104. Training percentage must be between 0 and 1. Current value: ');

        // [WHEN] Training is performed
        asserterror MLPredictionManagement.Train(Model, Quality);

        // [THEN] The appropriate error is throw
        Assert.AreEqual(ExpectedErrorText, GetLastErrorText, 'Wrong error text in training.');
        ClearLastError();

        // [WHEN] Prediction is performed
        asserterror MLPredictionManagement.Predict(Model);

        // [THEN] The appropriate error is throw
        Assert.AreEqual(ExpectedErrorText, GetLastErrorText, 'Wrong error text in prediction.');
        ClearLastError();

        // [WHEN] Evaluate is performed
        asserterror MLPredictionManagement.Evaluate(Model, Quality);

        // [THEN] The appropriate error is throw
        Assert.AreEqual(ExpectedErrorText, GetLastErrorText, 'Wrong error text in evaluation.');
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSendToAzureMLCallIncrementsProcessingTime()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        AzureAIUsage: Record "Azure AI Usage";
        AzureAIUsageImpl: Codeunit "Azure AI Usage Impl.";
        MLPredictionManagement: Codeunit "ML Prediction Management";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureAIService: Enum "Azure AI Service";
        Model: Text;
        Quality: Decimal;
        LastDateTimeUpdated: DateTime;
    begin
        // [SCENARIO] Call to Send to AzureML increments usage
        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnsureThatMockDataIsFetchedFromKeyVault();

        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Training, true);

        // [GIVEN] A usage record exists for Azure ML, with say 1000 seconds of usage
        AzureAIUsage.DeleteAll();

        AzureAIUsageImpl.GetSingleInstance(AzureAIService::"Machine Learning", AzureAIUsage);
        AzureAIUsage."Total Resource Usage" := 3;
        LastDateTimeUpdated := CurrentDateTime - 1000;
        AzureAIUsage."Last DateTime Updated" := LastDateTimeUpdated;
        AzureAIUsage.Modify();

        // [WHEN] Training is performed
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] Usage is incremented with the processing time
        AzureAIUsageImpl.GetSingleInstance(AzureAIService::"Machine Learning", AzureAIUsage);
        Assert.IsTrue(AzureAIUsage."Total Resource Usage" > 3, 'Processing time has not increased');

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeWithKeyVaultCredentialsChecksForExcessUsage()
    var
        AzureAIUsage: Record "Azure AI Usage";
        AzureAIUsageImpl: Codeunit "Azure AI Usage Impl.";
        MLPredictionManagement: Codeunit "ML Prediction Management";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureAIService: Enum "Azure AI Service";
    begin
        // [SCENARIO] Initializing with Key vault credentials errors out if the usage limit has been reached.
        LibraryLowerPermissions.SetO365Basic();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnsureThatMockDataIsFetchedFromKeyVault();

        // [GIVEN] A usage record exists for Azure ML, with say 1000 seconds of usage which is the same as its original quota
        AzureAIUsage.DeleteAll();
        AzureAIUsageImpl.GetSingleInstance(AzureAIService::"Machine Learning", AzureAIUsage);
        AzureAIUsage."Total Resource Usage" := AzureAIUsage."Original Resource Limit" + 1;
        AzureAIUsage.Modify();

        // [WHEN] The codeunit is initialized with key vault credentials
        asserterror MLPredictionManagement.InitializeWithKeyVaultCredentials(0);

        // [THEN] The error is about excess usage
        Assert.ExpectedError(AzureMachineLearningLimitReachedErr);

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsDataSufficient()
    var
        TempFeatureLabelData: Record "Feature Label Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Result: Boolean;
        ApiUri: Text[250];
        ApiKey: Text[200];
    begin
        // [SCENARIO] A feature label dataset meets the criteria of sufficient data
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] Initialized
        ApiUri := 'ApiUri';
        ApiKey := '';
        MLPredictionManagement.Initialize(ApiUri, ApiKey, 0);

        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        MLPredictionManagement.SetRecord(TempFeatureLabelData);
        MLPredictionManagement.AddFeature(TempFeatureLabelData.FieldNo("Feature A"));
        MLPredictionManagement.AddFeature(TempFeatureLabelData.FieldNo("Feature B"));
        MLPredictionManagement.AddFeature(TempFeatureLabelData.FieldNo("Feature C"));
        MLPredictionManagement.SetLabel(TempFeatureLabelData.FieldNo(Label));

        // [GIVEN] Create records with 2 labels of sizes 26 and 4 counts
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'P', 26);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'Q', 4);

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Does not meet criteria
        Assert.IsFalse(Result, 'Total = 30 & Min Records Required (P, Q) = 2.856943, 40.22662 respectively');

        // [GIVEN] Create records with 3 labels of sizes 25, 3 and 2 counts
        TempFeatureLabelData.DeleteAll();
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'P', 25);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'Q', 3);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'R', 2);

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Does not meet criteria
        Assert.IsFalse(Result, 'Total= 30 & Min Records Required (P, Q, R) = 3.212743, 54.63586, 83.43562 respectively');

        // [GIVEN] Create records with 3 labels of sizes 15, 9 and 9 counts
        TempFeatureLabelData.DeleteAll();
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'P', 15);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'Q', 9);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'R', 9);

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Meets criteria
        Assert.IsTrue(Result, 'Total = 33 & Min Records Required (P, Q, R) = 9.496985162, 18.07629231, 18.07629231 respectively');

        // [GIVEN] Create records with 2 labels of sizes 47 and 18 counts
        TempFeatureLabelData.DeleteAll();
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'P', 47);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'Q', 18);

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Meets criteria
        Assert.IsTrue(Result, 'Total = 65 & Min Records Required (P, Q) = 4.483172266, 17.75372756 respectively');

        // [GIVEN] Create records with 1 labels of size 30 count
        TempFeatureLabelData.DeleteAll();
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'P', 30);

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Does not meet criteria
        Assert.IsFalse(Result, 'Total = 30 & labels are only of one kind');

        // [GIVEN] Create empty record
        TempFeatureLabelData.DeleteAll();

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Does not meet criteria
        Assert.IsFalse(Result, 'Total = 0');

        // [GIVEN] Create records with 2 labels of sizes 10 and 13 counts
        TempFeatureLabelData.DeleteAll();
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'P', 10);
        CreatePredictionDataWithOnlyLabel(TempFeatureLabelData, 'Q', 13);

        // [WHEN] IsDataSufficientForClassification is Invoked
        Result := MLPredictionManagement.IsDataSufficientForClassification();

        // [THEN] Does not meet criteria
        Assert.IsFalse(Result, 'Total training data size is less than 20, which should be insufficient.');

        // [WHEN] IsDataSufficientForRegression is Invoked
        Result := MLPredictionManagement.IsDataSufficientForRegression();

        // [THEN] Does not meet criteria
        Assert.IsFalse(Result, 'Total training data size is less than 20, which should be insufficient.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTypesInAMLCall()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        Model: Text;
        Quality: Decimal;
    begin
        // [SCENARIO] A request is being sent to AML. Types are part of paramaters.
        // [GIVEN] Data has been prepared for training and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();
        InitLibraryAndData(TempPredictionData, MLPredictionManagement, MockServiceTrainingUriTxt,
          AzureMLTask::Training, false);

        // [WHEN] Training is performed
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] Column feature types are correctly set
        Assert.AreEqual('Decimal', MLPredictionManagement.GetParameter('featuretype1'), 'Feature type 1 is set incorrectly.');
        Assert.AreEqual('Integer', MLPredictionManagement.GetParameter('featuretype2'), 'Feature type 2 is set incorrectly.');
        Assert.AreEqual('Option', MLPredictionManagement.GetParameter('featuretype3'), 'Feature type 3 is set incorrectly.');

        // [THEN] Label feature type is correctly set
        Assert.AreEqual('Boolean', MLPredictionManagement.GetParameter('labeltype'), 'Label type 3 is set incorrectly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFlowFieldsInData()
    var
        TempPredictionData: Record "Prediction Data" temporary;
        MLPredictionManagement: Codeunit "ML Prediction Management";
        HttpMessageHandler: DotNet MockHttpMessageHandler;
        Model: Text;
        Quality: Decimal;
        ApiUri: Text[250];
        ApiKey: Text[200];
    begin
        // [SCENARIO] A request is being sent to AML. A FlowField is in the data

        // [GIVEN] Data has been prepared for training with a FlowField feature and label and the Prediction Library initialized
        LibraryLowerPermissions.SetO365Basic();

        MLPredictionManagement.SetMessageHandler(HttpMessageHandler.MockHttpMessageHandler(GetResponseFileName(AzureMLTask)));
        ApiUri := MockServiceTrainingUriTxt;
        ApiKey := '';
        MLPredictionManagement.Initialize(ApiUri, ApiKey, 0);
        MLPredictionManagement.SetRecord(TempPredictionData);
        MLPredictionManagement.AddFeature(TempPredictionData.FieldNo("Feature E"));
        MLPredictionManagement.AddFeature(TempPredictionData.FieldNo("Feature C"));
        MLPredictionManagement.SetLabel(TempPredictionData.FieldNo("Feature F"));

        TempPredictionData.DeleteAll();

        TempPredictionData.Init();
        TempPredictionData."Feature C" := 3;
        TempPredictionData.Insert();

        // [WHEN] Training is performed
        MLPredictionManagement.Train(Model, Quality);

        // [THEN] FlowField feature data is calculated correctly
        Assert.AreNotEqual('0', MLPredictionManagement.GetInput(1, 1), 'Feature FlowField is calculated incorrectly.');

        // [THEN] FlowField label data is calculated correctly
        Assert.AreNotEqual('0', MLPredictionManagement.GetInput(1, MLPredictionManagement.MaxNoFeatures() + 1),
          'Label FlowField is calculated incorrectly.');
    end;

    [Normal]
    local procedure InitLibraryAndData(var TempPredictionData: Record "Prediction Data" temporary; var MLPredictionManagement: Codeunit "ML Prediction Management"; ApiUri: Text[250]; AzureMLTask: Option; UseStdCredentials: Boolean)
    var
        HttpMessageHandler: DotNet MockHttpMessageHandler;
        ApiKey: Text[200];
    begin
        ApiKey := '';
        MLPredictionManagement.SetMessageHandler(HttpMessageHandler.MockHttpMessageHandler(GetResponseFileName(AzureMLTask)));

        if UseStdCredentials then
            MLPredictionManagement.InitializeWithKeyVaultCredentials(0)
        else
            MLPredictionManagement.Initialize(ApiUri, ApiKey, 0);
        MLPredictionManagement.SetRecord(TempPredictionData);
        MLPredictionManagement.AddFeature(TempPredictionData.FieldNo("Feature A"));
        MLPredictionManagement.AddFeature(TempPredictionData.FieldNo("Feature C"));
        MLPredictionManagement.AddFeature(TempPredictionData.FieldNo("Feature B"));
        MLPredictionManagement.SetLabel(TempPredictionData.FieldNo(Label));

        TempPredictionData.DeleteAll();

        TempPredictionData.Init();
        TempPredictionData."Not included" := 'K1';
        TempPredictionData."Feature A" := 1.2;
        TempPredictionData."Feature B" := TempPredictionData."Feature B"::Option2;
        TempPredictionData."Feature C" := 2;
        TempPredictionData.Label := false;
        TempPredictionData.Insert();

        TempPredictionData.Init();
        TempPredictionData."Not included" := 'K2';
        TempPredictionData."Feature A" := 3.2;
        TempPredictionData."Feature B" := TempPredictionData."Feature B"::Option1;
        TempPredictionData."Feature C" := 23;
        TempPredictionData.Label := false;
        TempPredictionData.Insert();
    end;

    local procedure GetTrainingFileName(): Text
    begin
        exit('\App\Test\Files\AzureMLResponse\Training.txt');
    end;

    local procedure GetPredictionFileName(): Text
    begin
        exit('\App\Test\Files\AzureMLResponse\Prediction.txt');
    end;

    local procedure GetEvaluationFileName(): Text
    begin
        exit('\App\Test\Files\AzureMLResponse\Evaluation.txt');
    end;

    local procedure GetErrorFileName(): Text
    begin
        exit('\App\Test\Files\AzureMLResponse\Error.txt');
    end;

    local procedure GetPlotFileName(): Text
    begin
        exit('\App\Test\Files\AzureMLResponse\Plot.txt');
    end;

    local procedure GetResponseFileName(Task: Option): Text
    begin
        case Task of
            AzureMLTask::Prediction:
                exit(LibraryUtilityOnPrem.GetInetRoot() + GetPredictionFileName());
            AzureMLTask::Training:
                exit(LibraryUtilityOnPrem.GetInetRoot() + GetTrainingFileName());
            AzureMLTask::Evaluation:
                exit(LibraryUtilityOnPrem.GetInetRoot() + GetEvaluationFileName());
            AzureMLTask::Error:
                exit(LibraryUtilityOnPrem.GetInetRoot() + GetErrorFileName());
            AzureMLTask::Plot:
                exit(LibraryUtilityOnPrem.GetInetRoot() + GetPlotFileName());
        end;
    end;

    local procedure EnsureThatMockDataIsFetchedFromKeyVault()
    var
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        TimeSeriesParams: Text;
    begin
        TimeSeriesParams := '{"ApiKeys":["test"],"Limit":"10","ApiUris":["https://services.azureml.net/workspaces/fc0584f5f74a4aa19a55096fc8ebb2b7"]}'; // non-existing API URI

        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping(StrSubstNo('machinelearning-%1', TenantId()), TimeSeriesParams);
        MockAzureKeyvaultSecretProvider.AddSecretMapping('machinelearning', TimeSeriesParams);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
    end;

    local procedure CreatePredictionDataWithOnlyLabel(var FeatureLabelData: Record "Feature Label Data"; Label: Code[10]; "Count": Integer)
    var
        LastKey: Code[10];
        I: Integer;
    begin
        for I := 1 to Count do begin
            FeatureLabelData.Init();
            if FeatureLabelData.FindLast() then
                LastKey := FeatureLabelData."Not Included"
            else
                LastKey := 'KEY0000000';
            FeatureLabelData."Not Included" := IncStr(LastKey);
            FeatureLabelData.Label := Label;
            FeatureLabelData.Insert();
        end;
    end;

    local procedure GetTrainedModel() Model: Text
    var
        ModelFile: File;
        ModelStream: InStream;
    begin
        ModelFile.Open(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\Prediction\model.txt');
        ModelFile.CreateInStream(ModelStream);
        ModelStream.ReadText(Model);
    end;
}

