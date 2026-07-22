// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;

/// <summary>
/// Codeunit that handles Cartera-specific configuration for Gen. Journal Template.
/// </summary>
codeunit 7000195 "CRT Gen. Jnl. Template Subs"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Template", 'OnAfterValidateType', '', false, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
        if GenJournalTemplate.Type = "Gen. Journal Template Type"::Cartera then begin
            GenJournalTemplate."Source Code" := SourceCodeSetup."Cartera Journal";
            GenJournalTemplate."Page ID" := Page::"Cartera Journal";
        end;
    end;
}
