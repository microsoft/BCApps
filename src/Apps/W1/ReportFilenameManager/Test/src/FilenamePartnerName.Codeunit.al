// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50183 "Filename Partner Name"
{
    // Stands for another extension that names documents itself, through Electronic Document
    // Format.GetAttachmentFileName's own event, and always gives the same name - whether or not
    // anything named the file before it, as extensions commonly do. Send to Disk names its file
    // through that procedure, so with this bound the partner's name must be the one the file gets,
    // whichever order the subscribers run in. Bound manually.

    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure NameItThePartnersWay(RecordVariant: Variant; DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]; var IsHandled: Boolean; var FileName: Text[250])
    begin
        FileName := PartnerNameTok;
        IsHandled := true;
    end;

    internal procedure PartnerName(): Text
    begin
        exit(PartnerNameTok);
    end;

    var
        PartnerNameTok: Label 'Partner-A.pdf', Locked = true;
}
