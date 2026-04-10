// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using System.Threading;

codeunit 5354 "Auto Process Sales Quotes"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
        CreateNAVSalesQuotesFromSubmittedCRMSalesquotes();
    end;

    local procedure CreateNAVSalesQuotesFromSubmittedCRMSalesquotes()
    var
        CRMQuote: Record "CRM Quote";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
    begin
        IntegrationTableSynch.OnAfterInitSynchJob(TableConnectionType::CRM, Database::"CRM Quote");

        CRMQuote.SetFilter(StateCode, '%1|%2', CRMQuote.StateCode::Active, CRMQuote.StateCode::Won);
        if CRMQuote.FindSet(true) then
            repeat
                if CODEUNIT.Run(CODEUNIT::"CRM Quote to Sales Quote", CRMQuote) then
                    Commit();
            until CRMQuote.Next() = 0;
    end;
}

