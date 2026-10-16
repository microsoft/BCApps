// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Intercompany.Journal;

codeunit 8412 "IC Gen. Journal Template"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Template", 'OnAfterValidateType', '', true, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
        if GenJournalTemplate.Type <> GenJournalTemplate.Type::Intercompany then
            exit;

        GenJournalTemplate."Source Code" := SourceCodeSetup."IC General Journal";
        if GenJournalTemplate.Recurring then
            GenJournalTemplate."Page ID" := Page::"Recurring General Journal"
        else
            GenJournalTemplate."Page ID" := Page::"IC General Journal";
    end;
}