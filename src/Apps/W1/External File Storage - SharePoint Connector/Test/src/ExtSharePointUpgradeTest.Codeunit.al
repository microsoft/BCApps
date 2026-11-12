// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.Utilities;

codeunit 144584 "Ext. SharePoint Upgrade Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestUpgradeSetsUseLegacyRestAPIOnExistingAccounts()
    var
        ExtSharePointAccount: Record "Ext. SharePoint Account";
        ExtSharePointUpgrade: Codeunit "Ext. SharePoint Upgrade";
        FirstAccountId: Guid;
        SecondAccountId: Guid;
    begin
        // [GIVEN] Accounts created before the flag existed (Use legacy REST API = false)
        ExtSharePointAccount.DeleteAll();
        FirstAccountId := CreateAccount(false);
        SecondAccountId := CreateAccount(false);

        // [WHEN] The upgrade routine runs
        ExtSharePointUpgrade.SetUseLegacyRestAPIForExistingAccounts();

        // [THEN] Existing accounts keep using the REST API so their behavior does not silently change
        ExtSharePointAccount.Get(FirstAccountId);
        Assert.IsTrue(ExtSharePointAccount."Use legacy REST API", 'Existing accounts must be switched to the legacy REST API on upgrade');
        ExtSharePointAccount.Get(SecondAccountId);
        Assert.IsTrue(ExtSharePointAccount."Use legacy REST API", 'All existing accounts must be switched, not just the first one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestUpgradeIsNoOpWhenNoAccountsNeedUpdating()
    var
        ExtSharePointAccount: Record "Ext. SharePoint Account";
        ExtSharePointUpgrade: Codeunit "Ext. SharePoint Upgrade";
        AccountId: Guid;
    begin
        // [GIVEN] Only accounts that already use the legacy REST API
        ExtSharePointAccount.DeleteAll();
        AccountId := CreateAccount(true);

        // [WHEN] The upgrade routine runs
        ExtSharePointUpgrade.SetUseLegacyRestAPIForExistingAccounts();

        // [THEN] The account is untouched
        ExtSharePointAccount.Get(AccountId);
        Assert.IsTrue(ExtSharePointAccount."Use legacy REST API", 'Accounts already on the legacy REST API must stay on it');
    end;

    local procedure CreateAccount(UseLegacyRestAPI: Boolean): Guid
    var
        ExtSharePointAccount: Record "Ext. SharePoint Account";
    begin
        ExtSharePointAccount.Init();
        ExtSharePointAccount.Id := CreateGuid();
        ExtSharePointAccount."Use legacy REST API" := UseLegacyRestAPI;
        ExtSharePointAccount.Insert();
        exit(ExtSharePointAccount.Id);
    end;
}
