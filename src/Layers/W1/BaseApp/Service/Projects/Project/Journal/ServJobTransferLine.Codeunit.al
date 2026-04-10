// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;

codeunit 6456 "Serv. Job Transfer Line"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJnlLineToLedgEntry', '', true, false)]
    local procedure OnAfterFromJnlLineToLedgEntry(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Service Order No." := JobJournalLine."Service Order No.";
        JobLedgerEntry."Posted Service Shipment No." := JobJournalLine."Posted Service Shipment No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJnlToPlanningLine', '', true, false)]
    local procedure OnAfterFromJnlToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line")
    begin
        JobPlanningLine."Service Order No." := JobJournalLine."Service Order No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromJobLedgEntryToPlanningLine', '', true, false)]
    local procedure OnAfterFromJobLedgEntryToPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
        JobPlanningLine."Service Order No." := JobLedgEntry."Service Order No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromPlanningSalesLineToJnlLine', '', true, false)]
    local procedure OnAfterFromPlanningSalesLineToJnlLine(var JobJnlLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
        JobJnlLine."Service Order No." := JobPlanningLine."Service Order No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnFromWarehouseActivityLineToJnlLineOnAfterJobJnlLineInsert', '', true, false)]
    local procedure OnFromWarehouseActivityLineToJnlLineOnAfterJobJnlLineInsert(var JobJournalLine: Record "Job Journal Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
        JobJournalLine."Service Order No." := JobPlanningLine."Service Order No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnAfterFromPlanningLineToJnlLine', '', true, false)]
    local procedure OnAfterFromPlanningLineToJnlLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
        JobJournalLine."Service Order No." := JobPlanningLine."Service Order No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Transfer Line", 'OnFromWarehouseActivityLineToJnlLineOnAfterSetJobPlanningLineFilters', '', true, false)]
    local procedure OnFromWarehouseActivityLineToJnlLineOnAfterSetJobPlanningLineFilters(var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.SetLoadFields("Service Order No.");
    end;
}
