// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.Upgrade;

/// <summary>
/// Upgrade email attachments to be of type Media instead of BLOB.
/// </summary>
codeunit 8910 "Email Attachment Upgrade"
{
    Subtype = Upgrade;
    InherentPermissions = X;
    InherentEntitlements = X;
    ObsoleteReason = 'Attachment field has been removed in version 26.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetEmailAttachmentUpgradeTag());
    end;

    internal procedure GetEmailAttachmentUpgradeTag(): Code[250]
    begin
        exit('MS-385494-EmailAttachmentToMedia-20210103');
    end;

}
