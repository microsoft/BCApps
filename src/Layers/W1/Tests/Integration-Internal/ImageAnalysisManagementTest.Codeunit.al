codeunit 135206 "Image Analysis Management Test"
{
    Permissions = TableData "Azure AI Usage" = rimd;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Image Analysis]
    end;

    var
        AzureAIUsage: Record "Azure AI Usage";
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        HttpMessageHandler: DotNet MockHttpMessageHandler;
        SetMediaErr: Label 'There was a problem uploading the image file. Please try again.';
        UnauthorizedErr: Label 'Could not contact the Computer Vision API. Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription. Status code: Unauthorized.';
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        UnauthorizedForCustomVisionErr: Label 'Could not contact the Custom Vision Service. Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription. Status code: Unauthorized.';
        TooManyCallsErr: Label 'Sorry, you''ll have to wait until the start of the next hour. You can analyze 0 images per hour, and you''ve already hit the limit.';
        KeyvaultValueTxt: Label '[{"key":"%1","endpoint":"%2","limittype":"%3","limitvalue":"%4"}]';
        MissingImageAnalysisSecretErr: Label 'There is a missing configuration value on our end. Try again later.';
        GenericErrorErr: Label 'There was an error in contacting the Computer Vision API. Please try again or contact an administrator.';
        ChangingLimitAfterInitErr: Label 'You cannot change the limit setting after initialization.';
        LimitType: Option Year,Month,Day,Hour;

    [Test]
    [Scope('OnPrem')]
    procedure TestAnalyzeTags()
    var
        Item: Record Item;
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        HttpRequestMessage: DotNet HttpRequestMessage;
        HttpRequestHeaders: DotNet HttpRequestHeaders;
        Result: Boolean;
        MessageTxt: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] Image Analysis is invoked on a proper image

        // [GIVEN] An Item with an image
        ImageAnalysisSetup.DeleteAll();
        AzureAIUsage.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        InitializeMockKeyvault('fakekey', 'https://fakeuri', '1000', 'Hour');
        LibraryInventory.CreateItem(Item);
        Item.Picture.ImportFile(GetImagePath(), 'Description');

        LibraryLowerPermissions.SetO365Basic();

        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetMedia(Item.Picture.Item(1));
        HttpMessageHandler := HttpMessageHandler.MockHttpMessageHandler(GetImageAnalysisTagsResponsePath());
        ImageAnalysisManagement.SetHttpMessageHandler(HttpMessageHandler);

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The request contains the right key header
        HttpRequestMessage := HttpMessageHandler.RequestMessage;
        HttpRequestHeaders := HttpRequestMessage.Headers;
        HttpRequestHeaders.GetValues('Ocp-Apim-Subscription-Key'); // Will throw if not present

        // [THEN] The analysis is successful
        ImageAnalysisManagement.GetLastError(MessageTxt, IsUsageLimitError);
        Assert.IsTrue(Result, 'Analysis failed. Error is ' + MessageTxt);

        // [THEN] The correct number and type of tags are found
        Assert.AreEqual(4, ImageAnalysisResult.TagCount(), 'Wrong number of tags found.');
        Assert.AreEqual('seat', ImageAnalysisResult.TagName(2), 'Wrong name of tag found.');
        Assert.AreEqual(0.998513400554657, ImageAnalysisResult.TagConfidence(1), 'Wrong confidence of tag found.');

        CheckTagsEmpty(ImageAnalysisResult);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAnalyzeTagsForCustomVision()
    var
        Item: Record Item;
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        HttpRequestMessage: DotNet HttpRequestMessage;
        HttpRequestHeaders: DotNet HttpRequestHeaders;
        Result: Boolean;
        MessageTxt: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] Custom Image Analysis is invoked on a proper image if URI is set

        // [GIVEN] An Item with an image
        ImageAnalysisSetup.DeleteAll();
        AzureAIUsage.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', 'https://fakeuri/customvision/', '1000', 'Hour');
        LibraryInventory.CreateItem(Item);
        LibraryLowerPermissions.SetO365Basic();
        Item.Picture.ImportFile(GetImagePath(), 'Description');

        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetMedia(Item.Picture.Item(1));
        HttpMessageHandler := HttpMessageHandler.MockHttpMessageHandler(GetCustomImageAnalysisTagsResponsePath());
        ImageAnalysisManagement.SetHttpMessageHandler(HttpMessageHandler);

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The request contains the right key header
        HttpRequestMessage := HttpMessageHandler.RequestMessage;
        HttpRequestHeaders := HttpRequestMessage.Headers;
        HttpRequestHeaders.GetValues('Prediction-Key'); // Will throw if not present

        // [THEN] The analysis is successful
        ImageAnalysisManagement.GetLastError(MessageTxt, IsUsageLimitError);
        Assert.IsTrue(Result, 'Analysis failed. Error is ' + MessageTxt);

        // [THEN] The correct number and type of tags are found
        Assert.AreEqual('Hemlock', ImageAnalysisResult.TagName(2), 'Wrong name of tag found.');
        Assert.AreEqual(2, ImageAnalysisResult.TagCount(), 'Wrong number of tags found.');
        Assert.AreEqual(1.0, ImageAnalysisResult.TagConfidence(1), 'Wrong confidence of tag found.');

        CheckTagsEmpty(ImageAnalysisResult);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAnalyzeTagsForCustomVisionV2()
    var
        Item: Record Item;
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        HttpRequestMessage: DotNet HttpRequestMessage;
        HttpRequestHeaders: DotNet HttpRequestHeaders;
        Result: Boolean;
        MessageTxt: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] Custom Image Analysis V2 is invoked on a proper image if URI is set

        // [GIVEN] An Item with an image
        ImageAnalysisSetup.DeleteAll();
        AzureAIUsage.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', 'https://fakeuri/customvision/', '1000', 'Hour');
        LibraryInventory.CreateItem(Item);
        LibraryLowerPermissions.SetO365Basic();
        Item.Picture.ImportFile(GetImagePath(), 'Description');

        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetMedia(Item.Picture.Item(1));
        HttpMessageHandler := HttpMessageHandler.MockHttpMessageHandler(GetCustomImageAnalysisTagsResponsePathV2());
        ImageAnalysisManagement.SetHttpMessageHandler(HttpMessageHandler);

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The request contains the right key header
        HttpRequestMessage := HttpMessageHandler.RequestMessage;
        HttpRequestHeaders := HttpRequestMessage.Headers;
        HttpRequestHeaders.GetValues('Prediction-Key'); // Will throw if not present

        // [THEN] The analysis is successful
        ImageAnalysisManagement.GetLastError(MessageTxt, IsUsageLimitError);
        Assert.IsTrue(Result, 'Analysis failed. Error is ' + MessageTxt);

        // [THEN] The correct number and type of tags are found
        Assert.AreEqual('Hemlock', ImageAnalysisResult.TagName(2), 'Wrong name of tag found.');
        Assert.AreEqual(2, ImageAnalysisResult.TagCount(), 'Wrong number of tags found.');
        Assert.AreEqual(1.0, ImageAnalysisResult.TagConfidence(1), 'Wrong confidence of tag found.');

        CheckTagsEmpty(ImageAnalysisResult);
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure CheckTagsEmpty(ImageAnalysisResult: Codeunit "Image Analysis Result")
    var
        AzureAIUsageCodeunit: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
    begin
        // [THEN] No error is raised if wrong tag number is used
        Assert.AreEqual('', ImageAnalysisResult.TagName(5), 'Wrong tag name returned.');
        Assert.AreEqual(0, ImageAnalysisResult.TagConfidence(5), 'Wrong tag confidence returned.');

        // [THEN] The correct colors are returned
        Assert.AreEqual('', ImageAnalysisResult.DominantColorForeground(), 'Wrong dominant foreground color found.');
        Assert.AreEqual('', ImageAnalysisResult.DominantColorBackground(), 'Wrong dominant background color found.');
        Assert.AreEqual(0, ImageAnalysisResult.DominantColorCount(), 'Wrong number of dominant colors found.');

        // [THEN] No error is raised if wrong color number is used
        Assert.AreEqual('', ImageAnalysisResult.DominantColor(3), 'Wrong color returned.');
#if not CLEAN25
        // [THEN] The correct number of faces are found
        Assert.AreEqual(0, ImageAnalysisResult.FaceCount(), 'Wrong number of faces found.');

        // [THEN] No error is raised if wrong face number is used
        Assert.AreEqual('', ImageAnalysisResult.FaceGender(1), 'Wrong face gender returned.');
        Assert.AreEqual(0, ImageAnalysisResult.FaceAge(1), 'Wrong face gender returned.');
#endif

        // [THEN] The usage count is incremented
        Assert.AreEqual(
          1, AzureAIUsageCodeunit.GetTotalProcessingTime(AzureAIService::"Computer Vision"),
          'Number of calls not incremented.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAnalyzeColors()
    var
        Item: Record Item;
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        AzureAIUsageCodeunit: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
        Result: Boolean;
        MessageTxt: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] Image Analysis is invoked on a proper image

        // [GIVEN] An Item with an image
        ImageAnalysisSetup.DeleteAll();
        AzureAIUsage.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        LibraryInventory.CreateItem(Item);
        Item.Picture.ImportFile(GetImagePath(), 'Description');
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '1000', 'Hour');

        LibraryLowerPermissions.SetO365Basic();

        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetMedia(Item.Picture.Item(1));
        ImageAnalysisManagement.SetHttpMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(GetImageAnalysisColorResponsePath()));

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeColors(ImageAnalysisResult);

        // [THEN] The analysis is successful
        ImageAnalysisManagement.GetLastError(MessageTxt, IsUsageLimitError);
        Assert.IsTrue(Result, 'Analysis failed. Error is ' + MessageTxt);

        // [THEN] The correct number and type of tags are found
        Assert.AreEqual(0, ImageAnalysisResult.TagCount(), 'Wrong number of tags found.');

        // [THEN] No error is raised if wrong tag number is used
        Assert.AreEqual('', ImageAnalysisResult.TagName(5), 'Wrong tag name returned.');
        Assert.AreEqual(0, ImageAnalysisResult.TagConfidence(5), 'Wrong tag confidence returned.');

        // [THEN] The correct colors are returned
        Assert.AreEqual('White', ImageAnalysisResult.DominantColorForeground(), 'Wrong dominant foreground color found.');
        Assert.AreEqual('White', ImageAnalysisResult.DominantColorBackground(), 'Wrong dominant background color found.');
        Assert.AreEqual(2, ImageAnalysisResult.DominantColorCount(), 'Wrong number of dominant colors found.');
        Assert.AreEqual('Blue', ImageAnalysisResult.DominantColor(2), 'Wrong dominant color found.');

        // [THEN] No error is raised if wrong color number is used
        Assert.AreEqual('', ImageAnalysisResult.DominantColor(3), 'Wrong color returned.');
#if not CLEAN25
        // [THEN] The correct number of faces are found
        Assert.AreEqual(0, ImageAnalysisResult.FaceCount(), 'Wrong number of faces found.');

        // [THEN] No error is raised if wrong face number is used
        Assert.AreEqual('', ImageAnalysisResult.FaceGender(1), 'Wrong face gender returned.');
        Assert.AreEqual(0, ImageAnalysisResult.FaceAge(1), 'Wrong face gender returned.');
#endif

        // [THEN] The usage count is incremented
        Assert.AreEqual(
          1, AzureAIUsageCodeunit.GetTotalProcessingTime(AzureAIService::"Computer Vision"),
          'Number of calls not incremented.');
    end;
#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    [Obsolete('Image analysis for face is being removed. There is no replacement.', '25.0')]
    procedure TestAnalyzeFaces()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        FileManagement: Codeunit "File Management";
    begin
        // [SCENARIO] Image Analysis is invoked on a proper image with a face

        // [GIVEN] A BLOB with an image of a face
        // Import needs to happen before setting to saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        FileManagement.BLOBImportFromServerFile(TempBlob, GetFaceImagePath());
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '1000', 'Hour');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryLowerPermissions.SetO365Basic();

        ImageAnalysisManagement.Initialize();

        ImageAnalysisManagement.SetBlob(TempBlob);
        ImageAnalysisManagement.SetHttpMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(GetFaceAnalysisResponsePath()));

        // [WHEN] Analyze is invoked
        ImageAnalysisManagement.AnalyzeFaces(ImageAnalysisResult);

        // [THEN] The correct face characteristics are found
        Assert.AreEqual(1, ImageAnalysisResult.FaceCount(), 'Wrong number of faces found.');
        Assert.AreEqual('Female', ImageAnalysisResult.FaceGender(1), 'Wrong gender of face found.');
        Assert.AreEqual(28, ImageAnalysisResult.FaceAge(1), 'Wrong age of face found.');
    end;

    [Test]
    [Scope('OnPrem')]
    [Obsolete('Image analysis for face is being removed. There is no replacement.', '25.0')]
    procedure TestAnalyzeFacesForMinors()
    var
        TempBlob: Codeunit "Temp Blob";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        FileManagement: Codeunit "File Management";
    begin
        // [SCENARIO] Image Analysis is invoked on a proper image with a face for a minor (< 16 years)

        // [GIVEN] A BLOB with an image of a face of a minor
        // This import needs to happen before setting to saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        FileManagement.BLOBImportFromServerFile(TempBlob, GetFaceImagePath());
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '1000', 'Hour');
        LibraryLowerPermissions.SetO365Basic();

        ImageAnalysisManagement.Initialize();

        ImageAnalysisManagement.SetBlob(TempBlob);
        ImageAnalysisManagement.SetHttpMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(GetFaceMinorAnalysisResponsePath()));

        // [WHEN] Analyze is invoked
        ImageAnalysisManagement.AnalyzeFaces(ImageAnalysisResult);

        // [THEN] The no face characteristics are found
        Assert.AreEqual(1, ImageAnalysisResult.FaceCount(), 'Wrong number of faces found.');
        Assert.AreEqual('', ImageAnalysisResult.FaceGender(1), 'The gender may not be specified for a minor.');
        Assert.AreEqual(0, ImageAnalysisResult.FaceAge(1), 'The age may not be specified for a minor.');
    end;
#endif

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestWrongMediaId()
    var
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
    begin
        // [SCENARIO] Image analysis is attempted given invalid Media ID

        // [GIVEN]

        // [WHEN] Media is set
        asserterror ImageAnalysisManagement.SetMedia('CDEF7890-ABCD-0123-1234-567890ABCDEF');

        // [THEN] The correct error is thrown
        Assert.ExpectedError(SetMediaErr);
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestHandleHttpError()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        Result: Boolean;
        ErrorValue: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] An HTTP error is returned from Cognitive Services

        // [GIVEN] An image to analyse and initialization with a wrong key
        // This import needs to happen before setting to saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        FileManagement.BLOBImportFromServerFile(TempBlob, GetImagePath());
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '1000', 'Hour');

        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetBlob(TempBlob);

        ImageAnalysisManagement.SetHttpMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(GetImageAnalysisErrorResponsePath()));

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The correct error is set
        Assert.IsFalse(Result, 'Analysis should have failed.');
        Result := ImageAnalysisManagement.GetLastError(ErrorValue, IsUsageLimitError);
        Assert.IsFalse(IsUsageLimitError, 'Did not expect a usage limit error.');
        Assert.AreEqual(UnauthorizedErr, ErrorValue, 'Expected the last error to be Unauthorized error.');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestHandleHttpErrorForCustomVision()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        Result: Boolean;
        ErrorValue: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] An HTTP error is returned from the Custom Vision Service

        // [GIVEN] An image to analyse and initialization with a wrong key
        // This import needs to happen before setting to saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        FileManagement.BLOBImportFromServerFile(TempBlob, GetImagePath());
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', 'https://fakeuri/customvision/', '1000', 'Hour');
        ImageAnalysisManagement.Initialize();

        ImageAnalysisManagement.SetBlob(TempBlob);

        ImageAnalysisManagement.SetHttpMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(GetCustomImageAnalysisErrorResponsePath()));

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The correct error is set
        Assert.IsFalse(Result, 'Analysis should have failed.');
        Result := ImageAnalysisManagement.GetLastError(ErrorValue, IsUsageLimitError);
        Assert.IsFalse(IsUsageLimitError, 'Did not expect a usage limit error.');
        Assert.AreEqual(UnauthorizedForCustomVisionErr, ErrorValue, 'Expected the last error to be Unauthorized error.');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestHandleGenericError()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        Result: Boolean;
        ErrorValue: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] A .NET error is thrown, but is not surfaced

        // [GIVEN] An image to analyse and initialization with a wrong key
        ImageAnalysisSetup.DeleteAll();
        AzureAIUsage.DeleteAll();

        // This import needs to happen before setting to saas
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        FileManagement.BLOBImportFromServerFile(TempBlob, GetImagePath());
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', '!!malformed', '1000', 'Hour');
        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetBlob(TempBlob);

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The correct error is set
        Assert.IsFalse(Result, 'Analysis should have failed.');
        Result := ImageAnalysisManagement.GetLastError(ErrorValue, IsUsageLimitError);
        Assert.IsFalse(IsUsageLimitError, 'Did not expect a usage limit error.');
        Assert.AreEqual(GenericErrorErr, ErrorValue, 'Expected the last error to be a generic error.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHandleEmptyKeyvault()
    var
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
    begin
        // [SCENARIO] Initialize with missing values in the keyvault

        // [GIVEN] The limit is missing
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryLowerPermissions.SetO365Basic();
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '', 'Hour');

        // [WHEN] Initialize is invoked
        asserterror ImageAnalysisManagement.Initialize();

        // [THEN] The correct error is thrown
        Assert.ExpectedError(MissingImageAnalysisSecretErr);

        Clear(ImageAnalysisManagement);

        // [GIVEN] The limit type is missing
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '5', '');

        // [WHEN] Initialize is invoked
        asserterror ImageAnalysisManagement.Initialize();

        // [THEN] The correct error is thrown
        Assert.ExpectedError(MissingImageAnalysisSecretErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHandleTooManyCallsError()
    var
        Item: Record Item;
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        ImageAnalysisResult: Codeunit "Image Analysis Result";
        Result: Boolean;
        ErrorValue: Text;
        IsUsageLimitError: Boolean;
    begin
        // [SCENARIO] Image Analysis returns an error on too many calls

        // [GIVEN] An Item with an image
        LibraryInventory.CreateItem(Item);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        Item.Picture.ImportFile(GetImagePath(), 'Description');
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '0', 'Hour');

        LibraryLowerPermissions.SetO365Basic();

        ImageAnalysisManagement.Initialize();
        ImageAnalysisManagement.SetMedia(Item.Picture.Item(1));
        ImageAnalysisManagement.SetHttpMessageHandler(
          HttpMessageHandler.MockHttpMessageHandler(GetImageAnalysisTagsResponsePath()));

        // [WHEN] Analyze is invoked
        Result := ImageAnalysisManagement.AnalyzeTags(ImageAnalysisResult);

        // [THEN] The correct error is set
        Assert.IsFalse(Result, 'Analysis should have failed.');
        Result := ImageAnalysisManagement.GetLastError(ErrorValue, IsUsageLimitError);
        Assert.IsTrue(IsUsageLimitError, 'Did not expect a usage limit error.');
        Assert.AreEqual(TooManyCallsErr, ErrorValue, 'Expected the last error to be TooManyCallsErr.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetLimitAfterInit()
    var
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
    begin
        // [SCENARIO] Set a value for the limit after initializing should throw an error
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] ImageAnalysisManagement is Initialized
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '3', 'Hour');
        ImageAnalysisManagement.Initialize();

        // [WHEN] SetLimit functions are called
        // [THEN] An error is raised
        asserterror ImageAnalysisManagement.SetLimitInDays(3);
        Assert.ExpectedError(ChangingLimitAfterInitErr);
        asserterror ImageAnalysisManagement.SetLimitInHours(3);
        Assert.ExpectedError(ChangingLimitAfterInitErr);
        asserterror ImageAnalysisManagement.SetLimitInMonths(3);
        Assert.ExpectedError(ChangingLimitAfterInitErr);
        asserterror ImageAnalysisManagement.SetLimitInYears(3);
        Assert.ExpectedError(ChangingLimitAfterInitErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLimitIsNeverSetWithCustomUri()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        Value: Integer;
        Type: Option;
        ApiKey: Text;
    begin
        // [SCENARIO] For Custom Uri not set Limit means Unlimited
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] A custom uri and key are provided but the limit is not set
        ImageAnalysisManagement.SetUriAndKey('some uri', GetKey());

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();

        // [THEN] The Limit is set to 999 Years
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Year, 'Limit Type was expected to be Year');
        Assert.AreEqual(Value, 999, 'Limit Value was expected to be 999');

        Clear(ImageAnalysisManagement);

        // [GIVEN] A custom uri and key are provided but the limit is not set
        ImageAnalysisSetup.Get();
        ImageAnalysisSetup."Api Uri" := 'some uri';
        ApiKey := 'some key';
        ImageAnalysisSetup.SetApiKey(ApiKey);
        ImageAnalysisSetup.Modify();

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();

        // [THEN] The Limit is set to 999 Years
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Year, 'Limit Type was expected to be Year');
        Assert.AreEqual(Value, 999, 'Limit Value was expected to be 999');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetLimitWithoutCustomUri()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        Value: Integer;
        Type: Option;
    begin
        // [SCENARIO] For Custom Uri not set Limit means Unlimited
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] No uri and key have been specified
        ImageAnalysisSetup.DeleteAll();
        AzureAIUsage.DeleteAll();

        // [GIVEN] The Limit is set up to 10 years
        ImageAnalysisManagement.SetLimitInYears(10);

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();
        InitializeMockKeyvault('fakekey', 'https://fakeuri', '3', 'Hour');

        // [THEN] The Limit value comes from key vault
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Hour, 'Limit Type was expected to be Hour');
        Assert.AreEqual(Value, 3, 'Limit Value was expected to be 3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetLimitWithCustomUri()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        Value: Integer;
        Type: Option;
    begin
        // [SCENARIO] For Custom Uri developer can set his own Limit through API
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryLowerPermissions.SetO365Basic();

        // [GIVEN] No uri and key have been specified
        ImageAnalysisSetup.DeleteAll();

        // [GIVEN] A custom uri and key are provided but the limit is not set
        ImageAnalysisManagement.SetUriAndKey('some uri', GetKey());

        // [GIVEN] The Limit is set up to 10 years
        ImageAnalysisManagement.SetLimitInYears(10);
        // [THEN] Negative values are ignored
        ImageAnalysisManagement.SetLimitInYears(-1);

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();

        // [THEN] The Limit value comes from key vault
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Year, 'Limit Type was expected to be Year');
        Assert.AreEqual(Value, 10, 'Limit Value was expected to be 10');

        Clear(ImageAnalysisManagement);

        // [GIVEN] A custom uri and key are provided but the limit is not set
        ImageAnalysisManagement.SetUriAndKey('some uri', GetKey());

        // [GIVEN] The Limit is set up to 10 Months
        ImageAnalysisManagement.SetLimitInMonths(10);
        // [THEN] Negative values are ignored
        ImageAnalysisManagement.SetLimitInMonths(-1);

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();

        // [THEN] The Limit value comes from key vault
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Month, 'Limit Type was expected to be Month');
        Assert.AreEqual(Value, 10, 'Limit Value was expected to be 10');

        Clear(ImageAnalysisManagement);

        // [GIVEN] A custom uri and key are provided but the limit is not set
        ImageAnalysisManagement.SetUriAndKey('some uri', GetKey());

        // [GIVEN] The Limit is set up to 10 Days
        ImageAnalysisManagement.SetLimitInDays(10);
        // [THEN] Negative values are ignored
        ImageAnalysisManagement.SetLimitInDays(-1);

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();

        // [THEN] The Limit value comes from key vault
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Day, 'Limit Type was expected to be Day');
        Assert.AreEqual(Value, 10, 'Limit Value was expected to be 10');

        Clear(ImageAnalysisManagement);

        // [GIVEN] A custom uri and key are provided but the limit is not set
        ImageAnalysisManagement.SetUriAndKey('some uri', GetKey());

        // [GIVEN] The Limit is set up to 10 Hours
        ImageAnalysisManagement.SetLimitInHours(10);
        // [THEN] Negative values are ignored
        ImageAnalysisManagement.SetLimitInHours(-1);

        // [WHEN] The Library is initialized
        ImageAnalysisManagement.Initialize();

        // [THEN] The Limit value comes from key vault
        ImageAnalysisManagement.GetLimitParams(Type, Value);
        Assert.AreEqual(Type, LimitType::Hour, 'Limit Type was expected to be Hour');
        Assert.AreEqual(Value, 10, 'Limit Value was expected to be 10');
    end;

    local procedure GetKey(): SecretText
    var
        ApiKey: Text;
    begin
        ApiKey := 'some key';
        exit(ApiKey);
    end;

    [Normal]
    local procedure GetImagePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\AllowedImage.jpg');
    end;
#if not CLEAN25
    [Normal]
    [Obsolete('Image analysis for face is being removed. There is no replacement.', '25.0')]
    local procedure GetFaceImagePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\Debra Core.jpg');
    end;
#endif

    [Normal]
    local procedure GetImageAnalysisColorResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\ImageAnalysisColorResponse.txt');
    end;

    [Normal]
    local procedure GetImageAnalysisTagsResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\ImageAnalysisTagsResponse.txt');
    end;

    [Normal]
    local procedure GetCustomImageAnalysisTagsResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\CustomImageAnalysisTagsResponse.txt');
    end;

    [Normal]
    local procedure GetCustomImageAnalysisTagsResponsePathV2(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\CustomImageAnalysisTagsResponseV2.txt');
    end;

    [Normal]
    local procedure GetCustomImageAnalysisErrorResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\CustomImageAnalysisErrorResponse.txt');
    end;

    [Normal]
    local procedure GetImageAnalysisErrorResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\ImageAnalysisErrorResponse.txt');
    end;
#if not CLEAN25
    [Normal]
    [Obsolete('Image analysis for face is being removed. There is no replacement.', '25.0')]
    local procedure GetFaceAnalysisResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\FaceImageAnalysisResponse.txt');
    end;

    [Normal]
    [Obsolete('Image analysis for face is being removed. There is no replacement.', '25.0')]
    local procedure GetFaceMinorAnalysisResponsePath(): Text
    begin
        exit(LibraryUtilityOnPrem.GetInetRoot() + '\App\Test\Files\ImageAnalysis\FaceMinorImageAnalysisResponse.txt');
    end;
#endif

    local procedure InitializeMockKeyvault(ApiKey: Text; ApiEndpoint: Text; ImageAnalysisLimit: Text; ImageAnalysisPeriodType: Text)
    var
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
    begin
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping(
          'cognitive-vision-params', StrSubstNo(KeyvaultValueTxt, ApiKey, ApiEndpoint, ImageAnalysisPeriodType, ImageAnalysisLimit));

        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
    end;
}

