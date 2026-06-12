// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.AI;

codeunit 8359 "MCP Notifications"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureDisabledMsg: Label 'The MCP server feature is disabled. Clients will receive a ''feature disabled'' error until you enable the MCP server capability on the Copilot & agent capabilities page.';
        OpenCapabilitiesPageLbl: Label 'Open Copilot & agent capabilities';
        FeatureDisabledNotificationIdLbl: Label '7d6f6b3c-9d8f-4e8e-9c1e-2a3b4c5d6e7f', Locked = true;

    /// <summary>
    /// Sends a non-modal notification when the MCP server capability is deactivated. No-op when active.
    /// </summary>
    internal procedure ShowFeatureDisabledIfApplicable()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        FeatureDisabledNotification: Notification;
        AppId: Guid;
    begin
        AppId := GetMCPAppId();
        if CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"MCP Server", AppId) then
            exit;

        FeatureDisabledNotification.Id := FeatureDisabledNotificationIdLbl;
        FeatureDisabledNotification.Message := FeatureDisabledMsg;
        FeatureDisabledNotification.Scope := NotificationScope::LocalScope;
        FeatureDisabledNotification.AddAction(OpenCapabilitiesPageLbl, Codeunit::"MCP Notifications", 'OpenCopilotCapabilitiesPage');
        FeatureDisabledNotification.Send();
    end;

    procedure OpenCopilotCapabilitiesPage(FeatureDisabledNotification: Notification)
    begin
        Page.Run(Page::"Copilot AI Capabilities");
    end;

    local procedure GetMCPAppId(): Guid
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        exit(ModuleInfo.Id());
    end;
}
