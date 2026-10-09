// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Journal;

codeunit 8416 "IC Journal Errors Mgt."
{
    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        JournalErrorsMgt.InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        JournalErrorsMgt.SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        JournalErrorsMgt.SetRecXRecOnModify(xRec, Rec);
    end;
}
