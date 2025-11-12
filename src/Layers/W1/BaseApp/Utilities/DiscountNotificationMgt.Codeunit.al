// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Purchases.Setup;
using System.Environment.Configuration;

codeunit 65 "Discount Notification Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        MissingDiscountAccountMsg: Label 'G/L accounts for discounts are missing on one or more lines on the General Posting Setup page.';
        DetailsTok: Label 'Open the General Posting Setup page.';

    procedure NotifyAboutMissingSetup(SetupRecordID: RecordID; GenBusPostingGroup: Code[20]; DiscountPosting: Option "No Discounts","Invoice Discounts","Line Discounts","All Discounts"; ExceptDiscountPosting: Integer): Boolean
    begin
        exit(NotifyAboutMissingSetups(SetupRecordID, GenBusPostingGroup, '', DiscountPosting, ExceptDiscountPosting));
    end;

    procedure NotifyAboutMissingSetup(SetupRecordID: RecordID; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; DiscountPosting: Option "No Discounts","Invoice Discounts","Line Discounts","All Discounts"; ExceptDiscountPosting: Integer): Boolean
    begin
        exit(NotifyAboutMissingSetups(SetupRecordID, GenBusPostingGroup, GenProdPostingGroup, DiscountPosting, ExceptDiscountPosting));
    end;

    local procedure NotifyAboutMissingSetups(SetupRecordID: RecordID; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; DiscountPosting: Option "No Discounts","Invoice Discounts","Line Discounts","All Discounts"; ExceptDiscountPosting: Integer): Boolean
    var
        GeneralPostingSetup: Record "General Posting Setup";
        FieldNumber: Integer;
    begin
        RecallNotification(SetupRecordID);
        if DiscountPosting in [DiscountPosting::"No Discounts", ExceptDiscountPosting] then
            exit(false);
        if FindSetupMissingDiscountAccount(SetupRecordID.TableNo, DiscountPosting, GenBusPostingGroup, GenProdPostingGroup, GeneralPostingSetup, FieldNumber) then begin
            SendNotification(SetupRecordID, DiscountPosting, GenBusPostingGroup, GenProdPostingGroup);
            exit(true);
        end;
    end;

    local procedure FindSetupMissingDiscountAccount(SetupTableNo: Integer; DiscountPosting: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; var GeneralPostingSetup: Record "General Posting Setup"; var FieldNumber: Integer): Boolean
    begin
        if GenBusPostingGroup <> '' then
            GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusPostingGroup);
        if GenProdPostingGroup <> '' then
            GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        case SetupTableNo of
            DATABASE::"Sales & Receivables Setup":
                exit(GeneralPostingSetup.FindSetupMissingSalesDiscountAccount(DiscountPosting, FieldNumber));
            DATABASE::"Purchases & Payables Setup":
                exit(GeneralPostingSetup.FindSetupMissingPurchDiscountAccount(DiscountPosting, FieldNumber));
        end;
    end;

    procedure RecallNotification(SetupRecordID: RecordID)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(SetupRecordID, false);
    end;

    local procedure SendNotification(SetupRecordID: RecordID; DiscountPosting: Integer; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notification: Notification;
    begin
        Notification.Message(MissingDiscountAccountMsg);
        Notification.SetData('SetupTableNo', Format(SetupRecordID.TableNo));
        Notification.SetData('DiscountPosting', Format(DiscountPosting));
        Notification.SetData('GenBusPostingGroup', GenBusPostingGroup);
        Notification.SetData('GenProdPostingGroup', GenProdPostingGroup);
        Notification.AddAction(DetailsTok, CODEUNIT::"Discount Notification Mgt.", 'ShowGenPostingSetupMissingDiscountAccounts');
        NotificationLifecycleMgt.SendNotification(Notification, SetupRecordID);
    end;

    procedure ShowGenPostingSetupMissingDiscountAccounts(Notification: Notification)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenBusPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
        SetupTableNo: Integer;
        FieldNumber: Integer;
        DiscountPosting: Option;
    begin
        Evaluate(SetupTableNo, Notification.GetData('SetupTableNo'));
        Evaluate(DiscountPosting, Notification.GetData('DiscountPosting'));
        GenBusPostingGroup := CopyStr(Notification.GetData('GenBusPostingGroup'), 1, MaxStrLen(GenBusPostingGroup));
        GenProdPostingGroup := CopyStr(Notification.GetData('GenProdPostingGroup'), 1, MaxStrLen(GenProdPostingGroup));
        FindSetupMissingDiscountAccount(SetupTableNo, DiscountPosting, GenBusPostingGroup, GenProdPostingGroup, GeneralPostingSetup, FieldNumber);
        PAGE.Run(PAGE::"General Posting Setup", GeneralPostingSetup, FieldNumber);
    end;
}

