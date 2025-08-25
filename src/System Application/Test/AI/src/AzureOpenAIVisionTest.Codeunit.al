namespace System.Test.AI;

using System.AI;
using System.Utilities;
using System.TestLibraries.AI;
using System.Test.DataAdministration;
using System.TestLibraries.Utilities;
using System.Environment;
using System.Text;

codeunit 132691 "Azure OpenAI Vision Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestAddUserMessageWithImageUrl()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        UserText: Text;
        ImageUrl: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        ContentItem: JsonToken;
        ContentItemType: JsonToken;
        ImageUrlJsonTok: JsonToken;
        ImageUrlObj: JsonToken;
        DetailJsonTok: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with text and image URL adds a message with proper JSON structure

        // [GIVEN] A user text and image URL
        UserText := 'Describe this image';
        ImageUrl := 'https://example.com/image.jpg';

        // [WHEN] Adding a user message with an image URL
        AOAIChatMessages.AddUserMessage(UserText, ImageUrl, Enum::"AOAI Image Detail Level"::high);

        // [THEN] The history contains one message
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains both text and image parts in proper format
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        LibraryAssert.IsTrue(MessageJsonTok.AsObject().Get('content', ContentJsonTok), 'Content should exist in the message');

        // Verify content is an array with 2 items (text and image)
        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
        LibraryAssert.AreEqual(2, ContentJsonTok.AsArray().Count(), 'Content should have 2 items (text and image)');

        // Check first item is text
        ContentJsonTok.AsArray().Get(0, ContentItem);
        LibraryAssert.IsTrue(ContentItem.AsObject().Get('type', ContentItemType), 'Content item should have type');
        LibraryAssert.AreEqual('text', ContentItemType.AsValue().AsText(), 'First content item should be text');
        LibraryAssert.IsTrue(ContentItem.AsObject().Get('text', ContentItemType), 'Content item should have text');
        LibraryAssert.AreEqual(UserText, ContentItemType.AsValue().AsText(), 'Text content should match input');

        // Check second item is image URL
        ContentJsonTok.AsArray().Get(1, ContentItem);
        LibraryAssert.IsTrue(ContentItem.AsObject().Get('type', ContentItemType), 'Content item should have type');
        LibraryAssert.AreEqual('image_url', ContentItemType.AsValue().AsText(), 'Second content item should be image_url');
        LibraryAssert.IsTrue(ContentItem.AsObject().Get('image_url', ImageUrlJsonTok), 'Content item should have image_url');
        LibraryAssert.IsTrue(ImageUrlJsonTok.AsObject().Get('url', ImageUrlObj), 'image_url should have url');
        LibraryAssert.AreEqual(ImageUrl, ImageUrlObj.AsValue().AsText(), 'URL should match input');

        // Check detail level is properly set
        LibraryAssert.IsTrue(ImageUrlJsonTok.AsObject().Get('detail', DetailJsonTok), 'image_url should have detail');
        LibraryAssert.AreEqual('high', DetailJsonTok.AsValue().AsText(), 'Detail should be set to high');
    end;

    [Test]
    procedure TestAddUserMessageWithImageUrlAutoDetail()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        UserText: Text;
        ImageUrl: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        ContentItem: JsonToken;
        ImageUrlJsonTok: JsonToken;
        DetailJsonTok: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with auto detail level doesn't include detail in the JSON

        // [GIVEN] A user text and image URL
        UserText := 'Describe this image';
        ImageUrl := 'https://example.com/image.jpg';

        // [WHEN] Adding a user message with an image URL and auto detail level
        AOAIChatMessages.AddUserMessage(UserText, ImageUrl, Enum::"AOAI Image Detail Level"::auto);

        // [THEN] The message JSON doesn't include a detail field
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);
        ContentJsonTok.AsArray().Get(1, ContentItem);
        ContentItem.AsObject().Get('image_url', ImageUrlJsonTok);
        LibraryAssert.IsFalse(ImageUrlJsonTok.AsObject().Get('detail', DetailJsonTok), 'Detail should not be present when set to auto');
    end;

    [Test]
    procedure TestAddUserMessageWithImageStreamFromTempBlob()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        UserText: Text;
        FileExtension: Text;
        ImageData: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        ContentItem: JsonToken;
        ContentItemType: JsonToken;
        ImageUrlJsonTok: JsonToken;
        ImageUrlObj: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with image from stream creates a data URL in the proper format

        // [GIVEN] A user text and image data in a TempBlob
        UserText := 'Describe this image';
        FileExtension := 'png';

        // Create a very small test image data
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Adding a user message with an image from temp blob
        AOAIChatMessages.AddUserMessage(UserText, TempBlob, FileExtension, Enum::"AOAI Image Detail Level"::low);

        // [THEN] The history contains one message with a proper data URL
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains both text and image parts in proper format
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        // Verify content has 2 items (text and image)
        LibraryAssert.AreEqual(2, ContentJsonTok.AsArray().Count(), 'Content should have 2 items (text and image)');

        // Check second item is image data URL
        ContentJsonTok.AsArray().Get(1, ContentItem);
        ContentItem.AsObject().Get('type', ContentItemType);
        LibraryAssert.AreEqual('image_url', ContentItemType.AsValue().AsText(), 'Second content item should be image_url');
        ContentItem.AsObject().Get('image_url', ImageUrlJsonTok);
        ImageUrlJsonTok.AsObject().Get('url', ImageUrlObj);

        // Check URL starts with data:image/png;base64
        LibraryAssert.IsTrue(ImageUrlObj.AsValue().AsText().StartsWith('data:image/png;base64,'), 'URL should be a PNG data URL');
    end;

    [Test]
    procedure TestAddUserMessageWithImageStream()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        TempBlobStream: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        UserText: Text;
        FileExtension: Text;
        ImageData: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        ContentItem: JsonToken;
        ImageUrlJsonTok: JsonToken;
        ImageUrlObj: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with an image stream creates a data URL in the proper format

        // [GIVEN] A user text and image data in a Stream
        UserText := 'Describe this image';
        FileExtension := 'jpg';

        // Create a very small test image data
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlobStream.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlobStream.CreateInStream(InStream);

        // [WHEN] Adding a user message with an image stream
        AOAIChatMessages.AddUserMessage(UserText, InStream, FileExtension, Enum::"AOAI Image Detail Level"::high);

        // [THEN] The history contains one message with a proper data URL
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains both text and image parts in proper format
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        // Verify content has 2 items (text and image)
        LibraryAssert.AreEqual(2, ContentJsonTok.AsArray().Count(), 'Content should have 2 items (text and image)');

        // Check second item is image data URL and starts with data:image/jpeg;base64
        ContentJsonTok.AsArray().Get(1, ContentItem);
        ContentItem.AsObject().Get('image_url', ImageUrlJsonTok);
        ImageUrlJsonTok.AsObject().Get('url', ImageUrlObj);
        LibraryAssert.IsTrue(ImageUrlObj.AsValue().AsText().StartsWith('data:image/jpeg;base64,'), 'URL should be a JPEG data URL');
    end;

    [Test]
    procedure TestAddUserMessageWithTenantMedia()
    var
        TenantMedia: Record "Tenant Media";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        BlobOutStream: OutStream;
        InStream: InStream;
        UserText: Text;
        ImageData: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with TenantMedia adds a message with a proper data URL

        // [GIVEN] A user text and TenantMedia record with image content
        UserText := 'Describe this image';

        // Create test image data
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlob.CreateInStream(InStream);

        // Create a TenantMedia record with the image
        TenantMedia.Init();
        TenantMedia."Mime Type" := 'image/png';
        TenantMedia.ID := CreateGuid();
        TenantMedia.Insert();

        // Update the TenantMedia.Content with test image data
        TenantMedia.Content.CreateOutStream(BlobOutStream);
        CopyStream(BlobOutStream, InStream);
        TenantMedia.Modify();

        // [WHEN] Adding a user message with the TenantMedia
        AOAIChatMessages.AddUserMessage(UserText, TenantMedia, Enum::"AOAI Image Detail Level"::auto);

        // [THEN] The history contains one message with a proper data URL
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains content in JSON format
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        LibraryAssert.IsTrue(MessageJsonTok.AsObject().Get('content', ContentJsonTok), 'Content should exist in the message');
        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
    end;

    [Test]
    procedure TestAddUserMessageWithMediaSet()
    var
        TestMediaCleanup: Record "Test Media Cleanup";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        UserText: Text;
        ImageData: Text;
        MediaSetId: Guid;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with MediaSet adds a message with all images as data URLs

        // [GIVEN] A user text and a Test Media Cleanup record with MediaSet content
        UserText := 'Describe these images';

        // Create a Test Media Cleanup record
        TestMediaCleanup.Init();
        TestMediaCleanup."Primary Key" := 1;
        TestMediaCleanup.Insert();

        // Create image data and upload to MediaSet field
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlob.CreateInStream(InStream);

        // Import stream into the Test Media Cleanup record's MediaSet field
        TestMediaCleanup."Test Media Set".ImportStream(InStream, 'Test Image');
        TestMediaCleanup.Modify();

        // Get the MediaSet ID
        MediaSetId := TestMediaCleanup."Test Media Set".MediaId;

        // [WHEN] Adding a user message with the MediaSet ID
        AOAIChatMessages.AddUserMessage(UserText, MediaSetId, Enum::"AOAI Image Detail Level"::low);

        // [THEN] The history contains one message with a proper data URL
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains content in JSON format
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        LibraryAssert.IsTrue(MessageJsonTok.AsObject().Get('content', ContentJsonTok), 'Content should exist in the message');
        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
    end;

    [Test]
    procedure TestAddUserMessageWithMultipleImagesMediaSet()
    var
        TestMediaCleanup: Record "Test Media Cleanup";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        UserText: Text;
        MediaSetId: Guid;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        ImageCount: Integer;
    begin
        // [SCENARIO] AddUserMessage with MediaSet containing 5 images adds a message with all images as data URLs

        // [GIVEN] A user text and a Test Media Cleanup record with multiple images in MediaSet
        UserText := 'Describe these 5 images';
        ImageCount := 5;

        // Create a Test Media Cleanup record
        TestMediaCleanup.Init();
        TestMediaCleanup."Primary Key" := 2;
        TestMediaCleanup.Insert();

        // Add images to the MediaSet
        AddImagesToMediaSet(TestMediaCleanup, ImageCount);

        // Get the MediaSet ID
        MediaSetId := TestMediaCleanup."Test Media Set".MediaId;

        // [WHEN] Adding a user message with the MediaSet ID containing 5 images
        AOAIChatMessages.AddUserMessage(UserText, MediaSetId, Enum::"AOAI Image Detail Level"::low);

        // [THEN] The history contains one message
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains content in JSON format with all 5 images
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        // Content should be an array with 6 items (1 text + 5 images)
        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
        LibraryAssert.AreEqual(ImageCount + 1, ContentJsonTok.AsArray().Count(), 'Content should have 6 items (1 text + 5 images)');
    end;

    [Test]
    procedure TestAddUserMessageWithMaxImagesMediaSet()
    var
        TestMediaCleanup: Record "Test Media Cleanup";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        UserText: Text;
        MediaSetId: Guid;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        TotalImageCount: Integer;
        MaxImagesAllowed: Integer;
    begin
        // [SCENARIO] AddUserMessage with MediaSet containing 11 images only includes the first 10 in the message

        // [GIVEN] A user text and a Test Media Cleanup record with 11 images in MediaSet
        UserText := 'Describe these images';
        TotalImageCount := 11;
        MaxImagesAllowed := 10; // Assuming a limit of 10 images per message

        // Create a Test Media Cleanup record
        TestMediaCleanup.Init();
        TestMediaCleanup."Primary Key" := 3;
        TestMediaCleanup.Insert();

        // Add 11 images to the MediaSet
        AddImagesToMediaSet(TestMediaCleanup, TotalImageCount);

        // Get the MediaSet ID
        MediaSetId := TestMediaCleanup."Test Media Set".MediaId;

        // [WHEN] Adding a user message with the MediaSet ID containing 11 images
        AOAIChatMessages.AddUserMessage(UserText, MediaSetId, Enum::"AOAI Image Detail Level"::low);

        // [THEN] The history contains one message
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains content in JSON format with max 10 images
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        // Content should be an array with 11 items (1 text + 10 images max)
        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
        LibraryAssert.AreEqual(MaxImagesAllowed + 1, ContentJsonTok.AsArray().Count(), 'Content should have 11 items (1 text + 10 images)');
    end;

    [Test]
    procedure TestAddUserMessageWithOnlyText()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        UserText: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
    begin
        // [SCENARIO] Regular AddUserMessage with just text doesn't create a JSON array structure

        // [GIVEN] A user text
        UserText := 'This is a regular text message';

        // [WHEN] Adding a regular user message
        AOAIChatMessages.AddUserMessage(UserText);

        // [THEN] The history contains one message with just text content
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The content is a plain text string, not a JSON array
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        LibraryAssert.IsTrue(ContentJsonTok.IsValue(), 'Content should be a value, not an array');
        LibraryAssert.AreEqual(UserText, ContentJsonTok.AsValue().AsText(), 'Content should match input text');
    end;

    [Test]
    procedure TestAddUserMessageWithEmptyImage()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        UserText: Text;
        EmptyUrl: Text;
    begin
        // [SCENARIO] AddUserMessage with empty image URL doesn't add a message

        // [GIVEN] A user text and empty image URL
        UserText := 'Describe this image';
        EmptyUrl := '';

        // [WHEN] Adding a user message with an empty image URL
        AOAIChatMessages.AddUserMessage(UserText, EmptyUrl, Enum::"AOAI Image Detail Level"::high);

        // [THEN] The history should be empty
        LibraryAssert.AreEqual(0, AOAIChatMessages.GetHistory().Count, 'The history should be empty when image URL is empty');
    end;

    [Test]
    procedure TestAddUserMessageWithEmptyTextAndValidImage()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        EmptyText: Text;
        ImageUrl: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
    begin
        // [SCENARIO] AddUserMessage with empty text but valid image URL adds a message with just the image

        // [GIVEN] An empty user text and valid image URL
        EmptyText := '';
        ImageUrl := 'https://example.com/image.jpg';

        // [WHEN] Adding a user message with empty text and valid image URL
        AOAIChatMessages.AddUserMessage(EmptyText, ImageUrl, Enum::"AOAI Image Detail Level"::high);

        // [THEN] The history contains one message
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains only the image part (not text part)
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
        LibraryAssert.AreEqual(1, ContentJsonTok.AsArray().Count(), 'Content should have only 1 item (image)');
    end;

    [Test]
    procedure TestMultipleImagesInChatSession()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        UserText1: Text;
        UserText2: Text;
        ImageUrl1: Text;
        ImageUrl2: Text;
        AssistantResponse: Text;
        HistoryJsonArray: JsonArray;
    begin
        // [SCENARIO] Multiple images can be added in a chat session

        // [GIVEN] User texts and image URLs
        UserText1 := 'What is in this image?';
        ImageUrl1 := 'https://example.com/image1.jpg';
        UserText2 := 'And what is in this one?';
        ImageUrl2 := 'https://example.com/image2.jpg';
        AssistantResponse := 'The first image shows a cat.';

        // [WHEN] Adding multiple messages with images to the chat
        AOAIChatMessages.AddUserMessage(UserText1, ImageUrl1, Enum::"AOAI Image Detail Level"::auto);
        AOAIChatMessages.AddAssistantMessage(AssistantResponse);
        AOAIChatMessages.AddUserMessage(UserText2, ImageUrl2, Enum::"AOAI Image Detail Level"::auto);

        // [THEN] The history contains three messages
        LibraryAssert.AreEqual(3, AOAIChatMessages.GetHistory().Count, 'The history should contain three messages');

        // [THEN] The JSON for the chat history is correct
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(3, AOAIChatMessages);
        LibraryAssert.AreEqual(3, HistoryJsonArray.Count, 'The JSON history should contain three messages');
    end;

    [Test]
    procedure TestUnsupportedFileExtension()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        UserText: Text;
        InvalidFileExtension: Text;
        ImageData: Text;
    begin
        // [SCENARIO] Unsupported file extension should fail

        // [GIVEN] A user text and image data in a Stream with invalid extension
        UserText := 'Describe this image';
        InvalidFileExtension := 'xyz'; // Unsupported extension

        // Create a test image data
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Adding a user message with invalid file extension
        asserterror AOAIChatMessages.AddUserMessage(UserText, InStream, InvalidFileExtension, Enum::"AOAI Image Detail Level"::high);

        // [THEN] An error should be raised
        LibraryAssert.ExpectedError('Could not resolve Mime type for the provided file extension xyz.');
    end;

    [Test]
    procedure TestSimulatedEndToEndVisionSession()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        ImageStream: InStream;
        UserText: Text;
        FileExtension: Text;
        ImageUrl: Text;
        ImageData: Text;
        HistoryJsonArray: JsonArray;
        MockAIResponse: Text;
    begin
        // [SCENARIO] Simulating an end-to-end vision chat flow with both text and image inputs

        // [GIVEN] Test data for the vision session
        UserText := 'What is in this image?';
        ImageUrl := 'https://example.com/image.jpg';
        FileExtension := 'png';

        // Create a test image
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlob.CreateInStream(InStream);
        ImageStream := InStream;

        // Mock AI setup (we won't actually call the API)
        MockAIResponse := 'I can see a simple 1x1 pixel PNG image with a transparent background.';

        // [WHEN] Setting up and using the vision capabilities
        // Setup system message
        AOAIChatMessages.AddSystemMessage('You are an AI image description assistant.');

        // Add text and images in different ways
        AOAIChatMessages.AddUserMessage(UserText);
        AOAIChatMessages.AddUserMessage('', ImageStream, FileExtension, Enum::"AOAI Image Detail Level"::auto);
        AOAIChatMessages.AddUserMessage('', ImageUrl, Enum::"AOAI Image Detail Level"::auto);

        // Simulate AI response (without actually calling Azure OpenAI)
        AOAIChatMessages.AddAssistantMessage(MockAIResponse);

        // [THEN] Verify the chat history is constructed correctly
        LibraryAssert.AreEqual(5, AOAIChatMessages.GetHistory().Count, 'The history should contain five messages');

        // Check the content of the history
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(5, AOAIChatMessages);
        LibraryAssert.AreEqual(5, HistoryJsonArray.Count(), 'The JSON history array should have 5 items');

        // Check the last message (AI response)
        LibraryAssert.AreEqual(MockAIResponse, AOAIChatMessages.GetLastMessage(), 'The last message should be the AI response');
    end;

    [Test]
    procedure TestTextAndImageInOneMessage()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        UserText: Text;
        FileExtension: Text;
        ImageData: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        ContentJsonTok: JsonToken;
        ContentItem: JsonToken;
        ContentItemType: JsonToken;
        TextContent: JsonToken;
    begin
        // [SCENARIO] Adding text and image in one message works correctly

        // [GIVEN] A user text and image data
        UserText := 'Please describe this image in detail:';
        FileExtension := 'png';

        // Create a test image
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(ImageData, OutStream);
        TempBlob.CreateInStream(InStream);

        // [WHEN] Adding a user message with both text and image
        AOAIChatMessages.AddUserMessage(UserText, InStream, FileExtension, Enum::"AOAI Image Detail Level"::high);

        // [THEN] The history contains one message
        LibraryAssert.AreEqual(1, AOAIChatMessages.GetHistory().Count, 'The history should contain one message');

        // [THEN] The message contains both text and image parts in proper format
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(1, AOAIChatMessages);
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('content', ContentJsonTok);

        // Verify content is an array with 2 items (text and image)
        LibraryAssert.IsTrue(ContentJsonTok.IsArray(), 'Content should be an array');
        LibraryAssert.AreEqual(2, ContentJsonTok.AsArray().Count(), 'Content should have 2 items (text and image)');

        // Check first item is text with the correct content
        ContentJsonTok.AsArray().Get(0, ContentItem);
        ContentItem.AsObject().Get('type', ContentItemType);
        LibraryAssert.AreEqual('text', ContentItemType.AsValue().AsText(), 'First content item should be text');
        ContentItem.AsObject().Get('text', TextContent);
        LibraryAssert.AreEqual(UserText, TextContent.AsValue().AsText(), 'Text content should match input');
    end;

    local procedure AddImagesToMediaSet(var TestMediaCleanup: Record "Test Media Cleanup"; ImageCount: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStream: OutStream;
        InStream: InStream;
        ImageData: Text;
        i: Integer;
    begin
        // Sample 1x1 pixel PNG image data
        ImageData := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

        for i := 1 to ImageCount do begin
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutStream);
            Base64Convert.FromBase64(ImageData, OutStream);
            TempBlob.CreateInStream(InStream);

            // Import stream into the MediaSet field
            TestMediaCleanup."Test Media Set".ImportStream(InStream, 'Test Image ' + Format(i));
        end;

        TestMediaCleanup.Modify();
    end;
}