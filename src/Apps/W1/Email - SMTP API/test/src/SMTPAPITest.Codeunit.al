// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 139771 "SMTP API Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestServerTxt: Label 'Something@Url.com';
        TestServerPort: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure TestConnect()
    var
        LibrarySMTPAPI: Codeunit "Library - SMTP API";
        SMTPAPIClientMock: Codeunit "SMTP API Client Mock";
        iSMTPClient: Interface "iSMTP Client";
    begin
        // [SCENARIO] Test connecting to servers

        // [GIVEN] Server, port and client
        Initialize(iSMTPClient);
        LibrarySMTPAPI.SetClient(iSMTPClient);

        // [WHEN] Connect with given server, port and client
        // [THEN] Connected
        LibraryAssert.IsTrue(LibrarySMTPAPI.Connect(TestServerTxt, TestServerPort, true), 'Failed to connect to server');

        // [WHEN] Set mock to fail on connect
        SMTPAPIClientMock.FailOnConnect(true);

        // [THEN] Fails to connect to server
        LibraryAssert.IsFalse(LibrarySMTPAPI.Connect(TestServerTxt, TestServerPort, true), 'Connected to server');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAuthenticate()
    var
        SMTPAuthentication: Codeunit "SMTP Authentication";
        LibrarySMTPAPI: Codeunit "Library - SMTP API";
        SMTPAPIClientMock: Codeunit "SMTP API Client Mock";
        iSMTPClient: Interface "iSMTP Client";
    begin
        // [SCENARIO] Test authentication to servers

        // [GIVEN] Connection info and client 
        Initialize(iSMTPClient);
        LibrarySMTPAPI.SetClient(iSMTPClient);

        // [WHEN] Connect to server and try to authenticate
        // [THEN] Authenticate successfully
        LibraryAssert.IsTrue(LibrarySMTPAPI.Connect(TestServerTxt, TestServerPort, true), 'Failed to connect to server');
        LibraryAssert.IsTrue(LibrarySMTPAPI.Authenticate("SMTP Authentication Types"::Basic, SMTPAuthentication), 'Failed to authenticate');

        // [WHEN] Set mock to fail on authentication
        SMTPAPIClientMock.FailOnAuthenticate(true);

        // [THEN] Fail to authenticate
        LibraryAssert.IsFalse(LibrarySMTPAPI.Authenticate("SMTP Authentication Types"::Basic, SMTPAuthentication), 'Authenticated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSend()
    var
        SMTPAuthentication: Codeunit "SMTP Authentication";
        LibrarySMTPAPI: Codeunit "Library - SMTP API";
        SMTPAPIClientMock: Codeunit "SMTP API Client Mock";
        SMTPMessage: Codeunit "SMTP Message";
        iSMTPClient: Interface "iSMTP Client";
    begin
        // [SCENARIO] Send email

        // [GIVEN] Connection info and client
        Initialize(iSMTPClient);
        LibrarySMTPAPI.SetClient(iSMTPClient);

        // [WHEN] Connect to server, authenticate and try to send email
        // [THEN] Successfully send email
        LibraryAssert.IsTrue(LibrarySMTPAPI.Connect(TestServerTxt, TestServerPort, true), 'Failed to connect to server');
        LibraryAssert.IsTrue(LibrarySMTPAPI.Authenticate("SMTP Authentication Types"::Basic, SMTPAuthentication), 'Failed to authenticate');
        LibraryAssert.IsTrue(LibrarySMTPAPI.Send(SMTPMessage), 'Message failed to send');

        // [WHEN] Set mock to fail on sending of email
        SMTPAPIClientMock.FailOnSendMessage(true);

        // [THEN] Fails to send email
        LibraryAssert.IsFalse(LibrarySMTPAPI.Send(SMTPMessage), 'Message sent');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInlineImagesNotDisposedAfterSetBody()
    var
        SMTPMessageImpl: Codeunit "SMTP Message Impl";
        TempBlob: Codeunit "Temp Blob";
        Recipients: List of [Text];
        OutStr: OutStream;
        InStr: InStream;
        HtmlBody: Text;
    begin
        // [SCENARIO] Bug 630843: SetBody with HTML inline base64 images plus
        // file attachments produces a multipart MimeMessage whose inline-image
        // MimeParts must remain non-disposed when Send/Prepare is called.
        // The AL DotNet wrapper for the MimeEntity returned by
        // BodyBuilder.LinkedResources.Add() must be kept alive in codeunit
        // scope; otherwise it goes out of scope, AL disposes the underlying
        // MimePart, and SmtpClient.Send -> Multipart.Prepare throws
        // ObjectDisposedException: 'MimePart'.

        // [GIVEN] HTML body containing several inline base64 images
        HtmlBody := '<html><body><p>test</p>';
        HtmlBody += '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" />';
        HtmlBody += '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" />';
        HtmlBody += '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPj/HwADBwIAMCbHYQAAAABJRU5ErkJggg==" />';
        HtmlBody += '</body></html>';

        // [WHEN] An SMTPMessage is built with sender, recipient, subject,
        // HTML body (which triggers ConvertBase64ImagesToContentId) and a
        // regular file attachment (which produces nested multipart structure)
        SMTPMessageImpl.AddFrom('Sender', 'sender@test.com');
        Recipients.Add('recipient@test.com');
        SMTPMessageImpl.SetToRecipients(Recipients);
        SMTPMessageImpl.SetSubject('Inline image dispose repro');
        SMTPMessageImpl.SetBody(HtmlBody, true);

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('attachment content');
        TempBlob.CreateInStream(InStr);
        SMTPMessageImpl.AddAttachment(InStr, 'attachment.txt');

        // [THEN] MimeMessage.Prepare() (the same call SmtpClient.Send makes
        // internally) succeeds without ObjectDisposedException
        LibraryAssert.IsTrue(
            SMTPMessageImpl.TryPrepareMessage(),
            StrSubstNo('MimeMessage.Prepare() failed — inline-image MimePart was disposed: %1', GetLastErrorText()));
    end;

    local procedure Initialize(var iSMTPClient: Interface "iSMTP Client")
    var
        SMTPAPIClientMock: Codeunit "SMTP API Client Mock";
    begin
        TestServerPort := 255;
        SMTPAPIClientMock.Initialize(iSMTPClient);
    end;

}