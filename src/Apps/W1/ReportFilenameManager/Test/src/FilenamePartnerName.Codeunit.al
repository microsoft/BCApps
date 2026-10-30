// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;

codeunit 149533 "Filename Partner Name"
{
    // Stands for another extension that always sets its own name, ignoring any name set before it.
    // With this bound, the partner's name must win whichever order the subscribers run in.

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
