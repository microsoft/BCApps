// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Integration.Dataverse;
using Microsoft.Utilities;
using System.DataAdministration;
using System.Threading;
using System.Automation;

codeunit 8912 "Environment Cleanup Subs"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure ClearCompanyConfigGeneral(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        ServiceConnection: Record "Service Connection";
        ExchangeSync: Record "Exchange Sync";
        JobQueueManagement: Codeunit "Job Queue Management";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        nullGUID: Guid;
    begin
        // For behavior in all cases of copying a new env.
        if CompanyName() <> CompanyName then begin
            OCRServiceSetup.ChangeCompany(CompanyName);
            DocExchServiceSetup.ChangeCompany(CompanyName);
            CurrExchRateUpdateSetup.ChangeCompany(CompanyName);
            VATRegNoSrvConfig.ChangeCompany(CompanyName);
            ServiceConnection.ChangeCompany(CompanyName);
            ExchangeSync.ChangeCompany(CompanyName);
        end;

        OCRServiceSetup.ModifyAll("Password Key", nullGUID);
        OCRServiceSetup.ModifyAll(Enabled, false);

        DocExchServiceSetup.ModifyAll(Enabled, false);

        CurrExchRateUpdateSetup.ModifyAll(Enabled, false);

        VATRegNoSrvConfig.ModifyAll(Enabled, false);

        CDSIntegrationImpl.CleanCDSIntegration(CompanyName);

        ServiceConnection.ModifyAll(Status, ServiceConnection.Status::Disabled);
        ExchangeSync.ModifyAll(Enabled, false);

        JobQueueManagement.SetRecurringJobsOnHold(CompanyName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure ClearCompanyConfigProdToProd(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        // Example on how to enfore a specific scenario. For instance prod to prod. 
        if (SourceEnv <> SourceEnv::Production) or (DestinationEnv <> DestinationEnv::Production) then
            exit;

        // Prod to prod copy cleanup code goes here

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure ClearDatabaseConfigGeneral(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
    begin
        // For behavior in all cases of copying a new env.

        FlowServiceConfiguration.ModifyAll("Flow Service", FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)");
        Commit();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure ClearDatabaseConfigProdToProd(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        // Example on how to enfore a specific scenario. For instance prod to prod. 
        if (SourceEnv <> SourceEnv::Production) or (DestinationEnv <> DestinationEnv::Production) then
            exit;

        // Prod to prod copy cleanup code goes here

    end;
}
