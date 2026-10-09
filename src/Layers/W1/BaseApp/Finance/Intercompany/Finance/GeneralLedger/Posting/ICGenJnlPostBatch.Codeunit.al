// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;

codeunit 8415 "IC Gen. Jnl.-Post Batch"
{
    SingleInstance = true;

    var
        ICFeedback: Codeunit "IC Feedback";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxExport: Codeunit "IC Outbox Export";
#if not CLEAN29
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
#endif
        ICLastDocType: Enum "Gen. Journal Document Type";
        ICLastDate: Date;
        ICLastDocNo: Code[20];
        CurrentICPartner: Code[20];
        LastICTransactionNo: Integer;
        ICTransactionNo: Integer;
        ICProcessedLines: Integer;
        CannotEnterErr: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Comment = '%1 = Account No., %2 = Bal. Account No.';
        DoesNotContainErr: Label 'Line No. %1 does not contain a G/L Account or Bank Account. When the %2 field contains an account number, either the %3 field or the %4 field must contain a G/L Account or Bank Account.', Comment = '%1 = Line No., %2 = IC Account No., %3 = Account No., %4 = Bal. Account No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnBeforeProcessLines, '', true, false)]
    local procedure OnBeforeProcessLines(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
        ClearAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnProcessLinesOnAfterCheckLines, '', true, false)]
    local procedure OnProcessLinesOnAfterCheckLines(GenJnlTemplate: Record "Gen. Journal Template"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var LastDate: Date; var LastDocType: Enum "Gen. Journal Document Type"; var LastDocNo: Code[20])
    begin
        if GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany then
            CheckICDocument(TempGenJnlLine, LastDate, LastDocType, LastDocNo);
    end;

    local procedure CheckICDocument(var TempGenJnlLine1: Record "Gen. Journal Line" temporary; var LastDate: Date; var LastDocType: Enum "Gen. Journal Document Type"; var LastDocNo: Code[20])
    var
        TempGenJnlLine2: Record "Gen. Journal Line" temporary;
        ICPartnerCode: Code[20];
    begin
        TempGenJnlLine1.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
        TempGenJnlLine1.SetRange("Journal Template Name", TempGenJnlLine1."Journal Template Name");
        TempGenJnlLine1.SetRange("Journal Batch Name", TempGenJnlLine1."Journal Batch Name");
        TempGenJnlLine1.Find('-');
        repeat
            if (TempGenJnlLine1."Posting Date" <> LastDate) or (TempGenJnlLine1."Document Type" <> LastDocType) or (TempGenJnlLine1."Document No." <> LastDocNo) then begin
                TempGenJnlLine2 := TempGenJnlLine1;
                TempGenJnlLine1.SetRange("Posting Date", TempGenJnlLine1."Posting Date");
                TempGenJnlLine1.SetRange("Document No.", TempGenJnlLine1."Document No.");
                TempGenJnlLine1.SetFilter(TempGenJnlLine1."IC Partner Code", '<>%1', '');
                if TempGenJnlLine1.Find('-') then
                    ICPartnerCode := TempGenJnlLine1."IC Partner Code"
                else
                    ICPartnerCode := '';
                TempGenJnlLine1.SetRange("Posting Date");
                TempGenJnlLine1.SetRange("Document No.");
                TempGenJnlLine1.SetRange("IC Partner Code");
                LastDate := TempGenJnlLine1."Posting Date";
                LastDocType := TempGenJnlLine1."Document Type";
                LastDocNo := TempGenJnlLine1."Document No.";
                TempGenJnlLine1 := TempGenJnlLine2;
            end;
            if (ICPartnerCode <> '') and (TempGenJnlLine1."IC Direction" = TempGenJnlLine1."IC Direction"::Outgoing) then begin
                if (TempGenJnlLine1."Account Type" in [TempGenJnlLine1."Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and
                   (TempGenJnlLine1."Bal. Account Type" in [TempGenJnlLine1."Bal. Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and
                   (TempGenJnlLine1."Account No." <> '') and
                   (TempGenJnlLine1."Bal. Account No." <> '')
                then
                    Error(CannotEnterErr, TempGenJnlLine1.FieldCaption("Account No."), TempGenJnlLine1.FieldCaption("Bal. Account No."));
                if ((TempGenJnlLine1."Account Type" in [TempGenJnlLine1."Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and (TempGenJnlLine1."Account No." <> '')) xor
                   ((TempGenJnlLine1."Bal. Account Type" in [TempGenJnlLine1."Bal. Account Type"::"G/L Account", TempGenJnlLine1."Account Type"::"Bank Account"]) and
                    (TempGenJnlLine1."Bal. Account No." <> ''))
                then
                    TempGenJnlLine1.TestField(TempGenJnlLine1."IC Account No.")
                else
                    if TempGenJnlLine1."IC Account No." <> '' then
                        Error(DoesNotContainErr,
                          TempGenJnlLine1."Line No.", TempGenJnlLine1.FieldCaption("IC Account No."), TempGenJnlLine1.FieldCaption("Account No."),
                          TempGenJnlLine1.FieldCaption("Bal. Account No."));
            end else
                TempGenJnlLine1.TestField(TempGenJnlLine1."IC Account No.", '');
        until TempGenJnlLine1.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnProcessLinesOnProcessICTransaction, '', true, false)]
    local procedure OnProcessLinesOnProcessICTransaction(var GenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary; var GenJnlTemplate: Record "Gen. Journal Template")
    begin
        ProcessICLines(GenJnlTemplate, GenJnlLine, TempGenJnlLine);
        ProcessICTransaction();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnProcessLinesOnAfterPostGenJnlPostLines, '', true, false)]
    local procedure OnProcessLinesOnAfterPostGenJnlPostLines(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if LastICTransactionNo > 0 then
            ICOutboxExport.ProcessAutoSendOutboxTransactionNo(ICTransactionNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnBlankICPartner, '', true, false)]
    local procedure OnBlankICPartner(var Result: Boolean)
    begin
        Result := CurrentICPartner = '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnAfterProcessLinesIC, '', true, false)]
    local procedure OnAfterProcessLinesIC(var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    begin
        if LastICTransactionNo > 0 then
            ICFeedback.ShowIntercompanyMessage(TempGenJnlLine, ICLastDocNo, ICProcessedLines);
    end;

    local procedure ProcessICLines(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlLine: Record "Gen. Journal Line"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessICLines(CurrentICPartner, ICTransactionNo, ICLastDocNo, ICLastDate, ICLastDocType, GenJnlLine, TempGenJnlLine, ICProcessedLines, IsHandled);
#if not CLEAN29
        GenJnlPostBatch.RunOnBeforeProcessICLines(CurrentICPartner, ICTransactionNo, ICLastDocNo, ICLastDate, ICLastDocType, GenJnlLine, TempGenJnlLine, ICProcessedLines, IsHandled);
#endif
        if IsHandled then
            exit;

        if (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and not GenJnlLine.EmptyLine() and
               ((GenJnlLine."Posting Date" <> ICLastDate) or (GenJnlLine."Document Type" <> ICLastDocType) or (GenJnlLine."Document No." <> ICLastDocNo) or
               ((GenJnlLine."IC Partner Code" <> CurrentICPartner) and (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"IC Partner")))
        then begin
            CurrentICPartner := '';
            ICLastDate := GenJnlLine."Posting Date";
            ICLastDocType := GenJnlLine."Document Type";
            ICLastDocNo := GenJnlLine."Document No.";
            TempGenJnlLine.Reset();
            TempGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            TempGenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            TempGenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            TempGenJnlLine.SetRange("Posting Date", GenJnlLine."Posting Date");
            TempGenJnlLine.SetRange("Document No.", GenJnlLine."Document No.");
            if (GenJnlLine."IC Partner Code" = '') then
                TempGenJnlLine.SetFilter("IC Partner Code", '<>%1', '')
            else
                TempGenJnlLine.SetRange("IC Partner Code", GenJnlLine."IC Partner Code");

            if TempGenJnlLine.FindFirst() and (TempGenJnlLine."IC Partner Code" <> '') then begin
                ICProcessedLines := ICProcessedLines + 1;
                CurrentICPartner := TempGenJnlLine."IC Partner Code";
                if TempGenJnlLine."IC Direction" = TempGenJnlLine."IC Direction"::Outgoing then
                    ICTransactionNo := ICInboxOutboxMgt.CreateOutboxJnlTransaction(TempGenJnlLine, false)
                else
                    if HandledICInboxTrans.Get(
                         TempGenJnlLine."IC Partner Transaction No.", TempGenJnlLine."IC Partner Code",
                         HandledICInboxTrans."Transaction Source"::"Created by Partner", TempGenJnlLine."Document Type")
                    then begin
                        HandledICInboxTrans.LockTable();
                        HandledICInboxTrans.Status := HandledICInboxTrans.Status::Posted;
                        OnProcessICLinesOnBeforeHandledICInboxTransModify(HandledICInboxTrans, GenJnlLine);
#if not CLEAN29
                        GenJnlPostBatch.RunOnProcessICLinesOnBeforeHandledICInboxTransModify(HandledICInboxTrans, GenJnlLine);
#endif
                        HandledICInboxTrans.Modify();
                    end
            end
        end;
    end;

    local procedure ProcessICTransaction()
    begin
        if LastICTransactionNo = 0 then
            LastICTransactionNo := ICTransactionNo
        else
            if LastICTransactionNo <> ICTransactionNo then begin
                ICOutboxExport.ProcessAutoSendOutboxTransactionNo(LastICTransactionNo);
                LastICTransactionNo := ICTransactionNo;
            end;
    end;

    internal procedure GetICTransactionNo(): Integer
    begin
        exit(ICTransactionNo);
    end;

    internal procedure GetICPartnerCode(): Code[20]
    begin
        exit(CurrentICPartner);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnPostGenJournalLineOnBeforeCheckDocumentNo, '', true, false)]
    local procedure OnPostGenJournalLineOnBeforeCheckDocumentNo(var GenJnlLine: Record "Gen. Journal Line"; GLRegNo: Integer)
    begin
        if CurrentICPartner <> '' then
            GenJnlLine."IC Partner Code" := CurrentICPartner;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", OnAfterPostGenJnlLineIC, '', true, false)]
    local procedure OnAfterPostGenJnlLineIC(GenJnlTemplate: Record "Gen. Journal Template"; var GenJournalLine: Record "Gen. Journal Line"; var GenJnlLine5: Record "Gen. Journal Line")
    begin
        if (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and (CurrentICPartner <> '') and
           (GenJournalLine."IC Direction" = GenJournalLine."IC Direction"::Outgoing) and (ICTransactionNo > 0)
        then
            ICInboxOutboxMgt.CreateOutboxJnlLine(ICTransactionNo, 1, GenJnlLine5);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessICLines(var CurrentICPartner: Code[20]; var ICTransactionNo: Integer; var ICLastDocNo: Code[20]; var ICLastDate: Date; var ICLastDocType: Enum "Gen. Journal Document Type"; var GenJournalLine: Record "Gen. Journal Line"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; var ICProcessedLines: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessICLinesOnBeforeHandledICInboxTransModify(var HandledICInboxTrans: Record "Handled IC Inbox Trans."; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}