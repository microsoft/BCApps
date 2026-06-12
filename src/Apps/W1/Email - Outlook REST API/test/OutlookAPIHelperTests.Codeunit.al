// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139752 "Outlook API Helper Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;
    Permissions = tabledata "Email - Outlook Account" = rimd,
                    tabledata "Email Inbox" = rimd;

    var
        LibraryAssert: Codeunit "Library Assert";
        SendEmailExternalUserErr: Label 'Could not send the email, because the user is delegated or external.';

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
    procedure GraphRetrieveEmailsWithHeadersHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        RetrieveEmailFileTok: Label 'RetrieveEmailWithHeaders.txt', Locked = true;
    begin
        Response.Content.WriteFrom(NavApp.GetResourceAsText(RetrieveEmailFileTok, TextEncoding::UTF8));
        Response.HttpStatusCode := 200;
        exit(false);
    end;
}
