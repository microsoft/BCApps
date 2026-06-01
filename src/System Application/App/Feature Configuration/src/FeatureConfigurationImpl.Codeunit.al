// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Config;

using System;

codeunit 8348 "Feature Configuration Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetConfiguration(ConfigKey: Text; var CallerModuleInfo: ModuleInfo): Text
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        CurrentModuleInfo: ModuleInfo;
        OnlyMicrosoftAllowedErr: Label 'Only the publisher %1 can access configurations.', Comment = '%1 is the publisher of the calling module.';
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.Publisher <> CallerModuleInfo.Publisher then
            Error(OnlyMicrosoftAllowedErr, CurrentModuleInfo.Publisher);

        exit(ALCopilotFunctions.GetConfigurationSetting(ConfigKey));
    end;

}