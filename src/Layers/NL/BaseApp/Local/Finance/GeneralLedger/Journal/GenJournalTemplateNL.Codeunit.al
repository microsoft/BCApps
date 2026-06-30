// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Statement;
using Microsoft.Foundation.AuditCodes;

codeunit 11340 "Gen. Journal Template NL"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Template", OnAfterValidateType, '', false, false)]
    local procedure OnAfterValidateType(var GenJournalTemplate: Record "Gen. Journal Template"; SourceCodeSetup: Record "Source Code Setup")
    begin
        if GenJournalTemplate.Recurring then
            exit;

        case GenJournalTemplate.Type of
            GenJournalTemplate.Type::Cash:
                begin
                    GenJournalTemplate."Source Code" := SourceCodeSetup."Cash Journal";
                    GenJournalTemplate."Page ID" := PAGE::"Cash Journal";
                    GenJournalTemplate."Posting Report ID" := REPORT::"CBG Posting - Test";
                    GenJournalTemplate."Test Report ID" := REPORT::"CBG Posting - Test";
                end;
            GenJournalTemplate.Type::Bank:
                begin
                    GenJournalTemplate."Source Code" := SourceCodeSetup."Bank Journal";
                    GenJournalTemplate."Page ID" := PAGE::"Bank/Giro Journal";
                    GenJournalTemplate."Posting Report ID" := REPORT::"CBG Posting - Test";
                    GenJournalTemplate."Test Report ID" := REPORT::"CBG Posting - Test";
                end;
        end;
    end;
}