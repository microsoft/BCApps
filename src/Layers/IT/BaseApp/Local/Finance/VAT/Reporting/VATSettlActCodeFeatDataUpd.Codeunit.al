#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ----------------------------------------------

namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Navigate;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 12136 "VATSettl ActCode FeatDataUpd" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = TableData "Feature Data Update Status" = rm,
                  TableData "Periodic Settlement VAT Entry" = rm,
                  TableData "Periodic VAT Settlement Entry" = rm;

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        if TempDocumentEntry.IsEmpty() then begin
            SetUpgradeTag(false);
            exit(false);
        end;
        exit(true);
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        StartDateTime: DateTime;
        EndDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'UpgradeCalcAndPostPerActivityCode', StartDateTime);
        UpgradeCalcAndPostPerActivityCode();
        EndDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'UpgradeCalcAndPostPerActivityCode', EndDateTime);
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    begin
        SetUpgradeTag(true);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
    end;

    local procedure CountRecords()
    var
        Company: Record Company;
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
        RecordCount: Integer;
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();
        if Company.FindSet() then
            repeat
                PeriodicSettlementVATEntry.ChangeCompany(Company.Name);
                RecordCount += PeriodicSettlementVATEntry.Count();
            until Company.Next() = 0;
        InsertDocumentEntry(Database::"Periodic Settlement VAT Entry", PeriodicSettlementVATEntry.TableCaption(), RecordCount);
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure UpgradeCalcAndPostPerActivityCode()
    var
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
        PeriodicSettlVATEntry: Record "Periodic VAT Settlement Entry";
        PeriodicVATSettlement: Codeunit "Periodic VAT Settlement";
    begin
        if PeriodicSettlementVATEntry.FindSet() then
            repeat
                PeriodicSettlVATEntry."VAT Period" := PeriodicSettlementVATEntry."VAT Period";
                PeriodicSettlVATEntry."VAT Settlement" := PeriodicSettlementVATEntry."VAT Settlement";
                PeriodicSettlVATEntry."Add-Curr. VAT Settlement" := PeriodicSettlementVATEntry."Add-Curr. VAT Settlement";
                PeriodicSettlVATEntry."Prior Period Input VAT" := PeriodicSettlementVATEntry."Prior Period Input VAT";
                PeriodicSettlVATEntry."Prior Period Output VAT" := PeriodicSettlementVATEntry."Prior Period Output VAT";
                PeriodicSettlVATEntry."Add Curr. Prior Per. Inp. VAT" := PeriodicSettlementVATEntry."Add Curr. Prior Per. Inp. VAT";
                PeriodicSettlVATEntry."Add Curr. Prior Per. Out VAT" := PeriodicSettlementVATEntry."Add Curr. Prior Per. Out VAT";
                PeriodicSettlVATEntry."Paid Amount" := PeriodicSettlementVATEntry."Paid Amount";
                PeriodicSettlVATEntry."Advanced Amount" := PeriodicSettlementVATEntry."Advanced Amount";
                PeriodicSettlVATEntry."Add-Curr. Paid. Amount" := PeriodicSettlementVATEntry."Add-Curr. Paid. Amount";
                PeriodicSettlVATEntry."Add-Curr. Advanced Amount" := PeriodicSettlementVATEntry."Add-Curr. Advanced Amount";
                PeriodicSettlVATEntry."Bank Code" := PeriodicSettlementVATEntry."Bank Code";
                PeriodicSettlVATEntry."Paid Date" := PeriodicSettlementVATEntry."Paid Date";
                PeriodicSettlVATEntry.Description := PeriodicSettlementVATEntry.Description;
                PeriodicSettlVATEntry."VAT Period Closed" := PeriodicSettlementVATEntry."VAT Period Closed";
                PeriodicSettlVATEntry."Prior Year Input VAT" := PeriodicSettlementVATEntry."Prior Year Input VAT";
                PeriodicSettlVATEntry."Prior Year Output VAT" := PeriodicSettlementVATEntry."Prior Year Output VAT";
                PeriodicSettlVATEntry."Add Curr.Prior Year Inp. VAT" := PeriodicSettlementVATEntry."Add Curr.Prior Year Inp. VAT";
                PeriodicSettlVATEntry."Add Curr.Prior Year Out. VAT" := PeriodicSettlementVATEntry."Add Curr.Prior Year Out. VAT";
                PeriodicSettlVATEntry."Payable VAT Variation" := PeriodicSettlementVATEntry."Payable VAT Variation";
                PeriodicSettlVATEntry."Deductible VAT Variation" := PeriodicSettlementVATEntry."Deductible VAT Variation";
                PeriodicSettlVATEntry."Tax Debit Variation" := PeriodicSettlementVATEntry."Tax Debit Variation";
                PeriodicSettlVATEntry."Tax Credit Variation" := PeriodicSettlementVATEntry."Tax Credit Variation";
                PeriodicSettlVATEntry."Unpaid VAT Previous Periods" := PeriodicSettlementVATEntry."Unpaid VAT Previous Periods";
                PeriodicSettlVATEntry."Tax Debit Variation Interest" := PeriodicSettlementVATEntry."Tax Debit Variation Interest";
                PeriodicSettlVATEntry."Omit VAT Payable Interest" := PeriodicSettlementVATEntry."Omit VAT Payable Interest";
                PeriodicSettlVATEntry."Credit VAT Compensation" := PeriodicSettlementVATEntry."Credit VAT Compensation";
                PeriodicSettlVATEntry."Special Credit" := PeriodicSettlementVATEntry."Special Credit";
                OnAfterTransferfieldsToPeriodicSettlVATEntry(CompanyName(), PeriodicSettlementVATEntry, PeriodicSettlVATEntry);
                PeriodicVATSettlement.OnAfterTransferfieldsToPeriodicSettlVATEntry(PeriodicSettlementVATEntry, PeriodicSettlVATEntry);
                PeriodicSettlVATEntry.Insert(true);
            until PeriodicSettlementVATEntry.Next() = 0;
    end;

    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTags: Codeunit "Upgrade Tag Def - Country";
    begin
        // Set the upgrade tag to indicate that the data update is executed/skipped and the feature is enabled.
        // This is needed when the feature is enabled by default in a future version, to skip the data upgrade.
        if UpgradeTag.HasUpgradeTag(UpgradeTags.GetPeriodicVATSettlementEntryUpgradeTag()) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgradeTags.GetPeriodicVATSettlementEntryUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgradeTags.GetPeriodicVATSettlementEntryUpgradeTag(), true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferfieldsToPeriodicSettlVATEntry(CalledFromCompanyName: Text[30]; PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; var PeriodicSettlVATEntry: Record "Periodic VAT Settlement Entry")
    begin
    end;
}
#endif