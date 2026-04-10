// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Diagnostics;
using System.Environment;
using System.Reflection;
using System.Text;

codeunit 104070 "Upgrade Refs To Rem. Tables"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        RemovedTablesFilter: Text;
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        // There is no check for upgrade tags, as this code needs to run
        // on every upgrade (in case more tables got removed)

        RemovedTablesFilter := GetRemovedTablesFilter();
        CleanUpChangeLogSetup(RemovedTablesFilter);
    end;

    local procedure CleanUpChangeLogSetup(RemovedTablesFilter: Text)
    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        ChangeLogSetupTable.SetFilter("Table No.", RemovedTablesFilter);
        ChangeLogSetupTable.DeleteAll();
    end;

    local procedure GetRemovedTablesFilter(): Text
    var
        TableMetadata: Record "Table Metadata";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        TableMetadataRecordRef: RecordRef;
    begin
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
        TableMetadataRecordRef.GetTable(TableMetadata);
        exit(SelectionFilterManagement.GetSelectionFilter(TableMetadataRecordRef, TableMetadata.FieldNo(ID), false));
    end;
}