codeunit 139134 "Mail Management Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Email]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;
        EmailSendErr: Label 'The email to %1 with subject %2 has not been sent.', Comment = '%1 - To address, %2 - Email subject';

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure TestMailManagementSend()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
        DialogSubject: Variant;
        DialogBody: Variant;
        DialogMyEmail: Variant;
    begin
        Initialize();

        TempEmailItem."From Address" := 'no@where.com';
        TempEmailItem."Send to" := 'Some@where.com';
        TempEmailItem.Subject := 'Anywhere';
        TempEmailItem.SetBodyText('Here');

        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');
        MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);
        Assert.IsTrue(MailManagement.IsSent(), 'Mail should be sent');
        Assert.IsFalse(MailManagement.IsCancelled(), 'Mail send was not cancelled');

        LibraryVariableStorage.Dequeue(DialogSubject);
        LibraryVariableStorage.Dequeue(DialogBody);
        LibraryVariableStorage.Dequeue(DialogMyEmail);

        Assert.AreEqual(TempEmailItem.Subject, DialogSubject, 'Subject is not the same');
        Assert.AreEqual(TempEmailItem.GetBodyText(), DialogBody, 'Body is not the same');
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure TestMailManagementSendFail()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
        ConnectorMock: Codeunit "Connector Mock";
        Result: Boolean;
    begin
        Initialize();

        TempEmailItem."From Address" := 'no@where.com';
        TempEmailItem."Send to" := 'Some@where.com';
        TempEmailItem.Subject := 'Anywhere';
        TempEmailItem.SetBodyText('Here');

        ConnectorMock.FailOnSend(true);
        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');
        asserterror Result := MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);
        Assert.IsFalse(Result, 'The mail should not be send based on result');
        Assert.IsFalse(MailManagement.IsSent(), 'Mail should not be send');
        Assert.IsFalse(MailManagement.IsCancelled(), 'Mail cancelled by Outlook not chosen confirmation dialog');
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure TestMailManagementSendFail2()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
        ConnectorMock: Codeunit "Connector Mock";
        DialogSubject: Variant;
        DialogBody: Variant;
        DialogMyEmail: Variant;
    begin
        Initialize();

        TempEmailItem."From Address" := 'no@where.com';
        TempEmailItem."Send to" := 'Some@where.com';
        TempEmailItem.Subject := 'Anywhere';
        TempEmailItem.SetBodyText('Here');

        ConnectorMock.FailOnSend(true);
        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');
        asserterror MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);
        Assert.IsFalse(MailManagement.IsSent(), 'Mail should be sent');
        Assert.IsFalse(MailManagement.IsCancelled(), 'Mail send was not cancelled');

        LibraryVariableStorage.Dequeue(DialogSubject);
        LibraryVariableStorage.Dequeue(DialogBody);
        LibraryVariableStorage.Dequeue(DialogMyEmail);

        Assert.AreEqual(TempEmailItem.Subject, DialogSubject, 'Subject is not the same');
        Assert.AreEqual(TempEmailItem.GetBodyText(), DialogBody, 'Body is not the same');
    end;

    [Test]
    [HandlerFunctions('CancelMailDialog,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestMailDialogCancelled()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
    begin
        Initialize();

        TempEmailItem."From Address" := 'no@where.com';
        TempEmailItem."Send to" := 'Some@where.com';
        TempEmailItem.Subject := 'Anywhere';
        TempEmailItem.SetBodyText('Here');

        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');
        MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);
        Assert.IsFalse(MailManagement.IsSent(), 'Mail should be sent');
        Assert.IsTrue(MailManagement.IsCancelled(), 'Mail send was not cancelled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidEmailAddress()
    var
        MailManagement: Codeunit "Mail Management";
    begin
        asserterror MailManagement.CheckValidEmailAddress('@a');
        asserterror MailManagement.CheckValidEmailAddress('b@');
        asserterror MailManagement.CheckValidEmailAddress('ab)@c.d');
        asserterror MailManagement.CheckValidEmailAddress('a@@b');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValidEmailAddressesOnStringWithMultipleEmailAddresses()
    var
        MailManagement: Codeunit "Mail Management";
        MultipleAddressesTxt: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341841] Run CheckValidEmailAddresses function of MailManagement codeunit on string with multiple e-mail addresses.

        // [WHEN] Run CheckValidEmailAddresses of MailManagement codeunit on string with multiple email addresses in cases:
        // [WHEN] delimiter is semicolon; delimiter is comma or vertical bar or space; one of the elements is not a valid email address.
        MultipleAddressesTxt := 'test1@test.com; test2@test.com; test3@test.com';
        MailManagement.CheckValidEmailAddresses(MultipleAddressesTxt);

        MultipleAddressesTxt := 'test1@test.com, test2@test.com, test3@test.com';
        asserterror MailManagement.CheckValidEmailAddresses(MultipleAddressesTxt);

        MultipleAddressesTxt := 'test1@test.com| test2@test.com| test3@test.com';
        asserterror MailManagement.CheckValidEmailAddresses(MultipleAddressesTxt);

        MultipleAddressesTxt := 'test1@test.com test2@test.com test3@test.com';
        asserterror MailManagement.CheckValidEmailAddresses(MultipleAddressesTxt);

        MultipleAddressesTxt := 'test1@test.com; test2.com; test3@test.com';
        asserterror MailManagement.CheckValidEmailAddresses(MultipleAddressesTxt);

        // [THEN] String is validated without errors in cases, when valid email addresses are separated by a semicolon or a comma.
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure TestMailDialogClearBodyAfterTemplate()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlobMail: Codeunit "Temp Blob";
        MailManagement: Codeunit "Mail Management";
        TemplateBodyText: Text;
        DialogBodyText: array[2] of Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 201460] Send Email dialog has an empty message body when send a new email after one with a template body in subsequent runs
        Initialize();

        // [GIVEN] Send first email using email template body
        TemplateBodyText := LibraryUtility.GenerateRandomXMLText(100);
        GenerateTempBody(TemplateBodyText, TempBlobMail);
        InitTempEmailItem(TempEmailItem, false, TempBlobMail);
        SendEmail(TempEmailItem, MailManagement);

        // [WHEN] Send second email using plain text body
        InitTempEmailItem(TempEmailItem, true);
        SendEmail(TempEmailItem, MailManagement);

        // [THEN] The first "Send Email" dialog is opened with filled message body text from template
        // [THEN] The second "Send Email" dialog is opened with an empty message body text
        LibraryVariableStorage.AssertPeekAvailable(6);
        DialogBodyText[1] := LibraryVariableStorage.PeekText(2);
        DialogBodyText[2] := LibraryVariableStorage.PeekText(5);

        Assert.AreNotEqual('', DialogBodyText[1], 'Body text was expected loaded from template');
        Assert.ExpectedMessage(TemplateBodyText, DialogBodyText[1]);

        // TODO: html is not converted into plain body text when load from template. Should be fixed.
        asserterror Assert.AreEqual(TemplateBodyText, DialogBodyText[1], 'Body text was expected loaded from template');

        Assert.AreEqual('', DialogBodyText[2], 'Body text was not cleared when moving from template to non-template email bodies');
    end;

    [Test]
    [HandlerFunctions('ValidateMailDialog')]
    [Scope('OnPrem')]
    procedure TestMailDialogClearBodyAfterPlainText()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
        BodyText: Text;
        DialogBodyText: array[2] of Text;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 201460] Send Email dialog has an empty message body when send a new email after one with non-empty plain text body in subsequent runs
        Initialize();

        // [GIVEN] Send first email using non-empty plain text message body
        BodyText := LibraryUtility.GenerateRandomXMLText(100);
        InitTempEmailItem(TempEmailItem, true);
        TempEmailItem.SetBodyText(BodyText);
        SendEmail(TempEmailItem, MailManagement);

        // [WHEN] Send second email using plain text body
        InitTempEmailItem(TempEmailItem, true);
        SendEmail(TempEmailItem, MailManagement);

        // [THEN] The second "Send Email" dialog is opened with an empty body text
        LibraryVariableStorage.AssertPeekAvailable(6);
        DialogBodyText[1] := LibraryVariableStorage.PeekText(2);
        DialogBodyText[2] := LibraryVariableStorage.PeekText(5);

        Assert.AreEqual(BodyText, DialogBodyText[1], '');
        Assert.AreEqual('', DialogBodyText[2], 'Body text was not cleared when moving from one plain text to another email bodies');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServMailManagementRun()
    var
        ServiceEmailQueue: Record "Service Email Queue";
        MailManagementTest: Codeunit "Mail Management Test";
        ConnectorMock: Codeunit "Connector Mock";
        Result: Boolean;
    begin
        // [SCENARIO 381524] ServMailManagement sends email based on "Service EMail Queue" entry
        // [GIVEN] "Service EMail Queue" entry "S" created from service order where "To Address" = "A", "Subject Line" = "SL", "Body Line" = "BL" and "Copy-to Address" = "CA"
        // [GIVEN] Error happens during sending
        Initialize();
        ConnectorMock.FailOnSend(true);
        ClearLastError();

        MockServiceEMailQueue(ServiceEmailQueue);
        Commit();

        // [WHEN] Run ServMailManagement codeunit for "S"
        // Here we simulate sending. We just ensure that send called. Further errors does not relate to the bug 381524
        // We get send error as the expected result.
        // Also we subscribed to "Email Item".INSERT trigger to identify that created entry is correct.
        BindSubscription(MailManagementTest);
        Result := CODEUNIT.Run(CODEUNIT::ServMailManagement, ServiceEmailQueue);
        Assert.IsFalse(Result, 'ServMailManagement RUN trigger must fail');

        // [THEN] Temp Email Item "I" created where "I"."Send To" = "A", "I"."Send CC" = "CA", "I"."Subject" = "SL" and "I".Body = "BL"
        // [THEN] Multiline error 'Failure sending mail. Unable to connect to the remote server' has been thrown
        Assert.ExpectedError('Failed to send email');

        asserterror ServiceEmailQueue.Find(); // must be deleted in event subscriber. This line ensures subscriber called and completed
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServMailManagementRunWithoutAnyEmailAccount()
    var
        ServiceEmailQueue: Record "Service Email Queue";
        MailManagementTest: Codeunit "Mail Management Test";
        ConnectorMock: Codeunit "Connector Mock";
        Result: Boolean;
    begin
        // [SCENARIO 381524] ServMailManagement throws error <Email to "A" with subject "SL" has not been sent.> when runs without any registered email account
        // [GIVEN] "Service EMail Queue" entry "S" created from service order where "To Address" = "A" and "Subject Line" = "SL"
        // [GIVEN] There are no registered email accounts.
        Initialize();
        ConnectorMock.Initialize();
        ClearLastError();

        MockServiceEMailQueue(ServiceEmailQueue);
        Commit();

        // [WHEN] Run ServMailManagement codeunit for "S"
        BindSubscription(MailManagementTest);
        Result := CODEUNIT.Run(CODEUNIT::ServMailManagement, ServiceEmailQueue);
        Assert.IsFalse(Result, 'ServMailManagement RUN trigger must fail');
        // [THEN] Multiline error 'Email to "A" with subject "SL" has not been sent.' has been thrown
        Assert.ExpectedError(StrSubstNo(EmailSendErr, ServiceEmailQueue."To Address", ServiceEmailQueue."Subject Line"));
    end;

    [Test]
    [HandlerFunctions('UpdateValidateMailDialog,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestMailDialogOpenedTwiceCcTextAndBccTextBlank()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlobMail: Codeunit "Temp Blob";
        MailManagement: Codeunit "Mail Management";
        ActionType: Option Update,Validate;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228378] BCC and CC are blank on second run of Email Dialog when changed on previous run
        Initialize();

        // [GIVEN] Email Item where BCC and CC are not specified
        GenerateTempBody(LibraryUtility.GenerateRandomXMLText(100), TempBlobMail);
        InitTempEmailItem(TempEmailItem, false, TempBlobMail);
        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');

        // [GIVEN] CC Text and BCC Text are updated on Send Email Dialog
        EnqueueCCAndBCCValues(ActionType::Update, 'abc@abc.com', 'xyz@abc.com');
        MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);

        // [WHEN] Open Send Email Dialog again
        EnqueueCCAndBCCValues(ActionType::Validate, '', '');
        MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);

        // [THEN] BCC Text and CC Text are empty
        // verified in UpdateValidateMailDialog
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('UpdateValidateMailDialog,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestMailDialogOpenedTwiceCcTextAndBccTextFromMailItem()
    var
        TempEmailItem: Record "Email Item" temporary;
        TempBlobMail: Codeunit "Temp Blob";
        MailManagement: Codeunit "Mail Management";
        ActionType: Option Update,Validate;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 228378] BCC and CC are initialized from Email Item on second run of Email Dialog when changed on previous run
        Initialize();

        // [GIVEN] Email Item where BCC = "toBCC" and CC = "toCC"
        GenerateTempBody(LibraryUtility.GenerateRandomXMLText(100), TempBlobMail);
        InitTempEmailItem(TempEmailItem, false, TempBlobMail);
        TempEmailItem."Send CC" := LibraryUtility.GenerateGUID();
        TempEmailItem."Send BCC" := LibraryUtility.GenerateGUID();
        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');

        // [GIVEN] CC Text and BCC Text are updated on Send Email Dialog
        EnqueueCCAndBCCValues(ActionType::Update, 'abc@abc.com', 'xyz@abc.com');
        MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);

        // [WHEN] Open Send Email Dialog again
        EnqueueCCAndBCCValues(ActionType::Validate, TempEmailItem."Send CC", TempEmailItem."Send BCC");
        MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::Default);

        // [THEN] BCC Text and CC Text are equal to "toCC" and "toBCC" respectively
        // verified in UpdateValidateMailDialog
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryEmail: Codeunit "Library - Email";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryEmail.SetUpEmailAccount();
        BindActiveDirectoryMockEvents();

        LibraryVariableStorage.Clear();

        if not IsInitialized then
            IsInitialized := true;
    end;

    local procedure MockServiceEMailQueue(var ServiceEmailQueue: Record "Service Email Queue")
    begin
        LibraryUtility.GetNewRecNo(ServiceEmailQueue, ServiceEmailQueue.FieldNo("Entry No."));
        ServiceEmailQueue."Body Line" := LibraryUtility.GenerateGUID();
        ServiceEmailQueue."To Address" := 'Some@where.com';
        ServiceEmailQueue."Copy-to Address" := 'NoSome@where.com';
        ServiceEmailQueue."Subject Line" := LibraryUtility.GenerateGUID();
        ServiceEmailQueue.Insert();
    end;

    local procedure InitTempEmailItem(var EmailItem: Record "Email Item"; PlaintextFormatted: Boolean)
    begin
        Clear(EmailItem);
        EmailItem."From Address" := 'no@where.com';
        EmailItem."Send to" := 'Some@where.com';
        EmailItem.Subject := 'Anywhere';
        EmailItem."Plaintext Formatted" := PlaintextFormatted;
    end;

    local procedure InitTempEmailItem(var EmailItem: Record "Email Item"; PlaintextFormatted: boolean; TempBlobBody: Codeunit "Temp Blob")
    begin
        InitTempEmailItem(EmailItem, PlaintextFormatted);
        EmailItem.SetBody(TempBlobBody);
    end;

    local procedure EnqueueCCAndBCCValues(ActionType: Variant; CCText: Variant; BCCText: Variant)
    begin
        LibraryVariableStorage.Enqueue(ActionType);
        LibraryVariableStorage.Enqueue(CCText);
        LibraryVariableStorage.Enqueue(BCCText);
    end;

    local procedure SendEmail(var EmailItem: Record "Email Item"; var MailManagement: Codeunit "Mail Management")
    begin
        Assert.IsTrue(MailManagement.IsEnabled(), 'Mail management is not configured');
        MailManagement.Send(EmailItem, Enum::"Email Scenario"::Default);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ValidateMailDialog(var TestEmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(TestEmailEditor.SubjectField.Value);
        LibraryVariableStorage.Enqueue(TestEmailEditor.BodyField.Value);
        LibraryVariableStorage.Enqueue(TestEmailEditor.BccField.Value);
        TestEmailEditor.Send.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateValidateMailDialog(var TestEmailEditor: TestPage "Email Editor")
    var
        ActionType: Option Update,Validate;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ActionType::Update:
                begin
                    TestEmailEditor.CcField.SetValue(LibraryVariableStorage.DequeueText());
                    TestEmailEditor.BccField.SetValue(LibraryVariableStorage.DequeueText());
                    TestEmailEditor.Send.Invoke();
                end;
            ActionType::Validate:
                begin
                    TestEmailEditor.CcField.AssertEquals(LibraryVariableStorage.DequeueText());
                    TestEmailEditor.BccField.AssertEquals(LibraryVariableStorage.DequeueText());
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelMailDialog(var TestEmailEditor: TestPage "Email Editor")
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmDialogFalseReply(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure GenerateTempBody(BodyText: Text; var TempBlob: Codeunit "Temp Blob")
    var
        BlobStream: OutStream;
    begin
        TempBlob.CreateOutStream(BlobStream);
        BlobStream.WriteText('<html><body><b>' + BodyText + '</b></body></html>');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Email Item", 'OnAfterInsertEvent', '', false, false)]
    local procedure VerifyTempEmailItemOnAfterInsertEvent(var Rec: Record "Email Item"; RunTrigger: Boolean)
    var
        ServiceEmailQueue: Record "Service Email Queue";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Assert.IsTrue(RecRef.IsTemporary, 'Expected temporary Email Item');
        Assert.IsFalse(RunTrigger, 'Expected INSERT call without trigger');
        ServiceEmailQueue.FindLast();
        Assert.AreEqual(Rec.GetBodyText(), ServiceEmailQueue."Body Line", 'Body text is wrong');
        Rec.TestField("Send to", ServiceEmailQueue."To Address");
        Rec.TestField("Send CC", ServiceEmailQueue."Copy-to Address");
        Rec.TestField(Subject, ServiceEmailQueue."Subject Line");

        // Fix for bug: 209447 (for some reason Sender may come blank)
        Rec."From Address" := 'from@somewhere.com';
        Rec.Modify();

        ServiceEmailQueue.Delete();
        Commit();
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

