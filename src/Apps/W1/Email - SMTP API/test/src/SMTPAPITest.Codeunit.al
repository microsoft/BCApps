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
        TestServerTxt: Label 'test-smtp-server-host';
        AssertFailFormatTxt: Label '%1 Last error: %2', Locked = true;
        TryPrepareFailedTxt: Label 'MimeMessage.Prepare() failed - inline-image MimePart was disposed: %1', Locked = true;
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
            StrSubstNo(TryPrepareFailedTxt, GetLastErrorText()));
    end;

    local procedure Initialize(var iSMTPClient: Interface "iSMTP Client")
    var
        SMTPAPIClientMock: Codeunit "SMTP API Client Mock";
    begin
        TestServerPort := 255;
        SMTPAPIClientMock.Initialize(iSMTPClient);
    end;

    // ----------------------------------------------------------------------------------------
    // Per-DotNet-API tests
    //
    // These tests catch *silent* breakages caused by upgrades to the underlying email
    // library (MimeKit / MailKit). AL DotNet calls are late-bound, so a signature change
    // in a .NET method only manifests at runtime.
    // ----------------------------------------------------------------------------------------

    [Test]
    [Scope('OnPrem')]
    procedure TestAddFromValidAddress()
    var
        SMTPMessage: Codeunit "SMTP Message";
    begin
        // [SCENARIO] AddFrom with a valid address succeeds.

        // [WHEN] AddFrom is called with a parseable address
        // [THEN] No .NET exception is thrown
        LibraryAssert.IsTrue(TryAddFrom(SMTPMessage, 'Sender Name', 'sender@contoso.com'), 'AddFrom should succeed for a valid address.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddFromInvalidAddress()
    var
        SMTPMessage: Codeunit "SMTP Message";
    begin
        // [SCENARIO] AddFrom with an invalid address fails through the TryFunction (no crash).

        // [WHEN] AddFrom is called with a malformed address
        // [THEN] The TryFunction returns false
        LibraryAssert.IsFalse(TryAddFrom(SMTPMessage, 'Sender', 'not-an-email'), 'AddFrom should fail for an invalid address.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetToRecipientsValid()
    var
        SMTPMessage: Codeunit "SMTP Message";
        Recipients: List of [Text];
    begin
        // [SCENARIO] SetToRecipients with valid addresses populates the To list.

        Recipients.Add('to1@contoso.com');
        Recipients.Add('to2@contoso.com');

        AssertSucceeds(TrySetToRecipients(SMTPMessage, Recipients), 'SetToRecipients should not throw for valid addresses.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetToRecipientsInvalid()
    var
        SMTPMessage: Codeunit "SMTP Message";
        Recipients: List of [Text];
    begin
        // [SCENARIO] SetToRecipients raises a clear error on invalid addresses.

        Recipients.Add('not-an-email');

        LibraryAssert.IsFalse(TrySetToRecipients(SMTPMessage, Recipients), 'SetToRecipients should throw for invalid addresses.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetCCRecipients()
    var
        SMTPMessage: Codeunit "SMTP Message";
        Recipients: List of [Text];
    begin
        // [SCENARIO] SetCCRecipients populates the Cc list.

        Recipients.Add('cc1@contoso.com');
        AssertSucceeds(TrySetCCRecipients(SMTPMessage, Recipients), 'SetCCRecipients should not throw.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBCCRecipients()
    var
        SMTPMessage: Codeunit "SMTP Message";
        Recipients: List of [Text];
    begin
        // [SCENARIO] SetBCCRecipients populates the Bcc list.

        Recipients.Add('bcc1@contoso.com');
        AssertSucceeds(TrySetBCCRecipients(SMTPMessage, Recipients), 'SetBCCRecipients should not throw.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetSubject()
    var
        SMTPMessage: Codeunit "SMTP Message";
    begin
        // [SCENARIO] SetSubject assigns the subject without throwing.

        AssertSucceeds(TrySetSubject(SMTPMessage, 'Hello world'), 'SetSubject should not throw.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBodyText()
    var
        SMTPMessage: Codeunit "SMTP Message";
    begin
        // [SCENARIO] Plain-text body assignment succeeds.

        AssertSucceeds(TrySetBody(SMTPMessage, 'Plain text body', false), 'SetBody (text) should not throw.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBodyHtmlPlain()
    var
        SMTPMessage: Codeunit "SMTP Message";
    begin
        // [SCENARIO] HTML body without inline images succeeds.

        AssertSucceeds(TrySetBody(SMTPMessage, '<html><body><p>Hello</p></body></html>', true), 'SetBody (HTML, no images) should not throw.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetBodyHtmlWithBase64Image()
    var
        SMTPMessage: Codeunit "SMTP Message";
    begin
        // [SCENARIO] HTML body containing a single base64-encoded inline image succeeds.
        // Exercises the entire inline-image .NET pipeline.

        AssertSucceeds(TrySetBody(SMTPMessage, BuildHtmlWithInlineImages(1), true), 'SetBody with one inline base64 image should not throw.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddAttachment()
    var
        SMTPMessage: Codeunit "SMTP Message";
        TempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
        AttachmentOutStream: OutStream;
    begin
        // [SCENARIO] AddAttachment with a valid stream returns true.
        // Regression test for incident #1: MimeKit changed the signature of
        // AttachmentCollection.Add to require a CancellationToken.

        TempBlob.CreateOutStream(AttachmentOutStream);
        AttachmentOutStream.WriteText('attachment content');
        TempBlob.CreateInStream(AttachmentInStream);

        LibraryAssert.IsTrue(SMTPMessage.AddAttachment(AttachmentInStream, 'test.txt'), 'AddAttachment should succeed for a valid stream + name.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAddAttachmentFilenameSanitized()
    var
        SMTPMessage: Codeunit "SMTP Message";
        TempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
        AttachmentOutStream: OutStream;
    begin
        // [SCENARIO] AddAttachment with illegal characters in the filename still succeeds.

        TempBlob.CreateOutStream(AttachmentOutStream);
        AttachmentOutStream.WriteText('content');
        TempBlob.CreateInStream(AttachmentInStream);

        LibraryAssert.IsTrue(SMTPMessage.AddAttachment(AttachmentInStream, 'bad<>name?.txt'), 'AddAttachment should succeed when the filename contains illegal characters.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPrepareCompletesForFullMessage()
    var
        SMTPMessageImpl: Codeunit "SMTP Message Impl";
        TempBlob: Codeunit "Temp Blob";
        Recipients: List of [Text];
        OutStr: OutStream;
        InStr: InStream;
    begin
        // [SCENARIO] Building a full message and preparing the MIME message succeeds end-to-end.

        SMTPMessageImpl.AddFrom('Sender', 'sender@contoso.com');
        Recipients.Add('to@contoso.com');
        SMTPMessageImpl.SetToRecipients(Recipients);
        SMTPMessageImpl.SetSubject('Subject');
        SMTPMessageImpl.SetBody('<html><body><p>Hello</p></body></html>', true);

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('document content');
        TempBlob.CreateInStream(InStr);
        SMTPMessageImpl.AddAttachment(InStr, 'doc.txt');

        LibraryAssert.IsTrue(SMTPMessageImpl.TryPrepareMessage(), 'TryPrepareMessage should succeed for a fully-constructed message.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPrepareWithMultipleInlineImages()
    var
        SMTPMessageImpl: Codeunit "SMTP Message Impl";
    begin
        // [SCENARIO] A message with several inline base64 images can be prepared without
        // ObjectDisposedException.

        SMTPMessageImpl.AddFrom('Sender', 'sender@contoso.com');
        SMTPMessageImpl.SetSubject('Multi-image regression');
        SMTPMessageImpl.SetBody(BuildHtmlWithInlineImages(5), true);

        LibraryAssert.IsTrue(SMTPMessageImpl.TryPrepareMessage(), 'TryPrepareMessage should succeed when the body contains multiple inline base64 images.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPrepareAfterSetBodyAndAttachment()
    var
        SMTPMessageImpl: Codeunit "SMTP Message Impl";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        // [SCENARIO] Setting an HTML body with inline images and then adding an attachment
        // does not invalidate the previously stored linked resources.

        SMTPMessageImpl.AddFrom('Sender', 'sender@contoso.com');
        SMTPMessageImpl.SetSubject('Order regression');
        SMTPMessageImpl.SetBody(BuildHtmlWithInlineImages(2), true);

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('some bytes');
        TempBlob.CreateInStream(InStr);
        SMTPMessageImpl.AddAttachment(InStr, 'attachment.txt');

        LibraryAssert.IsTrue(SMTPMessageImpl.TryPrepareMessage(), 'TryPrepareMessage should succeed when SetBody (with inline images) is followed by AddAttachment.');
    end;

    // ---- helpers ----

    local procedure AssertSucceeds(Result: Boolean; Message: Text)
    begin
        if not Result then
            LibraryAssert.Fail(StrSubstNo(AssertFailFormatTxt, Message, GetLastErrorText()));
    end;

    [TryFunction]
    local procedure TryAddFrom(var SMTPMessage: Codeunit "SMTP Message"; Name: Text; Address: Text)
    begin
        SMTPMessage.AddFrom(Name, Address);
    end;

    [TryFunction]
    local procedure TrySetToRecipients(var SMTPMessage: Codeunit "SMTP Message"; Recipients: List of [Text])
    begin
        SMTPMessage.SetToRecipients(Recipients);
    end;

    [TryFunction]
    local procedure TrySetCCRecipients(var SMTPMessage: Codeunit "SMTP Message"; Recipients: List of [Text])
    begin
        SMTPMessage.SetCCRecipients(Recipients);
    end;

    [TryFunction]
    local procedure TrySetBCCRecipients(var SMTPMessage: Codeunit "SMTP Message"; Recipients: List of [Text])
    begin
        SMTPMessage.SetBCCRecipients(Recipients);
    end;

    [TryFunction]
    local procedure TrySetSubject(var SMTPMessage: Codeunit "SMTP Message"; Subject: Text)
    begin
        SMTPMessage.SetSubject(Subject);
    end;

    [TryFunction]
    local procedure TrySetBody(var SMTPMessage: Codeunit "SMTP Message"; Body: Text; HtmlFormatted: Boolean)
    begin
        SMTPMessage.SetBody(Body, HtmlFormatted);
    end;

    local procedure BuildHtmlWithInlineImages(Count: Integer): Text
    var
        Html: TextBuilder;
        Base64PngTok: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkAAIAAAoAAv/lxKUAAAAASUVORK5CYII=', Locked = true;
        i: Integer;
    begin
        Html.Append('<html><body>');
        for i := 1 to Count do begin
            Html.Append('<p>Image ');
            Html.Append(Format(i));
            Html.Append('</p><img src="data:image/png;base64,');
            Html.Append(Base64PngTok);
            Html.Append('" />');
        end;
        Html.Append('</body></html>');
        exit(Html.ToText());
    end;

}