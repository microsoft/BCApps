#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.Navigate;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 5866 "Accelerated Depr. Feature" implements "Feature Data Update"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'Accelerated depreciation feature will be always enabled in version 31.0';
    ObsoleteTag = '29.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        FeatureMgtFacade: Codeunit "Feature Management Facade";
        DescriptionTxt: Label 'Existing records in FR BaseApp fields will be copied to W1 BaseApp fields';
        AcceleratedDepreciationLbl: Label 'AcceleratedDepreciation', Locked = true;

    procedure IsEnabled() Enabled: Boolean
    begin
        Enabled := FeatureMgtFacade.IsEnabled(AcceleratedDepreciationLbl);
    end;

    procedure IsDefaultsFeatureEnabled(): Boolean
    begin
        exit(FeatureMgtFacade.IsEnabled(GetAcceleratedDepreciationFeatureKey()));
    end;

    procedure GetAcceleratedDepreciationFeatureKey(): Text[50]
    begin
        exit(AcceleratedDepreciationLbl);
    end;

    procedure IsDataUpdateRequired(): Boolean
    begin
        CountRecords();
        if TempDocumentEntry.IsEmpty() then begin
            SetUpgradeTag(false);
            exit(false);
        end;
        exit(true);
    end;

    procedure ReviewData()
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
        EndDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Accelerated depreciation', StartDateTime);
        UpgradeAcceleratedDepreciation();
        EndDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Accelerated depreciation', EndDateTime);
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        UpdateFeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");

        SetUpgradeTag(true);
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    local procedure CountRecords()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        FAPostingGr: Record "FA Posting Group";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
    begin
        InsertDocumentEntry(Database::"Gen. Journal Line", GenJournalLine.TableCaption(), GenJournalLine.Count());
        InsertDocumentEntry(Database::"Posted Gen. Journal Line", PostedGenJournalLine.TableCaption(), PostedGenJournalLine.Count());
        InsertDocumentEntry(Database::"Depreciation Book", DeprBook.TableCaption(), DeprBook.Count());
        InsertDocumentEntry(Database::"FA Depreciation Book", FADeprBook.TableCaption(), FADeprBook.Count());
        InsertDocumentEntry(Database::"FA Ledger Entry", FALedgEntry.TableCaption(), FALedgEntry.Count());
        InsertDocumentEntry(Database::"FA Posting Group", FAPostingGr.TableCaption(), FAPostingGr.Count());
        InsertDocumentEntry(Database::"FA Reclass. Journal Line", FAReclassJnlLine.TableCaption(), FAReclassJnlLine.Count());
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

    local procedure UpgradeAcceleratedDepreciation()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        FAPostingGr: Record "FA Posting Group";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
    begin
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine."Is Derogatory" := GenJournalLine."Derogatory Line";
                GenJournalLine.Modify();
            until GenJournalLine.Next() = 0;

        if PostedGenJournalLine.FindSet() then
            repeat
                PostedGenJournalLine."Is Derogatory" := PostedGenJournalLine."Derogatory Line";
                PostedGenJournalLine.Modify();
            until PostedGenJournalLine.Next() = 0;

        if DeprBook.FindSet() then
            repeat
                DeprBook."Derogatory Calc." := DeprBook."Derogatory Calculation";
                DeprBook."Integration G/L - Derogatory" := DeprBook."G/L Integration - Derogatory";
                DeprBook.Modify();
            until DeprBook.Next() = 0;

        if FADeprBook.FindSet() then
            repeat
                FADeprBook."Last Derogatory" := FADeprBook."Last Derogatory Date";
                FADeprBook.Modify();
            until FADeprBook.Next() = 0;

        if FALedgEntry.FindSet() then
            repeat
                FALedgEntry."Derogatory Excluded" := FALedgEntry."Exclude Derogatory";
                FALedgEntry.Modify();
            until FALedgEntry.Next() = 0;

        if FAPostingGr.FindSet() then
            repeat
                FAPostingGr."Derogatory Acc." := FAPostingGr."Derogatory Account";
                FAPostingGr."Derogatory Account (Decrease)" := FAPostingGr."Derogatory Acc. (Decrease)";
                FAPostingGr."Derog. Bal. Account (Decrease)" := FAPostingGr."Derog. Bal. Acc. (Decrease)";
                FAPostingGr."Derogatory Expense Acc." := FAPostingGr."Derogatory Expense Account";
                FAPostingGr.Modify();
            until FAPostingGr.Next() = 0;

        if FAReclassJnlLine.FindSet() then
            repeat
                FAReclassJnlLine."Reclass. Derogatory" := FAReclassJnlLine."Reclassify Derogatory";
                FAReclassJnlLine.Modify();
            until FAReclassJnlLine.Next() = 0;
    end;

    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";
    begin
        // Set the upgrade tag to indicate that the data update is executed/skipped and the feature is enabled.
        // This is needed when the feature is enabled by default in a future version, to skip the data upgrade.
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag(), true);
    end;
}
#endif
