codeunit 135215 "Item From Picture Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Image Analysis Scenario" = RIMD,
                  tabledata "Azure AI Usage" = RMID,
                  tabledata "Feature Key" = RM,
                  tabledata "Feature Data Update Status" = R;

    trigger OnRun()
    begin
        // [FEATURE] [Image Analysis] [Item From Picture]
    end;

    var
        Assert: Codeunit Assert;
        ItemFromPictureTests: Codeunit "Item From Picture Tests";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        TestTagsTxt: Label '[{"confidence": 0.996441006660461, "name": "appliance"}, {"confidence": 0.982585787773132, "name": "beaver"}, {"confidence": 0.9576775431633, "name": "kitchen appliance"}, {"confidence": 0.956994295120239, "name": "small appliance"}, {"confidence": 0.879383683204651, "name": "indoor"}, {"confidence": 0.8634113073349, "name": "mixer"}, {"confidence": 0.862547278404236, "name": "wall"}, {"confidence": 0.604613900184631, "name": "coffee maker"}]', Locked = true;
        IsInitialized: Boolean;
        Subscriber_ExpectImgAnalysisCall: Boolean;
        Subscriber_ExpectedUrl: Text;
        Subscriber_ReturnStatusCode: Integer;
        Subscriber_ReturnTags: Text;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleSetupNotification')]
    procedure PrivacyNoticeOff_NotificationAndNoAnalysis()
    var
        ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary;
        ItemFromPictureTestPage: TestPage "Item From Picture";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
    begin
        Init();
        ItemFromPictureTests.Subscriber_DontExpectImageAnalysisHttpCall();
        LibraryVariableStorage.Enqueue('Next time you open this page, we can prefill some information for you.');

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');

        CreateItemFromPictureBuffer(ItemFromPictureBuffer);
        ItemFromPictureTestPage.Trap();
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleSetupNotification,SetupWizardHandler')]
    procedure NoSetupOnPrem_NotificationAndNoAnalysis()
    var
        ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary;
        ImageAnalysisSetup: TestPage "Image Analysis Setup";
        ItemFromPictureTestPage: TestPage "Item From Picture";
        ItemFromPictureCodeunit: Codeunit "Item From Picture";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
        DummyNotif: Notification;
    begin
        Init();
        ImageAnalysisSetup.Trap();
        ItemFromPictureCodeunit.RunWizard(DummyNotif);
        ImageAnalysisSetup.Close();
        ItemFromPictureTests.Subscriber_DontExpectImageAnalysisHttpCall();
        LibraryVariableStorage.Enqueue('We could not analyze your image because of the following error: To analyze images, you must provide an API key and an API URI for Computer Vision.');

        CreateItemFromPictureBuffer(ItemFromPictureBuffer);

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');

        ItemFromPictureTestPage.Trap();
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SetupWizardHandler')]
    procedure NoSetupAndSaas_Successful()
    var
        ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ImageAnalysisSetup: TestPage "Image Analysis Setup";
        ItemFromPictureTestPage: TestPage "Item From Picture";
        ItemFromPictureCodeunit: Codeunit "Item From Picture";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
        DummyNotif: Notification;
    begin
        Init();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetupKeyVault();
        ImageAnalysisSetup.Trap();
        ItemFromPictureCodeunit.RunWizard(DummyNotif);
        ImageAnalysisSetup.Close();
        ItemFromPictureTests.Subscriber_ExpectImgAnalysisHttpCall(true, 200, TestTagsTxt, 'https://northeurope.api.cognitive.microsoft.com/vision/v3.2/analyze?language=en&visualFeatures=Tags');

        CreateItemFromPictureBuffer(ItemFromPictureBuffer);

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');

        ItemFromPictureTestPage.Trap();
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('BEAVER', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('PROFITABLE ITEM $$$', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');

        Assert.IsTrue(ItemFromPictureTestPage.Attributes.First(), 'No attribute!');
        Assert.AreEqual('Fur color', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.Next(), 'Only one attribute!');
        Assert.AreEqual('Number of legs', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('4', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        Assert.IsTrue(ItemFromPictureTestPage.Attributes.Next(), 'Only two attributes!'); // There seems to be an empty attribute here
        Assert.IsFalse(ItemFromPictureTestPage.Attributes.Next(), 'More than three attributes!');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidSetup_NoTags()
    var
        ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary;
        ItemFromPictureTestPage: TestPage "Item From Picture";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
    begin
        Init();
        ItemFromPictureTests.Subscriber_ExpectImgAnalysisHttpCall(true, 200, '[]', 'https://microsoft.com/vision/v3.2/analyze?language=en&visualFeatures=Tags');
        CreateSetup();

        CreateItemFromPictureBuffer(ItemFromPictureBuffer);

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');

        ItemFromPictureTestPage.Trap();
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('ITEM', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleSetupNotification,SetupWizardHandler')]
    procedure ValidSetup_OverLimit()
    var
        ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        ImageAnalysisSetup: TestPage "Image Analysis Setup";
        ItemFromPictureCodeunit: Codeunit "Item From Picture";
        ItemFromPictureTestPage: TestPage "Item From Picture";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
        DummyNotif: Notification;
    begin
        Init();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetupKeyVault();
        ImageAnalysisSetup.Trap();
        ItemFromPictureCodeunit.RunWizard(DummyNotif);
        ImageAnalysisSetup.Close();
        ItemFromPictureTests.Subscriber_ExpectImgAnalysisHttpCall(true, 200, TestTagsTxt, 'https://northeurope.api.cognitive.microsoft.com/vision/v3.2/analyze?language=en&visualFeatures=Tags');

        CreateItemFromPictureBuffer(ItemFromPictureBuffer);

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');
        ItemList.Close();

        ItemFromPictureTestPage.Trap();
        LibraryVariableStorage.Enqueue('Seems like you reached the current limit of image analysis (1 per Year). You won''t be able to analyze more images until the next period starts.');
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('BEAVER', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('PROFITABLE ITEM $$$', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');

        Assert.IsTrue(ItemFromPictureTestPage.Attributes.First(), 'No attribute!');
        Assert.AreEqual('Fur color', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.Next(), 'Only one attribute!');
        Assert.AreEqual('Number of legs', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('4', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        Assert.IsTrue(ItemFromPictureTestPage.Attributes.Next(), 'Only two attributes!'); // There seems to be an empty attribute here
        Assert.IsFalse(ItemFromPictureTestPage.Attributes.Next(), 'More than three attributes!');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        ItemFromPictureBuffer.DeleteAll();
        CreateItemFromPictureBuffer(ItemFromPictureBuffer);

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');

        ItemFromPictureTestPage.Trap();
        LibraryVariableStorage.Enqueue('We could not analyze your image because of the following error: Sorry, you''ll have to wait until the start of the next year. You can analyze 1 images per year, and you''ve already hit the limit.');
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        Cleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidSetup_Successful()
    var
        ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary;
        FeatureKey: Record "Feature Key";
        ItemFromPictureTestPage: TestPage "Item From Picture";
        ItemList: TestPage "Item List";
        ItemCard: TestPage "Item Card";
    begin
        Init();
        ItemFromPictureTests.Subscriber_ExpectImgAnalysisHttpCall(true, 200, TestTagsTxt, 'https://microsoft.com/vision/v3.2/analyze?language=en&visualFeatures=Tags');
        CreateSetup();

        CreateItemFromPictureBuffer(ItemFromPictureBuffer);

        Assert.IsFalse(FeatureKey.Get('EntityText'), 'Feature Key should not exist.');

        ItemList.OpenEdit();
        Assert.IsTrue(ItemList.NewFromPicture.Enabled() and ItemList.NewFromPicture.Visible(), 'The action is not invokable.');

        ItemFromPictureTestPage.Trap();
        Page.Run(Page::"Item From Picture", ItemFromPictureBuffer);

        Assert.IsTrue(ItemFromPictureTestPage.CategoryCode.Enabled() and ItemFromPictureTestPage.CategoryCode.Visible(), 'The category field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.TemplateCode.Enabled() and ItemFromPictureTestPage.TemplateCode.Visible(), 'The template field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeNameField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeNameField.Visible(), 'The attribute name field is not editable.');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.AttributeValueField.Enabled() and ItemFromPictureTestPage.Attributes.AttributeValueField.Visible(), 'The attribute value field is not editable.');

        Assert.AreEqual('BEAVER', ItemFromPictureTestPage.CategoryCode.Value(), 'Unexpected category');
        Assert.AreEqual('PROFITABLE ITEM $$$', ItemFromPictureTestPage.TemplateCode.Value(), 'Unexpected template');

        Assert.IsTrue(ItemFromPictureTestPage.Attributes.First(), 'No attribute!');
        Assert.AreEqual('Fur color', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');
        Assert.IsTrue(ItemFromPictureTestPage.Attributes.Next(), 'Only one attribute!');
        Assert.AreEqual('Number of legs', ItemFromPictureTestPage.Attributes.AttributeNameField.Value(), 'Unexpected attribute name');
        Assert.AreEqual('4', ItemFromPictureTestPage.Attributes.AttributeValueField.Value(), 'Unexpected attribute value');

        Assert.IsTrue(ItemFromPictureTestPage.Attributes.Next(), 'Only two attributes!'); // There seems to be an empty attribute here
        Assert.IsFalse(ItemFromPictureTestPage.Attributes.Next(), 'More than three attributes!');

        ItemCard.Trap();
        ItemFromPictureTestPage.Close();
        ItemCard.Close();

        Cleanup();
    end;

    local procedure CreateItemFromPictureBuffer(var ItemFromPictureBuffer: Record "Item From Picture Buffer" temporary)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        OutStr := TempBlob.CreateOutStream();
        GetPicture(OutStr);

        ItemFromPictureBuffer.Init();
        ItemFromPictureBuffer.ItemMediaSet.ImportStream(TempBlob.CreateInStream(), '');
        ItemFromPictureBuffer.ItemMediaFileName := 'An item picture';
        ItemFromPictureBuffer.Insert(true);
    end;

    local procedure SetupKeyVault()
    var
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
    begin
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider();
        MockAzureKeyvaultSecretProvider.AddSecretMapping('cognitive-vision-params', '[{"limittype":"Year","endpoint":"https://northeurope.api.cognitive.microsoft.com/vision/v1.0/analyze","key":"SUPERSECRETKEY111","limitvalue":1},{"limittype":"Year","endpoint":"https://northeurope.api.cognitive.microsoft.com/vision/v1.0/analyze","key":"SUPERSECRETKEY222","limitvalue":1}]');
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
    end;

    local procedure Init()
    var
        AzureAIUsage: Record "Azure AI Usage";
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisScenario: Record "Image Analysis Scenario";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        AzureAIUsage.DeleteAll();
        ImageAnalysisSetup.DeleteAll();
        ImageAnalysisScenario.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        if BindSubscription(ItemFromPictureTests) then;
        TestClientTypeSubscriber.SetClientType(ClientType::Web);
        if BindSubscription(TestClientTypeSubscriber) then;

        if not IsInitialized then begin
            EnsureDemodata();
            IsInitialized := true;
        end;
    end;

    local procedure Cleanup()
    var
        AzureAIUsage: Record "Azure AI Usage";
        ImageAnalysisScenario: Record "Image Analysis Scenario";
        ImageAnalysisSetup: Record "Image Analysis Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        UnbindSubscription(ItemFromPictureTests);
        UnbindSubscription(TestClientTypeSubscriber);

        LibraryNotificationMgt.RecallNotificationsForRecord(ImageAnalysisSetup);
        AzureAIUsage.DeleteAll();
        ImageAnalysisScenario.DeleteAll();
        ImageAnalysisSetup.DeleteAll();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        ItemFromPictureTests.Subscriber_VerifyImageAnalysisHttpCall();
    end;

    local procedure CreateSetup()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
        ImageAnalysisScenario: Record "Image Analysis Scenario";
        ApiKey: Text;
    begin
        ImageAnalysisScenario.Status := true;
        ImageAnalysisScenario."Scenario Name" := 'ITEM FROM PICTURE';
        ImageAnalysisScenario.Insert();

        ApiKey := 'BEARER_1234567';
        ImageAnalysisSetup.SetApiKey(ApiKey);
        ImageAnalysisSetup."Api Uri" := 'https://microsoft.com/vision/v3.2/analyze';
        ImageAnalysisSetup.Insert();
    end;

    local procedure EnsureDemodata()
    var
        ItemTemplate: Record "Item Templ.";
        ItemCategory: Record "Item Category";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemCategory.Code := 'BEAVER';
        if ItemCategory.Insert() then;

        ItemTemplate.Code := 'PROFITABLE ITEM $$$';
        ItemTemplate."Item Category Code" := ItemCategory.Code;
        if ItemTemplate.Insert() then;

        ItemAttribute.Name := 'Fur color';
        ItemAttribute.Type := ItemAttribute.Type::Text;
        if ItemAttribute.Insert() then;
        ItemAttributeValue."Attribute ID" := ItemAttribute.ID;
        if ItemAttributeValue.Insert() then;
        ItemAttributeValueMapping."Table ID" := Database::"Item Category";
        ItemAttributeValueMapping."No." := ItemCategory.Code;
        ItemAttributeValueMapping."Item Attribute ID" := ItemAttribute.ID;
        ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
        if ItemAttributeValueMapping.Insert() then;

        Clear(ItemAttribute);
        Clear(ItemAttributeValueMapping);
        ItemAttribute.Name := 'Number of legs';
        ItemAttribute.Type := ItemAttribute.Type::Integer;
        if ItemAttribute.Insert() then;
        ItemAttributeValue."Attribute ID" := ItemAttribute.ID;
        ItemAttributeValue.Validate("Numeric Value", 4);
        if ItemAttributeValue.Insert() then;
        ItemAttributeValueMapping."Table ID" := Database::"Item Category";
        ItemAttributeValueMapping."No." := ItemCategory.Code;
        ItemAttributeValueMapping."Item Attribute ID" := ItemAttribute.ID;
        ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
        if ItemAttributeValueMapping.Insert() then;
    end;

    local procedure GetPicture(var Outstr: OutStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
        Base64String: Text;
    begin
        // Valid test PNG picture
        Base64String := 'iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAIAAACRXR/mAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABISURBVFhH7c4xAQAwDASh+jf91cCW4VDA20m1RC1RS9QStUQtUUvUErVELVFL1BK1RC1RS9QStUQtUUvUErVELVFL1BInW9sHBi0waLd0FpsAAAAASUVORK5CYII=';
        Base64Convert.FromBase64(Base64String, Outstr);
    end;

    [ModalPageHandler]
    procedure SetupWizardHandler(var ItemFromPictureWizard: TestPage "Item From Picture Wizard")
    begin
        ItemFromPictureWizard.ActionNext.Invoke(); // Introduction > Privacy Notice
        ItemFromPictureWizard.EnableFeature.SetValue(true);
        ItemFromPictureWizard.ActionNext.Invoke(); // Privacy Notice > Final step
        ItemFromPictureWizard.ActionFinishAndEnable.Invoke(); // Save and exit     
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure HandleSetupNotification(var TheNotification: Notification): Boolean
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), TheNotification.Message, 'Unexpected notification message');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Image Analysis Management", OnBeforeSendImageAnalysisRequest, '', false, false)]
    local procedure OnBeforeSendImageAnalysisRequestProvideResponse(HttpContent: HttpContent; RequestUrl: Text; var HttpStatusCode: Integer; var HttpResponseContentText: Text; var Handled: Boolean)
    var
        Content: Text;
        Jobj: JsonObject;
        JobjMetadata: JsonObject;
        JarrayTags: JsonArray;
    begin
        if Handled then
            Error('The event should not be handled.');

        if not Subscriber_ExpectImgAnalysisCall then
            Error('Image Analysis should not have been called');

        Assert.AreEqual(Subscriber_ExpectedUrl, RequestUrl, 'Unexpected request URL');
        HttpContent.ReadAs(Content);
        Assert.AreEqual(166, StrLen(Content), 'Unexpected content');

        Jobj.Add('modelVersion', '2021-05-01');
        Jobj.Add('requestId', '93c49f4b-085c-4c83-b29c-e4eb9013a1b9');
        JobjMetadata.Add('format', 'this is not really used but it''s returned by the service, so let''s mock it');
        Jobj.Add('metadata', JobjMetadata);
        JarrayTags.ReadFrom(Subscriber_ReturnTags);
        Jobj.Add('tags', JarrayTags);

        Handled := true;
        Subscriber_ExpectImgAnalysisCall := false;
        HttpStatusCode := Subscriber_ReturnStatusCode;
        Jobj.WriteTo(HttpResponseContentText);
    end;

    procedure Subscriber_DontExpectImageAnalysisHttpCall()
    begin
        Subscriber_ExpectImgAnalysisHttpCall(false, 0, '', '');
    end;

    procedure Subscriber_ExpectImgAnalysisHttpCall(ExpectCall: Boolean; HttpCode: Integer; Tags: Text; Url: Text)
    begin
        Subscriber_ExpectImgAnalysisCall := ExpectCall;
        Subscriber_ExpectedUrl := Url;
        Subscriber_ReturnStatusCode := HttpCode;
        Subscriber_ReturnTags := Tags;
    end;

    procedure Subscriber_VerifyImageAnalysisHttpCall()
    begin
        Assert.IsFalse(Subscriber_ExpectImgAnalysisCall, 'Image analysis should have been called');
    end;
}
