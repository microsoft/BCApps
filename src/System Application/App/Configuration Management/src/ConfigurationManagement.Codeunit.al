// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Config;

/// <summary>
/// Configuration Management codeunit to get configuration values.
/// </summary>
codeunit 8347 "Configuration Management"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ConfigurationManagementImpl: Codeunit "Configuration Management Impl.";

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
        exit(ConfigurationManagementImpl.GetConfiguration(ConfigKey, CallerModuleInfo));
    end;

}

