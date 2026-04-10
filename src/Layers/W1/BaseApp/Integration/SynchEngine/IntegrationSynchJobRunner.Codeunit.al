// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Threading;

codeunit 5339 "Integration Synch. Job Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(Rec."Record ID to Process");
        RunIntegrationTableSynch(IntegrationTableMapping, Rec.GetLastLogEntryNo());
    end;

    procedure RunIntegrationTableSynch(IntegrationTableMapping: Record "Integration Table Mapping"; JobLogEntryNo: Integer)
    begin
        IntegrationTableMapping.SetJobLogEntryNo(JobLogEntryNo);
        CODEUNIT.Run(IntegrationTableMapping."Synch. Codeunit ID", IntegrationTableMapping);
    end;
}

