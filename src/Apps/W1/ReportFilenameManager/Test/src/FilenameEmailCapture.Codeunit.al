// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using System.Email;
using System.Utilities;

codeunit 149543 "Filename Email Capture"
{
    // Reads an email's attachment names at the last point before it is sent (after Base Application
    // has added the reminder's invoices) or downloaded (the fallback with no email account), and
    // stops it there, so nothing is sent or downloaded.

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

    /// <param name="NewStopBeforeSend">False lets the email through to Base Application's sending, which
    /// with no email account is the download fallback.</param>
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
