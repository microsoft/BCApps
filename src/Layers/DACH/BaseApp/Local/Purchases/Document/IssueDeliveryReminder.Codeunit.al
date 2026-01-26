// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

codeunit 5005270 "Issue Delivery Reminder"
{
    Permissions = TableData "Delivery Reminder Line" = imd,
                  TableData "Issued Deliv. Reminder Header" = imd,
                  TableData "Issued Deliv. Reminder Line" = imd,
                  TableData "Delivery Reminder Ledger Entry" = rimd;

    trigger OnRun()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if ReplacePostingDate then
            DeliveryReminderHeader."Posting Date" := PostingDate;
        // Test Header
        CheckDeliveryReminderHeader();

        DeliveryReminderLine.Reset();
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        DeliveryReminderLine.SetFilter(Quantity, '<>0');
        if not DeliveryReminderLine.Find('-') then
            Error(Text1140000);

        Window.Open(
          Text1140001 +
          Text1140002 +
          Text1140003);

        Window.Update(1, DeliveryReminderHeader."No.");

        if (DeliveryReminderHeader."Issuing No." = '') and (DeliveryReminderHeader."No. Series" <> DeliveryReminderHeader."Issuing No. Series") then begin
            DeliveryReminderHeader.TestField("Issuing No. Series");
            DeliveryReminderHeader."Issuing No." := NoSeries.GetNextNo(DeliveryReminderHeader."Issuing No. Series", DeliveryReminderHeader."Posting Date");
            DeliveryReminderHeader.Modify();
            Commit();
        end;

        if DeliveryReminderHeader."Issuing No." <> '' then
            DocumentNo := DeliveryReminderHeader."Issuing No."
        else
            DocumentNo := DeliveryReminderHeader."No.";
        // Checking Lines
        DeliveryReminderLine.Reset();
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        LineCount := 0;
        if DeliveryReminderLine.Find('-') then
            repeat
                if DeliveryReminderLine.Type = DeliveryReminderLine.Type::" " then
                    DeliveryReminderLine.TestField(Quantity, 0);
                if (DeliveryReminderLine.Type <> DeliveryReminderLine.Type::" ")
                   and (DeliveryReminderLine."No." <> '')
                then begin
                    DeliveryReminderLine.TestField("Order No.");
                    DeliveryReminderLine.TestField("Order Line No.");
                end;
                LineCount := LineCount + 1;
                Window.Update(2, LineCount);
            until DeliveryReminderLine.Next() = 0;
        // Issuing
        SourceCodeSetup.Get('');
        SourceCode := SourceCodeSetup."Delivery Reminder";

        IssuedDeliveryReminderHeader.Init();
        IssuedDeliveryReminderHeader.TransferFields(DeliveryReminderHeader);
        IssuedDeliveryReminderHeader."No." := DocumentNo;
        IssuedDeliveryReminderHeader."Pre-Assigned No." := DeliveryReminderHeader."No.";
        IssuedDeliveryReminderHeader."Source Code" := SourceCode;
        IssuedDeliveryReminderHeader."User ID" := UserId;
        IssuedDeliveryReminderHeader."No. Printed" := 0;
        OnBeforeIssuedDeliveryReminderHeaderInsert(IssuedDeliveryReminderHeader, DeliveryReminderHeader);
        IssuedDeliveryReminderHeader.Insert();
        OnAfterIssuedDeliveryReminderHeaderInsert(IssuedDeliveryReminderHeader, DeliveryReminderHeader);

        if NextEntryNo = 0 then begin
            DelivReminLedgerEntries.LockTable();
            NextEntryNo := DelivReminLedgerEntries.GetLastEntryNo() + 1;
        end;

        DeliveryReminderLine.Reset();
        DeliveryReminderLine.SetRange("Document No.", DeliveryReminderHeader."No.");
        if DeliveryReminderLine.Find('-') then
            repeat
                if DeliveryReminderLine.Quantity <> 0 then begin
                    DelivReminLedgerEntries.Init();
                    DelivReminLedgerEntries."Entry No." := NextEntryNo;
                    DelivReminLedgerEntries."Reminder No." := IssuedDeliveryReminderHeader."No.";
                    DelivReminLedgerEntries."Reminder Line No." := DeliveryReminderLine."Line No.";
                    DelivReminLedgerEntries."Vendor No." := DeliveryReminderHeader."Vendor No.";
                    DelivReminLedgerEntries."Posting Date" := DeliveryReminderHeader."Posting Date";
                    DelivReminLedgerEntries."Document Date" := DeliveryReminderHeader."Document Date";
                    DelivReminLedgerEntries."Reminder Level" := DeliveryReminderLine."Reminder Level";
                    DelivReminLedgerEntries."Order No." := DeliveryReminderLine."Order No.";
                    DelivReminLedgerEntries."Order Line No." := DeliveryReminderLine."Order Line No.";
                    DelivReminLedgerEntries.Type := DeliveryReminderLine.Type;
                    DelivReminLedgerEntries."No." := DeliveryReminderLine."No.";
                    DelivReminLedgerEntries."Reorder Quantity" := DeliveryReminderLine."Reorder Quantity";
                    DelivReminLedgerEntries."Remaining Quantity" := DeliveryReminderLine."Remaining Quantity";
                    DelivReminLedgerEntries.Quantity := DeliveryReminderLine.Quantity;
                    DelivReminLedgerEntries."User ID" := UserId;
                    DelivReminLedgerEntries."Source Code" := SourceCode;
                    DelivReminLedgerEntries."Purch. Expected Receipt Date" := DeliveryReminderLine."Expected Receipt Date";
                    DelivReminLedgerEntries."Days overdue" := DeliveryReminderLine."Days overdue";
                    OnBeforeDelivReminLedgerEntriesInsert(DelivReminLedgerEntries, DeliveryReminderLine);
                    DelivReminLedgerEntries.Insert();
                    NextEntryNo := NextEntryNo + 1;
                end;

                IssuedDeliveryReminderLine.Init();
                IssuedDeliveryReminderLine.TransferFields(DeliveryReminderLine);
                IssuedDeliveryReminderLine."Document No." := IssuedDeliveryReminderHeader."No.";
                OnBeforeIssuedDeliveryReminderLineInsert(IssuedDeliveryReminderLine, DeliveryReminderLine);
                IssuedDeliveryReminderLine.Insert();
                OnAfterIssuedDeliveryReminderLineInsert(IssuedDeliveryReminderLine, DeliveryReminderLine);
            until DeliveryReminderLine.Next() = 0;
        DeliveryReminderLine.DeleteAll();

        DeliveryReminderCommentLine.Reset();
        DeliveryReminderCommentLine.SetRange("Document Type", DeliveryReminderCommentLine."Document Type"::"Delivery Reminder");
        DeliveryReminderCommentLine.SetRange("No.", DeliveryReminderHeader."No.");
        if DeliveryReminderCommentLine.Find('-') then
            repeat
                IssDelivReminCommLine2 := DeliveryReminderCommentLine;
                IssDelivReminCommLine2."Document Type" := DeliveryReminderCommentLine."Document Type"::"Issued Delivery Reminder";
                IssDelivReminCommLine2."No." := IssuedDeliveryReminderHeader."No.";
                IssDelivReminCommLine2.Insert();
            until DeliveryReminderCommentLine.Next() = 0;
        DeliveryReminderCommentLine.DeleteAll();

        DeliveryReminderHeader.Delete();
    end;

    var
        Text1140000: Label 'There is nothing to issue.';
        Text1140001: Label 'Delivery Reminder  #1#########\\';
        Text1140002: Label 'Checking lines        #2######\';
        Text1140003: Label 'Posting Lines         #3######\';
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderLine: Record "Delivery Reminder Line";
        IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header";
        IssuedDeliveryReminderLine: Record "Issued Deliv. Reminder Line";
        DelivReminLedgerEntries: Record "Delivery Reminder Ledger Entry";
        DeliveryReminderCommentLine: Record "Delivery Reminder Comment Line";
        IssDelivReminCommLine2: Record "Delivery Reminder Comment Line";
        SourceCodeSetup: Record "Source Code Setup";
        DocumentNo: Code[20];
        SourceCode: Code[20];
        NextEntryNo: Integer;
        Window: Dialog;
        LineCount: Integer;
        ReplacePostingDate: Boolean;
        PostingDate: Date;

    local procedure CheckDeliveryReminderHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDeliveryReminderHeader(DeliveryReminderHeader, IsHandled);
        if IsHandled then
            exit;

        DeliveryReminderHeader.TestField("No.");
        DeliveryReminderHeader.TestField("Vendor No.");
        DeliveryReminderHeader.TestField("Posting Date");
        DeliveryReminderHeader.TestField("Document Date");
    end;

    procedure Set(var NewDelivReminHeader: Record "Delivery Reminder Header"; NewReplacementPostingDate: Boolean; NewPostingDate: Date)
    begin
        DeliveryReminderHeader := NewDelivReminHeader;
        ReplacePostingDate := NewReplacementPostingDate;
        PostingDate := NewPostingDate;
    end;

    procedure GetIssDelivReminHeader(var IssDelivReminHeaderNew: Record "Issued Deliv. Reminder Header")
    begin
        IssDelivReminHeaderNew := IssuedDeliveryReminderHeader;
    end;

    procedure IncrNoPrinted(var IssDelivReminHeader: Record "Issued Deliv. Reminder Header")
    begin
        IssDelivReminHeader.Find();
        IssDelivReminHeader."No. Printed" := IssDelivReminHeader."No. Printed" + 1;
        IssDelivReminHeader.Modify();
        Commit();
    end;

    procedure DeleteIssuedDelivReminderLines(IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header")
    var
        IssuedDelivReminderLine: Record "Issued Deliv. Reminder Line";
    begin
        IssuedDelivReminderLine.SetRange("Document No.", IssuedDelivReminderHeader."No.");
        IssuedDelivReminderLine.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssuedDeliveryReminderHeaderInsert(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header"; DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDeliveryReminderHeader(var DeliveryReminderHeader: Record "Delivery Reminder Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelivReminLedgerEntriesInsert(var DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry"; DeliveryReminderLine: Record "Delivery Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedDeliveryReminderHeaderInsert(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header"; DeliveryReminderHeader: Record "Delivery Reminder Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedDeliveryReminderLineInsert(var IssuedDeliveryReminderLine: Record "Issued Deliv. Reminder Line"; DeliveryReminderLine: Record "Delivery Reminder Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssuedDeliveryReminderLineInsert(var IssuedDeliveryReminderLine: Record "Issued Deliv. Reminder Line"; DeliveryReminderLine: Record "Delivery Reminder Line")
    begin
    end;
}

