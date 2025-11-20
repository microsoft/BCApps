// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using System.Telemetry;
using System.Threading;

codeunit 107 "Import and Consolidate"
{
    Permissions = tabledata "General Ledger Setup" = R,
                    tabledata "Gen. Journal Batch" = R;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ConsolidationProcess: Record "Consolidation Process";
    begin
        ConsolidationProcess.Get(Rec."Record ID to Process");
        ImportAndConsolidate(ConsolidationProcess);
    end;

    var
        ConsolidationSetup: Record "Consolidation Setup";

    internal procedure ImportAndConsolidate(var ConsolidationProcess: Record "Consolidation Process")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
        BusinessUnit: Record "Business Unit";
        BusUnitConsolidationData: Record "Bus. Unit Consolidation Data";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation From API";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeries: Codeunit "No. Series";
        ConsolidationMethod: Interface "Consolidation Method";
        ImportConsolidationData: Interface "Import Consolidation Data";
        ImportingConsolidationDataTxt: Label 'Importing Consolidation Data';
    begin
        if ConsolidationProcess.Status <> ConsolidationProcess.Status::NotStarted then
            exit;
        Session.LogSecurityAudit(ImportingConsolidationDataTxt, SecurityOperationResult::Success, UserId(), AuditCategory::Euii);
        GeneralLedgerSetup.Get();
        BusUnitInConsProcess.SetRange("Consolidation Process Id", ConsolidationProcess.Id);
        BusUnitInConsProcess.SetAutoCalcFields("Default Data Import Method");

        ConsolidationProcess.Status := ConsolidationProcess.Status::InProgress;
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            GenJournalBatch.Get(ConsolidationProcess."Journal Template Name", ConsolidationProcess."Journal Batch Name");
            GenJournalBatch.TestField("No. Series");
            ConsolidationProcess."Document No." := NoSeries.GetNextNo(GenJournalBatch."No. Series", WorkDate());
        end;
        ConsolidationProcess.Modify();
        Commit();
        if BusUnitInConsProcess.FindSet() then begin
            FeatureTelemetry.LogUptake('0000KOJ', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
            FeatureTelemetry.LogUptake('0000KOG', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
            repeat
                BusinessUnit.Get(BusUnitInConsProcess."Business Unit Code");
                BusUnitInConsProcess.Status := BusUnitInConsProcess.Status::ImportingData;
                BusUnitInConsProcess.Modify();
                Commit();
                BusUnitConsolidationData."Consolidation Process Id" := ConsolidationProcess.Id;
                BusUnitConsolidationData."Business Unit Code" := BusinessUnit.Code;
                GetBusinessUnitConsolidationImplementations(BusinessUnit, BusUnitInConsProcess, ImportConsolidationData, ConsolidationMethod);
                ImportConsolidationData.ImportConsolidationDataForBusinessUnit(ConsolidationProcess, BusinessUnit, BusUnitConsolidationData);
                Session.LogMessage('0000OUM', 'Data imported succesfully', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', ConsolidationSetup.GetTelemetryCategory());
                ConsolidationMethod.Consolidate(ConsolidationProcess, BusinessUnit, BusUnitConsolidationData);
                Session.LogMessage('0000OUN', 'Business unit consolidated succesfully', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', ConsolidationSetup.GetTelemetryCategory());
                BusUnitInConsProcess.Status := BusUnitInConsProcess.Status::Finished;
                BusUnitInConsProcess.Modify();
                Commit();
            until BusUnitInConsProcess.Next() = 0;
            FeatureTelemetry.LogUsage('0000KOH', ImportConsolidationFromAPI.GetFeatureTelemetryName(), 'Completed consolidation imported from API');
        end;
        ConsolidationProcess.Status := ConsolidationProcess.Status::Completed;
        ConsolidationProcess.Modify();
    end;

    local procedure GetBusinessUnitConsolidationImplementations(BusinessUnit: Record "Business Unit"; BusUnitInConsProcess: Record "Bus. Unit In Cons. Process"; var ImportConsolidationDataImplementation: Interface "Import Consolidation Data"; var ConsolidationMethodImplementation: Interface "Consolidation Method")
    begin
        case BusinessUnit."Default Data Import Method" of
            BusinessUnit."Default Data Import Method"::Database:
                ImportConsolidationDataImplementation := Enum::"Import Consolidation Data"::"Import Consolidation Data from DB";
            BusinessUnit."Default Data Import Method"::API:
                ImportConsolidationDataImplementation := Enum::"Import Consolidation Data"::"Import Consolidation Data from API";
        end;
        ConsolidationMethodImplementation := Enum::"Consolidation Method"::Default;
        OnAfterGetBusinessUnitConsolidationImplementations(BusinessUnit, BusUnitInConsProcess, ImportConsolidationDataImplementation, ConsolidationMethodImplementation);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBusinessUnitConsolidationImplementations(BusinessUnit: Record "Business Unit"; BusUnitInConsProcess: Record "Bus. Unit In Cons. Process"; var ImportConsolidationDataImplementation: Interface "Import Consolidation Data"; var ConsolidationMethodImplementation: Interface "Consolidation Method")
    begin
    end;

    // No other event should be required in this codeunit.
#if not CLEAN27
    [IntegrationEvent(false, false)]
    [Obsolete('Please use OnAfterGetBusinessUnitConsolidationImplementations instead. You can override the behavior by providing your own implementations of the interfaces "Import Consolidation Data" and "Consolidation Method"', '27.0')]
    local procedure OnImportAndConsolidateOnBeforeSetConsolidationProcessParameters(var ConsolidationProcess: Record "Consolidation Process"; var BusUnitInConsProcess: Record "Bus. Unit In Cons. Process"; var IsHandled: Boolean)
    begin
    end;
#endif

}
