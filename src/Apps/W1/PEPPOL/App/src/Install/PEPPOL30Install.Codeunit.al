// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

codeunit 37215 "PEPPOL30 Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        PEPPOL30Initialize: Codeunit "PEPPOL30 Initialize";
    begin
        PEPPOL30Initialize.CreateElectronicDocumentFormats();
    end;
}