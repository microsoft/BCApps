// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Reporting;
using System.Azure.Identity;
using System.Email;
using System.Integration;
using System.IO;
using System.Security.AccessControl;
using System.Utilities;

codeunit 5052 AttachmentManagement
{

    trigger OnRun()
    begin
    end;

    var
        Text000Msg: Label 'Send attachments...\\';
        Text001Msg: Label 'Preparing';
        Text002Msg: Label 'Deliver misc.';
        Text008Msg: Label 'The interaction template has no attachment for the selected language code.';
        AttachmentTok: Label 'Attachment';

    [Scope('OnPrem')]
    procedure InsertAttachment(AttachmentNo: Integer): Integer
    var
        Attachment: Record Attachment;
        Attachment3: Record Attachment;
        IsHandled: Boolean;
    begin
        if AttachmentNo <> 0 then begin
            Attachment.Get(AttachmentNo);
            if Attachment."Storage Type" = Attachment."Storage Type"::Embedded then
                Attachment.CalcFields("Attachment File");
            Attachment3 := Attachment; // Remember "from" attachment
        end;

        Attachment.Insert(true);

        IsHandled := false;
        OnInsertAttachmentOnAfterAttachmentInserted(Attachment, AttachmentNo, Attachment3, IsHandled);
        if IsHandled then
            exit(Attachment."No.");

        if AttachmentNo <> 0 then
            // New attachment is based on old attachment
            TransferAttachment(Attachment3, Attachment); // Transfer attachments of different types.

        exit(Attachment."No.");
    end;

    [Scope('OnPrem')]
    procedure Send(var DeliverySorter: Record "Delivery Sorter")
    var
        TempDeliverySorterHtml: Record "Delivery Sorter" temporary;
        TempDeliverySorterWord: Record "Delivery Sorter" temporary;
        TempDeliverySorterOther: Record "Delivery Sorter" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
        WordTemplateInteractions: Codeunit "Word Template Interactions";
        IsHandled: Boolean;
    begin
        OnBeforeSend(DeliverySorter, IsHandled);
        if IsHandled then
            exit;
        ProcessDeliverySorter(DeliverySorter, TempDeliverySorterHtml, TempDeliverySorterWord, TempDeliverySorterOther);

        if TempDeliverySorterWord.FindFirst() then
            WordTemplateInteractions.Merge(TempDeliverySorterWord);

        if TempDeliverySorterHtml.FindFirst() then
            DeliverHTMLEmail(TempDeliverySorterHtml, InteractionLogEntry);

        if TempDeliverySorterOther.FindFirst() then
            DeliverEmailWithAttachment(TempDeliverySorterOther, InteractionLogEntry);

        OnAfterSend(
          DeliverySorter, TempDeliverySorterHtml, TempDeliverySorterWord,
          TempDeliverySorterOther, InteractionLogEntry);
    end;

    [Scope('OnPrem')]
    procedure SendUsingExchange(var DeliverySorter: Record "Delivery Sorter")
    var
        TempDeliverySorterHtml: Record "Delivery Sorter" temporary;
        TempDeliverySorterWord: Record "Delivery Sorter" temporary;
        TempDeliverySorterOther: Record "Delivery Sorter" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
        WordTemplateInteractions: Codeunit "Word Template Interactions";
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
    begin
        ProcessDeliverySorter(DeliverySorter, TempDeliverySorterHtml, TempDeliverySorterWord, TempDeliverySorterOther);

        if TempDeliverySorterWord.FindFirst() then
            WordTemplateInteractions.Merge(TempDeliverySorterWord);

        InitializeExchange(ExchangeWebServicesServer);
        if TempDeliverySorterHtml.FindFirst() then
            DeliverHTMLEmailViaExchange(ExchangeWebServicesServer, TempDeliverySorterHtml, InteractionLogEntry);

        if TempDeliverySorterOther.FindFirst() then
            DeliverEmailWithAttachmentViaExchange(ExchangeWebServicesServer, TempDeliverySorterOther, InteractionLogEntry);
    end;

    local procedure TransferAttachment(FromAttachment: Record Attachment; var ToAttachment: Record Attachment)
    var
        RMarketingSetup: Record "Marketing Setup";
        FileName: Text;
    begin
        // Transfer attachments of different types

        if (FromAttachment."Storage Type" = FromAttachment."Storage Type"::Embedded) and
           (ToAttachment."Storage Type" = ToAttachment."Storage Type"::"Disk File")
        then begin
            FileName := ToAttachment.ConstDiskFileName();
            FromAttachment.ExportAttachmentToServerFile(FileName); // Export blob to UNC location
            Clear(ToAttachment."Attachment File");
            RMarketingSetup.Get();
            RMarketingSetup.TestField("Attachment Storage Location");
            ToAttachment."Storage Pointer" := RMarketingSetup."Attachment Storage Location";
            ToAttachment.Modify();
        end;

        if (FromAttachment."Storage Type" = FromAttachment."Storage Type"::"Disk File") and
           (ToAttachment."Storage Type" = ToAttachment."Storage Type"::"Disk File")
        then begin
            // Copy external attachment (to new storage)
            RMarketingSetup.Get();
            RMarketingSetup.TestField("Attachment Storage Location");
            ToAttachment."Storage Pointer" := RMarketingSetup."Attachment Storage Location";
            ToAttachment.Modify();
            FILE.Copy(FromAttachment.ConstDiskFileName(), ToAttachment.ConstDiskFileName());
        end;

        if (FromAttachment."Storage Type" = FromAttachment."Storage Type"::"Disk File") and
           (ToAttachment."Storage Type" = ToAttachment."Storage Type"::Embedded)
        then begin
            // Transfer External to Embedded attachment
            ToAttachment.ImportAttachmentFromServerFile(FromAttachment.ConstDiskFileName(), true, false); // Import file from UNC location
            ToAttachment."File Extension" := FromAttachment."File Extension";
            ToAttachment."Storage Pointer" := '';
            ToAttachment.Modify();
        end;
    end;

    procedure InteractionEMail(var InteractionLogEntry: Record "Interaction Log Entry") EMailAddress: Text[80]
    var
        Contact: Record Contact;
        ContactAltAddress: Record "Contact Alt. Address";
        IsHandled: Boolean;
    begin
        OnBeforeInteractionEMail(InteractionLogEntry, EMailAddress, IsHandled);
        if IsHandled then
            exit(EMailAddress);

        if InteractionLogEntry."Contact Alt. Address Code" = '' then begin
            Contact.Get(InteractionLogEntry."Contact No.");
            exit(Contact."E-Mail");
        end;
        ContactAltAddress.Get(InteractionLogEntry."Contact No.", InteractionLogEntry."Contact Alt. Address Code");
        if ContactAltAddress."E-Mail" <> '' then
            exit(ContactAltAddress."E-Mail");

        Contact.Get(InteractionLogEntry."Contact No.");
        exit(Contact."E-Mail");
    end;

    [Scope('OnPrem')]
    procedure GenerateHTMLContent(var Attachment: Record Attachment; SegmentLine: Record "Segment Line"): Boolean
    begin
        if not Attachment.IsHTML() then
            exit(false);

        if Attachment.IsHTMLReady() then
            exit(true);

        exit(GenerateHTMLReadyAttachmentFromCustomLayout(Attachment, SegmentLine));
    end;

    [Scope('OnPrem')]
    procedure LoadHTMLContent(var Attachment: Record Attachment; SegmentLine: Record "Segment Line"): Text
    begin
        if not Attachment.IsHTML() then
            exit('');

        if Attachment.IsHTMLReady() then
            exit(Attachment.Read());

        exit(LoadHTMLContentFromCustomLayoutAttachment(Attachment, SegmentLine));
    end;

    local procedure LoadHTMLContentFromCustomLayoutAttachment(var Attachment: Record Attachment; SegmentLine: Record "Segment Line") Result: Text
    var
        TempAttachment: Record Attachment temporary;
        FileName: Text;
    begin
        Result := '';
        FileName := GenerateHTMLReadyContentFromCustomLayoutAttachment(Attachment, SegmentLine);
        if FileName = '' then
            exit;

        TempAttachment.Init();
        TempAttachment.ImportAttachmentFromServerFile(FileName, true, true);
        TempAttachment."No." := 0;
        TempAttachment.Insert();
        Result := TempAttachment.Read();
        TempAttachment.RemoveAttachment(false);
    end;

    local procedure GenerateHTMLReadyAttachmentFromCustomLayout(var Attachment: Record Attachment; SegmentLine: Record "Segment Line"): Boolean
    var
        FileName: Text;
    begin
        FileName := GenerateHTMLReadyContentFromCustomLayoutAttachment(Attachment, SegmentLine);
        if FileName = '' then
            exit(false);

        if Attachment.Delete() then;
        Attachment.Init();
        Attachment.ImportAttachmentFromServerFile(FileName, true, true);
        Attachment."No." := 0;
        Attachment.Insert();

        exit(true);
    end;

    local procedure GenerateHTMLReadyContentFromCustomLayoutAttachment(var Attachment: Record Attachment; SegmentLine: Record "Segment Line") FileName: Text
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        EmailMerge: Report "Email Merge";
        FileManagement: Codeunit "File Management";
        ContentBodyText: Text;
        CustomLayoutNo: Code[20];
        CustomLayoutName: Text[250];
    begin
        Clear(EmailMerge);
        FileName := FileManagement.ServerTempFileName('html');
        if FileName = '' then
            exit;

        Attachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutNo, CustomLayoutName);
        if CustomLayoutName <> '' then
            ReportLayoutSelection.SetTempLayoutSelectedName(CustomLayoutName)
        else
            ReportLayoutSelection.SetTempLayoutSelected(CustomLayoutNo);
        EmailMerge.InitializeRequest(SegmentLine, ContentBodyText);
        EmailMerge.SaveAsHtml(FileName);
        ReportLayoutSelection.ClearTempLayoutSelected();
    end;

    local procedure InitializeExchange(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server")
    var
        User: Record User;
    begin
        Commit();
        User.SetRange("User Name", UserId);
        if not User.FindFirst() and not InitializeExchangeWithToken(ExchangeWebServicesServer, User."Authentication Email") then
            Error('');
    end;

    [TryFunction]
    local procedure InitializeExchangeWithToken(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; AuthenticationEmail: Text[250])
    var
        ExchangeServiceSetup: Record "Exchange Service Setup";
        AzureADMgt: Codeunit "Azure AD Mgt.";
        AccessToken: SecretText;
    begin
        AccessToken := AzureADMgt.GetAccessTokenAsSecretText(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), false);

        if not AccessToken.IsEmpty() then begin
            ExchangeWebServicesServer.InitializeWithOAuthToken(AccessToken, ExchangeWebServicesServer.GetEndpoint());
            exit;
        end;

        ExchangeServiceSetup.Get();

        ExchangeWebServicesServer.InitializeWithCertificate(
          ExchangeServiceSetup."Azure AD App. ID", ExchangeServiceSetup."Azure AD App. Cert. Thumbprint",
          ExchangeServiceSetup."Azure AD Auth. Endpoint", ExchangeServiceSetup."Exchange Service Endpoint",
          ExchangeServiceSetup."Exchange Resource Uri");

        ExchangeWebServicesServer.SetImpersonatedIdentity(AuthenticationEmail);
    end;

    local procedure GetSenderSalesPersonEmail(var InteractionLogEntry: Record "Interaction Log Entry"): Text
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalesPersonPurchaser.Get(InteractionLogEntry."Salesperson Code");
        exit(SalesPersonPurchaser."E-Mail");
    end;

    local procedure DeliverHTMLEmail(var TempDeliverySorterHtml: Record "Delivery Sorter" temporary; var InteractLogEntry: Record "Interaction Log Entry")
    var
        Attachment: Record Attachment;
        HtmlBody: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        OnBeforeDeliverHTMLEmail(TempDeliverySorterHtml, InteractLogEntry, IsHandled);
        if IsHandled then
            exit;

        InteractLogEntry.LockTable();
        repeat
            InteractLogEntry.Get(TempDeliverySorterHtml."No.");

            if TempDeliverySorterHtml."Correspondence Type" = TempDeliverySorterHtml."Correspondence Type"::Email then begin
                GetAttachment(Attachment, TempDeliverySorterHtml."Attachment No.", false);
                Clear(HtmlBody);
                Attachment.ExportAttachmentToTempBlob(HtmlBody);
#if not CLEAN27
                OnDeliverHTMLEmailOnBeforeSendEmail(TempDeliverySorterHtml, Attachment, InteractLogEntry, '');
#else
                OnDeliverHTMLEmailOnBeforeSendEmail(TempDeliverySorterHtml, Attachment, InteractLogEntry);

#endif
                SendHTMLEmail(TempDeliverySorterHtml, InteractLogEntry, HtmlBody);
            end else
                SetDeliveryState(InteractLogEntry, false);
        until TempDeliverySorterHtml.Next() = 0;
    end;

    local procedure DeliverHTMLEmailViaExchange(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; var TempDeliverySorterHtml: Record "Delivery Sorter" temporary; var InteractLogEntry: Record "Interaction Log Entry")
    var
        Attachment: Record Attachment;
        FileManagement: Codeunit "File Management";
        EmailBodyFilePath: Text;
    begin
        InteractLogEntry.LockTable();
        repeat
            InteractLogEntry.Get(TempDeliverySorterHtml."No.");

            if TempDeliverySorterHtml."Correspondence Type" = TempDeliverySorterHtml."Correspondence Type"::Email then begin
                GetAttachment(Attachment, TempDeliverySorterHtml."Attachment No.", false);
                EmailBodyFilePath := FileManagement.ServerTempFileName('HTML');
                Attachment.ExportAttachmentToServerFile(EmailBodyFilePath);

                Commit();
                SendHTMLEmailViaExchange(
                  ExchangeWebServicesServer, TempDeliverySorterHtml, InteractLogEntry, Attachment);
                // Clean up
                FileManagement.DeleteServerFile(EmailBodyFilePath)
            end else
                SetDeliveryState(InteractLogEntry, false);
        until TempDeliverySorterHtml.Next() = 0;
    end;

    local procedure DeliverEmailWithAttachment(var TempDeliverySorterOther: Record "Delivery Sorter" temporary; var InteractLogEntry: Record "Interaction Log Entry")
    var
        Attachment: Record Attachment;
        AttachmentTempBlob: Codeunit "Temp Blob";
        HtmlBody: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        OnBeforeDeliverEmailWithAttachment(TempDeliverySorterOther, IsHandled, InteractLogEntry);
        if IsHandled then
            exit;

        repeat
            InteractLogEntry.LockTable();
            InteractLogEntry.Get(TempDeliverySorterOther."No.");
            if TempDeliverySorterOther."Correspondence Type" = TempDeliverySorterOther."Correspondence Type"::Email then begin
                GetAttachment(Attachment, TempDeliverySorterOther."Attachment No.", false);
                Clear(AttachmentTempBlob);
                Attachment.ExportAttachmentToTempBlob(AttachmentTempBlob);
                Clear(HtmlBody);
                PrepareDummyEmailBody(HtmlBody);
#if not CLEAN27
                OnDeliverEmailWithAttachmentOnBeforeSendEmail(TempDeliverySorterOther, InteractLogEntry, '', '');
#else
                OnDeliverEmailWithAttachmentOnBeforeSendEmail(TempDeliverySorterOther, InteractLogEntry);
#endif
                SendEmailWithAttachment(TempDeliverySorterOther, InteractLogEntry, AttachmentTempBlob, HtmlBody);
            end else
                SetDeliveryState(InteractLogEntry, false);
        until TempDeliverySorterOther.Next() = 0;
    end;

    local procedure DeliverEmailWithAttachmentViaExchange(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; var TempDeliverySorterOther: Record "Delivery Sorter" temporary; var InteractLogEntry: Record "Interaction Log Entry")
    var
        Contact: Record Contact;
        FileManagement: Codeunit "File Management";
        WindowDialog: Dialog;
        I: Integer;
        NoOfAttachments: Integer;
        AttachmentFileFullName: Text;
    begin
        WindowDialog.Open(
          Text000Msg +
          '#1############ @2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\' +
          '#3############ @4@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

        WindowDialog.Update(1, Text001Msg);
        WindowDialog.Update(2, 10000);
        WindowDialog.Update(3, Text002Msg);
        I := 0;
        NoOfAttachments := TempDeliverySorterOther.Count();
        repeat
            InteractLogEntry.LockTable();
            InteractLogEntry.Get(TempDeliverySorterOther."No.");
            if TempDeliverySorterOther."Correspondence Type" = TempDeliverySorterOther."Correspondence Type"::Email then begin
                // Export the attachment to the server TEMP directory, giving it a GUID
                AttachmentFileFullName := PrepareServerAttachment(
                    TempDeliverySorterOther."Attachment No.");

                // Send the mail
                Contact.Get(InteractLogEntry."Contact No.");
                SendEmailWithAttachmentViaExchange(
                  ExchangeWebServicesServer, TempDeliverySorterOther, InteractLogEntry, AttachmentFileFullName);
                // Clean up
                FileManagement.DeleteServerFile(AttachmentFileFullName);
            end else
                SetDeliveryState(InteractLogEntry, false);
            I := I + 1;
            WindowDialog.Update(4, Round(I / NoOfAttachments * 10000, 1));
        until TempDeliverySorterOther.Next() = 0;
        WindowDialog.Close();
    end;

    local procedure SendHTMLEmail(var TempDeliverySorterHtml: Record "Delivery Sorter" temporary; var InteractLogEntry: Record "Interaction Log Entry"; var HtmlBody: Codeunit "Temp Blob")
    var
        Contact: Record Contact;
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        AttachmentInStream: Instream;
        IsSent: Boolean;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        TempBlob.CreateInStream(AttachmentInStream);

        SourceTableIDs.Add(Database::"Interaction Log Entry");
        SourceIDs.Add(InteractLogEntry.SystemId);
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        if Contact.Get(InteractLogEntry."Contact No.") then begin
            SourceTableIDs.Add(Database::Contact);
            SourceIDs.Add(Contact.SystemId);
            SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
        end;

        IsSent := DocumentMailing.EmailFile(
            AttachmentInStream, '', HtmlBody,
            TempDeliverySorterHtml.Subject, InteractionEMail(InteractLogEntry), false, Enum::"Email Scenario"::Default, SourceTableIDs, SourceIDs, SourceRelationTypes);

        SetDeliveryState(InteractLogEntry, IsSent);
    end;

    local procedure SendHTMLEmailViaExchange(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; var TempDeliverySorterHtml: Record "Delivery Sorter" temporary; var InteractLogEntry: Record "Interaction Log Entry"; Attachment: Record Attachment)
    var
        IsSent: Boolean;
    begin
        IsSent :=
          ExchangeWebServicesServer.SendEmailMessageWithAttachment(
            TempDeliverySorterHtml.Subject, InteractionEMail(InteractLogEntry),
            Attachment.Read(), '', GetSenderSalesPersonEmail(InteractLogEntry));

        SetDeliveryState(InteractLogEntry, IsSent);
    end;

    local procedure SendEmailWithAttachment(TempDeliverySorterOther: Record "Delivery Sorter" temporary; InteractLogEntry: Record "Interaction Log Entry"; var AttachmentTempBlob: Codeunit "Temp Blob"; var HtmlBody: Codeunit "Temp Blob")
    var
        Contact: Record Contact;
        DocumentMailing: Codeunit "Document-Mailing";
        AttachmentStream: Instream;
        IsSent: Boolean;
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
    begin
        if AttachmentTempBlob.HasValue() then
            AttachmentTempBlob.CreateInStream(AttachmentStream);

        SourceTableIDs.Add(Database::"Interaction Log Entry");
        SourceIDs.Add(InteractLogEntry.SystemId);
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        if Contact.Get(InteractLogEntry."Contact No.") then begin
            SourceTableIDs.Add(Database::Contact);
            SourceIDs.Add(Contact.SystemId);
            SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
        end;

        IsSent := DocumentMailing.EmailFile(
            AttachmentStream, GetAttachmentFileDefaultName(TempDeliverySorterOther."Attachment No."),
            HtmlBody, TempDeliverySorterOther.Subject, InteractionEMail(InteractLogEntry), false, Enum::"Email Scenario"::Default, SourceTableIDs, SourceIDs, SourceRelationTypes);

        SetDeliveryState(InteractLogEntry, IsSent);
    end;

    local procedure SendEmailWithAttachmentViaExchange(var ExchangeWebServicesServer: Codeunit "Exchange Web Services Server"; TempDeliverySorterOther: Record "Delivery Sorter" temporary; InteractLogEntry: Record "Interaction Log Entry"; AttachmentFileFullName: Text)
    var
        IsSent: Boolean;
    begin
        IsSent :=
          ExchangeWebServicesServer.SendEmailMessageWithAttachment(
            TempDeliverySorterOther.Subject, InteractionEMail(InteractLogEntry),
            '', AttachmentFileFullName, GetSenderSalesPersonEmail(InteractLogEntry));
        SetDeliveryState(InteractLogEntry, IsSent);
    end;

    local procedure PrepareServerAttachment(AttachmentNo: Integer): Text
    var
        Attachment: Record Attachment;
        FileManagement: Codeunit "File Management";
        TempFileFullName: Text;
        AttachmentFileFullName: Text;
    begin
        GetAttachment(Attachment, AttachmentNo, true);
        TempFileFullName := FileManagement.ServerTempFileName('');
        Attachment.ExportAttachmentToServerFile(TempFileFullName);
        AttachmentFileFullName := FileManagement.CombinePath(
            FileManagement.GetDirectoryName(TempFileFullName), AttachmentTok + '.' + Attachment."File Extension");
        FileManagement.CopyServerFile(TempFileFullName, AttachmentFileFullName, true);
        FileManagement.DeleteServerFile(TempFileFullName);
        exit(AttachmentFileFullName);
    end;

    local procedure SetDeliveryState(var InteractLogEntry: Record "Interaction Log Entry"; IsSent: Boolean)
    begin
        OnBeforeSetDeliveryState(InteractLogEntry, IsSent);
        if IsSent then
            InteractLogEntry."Delivery Status" := InteractLogEntry."Delivery Status"::" "
        else
            InteractLogEntry."Delivery Status" := InteractLogEntry."Delivery Status"::Error;
        OnSetDeliveryStateOnBeforeModifyInteractLogEntry(InteractLogEntry, IsSent);
        InteractLogEntry.Modify();
        Commit();
    end;

    local procedure ProcessDeliverySorter(var DeliverySorter: Record "Delivery Sorter"; var TempDeliverySorterHtml: Record "Delivery Sorter" temporary; var TempDeliverySorterWord: Record "Delivery Sorter" temporary; var TempDeliverySorterOther: Record "Delivery Sorter" temporary)
    var
        Attachment: Record Attachment;
        WordTemplateInteractions: Codeunit "Word Template Interactions";
        Window: Dialog;
        NoOfAttachments: Integer;
        I: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessDeliverySorter(DeliverySorter, TempDeliverySorterHtml, TempDeliverySorterWord, TempDeliverySorterOther, IsHandled);
        if IsHandled then
            exit;

        Window.Open(
          Text000Msg +
          '#1############ @2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\' +
          '#3############ @4@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

        Window.Update(1, Text001Msg);
        Window.Update(3, Text002Msg);

        I := 0;
        if DeliverySorter.Find('-') then begin
            NoOfAttachments := DeliverySorter.Count();
            repeat
                DeliverySorter.TestField("Correspondence Type");
                if not (Attachment.Get(DeliverySorter."Attachment No.")) and (DeliverySorter."Word Template Code" = '') then
                    Error(Text008Msg);
                case true of
                    not (DeliverySorter."Word Template Code" = ''):
                        begin
                            TempDeliverySorterWord := DeliverySorter;
                            TempDeliverySorterWord.Insert();
                        end;
                    Attachment."File Extension" = 'HTML':
                        begin
                            TempDeliverySorterHtml := DeliverySorter;
                            OnProcessDeliverySorterHtml(DeliverySorter, TempDeliverySorterHtml, Attachment, I);
                            TempDeliverySorterHtml.Insert();
                        end;
                    WordTemplateInteractions.IsWordDocumentExtension(Attachment."File Extension"):
                        begin
                            TempDeliverySorterWord := DeliverySorter;
                            OnProcessDeliverySorterWord(DeliverySorter, TempDeliverySorterWord, Attachment, I);
                            TempDeliverySorterWord.Insert();
                        end;
                    else begin
                        TempDeliverySorterOther := DeliverySorter;
                        OnProcessDeliverySorterOther(DeliverySorter, TempDeliverySorterOther, Attachment, I);
                        TempDeliverySorterOther.Insert();
                    end;
                end;
                I := I + 1;
                Window.Update(2, Round(I / NoOfAttachments * 10000, 1));
            until DeliverySorter.Next() = 0;
        end;
        Window.Close();
    end;

    local procedure GetAttachment(var Attachment: Record Attachment; AttachmentNo: Integer; CheckExtension: Boolean)
    begin
        Attachment.Get(AttachmentNo);
        if CheckExtension then
            Attachment.TestField("File Extension");
        Attachment.CalcFields("Attachment File");
    end;

    local procedure PrepareDummyEmailBody(var HtmlBody: Codeunit "Temp Blob")
    var
        OutStream: OutStream;
    begin
        Clear(HtmlBody);
        HtmlBody.CreateOutStream(OutStream);
        OutStream.WriteText('<html><body></body></html>');
    end;

    local procedure GetAttachmentFileDefaultName(AttachmentNo: Integer): Text
    var
        Attachment: Record Attachment;
    begin
        Attachment.Get(AttachmentNo);
        exit(AttachmentTok + '.' + Attachment."File Extension");
    end;

    procedure ConvertCorrespondenceType(CorrespondenceType: Option "Same as Entry","Hard Copy",Email) ReturnType: Enum "Correspondence Type"
    var
        IsHandled: Boolean;
    begin
        case CorrespondenceType of
            CorrespondenceType::"Hard Copy":
                exit(Enum::"Correspondence Type"::"Hard Copy");
            CorrespondenceType::Email:
                exit(Enum::"Correspondence Type"::Email);
            else begin
                OnConvertCorrespondenceTypeElse(CorrespondenceType, ReturnType, IsHandled);
                if IsHandled then
                    exit(ReturnType);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSend(var DeliverySorter: Record "Delivery Sorter"; var DeliverySorterHTML: Record "Delivery Sorter"; var DeliverySorterWord: Record "Delivery Sorter"; var DeliverySorterOther: Record "Delivery Sorter"; var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliverEmailWithAttachment(var DeliverySorter: Record "Delivery Sorter"; var IsHandled: Boolean; var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeliverHTMLEmail(var DeliverySorter: Record "Delivery Sorter"; var InteractionLogEntry: Record "Interaction Log Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInteractionEMail(var InteractionLogEntry: Record "Interaction Log Entry"; var EMailAddress: Text[80]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSend(var DeliverySorter: Record "Delivery Sorter"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDeliveryState(var InteractLogEntry: Record "Interaction Log Entry"; var IsSent: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Parameter AttachmentFileFullName and EmailBodyFilePath will be removed', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnDeliverEmailWithAttachmentOnBeforeSendEmail(var DeliverySorter: Record "Delivery Sorter"; var InteractionLogEntry: Record "Interaction Log Entry"; AttachmentFileFullName: Text; EmailBodyFilePath: Text)
    begin
    end;

    [Obsolete('Parameter EmailBodyFilePath will be removed', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnDeliverHTMLEmailOnBeforeSendEmail(var DeliverySorter: Record "Delivery Sorter"; Attachment: Record Attachment; var InteractionLogEntry: Record "Interaction Log Entry"; EmailBodyFilePath: Text)
    begin
    end;
#else
    [IntegrationEvent(false, false)]
    local procedure OnDeliverEmailWithAttachmentOnBeforeSendEmail(var DeliverySorter: Record "Delivery Sorter"; var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeliverHTMLEmailOnBeforeSendEmail(var DeliverySorter: Record "Delivery Sorter"; Attachment: Record Attachment; var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnProcessDeliverySorterHtml(var DeliverySorter: Record "Delivery Sorter"; var TempDeliverySorter: Record "Delivery Sorter" temporary; Attachment: Record Attachment; I: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessDeliverySorterOther(var DeliverySorter: Record "Delivery Sorter"; var TempDeliverySorter: Record "Delivery Sorter" temporary; Attachment: Record Attachment; I: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessDeliverySorterWord(var DeliverySorter: Record "Delivery Sorter"; var TempDeliverySorter: Record "Delivery Sorter" temporary; Attachment: Record Attachment; I: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertCorrespondenceTypeElse(CorrespondenceType: Option; var ReturnType: Enum "Correspondence Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetDeliveryStateOnBeforeModifyInteractLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; IsSent: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDeliverySorter(var DeliverySorter: Record "Delivery Sorter"; var TempDeliverySorterHtml: Record "Delivery Sorter" temporary; var TempDeliverySorterWord: Record "Delivery Sorter" temporary; var TempDeliverySorterOther: Record "Delivery Sorter" temporary; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAttachmentOnAfterAttachmentInserted(var Attachment: Record Attachment; AttachmentNo: Integer; var FromAttachment: Record Attachment; var IsHandled: Boolean)
    begin
    end;
}