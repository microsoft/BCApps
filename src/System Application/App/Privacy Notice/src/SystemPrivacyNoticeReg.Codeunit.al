// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

/// <summary>
/// This codeunit registers platform level privacy notices and provides procedures to consistently reference the privacy notices.
/// </summary>
codeunit 1566 "System Privacy Notice Reg."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MicrosoftTeamsTxt: Label 'Microsoft Teams', Locked = true; // Product names are not translated and it's important this entry exists.
        PowerAutomateIdTxt: Label 'Power Automate', Locked = true; // Product names are not translated and it's important this entry exists.
        PowerAutomateLabelTxt: Label 'Microsoft Power Automate', Locked = true; // Product names are not translated and it's important this entry exists.
        MicrosoftLearnTxt: Label 'Microsoft Learn', Locked = true; // Product names are not translated and it's important this entry exists.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", OnRegisterPrivacyNotices, '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice."ID" := MicrosoftLearnTxt;
        TempPrivacyNotice."Integration Service Name" := MicrosoftLearnTxt;
        if not TempPrivacyNotice.Insert() then;
        TempPrivacyNotice.ID := MicrosoftTeamsTxt;
        TempPrivacyNotice."Integration Service Name" := MicrosoftTeamsTxt;
        if not TempPrivacyNotice.Insert() then;
        TempPrivacyNotice.ID := PowerAutomateIdTxt;
        TempPrivacyNotice."Integration Service Name" := PowerAutomateLabelTxt;
        if not TempPrivacyNotice.Insert() then;
    end;

    /// <summary>
    /// Gets the Microsoft Learn privacy notice identifier.
    /// </summary>
    /// <returns>The privacy notice id for Microsoft Learn.</returns>
    procedure GetMicrosoftLearnID(): Code[50]
    begin
        exit(MicrosoftLearnTxt);
    end;

    /// <summary>
    /// Gets the Microsoft Teams privacy notice identifier.
    /// </summary>
    /// <returns>The privacy notice id for Microsoft Teams.</returns>
    procedure GetTeamsPrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftTeamsTxt);
    end;

    /// <summary>
    /// Gets the Power Automate privacy notice identifier.
    /// </summary>
    /// <returns>The privacy notice id for Power Automate.</returns>
    procedure GetPowerAutomatePrivacyNoticeId(): Code[50]
    begin
        exit(PowerAutomateIdTxt);
    end;

    /// <summary>
    /// Gets the Power Automate privacy notice name.
    /// </summary>
    /// <returns>The privacy notice name for Power Automate.</returns>
    procedure GetPowerAutomatePrivacyNoticeName(): Code[250]
    begin
        exit(PowerAutomateLabelTxt);
    end;
}
