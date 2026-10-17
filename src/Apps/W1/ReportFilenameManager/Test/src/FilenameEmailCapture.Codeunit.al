// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50193 "Filename Email Capture"
{
    // Reads the attachment names of an email at the last two points Base Application raises before
    // the email leaves or is downloaded, and stops it there: a test session has no mailbox to send
    // from and no browser to receive a file.
    //
    //   Document-Mailing.OnBeforeSendEmail          every attachment on the email item, after Base
    //                                                Application has added the reminder's invoices
    //                                                and named the first attachment
    //   Mail Management.OnBeforeDownloadPdfAttachment the email download fallback, used when no email
    //                                                account is set up
    //
    // Bound manually by Filename Reminder Tests, so nothing outside it is affected.

    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure CaptureBeforeSend(var TempEmailItem: Record "Email Item" temporary; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20]; var HideDialog: Boolean; var ReportUsage: Integer; var EmailSentSuccesfully: Boolean; var IsHandled: Boolean; EmailDocName: Text[250]; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario")
    begin
        if not StopBeforeSend then
            exit;
        Emails.Add(NamesOf(TempEmailItem));
        EmailSentSuccesfully := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeDownloadPdfAttachment', '', false, false)]
    local procedure CaptureDownload(var TempEmailItem: Record "Email Item" temporary; var IsHandled: Boolean)
    begin
        Downloads.Add(NamesOf(TempEmailItem));
        IsHandled := true;
    end;

    /// <summary>
    /// Whether an email is stopped at OnBeforeSendEmail and recorded there, or let through to the
    /// rest of Base Application's sending - which, with no email account, is the download fallback.
    /// </summary>
    /// <param name="NewStopBeforeSend">True to stop and record at OnBeforeSendEmail.</param>
    internal procedure Start(NewStopBeforeSend: Boolean)
    begin
        StopBeforeSend := NewStopBeforeSend;
        Clear(Emails);
        Clear(Downloads);
    end;

    internal procedure CapturedEmails(): List of [Text]
    begin
        exit(Emails);
    end;

    internal procedure CapturedDownloads(): List of [Text]
    begin
        exit(Downloads);
    end;

    local procedure NamesOf(var TempEmailItem: Record "Email Item" temporary) Listed: Text
    var
        Attachments: Codeunit "Temp Blob List";
        Names: List of [Text];
        Name: Text;
    begin
        TempEmailItem.GetAttachments(Attachments, Names);
        Listed := StrSubstNo(CountLbl, Names.Count());
        foreach Name in Names do
            Listed += Name + SeparatorTok;
    end;

    var
        Emails: List of [Text];
        Downloads: List of [Text];
        StopBeforeSend: Boolean;
        CountLbl: Label '%1 attachments: ', Comment = '%1 how many', Locked = true;
        SeparatorTok: Label ' | ', Locked = true;
}
