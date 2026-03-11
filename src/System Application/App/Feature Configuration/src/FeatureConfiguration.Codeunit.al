// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Config;

/// <summary>
/// Feature configuration codeunit to get configuration values for features.
/// </summary>
codeunit 8347 "Feature Configuration"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureConfigurationImpl: Codeunit "Feature Configuration Impl.";

    /// <summary>
    /// Gets the configuration value for the specified key.
    /// </summary>
    /// <param name="ConfigKey">The configuration key to look up.</param>
    /// <returns>The configuration value associated with the specified key.</returns>
    procedure GetConfiguration(ConfigKey: Text): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(FeatureConfigurationImpl.GetConfiguration(ConfigKey, CallerModuleInfo));
    end;

}

