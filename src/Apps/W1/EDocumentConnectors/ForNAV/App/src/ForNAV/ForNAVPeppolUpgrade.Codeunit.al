// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;
codeunit 6413 "ForNAV Peppol Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerCompany()
    begin
        UpdateEndpoint();
    end;

    internal procedure UpdateEndpoint()
    var
        Setup: Record "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        if not Setup.FindFirst() then
            exit;

        Setup.Validate(Endpoint, PeppolOauth.GetDefaultEndpoint());
        Setup.Modify();
    end;
}