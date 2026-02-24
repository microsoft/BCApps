// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

/// <summary>
/// Exposes functionality to check the current feedback settings set for this tenant.
/// These settings can be controlled by admins in the Power Platform Admin Center.
/// </summary>
codeunit 3707 "Tenant Feedback Settings"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TenantFeedbackSettingsImpl: Codeunit "Tenant Feedback Settings Impl.";

    /// <summary>
    /// Checks whether Copilot like/dislike feedback is enabled.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetCopilotFeedbackEnabled(): Boolean
    begin
        exit(TenantFeedbackSettingsImpl.GetCopilotFeedbackEnabled());
    end;

    /// <summary>
    /// Checks whether survey feedback is enabled.
    /// </summary>
    procedure GetSurveyFeedbackEnabled(): Boolean
    begin
        exit(TenantFeedbackSettingsImpl.GetSurveyFeedbackEnabled());
    end;

    /// <summary>
    /// Checks whether feedback attachments are enabled.
    /// </summary>
    procedure GetFeedbackAttachmentsEnabled(): Boolean
    begin
        exit(TenantFeedbackSettingsImpl.GetFeedbackAttachmentsEnabled());
    end;

    /// <summary>
    /// Checks whether feedback reachout is enabled.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetFeedbackReachoutEnabled(): Boolean
    begin
        exit(TenantFeedbackSettingsImpl.GetFeedbackReachoutEnabled());
    end;

    /// <summary>
    /// Checks whether user-initiated feedback is enabled.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetUserInitiatedFeedbackEnabled(): Boolean
    begin
        exit(TenantFeedbackSettingsImpl.GetUserInitiatedFeedbackEnabled());
    end;
}