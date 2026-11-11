// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

#pragma warning disable AS0088
codeunit 7000127 "Gen. Journal Line Subscr. ES"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account Type', true, false)]
    local procedure GenJournalLineOnAfterValidateAccountType(var Rec: Record "Gen. Journal Line")
    begin
        Rec.ClearInvCrMemoTypeFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Account No.', true, false)]
    local procedure GenJournalLineOnAfterValidateAccountNo(var Rec: Record "Gen. Journal Line")
    begin
        Rec.ClearInvCrMemoTypeFields();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterValidateEvent', 'Bal. Account Type', true, false)]
    local procedure GenJournalLineOnAfterValidateBalAccountType(var Rec: Record "Gen. Journal Line")
    begin
        Rec.ClearInvCrMemoTypeFields();
    end;
}
