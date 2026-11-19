// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139752 "Outlook API Helper Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    Permissions = tabledata "Email - Outlook Account" = rimd,
                    tabledata "Email Inbox" = rimd,
                    tabledata "Email - Outlook API Setup" = rimd;

    var
        LibraryAssert: Codeunit "Library Assert";
        RecipientGraphMessages: JsonArray;
        RecipientGraphRequestCount: Integer;
        SendEmailExternalUserErr: Label 'Could not send the email, because the user is delegated or external.';
        UnexpectedRecipientCountErr: Label 'Unexpected %1 recipient count.', Comment = '%1 = Recipient type';
        UnexpectedRecipientErr: Label 'Unexpected or duplicate %1 recipient: %2.', Comment = '%1 = Recipient type, %2 = Email address';
        MissingRecipientsErr: Label 'Missing %1 recipients.', Comment = '%1 = Recipient type';

    [Test]
    procedure DefaultRedirectUrlIsAllowed()
    var
        EmailOAuthClient: Codeunit "Email - OAuth Client";
        OAuth2: Codeunit OAuth2;
        DefaultRedirectUrl: Text;
    begin
        // [FEATURE] [AI test 0.4]
        OAuth2.GetDefaultRedirectUrl(DefaultRedirectUrl);

        EmailOAuthClient.ValidateRedirectUrl(DefaultRedirectUrl);
    end;

    [Test]
    procedure NonDefaultRedirectUrlIsBlocked()
    var
        EmailOAuthClient: Codeunit "Email - OAuth Client";
    begin
        // [FEATURE] [AI test 0.4]
        asserterror EmailOAuthClient.ValidateRedirectUrl('https://contoso.example/oauth/callback');

        LibraryAssert.ExpectedError('The redirect URL must be');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RestoreDefaultRedirectUrlResetsSetupToDefault()
    var
        Setup: Record "Email - Outlook API Setup";
        EmailOAuthClient: Codeunit "Email - OAuth Client";
        OAuth2: Codeunit OAuth2;
        RedirectUrlErrorInfo: ErrorInfo;
        DefaultRedirectUrl: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [GIVEN] A setup record holding a non-default redirect URL
        if not Setup.Get() then
            Setup.Insert();
        Setup.RedirectURL := 'https://contoso.example/oauth/callback';
        Setup.Modify();

        // [WHEN] The Restore default redirect URL recovery action runs
        EmailOAuthClient.RestoreDefaultRedirectUrl(RedirectUrlErrorInfo);

        // [THEN] The stored redirect URL is reset to the environment default
        OAuth2.GetDefaultRedirectUrl(DefaultRedirectUrl);
        Setup.Get();
        LibraryAssert.AreEqual(CopyStr(DefaultRedirectUrl, 1, MaxStrLen(Setup.RedirectURL)), Setup.RedirectURL, 'Redirect URL should be reset to the environment default.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSendMailDelegatedAdmin()
    var
        PlanIds: Codeunit "Plan Ids";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        AzureADUserTestLibrary: Codeunit "Azure AD User Test Library";
        OutlookAPIClient: Codeunit "Email - Outlook API Client";
        EmailMessage: Codeunit "Email Message";
        AccessToken: SecretText;
    begin
        // [SCENARIO] External user (Delegated Admin) are prevented from sending emails
        // [GIVEN] The user is a delegated admin
        BindSubscription(AzureADUserTestLibrary);
        AzureADUserTestLibrary.SetIsUserDelegatedAdmin(true);
        AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanIds.GetDelegatedAdminPlanId());

        // [WHEN] The user attempts to send an email
        asserterror OutlookAPIClient.SendEmail(AccessToken, GetEmailJson(EmailMessage));

        // [THEN] The email is blocked and an error is shown
        LibraryAssert.ExpectedError(SendEmailExternalUserErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSendMailDelegatedHelpdesk()
    var
        PlanIds: Codeunit "Plan Ids";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        AzureADUserTestLibrary: Codeunit "Azure AD User Test Library";
        OutlookAPIClient: Codeunit "Email - Outlook API Client";
        EmailMessage: Codeunit "Email Message";
        AccessToken: SecretText;
    begin
        // [SCENARIO] External user (Delegated Helpdesk) is prevented from sending emails
        // [GIVEN] The user is a delegated helpdesk
        BindSubscription(AzureADUserTestLibrary);
        AzureADUserTestLibrary.SetIsUserDelegatedHelpdesk(true);
        AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanIds.GetHelpDeskPlanId());

        // [WHEN] The user attempts to send an email
        asserterror OutlookAPIClient.SendEmail(AccessToken, GetEmailJson(EmailMessage));

        // [THEN] The email is blocked and an error is shown
        LibraryAssert.ExpectedError(SendEmailExternalUserErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestSendMailExternalAccountant()
    var
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        OutlookAPIClient: Codeunit "Email - Outlook API Client";
        EmailMessage: Codeunit "Email Message";
        AzureADPlan: Codeunit "Azure AD Plan";
        PlanIds: Codeunit "Plan Ids";
        AccessToken: SecretText;
    begin
        // [SCENARIO] External user (External Accountant) is prevented from sending emails
        DeleteAllFromTablePlanAndUserPlan();

        // [GIVEN] The user only has an External Accountant license assigned
        AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanIds.GetExternalAccountantPlanId());
        LibraryAssert.IsTrue(AzureADPlan.IsPlanAssignedToUser(PlanIds.GetExternalAccountantPlanId()), 'User has no assigned external accountant plan.');

        // [WHEN] The user attempts to send an email
        asserterror OutlookAPIClient.SendEmail(AccessToken, GetEmailJson(EmailMessage));

        // [THEN] The email is blocked and an error is shown
        LibraryAssert.ExpectedError(SendEmailExternalUserErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsHandler')]
    procedure TestRetrieveEmailWithInlineAttachment()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        InStream: InStream;
        AttachmentContent: Text;
    begin
        // [SCENARIO] When retrieving emails with inline attachments, isInline and contentId are correctly parsed

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Filters are set to load attachments
        TempFilters.Init();
        TempFilters."Load Attachments" := true;
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;

        // [WHEN] Emails are retrieved (HTTP calls intercepted by GraphRetrieveEmailsHandler)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] An email inbox record was created
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');
        LibraryAssert.AreEqual('Test Inline Attachment', EmailInbox.Description, 'Unexpected email subject');

        // [THEN] The email message has attachments with correct inline properties
        EmailMessage.Get(EmailInbox."Message Id");

        // Verify first attachment (inline)
        LibraryAssert.IsTrue(EmailMessage.Attachments_First(), 'Expected at least one attachment');
        LibraryAssert.AreEqual('inline.txt', EmailMessage.Attachments_GetName(), 'Unexpected attachment name');
        LibraryAssert.AreEqual('text/plain', EmailMessage.Attachments_GetContentType(), 'Unexpected content type');
        LibraryAssert.IsTrue(EmailMessage.Attachments_IsInline(), 'First attachment should be inline');
        LibraryAssert.AreEqual('cid123', EmailMessage.Attachments_GetContentId(), 'Unexpected contentId for inline attachment');

        // Verify inline attachment content
        EmailMessage.Attachments_GetContent(InStream);
        InStream.ReadText(AttachmentContent);
        LibraryAssert.AreEqual('InlineContent', AttachmentContent, 'Unexpected inline attachment content');

        // Verify second attachment (regular)
        LibraryAssert.AreNotEqual(0, EmailMessage.Attachments_Next(), 'Expected a second attachment');
        LibraryAssert.AreEqual('doc.txt', EmailMessage.Attachments_GetName(), 'Unexpected attachment name');
        LibraryAssert.AreEqual('text/plain', EmailMessage.Attachments_GetContentType(), 'Unexpected content type');
        LibraryAssert.IsFalse(EmailMessage.Attachments_IsInline(), 'Second attachment should not be inline');
        LibraryAssert.AreEqual('', EmailMessage.Attachments_GetContentId(), 'Regular attachment should have empty contentId');

        // Verify regular attachment content
        EmailMessage.Attachments_GetContent(InStream);
        InStream.ReadText(AttachmentContent);
        LibraryAssert.AreEqual('RegularContent', AttachmentContent, 'Unexpected regular attachment content');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsNullContentIdHandler')]
    procedure TestRetrieveEmailWithNullContentId()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
    begin
        // [SCENARIO] When Graph returns contentId as JSON null on a non-inline attachment, parsing must
        // not crash and ContentId must not leak from a previous attachment that had one.

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Filters are set to load attachments
        TempFilters.Init();
        TempFilters."Load Attachments" := true;
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;

        // [WHEN] Emails are retrieved (response has an inline attachment with contentId
        // followed by a non-inline attachment with contentId: null)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] An email inbox record was created
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');

        // [THEN] The inline attachment keeps its contentId
        EmailMessage.Get(EmailInbox."Message Id");
        LibraryAssert.IsTrue(EmailMessage.Attachments_First(), 'Expected at least one attachment');
        LibraryAssert.AreEqual('cid789', EmailMessage.Attachments_GetContentId(), 'Unexpected contentId for inline attachment');

        // [THEN] The next attachment with contentId: null comes through as empty,
        // not the previous attachment's value
        LibraryAssert.AreNotEqual(0, EmailMessage.Attachments_Next(), 'Expected a second attachment');
        LibraryAssert.AreEqual('doc.pdf', EmailMessage.Attachments_GetName(), 'Unexpected attachment name');
        LibraryAssert.AreEqual('', EmailMessage.Attachments_GetContentId(), 'Null contentId must parse as empty and not leak the previous value');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsNonFileAttachmentsHandler')]
    procedure TestRetrieveEmailWithNonFileAttachments()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        InStream: InStream;
        AttachmentContent: Text;
    begin
        // [SCENARIO] An email whose attachments include item/reference attachments (which Microsoft Graph
        // returns without a 'contentBytes' property, e.g. bounce/NDR notifications) must not abort the batch.
        // Only file attachments must be imported; the others are skipped gracefully.

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Filters are set to load attachments
        TempFilters.Init();
        TempFilters."Load Attachments" := true;
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;

        // [WHEN] Emails are retrieved (response has an item attachment and a reference attachment
        // without contentBytes, followed by a regular file attachment)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] The email is imported instead of the whole batch failing with a missing 'contentBytes' error
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');
        LibraryAssert.AreEqual('Test Bounce With Item Attachment', EmailInbox.Description, 'Unexpected email subject');

        // [THEN] Only the file attachment is present; the item and reference attachments were skipped
        EmailMessage.Get(EmailInbox."Message Id");
        LibraryAssert.IsTrue(EmailMessage.Attachments_First(), 'Expected the file attachment to be imported');
        LibraryAssert.AreEqual('report.txt', EmailMessage.Attachments_GetName(), 'Unexpected attachment name');
        LibraryAssert.AreEqual('text/plain', EmailMessage.Attachments_GetContentType(), 'Unexpected content type');

        EmailMessage.Attachments_GetContent(InStream);
        InStream.ReadText(AttachmentContent);
        LibraryAssert.AreEqual('RegularContent', AttachmentContent, 'Unexpected file attachment content');

        // [THEN] There are no further attachments (item and reference attachments were not imported)
        LibraryAssert.AreEqual(0, EmailMessage.Attachments_Next(), 'Only the file attachment should have been imported');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsWithHeadersHandler')]
    procedure TestRetrieveEmailPersistsInternetMessageHeaders()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        HeaderValue: Text;
        LineFeed: Text[1];
    begin
        LineFeed[1] := 10;
        // [SCENARIO] When Graph returns internetMessageHeaders, they are persisted on the
        // Email Message and readable case-insensitively. Repeated headers (e.g. Received) are
        // joined with a line feed.

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Retrieval filters opt in to loading headers
        TempFilters.Init();
        TempFilters."Load Headers" := true;
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;

        // [WHEN] Emails are retrieved (response carries internetMessageHeaders)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] An email inbox record was created
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');

        // [THEN] Single-value headers round-trip case-insensitively
        EmailMessage.Get(EmailInbox."Message Id");
        LibraryAssert.IsTrue(EmailMessage.GetHeader('Authentication-Results', HeaderValue), 'Expected Authentication-Results header to be persisted');
        LibraryAssert.AreEqual('spf=pass smtp.mailfrom=test.com; dkim=pass; dmarc=pass action=none header.from=test.com; compauth=pass reason=100', HeaderValue, 'Unexpected Authentication-Results value');
        LibraryAssert.IsTrue(EmailMessage.GetHeader('X-MS-Exchange-Organization-AuthAs', HeaderValue), 'Expected AuthAs header to be persisted');
        LibraryAssert.AreEqual('Internal', HeaderValue, 'Unexpected AuthAs value');

        // [THEN] Repeated headers are joined with a line feed in document order
        LibraryAssert.IsTrue(EmailMessage.GetHeader('Received', HeaderValue), 'Expected Received header to be persisted');
        LibraryAssert.AreEqual('from MX1.test.com by EX1.test.com' + LineFeed + 'from sender.test.com by MX1.test.com', HeaderValue, 'Repeated Received headers should be joined with line feed');

        // [THEN] Headers that were not present return false
        LibraryAssert.IsFalse(EmailMessage.GetHeader('X-Not-Present', HeaderValue), 'Missing header should return false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsWithHeadersHandler')]
    procedure TestRetrieveEmailDoesNotPersistHeadersWhenNotRequested()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        HeaderValue: Text;
    begin
        // [SCENARIO] When Load Headers is not set, internetMessageHeaders returned by Graph
        // must not be persisted on the Email Message.

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Retrieval filters with Load Headers left at its default (false)
        TempFilters.Init();
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;

        // [WHEN] Emails are retrieved (response still carries internetMessageHeaders)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] An email inbox record was created
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');

        // [THEN] Headers from the Graph response are not persisted on the Email Message
        EmailMessage.Get(EmailInbox."Message Id");
        LibraryAssert.IsFalse(EmailMessage.GetHeader('Authentication-Results', HeaderValue), 'Authentication-Results must not be persisted when Load Headers is false');
        LibraryAssert.IsFalse(EmailMessage.GetHeader('Received', HeaderValue), 'Received must not be persisted when Load Headers is false');
        LibraryAssert.IsFalse(EmailMessage.GetHeader('X-MS-Exchange-Organization-AuthAs', HeaderValue), 'AuthAs must not be persisted when Load Headers is false');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsUnsafeBodyHandler')]
    procedure TestRetrieveEmailSanitizesBodyByDefault()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        Body: Text;
    begin
        // [SCENARIO] By default, retrieved email bodies are sanitized, stripping unsafe HTML.

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Filters that do not opt out of sanitization (default)
        TempFilters.Init();
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;

        // [WHEN] Emails are retrieved (response body contains unsafe HTML)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] An email inbox record was created
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');

        // [THEN] The unsafe markup is stripped from the body, but safe content remains
        EmailMessage.Get(EmailInbox."Message Id");
        Body := EmailMessage.GetBody();
        LibraryAssert.IsTrue(Body.Contains('Safe Content'), 'Safe content should be preserved');
        LibraryAssert.IsFalse(Body.ToLower().Contains('<script'), 'Script element should be sanitized out by default');
        LibraryAssert.IsFalse(Body.ToLower().Contains('onerror'), 'Event handler attribute should be sanitized out by default');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveEmailsUnsafeBodyHandler')]
    procedure TestRetrieveEmailBypassSanitizationKeepsRawBody()
    var
        OutlookAccount: Record "Email - Outlook Account";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        Body: Text;
    begin
        // [SCENARIO] When a first-party caller opts out via SetBypassBodySanitization, the raw
        // email body (including unsafe HTML) is preserved unsanitized.

        // [GIVEN] An Outlook account exists
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'testuser@test.com';
        OutlookAccount.Name := 'Test User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();

        // [GIVEN] OAuth token request is skipped
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Filters that opt out of body sanitization
        TempFilters.Init();
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;
        TempFilters.SetBypassBodySanitization(true);

        // [WHEN] Emails are retrieved (response body contains unsafe HTML)
        EmailInbox.Init();
        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        // [THEN] An email inbox record was created
        EmailInbox.MarkedOnly(true);
        LibraryAssert.IsTrue(EmailInbox.FindFirst(), 'Expected an email inbox record to be created');

        // [THEN] The raw body is kept verbatim, including the unsafe markup
        EmailMessage.Get(EmailInbox."Message Id");
        Body := EmailMessage.GetBody();
        LibraryAssert.IsTrue(Body.Contains('Safe Content'), 'Safe content should be preserved');
        LibraryAssert.IsTrue(Body.ToLower().Contains('<script'), 'Script element should be preserved when sanitization is bypassed');
        LibraryAssert.IsTrue(Body.ToLower().Contains('onerror'), 'Event handler attribute should be preserved when sanitization is bypassed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailPreservesThirdPartyCcAndTo()
    begin
        // [SCENARIO] Original To and third-party Cc are persisted even when Load Headers is false.
        RunRecipientRetrievalScenario('recipients-single', 'recipientuser@test.com', 'thirdparty@test.com',
            'recipientuser@test.com', 'thirdparty@test.com');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailPreservesMultipleToAndCc()
    begin
        RunRecipientRetrievalScenario('recipients-multiple', 'recipientuser@test.com;another@test.com', 'firstcc@test.com;secondcc@test.com',
            'recipientuser@test.com;another@test.com', 'firstcc@test.com;secondcc@test.com');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailPreservesSenderAndSelfInCc()
    begin
        // [SCENARIO] Retrieval preserves the original sender and mailbox in Cc; this is not reply-all filtering.
        RunRecipientRetrievalScenario('recipients-self', 'another@test.com', 'sender@test.com;recipientuser@test.com',
            'another@test.com', 'sender@test.com;recipientuser@test.com');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailPreservesOverlappingRecipientTypes()
    begin
        // [SCENARIO] An address shared by To and Cc must remain in both original groups.
        RunRecipientRetrievalScenario('recipients-overlap', 'recipientuser@test.com;shared@test.com', 'SHARED@test.com;thirdparty@test.com',
            'recipientuser@test.com;shared@test.com', 'shared@test.com;thirdparty@test.com');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailDeduplicatesWithinEachRecipientType()
    begin
        // [SCENARIO] Standard Email Message case-insensitive deduplication still applies within each type.
        RunRecipientRetrievalScenario('recipients-duplicates', 'recipientuser@test.com;RECIPIENTUSER@test.com;another@test.com',
            'thirdparty@test.com;THIRDPARTY@test.com;secondcc@test.com',
            'recipientuser@test.com;another@test.com', 'thirdparty@test.com;secondcc@test.com');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailWithEmptyRecipientArrays()
    begin
        RunRecipientRetrievalScenario('recipients-empty', '', '', '', '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailsWithMissingRecipientArrays()
    var
        OutlookAccount: Record "Email - Outlook Account";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        MessageJson: JsonObject;
    begin
        InitializeRecipientRetrieval(OutlookAccount, SkipTokenRequest);

        MessageJson := CreateRecipientGraphMessage('recipients-missing-both', '', '');
        MessageJson.Remove('toRecipients');
        MessageJson.Remove('ccRecipients');
        RecipientGraphMessages.Add(MessageJson);
        MessageJson := CreateRecipientGraphMessage('recipients-missing-to', '', 'thirdparty@test.com');
        MessageJson.Remove('toRecipients');
        RecipientGraphMessages.Add(MessageJson);
        MessageJson := CreateRecipientGraphMessage('recipients-missing-cc', 'recipientuser@test.com', '');
        MessageJson.Remove('ccRecipients');
        RecipientGraphMessages.Add(MessageJson);

        RetrieveRecipientEmails(OutlookAccount, 3);

        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-missing-both', '', '');
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-missing-to', '', 'thirdparty@test.com');
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-missing-cc', 'recipientuser@test.com', '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailsWithNullRecipientArrays()
    var
        OutlookAccount: Record "Email - Outlook Account";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        MessageJson: JsonObject;
        NullValue: JsonValue;
    begin
        InitializeRecipientRetrieval(OutlookAccount, SkipTokenRequest);
        NullValue.SetValueToNull();

        MessageJson := CreateRecipientGraphMessage('recipients-null-both', '', '');
        MessageJson.Replace('toRecipients', NullValue);
        MessageJson.Replace('ccRecipients', NullValue);
        RecipientGraphMessages.Add(MessageJson);
        MessageJson := CreateRecipientGraphMessage('recipients-null-to', '', 'thirdparty@test.com');
        MessageJson.Replace('toRecipients', NullValue);
        RecipientGraphMessages.Add(MessageJson);
        MessageJson := CreateRecipientGraphMessage('recipients-null-cc', 'recipientuser@test.com', '');
        MessageJson.Replace('ccRecipients', NullValue);
        RecipientGraphMessages.Add(MessageJson);

        RetrieveRecipientEmails(OutlookAccount, 3);

        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-null-both', '', '');
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-null-to', '', 'thirdparty@test.com');
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-null-cc', 'recipientuser@test.com', '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailsDoesNotLeakRecipientsBetweenMessages()
    var
        OutlookAccount: Record "Email - Outlook Account";
        FirstInbox: Record "Email Inbox";
        SecondInbox: Record "Email Inbox";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
    begin
        InitializeRecipientRetrieval(OutlookAccount, SkipTokenRequest);
        RecipientGraphMessages.Add(CreateRecipientGraphMessage('recipients-batch-first', 'firstto@test.com', 'firstcc@test.com'));
        RecipientGraphMessages.Add(CreateRecipientGraphMessage('recipients-batch-second', 'secondto@test.com', 'secondcc@test.com'));

        RetrieveRecipientEmails(OutlookAccount, 2);

        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-batch-first', 'firstto@test.com', 'firstcc@test.com');
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-batch-second', 'secondto@test.com', 'secondcc@test.com');
        FindRecipientInbox(OutlookAccount.Id, 'recipients-batch-first', FirstInbox);
        FindRecipientInbox(OutlookAccount.Id, 'recipients-batch-second', SecondInbox);
        LibraryAssert.IsTrue(FirstInbox."Message Id" <> SecondInbox."Message Id", 'Each Graph message must have its own Email Message.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('GraphRetrieveRecipientsHandler')]
    procedure TestRetrieveEmailAgainPreservesExistingMessageAndRecipients()
    var
        OutlookAccount: Record "Email - Outlook Account";
        OriginalInbox: Record "Email Inbox";
        RetrievedInbox: Record "Email Inbox";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        MessageJson: JsonObject;
        SenderJson: JsonObject;
    begin
        InitializeRecipientRetrieval(OutlookAccount, SkipTokenRequest);
        RecipientGraphMessages.Add(CreateRecipientGraphMessage('recipients-repeat', 'recipientuser@test.com', 'thirdparty@test.com'));
        RetrieveRecipientEmails(OutlookAccount, 1);
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-repeat', 'recipientuser@test.com', 'thirdparty@test.com');
        FindRecipientInbox(OutlookAccount.Id, 'recipients-repeat', OriginalInbox);

        // [WHEN] Graph returns the same external ID with different content and recipients.
        // The existing inbox-linked Email Message is immutable and must not be modified.
        Clear(RecipientGraphMessages);
        MessageJson := CreateRecipientGraphMessage('recipients-repeat', 'changedto@test.com', 'changedcc@test.com');
        MessageJson.Replace('subject', 'Changed subject');
        MessageJson.Replace('body', CreateRecipientGraphBody('Changed body'));
        SenderJson.Add('emailAddress', CreateRecipientGraphAddress('changedsender@test.com', 'Changed Sender'));
        MessageJson.Replace('sender', SenderJson);
        RecipientGraphMessages.Add(MessageJson);
        RetrieveRecipientEmails(OutlookAccount, 1);

        // [THEN] Retrieval succeeds without duplicates, rewriting, or immutable-message errors.
        AssertRetrievedRecipients(OutlookAccount.Id, 'recipients-repeat', 'recipientuser@test.com', 'thirdparty@test.com');
        FindRecipientInbox(OutlookAccount.Id, 'recipients-repeat', RetrievedInbox);
        LibraryAssert.AreEqual(OriginalInbox.Id, RetrievedInbox.Id, 'Retrieval must reuse the inbox record.');
        LibraryAssert.IsTrue(OriginalInbox.SystemId = RetrievedInbox.SystemId, 'Retrieval must not replace the inbox record.');
        LibraryAssert.AreEqual(OriginalInbox.SystemModifiedAt, RetrievedInbox.SystemModifiedAt, 'Retrieval must not rewrite the inbox record.');
        LibraryAssert.IsTrue(OriginalInbox."Message Id" = RetrievedInbox."Message Id", 'Retrieval must reuse the original Email Message.');
    end;

    local procedure RunRecipientRetrievalScenario(ExternalId: Text; ToAddresses: Text; CcAddresses: Text; ExpectedTo: Text; ExpectedCc: Text)
    var
        OutlookAccount: Record "Email - Outlook Account";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
    begin
        InitializeRecipientRetrieval(OutlookAccount, SkipTokenRequest);
        RecipientGraphMessages.Add(CreateRecipientGraphMessage(ExternalId, ToAddresses, CcAddresses));

        RetrieveRecipientEmails(OutlookAccount, 1);

        AssertRetrievedRecipients(OutlookAccount.Id, ExternalId, ExpectedTo, ExpectedCc);
    end;

    local procedure InitializeRecipientRetrieval(var OutlookAccount: Record "Email - Outlook Account"; var SkipTokenRequest: Codeunit "Skip Outlook API Token Request")
    begin
        Clear(RecipientGraphMessages);
        RecipientGraphRequestCount := 0;
        OutlookAccount.Init();
        OutlookAccount.Id := CreateGuid();
        OutlookAccount."Email Address" := 'recipientuser@test.com';
        OutlookAccount.Name := 'Recipient User';
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Test Outlook REST API";
        OutlookAccount.Insert();
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);
    end;

    local procedure RetrieveRecipientEmails(OutlookAccount: Record "Email - Outlook Account"; ExpectedInboxCount: Integer)
    var
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        EmailOutlookAPIHelper: Codeunit "Email - Outlook API Helper";
        PreviousRequestCount: Integer;
    begin
        TempFilters."Max No. of Emails" := 10;
        TempFilters."Body Type" := TempFilters."Body Type"::Text;
        TempFilters."Load Headers" := false;
        TempFilters."Load Attachments" := false;
        PreviousRequestCount := RecipientGraphRequestCount;

        EmailOutlookAPIHelper.RetrieveEmails(OutlookAccount.Id, EmailInbox, TempFilters);

        LibraryAssert.AreEqual(PreviousRequestCount + 1, RecipientGraphRequestCount, 'Expected exactly one Graph retrieval request.');
        EmailInbox.Reset();
        EmailInbox.SetRange("Account Id", OutlookAccount.Id);
        LibraryAssert.AreEqual(ExpectedInboxCount, EmailInbox.Count(), 'Unexpected number of inbox records for this account.');
    end;

    local procedure CreateRecipientGraphMessage(ExternalId: Text; ToAddresses: Text; CcAddresses: Text) MessageJson: JsonObject
    var
        SenderJson: JsonObject;
    begin
        MessageJson.Add('id', ExternalId);
        MessageJson.Add('conversationId', 'conversation-' + ExternalId);
        MessageJson.Add('receivedDateTime', '2026-01-02T03:04:05Z');
        MessageJson.Add('sentDateTime', '2026-01-02T03:00:00Z');
        MessageJson.Add('subject', 'Recipient retrieval');
        MessageJson.Add('body', CreateRecipientGraphBody('Recipient retrieval body.'));
        SenderJson.Add('emailAddress', CreateRecipientGraphAddress('sender@test.com', 'Original Sender'));
        MessageJson.Add('sender', SenderJson);
        MessageJson.Add('toRecipients', CreateRecipientGraphArray(ToAddresses));
        MessageJson.Add('ccRecipients', CreateRecipientGraphArray(CcAddresses));
        MessageJson.Add('hasAttachments', false);
        MessageJson.Add('isRead', false);
        MessageJson.Add('isDraft', false);
    end;

    local procedure CreateRecipientGraphBody(Content: Text) BodyJson: JsonObject
    begin
        BodyJson.Add('contentType', 'text');
        BodyJson.Add('content', Content);
    end;

    local procedure CreateRecipientGraphAddress(Address: Text; DisplayName: Text) AddressJson: JsonObject
    begin
        AddressJson.Add('address', Address);
        AddressJson.Add('name', DisplayName);
    end;

    local procedure CreateRecipientGraphArray(Addresses: Text) RecipientsJson: JsonArray
    var
        RecipientJson: JsonObject;
        AddressList: List of [Text];
        Address: Text;
    begin
        if Addresses = '' then
            exit;
        AddressList := Addresses.Split(';');
        foreach Address in AddressList do begin
            Clear(RecipientJson);
            RecipientJson.Add('emailAddress', CreateRecipientGraphAddress(Address, 'Recipient'));
            RecipientsJson.Add(RecipientJson);
        end;
    end;

    local procedure FindRecipientInbox(AccountId: Guid; ExternalId: Text; var EmailInbox: Record "Email Inbox")
    begin
        EmailInbox.Reset();
        EmailInbox.SetRange("Account Id", AccountId);
        EmailInbox.SetRange("External Message Id", ExternalId);
        LibraryAssert.AreEqual(1, EmailInbox.Count(), 'Expected exactly one persisted inbox record for the external message ID.');
        EmailInbox.FindFirst();
    end;

    local procedure AssertRetrievedRecipients(AccountId: Guid; ExternalId: Text; ExpectedTo: Text; ExpectedCc: Text)
    var
        EmailInbox: Record "Email Inbox";
        EmailMessage: Codeunit "Email Message";
    begin
        // Reread through the inbox link, rather than asserting against an in-memory Email Message.
        FindRecipientInbox(AccountId, ExternalId, EmailInbox);
        LibraryAssert.AreEqual('sender@test.com', EmailInbox."Sender Address", 'Importing recipients must not change the inbox sender address.');
        LibraryAssert.AreEqual('Original Sender', EmailInbox."Sender Name", 'Importing recipients must not change the inbox sender name.');
        LibraryAssert.AreEqual('Recipient retrieval', EmailInbox.Description, 'The original inbox description must be preserved.');
        LibraryAssert.IsTrue(EmailMessage.Get(EmailInbox."Message Id"), 'The inbox must link to a persisted Email Message.');
        LibraryAssert.AreEqual('Recipient retrieval', EmailMessage.GetSubject(), 'The original message subject must be preserved.');
        LibraryAssert.AreEqual('Recipient retrieval body.', EmailMessage.GetBody(), 'The original message body must be preserved.');
        AssertRecipientGroup(EmailMessage, Enum::"Email Recipient Type"::"To", ExpectedTo);
        AssertRecipientGroup(EmailMessage, Enum::"Email Recipient Type"::Cc, ExpectedCc);
        AssertRecipientGroup(EmailMessage, Enum::"Email Recipient Type"::Bcc, '');
    end;

    local procedure AssertRecipientGroup(EmailMessage: Codeunit "Email Message"; RecipientType: Enum "Email Recipient Type"; ExpectedAddresses: Text)
    var
        ActualRecipients: List of [Text];
        RemainingExpected: List of [Text];
        Address: Text;
    begin
        EmailMessage.GetRecipients(RecipientType, ActualRecipients);
        if ExpectedAddresses <> '' then
            RemainingExpected := ExpectedAddresses.ToLower().Split(';');
        LibraryAssert.AreEqual(RemainingExpected.Count(), ActualRecipients.Count(), StrSubstNo(UnexpectedRecipientCountErr, RecipientType));
        // Remove each matched address to verify exact membership and multiplicity, independent of order/casing.
        foreach Address in ActualRecipients do
            LibraryAssert.IsTrue(RemainingExpected.Remove(Address.ToLower()), StrSubstNo(UnexpectedRecipientErr, RecipientType, Address));
        LibraryAssert.AreEqual(0, RemainingExpected.Count(), StrSubstNo(MissingRecipientsErr, RecipientType));
    end;

    [HttpClientHandler]
    procedure GraphRetrieveRecipientsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ResponseJson: JsonObject;
        ResponseText: Text;
        RequestEndpoint: Text;
        QueryPosition: Integer;
    begin
        LibraryAssert.IsTrue(Request.RequestType = HttpRequestType::GET, 'Only Graph GET retrieval is expected.');
        RequestEndpoint := Request.Path;
        QueryPosition := StrPos(RequestEndpoint, '?');
        if QueryPosition > 0 then
            RequestEndpoint := CopyStr(RequestEndpoint, 1, QueryPosition - 1);
        LibraryAssert.AreEqual('https://graph.microsoft.com/v1.0/users/recipientuser@test.com/messages', RequestEndpoint, 'Unexpected Graph endpoint.');
        RecipientGraphRequestCount += 1;
        ResponseJson.Add('@odata.count', RecipientGraphMessages.Count());
        ResponseJson.Add('value', RecipientGraphMessages);
        ResponseJson.WriteTo(ResponseText);
        Response.Content.WriteFrom(ResponseText);
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    local procedure DeleteAllFromTablePlanAndUserPlan()
    var
        AzureADPlanTestLibraries: Codeunit "Azure AD Plan Test Library";
    begin
        AzureADPlanTestLibraries.DeleteAllPlans();
        AzureADPlanTestLibraries.DeleteAllUserPlan();
    end;

    local procedure GetEmailJson(EmailMessage: Codeunit "Email Message"): JsonObject
    var
        LibraryOutlookRestAPI: Codeunit "Library - Outlook Rest API";
        APIHelper: Codeunit "Email - Outlook API Helper";
    begin
        LibraryOutlookRestAPI.CreateEmailMessage(true, EmailMessage);
        exit(APIHelper.EmailMessageToJson(EmailMessage));
    end;

    [HttpClientHandler]
    procedure GraphRetrieveEmailsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RetrieveEmailFileTok: Label 'RetrieveEmailWithAttachments.txt', Locked = true;
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(RetrieveEmailFileTok, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [HttpClientHandler]
    procedure GraphRetrieveEmailsNullContentIdHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RetrieveEmailFileTok: Label 'RetrieveEmailWithNullContentId.txt', Locked = true;
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(RetrieveEmailFileTok, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [HttpClientHandler]
    procedure GraphRetrieveEmailsNonFileAttachmentsHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RetrieveEmailFileTok: Label 'RetrieveEmailWithNonFileAttachments.txt', Locked = true;
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(RetrieveEmailFileTok, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [HttpClientHandler]
    procedure GraphRetrieveEmailsWithHeadersHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RetrieveEmailFileTok: Label 'RetrieveEmailWithHeaders.txt', Locked = true;
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(RetrieveEmailFileTok, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
        exit(false);
    end;

    [HttpClientHandler]
    procedure GraphRetrieveEmailsUnsafeBodyHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RetrieveEmailFileTok: Label 'RetrieveEmailWithUnsafeBody.txt', Locked = true;
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(RetrieveEmailFileTok, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
        exit(false);
    end;
}
