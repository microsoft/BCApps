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
        IsInitialized: Boolean;

    local procedure InitializeConfigSettings()
    begin
        if IsInitialized then
            exit;

        PPACTenantSettings := ALCopilotFunctions.GetPPACTenantSettings();
        IsInitialized := true;
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
}