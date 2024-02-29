// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.FileSystem;

using System.FileSystem;

/// <summary>
/// Used to mock selected file accounts on File Accounts page.
/// </summary>
codeunit 134697 "File System Acc Selection Mock"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        SelectionFilterLbl: Label '%1|%2', Locked = true;

    internal procedure SelectAccount(AccountId: Guid)
    begin
        SelectedAccounts.Add(AccountId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Account Impl.", 'OnAfterSetSelectionFilter', '', false, false)]
    local procedure SelectAccounts(var FileAccount: Record "File Account")
    var
        SelectionFilter: Text;
        AccountId: Guid;
    begin
        FileAccount.Reset();

        foreach AccountId in SelectedAccounts do
            SelectionFilter := StrSubstNo(SelectionFilterLbl, SelectionFilter, AccountId);

        SelectionFilter := DelChr(SelectionFilter, '<>', '|'); // remove trailing and leading pipes

        if SelectionFilter <> '' then
            FileAccount.SetFilter("Account Id", SelectionFilter);
    end;

    var
        SelectedAccounts: List of [Guid];
}