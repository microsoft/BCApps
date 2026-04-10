// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

codeunit 1569 "Microsoft Learn Privacy Notice"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ShowingPrivacyNoticeTelemetryTxt: Label 'Showing privacy notice for Microsoft Learn', Locked = true;
        TelemetryCategoryTxt: Label 'Privacy Notice Microsoft Learn', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", OnBeforeShowPrivacyNotice, '', false, false)]
    local procedure ShowPrivacyNoticeMicrosoftLearn(PrivacyNotice: Record "Privacy Notice"; var Handled: Boolean)
    var
        SystemPrivacyNoticeReg: Codeunit "System Privacy Notice Reg.";
        MicrosoftLearnPrivacyNoticePage: Page "Microsoft Learn Privacy Notice";
    begin
        if Handled then
            exit;

        if UpperCase(PrivacyNotice.ID) <> UpperCase(SystemPrivacyNoticeReg.GetMicrosoftLearnID()) then
            exit;

        Session.LogMessage('0000OQN', ShowingPrivacyNoticeTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
        MicrosoftLearnPrivacyNoticePage.SetRecord(PrivacyNotice);
        MicrosoftLearnPrivacyNoticePage.RunModal();
        Handled := true;
    end;
}
