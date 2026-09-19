// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST.Base;

#if not CLEAN30
codeunit 18025 "Migrate Ecom Merchant Data"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnUpgradePerCompany()
    begin
    end;

    local procedure MoveECommerceData()
    begin
    end;

    local procedure MoveSalesHeaderData()
    begin
    end;

    local procedure MoveSalesInvoiceHeaderData()
    begin
    end;

    local procedure MoveSalesCrMemoHeaderData()
    begin
    end;

    local procedure MoveSalesShipmentHeaderData()
    begin
    end;

    local procedure MoveSalesArchivalHeaderData()
    begin
    end;

    local procedure MoveJournalLineData()
    begin
    end;

    local procedure InitDataMigrationProgressWindow()
    begin
    end;

    local procedure UpdateMigrationProgressWindow(TableID: Integer; RecordCount: Integer)
    begin
    end;

    local procedure UpdateRecordID(TableRecID: RecordID)
    begin
    end;

    local procedure CloseMigrationProgressWindow()
    begin
    end;
}
#endif
