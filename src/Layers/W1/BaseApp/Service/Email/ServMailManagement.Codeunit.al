// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Email;

using System.Email;

codeunit 5916 ServMailManagement
{
    TableNo = "Service Email Queue";

    trigger OnRun()
    var
        TempEmailItem: Record "Email Item" temporary;
        MailManagement: Codeunit "Mail Management";
    begin
        // do not silently exit if the sending failed
        if not MailManagement.IsEnabled() then
            Error(EmailSendErr, Rec."To Address", Rec."Subject Line");

        InitTempEmailItem(TempEmailItem, Rec);

        MailManagement.SetHideMailDialog(true);
        MailManagement.SetHideEmailSendingError(false);
        if not MailManagement.Send(TempEmailItem, Enum::"Email Scenario"::"Service Order") then
            Error(EmailSendErr, Rec."To Address", Rec."Subject Line");
    end;

    var
        EmailSendErr: Label 'The email to %1 with subject %2 has not been sent.', Comment = '%1 - To address, %2 - Email subject';

    local procedure InitTempEmailItem(var TempEmailItem: Record "Email Item" temporary; ServiceEmailQueue: Record "Service Email Queue")
    var
        ServerFile: File;
        InStream: Instream;
        IsHandled: Boolean;
    begin
        TempEmailItem.Initialize();
        if File.Exists(ServiceEmailQueue."Attachment Filename") then begin
            ServerFile.Open(ServiceEmailQueue."Attachment Filename");
            ServerFile.CreateInStream(InStream);
            TempEmailItem.AddAttachment(InStream, '');
            ServerFile.Close();
        end;

        IsHandled := false;
        OnInitTempEmailItemOnBeforeSetBodyText(ServiceEmailQueue, TempEmailItem, IsHandled);
        if not IsHandled then
            TempEmailItem.SetBodyText(ServiceEmailQueue."Body Line");
        TempEmailItem."Send to" := ServiceEmailQueue."To Address";
        TempEmailItem."Send CC" := ServiceEmailQueue."Copy-to Address";
        TempEmailItem.Subject := ServiceEmailQueue."Subject Line";
        TempEmailItem.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTempEmailItemOnBeforeSetBodyText(ServiceEmailQueue: Record "Service Email Queue"; var TempEmailItem: Record "Email Item" temporary; var IsHandled: Boolean)
    begin
    end;
}

