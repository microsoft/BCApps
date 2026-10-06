// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Upgrade;

codeunit 8750 "DA External Storage Upgrade"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Upgrade;
    Permissions = tabledata "Document Attachment" = rm;

    trigger OnUpgradePerCompany()
    begin
        UpgradeExternalFilePathHashes();
    end;

    internal procedure UpgradeExternalFilePathHashes()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetExternalFilePathHashUpgradeTag()) then
            exit;

        DocumentAttachment.SetCurrentKey("Stored Externally", "External File Path Hash");
        DocumentAttachment.SetRange("Stored Externally", true);
        DocumentAttachment.SetRange("External File Path Hash", '');
        DocumentAttachment.SetFilter("External File Path", '<>%1', '');
        DocumentAttachment.LockTable();
        // Each update removes a row from the filtered index; restart rather than advance that cursor.
        while DocumentAttachment.FindFirst() do begin
            DocumentAttachment."External File Path Hash" := DAExternalStorageImpl.GetExternalFilePathHash(DocumentAttachment."External File Path");
            DocumentAttachment.Modify(false);
        end;

        UpgradeTag.SetUpgradeTag(GetExternalFilePathHashUpgradeTag());
    end;

    internal procedure GetExternalFilePathHashUpgradeTag(): Code[250]
    begin
        exit('MS-647643-ExternalAttachmentPathHash-20261006');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetExternalFilePathHashUpgradeTag());
    end;
}
