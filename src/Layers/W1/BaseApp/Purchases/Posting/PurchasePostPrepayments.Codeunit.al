// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;
using System.Telemetry;

codeunit 444 "Purchase-Post Prepayments"
{
    Permissions = TableData "Purchase Line" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Vendor Posting Group" = rimd,
                  TableData "Inventory Posting Group" = rimd,
                  TableData "Purch. Inv. Header" = rimd,
                  TableData "Purch. Inv. Line" = rimd,
                  TableData "Purch. Cr. Memo Hdr." = rimd,
                  TableData "Purch. Cr. Memo Line" = rimd;
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        Execute(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        GenPostingSetup: Record "General Posting Setup";
        TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        ErrorMessageMgt: Codeunit "Error Message Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        SuppressCommit: Boolean;
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        PreviewMode: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Posting Prepayment Lines   #2######\';
        Text003: Label '%1 %2 -> Invoice %3';
        Text004: Label 'Posting purchases and VAT  #3######\';
        Text005: Label 'Posting to vendors         #4######\';
        Text006: Label 'Posting to bal. account    #5######';
        Text011: Label '%1 %2 -> Credit Memo %3';
        Text012: Label 'Prepayment %1, %2 %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PostingDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - Posting Date field caption';
        SpecifyInvNoSerieTok: Label 'Specify the code for the number series that will be used to assign numbers to posted purchase prepayment invoices.';
        SpecifyCrNoSerieTok: Label 'Specify the code for the number series that will be used to assign numbers to posted purchase prepayment invoices.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text013: Label 'It is not possible to assign a prepayment amount of %1 to the purchase lines.';
#pragma warning restore AA0470
        Text014: Label 'VAT Amount';
#pragma warning disable AA0470
        Text015: Label '%1% VAT';
        Text016: Label 'The new prepayment amount must be between %1 and %2.';
        Text017: Label 'At least one line must have %1 > 0 to distribute prepayment amount.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PrepaymentPurchaseTok: Label 'Prepayment Purchase', Locked = true;
#pragma warning disable AA0074
        text019: Label 'Invoice,Credit Memo';
#pragma warning restore AA0074

    procedure SetDocumentType(DocumentType: Option ,,Invoice,"Credit Memo")
    begin
        PrepmtDocumentType := DocumentType;
    end;

    local procedure Execute(var PurchHeader: Record "Purchase Header")
    begin
        case PrepmtDocumentType of
            PrepmtDocumentType::Invoice:
                Invoice(PurchHeader);
            PrepmtDocumentType::"Credit Memo":
                CreditMemo(PurchHeader);
        end;
    end;

    procedure Invoice(var PurchHeader: Record "Purchase Header")
    var
        Handled: Boolean;
    begin
        OnBeforeInvoice(PurchHeader, Handled);
        if not Handled then
            Code(PurchHeader, 0);
    end;

    procedure CreditMemo(var PurchHeader: Record "Purchase Header")
    var
        Handled: Boolean;
    begin
        OnBeforeCreditMemo(PurchHeader, Handled);
        if not Handled then
            Code(PurchHeader, 1);
    end;

    local procedure "Code"(var PurchHeader2: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SourceCodeSetup: Record "Source Code Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempPurchaseLine2: Record "Purchase Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        Window: Dialog;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        PostingNoSeriesCode: Code[20];
        ModifyHeader: Boolean;
        CalcPmtDiscOnCrMemos: Boolean;
        PostingDescription: Text[100];
        GenJnlLineDocType: Enum "Gen. Journal Document Type";
        LineCount: Integer;
        PostedDocTabNo: Integer;
        LineNo: Integer;
    begin
        OnBeforePostPrepayments(PurchHeader2, DocumentType, SuppressCommit);

        PurchHeader := PurchHeader2;
        GLSetup.GetRecordOnce();
        PurchSetup.Get();

        FeatureTelemetry.LogUptake('0000KQD', PrepaymentPurchaseTok, Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KQE', PrepaymentPurchaseTok, PrepaymentPurchaseTok);
        CheckPrepmtDoc(PurchHeader, DocumentType);

        UpdateDocNos(PurchHeader, DocumentType, GenJnlLineDocNo, PostingNoSeriesCode, ModifyHeader);

        if not PreviewMode and ModifyHeader then begin
            PurchHeader.Modify();
            if not SuppressCommit then
                Commit();
        end;

        OnCodeOnBeforeWindowOpen(PurchHeader, DocumentType);

        Window.Open(
          '#1#################################\\' +
          Text002 +
          Text004 +
          Text005 +
          Text006);
        Window.Update(1, StrSubstNo('%1 %2', SelectStr(1 + DocumentType, text019), PurchHeader."No."));

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Purchases;
        if PurchHeader."Prepmt. Posting Description" <> '' then
            PostingDescription := PurchHeader."Prepmt. Posting Description"
        else
            PostingDescription :=
              CopyStr(
                StrSubstNo(Text012, SelectStr(1 + DocumentType, text019), PurchHeader."Document Type", PurchHeader."No."),
                1, MaxStrLen(PurchHeader."Posting Description"));
        // Create posted header
        case DocumentType of
            DocumentType::Invoice:
                begin
                    if PurchSetup."Ext. Doc. No. Mandatory" then
                        PurchHeader.TestField("Vendor Invoice No.");
                    InsertPurchInvHeader(PurchInvHeader, PurchHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode);
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    PostedDocTabNo := Database::"Purch. Inv. Header";
                    GenJnlLineExtDocNo := PurchInvHeader."Vendor Invoice No.";
                    Window.Update(1, StrSubstNo(Text003, PurchHeader."Document Type", PurchHeader."No.", PurchInvHeader."No."));
                end;
            DocumentType::"Credit Memo":
                begin
                    if PurchSetup."Ext. Doc. No. Mandatory" then
                        PurchHeader.TestField("Vendor Cr. Memo No.");
                    CalcPmtDiscOnCrMemos := GetCalcPmtDiscOnCrMemos(PurchHeader."Prepmt. Payment Terms Code");
                    InsertPurchCrMemoHeader(
                      PurchCrMemoHeader, PurchHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode,
                      CalcPmtDiscOnCrMemos);
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    PostedDocTabNo := Database::"Purch. Cr. Memo Hdr.";
                    GenJnlLineExtDocNo := PurchCrMemoHeader."Vendor Cr. Memo No.";
                    Window.Update(1, StrSubstNo(Text011, PurchHeader."Document Type", PurchHeader."No.", PurchCrMemoHeader."No."));
                end;
        end;
        // Reverse old lines
        if DocumentType = DocumentType::Invoice then begin
            GetPurchLinesToDeduct(PurchHeader, TempPurchaseLine2);
            if not TempPurchaseLine2.IsEmpty() then
                CalcVATAmountLines(PurchHeader, TempPurchaseLine2, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
        end;
        // Create Lines
        TempPrepmtInvLineBuffer.DeleteAll();
        CalcVATAmountLines(PurchHeader, PurchLine, TempVATAmountLine, DocumentType);
        TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
        UpdateVATOnLines(PurchHeader, PurchLine, TempVATAmountLine, DocumentType);
        BuildInvLineBuffer(PurchHeader, PurchLine, DocumentType, TempPrepmtInvLineBuffer, true);

        CreateLinesFromBuffer(PurchHeader, PurchInvHeader, PurchCrMemoHeader, TempPrepmtInvLineBuffer, Window,
            PostedDocTabNo, GenJnlLineDocNo, DocumentType, LineNo);

        if PurchHeader."Compress Prepayment" then
            case DocumentType of
                DocumentType::Invoice:
                    CopyLineCommentLinesCompressedPrepayment(PurchHeader."No.", Database::"Purch. Inv. Header", PurchInvHeader."No.");
                DocumentType::"Credit Memo":
                    CopyLineCommentLinesCompressedPrepayment(PurchHeader."No.", Database::"Purch. Cr. Memo Hdr.", PurchCrMemoHeader."No.");
            end;

        OnAfterCreateLinesOnBeforeGLPosting(PurchHeader, PurchInvHeader, PurchCrMemoHeader, TempPrepmtInvLineBuffer, DocumentType, LineNo);
        // G/L Posting
        LineCount := 0;
        if not PurchHeader."Compress Prepayment" then
            TempPrepmtInvLineBuffer.CompressBuffer();
        TempPrepmtInvLineBuffer.SetRange(Adjustment, false);
        TempPrepmtInvLineBuffer.FindSet(true);
        repeat
            if DocumentType = DocumentType::"Credit Memo" then
                TempPrepmtInvLineBuffer.ReverseAmounts();
            RoundAmounts(PurchHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY);
            if PurchHeader."Currency Code" = '' then begin
                AdjustInvLineBuffers(PurchHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, DocumentType);
                TotalPrepmtInvLineBufferLCY := TotalPrepmtInvLineBuffer;
            end else
                AdjustInvLineBuffers(PurchHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType);
            TempPrepmtInvLineBuffer.Modify();
        until TempPrepmtInvLineBuffer.Next() = 0;

        TempPrepmtInvLineBuffer.Reset();
        TempPrepmtInvLineBuffer.SetCurrentKey(Adjustment);
        TempPrepmtInvLineBuffer.Find('+');
        repeat
            LineCount := LineCount + 1;
            Window.Update(3, LineCount);

            if TempPrepmtInvLineBuffer."VAT Calculation Type" =
               TempPrepmtInvLineBuffer."VAT Calculation Type"::"Reverse Charge VAT"
            then
                TempPrepmtInvLineBuffer.UpdateVATAmounts();

            PostPrepmtInvLineBuffer(
              PurchHeader, TempPrepmtInvLineBuffer, DocumentType, PostingDescription,
              GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
        until TempPrepmtInvLineBuffer.Next(-1) = 0;
        // Post vendor entry
        Window.Update(4, 1);
        OnCodeOnBeforePostVendorEntry(PurchHeader, TempPrepmtInvLineBuffer);
        PostVendorEntry(
          PurchHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription,
          GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDiscOnCrMemos);

        UpdatePostedPurchaseDocument(DocumentType, GenJnlLineDocNo);

        PurchaseAssertPrepmtAmountNotMoreThanDocAmount(VendLedgEntry, PurchHeader, PurchLine);
        // Balancing account
        if PurchHeader."Bal. Account No." <> '' then begin
            Window.Update(5, 1);
            OnCodeOnBeforePostBalancingEntry(PurchHeader, TempPrepmtInvLineBuffer);
            PostBalancingEntry(
              PurchHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, VendLedgEntry, DocumentType,
              GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
        end;
        // Update lines & header
        UpdatePurchaseDocument(PurchHeader, PurchLine, DocumentType, GenJnlLineDocNo);
        SetStatusPendingPrepayment(PurchHeader);
        PurchHeader.Modify();

        OnCodeOnAfterUpdateHeaderAndLines(PurchHeader, PurchInvHeader, PurchCrMemoHeader, GenJnlPostLine, PreviewMode);

        PurchHeader2 := PurchHeader;

        if PreviewMode then begin
            Window.Close();
            GenJnlPostPreview.ThrowError();
        end;

        OnAfterPostPrepayments(PurchHeader2, DocumentType, SuppressCommit, PurchInvHeader, PurchCrMemoHeader);
    end;

    local procedure PurchaseAssertPrepmtAmountNotMoreThanDocAmount(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseAssertPrepmtAmountNotMoreThanDocAmount(VendLedgEntry, PurchHeader, PurchLine, IsHandled);
        if IsHandled then
            exit;
        VendLedgEntry.FindLast();
        VendLedgEntry.CalcFields(Amount);
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then begin
            PurchLine.CalcSums("Amount Including VAT");
            PrepaymentMgt.AssertPrepmtAmountNotMoreThanDocAmount(
                PurchLine."Amount Including VAT", VendLedgEntry.Amount, PurchHeader."Currency Code", PurchSetup."Invoice Rounding");
        end;
    end;

    local procedure CreateLinesFromBuffer(var PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; var Window: Dialog; var PostedDocTabNo: Integer; GenJnlLineDocNo: Code[20]; DocumentType: Option Invoice,"Credit Memo"; var LineNo: Integer)
    var
        LineCount: Integer;
        PrevLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateLinesFromBuffer(PurchHeader, TempPrepmtInvLineBuffer, LineCount, Window, PurchInvHeader, PurchCrMemoHeader, PostedDocTabNo, IsHandled, DocumentType, LineNo);
        if IsHandled then
            exit;

        PrevLineNo := 0;
        TempPrepmtInvLineBuffer.Find('-');
        repeat
            LineCount := LineCount + 1;
            Window.Update(2, LineCount);
            LineNo := PrevLineNo + 10000;
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        InsertPurchInvLine(PurchInvHeader, LineNo, TempPrepmtInvLineBuffer, PurchHeader);
                        PostedDocTabNo := Database::"Purch. Inv. Line";
                    end;
                DocumentType::"Credit Memo":
                    begin
                        InsertPurchCrMemoLine(PurchCrMemoHeader, LineNo, TempPrepmtInvLineBuffer, PurchHeader);
                        PostedDocTabNo := Database::"Purch. Cr. Memo Line";
                    end;
            end;
            PrevLineNo := LineNo;
            InsertExtendedText(
              PostedDocTabNo, GenJnlLineDocNo, TempPrepmtInvLineBuffer."G/L Account No.", PurchHeader."Document Date", PurchHeader."Language Code", PrevLineNo);
        until TempPrepmtInvLineBuffer.Next() = 0;
    end;

    local procedure SetStatusPendingPrepayment(var PurchHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetStatusPendingPrepayment(PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader.TestStatusIsNotPendingPrepayment() then
            PurchHeader.Status := PurchHeader.Status::"Pending Prepayment";
    end;

    procedure CheckPrepmtDoc(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        Vend: Record Vendor;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
        ErrorContextElement: Codeunit "Error Context Element";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        SetupRecID: RecordId;
    begin
        OnBeforeCheckPrepmtDoc(PurchHeader, DocumentType);
        PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.TestField("Buy-from Vendor No.");
        PurchHeader.TestField("Pay-to Vendor No.");
        PurchHeader.TestField("Posting Date");
        PurchHeader.TestField("Document Date");
        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then
            PurchHeader.TestField("Journal Templ. Name");

        ErrorMessageMgt.PushContext(ErrorContextElement, PurchHeader.RecordId, 0, '');
        if GenJnlCheckLine.DateNotAllowed(PurchHeader."Posting Date", PurchHeader."Journal Templ. Name") then
            ErrorMessageMgt.LogContextFieldError(
              PurchHeader.FieldNo("Posting Date"), StrSubstNo(PostingDateNotAllowedErr, PurchHeader.FieldCaption("Posting Date")),
              SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, ''),
              ForwardLinkMgt.GetHelpCodeForAllowedPostingDate());

        if not CheckOpenPrepaymentLines(PurchHeader, DocumentType) then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        CheckDimensions.CheckPurchPrepmtDim(PurchHeader);

        PurchHeader.CheckPurchasePostRestrictions();
        Vend.Get(PurchHeader."Buy-from Vendor No.");
        Vend.CheckBlockedVendOnDocs(Vend, true);
        if PurchHeader."Pay-to Vendor No." <> PurchHeader."Buy-from Vendor No." then begin
            Vend.Get(PurchHeader."Pay-to Vendor No.");
            Vend.CheckBlockedVendOnDocs(Vend, true);
        end;
        OnAfterCheckPrepmtDoc(PurchHeader, DocumentType, ErrorMessageMgt);
        ErrorMessageMgt.Finish(PurchHeader.RecordId);
    end;

    local procedure UpdateDocNos(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocNos(PurchHeader, DocumentType, DocNo, NoSeriesCode, ModifyHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        case DocumentType of
            DocumentType::Invoice:
                begin
                    PurchHeader.TestField("Prepayment Due Date");
                    PurchHeader.TestField("Prepmt. Cr. Memo No.", '');
                    if PurchHeader."Prepayment No." = '' then
                        if not PreviewMode then
                            UpdateInvoiceDocNos(PurchHeader, ModifyHeader)
                        else
                            PurchHeader."Prepayment No." := '***';
                    DocNo := PurchHeader."Prepayment No.";
                    NoSeriesCode := PurchHeader."Prepayment No. Series";
                end;
            DocumentType::"Credit Memo":
                begin
                    PurchHeader.TestField("Prepayment No.", '');
                    if PurchHeader."Prepmt. Cr. Memo No." = '' then
                        if not PreviewMode then
                            UpdateCrMemoDocNos(PurchHeader, ModifyHeader)
                        else
                            PurchHeader."Prepmt. Cr. Memo No." := '***';
                    DocNo := PurchHeader."Prepmt. Cr. Memo No.";
                    NoSeriesCode := PurchHeader."Prepmt. Cr. Memo No. Series";
                end;
        end;

        if GLSetup."Journal Templ. Name Mandatory" then
            GenJournalTemplate.Get(PurchHeader."Journal Templ. Name");
    end;

    local procedure UpdateInvoiceDocNos(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ErrorContextElement: Codeunit "Error Context Element";
        NoSeries: Codeunit "No. Series";
    begin
        if GLSetup."Journal Templ. Name Mandatory" then begin
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.TestField("P. Prep. Inv. Template Name");
            GenJournalTemplate.Get(PurchasesPayablesSetup."P. Prep. Inv. Template Name");
            GenJournalTemplate.TestField("Posting No. Series");
            PurchHeader."Prepayment No." := NoSeries.GetNextNo(GenJournalTemplate."Posting No. Series", PurchHeader."Posting Date");
            ModifyHeader := true;
        end else begin
            if PurchHeader."Prepayment No. Series" = '' then begin
                PurchasesPayablesSetup.Get();
                ErrorMessageMgt.PushContext(ErrorContextElement, PurchasesPayablesSetup.RecordId, 0, '');
                if PurchasesPayablesSetup."Posted Prepmt. Inv. Nos." = '' then
                    ErrorMessageMgt.LogContextFieldError(
                        PurchasesPayablesSetup.FieldNo("Posted Prepmt. Inv. Nos."), SpecifyInvNoSerieTok,
                        PurchasesPayablesSetup.RecordId, PurchasesPayablesSetup.FieldNo("Posted Prepmt. Inv. Nos."), '');
                ErrorMessageMgt.Finish(PurchasesPayablesSetup.RecordId);
                PurchHeader."Prepayment No. Series" := PurchasesPayablesSetup."Posted Prepmt. Inv. Nos.";
                ModifyHeader := true;
            end;
            PurchHeader.TestField("Prepayment No. Series");
            PurchHeader."Prepayment No." := NoSeries.GetNextNo(PurchHeader."Prepayment No. Series", PurchHeader."Posting Date");
            ModifyHeader := true;
        end
    end;

    local procedure UpdateCrMemoDocNos(var PurchHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ErrorContextElement: Codeunit "Error Context Element";
        NoSeries: Codeunit "No. Series";
    begin
        OnBeforeUpdateCrMemoDocNos(PurchHeader);
        if GLSetup."Journal Templ. Name Mandatory" then begin
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.TestField("P. Prep. Cr.Memo Template Name");
            GenJournalTemplate.Get(PurchasesPayablesSetup."P. Prep. Cr.Memo Template Name");
            GenJournalTemplate.TestField("Posting No. Series");
            PurchHeader."Prepmt. Cr. Memo No." :=
                NoSeries.GetNextNo(GenJournalTemplate."Posting No. Series", PurchHeader."Posting Date");
            ModifyHeader := true;
        end else begin
            if PurchHeader."Prepmt. Cr. Memo No. Series" = '' then begin
                PurchasesPayablesSetup.Get();
                ErrorMessageMgt.PushContext(ErrorContextElement, PurchasesPayablesSetup.RecordId, 0, '');
                if PurchasesPayablesSetup."Posted Prepmt. Cr. Memo Nos." = '' then
                    ErrorMessageMgt.LogContextFieldError(
                        PurchasesPayablesSetup.FieldNo("Posted Prepmt. Cr. Memo Nos."), SpecifyCrNoSerieTok,
                        PurchasesPayablesSetup.RecordId, PurchasesPayablesSetup.FieldNo("Posted Prepmt. Cr. Memo Nos."), '');
                ErrorMessageMgt.Finish(PurchasesPayablesSetup.RecordId);
                PurchHeader."Prepmt. Cr. Memo No. Series" := PurchasesPayablesSetup."Posted Prepmt. Cr. Memo Nos.";
                ModifyHeader := true;
            end;
            PurchHeader.TestField("Prepmt. Cr. Memo No. Series");
            PurchHeader."Prepmt. Cr. Memo No." :=
                NoSeries.GetNextNo(PurchHeader."Prepmt. Cr. Memo No. Series", PurchHeader."Posting Date");
            ModifyHeader := true;
        end;
        OnAfterUpdateCrMemoDocNos(PurchHeader);
    end;

    procedure CheckOpenPrepaymentLines(PurchHeader: Record "Purchase Header"; DocumentType: Option) Found: Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        OnBeforeCheckOpenPrepaymentLines(PurchHeader, DocumentType);

        ApplyFilter(PurchHeader, DocumentType, PurchLine);
        if PurchLine.Find('-') then
            repeat
                if not Found then
                    Found := PrepmtAmount(PurchLine, DocumentType) <> 0;
                if PurchLine."Prepmt. Amt. Inv." = 0 then begin
                    PurchLine.UpdatePrepmtSetupFields();
                    PurchLine.Modify();
                end;
            until PurchLine.Next() = 0;

        OnAfterCheckOpenPrepaymentLines(PurchHeader, DocumentType, Found);
        exit(Found);
    end;

    local procedure RoundAmounts(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    var
        VAT: Boolean;
    begin
        TotalPrepmtInvLineBuf.IncrAmounts(PrepmtInvLineBuf);

        if PurchHeader."Currency Code" <> '' then begin
            VAT := PrepmtInvLineBuf.Amount <> PrepmtInvLineBuf."Amount Incl. VAT";
            PrepmtInvLineBuf."Amount Incl. VAT" :=
              AmountToLCY(PurchHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", TotalPrepmtInvLineBufLCY."Amount Incl. VAT");
            if VAT then
                PrepmtInvLineBuf.Amount := AmountToLCY(PurchHeader, TotalPrepmtInvLineBuf.Amount, TotalPrepmtInvLineBufLCY.Amount)
            else
                PrepmtInvLineBuf.Amount := PrepmtInvLineBuf."Amount Incl. VAT";
            PrepmtInvLineBuf."VAT Amount" := PrepmtInvLineBuf."Amount Incl. VAT" - PrepmtInvLineBuf.Amount;
            if PrepmtInvLineBuf."VAT Base Amount" <> 0 then
                PrepmtInvLineBuf."VAT Base Amount" := PrepmtInvLineBuf.Amount;
            PrepmtInvLineBuf."Orig. Pmt. Disc. Possible" :=
                AmountToLCY(
                    PurchHeader, TotalPrepmtInvLineBuf."Orig. Pmt. Disc. Possible", TotalPrepmtInvLineBufLCY."Orig. Pmt. Disc. Possible");
        end;

        OnRoundAmountsOnBeforeIncrAmoutns(PurchHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
        TotalPrepmtInvLineBufLCY.IncrAmounts(PrepmtInvLineBuf);

        OnAfterRoundAmounts(PurchHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
    end;

    local procedure AmountToLCY(PurchHeader: Record "Purchase Header"; TotalAmt: Decimal; PrevTotalAmt: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Init();
        exit(
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(PurchHeader."Posting Date", PurchHeader."Currency Code", TotalAmt, PurchHeader."Currency Factor")) -
              PrevTotalAmt);
    end;

    local procedure AdjustInvLineBuffers(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo")
    var
        VATAdjustment: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        CalcPrepmtAmtInvLCYInLines(PurchHeader, PrepmtInvLineBuf, DocumentType, VATAdjustment);
        if Abs(VATAdjustment[VAT::Base]) > GLSetup."Amount Rounding Precision" then
            InsertCorrInvLineBuffer(PrepmtInvLineBuf, PurchHeader, VATAdjustment[VAT::Base])
        else
            if (VATAdjustment[VAT::Base] <> 0) or (VATAdjustment[VAT::Amount] <> 0) then begin
                PrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
                TotalPrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
            end;
    end;

    local procedure CalcPrepmtAmtInvLCYInLines(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; var VATAdjustment: array[2] of Decimal)
    var
        PurchLine: Record "Purchase Line";
        PrepmtInvBufAmount: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        LineAmount: array[2] of Decimal;
        Ratio: array[2] of Decimal;
        PrepmtAmtReminder: array[2] of Decimal;
        PrepmtAmountRnded: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        PrepmtInvLineBuf.AmountsToArray(PrepmtInvBufAmount);
        if DocumentType = DocumentType::"Credit Memo" then
            ReverseDecArray(PrepmtInvBufAmount);

        TempGlobalPrepmtInvLineBuf.SetFilterOnPKey(PrepmtInvLineBuf);
        TempGlobalPrepmtInvLineBuf.CalcSums(Amount, "Amount Incl. VAT");
        TempGlobalPrepmtInvLineBuf.AmountsToArray(TotalAmount);
        for VAT := VAT::Base to VAT::Amount do
            if TotalAmount[VAT] = 0 then
                Ratio[VAT] := 0
            else
                Ratio[VAT] := PrepmtInvBufAmount[VAT] / TotalAmount[VAT];
        if TempGlobalPrepmtInvLineBuf.FindSet() then
            repeat
                TempGlobalPrepmtInvLineBuf.AmountsToArray(LineAmount);
                PrepmtAmountRnded[VAT::Base] :=
                  CalcRoundedAmount(LineAmount[VAT::Base], Ratio[VAT::Base], PrepmtAmtReminder[VAT::Base]);
                PrepmtAmountRnded[VAT::Amount] :=
                  CalcRoundedAmount(LineAmount[VAT::Amount], Ratio[VAT::Amount], PrepmtAmtReminder[VAT::Amount]);

                PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", TempGlobalPrepmtInvLineBuf."Line No.");
                if DocumentType = DocumentType::"Credit Memo" then begin
                    VATAdjustment[VAT::Base] += PurchLine."Prepmt. Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Base];
                    PurchLine."Prepmt. Amount Inv. (LCY)" := 0;
                    VATAdjustment[VAT::Amount] += PurchLine."Prepmt. VAT Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Amount];
                    PurchLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
                end else begin
                    PurchLine."Prepmt. Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Base];
                    PurchLine."Prepmt. VAT Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Amount];
                end;
                PurchLine.Modify();
            until TempGlobalPrepmtInvLineBuf.Next() = 0;
        TempGlobalPrepmtInvLineBuf.DeleteAll();
        ReverseDecArray(VATAdjustment);
    end;

    local procedure CalcRoundedAmount(LineAmount: Decimal; Ratio: Decimal; var Reminder: Decimal) RoundedAmount: Decimal
    var
        Amount: Decimal;
    begin
        Amount := Reminder + LineAmount * Ratio;
        RoundedAmount := Round(Amount);
        Reminder := Amount - RoundedAmount;
    end;

    local procedure ReverseDecArray(var DecArray: array[2] of Decimal)
    var
        Idx: Integer;
    begin
        for Idx := 1 to ArrayLen(DecArray) do
            DecArray[Idx] := -DecArray[Idx];
    end;

    local procedure InsertCorrInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PurchHeader: Record "Purchase Header"; VATBaseAdjustment: Decimal)
    var
        NewPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        SavedPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        AdjmtAmountACY: Decimal;
    begin
        SavedPrepmtInvLineBuf := PrepmtInvLineBuf;

        if PurchHeader."Currency Code" = '' then
            AdjmtAmountACY := VATBaseAdjustment
        else
            AdjmtAmountACY := 0;

        NewPrepmtInvLineBuf.FillAdjInvLineBuffer(
          PrepmtInvLineBuf,
          GetPrepmtAccNo(PrepmtInvLineBuf."Gen. Bus. Posting Group", PrepmtInvLineBuf."Gen. Prod. Posting Group"),
          VATBaseAdjustment, AdjmtAmountACY);
        PrepmtInvLineBuf.InsertInvLineBuffer(NewPrepmtInvLineBuf);

        NewPrepmtInvLineBuf.FillAdjInvLineBuffer(
          PrepmtInvLineBuf,
          GetCorrBalAccNo(PurchHeader, VATBaseAdjustment > 0),
          -VATBaseAdjustment, -AdjmtAmountACY);
        PrepmtInvLineBuf.InsertInvLineBuffer(NewPrepmtInvLineBuf);

        PrepmtInvLineBuf := SavedPrepmtInvLineBuf;
    end;

    local procedure GetPrepmtAccNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) PrepmtAccNo: Code[20]
    begin
        if (GenBusPostingGroup <> GenPostingSetup."Gen. Bus. Posting Group") or
           (GenProdPostingGroup <> GenPostingSetup."Gen. Prod. Posting Group")
        then
            GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        PrepmtAccNo := GenPostingSetup.GetPurchPrepmtAccount();
        OnAfterGetPrepmtAccNo(GenPostingSetup, PrepmtAccNo);
        exit(PrepmtAccNo);
    end;

    procedure GetCorrBalAccNo(PurchHeader: Record "Purchase Header"; PositiveAmount: Boolean): Code[20]
    var
        BalAccNo: Code[20];
    begin
        if PurchHeader."Currency Code" = '' then
            BalAccNo := GetInvRoundingAccNo(PurchHeader."Vendor Posting Group")
        else
            BalAccNo := GetGainLossGLAcc(PurchHeader."Currency Code", PositiveAmount);
        exit(BalAccNo);
    end;

    procedure GetInvRoundingAccNo(VendorPostingGroup: Code[20]): Code[20]
    var
        VendPostingGr: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
    begin
        VendPostingGr.Get(VendorPostingGroup);
        GLAcc.Get(VendPostingGr.GetInvRoundingAccount());
        exit(VendPostingGr."Invoice Rounding Account");
    end;

    local procedure GetGainLossGLAcc(CurrencyCode: Code[10]; PositiveAmount: Boolean): Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        if PositiveAmount then
            exit(Currency.GetRealizedGainsAccount());
        exit(Currency.GetRealizedLossesAccount());
    end;

    local procedure GetCurrencyAmountRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Initialize(CurrencyCode);
        Currency.TestField("Amount Rounding Precision");
        exit(Currency."Amount Rounding Precision");
    end;

    procedure UpdateVATOnLines(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        PrepmtAmt: Decimal;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        NewPmtDiscAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        PrepmtAmtToInvTotal: Decimal;
        RemainderExists: Boolean;
    begin
        Currency.Initialize(PurchHeader."Currency Code");

        ApplyFilter(PurchHeader, DocumentType, PurchLine);
        PurchLine.LockTable();
        PurchLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Inv.");
        PrepmtAmtToInvTotal := PurchLine."Prepmt. Line Amount" - PurchLine."Prepmt. Amt. Inv.";
        if PurchLine.Find('-') then
            repeat
                PrepmtAmt := PrepmtAmount(PurchLine, DocumentType);
                if PrepmtAmt <> 0 then begin
                    FindVATAmountLine(PurchLine, VATAmountLine, PrepmtAmt);
                    OnUpdateVATOnLinesOnAfterVATAmountLineGet(VATAmountLine);
                    if VATAmountLine.Modified then begin
                        RemainderExists :=
                          FindVATAmountLine(PurchLine, TempVATAmountLineRemainder, PrepmtAmt);
                        OnUpdateVATOnLinesOnAfterGetRemainder(TempVATAmountLineRemainder, RemainderExists);
                        if not RemainderExists then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        if PurchHeader."Prices Including VAT" then begin
                            if PrepmtAmt = 0 then begin
                                VATAmount := 0;
                                NewAmountIncludingVAT := 0;
                            end else begin
                                VATAmount :=
                                  TempVATAmountLineRemainder."VAT Amount" +
                                  VATAmountLine."VAT Amount" * PrepmtAmt / VATAmountLine."Line Amount";
                                NewAmountIncludingVAT :=
                                  TempVATAmountLineRemainder."Amount Including VAT" +
                                  VATAmountLine."Amount Including VAT" * PrepmtAmt / VATAmountLine."Line Amount";
                            end;
                            NewAmount :=
                              Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                              Round(VATAmount, Currency."Amount Rounding Precision");
                            NewVATBaseAmount :=
                              Round(
                                NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                Currency."Amount Rounding Precision");
                        end else begin
                            if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Full VAT" then begin
                                VATAmount := PrepmtAmt;
                                NewAmount := 0;
                                NewVATBaseAmount := 0;
                            end else begin
                                NewAmount := PrepmtAmt;
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - PurchHeader."VAT Base Discount %" / 100),
                                    Currency."Amount Rounding Precision");
                                if VATAmountLine."VAT Base" = 0 then
                                    VATAmount := 0
                                else
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                            end;
                            NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                        end;

                        PurchLine."Prepayment Amount" := NewAmount;
                        PurchLine."Prepmt. Amt. Incl. VAT" :=
                          Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        PurchLine."Prepmt. VAT Base Amt." := NewVATBaseAmount;

                        if (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount") = 0 then
                            VATDifference := 0
                        else begin
                            if PrepmtAmtToInvTotal = 0 then
                                VATDifference :=
                                  VATAmountLine."VAT Difference" * (PurchLine."Prepmt. Line Amount" - PurchLine."Prepmt. Amt. Inv.") /
                                  (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount")
                            else
                                VATDifference :=
                                  VATAmountLine."VAT Difference" * (PurchLine."Prepmt. Line Amount" - PurchLine."Prepmt. Amt. Inv.") /
                                  PrepmtAmtToInvTotal;
                            NewPmtDiscAmount :=
                              TempVATAmountLineRemainder."Pmt. Discount Amount" +
                              NewAmount * PurchHeader."Payment Discount %" / 100;
                        end;
                        PurchLine."Prepayment VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                        PurchLine."Prepmt. Pmt. Discount Amount" := Round(NewPmtDiscAmount, Currency."Amount Rounding Precision");

                        OnUpdateVATOnLinesOnBeforePurchLineModify(PurchHeader, PurchLine, TempVATAmountLineRemainder, NewAmount, NewAmountIncludingVAT, NewVATBaseAmount);
                        PurchLine.Modify();

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - PurchLine."Prepayment VAT Difference";
                        TempVATAmountLineRemainder."Pmt. Discount Amount" := NewPmtDiscAmount - Round(NewPmtDiscAmount);
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until PurchLine.Next() = 0;
        VATAmountLine.Reset();

        OnAfterUpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, DocumentType);
    end;

    procedure CalcVATAmountLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        Currency: Record Currency;
        NewAmount: Decimal;
        NewPrepmtVATDiffAmt: Decimal;
    begin
        Currency.Initialize(PurchHeader."Currency Code");

        VATAmountLine.DeleteAll();

        ApplyFilter(PurchHeader, DocumentType, PurchLine);
        if PurchLine.Find('-') then
            repeat
                NewAmount := PrepmtAmount(PurchLine, DocumentType);
                if NewAmount <> 0 then begin
                    if DocumentType = DocumentType::Invoice then
                        NewAmount := PurchLine."Prepmt. Line Amount";
                    if PurchLine."Prepmt. VAT Calc. Type" in
                       [PurchLine."VAT Calculation Type"::"Reverse Charge VAT", PurchLine."VAT Calculation Type"::"Sales Tax"]
                    then
                        PurchLine."VAT %" := 0;

                    if not FindVATAmountLine(PurchLine, VATAmountLine, NewAmount) then
                        InsertVATAmountLine(PurchLine, VATAmountLine, NewAmount);

                    VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + NewAmount;
                    NewPrepmtVATDiffAmt := PrepmtVATDiffAmount(PurchLine, DocumentType);
                    if DocumentType = DocumentType::Invoice then
                        NewPrepmtVATDiffAmt := PurchLine."Prepayment VAT Difference" + PurchLine."Prepmt VAT Diff. to Deduct" +
                          PurchLine."Prepmt VAT Diff. Deducted";
                    VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + NewPrepmtVATDiffAmt;
                    VATAmountLine.Modify();
                end;
            until PurchLine.Next() = 0;
        VATAmountLine.Reset();

        VATAmountLine.UpdateLines(
          NewAmount, Currency, PurchHeader."Currency Factor", PurchHeader."Prices Including VAT",
          PurchHeader."VAT Base Discount %", PurchHeader."Tax Area Code", PurchHeader."Tax Liable", PurchHeader."Posting Date");

        OnAfterCalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, DocumentType);
    end;

    local procedure FindVATAmountLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line" temporary; LineAmount: Decimal): Boolean
    begin
        VATAmountLine.Reset();
        VATAmountLine.SetRange("VAT Identifier", PurchaseLine."Prepayment VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", PurchaseLine."Prepmt. VAT Calc. Type");
        VATAmountLine.SetRange("Tax Group Code", PurchaseLine."Prepayment Tax Group Code");
        VATAmountLine.SetRange("Use Tax", false);
        VATAmountLine.SetRange(Positive, LineAmount >= 0);
        OnFindVATAmountLineOnAfterSetFilters(PurchaseLine, VATAmountLine);
        exit(VATAmountLine.FindFirst());
    end;

    local procedure InsertVATAmountLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; LineAmount: Decimal)
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT Identifier" := PurchaseLine."Prepayment VAT Identifier";
        VATAmountLine."VAT Calculation Type" := PurchaseLine."Prepmt. VAT Calc. Type";
        VATAmountLine."Tax Group Code" := PurchaseLine."Prepayment Tax Group Code";
        VATAmountLine."VAT %" := PurchaseLine."Prepayment VAT %";
        VATAmountLine.Positive := LineAmount >= 0;
        VATAmountLine.Modified := true;
        VATAmountLine."Includes Prepayment" := true;
        OnInsertVATAmountOnBeforeInsert(PurchaseLine, VATAmountLine);
        VATAmountLine.Insert();
    end;

    procedure SumPrepmt(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var VATAmountText: Text[30])
    var
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer";
        DifVATPct: Boolean;
        PrevVATPct: Decimal;
    begin
        CalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, 2);
        UpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, 2);
        BuildInvLineBuffer(PurchHeader, PurchLine, 2, TempPrepmtInvLineBuf, false);
        if TempPrepmtInvLineBuf.Find('-') then begin
            PrevVATPct := TempPrepmtInvLineBuf.GetVATPct();
            repeat
                RoundAmounts(PurchHeader, TempPrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
                if TempPrepmtInvLineBuf.GetVATPct() <> PrevVATPct then
                    DifVATPct := true;
            until TempPrepmtInvLineBuf.Next() = 0;
        end;
        TotalAmount := TotalPrepmtInvLineBuf.Amount;
        TotalVATAmount := TotalPrepmtInvLineBuf."VAT Amount";
        if DifVATPct or (TempPrepmtInvLineBuf."VAT %" = 0) then
            VATAmountText := Text014
        else
            VATAmountText := StrSubstNo(Text015, PrevVATPct);
    end;

    procedure GetPurchLines(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToPurchLine: Record "Purchase Line")
    var
        FromPurchLine: Record "Purchase Line";
        InvRoundingPurchLine: Record "Purchase Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalAmt: Decimal;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLines(PurchHeader, DocumentType, ToPurchLine, IsHandled);
        if IsHandled then
            exit;

        ApplyFilter(PurchHeader, DocumentType, FromPurchLine);
        if FromPurchLine.Find('-') then begin
            repeat
                ToPurchLine := FromPurchLine;
                ToPurchLine.Insert();
            until FromPurchLine.Next() = 0;

            PurchSetup.Get();
            if PurchSetup."Invoice Rounding" then begin
                CalcVATAmountLines(PurchHeader, ToPurchLine, TempVATAmountLine, 2);
                UpdateVATOnLines(PurchHeader, ToPurchLine, TempVATAmountLine, 2);
                ToPurchLine.CalcSums("Prepmt. Amt. Incl. VAT");
                TotalAmt := ToPurchLine."Prepmt. Amt. Incl. VAT";
                ToPurchLine.FindLast();
                if InitInvoiceRoundingLine(PurchHeader, TotalAmt, InvRoundingPurchLine) then begin
                    NextLineNo := ToPurchLine."Line No." + 1;
                    ToPurchLine := InvRoundingPurchLine;
                    ToPurchLine."Line No." := NextLineNo;

                    if DocumentType <> DocumentType::"Credit Memo" then
                        ToPurchLine."Prepmt. Line Amount" := ToPurchLine."Line Amount"
                    else
                        ToPurchLine."Prepmt. Amt. Inv." := ToPurchLine."Line Amount";
                    ToPurchLine."Prepmt. VAT Calc. Type" := ToPurchLine."VAT Calculation Type";
                    ToPurchLine."Prepayment VAT Identifier" := ToPurchLine."VAT Identifier";
                    ToPurchLine."Prepayment Tax Group Code" := ToPurchLine."Tax Group Code";
                    ToPurchLine."Prepayment VAT Identifier" := ToPurchLine."VAT Identifier";
                    ToPurchLine."Prepayment Tax Group Code" := ToPurchLine."Tax Group Code";
                    ToPurchLine."Prepayment VAT %" := ToPurchLine."VAT %";
                    ToPurchLine.Insert();
                end;
            end;
        end;
    end;

    local procedure BuildInvLineBuffer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; UpdateLines: Boolean)
    var
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferDummy: Record "Prepayment Inv. Line Buffer";
    begin
        TempGlobalPrepmtInvLineBuf.Reset();
        TempGlobalPrepmtInvLineBuf.DeleteAll();
        TempPurchaseLine.Reset();
        TempPurchaseLine.DeleteAll();
        PurchSetup.Get();
        ApplyFilter(PurchHeader, DocumentType, PurchLine);
        if PurchLine.Find('-') then
            repeat
                if PrepmtAmount(PurchLine, DocumentType) <> 0 then begin
                    FillInvLineBuffer(PurchHeader, PurchLine, PrepmtInvLineBuf2);
                    if UpdateLines then
                        TempGlobalPrepmtInvLineBuf.CopyWithLineNo(PrepmtInvLineBuf2, PurchLine."Line No.");
                    PrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
                    if PurchSetup."Invoice Rounding" then
                        RoundAmounts(
                          PurchHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferDummy);
                    TempPurchaseLine := PurchLine;
                    TempPurchaseLine.Insert();
                end
                else
                    OnBuildInvLineBufferOnPrepmtAmountZero(PurchHeader, PurchLine, PrepmtInvLineBuf2, PrepmtInvLineBuf, TempPurchaseLine);
            until PurchLine.Next() = 0;
        if PurchSetup."Invoice Rounding" then
            if InsertInvoiceRounding(
                 PurchHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, PurchLine."Line No.")
            then
                PrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
        ErrorMessageMgt.FinishTopContext();
    end;

    procedure BuildInvLineBuffer(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        BuildInvLineBuffer(PurchHeader, PurchLine, DocumentType, PrepmtInvLineBuf, false);
    end;

    procedure FillInvLineBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        PrepmtInvLineBuf.Init();
        OnFillInvLineBufferOnAfterInit(PrepmtInvLineBuf, PurchHeader, PurchLine);

        PrepmtInvLineBuf."G/L Account No." := GetPrepmtAccNo(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");

        if not PurchHeader."Compress Prepayment" then begin
            PrepmtInvLineBuf."Line No." := PurchLine."Line No.";
            PrepmtInvLineBuf.Description := PurchLine.Description;
        end;

        PrepmtInvLineBuf.CopyFromPurchLine(PurchLine);
        PrepmtInvLineBuf.FillFromGLAcc(PurchHeader."Compress Prepayment");

        PrepmtInvLineBuf.SetAmounts(
          PurchLine."Prepayment Amount", PurchLine."Prepmt. Amt. Incl. VAT", PurchLine."Prepayment Amount",
          PurchLine."Prepayment Amount", PurchLine."Prepayment Amount", PurchLine."Prepayment VAT Difference");

        PrepmtInvLineBuf."VAT Amount" := PurchLine."Prepmt. Amt. Incl. VAT" - PurchLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Amount (ACY)" := PurchLine."Prepmt. Amt. Incl. VAT" - PurchLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Base Before Pmt. Disc." := PurchLine."Prepayment Amount";
        PrepmtInvLineBuf."Orig. Pmt. Disc. Possible" := PurchLine."Prepmt. Pmt. Discount Amount";
        PrepmtInvLineBuf."Location Code" := PurchLine."Location Code";

        OnAfterFillInvLineBuffer(PrepmtInvLineBuf, PurchLine, SuppressCommit, PurchHeader);
    end;

    local procedure InsertInvoiceRounding(PurchHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrevLineNo: Integer): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        if InitInvoiceRoundingLine(PurchHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", PurchLine) then begin
            CreateDimensions(PurchLine);
            PrepmtInvLineBuf.Init();
            PrepmtInvLineBuf."Line No." := PrevLineNo + 10000;
            PrepmtInvLineBuf."Invoice Rounding" := true;
            PrepmtInvLineBuf."G/L Account No." := PurchLine."No.";
            PrepmtInvLineBuf.Description := PurchLine.Description;

            PrepmtInvLineBuf.CopyFromPurchLine(PurchLine);

            PrepmtInvLineBuf.SetAmounts(
              PurchLine."Line Amount", PurchLine."Amount Including VAT", PurchLine."Line Amount",
              PurchLine."Prepayment Amount", PurchLine."Line Amount", 0);

            PrepmtInvLineBuf."VAT Amount" := PurchLine."Amount Including VAT" - PurchLine."Line Amount";
            PrepmtInvLineBuf."VAT Amount (ACY)" := PurchLine."Amount Including VAT" - PurchLine."Line Amount";
            exit(true);
        end;

        OnAfterInsertInvoiceRounding(PurchHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, PrevLineNo);
    end;

    local procedure InitInvoiceRoundingLine(PurchHeader: Record "Purchase Header"; TotalAmount: Decimal; var PurchLine: Record "Purchase Line"): Boolean
    var
        Currency: Record Currency;
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.Initialize(PurchHeader."Currency Code");
        Currency.TestField("Invoice Rounding Precision");
        InvoiceRoundingAmount :=
          -Round(
            TotalAmount -
            Round(
              TotalAmount,
              Currency."Invoice Rounding Precision",
              Currency.InvoiceRoundingDirection()),
            Currency."Amount Rounding Precision");

        if InvoiceRoundingAmount = 0 then
            exit(false);

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."System-Created Entry" := true;
        PurchLine.Type := PurchLine.Type::"G/L Account";
        PurchLine.Validate("No.", GetInvRoundingAccNo(PurchHeader."Vendor Posting Group"));
        PurchLine.Validate(Quantity, 1);
        if PurchHeader."Prices Including VAT" then
            PurchLine.Validate("Direct Unit Cost", InvoiceRoundingAmount)
        else
            PurchLine.Validate(
              "Direct Unit Cost",
              Round(
                InvoiceRoundingAmount /
                (1 + (1 - PurchHeader."VAT Base Discount %" / 100) * PurchLine."VAT %" / 100),
                Currency."Amount Rounding Precision"));
        PurchLine."Prepayment Amount" := PurchLine."Direct Unit Cost";
        PurchLine.Validate("Amount Including VAT", InvoiceRoundingAmount);
        exit(true);
    end;

    local procedure ApplyFilter(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PurchLine: Record "Purchase Line")
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        if DocumentType in [DocumentType::Invoice, DocumentType::Statistic] then
            PurchLine.SetFilter("Prepmt. Line Amount", '<>0')
        else
            PurchLine.SetFilter("Prepmt. Amt. Inv.", '<>0');

        OnAfterApplyFilter(PurchLine, PurchHeader, DocumentType);
    end;

    procedure PrepmtAmount(PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        case DocumentType of
            DocumentType::Statistic:
                exit(PurchLine."Prepmt. Line Amount");
            DocumentType::Invoice:
                exit(PurchLine."Prepmt. Line Amount" - PurchLine."Prepmt. Amt. Inv.");
            else
                exit(PurchLine."Prepmt. Amt. Inv." - PurchLine."Prepmt Amt Deducted");
        end;
    end;

    local procedure CopyHeaderCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchSetup."Copy Comments Order to Invoice" then
            exit;

        case ToDocType of
            Database::"Purch. Inv. Header":
                PurchCommentLine.CopyHeaderComments(
                    PurchCommentLine."Document Type"::Order.AsInteger(), PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(), FromNumber, ToNumber);
            Database::"Purch. Cr. Memo Hdr.":
                PurchCommentLine.CopyHeaderComments(
                    PurchCommentLine."Document Type"::Order.AsInteger(), PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), FromNumber, ToNumber);
        end;
    end;

    local procedure CopyLineCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20]; FromLineNo: Integer; ToLineNo: Integer)
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchSetup."Copy Comments Order to Invoice" then
            exit;

        case ToDocType of
            Database::"Purch. Inv. Header":
                PurchCommentLine.CopyLineComments(
                    PurchCommentLine."Document Type"::Order.AsInteger(), PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(), FromNumber, ToNumber, FromLineNo, ToLineNo);
            Database::"Purch. Cr. Memo Hdr.":
                PurchCommentLine.CopyLineComments(
                    PurchCommentLine."Document Type"::Order.AsInteger(), PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), FromNumber, ToNumber, FromLineNo, ToLineNo);
        end;
    end;

    local procedure CopyLineCommentLinesCompressedPrepayment(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        if not PurchSetup."Copy Comments Order to Invoice" then
            exit;

        case ToDocType of
            Database::"Purch. Inv. Header":
                PurchCommentLine.CopyLineCommentsFromPurchaseLines(
                  PurchCommentLine."Document Type"::Order.AsInteger(), PurchCommentLine."Document Type"::"Posted Invoice".AsInteger(), FromNumber, ToNumber, TempPurchaseLine);
            Database::"Purch. Cr. Memo Hdr.":
                PurchCommentLine.CopyLineCommentsFromPurchaseLines(
                  PurchCommentLine."Document Type"::Order.AsInteger(), PurchCommentLine."Document Type"::"Posted Credit Memo".AsInteger(), FromNumber, ToNumber, TempPurchaseLine);
        end;
    end;

    local procedure InsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer)
    var
        TempExtTextLine: Record "Extended Text Line" temporary;
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertExtendedText(TabNo, DocNo, GLAccNo, DocDate, LanguageCode, PrevLineNo, IsHandled);
        if IsHandled then
            exit;

        TransferExtText.PrepmtGetAnyExtText(GLAccNo, TabNo, DocDate, LanguageCode, TempExtTextLine);
        if TempExtTextLine.Find('-') then begin
            NextLineNo := PrevLineNo + 10000;
            repeat
                case TabNo of
                    Database::"Purch. Inv. Line":
                        begin
                            PurchInvLine.Init();
                            PurchInvLine."Document No." := DocNo;
                            PurchInvLine."Line No." := NextLineNo;
                            PurchInvLine.Description := TempExtTextLine.Text;
                            PurchInvLine.Insert();
                        end;
                    Database::"Purch. Cr. Memo Line":
                        begin
                            PurchCrMemoLine.Init();
                            PurchCrMemoLine."Document No." := DocNo;
                            PurchCrMemoLine."Line No." := NextLineNo;
                            PurchCrMemoLine.Description := TempExtTextLine.Text;
                            PurchCrMemoLine.Insert();
                        end;
                end;
                PrevLineNo := NextLineNo;
                NextLineNo := NextLineNo + 10000;
            until TempExtTextLine.Next() = 0;
        end;
    end;

    local procedure PostPrepmtInvLineBuffer(PurchHeader: Record "Purchase Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PostingDescription,
            PrepmtInvLineBuffer."Global Dimension 1 Code", PrepmtInvLineBuffer."Global Dimension 2 Code",
            PrepmtInvLineBuffer."Dimension Set ID", PurchHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);
        GenJnlLine.CopyFromPurchHeaderPrepmt(PurchHeader);
        GenJnlLine.CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer);

        GenJnlLine.Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";
        if not PrepmtInvLineBuffer.Adjustment then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;

        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := GenJournalTemplate.Name;

        OnBeforePostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit);
        RunGenJnlPostLine(GenJnlLine);
        OnAfterPostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit, GenJnlPostLine);
    end;

    local procedure PostVendorEntry(PurchHeader: Record "Purchase Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostVendorEntryProcedure(PurchHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription, DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDisc, GenJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PostingDescription,
            PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
            PurchHeader."Dimension Set ID", PurchHeader."Reason Code");
        OnPostVendorEntryOnAfterInitNewLine(GenJnlLine, PurchHeader);

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

        GenJnlLine.CopyFromPurchHeaderPrepmtPost(PurchHeader, (DocumentType = DocumentType::Invoice) or CalcPmtDisc);

        GenJnlLine.Amount := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
        GenJnlLine."Source Currency Amount" := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
        GenJnlLine."Amount (LCY)" := -TotalPrepmtInvLineBufferLCY."Amount Incl. VAT";
        GenJnlLine."Sales/Purch. (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;
        GenJnlLine."Profit (LCY)" := -TotalPrepmtInvLineBufferLCY.Amount;

        GenJnlLine.Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        GenJnlLine."Orig. Pmt. Disc. Possible" := -TotalPrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" := -TotalPrepmtInvLineBufferLCY."Orig. Pmt. Disc. Possible";

        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := GenJournalTemplate.Name;

        OnBeforePostVendorEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit, PurchHeader, DocumentType);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostVendorEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
    end;

    local procedure PostBalancingEntry(PurchHeader: Record "Purchase Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; var VendLedgEntry: Record "Vendor Ledger Entry"; DocumentType: Option Invoice,"Credit Memo"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
            PurchHeader."Posting Date", PurchHeader."Document Date", PurchHeader."VAT Reporting Date", PurchHeader."Posting Description",
            PurchHeader."Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 2 Code",
            PurchHeader."Dimension Set ID", PurchHeader."Reason Code");

        if DocType = GenJnlLine."Document Type"::"Credit Memo" then
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Refund, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode)
        else
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Payment, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

        GenJnlLine.CopyFromPurchHeaderPrepmtPost(PurchHeader, false);
        if PurchHeader."Bal. Account Type" = PurchHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := PurchHeader."Bal. Account No.";

        GenJnlLine.Amount := TotalPrepmtInvLineBuffer."Amount Incl. VAT" + VendLedgEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        if VendLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalPrepmtInvLineBufferLCY."Amount Incl. VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalPrepmtInvLineBufferLCY."Amount Incl. VAT" +
              Round(VendLedgEntry."Remaining Pmt. Disc. Possible" / VendLedgEntry."Adjusted Currency Factor");

        GenJnlLine.Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        GenJnlLine."Applies-to Doc. Type" := DocType;
        GenJnlLine."Applies-to Doc. No." := DocNo;

        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalPrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" := TotalPrepmtInvLineBufferLCY."Orig. Pmt. Disc. Possible";

        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := GenJournalTemplate.Name;

        OnBeforePostBalancingEntry(GenJnlLine, VendLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostBalancingEntry(GenJnlLine, VendLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        OnBeforeRunGenJnlPostLine(GenJnlLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure UpdatePrepmtAmountOnPurchLines(PurchHeader: Record "Purchase Header"; NewTotalPrepmtAmount: Decimal)
    var
        Currency: Record Currency;
        PurchLine: Record "Purchase Line";
        TotalLineAmount: Decimal;
        TotalPrepmtAmount: Decimal;
        TotalPrepmtAmtInv: Decimal;
        LastLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtAmountOnPurchLines(PurchHeader, NewTotalPrepmtAmount, IsHandled);
        if IsHandled then
            exit;

        Currency.Initialize(PurchHeader."Currency Code");

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        PurchLine.SetFilter("Line Amount", '<>0');
        PurchLine.SetFilter("Prepayment %", '<>0');
        PurchLine.LockTable();
        if PurchLine.Find('-') then
            repeat
                TotalLineAmount := TotalLineAmount + PurchLine."Line Amount";
                TotalPrepmtAmtInv := TotalPrepmtAmtInv + PurchLine."Prepmt. Amt. Inv.";
                LastLineNo := PurchLine."Line No.";
            until PurchLine.Next() = 0
        else
            Error(Text017, PurchLine.FieldCaption("Prepayment %"));
        if TotalLineAmount = 0 then
            Error(Text013, NewTotalPrepmtAmount);
        if not (NewTotalPrepmtAmount in [TotalPrepmtAmtInv .. TotalLineAmount]) then
            Error(Text016, TotalPrepmtAmtInv, TotalLineAmount);
        TotalPrepmtAmount := 0;
        if PurchLine.Find('-') then
            repeat
                if PurchLine."Line No." <> LastLineNo then
                    PurchLine.Validate(
                      "Prepmt. Line Amount",
                      Round(
                        NewTotalPrepmtAmount * PurchLine."Line Amount" / TotalLineAmount,
                        Currency."Amount Rounding Precision"))
                else
                    PurchLine.Validate("Prepmt. Line Amount", NewTotalPrepmtAmount - TotalPrepmtAmount);
                TotalPrepmtAmount := TotalPrepmtAmount + PurchLine."Prepmt. Line Amount";
                PurchLine.Modify();
            until PurchLine.Next() = 0;
    end;

    local procedure CreateDimensions(var PurchLine: Record "Purchase Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodeSetup.Get();
        DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", PurchLine."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, PurchLine."Job No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", PurchLine."Responsibility Center");
        OnCreateDimensionsOnAfterAddDimSources(PurchLine, DefaultDimSource);

        PurchLine."Shortcut Dimension 1 Code" := '';
        PurchLine."Shortcut Dimension 2 Code" := '';
        PurchLine."Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            PurchLine, 0, DefaultDimSource, SourceCodeSetup.Purchases,
            PurchLine."Shortcut Dimension 1 Code", PurchLine."Shortcut Dimension 2 Code", PurchLine."Dimension Set ID", Database::Vendor);

        OnAfterCreateDimensionsProcedure(PurchLine, DefaultDimSource);
    end;

    procedure GetPurchLinesToDeduct(PurchHeader: Record "Purchase Header"; var PurchLines: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        ApplyFilter(PurchHeader, 1, PurchLine);
        if PurchLine.FindSet() then
            repeat
                if (PrepmtAmount(PurchLine, 0) <> 0) and (PrepmtAmount(PurchLine, 1) <> 0) then
                    if not PurchLines.Get(PurchLine.RecordId) then begin
                        PurchLines := PurchLine;
                        PurchLines.Insert();
                    end;
            until PurchLine.Next() = 0;
    end;

    local procedure PrepmtVATDiffAmount(PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        case DocumentType of
            DocumentType::Statistic:
                exit(PurchLine."Prepayment VAT Difference");
            DocumentType::Invoice:
                exit(PurchLine."Prepayment VAT Difference");
            else
                exit(PurchLine."Prepmt VAT Diff. to Deduct");
        end;
    end;

    local procedure UpdatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20])
    begin
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        if DocumentType = DocumentType::Invoice then begin
            PurchaseHeader."Last Prepayment No." := GenJnlLineDocNo;
            PurchaseHeader."Prepayment No." := '';
            PurchLine.SetFilter("Prepmt. Line Amount", '<>0');
            if PurchLine.FindSet(true) then
                repeat
                    if PurchLine."Prepmt. Line Amount" <> PurchLine."Prepmt. Amt. Inv." then begin
                        PurchLine."Prepmt. Amt. Inv." := PurchLine."Prepmt. Line Amount";
                        PurchLine."Prepmt. Amount Inv. Incl. VAT" := PurchLine."Prepmt. Amt. Incl. VAT";
                        PurchLine.CalcPrepaymentToDeduct();
                        PurchLine."Prepmt VAT Diff. to Deduct" :=
                          PurchLine."Prepmt VAT Diff. to Deduct" + PurchLine."Prepayment VAT Difference";
                        PurchLine."Prepayment VAT Difference" := 0;
                        OnUpdatePurchaseDocumentOnBeforeModifyInvoicePurchLine(PurchLine);
                        PurchLine.Modify();
                    end;
                until PurchLine.Next() = 0;
        end else begin
            PurchaseHeader."Last Prepmt. Cr. Memo No." := GenJnlLineDocNo;
            PurchaseHeader."Prepmt. Cr. Memo No." := '';
            PurchLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if PurchLine.FindSet(true) then
                repeat
                    PurchLine."Prepmt. Amt. Inv." := PurchLine."Prepmt Amt Deducted";
                    if PurchaseHeader."Prices Including VAT" then
                        PurchLine."Prepmt. Amount Inv. Incl. VAT" := PurchLine."Prepmt. Amt. Inv."
                    else
                        PurchLine."Prepmt. Amount Inv. Incl. VAT" :=
                          Round(
                            PurchLine."Prepmt. Amt. Inv." * (100 + PurchLine."Prepayment VAT %") / 100,
                            GetCurrencyAmountRoundingPrecision(PurchLine."Currency Code"));
                    PurchLine."Prepmt. Amt. Incl. VAT" := PurchLine."Prepmt. Amount Inv. Incl. VAT";
                    PurchLine."Prepayment Amount" := PurchLine."Prepmt. Amt. Inv.";
                    PurchLine."Prepmt Amt to Deduct" := 0;
                    PurchLine."Prepmt VAT Diff. to Deduct" := 0;
                    PurchLine."Prepayment VAT Difference" := 0;
                    OnUpdatePurchaseDocumentOnBeforeModifyCrMemoPurchLine(PurchLine);
                    PurchLine.Modify();
                until PurchLine.Next() = 0;
        end;
    end;

    local procedure UpdatePostedPurchaseDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePostedPurchaseDocument(VendorLedgerEntry, PurchInvHeader, PurchCrMemoHdr, DocumentType, IsHandled, DocumentNo);
        if IsHandled then
            exit;

        case DocumentType of
            DocumentType::Invoice:
                begin
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
                    VendorLedgerEntry.SetRange("Document No.", DocumentNo);
                    VendorLedgerEntry.FindFirst();
                    PurchInvHeader.Get(DocumentNo);
                    PurchInvHeader."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchInvHeader.Modify();
                end;
            DocumentType::"Credit Memo":
                begin
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
                    VendorLedgerEntry.SetRange("Document No.", DocumentNo);
                    VendorLedgerEntry.FindFirst();
                    PurchCrMemoHdr.Get(DocumentNo);
                    PurchCrMemoHdr."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
                    PurchCrMemoHdr.Modify();
                end;
        end;

        OnAfterUpdatePostedPurchDocument(DocumentType, DocumentNo, SuppressCommit);
    end;

    local procedure InsertPurchInvHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    begin
        PurchInvHeader.Init();
        PurchInvHeader.TransferFields(PurchHeader);
        PurchInvHeader."Posting Description" := PostingDescription;
        PurchInvHeader."Payment Terms Code" := PurchHeader."Prepmt. Payment Terms Code";
        PurchInvHeader."Due Date" := PurchHeader."Prepayment Due Date";
        PurchInvHeader."Pmt. Discount Date" := PurchHeader."Prepmt. Pmt. Discount Date";
        PurchInvHeader."Payment Discount %" := PurchHeader."Prepmt. Payment Discount %";
        PurchInvHeader."No." := GenJnlLineDocNo;
        PurchInvHeader."Order No." := PurchHeader."No.";
        PurchInvHeader."Pre-Assigned No. Series" := '';
        PurchInvHeader."Source Code" := SrcCode;
        PurchInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchInvHeader."User ID"));
        PurchInvHeader."No. Printed" := 0;
        PurchInvHeader."Prepayment Invoice" := true;
        PurchInvHeader."Prepayment Order No." := PurchHeader."No.";
        PurchInvHeader."No. Series" := PostingNoSeriesCode;
        OnBeforePurchInvHeaderInsert(PurchInvHeader, PurchHeader, SuppressCommit);
        PurchInvHeader.Insert();
        CopyHeaderCommentLines(PurchHeader."No.", Database::"Purch. Inv. Header", GenJnlLineDocNo);
        OnAfterPurchInvHeaderInsert(PurchInvHeader, PurchHeader, SuppressCommit);
    end;

    local procedure InsertPurchCrMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr.TransferFields(PurchHeader);
        PurchCrMemoHdr."Payment Terms Code" := PurchHeader."Prepmt. Payment Terms Code";
        PurchCrMemoHdr."Pmt. Discount Date" := PurchHeader."Prepmt. Pmt. Discount Date";
        PurchCrMemoHdr."Payment Discount %" := PurchHeader."Prepmt. Payment Discount %";
        if (PurchHeader."Prepmt. Payment Terms Code" <> '') and not CalcPmtDiscOnCrMemos then begin
            PurchCrMemoHdr."Payment Discount %" := 0;
            PurchCrMemoHdr."Pmt. Discount Date" := 0D;
        end;
        PurchCrMemoHdr."Posting Description" := PostingDescription;
        PurchCrMemoHdr."Due Date" := PurchHeader."Prepayment Due Date";
        PurchCrMemoHdr."No." := GenJnlLineDocNo;
        PurchCrMemoHdr."Pre-Assigned No. Series" := '';
        PurchCrMemoHdr."Source Code" := SrcCode;
        PurchCrMemoHdr."User ID" := CopyStr(UserId(), 1, MaxStrLen(PurchCrMemoHdr."User ID"));
        PurchCrMemoHdr."No. Printed" := 0;
        PurchCrMemoHdr."Prepayment Credit Memo" := true;
        PurchCrMemoHdr."Prepayment Order No." := PurchHeader."No.";
        PurchCrMemoHdr.Correction := GLSetup."Mark Cr. Memos as Corrections";
        PurchCrMemoHdr."No. Series" := PostingNoSeriesCode;
        OnBeforePurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);
        PurchCrMemoHdr.Insert();
        CopyHeaderCommentLines(PurchHeader."No.", Database::"Purch. Cr. Memo Hdr.", GenJnlLineDocNo);
        OnAfterPurchCrMemoHeaderInsert(PurchCrMemoHdr, PurchHeader, SuppressCommit);
    end;

    local procedure GetCalcPmtDiscOnCrMemos(PrepmtPmtTermsCode: Code[10]): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PrepmtPmtTermsCode = '' then
            exit(false);
        PaymentTerms.Get(PrepmtPmtTermsCode);
        exit(PaymentTerms."Calc. Pmt. Disc. on Cr. Memos");
    end;

    local procedure InsertPurchInvLine(PurchInvHeader: Record "Purch. Inv. Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseHeader: Record "Purchase Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.Init();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine."Order No." := PurchInvHeader."Order No.";
        PurchInvLine."Line No." := LineNo;
        PurchInvLine."Buy-from Vendor No." := PurchInvHeader."Buy-from Vendor No.";
        PurchInvLine."Pay-to Vendor No." := PurchInvHeader."Pay-to Vendor No.";
        PurchInvLine.Type := PurchInvLine.Type::"G/L Account";
        PurchInvLine."No." := PrepmtInvLineBuffer."G/L Account No.";
        PurchInvLine."Posting Date" := PurchInvHeader."Posting Date";
        PurchInvLine."Shortcut Dimension 1 Code" := PrepmtInvLineBuffer."Global Dimension 1 Code";
        PurchInvLine."Shortcut Dimension 2 Code" := PrepmtInvLineBuffer."Global Dimension 2 Code";
        PurchInvLine."Dimension Set ID" := PrepmtInvLineBuffer."Dimension Set ID";
        PurchInvLine.Description := PrepmtInvLineBuffer.Description;
        PurchInvLine.Quantity := 1;
        if PurchInvHeader."Prices Including VAT" then begin
            PurchInvLine."Direct Unit Cost" := PrepmtInvLineBuffer."Amount Incl. VAT";
            PurchInvLine."Line Amount" := PrepmtInvLineBuffer."Amount Incl. VAT";
        end else begin
            PurchInvLine."Direct Unit Cost" := PrepmtInvLineBuffer.Amount;
            PurchInvLine."Line Amount" := PrepmtInvLineBuffer.Amount;
        end;
        PurchInvLine."Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        PurchInvLine."Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        PurchInvLine."VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        PurchInvLine."VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        PurchInvLine."VAT %" := PrepmtInvLineBuffer."VAT %";
        PurchInvLine.Amount := PrepmtInvLineBuffer.Amount;
        PurchInvLine."VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        PurchInvLine."Amount Including VAT" := PrepmtInvLineBuffer."Amount Incl. VAT";
        PurchInvLine."VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        PurchInvLine."VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        PurchInvLine."VAT Identifier" := PrepmtInvLineBuffer."VAT Identifier";
        PurchInvLine."Job No." := PrepmtInvLineBuffer."Job No.";
        PurchInvLine."Job Task No." := PrepmtInvLineBuffer."Job Task No.";
        PurchInvLine."Pmt. Discount Amount" := PrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        PurchInvLine."Location Code" := PrepmtInvLineBuffer."Location Code";
        OnBeforePurchInvLineInsert(PurchInvLine, PurchInvHeader, PrepmtInvLineBuffer, SuppressCommit);
        PurchInvLine.Insert();
        if not PurchaseHeader."Compress Prepayment" then
            CopyLineCommentLines(
              PurchaseHeader."No.", Database::"Purch. Inv. Header", PurchInvHeader."No.", PrepmtInvLineBuffer."Line No.", LineNo);
        OnAfterPurchInvLineInsert(PurchInvLine, PurchInvHeader, PrepmtInvLineBuffer, SuppressCommit);
    end;

    local procedure InsertPurchCrMemoLine(PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseHeader: Record "Purchase Header")
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.Init();
        PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
        PurchCrMemoLine."Line No." := LineNo;
        PurchCrMemoLine."Buy-from Vendor No." := PurchCrMemoHdr."Buy-from Vendor No.";
        PurchCrMemoLine."Pay-to Vendor No." := PurchCrMemoHdr."Pay-to Vendor No.";
        PurchCrMemoLine.Type := PurchCrMemoLine.Type::"G/L Account";
        PurchCrMemoLine."No." := PrepmtInvLineBuffer."G/L Account No.";
        PurchCrMemoLine."Posting Date" := PurchCrMemoHdr."Posting Date";
        PurchCrMemoLine."Shortcut Dimension 1 Code" := PrepmtInvLineBuffer."Global Dimension 1 Code";
        PurchCrMemoLine."Shortcut Dimension 2 Code" := PrepmtInvLineBuffer."Global Dimension 2 Code";
        PurchCrMemoLine."Dimension Set ID" := PrepmtInvLineBuffer."Dimension Set ID";
        PurchCrMemoLine.Description := PrepmtInvLineBuffer.Description;
        PurchCrMemoLine.Quantity := 1;
        if PurchCrMemoHdr."Prices Including VAT" then begin
            PurchCrMemoLine."Direct Unit Cost" := PrepmtInvLineBuffer."Amount Incl. VAT";
            PurchCrMemoLine."Line Amount" := PrepmtInvLineBuffer."Amount Incl. VAT";
        end else begin
            PurchCrMemoLine."Direct Unit Cost" := PrepmtInvLineBuffer.Amount;
            PurchCrMemoLine."Line Amount" := PrepmtInvLineBuffer.Amount;
        end;
        PurchCrMemoLine."Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        PurchCrMemoLine."Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        PurchCrMemoLine."VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        PurchCrMemoLine."VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        PurchCrMemoLine."VAT %" := PrepmtInvLineBuffer."VAT %";
        PurchCrMemoLine.Amount := PrepmtInvLineBuffer.Amount;
        PurchCrMemoLine."VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        PurchCrMemoLine."Amount Including VAT" := PrepmtInvLineBuffer."Amount Incl. VAT";
        PurchCrMemoLine."VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        PurchCrMemoLine."VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        PurchCrMemoLine."VAT Identifier" := PrepmtInvLineBuffer."VAT Identifier";
        PurchCrMemoLine."Job No." := PrepmtInvLineBuffer."Job No.";
        PurchCrMemoLine."Job Task No." := PrepmtInvLineBuffer."Job Task No.";
        PurchCrMemoLine."Pmt. Discount Amount" := PrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        OnBeforePurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHdr, PrepmtInvLineBuffer, SuppressCommit);
        PurchCrMemoLine.Insert();
        if not PurchaseHeader."Compress Prepayment" then
            CopyLineCommentLines(
              PurchaseHeader."No.", Database::"Purch. Cr. Memo Hdr.", PurchCrMemoHdr."No.", PrepmtInvLineBuffer."Line No.", LineNo);
        OnAfterPurchCrMemoLineInsert(PurchCrMemoLine, PurchCrMemoHdr, PrepmtInvLineBuffer, SuppressCommit);
    end;

    procedure GetPreviewMode(): Boolean
    begin
        exit(PreviewMode);
    end;

    procedure GetSuppressCommit(): Boolean
    begin
        exit(SuppressCommit);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimensionsProcedure(var PurchaseLine: Record "Purchase Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyFilter(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPrepmtDoc(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLinesOnBeforeGLPosting(var PurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PurchLine: Record "Purchase Line"; CommitIsSuppressed: Boolean; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceRounding(PurchaseHeader: Record "Purchase Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var PrevLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepayments(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(PurchaseHeader: Record "Purchase Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostedPurchDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtDoc(PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInvoice(var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreditMemo(var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLinesFromBuffer(var PurchHeader: Record "Purchase Header"; var TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; var LineCount: Integer; var Window: Dialog; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var PostedDocTabNo: Integer; var IsHandled: Boolean; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepayments(var PurchHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorEntryProcedure(var PurchHeader: Record "Purchase Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseAssertPrepmtAmountNotMoreThanDocAmount(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchInvHeader: Record "Purch. Inv. Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchCrMemoLineInsert(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean; PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSupressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetStatusPendingPrepayment(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocNos(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean; var PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePostedPurchaseDocument(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean; DocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostBalancingEntry(var PurchaseHeader: Record "Purchase Header"; var TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostVendorEntry(var PurchaseHeader: Record "Purchase Header"; var TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostVendorEntryOnAfterInitNewLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountsOnBeforeIncrAmoutns(PurchaseHeader: Record "Purchase Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseDocumentOnBeforeModifyCrMemoPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchaseDocumentOnBeforeModifyInvoicePurchLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterGetRemainder(var VATAmountLineRemainder: Record "VAT Amount Line"; var RemainderExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterVATAmountLineGet(var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforePurchLineModify(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWindowOpen(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvLineBufferOnAfterInit(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterUpdateHeaderAndLines(var PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"; var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmountOnPurchLines(PurchaseHeader: Record "Purchase Header"; NewTotalPrepmtAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCrMemoDocNos(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCrMemoDocNos(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLines(PurchaseHeader: Record "Purchase Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOpenPrepaymentLines(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckOpenPrepaymentLines(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVATAmountLineOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildInvLineBufferOnPrepmtAmountZero(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var PrepaymentInvLineBuffer2: Record "Prepayment Inv. Line Buffer"; var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TempPurchaseLineSource: Record "Purchase Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimensionsOnAfterAddDimSources(var PurchaseLine: Record "Purchase Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepmtAccNo(GenPostingSetup: Record "General Posting Setup"; var PrepmtAccNo: Code[20])
    begin
    end;
}
