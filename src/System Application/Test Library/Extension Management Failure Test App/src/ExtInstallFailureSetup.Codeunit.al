// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps;

codeunit 135111 "Ext. Install Failure Setup"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    var
        InstallMarker: Record "Ext. Install Failure Marker";
    begin
        if not InstallMarker.IsEmpty() then
            Error(InstallFailureErr);

        InstallMarker.Insert();
    end;

    var
        InstallFailureErr: Label 'The test extension installation failed with a detailed error.';
}
