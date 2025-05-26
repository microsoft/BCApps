// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Email;

using System.Email;
using System.TestLibraries.Email;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134055 "Https Mock Email Test"
{
    Subtype = Test;
    Permissions = tabledata "Email Message" = rid,
                  tabledata "Email Message Attachment" = r,
                  tabledata "Email Recipient" = r,
                  tabledata "Email Related Record" = r,
                  tabledata "Email Outbox" = rimd,
                  tabledata "Email View Policy" = rid,
                  tabledata "Email Address Lookup" = rimd,
                  tabledata "Email Rate Limit" = rimd,
                  tabledata "Sent Email" = rid;

    EventSubscriberInstance = Manual;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        PermissionsMock: Codeunit "Permissions Mock";
        Email: Codeunit Email;

    [Test]
    [HandlerFunctions('HttpRequestMockSuccessHandler')]
    [Scope('OnPrem')]
    procedure SendNewMessageThroughEditorSuccessTest()
    var
        Account: Record "Email Account";
        OutlookAccount: Record "Email - Outlook Account";
        OutlookApiSetup: Record "Email - Outlook API Setup";
        SentEmail: Record "Sent Email";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        ConnectorMock: Codeunit "Connector Mock";
        EmailMessage: Codeunit "Email Message";
        Editor: TestPage "Email Editor";
    begin
        // [Scenario] When user send the email from the editor with Microsoft 365 connector, the http request mocker returns a 202 to mock the success. All the records are updated correctly.
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);
        // [GIVEN] Set up the email account and Outlook account
        PermissionsMock.Set('Super');
        ConnectorMock.AddAccount(Account, Enum::"Email Connector"::"Microsoft 365");
        SetupOutlookAccount(OutlookAccount, Account);
        SetupOutlookApi(OutlookApiSetup);

        // [GIVEN] The Email Editor pages opens up and details are filled
        Editor.Trap();
        EmailMessage.Create('', '', '', false);
        Email.OpenInEditor(EmailMessage, Account);
        Editor.ToField.SetValue('testtest@microsoft.com');
        Editor.SubjectField.SetValue('Test Subject');
        Editor.BodyField.SetValue('Test body');

        // [WHEN] The send action is invoked, the post request is mocked to return a 202 - the email is sent successfully
        Editor.Send.Invoke();

        // [THEN] The mail is sent and the info is correct
        EmailMessage.GetId();
        SentEmail.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(SentEmail.FindFirst(), 'A Sent Email record should have been inserted.');
        Assert.AreEqual('Test Subject', SentEmail.Description, 'A different description was expected');
        Assert.AreEqual(Account."Account Id", SentEmail."Account Id", 'A different account was expected');
        Assert.AreEqual(Account."Email Address", SentEmail."Sent From", 'A different sent from was expected');
        Assert.AreEqual(Enum::"Email Connector"::"Microsoft 365", SentEmail.Connector, 'A different connector was expected');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HttpRequestMockSuccessHandler')]
    procedure ScheduledEmailBackgroundTest()
    var
        Account: Record "Email Account";
        OutlookAccount: Record "Email - Outlook Account";
        OutlookApiSetup: Record "Email - Outlook API Setup";
        EmailOutbox: Record "Email Outbox";
        SentEmail: Record "Sent Email";
        SkipTokenRequest: Codeunit "Skip Outlook API Token Request";
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
    begin
        // [Scenario] When the email is sent from the background task with Microsoft 365 connector, the http request mocker returns a 202 to mock the success. All the records are updated correctly.
        BindSubscription(SkipTokenRequest);
        SkipTokenRequest.SetSkipTokenRequest(true);

        // [GIVEN] Set up the email account and Outlook account
        PermissionsMock.Set('Super');
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        Assert.IsTrue(EmailMessage.Get(EmailMessage.GetId()), 'The email should exist');
        ConnectorMock.AddAccount(Account, Enum::"Email Connector"::"Microsoft 365");
        SetupOutlookAccount(OutlookAccount, Account);
        SetupOutlookApi(OutlookApiSetup);

        EmailOutbox."Message Id" := EmailMessage.GetId();
        EmailOutbox.Insert();
        EmailOutbox.Connector := Enum::"Email Connector"::"Microsoft 365";
        EmailOutbox."Account Id" := Account."Account Id";
        EmailOutbox.Description := CopyStr('Test Subject', 1, MaxStrLen(EmailOutbox.Description));
        EmailOutbox."User Security Id" := UserSecurityId();
        EmailOutbox."Send From" := Account."Email Address";
        EmailOutbox.Modify();

        // [WHEN] The sending task is run from the background, the post request is mocked to return a 202 - the email is sent successfully
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [THEN] No error occurs
        Assert.AreEqual('', GetLastErrorText(), 'There should be no errors when enqueuing an email.');

        // [THEN] The mail is sent and the info is correct
        EmailMessage.GetId();
        SentEmail.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(SentEmail.FindFirst(), 'A Sent Email record should have been inserted.');
        Assert.AreEqual('Test Subject', SentEmail.Description, 'A different description was expected');
        Assert.AreEqual(Account."Account Id", SentEmail."Account Id", 'A different account was expected');
        Assert.AreEqual(Account."Email Address", SentEmail."Sent From", 'A different sent from was expected');
        Assert.AreEqual(Enum::"Email Connector"::"Microsoft 365", SentEmail.Connector, 'A different connector was expected');
    end;

    local procedure SetupOutlookAccount(var OutlookAccount: Record "Email - Outlook Account"; Account: Record "Email Account")
    begin
        OutlookAccount.Id := Account."Account Id";
        OutlookAccount."Email Address" := Account."Email Address";
        OutlookAccount.Name := Account.Name;
        OutlookAccount."Outlook API Email Connector" := Enum::"Email Connector"::"Microsoft 365";
        OutlookAccount.Insert();
    end;

    local procedure SetupOutlookApi(var OutlookApiSetup: Record "Email - Outlook API Setup")
    begin
        if OutlookApiSetup.FindFirst() then
            exit;
        OutlookApiSetup.ClientId := Any.GuidValue();
        OutlookApiSetup.ClientSecret := Any.GuidValue();
        OutlookApiSetup.RedirectURL := CopyStr(Any.AlphanumericText(50), 1, 250);
        OutlookApiSetup.Insert();
    end;

    [HttpClientHandler]
    procedure HttpRequestMockSuccessHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if (Request.RequestType = HttpRequestType::Post) then begin
            // Populate the mocked response with content `HTTP/1.1 202 Accepted`
            response.HttpStatusCode := 202;
            response.ReasonPhrase := 'Accepted';

            exit(false); // Use the mocked response
        end;

        exit(true); // fall through and issue the original request in case of other requests
    end;
}