// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;

/// <summary>
/// Used to mock selected file accounts on File Accounts page.
/// </summary>
codeunit 135812 "Ext. File Storage Acc Sel Mock"
{
    EventSubscriberInstance = Manual;

    var
        SelectionFilterLbl: Label '%1|%2', Locked = true;

    procedure SelectAccount(AccountId: Guid)
    begin
        SelectedAccounts.Add(AccountId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Account Impl.", 'OnAfterSetSelectionFilter', '', false, false)]
    local procedure SelectAccounts(var TempFileAccount: Record "File Account" temporary)
    var
        AccountId: Guid;
        SelectionFilter: Text;
    begin
        TempFileAccount.Reset();

        foreach AccountId in SelectedAccounts do
            SelectionFilter := StrSubstNo(SelectionFilterLbl, SelectionFilter, AccountId);

        SelectionFilter := DelChr(SelectionFilter, '<>', '|'); // remove trailing and leading pipes

        if SelectionFilter <> '' then
            TempFileAccount.SetFilter("Account Id", SelectionFilter);
    end;

    var
        SelectedAccounts: List of [Guid];
}