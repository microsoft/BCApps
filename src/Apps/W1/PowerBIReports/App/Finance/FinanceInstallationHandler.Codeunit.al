// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.PowerBIReports;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment.Configuration;

codeunit 36953 "Finance Installation Handler"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "G/L Account Category" = r;

    internal procedure SetupDefaultsForPowerBIReportsIfNotInitialized()
    var
        PowerBIAccountCategory: Record "Account Category";
    begin
        if PowerBIAccountCategory.IsEmpty() then
            RestorePowerBIAccountCategories();
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Account Category", 'r')]
    internal procedure RestorePowerBIAccountCategories()
    begin
        InsertL1AccountCategories();
        InsertL2AccountCategories();
        InsertL3AccountCategories();
    end;

    internal procedure NotifyIfAccountCategoryMappingIncomplete()
    var
        MyNotifications: Record "My Notifications";
        Notify: Notification;
        UnmappedCount: Integer;
        IncompleteMappingMsg: Label '%1 Power BI account categories are not mapped to a G/L account category. Related finance KPIs (such as Liquidity, EBITDA, and Aged Receivables/Payables) will show blank values until you complete the mapping.', Comment = '%1 - number of unmapped account categories';
        SetUpMappingLbl: Label 'Set up account categories';
        DontShowAgainLbl: Label 'Don''t show again';
    begin
        UnmappedCount := GetUnmappedRequiredCategoryCount();
        if UnmappedCount = 0 then
            exit;

        if not MyNotifications.Get(UserId(), GetMappingNotificationId()) then
            SetMappingNotificationDefaultState(true);
        if not MyNotifications.IsEnabled(GetMappingNotificationId()) then
            exit;

        Notify.Id := GetMappingNotificationId();
        Notify.Message(StrSubstNo(IncompleteMappingMsg, UnmappedCount));
        Notify.Scope := NotificationScope::LocalScope;
        Notify.AddAction(SetUpMappingLbl, Codeunit::"Finance Installation Handler", 'OpenAccountCategoriesPage');
        Notify.AddAction(DontShowAgainLbl, Codeunit::"Finance Installation Handler", 'DisableMappingNotification');
        Notify.Send();
    end;

    procedure OpenAccountCategoriesPage(Notify: Notification)
    begin
        Page.Run(Page::"Account Categories");
    end;

    procedure DisableMappingNotification(Notify: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetMappingNotificationId()) then
            SetMappingNotificationDefaultState(false);
    end;

    internal procedure SetMappingNotificationDefaultState(DefaultState: Boolean)
    var
        MyNotifications: Record "My Notifications";
        NotificationNameTxt: Label 'Warn about incomplete Power BI account category mapping.';
        NotificationDescTxt: Label 'Show a warning on the Power BI Reports Setup page when some Power BI account categories are not mapped to a G/L account category.';
    begin
        MyNotifications.InsertDefault(GetMappingNotificationId(), NotificationNameTxt, NotificationDescTxt, DefaultState);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    begin
        SetMappingNotificationDefaultState(true);
    end;

    local procedure GetUnmappedRequiredCategoryCount(): Integer
    var
        PowerBIAccountCategory: Record "Account Category";
        UnmappedCount: Integer;
    begin
        if PowerBIAccountCategory.FindSet() then
            repeat
                if IsAccountCategoryRequired(PowerBIAccountCategory."Account Category Type") then
                    if PowerBIAccountCategory."G/L Acc. Category Entry No." = 0 then
                        UnmappedCount += 1;
            until PowerBIAccountCategory.Next() = 0;
        exit(UnmappedCount);
    end;

    local procedure IsAccountCategoryRequired(AccountCategoryType: Enum "Account Category Type"): Boolean
    begin
        // These categories are intentionally left unmapped by default and are optional.
        case AccountCategoryType of
            AccountCategoryType::L2ExtraordinaryExpense,
            AccountCategoryType::L2FXLossesExpense,
            AccountCategoryType::L2FXGainsIncome,
            AccountCategoryType::L2ExtraordinaryIncome,
            AccountCategoryType::L3Purchases,
            AccountCategoryType::L3AccountsPayable:
                exit(false);
            else
                exit(true);
        end;
    end;

    local procedure GetMappingNotificationId(): Guid
    begin
        exit('b6f6b8a4-2c1f-4f2e-9a5a-3c0d6e7f8a90');
    end;

    local procedure InsertL1AccountCategories()
    begin
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L1Assets, 1, 0);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L1Liabilities, 10, 0);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L1Equity, 14, 0);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L1Revenue, 18, 0);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L1CostOfGoodsSold, 26, 0);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L1Expense, 31, 0);
    end;

    local procedure InsertL2AccountCategories()
    begin
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2CurrentAssets, 2, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2CurrentLiabilities, 11, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2PayrollLiabilities, 12, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2LongTermLiabilities, 13, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2ShareholdersEquity, 15, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2InterestExpense, 34, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2TaxExpense, 43, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2InterestRevenue, 24, 1);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2DepreciationAmortizationExpense, 9, 2);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L2FixedAssets, 7, 1);
        InsertPowerBIAccountCategoryWithoutGLAccCategory(Enum::"Account Category Type"::L2ExtraordinaryExpense, 1);
        InsertPowerBIAccountCategoryWithoutGLAccCategory(Enum::"Account Category Type"::L2FXLossesExpense, 1);
        InsertPowerBIAccountCategoryWithoutGLAccCategory(Enum::"Account Category Type"::L2FXGainsIncome, 1);
        InsertPowerBIAccountCategoryWithoutGLAccCategory(Enum::"Account Category Type"::L2ExtraordinaryIncome, 1);
    end;

    local procedure InsertL3AccountCategories()
    begin
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L3Inventory, 6, 2);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L3AccountsReceivable, 4, 2);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L3PurchasePrepayments, 5, 2);
        InsertPowerBIAccountCategory(Enum::"Account Category Type"::L3LiquidAssets, 3, 2);
        InsertPowerBIAccountCategoryWithoutGLAccCategory(Enum::"Account Category Type"::L3Purchases, 2);
        InsertPowerBIAccountCategoryWithoutGLAccCategory(Enum::"Account Category Type"::L3AccountsPayable, 2);
    end;

    local procedure InsertPowerBIAccountCategoryWithoutGLAccCategory(AccountCategoryType: Enum "Account Category Type"; GLAccCatIndentation: Integer)
    begin
        InsertPowerBIAccountCategory(AccountCategoryType, 0, GLAccCatIndentation);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Account Category", 'im')]
    local procedure InsertPowerBIAccountCategory(AccountCategoryType: Enum "Account Category Type"; GLAccCatEntryNo: Integer; GLAccCatIndentation: Integer)
    var
        NewPowerBIAccountCategory: Record "Account Category";
        GLAccCatParentEntryNo: Integer;
    begin
        if not NewPowerBIAccountCategory.Get(AccountCategoryType) then begin
            NewPowerBIAccountCategory.Init();
            NewPowerBIAccountCategory."Account Category Type" := AccountCategoryType;
            NewPowerBIAccountCategory.Insert();
        end;

        if ValidateGLAccountCategory(GLAccCatEntryNo, GLAccCatIndentation, GLAccCatParentEntryNo) then begin
            NewPowerBIAccountCategory."G/L Acc. Category Entry No." := GLAccCatEntryNo;

            if GLAccCatParentEntryNo > 0 then
                NewPowerBIAccountCategory."Parent Acc. Category Entry No." := GLAccCatParentEntryNo;

            NewPowerBIAccountCategory.Modify();
        end;
    end;

    local procedure ValidateGLAccountCategory(EntryNo: Integer; Indentation: Integer; var ParentEntryNo: Integer): Boolean
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if EntryNo = 0 then
            exit(false);

        GLAccountCategory.SetLoadFields(Indentation, "Parent Entry No.");
        if GLAccountCategory.Get(EntryNo) then
            if GLAccountCategory.Indentation = Indentation then begin
                ParentEntryNo := GLAccountCategory."Parent Entry No.";
                exit(true);
            end;
    end;
}
