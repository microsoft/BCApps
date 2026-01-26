// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;

codeunit 11612 "Serv. Document Mgt. APAC"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterShouldCheckAdjustmentAppliesTo', '', false, false)]
    local procedure OnAfterShouldCheckAdjustmentAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; var ShouldCheck: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if GenJournalLine."Source Code" = SourceCodeSetup."Service Management" then
            ShouldCheck := false;
    end;
}