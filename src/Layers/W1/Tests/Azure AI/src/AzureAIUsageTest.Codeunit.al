codeunit 135205 "Azure AI Usage Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [Feature] [Azure AI Usage Service Usage]
        // Tests for codeunit Azure AI Service
    end;

    var
        Assert: Codeunit Assert;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        AzureAIUsageLibrary: Codeunit "Azure AI Usage Library";
        AzureAIService: Enum "Azure AI Service";
        LimitPeriod: Option Year,Month,Day,Hour;
        ProcessingTimeLessThanZeroErr: Label 'The available Azure Machine Learning processing time is less than or equal to zero.';
        CannotSetInfiniteAccessErr: Label 'Cannot set infinite access for user''s own service because the API key or API URI is empty.';

    [Test]
    procedure TestSetInfiniteImageAnalysisAccess()
    var
        AzureAIUsageImpl: Codeunit "Azure AI Usage Impl.";
        ImageAnalysisSetupRec: Record "Image Analysis Setup";
        AzureAIUsageRec: Record "Azure AI Usage";
    begin
        // [Scenario] Test setting infinite image analysis access.
        // [NOTE] This test is the unit test for the function SetInfiniteImageAnalysisAccess in Azure AI Usage Impl, because it is used internal.  
        Initialize();

        // [Given] Initiate Image Analysis Setup
        ImageAnalysisSetupRec.DeleteAll();
        ImageAnalysisSetupRec.Init();
        ImageAnalysisSetupRec.Insert();

        // [When] Setting infinite access without API key and API URI
        asserterror AzureAIUsageImpl.SetInfiniteImageAnalysisAccess(ImageAnalysisSetupRec);
        // [Then] An error is thrown
        Assert.ExpectedError(CannotSetInfiniteAccessErr);

        // [Given] Setting API URI for ImageAnalysisSetupRec
        ImageAnalysisSetupRec.GetSingleInstance();
        ImageAnalysisSetupRec.Validate("Api Uri", 'https://api.cognitive.microsoft.com/vision/v1.0/analyze');

        // [When] Setting infinite access without API key
        asserterror AzureAIUsageImpl.SetInfiniteImageAnalysisAccess(ImageAnalysisSetupRec);
        // [Then] An error is thrown
        Assert.ExpectedError(CannotSetInfiniteAccessErr);

        // [Given] Setting API URI for ImageAnalysisSetupRec
        ImageAnalysisSetupRec.SetApiKey(SecretText.SecretStrSubstNo('1234567890'));

        // [When] Setting infinite access with API key and API URI
        // [Then] No error is thrown
        AzureAIUsageImpl.SetInfiniteImageAnalysisAccess(ImageAnalysisSetupRec);

        // [When] Setting infinite access successfully
        // [Then] The limit period is set to Year and the resource limit is set to 999.0
        Assert.AreEqual(999.0, AzureAIUsageImpl.GetResourceLimit(AzureAIService::"Computer Vision"), 'Total limit time for Computer Vision should be 999.0');
        Assert.AreEqual(AzureAIUsageRec."Limit Period"::Year, AzureAIUsageImpl.GetLimitPeriod(AzureAIService::"Computer Vision"), 'Limit period for Computer Vision should be Year');
    end;

    [Test]
    procedure IncrementTotalProcessingTimeInvalidTime()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
    begin
        // [Scenario] Increamenting the processing time with negative value throws an error 
        Initialize();

        asserterror AzureAIUsage.IncrementTotalProcessingTime(AzureAIService::"Computer Vision", -10);
        Assert.ExpectedError(ProcessingTimeLessThanZeroErr);

        asserterror AzureAIUsage.IncrementTotalProcessingTime(AzureAIService::"Machine Learning", -42);
        Assert.ExpectedError(ProcessingTimeLessThanZeroErr);
    end;

    [Test]
    procedure IncrementTotalProcessingTimeDifferentService()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        Now: DateTime;
    begin
        // [Scenario] Incrementing the processing time of a service does not change the processing time of other services
        Initialize();
        Now := CurrentDateTime();

        // [Given] Entries for both Computer Vision and Machine Learning
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Computer Vision", 100, 1000, 0, Now);
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20, 30, 1, Now);

        Assert.AreEqual(100, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Computer Vision"), 'Wrong total processing time for Computer Vision');
        Assert.AreEqual(20, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'Wrong total processing time for Machine Learning');

        // [When] Incrementing the processing time of Computer Vision
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIService::"Computer Vision", 10);

        // [Then] Only the value for Computer Vision is changed
        Assert.AreEqual(110, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Computer Vision"), 'Wrong total processing time for Computer Vision');
        Assert.AreEqual(20, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'Wrong total processing time for Machine Learning');
    end;

    [Test]
    procedure IncrementTotalProcessingTimeNonExistingService()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        Now: DateTime;
    begin
        // [Scenario] When incrementing the processing time for a service that do not exist, the entry is vreated

        Initialize();
        Now := CurrentDateTime();

        // [Given] Entries for Machine Learning only
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20.5, 30, 1, Now);

        Assert.AreEqual(0.0, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Computer Vision"), 'Total processing time for Computer Vision should be 0.0');
        Assert.AreEqual(20.5, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'Wrong total processing time for Machine Learning');

        // [When] Incrementing the processing time of Computer Vision (that does not exist)
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIService::"Computer Vision", 10);

        // [Then] Only the value for Computer Vision is changed
        Assert.AreEqual(10, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Computer Vision"), 'Wrong total processing time for Computer Vision');
        Assert.AreEqual(20.5, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'Wrong total processing time for Machine Learning');
    end;

    [Test]
    procedure IsLimitReachedNonExistingService()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
    begin
        // [Scenario] When checking if the limit was reached on a non existing service, the function returns false.
        Initialize();

        // [Given] No entries

        // [When] Checking if the limit was reached for Computer Vision (that does not exist)
        Assert.IsFalse(AzureAIUsage.IsLimitReached(AzureAIService::"Computer Vision", 1000), 'The limit of a non-existing service should be reached');

        // [Then] The result should be 'false'
    end;

    [Test]
    procedure IsLimitReachedReturnsFalse()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        Now: DateTime;
    begin
        // [Scenario] When checking if the limit was reached, the function returns false if the limit was not reached.
        Initialize();
        Now := CurrentDateTime();

        // [Given] Entries for Machine Learning only
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20.5, 30, LimitPeriod::Month, Now);

        // [When] Checking if the limit was reached for Machine Learning
        Assert.IsFalse(AzureAIUsage.IsLimitReached(AzureAIService::"Machine Learning", 1000), 'The limit for Machine Learning should not be reached');

        // [Then] The result should be 'false'
    end;

    [Test]
    procedure IsLimitReachedReturnsTrue()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        Now: DateTime;
    begin
        // [Scenario] When checking if the limit was reached, the function returns true if the limit was reached.
        Initialize();
        Now := CurrentDateTime();

        // [Given] Entries for Machine Learning only
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20.5, 30, 1, Now);

        // [When] Checking if the limit was reached for Machine Learning
        Assert.IsTrue(AzureAIUsage.IsLimitReached(AzureAIService::"Machine Learning", 10), 'The limit for Machine Learning should be reached');

        // [Then] The result should be 'true'
    end;

    [Test]
    procedure ProcessingTimeIsResetIfChangedDay()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        Now: DateTime;
        Yesterday: DateTime;
    begin
        // [Scenario] The processing time is reset if it's new period (day)
        Initialize();
        Now := CurrentDateTime();
        Yesterday := CreateDateTime(CalcDate('<-1D>', DT2Date(Now)), DT2Time(Now));

        // [Given] Entries for Machine Learning only
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20.5, 30, LimitPeriod::Day, Yesterday);

        // [When] Checking the processing time
        Assert.AreEqual(0.0, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'The processing time for Machine Learning was not reset.');

        // [Then] The processing time was reset to 0.0
    end;

    [Test]
    procedure ProcessingTimeIsResetIfChangedMonth()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIUsageMocks: Codeunit "Azure AI Usage Mocks";
        Now: DateTime;
        LastMonth: DateTime;
    begin
        // [Scenario] The processing time is reset if it's new period (month)
        Initialize();
        BindSubscription(AzureAIUsageMocks);

        Now := CurrentDateTime();
        LastMonth := CreateDateTime(CalcDate('<-1M>', DT2Date(Now)), DT2Time(Now));
        AzureAIUsageMocks.SetCurrentDateTime(Now);

        // [Given] Entries for Machine Learning only
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20.5, 30, LimitPeriod::Month, LastMonth);

        // [When] Checking the processing time
        Assert.AreEqual(0.0, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'The processing time for Machine Learning was not reset.');

        // [Then] The processing time was reset to 0.0

        // Tear down
        UnbindSubscription(AzureAIUsageMocks);
    end;

    [Test]
    procedure ProcessingTimeIsResetIfChangedYear()
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        Now: DateTime;
        LastYear: DateTime;
    begin
        // [Scenario] The processing time is reset if it's new period (year)
        Initialize();
        Now := CurrentDateTime();
        LastYear := CreateDateTime(CalcDate('<-1Y>', DT2Date(Now)), DT2Time(Now));

        // [Given] Entries for Machine Learning only
        AzureAIUsageLibrary.InsertEntry(AzureAIService::"Machine Learning", 20.5, 30, LimitPeriod::Year, LastYear);

        // [When] Checking the processing time
        Assert.AreEqual(0.0, AzureAIUsage.GetTotalProcessingTime(AzureAIService::"Machine Learning"), 'The processing time for Machine Learning was not reset.');

        // [Then] The processing time was reset to 0.0
    end;

    local procedure Initialize()
    begin
        AzureAIUsageLibrary.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
    end;

}