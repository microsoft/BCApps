namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Threading;

codeunit 1512 "Workflow Create Payment Line"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
    begin
        if not WorkflowStepArgument.Get(Rec."Record ID to Process") then begin
            WorkflowStepArgumentArchive.SetRange("Original Record ID", Rec."Record ID to Process");
            if not WorkflowStepArgumentArchive.FindFirst() then
                exit;

            WorkflowStepArgument.TransferFields(WorkflowStepArgumentArchive);
        end;
        CreatePmtLine(WorkflowStepArgument);
    end;

    var
        PaymentTxt: Label 'Payment for %1 %2.', Comment = '%1 = Document Type (Eg. Invoice) %2 = Document No. (1201); Payment for Invoice 1201';

    procedure CreatePmtLine(WorkflowStepArgument: Record "Workflow Step Argument")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        RecRef: RecordRef;
        EmptyDateFormula: DateFormula;
        LastLineNo: Integer;
        LastDocNo: Code[20];
    begin
        GenJournalTemplate.Get(WorkflowStepArgument."General Journal Template Name");
        GenJournalBatch.Get(GenJournalTemplate.Name, WorkflowStepArgument."General Journal Batch Name");

        WorkflowStepInstance.SetLoadFields("Record ID");
        WorkflowStepInstance.SetRange(Argument, WorkflowStepArgument.ID);
        if WorkflowStepInstance.FindFirst() then
            RecRef.Get(WorkflowStepInstance."Record ID")
        else begin
            WorkflowStepInstanceArchive.SetLoadFields("Record ID");
            WorkflowStepInstanceArchive.SetRange(Argument, WorkflowStepArgument.ID);
            if not WorkflowStepInstanceArchive.FindFirst() then
                exit;

            RecRef.Get(WorkflowStepInstanceArchive."Record ID")
        end;

        RecRef.SetTable(PurchInvHeader);
        PurchInvHeader.Find();
        VendorLedgerEntry.Get(PurchInvHeader."Vendor Ledger Entry No.");
        Vendor.Get(VendorLedgerEntry."Vendor No.");

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindLast() then begin
            LastLineNo := GenJournalLine."Line No.";
            LastDocNo := GenJournalLine."Document No.";
        end;

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LastLineNo + 10000;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Posting No. Series" := GenJournalBatch."Posting No. Series";

        VendorLedgerEntry.CalcFields(Amount);

        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine.Validate("Account No.", VendorLedgerEntry."Vendor No.");
        GenJournalLine."Bal. Account Type" := GenJournalBatch."Bal. Account Type";
        GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        GenJournalLine.Validate("Currency Code", VendorLedgerEntry."Currency Code");
        GenJournalLine.Description := StrSubstNo(PaymentTxt, VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.");
        GenJournalLine."Source Line No." := VendorLedgerEntry."Entry No.";
        GenJournalLine."Shortcut Dimension 1 Code" := VendorLedgerEntry."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := VendorLedgerEntry."Global Dimension 2 Code";
        GenJournalLine."Dimension Set ID" := VendorLedgerEntry."Dimension Set ID";
        GenJournalLine."Source Code" := GenJournalTemplate."Source Code";
        GenJournalLine."Reason Code" := GenJournalBatch."Reason Code";
        GenJournalLine.Validate(Amount, -VendorLedgerEntry.Amount);
        GenJournalLine."Applies-to Doc. Type" := VendorLedgerEntry."Document Type";
        GenJournalLine."Applies-to Doc. No." := VendorLedgerEntry."Document No.";
        GenJournalLine."Payment Method Code" := VendorLedgerEntry."Payment Method Code";
        GenJournalLine."Creditor No." := VendorLedgerEntry."Creditor No.";
        GenJournalLine."Payment Reference" := VendorLedgerEntry."Payment Reference";
        GenJournalLine."Applies-to Ext. Doc. No." := VendorLedgerEntry."External Document No.";
        Evaluate(EmptyDateFormula, '<0D>');
        GenJournalLine.SetPostingDateAsDueDate(GenJournalLine.GetAppliesToDocDueDate(), EmptyDateFormula);
        GenJournalLine."Document No." := GetDocumentNo(GenJournalLine, LastDocNo);
        GenJournalLine.Insert();
    end;

    procedure GetDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; LastDocNo: Code[20]): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if GenJournalBatch."No. Series" = '' then
            exit(IncStr(LastDocNo));

        exit(NoSeries.PeekNextNo(GenJournalBatch."No. Series", GenJournalLine."Posting Date"));
    end;
}

