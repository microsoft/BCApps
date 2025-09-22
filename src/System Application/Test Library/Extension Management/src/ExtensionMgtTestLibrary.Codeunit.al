// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps;

using System.Apps;

codeunit 135109 "Extension Mgt. Test Library"
{
    var
        ExtensionInstallationImpl: Codeunit "Extension Installation Impl";

    procedure RunExtensionSetup(AppId: Guid)
    begin
        ExtensionInstallationImpl.RunExtensionSetup(AppId);
    end;
}