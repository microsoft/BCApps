namespace System.Email;

using System;
using System.Environment;
using System.IO;
using System.Utilities;

codeunit 9520 "Mail Management"
{
    Permissions = TableData "Email Attachments" = rimd;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        if not IsEnabled() then
            Error(MailingNotSupportedErr);
        if not DoSend() then
            Error(MailWasNotSendErr);
    end;

    var
        TempEmailModuleAccount: Record "Email Account" temporary;
        TempEmailItem: Record "Email Item" temporary;
        ClientTypeManagement: Codeunit "Client Type Management";
        InvalidEmailAddressErr: Label 'The email address "%1" is not valid.', Comment = '%1 - Recipient email address';
        HideMailDialog: Boolean;
        Cancelled: Boolean;
        MailSent: Boolean;
        EnqueueMail: Boolean;
        MailingNotSupportedErr: Label 'The required email is not supported.';
        MailWasNotSendErr: Label 'The email was not sent.';
        SaveFileDialogTitleMsg: Label 'Save PDF file';
        SaveFileDialogFilterMsg: Label 'PDF Files (*.pdf)|*.pdf';
        OutlookSupported: Boolean;
        CannotSendMailThenDownloadQst: Label 'Do you want to download the attachment?';
        CannotSendMailThenDownloadErr: Label 'You cannot send the email.\Verify that the email settings are correct.';
        HideEmailSendingError: Boolean;
        NoScenarioDefinedErr: Label 'No email account defined for the scenario ''%1''. Please, register an account on the ''Email Accounts'' page and assign scenario ''%1'' to it on the ''Email Scenario Setup'' page. Mark one of the accounts as the default account to use it for all scenarios that are not explicitly defined.', Comment = '%1 - The email scenario, for example, Sales Invoice';
        NoDefaultScenarioDefinedErr: Label 'The default account is not selected. Please, register an account on the ''Email Accounts'' page and mark it as the default account on the ''Email Scenario Setup'' page.';
        EmailScenarioMsg: Label 'Sending email using scenario: %1.', Comment = '%1 - Email scenario (e. g. sales order)', Locked = true;
        EmailManagementCategoryTxt: Label 'EmailManagement', Locked = true;
        CurrentEmailScenario: Enum "Email Scenario";

    procedure AddSource(TableId: Integer; SystemId: Guid)
    begin
        TempEmailItem.AddSourceDocument(TableId, SystemId);
    end;

    procedure AddSendTo(EmailAddresses: Text)
    begin
        TempEmailItem."Send to" := CopyStr(EmailAddresses, 1, 250);
    end;

    local procedure SendViaEmailModule(): Boolean
    var
        Email: Codeunit Email;
        Message: Codeunit "Email Message";
        ErrorMessageManagement: Codeunit "Error Message Management";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachmentNames: List of [Text];
        AttachmentStream: Instream;
        Index: Integer;
        ToList: List of [Text];
        CcList: List of [Text];
        BccList: List of [Text];
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendViaEmailModule(TempEmailItem, CurrentEmailScenario, TempEmailModuleAccount, HideMailDialog, IsHandled, MailSent);
        if IsHandled then
            exit(MailSent);

        RecipientStringToList(TempEmailItem."Send to", ToList);
        RecipientStringToList(TempEmailItem."Send CC", CcList);
        RecipientStringToList(TempEmailItem."Send BCC", BccList);

        Message.Create(ToList, TempEmailItem.Subject, TempEmailItem.GetBodyText(), TempEmailItem."Send As HTML", CcList, BccList);

        TempEmailItem.GetSourceDocuments(SourceTableIDs, SourceIDs, SourceRelationTypes);
        for Index := 1 to SourceTableIDs.Count() do
            if SourceRelationTypes.Count() < Index then
                Email.AddRelation(Message, SourceTableIDs.Get(Index), SourceIDs.Get(Index), Enum::"Email Relation Type"::"Related Entity", Enum::"Email Relation Origin"::"Compose Context")
            else
                Email.AddRelation(Message, SourceTableIDs.Get(Index), SourceIDs.Get(Index), Enum::"Email Relation Type".FromInteger(SourceRelationTypes.Get(Index)), Enum::"Email Relation Origin"::"Compose Context");

        OnSendViaEmailModuleOnAfterCreateMessage(Message, TempEmailItem);

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        for Index := 1 to Attachments.Count() do begin
            Attachments.Get(Index, Attachment);
            Attachment.CreateInStream(AttachmentStream);
            Message.AddAttachment(GetAttachmentName(AttachmentNames, Index), '', AttachmentStream);
        end;

        Session.LogMessage('0000CTW', StrSubstNo(EmailScenarioMsg, Format(CurrentEmailScenario)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailManagementCategoryTxt, 'EmailMessageID', Message.GetId());
        OnSendViaEmailModuleOnAfterAddAttachments(Message, TempEmailItem);

        ClearLastError();
        Cancelled := false;
        OnSendViaEmailModuleOnBeforeOpenInEditorModally(CurrentEmailScenario, TempEmailModuleAccount, Message, HideMailDialog);
        if not HideMailDialog then begin
            Commit();
            MailSent := Email.OpenInEditorModallyWithScenario(Message, TempEmailModuleAccount, CurrentEmailScenario) = Enum::"Email Action"::Sent;
            Cancelled := not MailSent;
        end else begin
            Email.AddDefaultAttachments(Message, CurrentEmailScenario);
            if not EnqueueMail then
                MailSent := Email.Send(Message, TempEmailModuleAccount)
            else begin
                Email.Enqueue(Message, TempEmailModuleAccount);
                MailSent := true;
            end;
        end;

        OnSendViaEmailModuleOnAfterEmailSend(Message, TempEmailItem, MailSent, Cancelled, HideEmailSendingError);

        if not MailSent and not Cancelled and not HideEmailSendingError then
            ErrorMessageManagement.LogSimpleErrorMessage(GetLastErrorText());

        exit(MailSent);
    end;

    local procedure GetAttachmentName(AttachmentNames: List of [Text]; Index: Integer) AttachmentName: Text[250]
    begin
        AttachmentName := CopyStr(AttachmentNames.Get(Index), 1, 250);
        OnAfterGetAttachmentName(AttachmentNames, Index, AttachmentName, TempEmailItem);
    end;

    internal procedure RecipientStringToList(DelimitedRecipients: Text; var Recipients: List of [Text])
    var
        Seperators: Text;
    begin
        if DelimitedRecipients = '' then
            exit;

        Seperators := '; ,';
        Recipients := DelimitedRecipients.Split(Seperators.Split());
    end;

    procedure InitializeFrom(NewHideMailDialog: Boolean; NewHideEmailSendingError: Boolean)
    begin
        SetHideMailDialog(NewHideMailDialog);
        SetHideEmailSendingError(NewHideEmailSendingError);
    end;

    procedure SetHideMailDialog(NewHideMailDialog: Boolean)
    begin
        HideMailDialog := NewHideMailDialog;
    end;

    procedure SetHideEmailSendingError(NewHideEmailSendingError: Boolean)
    begin
        HideEmailSendingError := NewHideEmailSendingError;
    end;

    procedure CheckValidEmailAddresses(Recipients: Text)
    var
        TmpRecipients: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckValidEmailAddresses(Recipients, IsHandled);
        if IsHandled then
            exit;

        if Recipients = '' then
            Error(InvalidEmailAddressErr, Recipients);

        TmpRecipients := DelChr(Recipients, '<>', ';');
        while StrPos(TmpRecipients, ';') > 1 do begin
            CheckValidEmailAddress(CopyStr(TmpRecipients, 1, StrPos(TmpRecipients, ';') - 1));
            TmpRecipients := CopyStr(TmpRecipients, StrPos(TmpRecipients, ';') + 1);
        end;
        CheckValidEmailAddress(TmpRecipients);
    end;

    [TryFunction]
    procedure CheckValidEmailAddress(EmailAddress: Text)
    var
        EmailAccount: Codeunit "Email Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckValidEmailAddr(EmailAddress, IsHandled);
        if IsHandled then
            exit;

        EmailAddress := DelChr(EmailAddress, '<>');

        // Check that only one address is validated.
        if EmailAddress.Split('@').Count() <> 2 then
            Error(InvalidEmailAddressErr, EmailAddress);

        if not EmailAccount.ValidateEmailAddress(EmailAddress) then
            Error(InvalidEmailAddressErr, EmailAddress);
    end;

    [TryFunction]
    procedure ValidateEmailAddressField(var EmailAddress: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmailAddressField(EmailAddress, IsHandled);
        if IsHandled then
            exit;

        EmailAddress := DelChr(EmailAddress, '<>');

        if EmailAddress = '' then
            exit;

        CheckValidEmailAddress(EmailAddress);
    end;

    procedure IsEnabled() Result: Boolean
    var
        EmailAccount: Codeunit "Email Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsEnabled(OutlookSupported, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(EmailAccount.IsAnyAccountRegistered());
    end;

    procedure IsCancelled(): Boolean
    begin
        exit(Cancelled);
    end;

    procedure IsSent(): Boolean
    begin
        exit(MailSent);
    end;

    procedure Send(var ParmEmailItem: Record "Email Item"; EmailScenario: Enum "Email Scenario"): Boolean
    begin
        exit(Send(ParmEmailItem, EmailScenario, false));
    end;

    // Email Item needs to be passed by var so the attachments are available
    procedure Send(var ParmEmailItem: Record "Email Item"; EmailScenario: Enum "Email Scenario"; Enqueue: Boolean): Boolean
    var
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
        SourceTables, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        ParmEmailItem.GetAttachments(Attachments, AttachmentNames);
        ParmEmailItem.GetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);
        TempEmailItem := ParmEmailItem;
        TempEmailItem.SetAttachments(Attachments, AttachmentNames);
        TempEmailItem.SetSourceDocuments(SourceTables, SourceIDs, SourceRelationTypes);
        OnSendOnBeforeQualifyFromAddress(TempEmailItem, EmailScenario);
        QualifyFromAddress(EmailScenario);
        CurrentEmailScenario := EmailScenario;
        MailSent := false;
        EnqueueMail := Enqueue;
        exit(DoSend());
    end;

    local procedure DoSend(): Boolean
    begin
        if not CanSend() then
            exit(true);

        SendViaEmailModule();
        if Cancelled then
            exit(true);
        exit(IsSent());
    end;

    local procedure QualifyFromAddress(EmailScenario: Enum "Email Scenario")
    var
        EmailScenarios: Codeunit "Email Scenario";
    begin
        OnBeforeQualifyFromAddress(TempEmailItem);

        // Try get the email account to use by the provided scenario
        if not EmailScenarios.GetEmailAccount(EmailScenario, TempEmailModuleAccount) then
            if EmailScenario = Enum::"Email Scenario"::Default then
                Error(NoDefaultScenarioDefinedErr)
            else
                Error(NoScenarioDefinedErr, EmailScenario);
        OnQualifyFromAddressOnAfterGetEmailAccount(TempEmailItem, EmailScenario, TempEmailModuleAccount);
        exit;
    end;

    procedure SendMailOrDownload(var TempEmailItem: Record "Email Item" temporary; HideMailDialog: Boolean; EmailScenario: Enum "Email Scenario")
    begin
        SendMailOrDownload(TempEmailItem, HideMailDialog, EmailScenario, false);
    end;

    // Email Item needs to be passed by var so the attachments are available
    procedure SendMailOrDownload(var TempEmailItem: Record "Email Item" temporary; HideMailDialog: Boolean; EmailScenario: Enum "Email Scenario"; Enqueue: Boolean)
    var
        MailManagement: Codeunit "Mail Management";
    begin
        MailManagement.InitializeFrom(HideMailDialog, not IsBackground());
        if MailManagement.IsEnabled() then
            if MailManagement.Send(TempEmailItem, EmailScenario, Enqueue) then begin
                OnSendMailOrDownloadOnBeforeMailManagementIsSent(MailManagement, TempEmailItem);
                MailSent := MailManagement.IsSent();
                exit;
            end;

        if IsBackground() then
            exit;

        if not Confirm(StrSubstNo('%1\\%2', CannotSendMailThenDownloadErr, CannotSendMailThenDownloadQst)) then
            exit;

        DownloadPdfAttachment(TempEmailItem);

        OnAfterSendMailOrDownload(TempEmailItem, MailSent);
    end;

    procedure DownloadPdfAttachment(var TempEmailItem: Record "Email Item" temporary)
    var
        DataCompression: Codeunit "Data Compression";
        Attachments: Codeunit "Temp Blob List";
        Attachment: Codeunit "Temp Blob";
        AttachmentArchiveTempBlob: Codeunit "Temp Blob";
        AttachmentNames: List of [Text];
        AttachmentName: Text;
        AttachmentStream: Instream;
        AttachmentOutStream: Outstream;
        AttachmentNumber: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadPdfAttachment(TempEmailItem, IsHandled);
        if IsHandled then
            exit;

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        if Attachments.Count() = 1 then begin
            AttachmentName := AttachmentNames.Get(1);
            Attachments.Get(1, Attachment);
            Attachment.CreateInStream(AttachmentStream);
            DownloadFromStream(AttachmentStream, SaveFileDialogTitleMsg, '', SaveFileDialogFilterMsg, AttachmentName);
        end else begin
            DataCompression.CreateZipArchive();
            for AttachmentNumber := 1 to Attachments.Count() do begin
                AttachmentName := AttachmentNames.Get(AttachmentNumber);
                Attachments.Get(AttachmentNumber, Attachment);
                Attachment.CreateInStream(AttachmentStream);
                DataCompression.AddEntry(AttachmentStream, AttachmentName);
            end;
            AttachmentName := 'Attachments.zip';
            AttachmentArchiveTempBlob.CreateOutStream(AttachmentOutStream);
            DataCompression.SaveZipArchive(AttachmentOutStream);
            DataCompression.CloseZipArchive();
            AttachmentArchiveTempBlob.CreateInStream(AttachmentStream);
            DownloadFromStream(AttachmentStream, SaveFileDialogTitleMsg, '', SaveFileDialogFilterMsg, AttachmentName);
        end;

        OnAfterDownloadPDFAttachment();
    end;

    [Scope('OnPrem')]
    procedure ImageBase64ToUrl(BodyText: Text): Text
    var
        Regex: DotNet Regex;
        Convert: DotNet Convert;
        MemoryStream: DotNet MemoryStream;
        SearchText: Text;
        Base64: Text;
        MimeType: Text;
        MediaId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImageBase64ToUrl(BodyText, SearchText, Regex, MemoryStream, MediaId, Base64, Convert, IsHandled);
        if IsHandled then
            exit(BodyText);

        SearchText := '(.*<img src=\")data:image\/([a-z]+);base64,([a-zA-Z0-9\/+=]+)(\".*)';
        Regex := Regex.Regex(SearchText);
        while Regex.IsMatch(BodyText) do begin
            Base64 := Regex.Replace(BodyText, '$3', 1);
            MimeType := Regex.Replace(BodyText, '$2', 1);
            MemoryStream := MemoryStream.MemoryStream(Convert.FromBase64String(Base64));
            // 20160 =  14days * 24/hours/day * 60min/hour
            MediaId := ImportStreamWithUrlAccess(MemoryStream, Format(CreateGuid()) + MimeType, 20160);

            BodyText := Regex.Replace(BodyText, '$1' + GetDocumentUrl(MediaId) + '$4', 1);
        end;
        exit(BodyText);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryGetSenderEmailAddress(var FromAddress: Text[250])
    begin
        FromAddress := GetSenderEmailAddress(Enum::"Email Scenario"::Default);
    end;

    procedure GetSenderEmailAddress(EmailScenario: Enum "Email Scenario"): Text[250]
    begin
        if not IsEnabled() then
            exit('');
        QualifyFromAddress(EmailScenario);

        OnAfterGetSenderEmailAddress(TempEmailItem);
        exit(TempEmailModuleAccount."Email Address");
    end;

    local procedure CanSend(): Boolean
    var
        CancelSending: Boolean;
    begin
        OnBeforeDoSending(CancelSending);
        exit(not CancelSending);
    end;

    local procedure IsBackground() Result: Boolean
    begin
        Result := ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Background];
        OnAfterIsBackground(Result);
    end;

    procedure IsHandlingGetEmailBody(): Boolean
    begin
        if IsHandlingGetEmailBodyCustomer() then
            exit(true);

        exit(IsHandlingGetEmailBodyVendor());
    end;

    procedure IsHandlingGetEmailBodyCustomer(): Boolean
    var
        Result: Boolean;
    begin
        OnSetIsHandlingGetEmailBodyCustomer(Result);
        exit(Result);
    end;

    procedure IsHandlingGetEmailBodyVendor(): Boolean
    var
        Result: Boolean;
    begin
        OnSetIsHandlingGetEmailBodyVendor(Result);
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnSetIsHandlingGetEmailBodyCustomer', '', false, false)]
    local procedure HandleOnOnSetIsHandlingGetEmailBodyCustomer(var Result: Boolean)
    begin
        Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnSetIsHandlingGetEmailBodyVendor', '', false, false)]
    local procedure HandleOnSetIsHandlingGetEmailBodyVendor(var Result: Boolean)
    begin
        Result := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetIsHandlingGetEmailBodyCustomer(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetIsHandlingGetEmailBodyVendor(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValidEmailAddresses(Recipients: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValidEmailAddr(EmailAddress: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoSending(var CancelSending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEnabled(OutlookSupported: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadPdfAttachment(var TempEmailItem: Record "Email Item" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQualifyFromAddress(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmailAddressField(var EmailAddress: Text; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
#pragma warning disable AA0228
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendMailOnWinClient(var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteTempAttachments(var EmailItem: Record "Email Item")
    begin
    end;
#pragma warning restore AA0228
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSenderEmailAddress(var EmailItem: Record "Email Item")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterIsBackground(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAttachmentName(AttachmentNames: List of [Text]; Index: Integer; var AttachmentName: Text[250]; var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendMailOrDownload(var TempEmailItem: Record "Email Item" temporary; var MailSent: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImageBase64ToUrl(var BodyText: Text; var SearchText: Text; var Regex: DotNet Regex; var MemoryStream: DotNet MemoryStream; var MediaId: Guid; var Base64: Text; var Convert: DotNet Convert; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQualifyFromAddressOnAfterGetEmailAccount(var TempEmailItem: Record "Email Item" temporary; EmailScenario: Enum "Email Scenario"; var TempEmailAccount: Record "Email Account" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendOnBeforeQualifyFromAddress(var TempEmailItem: Record "Email Item" temporary; EmailScenario: Enum "Email Scenario")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendMailOrDownloadOnBeforeMailManagementIsSent(var MailManagement: Codeunit "Mail Management"; TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendViaEmailModuleOnAfterAddAttachments(var Message: Codeunit "Email Message"; var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendViaEmailModuleOnAfterCreateMessage(var Message: Codeunit "Email Message"; var TempEmailItem: Record "Email Item" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendViaEmailModuleOnAfterEmailSend(var Message: Codeunit "Email Message"; var TempEmailItem: Record "Email Item" temporary; var MailSent: Boolean; var Cancelled: Boolean; var HideEmailSendingError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendViaEmailModule(var TempEmailItem: Record "Email Item" temporary; EmailScenario: Enum "Email Scenario"; var TempEmailAccount: Record "Email Account" temporary; HideMailDialog: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDownloadPDFAttachment()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendViaEmailModuleOnBeforeOpenInEditorModally(EmailScenario: Enum "Email Scenario"; var TempEmailAccount: Record "Email Account" temporary; var Message: Codeunit "Email Message"; var HideMailDialog: Boolean)
    begin
    end;
}
