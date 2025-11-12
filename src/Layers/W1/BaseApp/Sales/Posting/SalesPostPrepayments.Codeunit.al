// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Utilities;
using System.Telemetry;

codeunit 442 "Sales-Post Prepayments"
{
    Permissions = TableData "Sales Line" = rimd,
                  TableData "Sales Invoice Header" = rimd,
                  TableData "Sales Invoice Line" = rimd,
                  TableData "Sales Cr.Memo Header" = rimd,
                  TableData "Sales Cr.Memo Line" = rimd,
                  TableData "General Posting Setup" = rimd;
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        Execute(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        GenPostingSetup: Record "General Posting Setup";
        TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        ErrorMessageMgt: Codeunit "Error Message Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PrepmtDocumentType: Option ,,Invoice,"Credit Memo";
        SuppressCommit: Boolean;
        PreviewMode: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Posting Prepayment Lines   #2######\';
        Text003: Label '%1 %2 -> Invoice %3';
        Text004: Label 'Posting sales and VAT      #3######\';
        Text005: Label 'Posting to customers       #4######\';
        Text006: Label 'Posting to bal. account    #5######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PostingDateNotAllowedErr: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 - Posting Date field caption';
        SpecifyInvNoSerieTok: Label 'Specify the code for the number series that will be used to assign numbers to posted sales prepayment invoices.';
        SpecifyCrNoSerieTok: Label 'Specify the code for the number series that will be used to assign numbers to posted sales prepayment credit memos.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label '%1 %2 -> Credit Memo %3';
        Text012: Label 'Prepayment %1, %2 %3.';
        Text013: Label 'It is not possible to assign a prepayment amount of %1 to the sales lines.';
#pragma warning restore AA0470
        Text014: Label 'VAT Amount';
#pragma warning disable AA0470
        Text015: Label '%1% VAT';
        Text016: Label 'The new prepayment amount must be between %1 and %2.';
        Text017: Label 'At least one line must have %1 > 0 to distribute prepayment amount.';
        Text018: Label 'must be positive when %1 is not 0';
#pragma warning restore AA0470
        Text019: Label 'Invoice,Credit Memo';
#pragma warning restore AA0074
        PrepaymentSalesTok: Label 'Prepayment Sales', Locked = true;
        UpdateTok: Label '%1 %2', Locked = true;

    procedure SetDocumentType(DocumentType: Option ,,Invoice,"Credit Memo")
    begin
        PrepmtDocumentType := DocumentType;
    end;

    local procedure Execute(var SalesHeader: Record "Sales Header")
    begin
        case PrepmtDocumentType of
            PrepmtDocumentType::Invoice:
                Invoice(SalesHeader);
            PrepmtDocumentType::"Credit Memo":
                CreditMemo(SalesHeader);
        end;
    end;

    procedure Invoice(var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeInvoice(SalesHeader, Handled);
        if not Handled then
            Code(SalesHeader, 0);
    end;

    procedure CreditMemo(var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeCreditMemo(SalesHeader, Handled);
        if not Handled then
            Code(SalesHeader, 1);
    end;

    local procedure "Code"(var SalesHeader2: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        SourceCodeSetup: Record "Source Code Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer";
        GenJnlLine: Record "Gen. Journal Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempSalesLines: Record "Sales Line" temporary;
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        DocumentTotals: Codeunit "Document Totals";
        Window: Dialog;
        GenJnlLineDocNo: Code[20];
        GenJnlLineExtDocNo: Code[35];
        SrcCode: Code[10];
        PostingNoSeriesCode: Code[20];
        ModifyHeader: Boolean;
        IsHandled: Boolean;
        ShouldSetPendingPrepaymentStatus: Boolean;
        CalcPmtDiscOnCrMemos: Boolean;
        PostingDescription: Text[100];
        GenJnlLineDocType: Enum "Gen. Journal Document Type";
        PrevLineNo: Integer;
        LineCount: Integer;
        PostedDocTabNo: Integer;
        LineNo: Integer;
    begin
        OnBeforePostPrepayments(SalesHeader2, DocumentType, SuppressCommit, PreviewMode);

        SalesHeader := SalesHeader2;
        GLSetup.GetRecordOnce();
        SalesSetup.Get();

        FeatureTelemetry.LogUptake('0000KQB', PrepaymentSalesTok, Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KQC', PrepaymentSalesTok, PrepaymentSalesTok);

        if (SalesSetup."Calc. Inv. Discount" and (SalesHeader.Status = SalesHeader.Status::Open)) then begin
            DocumentTotals.SalesRedistributeInvoiceDiscountAmountsOnDocument(SalesHeader);
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."); // Reload SalesHeader that might have been changed
        end;

        OnCodeOnBeforeCheckPrepmtDoc(SalesHeader, DocumentType);

        CheckPrepmtDoc(SalesHeader, DocumentType);

        UpdateDocNos(SalesHeader, DocumentType, GenJnlLineDocNo, PostingNoSeriesCode, ModifyHeader);

        if not PreviewMode and ModifyHeader then begin
            SalesHeader.Modify();
            if not SuppressCommit then
                Commit();
        end;

        OnCodeOnBeforeWindowOpen(SalesHeader, DocumentType);
        if GuiAllowed then begin
            Window.Open(
            '#1#################################\\' +
            Text002 +
            Text004 +
            Text005 +
            Text006);
            Window.Update(1, StrSubstNo(UpdateTok, SelectStr(1 + DocumentType, Text019), SalesHeader."No."));
        end;

        SourceCodeSetup.Get();
        SrcCode := SourceCodeSetup.Sales;
        if SalesHeader."Prepmt. Posting Description" <> '' then
            PostingDescription := SalesHeader."Prepmt. Posting Description"
        else
            PostingDescription :=
              CopyStr(
                StrSubstNo(Text012, SelectStr(1 + DocumentType, Text019), SalesHeader."Document Type", SalesHeader."No."),
                1, MaxStrLen(SalesHeader."Posting Description"));
        OnCodeOnAfterPostingDescriptionSet(SalesHeader, DocumentType, PostingDescription);
        // Create posted header
        if SalesSetup."Ext. Doc. No. Mandatory" then
            SalesHeader.TestField("External Document No.");

        OnCodeOnBeforeInsertPostedHeaders(SalesHeader);
        case DocumentType of
            DocumentType::Invoice:
                begin
                    InsertSalesInvHeader(SalesInvHeader, SalesHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode);
                    GenJnlLineDocType := GenJnlLine."Document Type"::Invoice;
                    PostedDocTabNo := Database::"Sales Invoice Header";
                    if GuiAllowed then
                        Window.Update(1, StrSubstNo(Text003, SalesHeader."Document Type", SalesHeader."No.", SalesInvHeader."No."));
                end;
            DocumentType::"Credit Memo":
                begin
                    CalcPmtDiscOnCrMemos := GetCalcPmtDiscOnCrMemos(SalesHeader."Prepmt. Payment Terms Code");
                    InsertSalesCrMemoHeader(
                      SalesCrMemoHeader, SalesHeader, PostingDescription, GenJnlLineDocNo, SrcCode, PostingNoSeriesCode,
                      CalcPmtDiscOnCrMemos);
                    GenJnlLineDocType := GenJnlLine."Document Type"::"Credit Memo";
                    PostedDocTabNo := Database::"Sales Cr.Memo Header";
                    if GuiAllowed then
                        Window.Update(1, StrSubstNo(Text011, SalesHeader."Document Type", SalesHeader."No.", SalesCrMemoHeader."No."));
                end;
        end;
        GenJnlLineExtDocNo := SalesHeader."External Document No.";
        // Reverse old lines
        if DocumentType = DocumentType::Invoice then begin
            GetSalesLinesToDeduct(SalesHeader, TempSalesLines);
            if not TempSalesLines.IsEmpty() then
                CalcVATAmountLines(SalesHeader, TempSalesLines, TempVATAmountLineDeduct, DocumentType::"Credit Memo");
        end;
        // Create Lines
        TempPrepmtInvLineBuffer.DeleteAll();

        IsHandled := false;
        OnCodeOnBeforeCalcAndUpdateVATAmountLines(SalesHeader, SalesLine, TempPrepmtInvLineBuffer, DocumentType, IsHandled);
        if not IsHandled then begin
            CalcVATAmountLines(SalesHeader, SalesLine, TempVATAmountLine, DocumentType);
            TempVATAmountLine.DeductVATAmountLine(TempVATAmountLineDeduct);
            UpdateVATOnLines(SalesHeader, SalesLine, TempVATAmountLine, DocumentType);
            BuildInvLineBuffer(SalesHeader, SalesLine, DocumentType, TempPrepmtInvLineBuffer, true);
        end;
        OnCodeOnAfterBuildInvLineBuffer(TempVATAmountLine, TempPrepmtInvLineBuffer);

        CreateLinesFromBuffer(SalesHeader, SalesLine, TempPrepmtInvLineBuffer, SalesInvHeader, SalesCrMemoHeader, PrevLineNo, LineCount, PostedDocTabNo, LineNo, DocumentType, Window, GenJnlLineDocNo);

        if SalesHeader."Compress Prepayment" then
            case DocumentType of
                DocumentType::Invoice:
                    CopyLineCommentLinesCompressedPrepayment(SalesHeader."No.", Database::"Sales Invoice Header", SalesInvHeader."No.");
                DocumentType::"Credit Memo":
                    CopyLineCommentLinesCompressedPrepayment(SalesHeader."No.", Database::"Sales Cr.Memo Header", SalesCrMemoHeader."No.");
            end;

        OnAfterCreateLinesOnBeforeGLPosting(SalesHeader, SalesInvHeader, SalesCrMemoHeader, TempPrepmtInvLineBuffer, DocumentType, LineNo);

        // G/L Posting
        LineCount := 0;
        if not SalesHeader."Compress Prepayment" then
            TempPrepmtInvLineBuffer.CompressBuffer();
        TempPrepmtInvLineBuffer.SetRange(Adjustment, false);
        TempPrepmtInvLineBuffer.FindSet(true);
        repeat
            if DocumentType = DocumentType::Invoice then
                TempPrepmtInvLineBuffer.ReverseAmounts();
            RoundAmounts(SalesHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY);
            if SalesHeader."Currency Code" = '' then begin
                AdjustInvLineBuffers(SalesHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBuffer, DocumentType);
                TotalPrepmtInvLineBufferLCY := TotalPrepmtInvLineBuffer;
            end else
                AdjustInvLineBuffers(SalesHeader, TempPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType);
            TempPrepmtInvLineBuffer.Modify();
        until TempPrepmtInvLineBuffer.Next() = 0;

        TempPrepmtInvLineBuffer.Reset();
        TempPrepmtInvLineBuffer.SetCurrentKey(Adjustment);
        TempPrepmtInvLineBuffer.Find('+');
        repeat
            LineCount := LineCount + 1;
            if GuiAllowed then
                Window.Update(3, LineCount);

            PostPrepmtInvLineBuffer(
              SalesHeader, TempPrepmtInvLineBuffer, DocumentType, PostingDescription,
              GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
        until TempPrepmtInvLineBuffer.Next(-1) = 0;
        // Post customer entry
        if GuiAllowed then
            Window.Update(4, 1);
        OnCodeOnBeforePostCustomerEntry(SalesHeader, TempPrepmtInvLineBuffer);
        PostCustomerEntry(
          SalesHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription,
          GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDiscOnCrMemos);

        UpdatePostedSalesDocument(DocumentType, GenJnlLineDocNo, CustLedgEntry);

        SalesAssertPrepmtAmountNotMoreThanDocAmount(CustLedgEntry, SalesHeader, SalesLine);
        // Balancing account
        if SalesHeader."Bal. Account No." <> '' then begin
            if GuiAllowed then
                Window.Update(5, 1);
            OnCodeOnBeforePostBalancingEntry(SalesHeader, TempPrepmtInvLineBuffer);
            PostBalancingEntry(
              SalesHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, CustLedgEntry, DocumentType,
              PostingDescription, GenJnlLineDocType, GenJnlLineDocNo, GenJnlLineExtDocNo, SrcCode, PostingNoSeriesCode);
        end;
        // Update lines & header
        UpdateSalesDocument(SalesHeader, SalesLine, DocumentType, GenJnlLineDocNo);
        ShouldSetPendingPrepaymentStatus := SalesHeader.TestStatusIsNotPendingPrepayment();
        OnCodeOnAfterCalcShouldSetPendingPrepaymentStatus(SalesHeader, SalesInvHeader, SalesCrMemoHeader, DocumentType, PreviewMode, ShouldSetPendingPrepaymentStatus);
        if ShouldSetPendingPrepaymentStatus then
            SalesHeader.Status := SalesHeader.Status::"Pending Prepayment";
        SalesHeader.Modify();

        OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(SalesHeader, SalesInvHeader, SalesCrMemoHeader, GenJnlPostLine, PreviewMode);

        if PreviewMode then begin
            if GuiAllowed then
                Window.Close();
            OnBeforeThrowPreviewError(SalesHeader);
            GenJnlPostPreview.ThrowError();
        end;

        SalesHeader2 := SalesHeader;

        OnAfterPostPrepayments(SalesHeader2, DocumentType, SuppressCommit, SalesInvHeader, SalesCrMemoHeader, CustLedgEntry);
    end;

    local procedure CreateLinesFromBuffer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var PrevLineNo: Integer; var LineCount: Integer; var PostedDocTabNo: Integer; var LineNo: Integer; DocumentType: Option Invoice,"Credit Memo"; var Window: Dialog; GenJnlLineDocNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateLinesFromBuffer(SalesHeader, SalesLine, TempPrepmtInvLineBuffer, LineCount, SalesInvHeader, SalesCrMemoHeader, PostedDocTabNo, DocumentType, LineNo, GenJnlLineDocNo, IsHandled);
        if IsHandled then
            exit;

        TempPrepmtInvLineBuffer.Find('-');
        repeat
            LineCount := LineCount + 1;
            if GuiAllowed then
                Window.Update(2, LineCount);
            LineNo := PrevLineNo + 10000;
            case DocumentType of
                DocumentType::Invoice:
                    begin
                        InsertSalesInvLine(SalesInvHeader, LineNo, TempPrepmtInvLineBuffer, SalesHeader);
                        PostedDocTabNo := Database::"Sales Invoice Line";
                    end;
                DocumentType::"Credit Memo":
                    begin
                        InsertSalesCrMemoLine(SalesCrMemoHeader, LineNo, TempPrepmtInvLineBuffer, SalesHeader);
                        PostedDocTabNo := Database::"Sales Cr.Memo Line";
                    end;
            end;
            PrevLineNo := LineNo;
            InsertExtendedText(PostedDocTabNo, GenJnlLineDocNo, TempPrepmtInvLineBuffer."G/L Account No.", SalesHeader."Document Date", SalesHeader."Language Code", PrevLineNo, SalesHeader);
        until TempPrepmtInvLineBuffer.Next() = 0;
    end;

    local procedure SalesAssertPrepmtAmountNotMoreThanDocAmount(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesAssertPrepmtAmountNotMoreThanDocAmount(CustLedgEntry, SalesHeader, SalesLine, IsHandled);
        if IsHandled then
            exit;

        if CustLedgEntry."Entry No." = 0 then // Fallback if the Customer Ledger Entry was not provided from UpdatePostedSalesDocument or the event
            CustLedgEntry.FindLast();

        CustLedgEntry.CalcFields(Amount);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            SalesLine.CalcSums("Amount Including VAT");
            PrepaymentMgt.AssertPrepmtAmountNotMoreThanDocAmount(
                SalesLine."Amount Including VAT", CustLedgEntry.Amount, SalesHeader."Currency Code", SalesSetup."Invoice Rounding");
        end;
    end;

    procedure CheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    var
        Cust: Record Customer;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        CheckDimensions: Codeunit "Check Dimensions";
        ForwardLinkMgt: codeunit "Forward Link Mgt.";
        ErrorContextElement: Codeunit "Error Context Element";
        SetupRecID: RecordID;
    begin
        OnBeforeCheckPrepmtDoc(SalesHeader, DocumentType, SuppressCommit);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.TestField("Sell-to Customer No.");
        SalesHeader.TestField("Bill-to Customer No.");
        SalesHeader.TestField("Posting Date");
        SalesHeader.TestField("Document Date");
        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then
            SalesHeader.TestField("Journal Templ. Name");
        ErrorMessageMgt.PushContext(ErrorContextElement, SalesHeader.RecordId, 0, '');
        if GenJnlCheckLine.DateNotAllowed(SalesHeader."Posting Date", SalesHeader."Journal Templ. Name") then
            ErrorMessageMgt.LogContextFieldError(
              SalesHeader.FieldNo("Posting Date"), StrSubstNo(PostingDateNotAllowedErr, SalesHeader.FieldCaption("Posting Date")),
              SetupRecID, ErrorMessageMgt.GetFieldNo(SetupRecID.TableNo, ''),
              ForwardLinkMgt.GetHelpCodeForAllowedPostingDate());

        if not CheckOpenPrepaymentLines(SalesHeader, DocumentType) then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        CheckDimensions.CheckSalesPrepmtDim(SalesHeader);

        SalesHeader.CheckSalesPostRestrictions();
        Cust.Get(SalesHeader."Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, Enum::"Sales Document Type".FromInteger(PrepmtDocTypeToDocType(DocumentType)), false, true);
        if SalesHeader."Bill-to Customer No." <> SalesHeader."Sell-to Customer No." then begin
            Cust.Get(SalesHeader."Bill-to Customer No.");
            Cust.CheckBlockedCustOnDocs(Cust, Enum::"Sales Document Type".FromInteger(PrepmtDocTypeToDocType(DocumentType)), false, true);
        end;
        OnAfterCheckPrepmtDoc(SalesHeader, DocumentType, SuppressCommit, ErrorMessageMgt);
        ErrorMessageMgt.Finish(SalesHeader.RecordId);
    end;

    local procedure UpdateDocNos(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocNos(SalesHeader, DocumentType, DocNo, NoSeriesCode, ModifyHeader, PreviewMode, IsHandled);
        if IsHandled then
            exit;

        ModifyHeader := false;
        case DocumentType of
            DocumentType::Invoice:
                begin
                    SalesHeader.TestField("Prepayment Due Date");
                    SalesHeader.TestField("Prepmt. Cr. Memo No.", '');
                    if SalesHeader."Prepayment No." = '' then
                        if not PreviewMode then
                            UpdateInvoiceDocNos(SalesHeader, ModifyHeader)
                        else
                            SalesHeader."Prepayment No." := '***';
                    DocNo := SalesHeader."Prepayment No.";
                    NoSeriesCode := SalesHeader."Prepayment No. Series";
                end;
            DocumentType::"Credit Memo":
                begin
                    SalesHeader.TestField("Prepayment No.", '');
                    if SalesHeader."Prepmt. Cr. Memo No." = '' then
                        if not PreviewMode then
                            UpdateCrMemoDocNos(SalesHeader, ModifyHeader)
                        else
                            SalesHeader."Prepmt. Cr. Memo No." := '***';
                    DocNo := SalesHeader."Prepmt. Cr. Memo No.";
                    NoSeriesCode := SalesHeader."Prepmt. Cr. Memo No. Series";
                end;
        end;

        if GLSetup."Journal Templ. Name Mandatory" then
            GenJournalTemplate.Get(SalesHeader."Journal Templ. Name");

        OnAfterUpdateDocNos(SalesHeader);
    end;

    local procedure UpdateInvoiceDocNos(var SalesHeader: Record "Sales Header"; var ModifyHeader: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        if GLSetup."Journal Templ. Name Mandatory" then begin
            SalesReceivablesSetup.GetRecordOnce();
            SalesReceivablesSetup.TestField("S. Prep. Inv. Template Name");
            GenJournalTemplate.Get(SalesReceivablesSetup."S. Prep. Inv. Template Name");
            GenJournalTemplate.TestField("Posting No. Series");
            SalesHeader."Prepayment No." := NoSeries.GetNextNo(GenJournalTemplate."Posting No. Series", SalesHeader."Posting Date");
            ModifyHeader := true;
        end else begin
            if SalesHeader."Prepayment No. Series" = '' then begin
                SalesReceivablesSetup.Get();
                ErrorMessageMgt.PushContext(ErrorContextElement, SalesReceivablesSetup.RecordId, 0, '');
                if SalesReceivablesSetup."Posted Prepmt. Inv. Nos." = '' then
                    ErrorMessageMgt.LogContextFieldError(
                        SalesReceivablesSetup.FieldNo("Posted Prepmt. Inv. Nos."), SpecifyInvNoSerieTok,
                        SalesReceivablesSetup.RecordId, SalesReceivablesSetup.FieldNo("Posted Prepmt. Inv. Nos."), '');
                ErrorMessageMgt.Finish(SalesReceivablesSetup.RecordId);
                SalesHeader."Prepayment No. Series" := SalesReceivablesSetup."Posted Prepmt. Inv. Nos.";
                ModifyHeader := true;
            end;
            SalesHeader.TestField("Prepayment No. Series");
            SalesHeader."Prepayment No." := NoSeries.GetNextNo(SalesHeader."Prepayment No. Series", SalesHeader."Posting Date");
            ModifyHeader := true;
        end;
    end;

    local procedure UpdateCrMemoDocNos(var SalesHeader: Record "Sales Header"; var ModifyHeader: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        if GLSetup."Journal Templ. Name Mandatory" then begin
            SalesReceivablesSetup.GetRecordOnce();
            SalesReceivablesSetup.TestField("S. Prep. Cr.Memo Template Name");
            GenJournalTemplate.Get(SalesReceivablesSetup."S. Prep. Cr.Memo Template Name");
            GenJournalTemplate.TestField("Posting No. Series");
            SalesHeader."Prepmt. Cr. Memo No." := NoSeries.GetNextNo(GenJournalTemplate."Posting No. Series", SalesHeader."Posting Date");
            ModifyHeader := true;
        end else begin
            if SalesHeader."Prepmt. Cr. Memo No. Series" = '' then begin
                SalesReceivablesSetup.Get();
                ErrorMessageMgt.PushContext(ErrorContextElement, SalesReceivablesSetup.RecordId, 0, '');
                if SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos." = '' then
                    ErrorMessageMgt.LogContextFieldError(
                        SalesReceivablesSetup.FieldNo("Posted Prepmt. Cr. Memo Nos."), SpecifyCrNoSerieTok,
                        SalesReceivablesSetup.RecordId, SalesReceivablesSetup.FieldNo("Posted Prepmt. Cr. Memo Nos."), '');
                ErrorMessageMgt.Finish(SalesReceivablesSetup.RecordId);
                SalesReceivablesSetup.Testfield("Posted Prepmt. Cr. Memo Nos.");
                SalesHeader."Prepmt. Cr. Memo No. Series" := SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos.";
                ModifyHeader := true;
            end;
            SalesHeader.TestField("Prepmt. Cr. Memo No. Series");
            SalesHeader."Prepmt. Cr. Memo No." := NoSeries.GetNextNo(SalesHeader."Prepmt. Cr. Memo No. Series", SalesHeader."Posting Date");
            ModifyHeader := true;
        end;
    end;

    procedure CheckOpenPrepaymentLines(SalesHeader: Record "Sales Header"; DocumentType: Option) Found: Boolean
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOpenPrepaymentLines(SalesHeader, DocumentType, Found, IsHandled);
        if IsHandled then
            exit(Found);

        ApplyFilter(SalesHeader, DocumentType, SalesLine);
        if SalesLine.Find('-') then
            repeat
                if not Found then
                    Found := PrepmtAmount(SalesLine, DocumentType) <> 0;
                if SalesLine."Prepmt. Amt. Inv." = 0 then begin
                    SalesLine.UpdatePrepmtSetupFields();
                    SalesLine.Modify();
                end;
            until SalesLine.Next() = 0;
        exit(Found);
    end;

    local procedure RoundAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    var
        VAT: Boolean;
    begin
        TotalPrepmtInvLineBuf.IncrAmounts(PrepmtInvLineBuf);

        if SalesHeader."Currency Code" <> '' then begin
            VAT := PrepmtInvLineBuf.Amount <> PrepmtInvLineBuf."Amount Incl. VAT";
            PrepmtInvLineBuf."Amount Incl. VAT" :=
              AmountToLCY(SalesHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", TotalPrepmtInvLineBufLCY."Amount Incl. VAT");
            if VAT then
                PrepmtInvLineBuf.Amount := AmountToLCY(SalesHeader, TotalPrepmtInvLineBuf.Amount, TotalPrepmtInvLineBufLCY.Amount)
            else
                PrepmtInvLineBuf.Amount := PrepmtInvLineBuf."Amount Incl. VAT";
            PrepmtInvLineBuf."VAT Amount" := PrepmtInvLineBuf."Amount Incl. VAT" - PrepmtInvLineBuf.Amount;
            if PrepmtInvLineBuf."VAT Base Amount" <> 0 then
                PrepmtInvLineBuf."VAT Base Amount" := PrepmtInvLineBuf.Amount;
            PrepmtInvLineBuf."Orig. Pmt. Disc. Possible" :=
              AmountToLCY(
                SalesHeader,
                TotalPrepmtInvLineBuf."Orig. Pmt. Disc. Possible", TotalPrepmtInvLineBufLCY."Orig. Pmt. Disc. Possible");
        end;

        OnRoundAmountsOnBeforeIncrAmounts(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);

        TotalPrepmtInvLineBufLCY.IncrAmounts(PrepmtInvLineBuf);

        OnAfterRoundAmounts(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
    end;

    local procedure AmountToLCY(SalesHeader: Record "Sales Header"; TotalAmt: Decimal; PrevTotalAmt: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Init();
        exit(
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(SalesHeader."Posting Date", SalesHeader."Currency Code", TotalAmt, SalesHeader."Currency Factor")) -
            PrevTotalAmt);
    end;

    local procedure BuildInvLineBuffer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; var TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; UpdateLines: Boolean)
    var
        PrepmtInvLineBuf2: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferDummy: Record "Prepayment Inv. Line Buffer";
    begin
        TempGlobalPrepmtInvLineBuf.Reset();
        TempGlobalPrepmtInvLineBuf.DeleteAll();
        TempSalesLine.Reset();
        TempSalesLine.DeleteAll();
        SalesSetup.Get();
        ApplyFilter(SalesHeader, DocumentType, SalesLine);
        if SalesLine.Find('-') then
            repeat
                if PrepmtAmount(SalesLine, DocumentType) <> 0 then begin
                    if not CheckSystemCreatedInvoiceRoundEntry(SalesLine, SalesHeader."Customer Posting Group") then
                        CheckSalesLineIsNegative(SalesHeader, SalesLine);

                    OnBuildInvLineBufferOnBeforeFillInvLineBuffer(SalesHeader, SalesLine);
                    FillInvLineBuffer(SalesHeader, SalesLine, PrepmtInvLineBuf2);
                    if UpdateLines then
                        TempGlobalPrepmtInvLineBuf.CopyWithLineNo(PrepmtInvLineBuf2, SalesLine."Line No.");
                    TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
                    if SalesSetup."Invoice Rounding" then
                        RoundAmounts(SalesHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferDummy);
                    TempSalesLine := SalesLine;
                    TempSalesLine.Insert();
                end;
            until SalesLine.Next() = 0;
        if SalesSetup."Invoice Rounding" then
            if InsertInvoiceRounding(
                 SalesHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, SalesLine."Line No.")
            then
                TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
        ErrorMessageMgt.FinishTopContext();

        OnAfterBuildInvLineBuffer(TempPrepmtInvLineBuf);
    end;

    procedure BuildInvLineBuffer(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        BuildInvLineBuffer(SalesHeader, SalesLine, DocumentType, PrepmtInvLineBuf, false);
    end;

    local procedure AdjustInvLineBuffers(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo")
    var
        VATAdjustment: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        CalcPrepmtAmtInvLCYInLines(SalesHeader, PrepmtInvLineBuf, DocumentType, VATAdjustment);
        if Abs(VATAdjustment[VAT::Base]) > GLSetup."Amount Rounding Precision" then
            InsertCorrInvLineBuffer(PrepmtInvLineBuf, SalesHeader, VATAdjustment[VAT::Base])
        else
            if (VATAdjustment[VAT::Base] <> 0) or (VATAdjustment[VAT::Amount] <> 0) then begin
                PrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
                TotalPrepmtInvLineBuf.AdjustVATBase(VATAdjustment);
            end;
    end;

    local procedure CalcPrepmtAmtInvLCYInLines(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; var VATAdjustment: array[2] of Decimal)
    var
        SalesLine: Record "Sales Line";
        PrepmtInvBufAmount: array[2] of Decimal;
        TotalAmount: array[2] of Decimal;
        LineAmount: array[2] of Decimal;
        Ratio: array[2] of Decimal;
        PrepmtAmtReminder: array[2] of Decimal;
        PrepmtAmountRnded: array[2] of Decimal;
        VAT: Option ,Base,Amount;
    begin
        PrepmtInvLineBuf.AmountsToArray(PrepmtInvBufAmount);
        if DocumentType = DocumentType::Invoice then
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

                SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", TempGlobalPrepmtInvLineBuf."Line No.");
                if DocumentType = DocumentType::"Credit Memo" then begin
                    VATAdjustment[VAT::Base] += SalesLine."Prepmt. Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Base];
                    SalesLine."Prepmt. Amount Inv. (LCY)" := 0;
                    VATAdjustment[VAT::Amount] += SalesLine."Prepmt. VAT Amount Inv. (LCY)" - PrepmtAmountRnded[VAT::Amount];
                    SalesLine."Prepmt. VAT Amount Inv. (LCY)" := 0;
                end else begin
                    SalesLine."Prepmt. Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Base];
                    SalesLine."Prepmt. VAT Amount Inv. (LCY)" += PrepmtAmountRnded[VAT::Amount];
                end;
                SalesLine.Modify();
            until TempGlobalPrepmtInvLineBuf.Next() = 0;
        TempGlobalPrepmtInvLineBuf.DeleteAll();
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

    local procedure InsertCorrInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header"; VATBaseAdjustment: Decimal)
    var
        NewPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        SavedPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        AdjmtAmountACY: Decimal;
    begin
        SavedPrepmtInvLineBuf := PrepmtInvLineBuf;

        if SalesHeader."Currency Code" = '' then
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
          GetCorrBalAccNo(SalesHeader, VATBaseAdjustment > 0),
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
        PrepmtAccNo := GenPostingSetup.GetSalesPrepmtAccount();
        OnAfterGetPrepmtAccNo(GenPostingSetup, PrepmtAccNo);
        exit(PrepmtAccNo);
    end;

    procedure GetCorrBalAccNo(SalesHeader: Record "Sales Header"; PositiveAmount: Boolean): Code[20]
    var
        BalAccNo: Code[20];
    begin
        if SalesHeader."Currency Code" = '' then
            BalAccNo := GetInvRoundingAccNo(SalesHeader."Customer Posting Group")
        else
            BalAccNo := GetGainLossGLAcc(SalesHeader."Currency Code", PositiveAmount);

        OnAfterGetCorrBalAccNo(SalesHeader, PositiveAmount, BalAccNo);
        exit(BalAccNo);
    end;

    procedure GetInvRoundingAccNo(CustomerPostingGroup: Code[20]): Code[20]
    var
        CustPostingGr: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
    begin
        CustPostingGr.Get(CustomerPostingGroup);
        GLAcc.Get(CustPostingGr.GetInvRoundingAccount());
        exit(CustPostingGr."Invoice Rounding Account");
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

    procedure FillInvLineBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer")
    begin
        PrepmtInvLineBuf.Init();
        OnBeforeFillInvLineBuffer(PrepmtInvLineBuf, SalesHeader, SalesLine);
        PrepmtInvLineBuf."G/L Account No." := GetPrepmtAccNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        if not SalesHeader."Compress Prepayment" then begin
            PrepmtInvLineBuf."Line No." := SalesLine."Line No.";
            PrepmtInvLineBuf.Description := SalesLine.Description;
        end;

        PrepmtInvLineBuf.CopyFromSalesLine(SalesLine);
        PrepmtInvLineBuf.FillFromGLAcc(SalesHeader."Compress Prepayment");

        PrepmtInvLineBuf.SetAmounts(
          SalesLine."Prepayment Amount", SalesLine."Prepmt. Amt. Incl. VAT", SalesLine."Prepayment Amount",
          SalesLine."Prepayment Amount", SalesLine."Prepayment Amount", SalesLine."Prepayment VAT Difference");

        PrepmtInvLineBuf."VAT Amount" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Amount (ACY)" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Base Before Pmt. Disc." := -SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."Orig. Pmt. Disc. Possible" := SalesLine."Prepmt. Pmt. Discount Amount";

        OnAfterFillInvLineBuffer(PrepmtInvLineBuf, SalesLine, SuppressCommit, SalesHeader);
    end;

    local procedure InsertInvoiceRounding(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrevLineNo: Integer): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if InitInvoiceRoundingLine(SalesHeader, TotalPrepmtInvLineBuf."Amount Incl. VAT", SalesLine) then begin
            CreateDimensions(SalesLine);
            PrepmtInvLineBuf.Init();
            PrepmtInvLineBuf."Line No." := PrevLineNo + 10000;
            PrepmtInvLineBuf."Invoice Rounding" := true;
            PrepmtInvLineBuf."G/L Account No." := SalesLine."No.";
            PrepmtInvLineBuf.Description := SalesLine.Description;

            PrepmtInvLineBuf.CopyFromSalesLine(SalesLine);
            PrepmtInvLineBuf."Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
            PrepmtInvLineBuf."VAT Bus. Posting Group" := SalesHeader."VAT Bus. Posting Group";

            PrepmtInvLineBuf.SetAmounts(
              SalesLine."Line Amount", SalesLine."Amount Including VAT", SalesLine."Line Amount",
              SalesLine."Prepayment Amount", SalesLine."Line Amount", 0);

            PrepmtInvLineBuf."VAT Amount" := SalesLine."Amount Including VAT" - SalesLine."Line Amount";
            PrepmtInvLineBuf."VAT Amount (ACY)" := SalesLine."Amount Including VAT" - SalesLine."Line Amount";
            OnAfterInsertInvoiceRounding(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, PrevLineNo);
            exit(true);
        end;
    end;

    procedure InitInvoiceRoundingLine(SalesHeader: Record "Sales Header"; TotalAmount: Decimal; var SalesLine: Record "Sales Line"): Boolean
    var
        Currency: Record Currency;
        InvoiceRoundingAmount: Decimal;
    begin
        Currency.Initialize(SalesHeader."Currency Code");
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

        SalesLine.SetHideValidationDialog(true);
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."System-Created Entry" := true;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine.Validate("No.", GetInvRoundingAccNo(SalesHeader."Customer Posting Group"));
        SalesLine.Validate(Quantity, 1);
        if SalesHeader."Prices Including VAT" then
            SalesLine.Validate("Unit Price", InvoiceRoundingAmount)
        else
            SalesLine.Validate(
              "Unit Price",
              Round(
                InvoiceRoundingAmount /
                (1 + (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100) * SalesLine."VAT %" / 100),
                Currency."Amount Rounding Precision"));
        SalesLine."Prepayment Amount" := SalesLine."Unit Price";
        SalesLine.Validate("Amount Including VAT", InvoiceRoundingAmount);
        exit(true);
    end;

    local procedure CopyHeaderCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        if not SalesSetup."Copy Comments Order to Invoice" then
            exit;

        case ToDocType of
            Database::"Sales Invoice Header":
                SalesCommentLine.CopyHeaderComments(
                    SalesCommentLine."Document Type"::Order.AsInteger(), SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                    FromNumber, ToNumber);
            Database::"Sales Cr.Memo Header":
                SalesCommentLine.CopyHeaderComments(
                    SalesCommentLine."Document Type"::Order.AsInteger(), SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                    FromNumber, ToNumber);
        end;
    end;

    local procedure CopyLineCommentLines(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20]; FromLineNo: Integer; ToLineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        if not SalesSetup."Copy Comments Order to Invoice" then
            exit;

        case ToDocType of
            Database::"Sales Invoice Header":
                SalesCommentLine.CopyLineComments(
                    SalesCommentLine."Document Type"::Order.AsInteger(), SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                    FromNumber, ToNumber, FromLineNo, ToLineNo);
            Database::"Sales Cr.Memo Header":
                SalesCommentLine.CopyLineComments(
                    SalesCommentLine."Document Type"::Order.AsInteger(), SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                    FromNumber, ToNumber, FromLineNo, ToLineNo);
        end;
    end;

    local procedure CopyLineCommentLinesCompressedPrepayment(FromNumber: Code[20]; ToDocType: Integer; ToNumber: Code[20])
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        if not SalesSetup."Copy Comments Order to Invoice" then
            exit;

        case ToDocType of
            Database::"Sales Invoice Header":
                SalesCommentLine.CopyLineCommentsFromSalesLines(
                  SalesCommentLine."Document Type"::Order.AsInteger(), SalesCommentLine."Document Type"::"Posted Invoice".AsInteger(),
                  FromNumber, ToNumber, TempSalesLine);
            Database::"Sales Cr.Memo Header":
                SalesCommentLine.CopyLineCommentsFromSalesLines(
                  SalesCommentLine."Document Type"::Order.AsInteger(), SalesCommentLine."Document Type"::"Posted Credit Memo".AsInteger(),
                  FromNumber, ToNumber, TempSalesLine);
        end;
    end;

    local procedure InsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer; var SalesHeader: Record "Sales Header")
    var
        TempExtTextLine: Record "Extended Text Line" temporary;
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TransferExtText: Codeunit "Transfer Extended Text";
        NextLineNo: Integer;
    begin
        OnBeforeInsertExtendedText(TabNo, DocNo, GLAccNo, DocDate, LanguageCode, PrevLineNo);
        TransferExtText.PrepmtGetAnyExtText(GLAccNo, TabNo, DocDate, LanguageCode, TempExtTextLine);
        if TempExtTextLine.Find('-') then begin
            NextLineNo := PrevLineNo + 10000;
            repeat
                case TabNo of
                    Database::"Sales Invoice Line":
                        begin
                            SalesInvLine.Init();
                            SalesInvLine."Document No." := DocNo;
                            SalesInvLine."Line No." := NextLineNo;
                            SalesInvLine.Description := TempExtTextLine.Text;
                            OnInsertExtendedTextOnBeforeSalesInvLineInsert(SalesInvLine, TabNo, DocNo, NextLineNo, TempExtTextLine, SalesHeader);
                            SalesInvLine.Insert();
                        end;
                    Database::"Sales Cr.Memo Line":
                        begin
                            SalesCrMemoLine.Init();
                            SalesCrMemoLine."Document No." := DocNo;
                            SalesCrMemoLine."Line No." := NextLineNo;
                            SalesCrMemoLine.Description := TempExtTextLine.Text;
                            OnInsertExtendedTextOnBeforeSalesCrMemoLineInsert(SalesCrMemoLine, TabNo, DocNo, NextLineNo, TempExtTextLine, SalesHeader);
                            SalesCrMemoLine.Insert();
                        end;
                end;
                PrevLineNo := NextLineNo;
                NextLineNo := NextLineNo + 10000;
            until TempExtTextLine.Next() = 0;
        end;
    end;

    procedure UpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
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
        GLSetup.GetRecordOnce();
        Currency.Initialize(SalesHeader."Currency Code");

        ApplyFilter(SalesHeader, DocumentType, SalesLine);
        SalesLine.LockTable();
        SalesLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Inv.");
        PrepmtAmtToInvTotal := SalesLine."Prepmt. Line Amount" - SalesLine."Prepmt. Amt. Inv.";
        if SalesLine.FindSet() then
            repeat
                PrepmtAmt := PrepmtAmount(SalesLine, DocumentType);
                if PrepmtAmt <> 0 then begin
                    FindVATAmountLine(SalesLine, VATAmountLine, PrepmtAmt);
                    OnUpdateVATOnLinesOnAfterVATAmountLineGet(VATAmountLine);
                    if VATAmountLine.Modified then begin
                        RemainderExists :=
                          FindVATAmountLine(SalesLine, TempVATAmountLineRemainder, PrepmtAmt);
                        OnUpdateVATOnLinesOnAfterGetRemainder(TempVATAmountLineRemainder, RemainderExists);
                        if not RemainderExists then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        if SalesHeader."Prices Including VAT" then begin
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
                                NewAmount * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100),
                                Currency."Amount Rounding Precision");
                        end else begin
                            if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then begin
                                VATAmount := PrepmtAmt;
                                NewAmount := 0;
                                NewVATBaseAmount := 0;
                            end else begin
                                NewAmount := PrepmtAmt;
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100),
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

                        SalesLine."Prepayment Amount" := NewAmount;
                        SalesLine."Prepmt. Amt. Incl. VAT" :=
                          Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        SalesLine."Prepmt. VAT Base Amt." := NewVATBaseAmount;

                        if (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount") = 0 then
                            VATDifference := 0
                        else begin
                            if PrepmtAmtToInvTotal = 0 then
                                VATDifference :=
                                  VATAmountLine."VAT Difference" * (SalesLine."Prepmt. Line Amount" - SalesLine."Prepmt. Amt. Inv.") /
                                  (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount")
                            else
                                VATDifference :=
                                  VATAmountLine."VAT Difference" * (SalesLine."Prepmt. Line Amount" - SalesLine."Prepmt. Amt. Inv.") /
                                  PrepmtAmtToInvTotal;
                            NewPmtDiscAmount :=
                              TempVATAmountLineRemainder."Pmt. Discount Amount" +
                              NewAmount * SalesHeader."Payment Discount %" / 100;
                        end;

                        SalesLine."Prepayment VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                        SalesLine."Prepmt. Pmt. Discount Amount" := Round(NewPmtDiscAmount, Currency."Amount Rounding Precision");
                        OnUpdateVATOnLinesOnBeforeSalesLineModify(SalesHeader, SalesLine, TempVATAmountLineRemainder, NewAmount, NewAmountIncludingVAT, NewVATBaseAmount);
                        SalesLine.Modify();

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - SalesLine."Prepayment VAT Difference";
                        TempVATAmountLineRemainder."Pmt. Discount Amount" := NewPmtDiscAmount - Round(NewPmtDiscAmount);
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until SalesLine.Next() = 0;
        VATAmountLine.Reset();

        OnAfterUpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, DocumentType);
    end;

    procedure CalcVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        Currency: Record Currency;
        NewAmount: Decimal;
        NewPrepmtVATDiffAmt: Decimal;
        IsHandled: Boolean;
    begin
        GLSetup.GetRecordOnce();
        Currency.Initialize(SalesHeader."Currency Code");

        VATAmountLine.DeleteAll();

        ApplyFilter(SalesHeader, DocumentType, SalesLine);
        if SalesLine.Find('-') then
            repeat
                NewAmount := PrepmtAmount(SalesLine, DocumentType);
                if NewAmount <> 0 then begin
                    if DocumentType = DocumentType::Invoice then
                        NewAmount := SalesLine."Prepmt. Line Amount";
                    if SalesLine."Prepmt. VAT Calc. Type" in
                       [SalesLine."VAT Calculation Type"::"Reverse Charge VAT", SalesLine."VAT Calculation Type"::"Sales Tax"]
                    then
                        SalesLine."VAT %" := 0;

                    if not FindVATAmountLine(SalesLine, VATAmountLine, NewAmount) then
                        InsertVATAmountLine(SalesLine, VATAmountLine, NewAmount);

                    VATAmountLine."Line Amount" := VATAmountLine."Line Amount" + NewAmount;
                    NewPrepmtVATDiffAmt := PrepmtVATDiffAmount(SalesLine, DocumentType);
                    if DocumentType = DocumentType::Invoice then
                        NewPrepmtVATDiffAmt := SalesLine."Prepayment VAT Difference" + SalesLine."Prepmt VAT Diff. to Deduct" +
                          SalesLine."Prepmt VAT Diff. Deducted";
                    VATAmountLine."VAT Difference" := VATAmountLine."VAT Difference" + NewPrepmtVATDiffAmt;
                    VATAmountLine.Modify();
                end;
            until SalesLine.Next() = 0;
        VATAmountLine.Reset();

        IsHandled := false;
        OnCalcVATAmountLinesOnBeforeUpdateLines(NewAmount, Currency, SalesHeader, IsHandled);
        if not IsHandled then
            VATAmountLine.UpdateLines(
              NewAmount, Currency, SalesHeader."Currency Factor", SalesHeader."Prices Including VAT",
              SalesLine.GetVatBaseDiscountPct(SalesHeader), SalesHeader."Tax Area Code", SalesHeader."Tax Liable", SalesHeader."Posting Date");

        OnAfterCalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, DocumentType, Currency);
    end;

    local procedure FindVATAmountLine(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line" temporary; LineAmount: Decimal): Boolean
    begin
        VATAmountLine.Reset();
        VATAmountLine.SetRange("VAT Identifier", SalesLine."Prepayment VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", SalesLine."Prepmt. VAT Calc. Type");
        VATAmountLine.SetRange("Tax Group Code", SalesLine."Prepayment Tax Group Code");
        VATAmountLine.SetRange("Use Tax", false);
        VATAmountLine.SetRange(Positive, LineAmount >= 0);
        OnFindVATAmountLineOnAfterSetFilters(SalesLine, VATAmountLine);
        exit(VATAmountLine.FindFirst());
    end;

    local procedure InsertVATAmountLine(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; LineAmount: Decimal)
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT Identifier" := SalesLine."Prepayment VAT Identifier";
        VATAmountLine."VAT Calculation Type" := SalesLine."Prepmt. VAT Calc. Type";
        VATAmountLine."Tax Group Code" := SalesLine."Prepayment Tax Group Code";
        VATAmountLine."VAT %" := SalesLine."Prepayment VAT %";
        VATAmountLine.Positive := LineAmount >= 0;
        VATAmountLine.Modified := true;
        VATAmountLine."Includes Prepayment" := true;
        OnInsertVATAmountOnBeforeInsert(SalesLine, VATAmountLine);
        VATAmountLine.Insert();
    end;

    procedure SumPrepmt(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalAmount: Decimal; var TotalVATAmount: Decimal; var VATAmountText: Text[30])
    var
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer";
        DifVATPct: Boolean;
        PrevVATPct: Decimal;
    begin
        CalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, 2);
        UpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, 2);
        BuildInvLineBuffer(SalesHeader, SalesLine, 2, TempPrepmtInvLineBuf, false);
        if TempPrepmtInvLineBuf.Find('-') then begin
            PrevVATPct := TempPrepmtInvLineBuf.GetVATPct();
            repeat
                RoundAmounts(SalesHeader, TempPrepmtInvLineBuf, TotalPrepmtInvLineBuf, TotalPrepmtInvLineBufLCY);
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

    procedure GetSalesLines(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToSalesLine: Record "Sales Line")
    var
        FromSalesLine: Record "Sales Line";
        InvRoundingSalesLine: Record "Sales Line";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalAmt: Decimal;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLines(SalesHeader, DocumentType, ToSalesLine, IsHandled);
        if IsHandled then
            exit;

        ApplyFilter(SalesHeader, DocumentType, FromSalesLine);
        if FromSalesLine.Find('-') then begin
            repeat
                ToSalesLine := FromSalesLine;
                ToSalesLine.Insert();
            until FromSalesLine.Next() = 0;

            SalesSetup.Get();
            if SalesSetup."Invoice Rounding" then begin
                CalcVATAmountLines(SalesHeader, ToSalesLine, TempVATAmountLine, 2);
                UpdateVATOnLines(SalesHeader, ToSalesLine, TempVATAmountLine, 2);
                ToSalesLine.CalcSums("Prepmt. Amt. Incl. VAT");
                TotalAmt := ToSalesLine."Prepmt. Amt. Incl. VAT";
                ToSalesLine.FindLast();
                if InitInvoiceRoundingLine(SalesHeader, TotalAmt, InvRoundingSalesLine) then begin
                    NextLineNo := ToSalesLine."Line No." + 1;
                    ToSalesLine := InvRoundingSalesLine;
                    ToSalesLine."Line No." := NextLineNo;

                    if DocumentType <> DocumentType::"Credit Memo" then
                        ToSalesLine."Prepmt. Line Amount" := ToSalesLine."Line Amount"
                    else
                        ToSalesLine."Prepmt. Amt. Inv." := ToSalesLine."Line Amount";
                    ToSalesLine."Prepmt. VAT Calc. Type" := ToSalesLine."VAT Calculation Type";
                    ToSalesLine."Prepayment VAT Identifier" := ToSalesLine."VAT Identifier";
                    ToSalesLine."Prepayment Tax Group Code" := ToSalesLine."Tax Group Code";
                    ToSalesLine."Prepayment VAT Identifier" := ToSalesLine."VAT Identifier";
                    ToSalesLine."Prepayment Tax Group Code" := ToSalesLine."Tax Group Code";
                    ToSalesLine."Prepayment VAT %" := ToSalesLine."VAT %";
                    OnGetSalesLinesOnBeforeInsertToSalesLine(ToSalesLine);
                    ToSalesLine.Insert();
                end;
            end;
        end;
    end;

    procedure ApplyFilter(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        if DocumentType in [DocumentType::Invoice, DocumentType::Statistic] then
            SalesLine.SetFilter("Prepmt. Line Amount", '<>0')
        else
            SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>0');

        OnAfterApplyFilter(SalesLine, SalesHeader, DocumentType);
    end;

    procedure PrepmtAmount(SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrepmtAmount(SalesLine, DocumentType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case DocumentType of
            DocumentType::Statistic:
                exit(SalesLine."Prepmt. Line Amount");
            DocumentType::Invoice:
                exit(SalesLine."Prepmt. Line Amount" - SalesLine."Prepmt. Amt. Inv.");
            else
                exit(SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt Amt Deducted");
        end;
    end;

    local procedure PostPrepmtInvLineBuffer(SalesHeader: Record "Sales Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", PostingDescription,
            PrepmtInvLineBuffer."Global Dimension 1 Code", PrepmtInvLineBuffer."Global Dimension 2 Code",
            PrepmtInvLineBuffer."Dimension Set ID", SalesHeader."Reason Code");

        GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);
        GenJnlLine.CopyFromSalesHeaderPrepmt(SalesHeader);
        GenJnlLine.CopyFromPrepmtInvoiceBuffer(PrepmtInvLineBuffer);

        if not PrepmtInvLineBuffer.Adjustment then
            GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
        GenJnlLine.Correction :=
          (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := GenJournalTemplate.Name;

        OnBeforePostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit);
        RunGenJnlPostLine(GenJnlLine);
        OnAfterPostPrepmtInvLineBuffer(GenJnlLine, PrepmtInvLineBuffer, SuppressCommit, GenJnlPostLine);
    end;

    local procedure PostCustomerEntry(SalesHeader: Record "Sales Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostCustomerEntryProcedure(SalesHeader, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, DocumentType, PostingDescription, DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode, CalcPmtDisc, GenJnlPostLine, IsHandled);
        if not IsHandled then begin
            GenJnlLine.InitNewLine(
                SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", PostingDescription,
                SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
                SalesHeader."Dimension Set ID", SalesHeader."Reason Code");
            GenJnlLine.Validate("Your Reference", SalesHeader."Your Reference");

            GenJnlLine.CopyDocumentFields(DocType, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

            GenJnlLine.CopyFromSalesHeaderPrepmtPost(SalesHeader, (DocumentType = DocumentType::Invoice) or CalcPmtDisc);

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

            OnBeforePostCustomerEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit, SalesHeader, DocumentType);
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        end;

        OnAfterPostCustomerEntry(GenJnlLine, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit);
    end;

    local procedure PostBalancingEntry(SalesHeader: Record "Sales Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CustLedgEntry: Record "Cust. Ledger Entry"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.InitNewLine(
            SalesHeader."Posting Date", SalesHeader."Document Date", SalesHeader."VAT Reporting Date", PostingDescription,
            SalesHeader."Shortcut Dimension 1 Code", SalesHeader."Shortcut Dimension 2 Code",
            SalesHeader."Dimension Set ID", SalesHeader."Reason Code");

        if DocType = GenJnlLine."Document Type"::"Credit Memo" then
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Refund, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode)
        else
            GenJnlLine.CopyDocumentFields(GenJnlLine."Document Type"::Payment, DocNo, ExtDocNo, SrcCode, PostingNoSeriesCode);

        GenJnlLine.CopyFromSalesHeaderPrepmtPost(SalesHeader, false);
        if SalesHeader."Bal. Account Type" = SalesHeader."Bal. Account Type"::"Bank Account" then
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := SalesHeader."Bal. Account No.";

        GenJnlLine.Amount := TotalPrepmtInvLineBuffer."Amount Incl. VAT" + CustLedgEntry."Remaining Pmt. Disc. Possible";
        GenJnlLine."Source Currency Amount" := GenJnlLine.Amount;
        if CustLedgEntry.Amount = 0 then
            GenJnlLine."Amount (LCY)" := TotalPrepmtInvLineBufferLCY."Amount Incl. VAT"
        else
            GenJnlLine."Amount (LCY)" :=
              TotalPrepmtInvLineBufferLCY."Amount Incl. VAT" +
              Round(
                CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor");

        GenJnlLine.Correction := (DocumentType = DocumentType::"Credit Memo") and GLSetup."Mark Cr. Memos as Corrections";

        GenJnlLine."Applies-to Doc. Type" := DocType;
        GenJnlLine."Applies-to Doc. No." := DocNo;

        GenJnlLine."Orig. Pmt. Disc. Possible" := TotalPrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        GenJnlLine."Orig. Pmt. Disc. Possible(LCY)" := TotalPrepmtInvLineBufferLCY."Orig. Pmt. Disc. Possible";
        if GLSetup."Journal Templ. Name Mandatory" then
            GenJnlLine."Journal Template Name" := GenJournalTemplate.Name;
        OnPostBalancingEntryOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, CustLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit, SalesHeader, DocType);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        OnAfterPostBalancingEntry(GenJnlLine, CustLedgEntry, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferLCY, SuppressCommit, SalesHeader);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        OnBeforeRunGenJnlPostLine(GenJnlLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure UpdatePrepmtAmountOnSaleslines(SalesHeader: Record "Sales Header"; NewTotalPrepmtAmount: Decimal)
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
        TotalLineAmount: Decimal;
        TotalPrepmtAmount: Decimal;
        TotalPrepmtAmtInv: Decimal;
        LastLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtAmountOnSaleslines(SalesHeader, NewTotalPrepmtAmount, IsHandled);
        if IsHandled then
            exit;

        Currency.Initialize(SalesHeader."Currency Code");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("Line Amount", '<>0');
        SalesLine.SetFilter("Prepayment %", '<>0');
        SalesLine.LockTable();
        if SalesLine.Find('-') then
            repeat
                TotalLineAmount := TotalLineAmount + SalesLine."Line Amount";
                TotalPrepmtAmtInv := TotalPrepmtAmtInv + SalesLine."Prepmt. Amt. Inv.";
                LastLineNo := SalesLine."Line No.";
            until SalesLine.Next() = 0
        else
            Error(Text017, SalesLine.FieldCaption("Prepayment %"));
        if TotalLineAmount = 0 then
            Error(Text013, NewTotalPrepmtAmount);
        if not (NewTotalPrepmtAmount in [TotalPrepmtAmtInv .. TotalLineAmount]) then
            Error(Text016, TotalPrepmtAmtInv, TotalLineAmount);

        TotalPrepmtAmount := 0;
        if SalesLine.Find('-') then
            repeat
                if SalesLine."Line No." <> LastLineNo then
                    SalesLine.Validate(
                      SalesLine."Prepmt. Line Amount",
                      Round(
                        NewTotalPrepmtAmount * SalesLine."Line Amount" / TotalLineAmount,
                        Currency."Amount Rounding Precision"))
                else
                    SalesLine.Validate("Prepmt. Line Amount", NewTotalPrepmtAmount - TotalPrepmtAmount);
                TotalPrepmtAmount := TotalPrepmtAmount + SalesLine."Prepmt. Line Amount";
                SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    local procedure CreateDimensions(var SalesLine: Record "Sales Line")
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodeSetup.Get();
        DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", SalesLine."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, SalesLine."Job No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", SalesLine."Responsibility Center");
        SalesLine."Shortcut Dimension 1 Code" := '';
        SalesLine."Shortcut Dimension 2 Code" := '';
        SalesLine."Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            SalesLine, 0, DefaultDimSource, SourceCodeSetup.Sales,
            SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code", SalesLine."Dimension Set ID", Database::Customer);

        OnAfterCreateDimensions(SalesLine, DefaultDimSource);
    end;

    procedure PrepmtDocTypeToDocType(DocumentType: Option Invoice,"Credit Memo"): Integer
    begin
        case DocumentType of
            DocumentType::Invoice:
                exit(2);
            DocumentType::"Credit Memo":
                exit(3);
        end;
        exit(2);
    end;

    procedure GetSalesLinesToDeduct(SalesHeader: Record "Sales Header"; var SalesLines: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
    begin
        ApplyFilter(SalesHeader, 1, SalesLine);
        if SalesLine.FindSet() then
            repeat
                if (PrepmtAmount(SalesLine, 0) <> 0) and (PrepmtAmount(SalesLine, 1) <> 0) then begin
                    SalesLines := SalesLine;
                    SalesLines.Insert();
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure PrepmtVATDiffAmount(SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        case DocumentType of
            DocumentType::Statistic:
                exit(SalesLine."Prepayment VAT Difference");
            DocumentType::Invoice:
                exit(SalesLine."Prepayment VAT Difference");
            else
                exit(SalesLine."Prepmt VAT Diff. to Deduct");
        end;
    end;

    local procedure UpdateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo"; GenJnlLineDocNo: Code[20])
    begin
        OnBeforeUpdateSalesDocument(SalesHeader, SalesLine, DocumentType, GenJnlLineDocNo);

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if DocumentType = DocumentType::Invoice then begin
            SalesHeader."Last Prepayment No." := GenJnlLineDocNo;
            SalesHeader."Prepayment No." := '';
            SalesLine.SetFilter("Prepmt. Line Amount", '<>0');
            if SalesLine.FindSet(true) then
                repeat
                    if SalesLine."Prepmt. Line Amount" <> SalesLine."Prepmt. Amt. Inv." then begin
                        SalesLine."Prepmt. Amt. Inv." := SalesLine."Prepmt. Line Amount";
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Incl. VAT";
                        SalesLine.CalcPrepaymentToDeduct();
                        SalesLine."Prepmt VAT Diff. to Deduct" :=
                          SalesLine."Prepmt VAT Diff. to Deduct" + SalesLine."Prepayment VAT Difference";
                        SalesLine."Prepayment VAT Difference" := 0;
                        OnUpdateSalesDocumentOnBeforeModifyInvoiceSalesLine(SalesLine);
                        SalesLine.Modify();
                    end;
                until SalesLine.Next() = 0;
        end else begin
            SalesHeader."Last Prepmt. Cr. Memo No." := GenJnlLineDocNo;
            SalesHeader."Prepmt. Cr. Memo No." := '';
            SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if SalesLine.FindSet(true) then
                repeat
                    SalesLine."Prepmt. Amt. Inv." := SalesLine."Prepmt Amt Deducted";
                    if SalesHeader."Prices Including VAT" then
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" := SalesLine."Prepmt. Amt. Inv."
                    else
                        SalesLine."Prepmt. Amount Inv. Incl. VAT" :=
                          Round(
                            SalesLine."Prepmt. Amt. Inv." * (100 + SalesLine."Prepayment VAT %") / 100,
                            GetCurrencyAmountRoundingPrecision(SalesLine."Currency Code"));
                    SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Amount Inv. Incl. VAT";
                    SalesLine."Prepayment Amount" := SalesLine."Prepmt. Amt. Inv.";
                    SalesLine."Prepmt Amt to Deduct" := 0;
                    SalesLine."Prepmt VAT Diff. to Deduct" := 0;
                    SalesLine."Prepayment VAT Difference" := 0;
                    OnUpdateSalesDocumentOnBeforeModifyCreditMemoSalesLine(SalesLine);
                    SalesLine.Modify();
                until SalesLine.Next() = 0;
        end;
    end;

    local procedure UpdatePostedSalesDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePostedSalesDocument(CustLedgerEntry, SalesInvoiceHeader, SalesCrMemoHeader, DocumentType, IsHandled, DocumentNo);
        if IsHandled then
            exit;

        case DocumentType of
            DocumentType::Invoice:
                begin
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst();
                    SalesInvoiceHeader.Get(DocumentNo);
                    SalesInvoiceHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    SalesInvoiceHeader.Modify();
                end;
            DocumentType::"Credit Memo":
                begin
                    CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst();
                    SalesCrMemoHeader.Get(DocumentNo);
                    SalesCrMemoHeader."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
                    SalesCrMemoHeader.Modify();
                end;
        end;

        OnAfterUpdatePostedSalesDocument(DocumentType, DocumentNo, SuppressCommit);
    end;

    local procedure InsertSalesInvHeader(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20])
    begin
        SalesInvHeader.Init();
        SalesInvHeader.TransferFields(SalesHeader);
        SalesInvHeader."Posting Description" := PostingDescription;
        SalesInvHeader."Payment Terms Code" := SalesHeader."Prepmt. Payment Terms Code";
        SalesInvHeader."Due Date" := SalesHeader."Prepayment Due Date";
        SalesInvHeader."Pmt. Discount Date" := SalesHeader."Prepmt. Pmt. Discount Date";
        SalesInvHeader."Payment Discount %" := SalesHeader."Prepmt. Payment Discount %";
        SalesInvHeader."No." := GenJnlLineDocNo;
        SalesInvHeader."Pre-Assigned No. Series" := '';
        SalesInvHeader."Source Code" := SrcCode;
        SalesInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesInvHeader."User ID"));
        SalesInvHeader."No. Printed" := 0;
        SalesInvHeader."Prepayment Invoice" := true;
        SalesInvHeader."Prepayment Order No." := SalesHeader."No.";
        SalesInvHeader."No. Series" := PostingNoSeriesCode;
        OnBeforeSalesInvHeaderInsert(SalesInvHeader, SalesHeader, SuppressCommit, GenJnlLineDocNo);
        SalesInvHeader.Insert();
        CopyHeaderCommentLines(SalesHeader."No.", Database::"Sales Invoice Header", GenJnlLineDocNo);
        OnAfterSalesInvHeaderInsert(SalesInvHeader, SalesHeader, SuppressCommit);
    end;

    local procedure InsertSalesInvLine(SalesInvHeader: Record "Sales Invoice Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header")
    var
        SalesInvLine: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        SalesInvLine.Init();
        SalesInvLine."Document No." := SalesInvHeader."No.";
        SalesInvLine."Line No." := LineNo;
        SalesInvLine."Sell-to Customer No." := SalesInvHeader."Sell-to Customer No.";
        SalesInvLine."Bill-to Customer No." := SalesInvHeader."Bill-to Customer No.";
        SalesInvLine.Type := SalesInvLine.Type::"G/L Account";
        SalesInvLine."No." := PrepmtInvLineBuffer."G/L Account No.";
        SalesInvLine."Posting Date" := SalesInvHeader."Posting Date";
        SalesInvLine."Shortcut Dimension 1 Code" := PrepmtInvLineBuffer."Global Dimension 1 Code";
        SalesInvLine."Shortcut Dimension 2 Code" := PrepmtInvLineBuffer."Global Dimension 2 Code";
        SalesInvLine."Dimension Set ID" := PrepmtInvLineBuffer."Dimension Set ID";
        SalesInvLine.Description := PrepmtInvLineBuffer.Description;
        if not SalesHeader."Compress Prepayment" then
            if SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", PrepmtInvLineBuffer."Line No.") then
                SalesInvLine."Description 2" := SalesLine."Description 2";

        if SalesHeader."Compress Prepayment" then
            if SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", LineNo) then
                SalesInvLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";

        SalesInvLine.Quantity := 1;
        if SalesInvHeader."Prices Including VAT" then begin
            SalesInvLine."Unit Price" := PrepmtInvLineBuffer."Amount Incl. VAT";
            SalesInvLine."Line Amount" := PrepmtInvLineBuffer."Amount Incl. VAT";
        end else begin
            SalesInvLine."Unit Price" := PrepmtInvLineBuffer.Amount;
            SalesInvLine."Line Amount" := PrepmtInvLineBuffer.Amount;
        end;
        SalesInvLine."Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        SalesInvLine."Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        SalesInvLine."VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        SalesInvLine."VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        SalesInvLine."VAT %" := PrepmtInvLineBuffer."VAT %";
        if VATPostingSetup.GET(PrepmtInvLineBuffer."VAT Bus. Posting Group", PrepmtInvLineBuffer."VAT Prod. Posting Group") then
            SalesInvLine."VAT Clause Code" := VATPostingSetup."VAT Clause Code";
        SalesInvLine.Amount := PrepmtInvLineBuffer.Amount;
        SalesInvLine."VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        SalesInvLine."Amount Including VAT" := PrepmtInvLineBuffer."Amount Incl. VAT";
        SalesInvLine."VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        SalesInvLine."VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        SalesInvLine."VAT Identifier" := PrepmtInvLineBuffer."VAT Identifier";
        SalesInvLine."Pmt. Discount Amount" := PrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        OnBeforeSalesInvLineInsert(SalesInvLine, SalesInvHeader, PrepmtInvLineBuffer, SuppressCommit);
        SalesInvLine.Insert();
        if not SalesHeader."Compress Prepayment" then
            CopyLineCommentLines(
              SalesHeader."No.", Database::"Sales Invoice Header", SalesInvHeader."No.", PrepmtInvLineBuffer."Line No.", LineNo);
        OnAfterSalesInvLineInsert(SalesInvLine, SalesInvHeader, PrepmtInvLineBuffer, SuppressCommit);
    end;

    local procedure InsertSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; PostingDescription: Text[100]; GenJnlLineDocNo: Code[20]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader.TransferFields(SalesHeader);
        SalesCrMemoHeader."Payment Terms Code" := SalesHeader."Prepmt. Payment Terms Code";
        SalesCrMemoHeader."Pmt. Discount Date" := SalesHeader."Prepmt. Pmt. Discount Date";
        SalesCrMemoHeader."Payment Discount %" := SalesHeader."Prepmt. Payment Discount %";
        if (SalesHeader."Prepmt. Payment Terms Code" <> '') and not CalcPmtDiscOnCrMemos then begin
            SalesCrMemoHeader."Payment Discount %" := 0;
            SalesCrMemoHeader."Pmt. Discount Date" := 0D;
        end;
        SalesCrMemoHeader."Posting Description" := PostingDescription;
        SalesCrMemoHeader."Due Date" := SalesHeader."Prepayment Due Date";
        SalesCrMemoHeader."No." := GenJnlLineDocNo;
        SalesCrMemoHeader."Pre-Assigned No. Series" := '';
        SalesCrMemoHeader."Source Code" := SrcCode;
        SalesCrMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(SalesCrMemoHeader."User ID"));
        SalesCrMemoHeader."No. Printed" := 0;
        SalesCrMemoHeader."Prepayment Credit Memo" := true;
        SalesCrMemoHeader."Prepayment Order No." := SalesHeader."No.";
        SalesCrMemoHeader.Correction := GLSetup."Mark Cr. Memos as Corrections";
        SalesCrMemoHeader."No. Series" := PostingNoSeriesCode;
        OnBeforeSalesCrMemoHeaderInsert(SalesCrMemoHeader, SalesHeader, SuppressCommit);
        SalesCrMemoHeader.Insert();
        CopyHeaderCommentLines(SalesHeader."No.", Database::"Sales Cr.Memo Header", GenJnlLineDocNo);
        OnAfterSalesCrMemoHeaderInsert(SalesCrMemoHeader, SalesHeader, SuppressCommit);
    end;

    local procedure InsertSalesCrMemoLine(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; LineNo: Integer; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesCrMemoLine.Init();
        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine."Line No." := LineNo;
        SalesCrMemoLine."Sell-to Customer No." := SalesCrMemoHeader."Sell-to Customer No.";
        SalesCrMemoLine."Bill-to Customer No." := SalesCrMemoHeader."Bill-to Customer No.";
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::"G/L Account";
        SalesCrMemoLine."No." := PrepmtInvLineBuffer."G/L Account No.";
        SalesCrMemoLine."Posting Date" := SalesCrMemoHeader."Posting Date";
        SalesCrMemoLine."Shortcut Dimension 1 Code" := PrepmtInvLineBuffer."Global Dimension 1 Code";
        SalesCrMemoLine."Shortcut Dimension 2 Code" := PrepmtInvLineBuffer."Global Dimension 2 Code";
        SalesCrMemoLine."Dimension Set ID" := PrepmtInvLineBuffer."Dimension Set ID";
        SalesCrMemoLine.Description := PrepmtInvLineBuffer.Description;
        SalesCrMemoLine.Quantity := 1;
        if SalesCrMemoHeader."Prices Including VAT" then begin
            SalesCrMemoLine."Unit Price" := PrepmtInvLineBuffer."Amount Incl. VAT";
            SalesCrMemoLine."Line Amount" := PrepmtInvLineBuffer."Amount Incl. VAT";
        end else begin
            SalesCrMemoLine."Unit Price" := PrepmtInvLineBuffer.Amount;
            SalesCrMemoLine."Line Amount" := PrepmtInvLineBuffer.Amount;
        end;
        SalesCrMemoLine."Gen. Bus. Posting Group" := PrepmtInvLineBuffer."Gen. Bus. Posting Group";
        SalesCrMemoLine."Gen. Prod. Posting Group" := PrepmtInvLineBuffer."Gen. Prod. Posting Group";
        SalesCrMemoLine."VAT Bus. Posting Group" := PrepmtInvLineBuffer."VAT Bus. Posting Group";
        SalesCrMemoLine."VAT Prod. Posting Group" := PrepmtInvLineBuffer."VAT Prod. Posting Group";
        SalesCrMemoLine."VAT %" := PrepmtInvLineBuffer."VAT %";
        if VATPostingSetup.GET(PrepmtInvLineBuffer."VAT Bus. Posting Group", PrepmtInvLineBuffer."VAT Prod. Posting Group") then
            SalesCrMemoLine."VAT Clause Code" := VATPostingSetup."VAT Clause Code";
        SalesCrMemoLine.Amount := PrepmtInvLineBuffer.Amount;
        SalesCrMemoLine."VAT Difference" := PrepmtInvLineBuffer."VAT Difference";
        SalesCrMemoLine."Amount Including VAT" := PrepmtInvLineBuffer."Amount Incl. VAT";
        SalesCrMemoLine."VAT Calculation Type" := PrepmtInvLineBuffer."VAT Calculation Type";
        SalesCrMemoLine."VAT Base Amount" := PrepmtInvLineBuffer."VAT Base Amount";
        SalesCrMemoLine."VAT Identifier" := PrepmtInvLineBuffer."VAT Identifier";
        SalesCrMemoLine."Pmt. Discount Amount" := PrepmtInvLineBuffer."Orig. Pmt. Disc. Possible";
        OnBeforeSalesCrMemoLineInsert(SalesCrMemoLine, SalesCrMemoHeader, PrepmtInvLineBuffer, SuppressCommit);
        SalesCrMemoLine.Insert();
        if not SalesHeader."Compress Prepayment" then
            CopyLineCommentLines(
              SalesHeader."No.", Database::"Sales Cr.Memo Header", SalesCrMemoHeader."No.", PrepmtInvLineBuffer."Line No.", LineNo);
        OnAfterSalesCrMemoLineInsert(SalesCrMemoLine, SalesCrMemoHeader, PrepmtInvLineBuffer, SuppressCommit);
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

    local procedure CheckSalesLineIsNegative(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLineIsNegative(SalesLine, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.Quantity < 0 then
            SalesLine.FieldError(Quantity, StrSubstNo(Text018, SalesHeader.FieldCaption("Prepayment %")));
        if SalesLine."Unit Price" < 0 then
            SalesLine.FieldError("Unit Price", StrSubstNo(Text018, SalesHeader.FieldCaption("Prepayment %")));
    end;

    local procedure CheckSystemCreatedInvoiceRoundEntry(SalesLine: Record "Sales Line"; CustomerPostingGroupCode: Code[20]): Boolean
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if (SalesLine.Type <> SalesLine.Type::"G/L Account") or (not SalesLine."System-Created Entry") then
            exit(false);

        if CustomerPostingGroupCode = '' then
            exit(false);

        CustomerPostingGroup.SetLoadFields("Invoice Rounding Account");
        if not CustomerPostingGroup.Get(CustomerPostingGroupCode) then
            exit(false);

        if CustomerPostingGroup."Invoice Rounding Account" = '' then
            exit(false);

        if SalesLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyFilter(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildInvLineBuffer(var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimensions(var SalesLine: Record "Sales Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLinesOnBeforeGLPosting(var SalesHeader: Record "Sales Header"; SalesInvHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceRounding(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var PrevLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepayments(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostedSalesDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOpenPrepaymentLines(SalesHeader: Record "Sales Header"; DocumentType: Option; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLinesFromBuffer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; var LineCount: Integer; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var PostedDocTabNo: Integer; DocumentType: Option; var LastLineNo: Integer; GenJnlLineDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInvoice(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreditMemo(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvLineBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepayments(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; GenJnlDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesAssertPrepmtAmountNotMoreThanDocAmount(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; GenJnlLineDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocNos(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean; IsPreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePostedSalesDocument(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean; DocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeUpdateLines(var NewAmount: Decimal; Currency: Record Currency; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterBuildInvLineBuffer(var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCalcAndUpdateVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostCustomerEntry(var SalesHeader: Record "Sales Header"; var TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostBalancingEntry(var SalesHeader: Record "Sales Header"; var TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWindowOpen(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldSetPendingPrepaymentStatus(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocumentType: Option Invoice,"Credit Memo"; PreviewMode: Boolean; var ShouldSetPendingPrepaymentStatus: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertExtendedTextOnBeforeSalesInvLineInsert(var SalesInvoiceLine: Record "Sales Invoice Line"; TabNo: Integer; DocNo: Code[20]; NextLineNo: Integer; var TempExtendedTextLine: Record "Extended Text Line" temporary; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertExtendedTextOnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; TabNo: Integer; DocNo: Code[20]; NextLineNo: Integer; var TempExtendedTextLine: Record "Extended Text Line" temporary; SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header"; DocType: enum "Gen. Journal Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountsOnBeforeIncrAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesDocumentOnBeforeModifyCreditMemoSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesDocumentOnBeforeModifyInvoiceSalesLine(var SalesLine: Record "Sales Line")
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
    local procedure OnUpdateVATOnLinesOnBeforeSalesLineModify(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowPreviewError(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLineIsNegative(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLines(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmountOnSaleslines(SalesHeader: Record "Sales Header"; NewTotalPrepmtAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesLinesOnBeforeInsertToSalesLine(var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeInsertPostedHeaders(var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDocNos(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBuildInvLineBufferOnBeforeFillInvLineBuffer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostingDescriptionSet(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var PostingDescription: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntryProcedure(var SalesHeader: Record "Sales Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepmtAmount(var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var Result: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVATAmountLineOnAfterSetFilters(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckPrepmtDoc(var SalesHeader: Record "Sales Header"; var DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepmtAccNo(GenPostingSetup: Record "General Posting Setup"; var PrepmtAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCorrBalAccNo(SalesHeader: Record "Sales Header"; PositiveAmount: Boolean; var BalAccNo: Code[20])
    begin
    end;
}
