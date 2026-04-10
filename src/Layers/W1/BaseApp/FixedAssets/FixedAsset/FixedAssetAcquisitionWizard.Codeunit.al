// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;
using System.Environment.Configuration;

codeunit 5550 "Fixed Asset Acquisition Wizard"
{

    trigger OnRun()
    begin
    end;

    var
        GenJournalBatchNameTxt: Label 'AUTOMATIC', Comment = 'Translate normally and keep the upper case';
        SimpleJnlDescriptionTxt: Label 'Fixed Asset Acquisition';

    procedure RunAcquisitionWizard(FixedAssetNo: Code[20])
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        TempGenJournalLine.SetRange("Account No.", FixedAssetNo);
        PAGE.RunModal(PAGE::"Fixed Asset Acquisition Wizard", TempGenJournalLine);
    end;

    procedure RunAcquisitionWizardFromNotification(FixedAssetAcquisitionNotification: Notification)
    var
        FixedAssetNo: Code[20];
    begin
        InitializeFromNotification(FixedAssetAcquisitionNotification, FixedAssetNo);
        RunAcquisitionWizard(FixedAssetNo);
    end;

    procedure PopulateDataOnNotification(var FixedAssetAcquisitionNotification: Notification; FixedAssetNo: Code[20])
    begin
        FixedAssetAcquisitionNotification.SetData(GetNotificationFANoDataItemID(), FixedAssetNo);
    end;

    procedure InitializeFromNotification(FixedAssetAcquisitionNotification: Notification; var FixedAssetNo: Code[20])
    begin
        FixedAssetNo := FixedAssetAcquisitionNotification.GetData(GetNotificationFANoDataItemID());
    end;

    procedure GetAutogenJournalBatch(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get(SelectFATemplate(), GetDefaultGenJournalBatchName()) then begin
            GenJournalBatch.Init();
            GenJournalBatch."Journal Template Name" := SelectFATemplate();
            GenJournalBatch.Name := CopyStr(GetDefaultGenJournalBatchName(), 1,
                MaxStrLen(GenJournalBatch.Name));
            GenJournalBatch.Description := SimpleJnlDescriptionTxt;
            GenJournalBatch.SetupNewBatch();
            GenJournalBatch.Insert();
        end;

        exit(GenJournalBatch.Name);
    end;

    procedure GetGenJournalBatchName(FANo: Code[20]): Code[10]
    var
        FAJournalSetup: Record "FA Journal Setup";
        FADepreciationBookCode: Code[10];
    begin
        if FANo <> '' then
            FADepreciationBookCode := GetFADeprBookCode(FANo);
        if FADepreciationBookCode <> '' then begin
            if FAJournalSetup.Get(FADepreciationBookCode, UserId()) then
                if FAJournalSetup."Gen. Jnl. Batch Name" <> '' then
                    exit(FAJournalSetup."Gen. Jnl. Batch Name");
            if FAJournalSetup.Get(FADepreciationBookCode, '') then
                if FAJournalSetup."Gen. Jnl. Batch Name" <> '' then
                    exit(FAJournalSetup."Gen. Jnl. Batch Name");
        end;
        exit(GetAutogenJournalBatch())
    end;

    local procedure GetFADeprBookCode(FANo: Code[20]): Code[10]
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("FA No.", FANo);
        if FADepreciationBook.FindFirst() then
            exit(FADepreciationBook."Depreciation Book Code");
    end;

    procedure SelectFATemplate() ReturnValue: Code[10]
    var
        FAJournalLine: Record "FA Journal Line";
        FAJnlManagement: Codeunit FAJnlManagement;
        JnlSelected: Boolean;
    begin
        FAJnlManagement.TemplateSelection(PAGE::"Fixed Asset Journal", false, FAJournalLine, JnlSelected);

        if JnlSelected then begin
            FAJournalLine.FilterGroup := 2;
            ReturnValue := CopyStr(FAJournalLine.GetFilter("Journal Template Name"), 1, MaxStrLen(FAJournalLine."Journal Template Name"));
            FAJournalLine.FilterGroup := 0;
        end;
    end;

    procedure HideNotificationForCurrentUser(Notification: Notification)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if Notification.Id = FixedAsset.GetNotificationID() then
            FixedAsset.DontNotifyCurrentUserAgain();
    end;

    procedure GetNotificationFANoDataItemID(): Text
    begin
        exit('FixedAssetNo');
    end;

    procedure GetDefaultGenJournalBatchName(): Text
    begin
        exit(GenJournalBatchNameTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Fixed Asset Card", 'OnClosePageEvent', '', false, false)]
    local procedure RecallNotificationAboutFAAcquisitionWizardOnFixedAssetCard(var Rec: Record "Fixed Asset")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.RecallNotificationForCurrentUser();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableSaaSNotificationPreferenceSetupOnInitializingNotificationWithDefaultState()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetNotificationDefaultState();
    end;
}

