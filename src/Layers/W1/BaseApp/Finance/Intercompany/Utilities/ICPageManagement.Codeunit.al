// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.Journal;

/// <summary>
/// Extends Page Management with Intercompany-specific page ID resolution.
/// Handles the Intercompany journal template type when resolving the page for a Gen. Journal Line.
/// </summary>
codeunit 8499 "IC Page Management"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnGetGenJournalLinePageIDOnType', '', false, false)]
    local procedure OnGetGenJournalLinePageIDOnType(GenJournalTemplate: Record "Gen. Journal Template"; var CardPageID: Integer)
    begin
        if GenJournalTemplate.Type <> GenJournalTemplate.Type::Intercompany then
            exit;

        CardPageID := Page::"IC General Journal";
    end;
}
