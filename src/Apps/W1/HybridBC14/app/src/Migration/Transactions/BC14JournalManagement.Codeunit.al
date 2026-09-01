// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 46863 "BC14 Journal Management"
{
    var
        JournalTemplateNameTok: Label 'BC14MIG', Locked = true;
        JournalTemplateDescTok: Label 'Business Central 14 Cloud Migration', Locked = true;

    internal procedure GetTemplateName(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        if GenJournalTemplate.Get(JournalTemplateNameTok) then
            exit(GenJournalTemplate.Name);

        GenJournalTemplate.Name := JournalTemplateNameTok;
        GenJournalTemplate.Description := JournalTemplateDescTok;
        GenJournalTemplate.Type := GenJournalTemplate.Type::General;
        GenJournalTemplate.Recurring := false;
        if GenJournalTemplate.Insert(true) then;
        exit(GenJournalTemplate.Name);
    end;

    internal procedure EnsureBatchExists(BatchName: Code[10]; BatchDescription: Text[100])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TemplateName: Code[10];
    begin
        TemplateName := GetTemplateName();

        if GenJournalBatch.Get(TemplateName, BatchName) then
            exit;

        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := TemplateName;
        GenJournalBatch.Name := BatchName;
        GenJournalBatch.Description := BatchDescription;
        GenJournalBatch.Insert(true);
    end;
}

