// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using System.Threading;

codeunit 7206 "CDS Setup Certificate Auth"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CDSConnectionSetup: Record "CDS Connection Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CDSConnectionSetup2: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CRMConnectionSetup2: Record "CRM Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ServerAddress: Text[250];
        UserName: Text[250];
        EmptySecretText: SecretText;
        ProxyVersion: Integer;
    begin
        if not CDSConnectionSetup2.WritePermission() then
            exit;

        if not CRMConnectionSetup2.WritePermission() then
            exit;

        if CDSConnectionSetup.Get() then
            if CDSConnectionSetup."Is Enabled" then begin
                ServerAddress := CDSConnectionSetup."Server Address";
                UserName := CDSConnectionSetup."User Name";
                ProxyVersion := CDSConnectionSetup."Proxy Version";
            end;

        if ServerAddress = '' then
            if CRMConnectionSetup.IsEnabled() then begin
                ServerAddress := CRMConnectionSetup."Server Address";
                UserName := CRMConnectionSetup."User Name";
                ProxyVersion := CRMConnectionSetup."Proxy Version";
            end;

        if (ServerAddress = '') or (ProxyVersion = 0) or (UserName = '') then
            exit;

        TempCDSConnectionSetup."Server Address" := ServerAddress;
        TempCDSConnectionSetup."User Name" := UserName;
        TempCDSConnectionSetup."Proxy Version" := ProxyVersion;
        TempCDSConnectionSetup."Authentication Type" := TempCDSConnectionSetup."Authentication Type"::Office365;
        TempCDSConnectionSetup.Insert();

        CDSIntegrationImpl.SetupCertificatetAuthenticationNoPrompt(TempCDSConnectionSetup);

        // if needed (if user name changed and auth type changed to Certificate on the temporary record), update the connection string and user name on both setup records
        if (TempCDSConnectionSetup."Connection String".IndexOf('{CERTIFICATE}') > 0) and (TempCDSConnectionSetup."User Name" <> UserName) then begin
            if CRMConnectionSetup.IsEnabled() then begin
                CRMConnectionSetup."User Name" := TempCDSConnectionSetup."User Name";
                CRMConnectionSetup.SetPassword(EmptySecretText);
                CRMConnectionSetup."Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                CRMConnectionSetup.SetConnectionString(TempCDSConnectionSetup."Connection String");
            end;

            if CDSConnectionSetup.Get() then
                if CDSConnectionSetup."Is Enabled" then begin
                    CDSConnectionSetup."User Name" := TempCDSConnectionSetup."User Name";
                    CDSConnectionSetup.SetPassword(EmptySecretText);
                    CDSConnectionSetup."Proxy Version" := TempCDSConnectionSetup."Proxy Version";
                    CDSConnectionSetup."Connection String" := TempCDSConnectionSetup."Connection String";
                    CDSConnectionSetup.Modify();
                end;
            Session.LogMessage('0000GJ6', StrSubstNo(CertificateConnectionSetupTelemetryMsg, ServerAddress), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end;
    end;

    var
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        CertificateConnectionSetupTelemetryMsg: Label 'Automatical process of setting up the certificate connection to %1 succeeded.', Locked = true;
}
