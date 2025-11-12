// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using System.Threading;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;

codeunit 5354 "Auto Process Sales Quotes"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
        CreateNAVSalesQuotesFromSubmittedCRMSalesquotes();
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        StartingToProcessQuoteTelemetryMsg: Label 'Job queue entry starting to process %1 quote %2 (quote number %3).', Locked = true;
        CommittingAfterProcessQuoteTelemetryMsg: Label 'Job queue entry committing after processing %1 quote %2 (quote number %3).', Locked = true;

    local procedure CreateNAVSalesQuotesFromSubmittedCRMSalesquotes()
    var
        CRMQuote: Record "CRM Quote";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        IntegrationTableSynch.OnAfterInitSynchJob(TableConnectionType::CRM, Database::"CRM Quote");

        CRMQuote.SetFilter(StateCode, '%1|%2', CRMQuote.StateCode::Active, CRMQuote.StateCode::Won);
        if CRMQuote.FindSet(true) then
            repeat
                Session.LogMessage('0000EU4', StrSubstNo(StartingToProcessQuoteTelemetryMsg, CRMProductName.CDSServiceName(), CRMQuote.QuoteId, CRMQuote.QuoteNumber), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                if CODEUNIT.Run(CODEUNIT::"CRM Quote to Sales Quote", CRMQuote) then begin
                    Session.LogMessage('0000EU5', StrSubstNo(CommittingAfterProcessQuoteTelemetryMsg, CRMProductName.CDSServiceName(), CRMQuote.QuoteId, CRMQuote.QuoteNumber), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                    Commit();
                end;
            until CRMQuote.Next() = 0;
    end;
}

