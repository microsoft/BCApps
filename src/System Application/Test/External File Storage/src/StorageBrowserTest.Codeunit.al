// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.ExternalFileStorage;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 134753 "Storage Browser Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteIsNotEnabledOnParentFolderEntry()
    var
        FileConnectorMock: Codeunit "File Connector Mock";
        AccountId: Guid;
        AccountsPage: TestPage "File Accounts";
        StorageBrowserPage: TestPage "Storage Browser";
    begin
        // [Scenario] The Delete action is not enabled on the parent folder entry ("..") of the Storage Browser, but it is enabled on a file

        // [Given] A file account with a folder and a file
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(AccountId);

        PermissionsMock.Set('File Storage Admin');

        // [Given] The Storage Browser is open on the file account
        AccountsPage.OpenView();
        Assert.IsTrue(AccountsPage.GoToKey(AccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector"), 'The file account should be on the page.');
        StorageBrowserPage.Trap();
        AccountsPage.StorageBrowser.Invoke();

        // [Given] The user has browsed into the folder, so the parent folder entry is shown
        GoToEntry(StorageBrowserPage, 'Test Folder');
        StorageBrowserPage.Name.Drilldown();

        // [When] The parent folder entry is the current row
        GoToEntry(StorageBrowserPage, '..');

        // [Then] The Delete action is not enabled
        Assert.IsFalse(StorageBrowserPage.Delete.Enabled(), 'The Delete action should not be enabled on the parent folder entry.');

        // [When] A file is the current row
        GoToEntry(StorageBrowserPage, 'Test.pdf');

        // [Then] The Delete action is enabled
        Assert.IsTrue(StorageBrowserPage.Delete.Enabled(), 'The Delete action should be enabled on a file.');
    end;

    local procedure GoToEntry(var StorageBrowserPage: TestPage "Storage Browser"; EntryName: Text)
    begin
        StorageBrowserPage.First();
        repeat
            if StorageBrowserPage.Name.Value() = EntryName then
                exit;
        until not StorageBrowserPage.Next();

        Assert.Fail(StrSubstNo('The entry %1 was not found in the Storage Browser.', EntryName));
    end;
}
