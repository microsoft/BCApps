// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

codeunit 1357 "Privacy Notice Registrations"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MicrosoftOneDriveTxt: Label 'Microsoft OneDrive', Locked = true; // Product names are not translated and it's important this entry exists.
        MicrosoftExchangeTxt: Label 'Microsoft Exchange', Locked = true;
#if not CLEAN27
        MicrosoftPowerAutomateTxt: Label 'Power Automate', Locked = true;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", 'OnRegisterPrivacyNotices', '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := MicrosoftOneDriveTxt;
        TempPrivacyNotice."Integration Service Name" := MicrosoftOneDriveTxt;
        if not TempPrivacyNotice.Insert() then;

        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := MicrosoftExchangeTxt;
        TempPrivacyNotice."Integration Service Name" := MicrosoftExchangeTxt;
        if not TempPrivacyNotice.Insert() then;
    end;

    procedure GetOneDrivePrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftOneDriveTxt);
    end;

    procedure GetExchangePrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftExchangeTxt);
    end;

#if not CLEAN27
    [Obsolete('This procedure has moved to "Flow Service Management" instead.', '27.0')]
    procedure GetPowerAutomatePrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftPowerAutomateTxt);
    end;
#endif
}
