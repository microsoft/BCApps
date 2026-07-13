// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using System.Upgrade;

codeunit 9900 "Data Upgrade Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        DataUpgradeInProgress: Codeunit "Data Upgrade In Progress";

    procedure SetTableSyncSetup(TableId: Integer; UpgradeTableId: Integer; TableUpgradeMode: Option Check,Copy,Move,Force)
    var
        TableSynchSetup: Record "Table Synch. Setup";
    begin
        if TableSynchSetup.Get(TableId) then begin
            TableSynchSetup."Upgrade Table ID" := UpgradeTableId;
            TableSynchSetup.Mode := TableUpgradeMode;
            TableSynchSetup.Modify();
        end;
    end;

    procedure SetUpgradeInProgress()
    begin
        BindSubscription(DataUpgradeInProgress);
    end;

    procedure IsUpgradeInProgress() UpgradeIsInProgress: Boolean
    begin
        OnIsUpgradeInProgress(UpgradeIsInProgress);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsUpgradeInProgress(var UpgradeIsInProgress: Boolean)
    begin
    end;
}

