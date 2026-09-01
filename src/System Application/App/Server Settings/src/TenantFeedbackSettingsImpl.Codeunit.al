// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System;

codeunit 3708 "Tenant Feedback Settings Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PPACTenantSettings: DotNet PPACTenantSettings;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        CacheExpiration: DateTime;

    local procedure InitializeConfigSettings()
    begin
        if CurrentDateTime() < GetCacheExpiration() then
            // Cache valid
            exit;

        PPACTenantSettings := ALCopilotFunctions.GetPPACTenantSettings();
        UpdateCacheExpiration();
    end;

    procedure GetCopilotFeedbackEnabled(): Boolean
    begin
        InitializeConfigSettings();
        exit(PPACTenantSettings.CopilotFeedbackEnabled);
    end;

    procedure GetSurveyFeedbackEnabled(): Boolean
    begin
        InitializeConfigSettings();
        exit(PPACTenantSettings.SurveyFeedbackEnabled);
    end;

    procedure GetFeedbackAttachmentsEnabled(): Boolean
    begin
        InitializeConfigSettings();
        exit(PPACTenantSettings.FeedbackAttachmentsEnabled);
    end;

    procedure GetFeedbackReachoutEnabled(): Boolean
    begin
        InitializeConfigSettings();
        exit(PPACTenantSettings.FeedbackReachoutEnabled);
    end;

    procedure GetUserInitiatedFeedbackEnabled(): Boolean
    begin
        InitializeConfigSettings();
        exit(PPACTenantSettings.UserInitiatedFeedbackEnabled);
    end;

    local procedure GetCacheExpiration(): DateTime
    begin
        exit(CacheExpiration);
    end;

    local procedure UpdateCacheExpiration()
    var
        CacheDurationMs: Integer;
    begin
        CacheDurationMs := 1000 * 60 * 30;
        CacheExpiration := CurrentDateTime() + CacheDurationMs;
    end;
}