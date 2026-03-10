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
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
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
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Posts prepayment invoices and credit memos for sales orders, creating the corresponding ledger entries and posted documents.
/// </summary>
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
        TempGlobalPrepmtInvLineBufGST: Record "Prepayment Inv. Line Buffer" temporary;
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
        Text020: Label 'must be %1, the same as in the field %2';
#pragma warning restore AA0074
        PrepaymentSalesTok: Label 'Prepayment Sales', Locked = true;
        UpdateTok: Label '%1 %2', Locked = true;

    /// <summary>
    /// Sets the prepayment document type to be posted.
    /// </summary>
    /// <param name="DocumentType">Specifies the prepayment document type (Invoice or Credit Memo).</param>
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

    /// <summary>
    /// Posts a prepayment invoice for the sales order.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order for which to post the prepayment invoice.</param>
    procedure Invoice(var SalesHeader: Record "Sales Header")
    var
        Handled: Boolean;
    begin
        OnBeforeInvoice(SalesHeader, Handled);
        if not Handled then
            Code(SalesHeader, 0);
    end;

    /// <summary>
    /// Posts a prepayment credit memo for the sales order.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order for which to post the prepayment credit memo.</param>
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
        TempOriginalSalesLine: Record "Sales Line" temporary;
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
        TempGlobalPrepmtInvLineBufGST.DeleteAll();

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
        OnCodeOnAfterSetSourceCode(SalesHeader, SourceCodeSetup, SrcCode);
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
            SavePrepmtAmounts(SalesHeader, SalesLine, DocumentType, TempOriginalSalesLine);
            UpdateVATOnLines(SalesHeader, SalesLine, TempVATAmountLine, DocumentType);
            BuildInvLineBuffer(SalesHeader, SalesLine, DocumentType, TempPrepmtInvLineBuffer, true);
            if GLSetup."GST Report" then
                BuildInvLineBufferGST(SalesHeader, SalesLine, DocumentType, TempGlobalPrepmtInvLineBufGST, SalesSetup."Invoice Rounding");
            RestorePrepmtAmounts(TempOriginalSalesLine, SalesLine, DocumentType);
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
        if not TempGlobalPrepmtInvLineBufGST.IsEmpty() then
            if GLSetup."GST Report" and (not SalesHeader."Compress Prepayment") then
                TempGlobalPrepmtInvLineBufGST.CompressBuffer();
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


        if (TotalPrepmtInvLineBuffer."VAT Amount" <> 0) and (SalesLine."VAT %" = 0) then
            SalesAssertPrepmtAmountNotMoreThanDocAmountBeforePost(TotalPrepmtInvLineBuffer, SalesHeader);

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

    local procedure SalesAssertPrepmtAmountNotMoreThanDocAmountBeforePost(TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header")
    var
        FromSalesLine: Record "Sales Line";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        PrepmtAmountInclVAT: Decimal;
        SalesPrepmtAmount: Decimal;
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;
        FromSalesLine.SetLoadFields("Document Type", "Document No.", "Type", "Prepayment %", "Amount Including VAT");
        FromSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        FromSalesLine.SetRange("Document No.", SalesHeader."No.");
        FromSalesLine.SetFilter(Type, '<>%1', FromSalesLine.Type::" ");
        FromSalesLine.SetFilter("Line Amount", '<>0');
        FromSalesLine.SetFilter("Prepayment %", '<>0');
        if FromSalesLine.FindSet() then
            repeat
                SalesPrepmtAmount += FromSalesLine."Amount Including VAT" * FromSalesLine."Prepayment %" / 100;
            until FromSalesLine.Next() = 0;
        PrepmtAmountInclVAT := -TotalPrepmtInvLineBuffer."Amount Incl. VAT";
        PrepaymentMgt.AssertPrepmtAmountNotMoreThanDocAmount(
             SalesPrepmtAmount, PrepmtAmountInclVAT, SalesHeader."Currency Code", SalesSetup."Invoice Rounding");
    end;

   /// <summary>
    /// Validates the sales order and prepayment settings before posting a prepayment document.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order to validate.</param>
    /// <param name="DocumentType">Specifies the prepayment document type (Invoice or Credit Memo) to validate for.</param>
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

    /// <summary>
    /// Checks if there are open prepayment lines available for posting.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order to check.</param>
    /// <param name="DocumentType">Specifies the prepayment document type to check for.</param>
    /// <returns>Returns true if open prepayment lines are found.</returns>
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
                    Found := PrepmtAmountCheck(SalesLine, DocumentType) <> 0;
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
                if IsFullGST(PrepmtInvLineBuf) then
                    PrepmtInvLineBuf."VAT Base Amount" :=
                      AmountToLCY(SalesHeader, TotalPrepmtInvLineBuf."VAT Base Amount", TotalPrepmtInvLineBufLCY."VAT Base Amount")
                else
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
        HasInvoiceDiscount: Boolean;
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

                    if SalesLine."Inv. Discount Amount" <> 0 then
                        HasInvoiceDiscount := true;

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
        UpdateDifferenceAmount(SalesHeader, TotalPrepmtInvLineBuffer, TempPrepmtInvLineBuf, HasInvoiceDiscount);
        
        if SalesSetup."Invoice Rounding" then
            if InsertInvoiceRounding(
                 SalesHeader, PrepmtInvLineBuf2, TotalPrepmtInvLineBuffer, SalesLine."Line No.")
            then
                TempPrepmtInvLineBuf.InsertInvLineBuffer(PrepmtInvLineBuf2);
        ErrorMessageMgt.FinishTopContext();

        OnAfterBuildInvLineBuffer(TempPrepmtInvLineBuf);
    end;

    /// <summary>
    /// Builds the prepayment invoice line buffer from the sales lines for posting.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="SalesLine">Specifies the sales lines to process.</param>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
    /// <param name="PrepmtInvLineBuf">Returns the prepayment invoice line buffer records.</param>
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

    /// <summary>
    /// Gets the correction balancing account number for prepayment adjustments.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="PositiveAmount">Specifies whether the adjustment amount is positive.</param>
    /// <returns>Returns the G/L account number for balancing the correction.</returns>
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

    /// <summary>
    /// Gets the invoice rounding account number from the customer posting group.
    /// </summary>
    /// <param name="CustomerPostingGroup">Specifies the customer posting group code.</param>
    /// <returns>Returns the invoice rounding G/L account number.</returns>
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

    /// <summary>
    /// Fills the prepayment invoice line buffer with data from a sales line.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="SalesLine">Specifies the sales line to copy data from.</param>
    /// <param name="PrepmtInvLineBuf">Returns the filled prepayment invoice line buffer record.</param>
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

        PrepmtInvLineBuf.Amount := SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Amount" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
        if IsFullGST(SalesLine) then begin
            if (PrepmtInvLineBuf."VAT Amount" = 0) and (SalesLine."VAT %" <> 0) then begin
                PrepmtInvLineBuf."VAT Base Amount" := 0;
                PrepmtInvLineBuf."VAT Base Amount (ACY)" := 0;
            end else begin
                PrepmtInvLineBuf."VAT Base Amount" := SalesLine."Prepmt. VAT Base Amt.";
                PrepmtInvLineBuf."VAT Base Amount (ACY)" := SalesLine."Prepmt. VAT Base Amt.";
            end;
            PrepmtInvLineBuf."Amount Incl. VAT" := PrepmtInvLineBuf.Amount + PrepmtInvLineBuf."VAT Amount";
            PrepmtInvLineBuf."Prepayment %" := SalesLine."Prepayment %";
        end else begin
            PrepmtInvLineBuf."VAT Base Amount" := SalesLine."Prepayment Amount";
            PrepmtInvLineBuf."VAT Base Amount (ACY)" := SalesLine."Prepayment Amount";
            PrepmtInvLineBuf."Amount Incl. VAT" := SalesLine."Prepmt. Amt. Incl. VAT";
        end;
        PrepmtInvLineBuf."Amount (ACY)" := SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Amount (ACY)" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Base Before Pmt. Disc." := -SalesLine."Prepayment Amount";
        PrepmtInvLineBuf."VAT Difference" := SalesLine."Prepayment VAT Difference";
        PrepmtInvLineBuf."Orig. Pmt. Disc. Possible" := SalesLine."Prepmt. Pmt. Discount Amount";

        OnAfterFillInvLineBuffer(PrepmtInvLineBuf, SalesLine, SuppressCommit, SalesHeader);
    end;

    local procedure InsertInvoiceRounding(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; PrevLineNo: Integer): Boolean
    var
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
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

            Currency.Initialize(SalesHeader."Currency Code");
            if IsFullGST(SalesLine) then
                PrepmtInvLineBuf.Amount := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount"
            else
                PrepmtInvLineBuf.Amount := SalesLine."Line Amount";
            PrepmtInvLineBuf."Amount Incl. VAT" := SalesLine."Amount Including VAT";
            if IsFullGST(SalesLine) and not
               SalesHeader."Prices Including VAT"
            then begin
                PrepmtInvLineBuf."VAT Base Amount" := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
                PrepmtInvLineBuf."VAT Base Amount (ACY)" := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount"
            end else
                if IsFullGST(SalesLine) and
                   SalesHeader."Prices Including VAT"
                then begin
                    PrepmtInvLineBuf."VAT Base Amount" :=
                      Round(
                        (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") /
                        (1 + SalesLine."Prepayment VAT %" / 100), Currency."Amount Rounding Precision");
                    PrepmtInvLineBuf."VAT Base Amount (ACY)" :=
                      Round(
                        (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") /
                        (1 + SalesLine."Prepayment VAT %" / 100), Currency."Amount Rounding Precision");
                end else begin
                    PrepmtInvLineBuf."VAT Base Amount" := SalesLine."Line Amount";
                    PrepmtInvLineBuf."VAT Base Amount (ACY)" := SalesLine."Line Amount"
                end;
            PrepmtInvLineBuf."VAT Amount" := SalesLine."Amount Including VAT" - SalesLine."Line Amount";
            PrepmtInvLineBuf."Amount (ACY)" := SalesLine."Prepayment Amount";
            PrepmtInvLineBuf."VAT Amount (ACY)" := SalesLine."Amount Including VAT" - SalesLine."Line Amount";
            OnAfterInsertInvoiceRounding(SalesHeader, PrepmtInvLineBuf, TotalPrepmtInvLineBuf, PrevLineNo);
            exit(true);
        end;
    end;

    /// <summary>
    /// Initializes an invoice rounding line for the prepayment if rounding is required.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="TotalAmount">Specifies the total prepayment amount to check for rounding.</param>
    /// <param name="SalesLine">Returns the initialized invoice rounding sales line if rounding is needed.</param>
    /// <returns>Returns true if an invoice rounding line was created.</returns>
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

    /// <summary>
    /// Updates the VAT amounts on sales lines based on the VAT amount lines for prepayment documents.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="SalesLine">Specifies the sales lines to update.</param>
    /// <param name="VATAmountLine">Specifies the VAT amount lines with calculated VAT amounts.</param>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
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
        DeductedVATBaseAmount: Decimal;
        NewVATBaseAmountRnded: Decimal;
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
                    if IsFullGST(SalesLine) then
                        if SalesLine."Prepayment VAT %" <> SalesLine."VAT %" then
                            SalesLine.FieldError(SalesLine."Prepayment VAT %", StrSubstNo(Text020, SalesLine."VAT %", SalesLine.FieldCaption("VAT %")));
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
                            end else
                                if IsFullGST(SalesLine) then begin
                                    if DocumentType = DocumentType::"Credit Memo" then begin
                                        VATAmount :=
                                          SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount" - SalesLine."Prepmt. VAT Amount Deducted";
                                        DeductedVATBaseAmount := SalesLine."Prepmt. VAT Base Deducted";
                                    end else
                                        VATAmount :=
                                          TempVATAmountLineRemainder."VAT Amount" +
                                          VATAmountLine."VAT Amount" * PrepmtAmt / VATAmountLine."Line Amount";
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      VATAmountLine."Amount Including VAT" * PrepmtAmt / VATAmountLine."Line Amount";
                                    NewVATBaseAmount :=
                                      TempVATAmountLineRemainder."VAT Base" +
                                      ((SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") / (1 + SalesLine."VAT %" / 100) - SalesLine."Prepmt. VAT Base Amt.") *
                                      (1 - SalesHeader."VAT Base Discount %" / 100);
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
                            if not IsFullGST(SalesLine) then
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100),
                                    Currency."Amount Rounding Precision");
                        end else
                            if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then begin
                                VATAmount := PrepmtAmt;
                                NewAmount := 0;
                                NewVATBaseAmount := 0;
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                            end else begin
                                NewAmount := PrepmtAmt;
                                if IsFullGST(SalesLine) then begin
                                    NewVATBaseAmount :=
                                      TempVATAmountLineRemainder."VAT Base" +
                                      (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount" - SalesLine."Prepmt. VAT Base Amt.") *
                                      (1 - SalesHeader."VAT Base Discount %" / 100);
                                    if VATAmountLine."VAT Base" = 0 then
                                        VATAmount := 0
                                    else
                                        if SalesLine."Prepayment %" = 0 then
                                            VATAmount := 0
                                        else
                                            if DocumentType = DocumentType::"Credit Memo" then begin
                                                VATAmount :=
                                                  SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount" - SalesLine."Prepmt. VAT Amount Deducted";
                                                DeductedVATBaseAmount := SalesLine."Prepmt. VAT Base Deducted";
                                            end else
                                                VATAmount :=
                                                  TempVATAmountLineRemainder."VAT Amount" +
                                                  VATAmountLine."VAT Amount" * PrepmtAmt / VATAmountLine."Line Amount";
                                    if SalesLine."Prepayment %" = 0 then
                                        NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision")
                                    else
                                        NewAmountIncludingVAT :=
                                          Round(NewAmount / (SalesLine."Prepayment %" / 100), Currency."Amount Rounding Precision") +
                                          Round(VATAmount, Currency."Amount Rounding Precision");
                                end else begin
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
                                    NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                                end;
                            end;
                        if DocumentType = DocumentType::"Credit Memo" then
                            NewAmountIncludingVAT := CalcDifferAmt(SalesLine, NewAmountIncludingVAT);

                        SalesLine."Prepayment Amount" := NewAmount;
                        if IsFullGST(SalesLine) then begin
                            SalesLine."Prepmt. Amt. Incl. VAT" :=
                              Round(SalesLine."Prepayment Amount" + VATAmount, Currency."Amount Rounding Precision");
                            NewVATBaseAmountRnded := Round(NewVATBaseAmount, Currency."Amount Rounding Precision");
                            if NewVATBaseAmountRnded <> 0 then
                                SalesLine."Prepmt. VAT Base Amt." := NewVATBaseAmountRnded
                            else
                                SalesLine."Prepmt. VAT Base Amt." :=
                                  SalesLine."Prepmt. VAT Base Amt." + NewVATBaseAmountRnded - DeductedVATBaseAmount;
                        end else begin
                            SalesLine."Prepmt. Amt. Incl. VAT" :=
                              Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                            SalesLine."Prepmt. VAT Base Amt." := NewVATBaseAmount;
                        end;
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

                        TempVATAmountLineRemainder."VAT Base" :=
                          NewVATBaseAmount - Round(NewVATBaseAmount, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        if not SalesHeader."Prices Including VAT" then
                            if IsFullGST(SalesLine) then
                                if SalesLine."Prepayment %" <> 0 then
                                    TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT +
                                      Round(NewAmount / (SalesLine."Prepayment %" / 100), Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - SalesLine."Prepayment VAT Difference";
                        TempVATAmountLineRemainder."Pmt. Discount Amount" := NewPmtDiscAmount - Round(NewPmtDiscAmount);
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until SalesLine.Next() = 0;
        VATAmountLine.Reset();

        OnAfterUpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, DocumentType);
    end;

    [Scope('OnPrem')]
    procedure SavePrepmtAmounts(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var TempOriginalSalesLine: Record "Sales Line")
    begin
        TempOriginalSalesLine.Reset();
        TempOriginalSalesLine.DeleteAll();

        ApplyFilter(SalesHeader, DocumentType, SalesLine);
        if SalesLine.FindSet() then
            repeat
                if SalesLine."Prepmt. Amt. Inv." <> SalesLine."Prepmt. Line Amount" then begin
                    TempOriginalSalesLine := SalesLine;
                    TempOriginalSalesLine.Insert();
                end;
            until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure RestorePrepmtAmounts(var TempOriginalSalesLine: Record "Sales Line"; var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
        TempOriginalSalesLine.Reset();
        if TempOriginalSalesLine.FindSet() then
            repeat
                SalesLine.Get(TempOriginalSalesLine."Document Type", TempOriginalSalesLine."Document No.", TempOriginalSalesLine."Line No.");
                if DocumentType = DocumentType::"Credit Memo" then begin
                    SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Amt. Incl. VAT" - TempOriginalSalesLine."Prepmt. Amt. Incl. VAT";
                    SalesLine."Prepayment Amount" := SalesLine."Prepayment Amount" - TempOriginalSalesLine."Prepayment Amount";
                end else begin
                    SalesLine."Prepmt. Amt. Incl. VAT" := SalesLine."Prepmt. Amt. Incl. VAT" + TempOriginalSalesLine."Prepmt. Amt. Incl. VAT";
                    SalesLine."Prepayment Amount" := SalesLine."Prepayment Amount" + TempOriginalSalesLine."Prepayment Amount";
                end;
                SalesLine.Modify();
            until TempOriginalSalesLine.Next() = 0;
        TempOriginalSalesLine.DeleteAll();
    end;

    /// <summary>
    /// Calculates the VAT amount lines for prepayment documents.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="SalesLine">Specifies the sales lines to calculate VAT for.</param>
    /// <param name="VATAmountLine">Returns the calculated VAT amount lines.</param>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
    procedure CalcVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    var
        PrevVatAmountLine: Record "VAT Amount Line";
        Currency: Record Currency;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
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
                    CalcFullGSTOnLine(SalesLine, VATAmountLine, DocumentType, SalesHeader."Prices Including VAT");
                    VATAmountLine.Modify();
                end;
            until SalesLine.Next() = 0;
        VATAmountLine.Reset();

        IsHandled := false;
        OnCalcVATAmountLinesOnBeforeUpdateLines(NewAmount, Currency, SalesHeader, IsHandled);
        if not IsHandled then
            if VATAmountLine.Find('-') then
                repeat
                    if (PrevVatAmountLine."VAT Identifier" <> VATAmountLine."VAT Identifier") or
                       (PrevVatAmountLine."VAT Calculation Type" <> VATAmountLine."VAT Calculation Type") or
                       (PrevVatAmountLine."Tax Group Code" <> VATAmountLine."Tax Group Code") or
                       (PrevVatAmountLine."Use Tax" <> VATAmountLine."Use Tax")
                    then
                        PrevVatAmountLine.Init();
                    if SalesHeader."Prices Including VAT" then
                        case VATAmountLine."VAT Calculation Type" of
                            VATAmountLine."VAT Calculation Type"::"Normal VAT",
                            VATAmountLine."VAT Calculation Type"::"Reverse Charge VAT":
                                begin
                                    if not VATAmountLine."Full GST on Prepayment" then begin
                                        VATAmountLine."VAT Base" :=
                                          Round(
                                            (VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount") / (1 + VATAmountLine."VAT %" / 100),
                                            Currency."Amount Rounding Precision") - VATAmountLine."VAT Difference";
                                        VATAmountLine."VAT Amount" :=
                                          VATAmountLine."VAT Difference" +
                                          Round(
                                            PrevVatAmountLine."VAT Amount" +
                                            (VATAmountLine."Line Amount" - VATAmountLine."VAT Base" - VATAmountLine."VAT Difference") *
                                            (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100),
                                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                        VATAmountLine."Amount Including VAT" := VATAmountLine."VAT Base" + VATAmountLine."VAT Amount";
                                    end;
                                    if VATAmountLine.Positive then
                                        PrevVatAmountLine.Init()
                                    else begin
                                        PrevVatAmountLine := VATAmountLine;
                                        PrevVatAmountLine."VAT Amount" :=
                                          (VATAmountLine."Line Amount" - VATAmountLine."VAT Base" - VATAmountLine."VAT Difference") *
                                          (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100);
                                        PrevVatAmountLine."VAT Amount" :=
                                          PrevVatAmountLine."VAT Amount" -
                                          Round(PrevVatAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                    end;
                                end;
                            VATAmountLine."VAT Calculation Type"::"Full VAT":
                                begin
                                    VATAmountLine."VAT Base" := 0;
                                    VATAmountLine."VAT Amount" := VATAmountLine."VAT Difference" + VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount";
                                    VATAmountLine."Amount Including VAT" := VATAmountLine."VAT Amount";
                                end;
                            VATAmountLine."VAT Calculation Type"::"Sales Tax":
                                begin
                                    VATAmountLine."Amount Including VAT" := VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount";
                                    VATAmountLine."VAT Base" :=
                                      Round(
                                        SalesTaxCalculate.ReverseCalculateTax(
                                          SalesHeader."Tax Area Code", VATAmountLine."Tax Group Code", SalesHeader."Tax Liable",
                                          SalesHeader."Posting Date", VATAmountLine."Amount Including VAT", VATAmountLine.Quantity, SalesHeader."Currency Factor"),
                                        Currency."Amount Rounding Precision");
                                    VATAmountLine."VAT Amount" := VATAmountLine."VAT Difference" + VATAmountLine."Amount Including VAT" - VATAmountLine."VAT Base";
                                    if VATAmountLine."VAT Base" = 0 then
                                        VATAmountLine."VAT %" := 0
                                    else
                                        VATAmountLine."VAT %" := Round(100 * VATAmountLine."VAT Amount" / VATAmountLine."VAT Base", 0.00001);
                                end;
                        end
                    else
                        case VATAmountLine."VAT Calculation Type" of
                            VATAmountLine."VAT Calculation Type"::"Normal VAT",
                            VATAmountLine."VAT Calculation Type"::"Reverse Charge VAT":
                                begin
                                    if not VATAmountLine."Full GST on Prepayment" then begin
                                        VATAmountLine."VAT Base" := VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount";
                                        VATAmountLine."VAT Amount" :=
                                          VATAmountLine."VAT Difference" +
                                          Round(
                                            PrevVatAmountLine."VAT Amount" +
                                            VATAmountLine."VAT Base" * VATAmountLine."VAT %" / 100 * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100),
                                            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                        VATAmountLine."Amount Including VAT" := VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount" + VATAmountLine."VAT Amount";
                                    end;
                                    if VATAmountLine.Positive then
                                        PrevVatAmountLine.Init()
                                    else begin
                                        PrevVatAmountLine := VATAmountLine;
                                        PrevVatAmountLine."VAT Amount" :=
                                          VATAmountLine."VAT Base" * VATAmountLine."VAT %" / 100 * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100);
                                        PrevVatAmountLine."VAT Amount" :=
                                          PrevVatAmountLine."VAT Amount" -
                                          Round(PrevVatAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                    end;
                                end;
                            VATAmountLine."VAT Calculation Type"::"Full VAT":
                                begin
                                    VATAmountLine."VAT Base" := 0;
                                    VATAmountLine."VAT Amount" := VATAmountLine."VAT Difference" + VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount";
                                    VATAmountLine."Amount Including VAT" := VATAmountLine."VAT Amount";
                                end;
                            VATAmountLine."VAT Calculation Type"::"Sales Tax":
                                begin
                                    VATAmountLine."VAT Base" := VATAmountLine."Line Amount" - VATAmountLine."Invoice Discount Amount";
                                    VATAmountLine."VAT Amount" :=
                                      SalesTaxCalculate.CalculateTax(
                                        SalesHeader."Tax Area Code", VATAmountLine."Tax Group Code", SalesHeader."Tax Liable",
                                        SalesHeader."Posting Date", VATAmountLine."VAT Base", VATAmountLine.Quantity, SalesHeader."Currency Factor");
                                    if VATAmountLine."VAT Base" = 0 then
                                        VATAmountLine."VAT %" := 0
                                    else
                                        VATAmountLine."VAT %" := Round(100 * VATAmountLine."VAT Amount" / VATAmountLine."VAT Base", 0.00001);
                                    VATAmountLine."VAT Amount" :=
                                      VATAmountLine."VAT Difference" +
                                      Round(VATAmountLine."VAT Amount", Currency."Amount Rounding Precision", Currency.VATRoundingDirection());
                                    VATAmountLine."Amount Including VAT" := VATAmountLine."VAT Base" + VATAmountLine."VAT Amount";
                                end;
                        end;

                    VATAmountLine."Calculated VAT Amount" := VATAmountLine."VAT Amount" - VATAmountLine."VAT Difference";
                    VATAmountLine.Modify();
                until VATAmountLine.Next() = 0;

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
        VATAmountLine.SetRange("Full GST on Prepayment", IsFullGST(SalesLine));
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
        VATAmountLine."Full GST on Prepayment" := IsFullGST(SalesLine);
        OnInsertVATAmountOnBeforeInsert(SalesLine, VATAmountLine);
        VATAmountLine.Insert();
    end;

    local procedure CalcFullGSTOnLine(SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; PricesIncludingVAT: Boolean)
    begin
        if VATAmountLine."Full GST on Prepayment" then begin
            if DocumentType = DocumentType::"Credit Memo" then begin
                VATAmountLine."VAT Base" += SalesLine."Prepmt. VAT Base Amt.";
                VATAmountLine."VAT Amount" += SalesLine."Prepmt. Amount Inv. Incl. VAT" - SalesLine."Prepayment Amount";
            end else begin
                VATAmountLine."VAT Amount" += SalesLine."Amount Including VAT" - SalesLine.Amount;
                VATAmountLine."VAT Base" += SalesLine.Amount;
            end;
            VATAmountLine."Amount Including VAT" := VATAmountLine."Line Amount";
            if not PricesIncludingVAT then
                VATAmountLine."Amount Including VAT" += VATAmountLine."VAT Amount";
        end;
    end;

    /// <summary>
    /// Calculates the total prepayment amount and VAT amount for statistics.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="SalesLine">Specifies the sales lines to summarize.</param>
    /// <param name="VATAmountLine">Returns the calculated VAT amount lines.</param>
    /// <param name="TotalAmount">Returns the total prepayment amount.</param>
    /// <param name="TotalVATAmount">Returns the total VAT amount.</param>
    /// <param name="VATAmountText">Returns the VAT percentage text for display.</param>
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

    /// <summary>
    /// Gets the sales lines with prepayment amounts for the specified document type.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
    /// <param name="ToSalesLine">Returns the sales lines with prepayment amounts.</param>
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

    /// <summary>
    /// Applies filters to the sales lines for prepayment processing based on document type.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
    /// <param name="SalesLine">Returns the filtered sales lines.</param>
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

    /// <summary>
    /// Calculates the prepayment amount for the sales line based on the document type.
    /// </summary>
    /// <param name="SalesLine">Specifies the sales line to calculate the prepayment amount for.</param>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
    /// <returns>Returns the prepayment amount.</returns>
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
        if GLSetup."GST Report" then
            InsertGST(SalesHeader, PrepmtInvLineBuffer, DocumentType, DocNo, GenJnlPostLine.GetVATEntryNo());
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

    /// <summary>
    /// Distributes the new total prepayment amount across the sales lines proportionally.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="NewTotalPrepmtAmount">Specifies the new total prepayment amount to distribute.</param>
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

    /// <summary>
    /// Converts the prepayment document type to the corresponding sales document type integer value.
    /// </summary>
    /// <param name="DocumentType">Specifies the prepayment document type.</param>
    /// <returns>Returns the corresponding sales document type as an integer.</returns>
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

    /// <summary>
    /// Gets the sales lines that have prepayment amounts to deduct during final invoicing.
    /// </summary>
    /// <param name="SalesHeader">Specifies the sales header of the order.</param>
    /// <param name="SalesLines">Returns the sales lines with prepayment amounts to deduct.</param>
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
        SalesLine2: Record "Sales Line";
        Currency: Record Currency;
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

        SalesInvLine.Quantity := 1;
        if GLSetup.CheckFullGSTonPrepayment(PrepmtInvLineBuffer."VAT Bus. Posting Group", PrepmtInvLineBuffer."VAT Prod. Posting Group") then
            SalesInvLine."Prepayment Line" := true;
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
        if IsFullGST(PrepmtInvLineBuffer) then begin
            Currency.Initialize(SalesInvHeader."Currency Code");
            SalesInvLine."Inv. Discount Amount" := 0;
            SalesLine2.Reset();
            SalesLine2.SetFilter("Document No.", SalesHeader."No.");
            if SalesLine2.Find('-') then
                repeat
                    SalesInvLine."Inv. Discount Amount" +=
                      Round(SalesLine2."Inv. Discount Amount" * SalesLine2."Prepayment %" / 100, Currency."Amount Rounding Precision");
                until SalesLine2.Next() = 0;
            SalesInvLine."Prepayment %" := PrepmtInvLineBuffer."Prepayment %";
        end;
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

    [Scope('OnPrem')]
    procedure InsertGST(SalesHeader: Record "Sales Header"; PrepmtInvBuf2: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; VATEntryNo: Integer)
    var
        GSTSalesEntry: Record "GST Sales Entry";
        SalesCrmemoLine3: Record "Sales Cr.Memo Line";
        SalesInvLine3: Record "Sales Invoice Line";
        EntryNo: Integer;
    begin
        if not GLSetup."GST Report" then
            exit;
        if PrepmtInvBuf2.Adjustment then
            exit;
        if VATEntryNo = 0 then
            exit;
        if GSTSalesEntry.FindLast() then
            EntryNo := GSTSalesEntry."Entry No." + 1
        else
            EntryNo := 1;

        GSTSalesEntry.Init();
        GSTSalesEntry."Entry No." := EntryNo;
        GSTSalesEntry."GST Entry No." := VATEntryNo;
        GSTSalesEntry."GST Entry Type" := GSTSalesEntry."GST Entry Type"::Sale;
        GSTSalesEntry."GST Base" := PrepmtInvBuf2."VAT Base Amount";
        GSTSalesEntry.Amount := PrepmtInvBuf2."VAT Amount";
        GSTSalesEntry."VAT Calculation Type" := PrepmtInvBuf2."VAT Calculation Type";
        GSTSalesEntry."VAT Bus. Posting Group" := PrepmtInvBuf2."VAT Bus. Posting Group";
        GSTSalesEntry."VAT Prod. Posting Group" := PrepmtInvBuf2."VAT Prod. Posting Group";
        GSTSalesEntry."Posting Date" := SalesHeader."Posting Date";
        GSTSalesEntry."Customer No." := SalesHeader."Sell-to Customer No.";
        GSTSalesEntry."Customer Name" := SalesHeader."Sell-to Customer Name";

        TempGlobalPrepmtInvLineBufGST.Get(
          PrepmtInvBuf2."G/L Account No.", PrepmtInvBuf2."Job No.", PrepmtInvBuf2."Tax Area Code", PrepmtInvBuf2."Tax Liable",
          PrepmtInvBuf2."Tax Group Code", PrepmtInvBuf2."Invoice Rounding", false, PrepmtInvBuf2."Line No.", PrepmtInvBuf2."Dimension Set ID");

        GenPostingSetup.Get(PrepmtInvBuf2."Gen. Bus. Posting Group", TempGlobalPrepmtInvLineBufGST."Gen. Prod. Posting Group");
        case DocumentType of
            DocumentType::Invoice:
                begin
                    GSTSalesEntry."Document Type" := GSTSalesEntry."Document Type"::Invoice;
                    GSTSalesEntry."Document No." := DocumentNo;
                    SalesInvLine3.Reset();
                    SalesInvLine3.SetRange("Document No.", DocumentNo);
                    SalesInvLine3.SetRange("No.", GenPostingSetup.GetSalesPrepmtAccount());
                    if SalesInvLine3.FindFirst() then begin
                        GSTSalesEntry."Document Line Type" := SalesInvLine3.Type;
                        GSTSalesEntry."Document Line Code" := SalesInvLine3."No.";
                        GSTSalesEntry."Document Line Description" := SalesInvLine3.Description;
                        GSTSalesEntry."Document Line No." := SalesInvLine3."Line No.";
                    end;
                end;
            DocumentType::"Credit Memo":
                begin
                    GSTSalesEntry."Document Type" := GSTSalesEntry."Document Type"::"Credit Memo";
                    GSTSalesEntry."Document No." := DocumentNo;
                    SalesCrmemoLine3.Reset();
                    SalesCrmemoLine3.SetRange("Document No.", DocumentNo);
                    SalesCrmemoLine3.SetRange("No.", GenPostingSetup.GetSalesPrepmtAccount());
                    if SalesCrmemoLine3.FindFirst() then begin
                        GSTSalesEntry."Document Line Type" := SalesCrmemoLine3.Type;
                        GSTSalesEntry."Document Line Code" := SalesCrmemoLine3."No.";
                        GSTSalesEntry."Document Line Description" := SalesCrmemoLine3.Description;
                        GSTSalesEntry."Document Line No." := SalesCrmemoLine3."Line No.";
                    end;
                end;
        end;
        GSTSalesEntry.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertInvLineBufferGST(var PrepmtInvBuf: Record "Prepayment Inv. Line Buffer"; PrepmtInvBuf2: Record "Prepayment Inv. Line Buffer")
    begin
        PrepmtInvBuf := PrepmtInvBuf2;
        if PrepmtInvBuf.Find() then begin
            PrepmtInvBuf.IncrAmounts(PrepmtInvBuf2);
            PrepmtInvBuf.Modify();
        end else
            PrepmtInvBuf.Insert();
    end;

    local procedure FillInvLineBufferGST(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; GLAcc: Record "G/L Account"; var PrepmtInvBuf: Record "Prepayment Inv. Line Buffer")
    var
        Currency: Record Currency;
    begin
        Clear(PrepmtInvBuf);

        PrepmtInvBuf."G/L Account No." := GLAcc."No.";
        PrepmtInvBuf."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        PrepmtInvBuf."VAT Bus. Posting Group" := SalesLine."VAT Bus. Posting Group";
        PrepmtInvBuf."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        PrepmtInvBuf."VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        PrepmtInvBuf."VAT Calculation Type" := SalesLine."Prepmt. VAT Calc. Type";
        PrepmtInvBuf."Global Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        PrepmtInvBuf."Global Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        PrepmtInvBuf."Dimension Set ID" := SalesLine."Dimension Set ID";
        PrepmtInvBuf."Job No." := SalesLine."Job No.";
        if GLSetup."Full GST on Prepayment" then
            PrepmtInvBuf."Invoice Discount Amount" := SalesLine."Prepmt. Line Amount" - SalesLine."Prepayment Amount";
        PrepmtInvBuf.Amount := SalesLine."Prepayment Amount";
        PrepmtInvBuf."Amount Incl. VAT" := SalesLine."Prepmt. Amt. Incl. VAT";

        Currency.Initialize(SalesHeader."Currency Code");
        GLSetup.Get();
        if GLSetup."Full GST on Prepayment" and not SalesHeader."Prices Including VAT" then
            PrepmtInvBuf."VAT Base Amount" := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount"
        else
            if not GLSetup."Full GST on Prepayment" then
                PrepmtInvBuf."VAT Base Amount" := SalesLine."Prepayment Amount"
            else
                if GLSetup."Full GST on Prepayment" and SalesHeader."Prices Including VAT" then
                    PrepmtInvBuf."VAT Base Amount" :=
                      Round(
                        (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") / (1 + SalesLine."Prepayment VAT %" / 100),
                        Currency."Amount Rounding Precision");
        PrepmtInvBuf."VAT Amount" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
        PrepmtInvBuf."Amount (ACY)" := SalesLine."Prepayment Amount";
        if GLSetup."Full GST on Prepayment" and not SalesHeader."Prices Including VAT" then
            PrepmtInvBuf."VAT Base Amount (ACY)" := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount"
        else
            if not GLSetup."Full GST on Prepayment" then
                PrepmtInvBuf."VAT Base Amount (ACY)" := SalesLine."Prepayment Amount"
            else
                if GLSetup."Full GST on Prepayment" and SalesHeader."Prices Including VAT" then
                    PrepmtInvBuf."VAT Base Amount (ACY)" :=
                      Round(
                        (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") / (1 + SalesLine."Prepayment VAT %" / 100),
                        Currency."Amount Rounding Precision");
        PrepmtInvBuf."VAT Amount (ACY)" := SalesLine."Prepmt. Amt. Incl. VAT" - SalesLine."Prepayment Amount";
        PrepmtInvBuf."VAT %" := SalesLine."Prepayment VAT %";
        if GLSetup."Full GST on Prepayment" then
            PrepmtInvBuf."Prepayment %" := SalesLine."Prepayment %";
        PrepmtInvBuf."VAT Identifier" := SalesLine."Prepayment VAT Identifier";
        PrepmtInvBuf."Tax Area Code" := SalesLine."Tax Area Code";
        PrepmtInvBuf."Tax Liable" := SalesLine."Tax Liable";
        PrepmtInvBuf."Tax Group Code" := SalesLine."Tax Group Code";
        if not SalesHeader."Compress Prepayment" then begin
            PrepmtInvBuf."Line No." := SalesLine."Line No.";
            PrepmtInvBuf.Description := SalesLine.Description;
        end else
            PrepmtInvBuf.Description := GLAcc.Name;
    end;

    local procedure BuildInvLineBufferGST(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; var PrepmtInvBuf: Record "Prepayment Inv. Line Buffer"; InvoiceRounding: Boolean)
    var
        GLAcc: Record "G/L Account";
        TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer";
        TotalPrepmtInvLineBufferDummy: Record "Prepayment Inv. Line Buffer";
    begin
        ApplyFilter(SalesHeader, DocumentType, SalesLine);
        SalesLine.SetRange("System-Created Entry", false);
        if SalesLine.Find('-') then
            repeat
                if PrepmtAmount(SalesLine, DocumentType) <> 0 then begin
                    if SalesLine.Quantity < 0 then
                        SalesLine.FieldError(Quantity, StrSubstNo(Text018, SalesHeader.FieldCaption("Prepayment %")));
                    if SalesLine."Unit Price" < 0 then
                        SalesLine.FieldError("Unit Price", StrSubstNo(Text018, SalesHeader.FieldCaption("Prepayment %")));
                    if (SalesLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
                       (SalesLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
                    then
                        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
                    GLAcc.Get(GenPostingSetup.GetSalesPrepmtAccount());
                    if GLSetup."GST Report" then begin
                        FillInvLineBufferGST(SalesHeader, SalesLine, GLAcc, TempGlobalPrepmtInvLineBufGST);
                        InsertInvLineBufferGST(PrepmtInvBuf, TempGlobalPrepmtInvLineBufGST);
                    end;
                    if InvoiceRounding then
                        RoundAmounts(SalesHeader, TempGlobalPrepmtInvLineBufGST, TotalPrepmtInvLineBuffer, TotalPrepmtInvLineBufferDummy);
                end;
            until SalesLine.Next() = 0;
        if InvoiceRounding then
            if InsertInvoiceRounding(SalesHeader, TempGlobalPrepmtInvLineBufGST, TotalPrepmtInvLineBuffer, SalesLine."Line No.") then
                PrepmtInvBuf.InsertInvLineBuffer(TempGlobalPrepmtInvLineBufGST);
    end;

    [Scope('OnPrem')]
    procedure PrepmtAmountCheck(SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic): Decimal
    begin
        case DocumentType of
            DocumentType::Statistic:
                exit(SalesLine."Prepmt. Line Amount");
            DocumentType::Invoice:
                if (SalesLine."Inv. Discount Amount" <> 0) and (SalesLine."Prepmt. Line Amount" > (SalesLine."Inv. Discount Amount" * SalesLine."Prepayment %" / 100)) then
                    exit(SalesLine."Prepmt. Line Amount" - (SalesLine."Inv. Discount Amount" * SalesLine."Prepayment %" / 100) - SalesLine."Prepmt. Amt. Inv.")
                else
                    exit(SalesLine."Prepmt. Line Amount" - SalesLine."Prepmt. Amt. Inv.");
            else
                exit(SalesLine."Prepmt. Amt. Inv." - SalesLine."Prepmt Amt Deducted");
        end;
    end;

    /// <summary>
    /// Gets whether the prepayment posting is running in preview mode.
    /// </summary>
    /// <returns>Returns true if preview mode is enabled.</returns>
    procedure GetPreviewMode(): Boolean
    begin
        exit(PreviewMode);
    end;

    /// <summary>
    /// Gets whether database commits are being suppressed during prepayment posting.
    /// </summary>
    /// <returns>Returns true if commits are suppressed.</returns>
    procedure GetSuppressCommit(): Boolean
    begin
        exit(SuppressCommit);
    end;

    /// <summary>
    /// Sets whether database commits should be suppressed during prepayment posting.
    /// </summary>
    /// <param name="NewSuppressCommit">Specifies whether to suppress commits.</param>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    /// <summary>
    /// Sets whether the prepayment posting is running in preview mode.
    /// </summary>
    /// <param name="NewPreviewMode">Specifies whether preview mode is enabled.</param>
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    local procedure CalcDifferAmt(SalesLine: Record "Sales Line"; NewAmountIncludingVAT: Decimal): Decimal
    var
        AmountInclVAT: Decimal;
        AmountInclVATDiff: Decimal;
    begin
        if SalesLine."Prepayment %" = 100 then begin
            AmountInclVATDiff := NewAmountIncludingVAT - SalesLine."Prepmt. Amt. Incl. VAT";
            if AmountInclVATDiff <> 0 then
                AmountInclVAT := NewAmountIncludingVAT - AmountInclVATDiff
            else
                AmountInclVAT := NewAmountIncludingVAT;
        end else
            AmountInclVAT := NewAmountIncludingVAT;
        exit(AmountInclVAT);
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

    local procedure IsFullGST(var SalesLine: Record "Sales Line"): Boolean
    begin
        GLSetup.GetRecordOnce();
        exit(GLSetup.CheckFullGSTonPrepayment(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"));
    end;

    local procedure IsFullGST(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"): Boolean
    begin
        GLSetup.GetRecordOnce();
        exit(GLSetup.CheckFullGSTonPrepayment(PrepaymentInvLineBuffer."VAT Bus. Posting Group", PrepaymentInvLineBuffer."VAT Prod. Posting Group"));
    end;

    local procedure UpdateDifferenceAmount(SalesHeader: Record "Sales Header"; var TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; var TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; HasInvoiceDiscount: Boolean)
    var
        Currency: Record Currency;
        PrepmtAmt: Decimal;
        DifferenceAmt: Decimal;
    begin
        if HasInvoiceDiscount and (SalesHeader."Prepayment %" <> 0) then begin
            Currency.Initialize(SalesHeader."Currency Code");
            SalesHeader.CalcFields(Amount);
            PrepmtAmt := Round(SalesHeader.Amount * SalesHeader."Prepayment %" / 100, Currency."Amount Rounding Precision");
            if TotalPrepmtInvLineBuffer.Amount > PrepmtAmt then begin
                DifferenceAmt := TotalPrepmtInvLineBuffer.Amount - PrepmtAmt;

                TempPrepmtInvLineBuf.Reset();
                TempPrepmtInvLineBuf.SetCurrentKey(Adjustment);
                if TempPrepmtInvLineBuf.FindLast() then begin
                    TempPrepmtInvLineBuf.Amount := Round(TempPrepmtInvLineBuf.Amount - DifferenceAmt, Currency."Amount Rounding Precision");
                    TempPrepmtInvLineBuf."Amount Incl. VAT" := Round(TempPrepmtInvLineBuf."Amount Incl. VAT" - DifferenceAmt, Currency."Amount Rounding Precision");
                    TempPrepmtInvLineBuf.Modify();
                end;
            end;
        end;
    end;

    /// <summary>
    /// Raised after applying filters on sales lines for prepayment processing.
    /// </summary>
    /// <param name="SalesLine">The filtered sales lines.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyFilter(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; DocumentType: Option)
    begin
    end;

    /// <summary>
    /// Raised after building the prepayment invoice line buffer.
    /// </summary>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer that was built.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterBuildInvLineBuffer(var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    /// <summary>
    /// Raised after calculating VAT amount lines for prepayments.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The sales lines being processed.</param>
    /// <param name="VATAmountLine">The calculated VAT amount lines.</param>
    /// <param name="DocumentType">The document type (Invoice, Credit Memo, or Statistic).</param>
    /// <param name="Currency">The currency used for the calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; Currency: Record Currency)
    begin
    end;

    /// <summary>
    /// Raised after checking the prepayment document for posting readiness.
    /// </summary>
    /// <param name="SalesHeader">The sales header that was checked.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="ErrorMessageMgt">The error message management codeunit for handling errors.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var ErrorMessageMgt: Codeunit "Error Message Management")
    begin
    end;

    /// <summary>
    /// Raised after creating dimensions for prepayment lines.
    /// </summary>
    /// <param name="SalesLine">The sales line with dimensions.</param>
    /// <param name="DefaultDimSource">The default dimension sources used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimensions(var SalesLine: Record "Sales Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    /// <summary>
    /// Raised after creating prepayment lines and before posting to the general ledger.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesInvHeader">The posted sales invoice header.</param>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header.</param>
    /// <param name="TempPrepmtInvLineBuffer">The temporary prepayment invoice line buffer.</param>
    /// <param name="DocumentType">The document type being posted.</param>
    /// <param name="LastLineNo">The last line number used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLinesOnBeforeGLPosting(var SalesHeader: Record "Sales Header"; SalesInvHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var LastLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised after filling the prepayment invoice line buffer from a sales line.
    /// </summary>
    /// <param name="PrepmtInvLineBuf">The prepayment invoice line buffer that was filled.</param>
    /// <param name="SalesLine">The source sales line.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillInvLineBuffer(var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; SalesLine: Record "Sales Line"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after inserting the invoice rounding line for prepayments.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer with rounding.</param>
    /// <param name="TotalPrepmtInvLineBuf">The total prepayment invoice line buffer.</param>
    /// <param name="PrevLineNo">The previous line number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertInvoiceRounding(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var PrevLineNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised after posting prepayments.
    /// </summary>
    /// <param name="SalesHeader">The sales header that was posted.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="SalesInvoiceHeader">The posted prepayment invoice header.</param>
    /// <param name="SalesCrMemoHeader">The posted prepayment credit memo header.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry that was created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepayments(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised after posting prepayments before throwing a preview mode error.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesInvHeader">The posted sales invoice header.</param>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepaymentsOnBeforeThrowPreviewModeError(var SalesHeader: Record "Sales Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after posting the balancing entry for prepayments.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="CustLedgEntry">The customer ledger entry.</param>
    /// <param name="TotalPrepmtInvLineBuffer">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufferLCY">The total prepayment invoice line buffer in LCY.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostBalancingEntry(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised after posting the customer entry for prepayments.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="TotalPrepmtInvLineBuffer">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufferLCY">The total prepayment invoice line buffer in LCY.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after posting a prepayment invoice line buffer entry.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer that was posted.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Raised after rounding prepayment amounts.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer with rounded amounts.</param>
    /// <param name="TotalPrepmtInvLineBuf">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufLCY">The total prepayment invoice line buffer in LCY.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    /// <summary>
    /// Raised after inserting a prepayment sales invoice header.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The sales invoice header that was inserted.</param>
    /// <param name="SalesHeader">The source sales header.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after inserting a prepayment sales invoice line.
    /// </summary>
    /// <param name="SalesInvLine">The sales invoice line that was inserted.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after inserting a prepayment sales credit memo header.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header that was inserted.</param>
    /// <param name="SalesHeader">The source sales header.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after inserting a prepayment sales credit memo line.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line that was inserted.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after updating the posted sales document with prepayment information.
    /// </summary>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="DocumentNo">The document number.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePostedSalesDocument(DocumentType: Option Invoice,"Credit Memo"; DocumentNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after updating VAT on lines for prepayments.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The sales lines being updated.</param>
    /// <param name="VATAmountLine">The VAT amount lines.</param>
    /// <param name="DocumentType">The document type (Invoice, Credit Memo, or Statistic).</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; DocumentType: Option Invoice,"Credit Memo",Statistic)
    begin
    end;

    /// <summary>
    /// Raised before checking the prepayment document for posting readiness.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="DocumentType">The document type to check.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtDoc(SalesHeader: Record "Sales Header"; DocumentType: Option; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before checking for open prepayment lines.
    /// </summary>
    /// <param name="SalesHeader">The sales header to check.</param>
    /// <param name="DocumentType">The document type to check.</param>
    /// <param name="Found">Returns whether open prepayment lines were found.</param>
    /// <param name="IsHandled">Set to true to skip the default check logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckOpenPrepaymentLines(SalesHeader: Record "Sales Header"; DocumentType: Option; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before creating lines from the prepayment buffer.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The sales line record.</param>
    /// <param name="TempGlobalPrepmtInvLineBuf">The temporary prepayment invoice line buffer.</param>
    /// <param name="LineCount">The line count.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header.</param>
    /// <param name="PostedDocTabNo">The posted document table number.</param>
    /// <param name="DocumentType">The document type.</param>
    /// <param name="LastLineNo">The last line number.</param>
    /// <param name="GenJnlLineDocNo">The general journal line document number.</param>
    /// <param name="IsHandled">Set to true to skip the default line creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLinesFromBuffer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempGlobalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary; var LineCount: Integer; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var PostedDocTabNo: Integer; DocumentType: Option; var LastLineNo: Integer; GenJnlLineDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting a prepayment invoice.
    /// </summary>
    /// <param name="SalesHeader">The sales header for the prepayment invoice.</param>
    /// <param name="Handled">Set to true to skip the default invoice posting.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeInvoice(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting a prepayment credit memo.
    /// </summary>
    /// <param name="SalesHeader">The sales header for the prepayment credit memo.</param>
    /// <param name="Handled">Set to true to skip the default credit memo posting.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreditMemo(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before filling the prepayment invoice line buffer.
    /// </summary>
    /// <param name="PrepaymentInvLineBuffer">The prepayment invoice line buffer to fill.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The source sales line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillInvLineBuffer(var PrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before inserting extended text for prepayment lines.
    /// </summary>
    /// <param name="TabNo">The table number.</param>
    /// <param name="DocNo">The document number.</param>
    /// <param name="GLAccNo">The G/L account number.</param>
    /// <param name="DocDate">The document date.</param>
    /// <param name="LanguageCode">The language code.</param>
    /// <param name="PrevLineNo">The previous line number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(TabNo: Integer; DocNo: Code[20]; GLAccNo: Code[20]; DocDate: Date; LanguageCode: Code[10]; var PrevLineNo: Integer);
    begin
    end;

    /// <summary>
    /// Raised before posting prepayments.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be posted.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepayments(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting the prepayment sales invoice header.
    /// </summary>
    /// <param name="SalesInvHeader">The sales invoice header to be inserted.</param>
    /// <param name="SalesHeader">The source sales header.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="GenJnlDocNo">The general journal document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; GenJnlDocNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raised before asserting that the prepayment amount is not more than the document amount.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry being checked.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="IsHandled">Set to true to skip the default assertion logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesAssertPrepmtAmountNotMoreThanDocAmount(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a prepayment sales invoice line.
    /// </summary>
    /// <param name="SalesInvLine">The sales invoice line to be inserted.</param>
    /// <param name="SalesInvHeader">The sales invoice header.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting the prepayment sales credit memo header.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The sales credit memo header to be inserted.</param>
    /// <param name="SalesHeader">The source sales header.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a prepayment sales credit memo line.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line to be inserted.</param>
    /// <param name="SalesCrMemoHeader">The sales credit memo header.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the customer entry for the prepayment.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="TotalPrepmtInvLineBuffer">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufferLCY">The total prepayment invoice line buffer in LCY.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntry(var GenJnlLine: Record "Gen. Journal Line"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    /// <summary>
    /// Raised before running the general journal post line codeunit.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Raised before updating the sales document after prepayment posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header to be updated.</param>
    /// <param name="SalesLine">The sales line to be updated.</param>
    /// <param name="DocumentType">The document type.</param>
    /// <param name="GenJnlLineDocNo">The general journal line document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; GenJnlLineDocNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raised before updating document numbers for prepayment posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="DocNo">The document number to be assigned.</param>
    /// <param name="NoSeriesCode">The number series code to use.</param>
    /// <param name="ModifyHeader">Indicates whether the header should be modified.</param>
    /// <param name="IsPreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="IsHandled">Set to true to skip the default document number update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocNos(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var DocNo: Code[20]; var NoSeriesCode: Code[20]; var ModifyHeader: Boolean; IsPreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating the posted sales document with the customer ledger entry number.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry that was created.</param>
    /// <param name="SalesInvoiceHeader">The posted sales invoice header.</param>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    /// <param name="DocumentNo">The document number.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePostedSalesDocument(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocumentType: Option Invoice,"Credit Memo"; var IsHandled: Boolean; DocumentNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raised before posting the prepayment invoice line buffer to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="PrepmtInvLineBuffer">The prepayment invoice line buffer.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepmtInvLineBuffer(var GenJnlLine: Record "Gen. Journal Line"; PrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean)
    begin
    end;

    /// <summary>
    /// Raised during VAT amount lines calculation before updating lines.
    /// </summary>
    /// <param name="NewAmount">The new amount calculated.</param>
    /// <param name="Currency">The currency used for the calculation.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeUpdateLines(var NewAmount: Decimal; Currency: Record Currency; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after building the prepayment invoice line buffer in the Code procedure.
    /// </summary>
    /// <param name="TempVATAmountLine">The temporary VAT amount lines.</param>
    /// <param name="TempPrepmtInvLineBuffer">The temporary prepayment invoice line buffer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterBuildInvLineBuffer(var TempVATAmountLine: Record "VAT Amount Line" temporary; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Raised before calculating and updating VAT amount lines in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TempPrepmtInvLineBuffer">The temporary prepayment invoice line buffer.</param>
    /// <param name="DocumentType">The document type.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCalcAndUpdateVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; DocumentType: Option; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before posting the customer entry in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="TempPrepaymentInvLineBuffer">The temporary prepayment invoice line buffer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostCustomerEntry(var SalesHeader: Record "Sales Header"; var TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Raised before posting the balancing entry in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="TempPrepaymentInvLineBuffer">The temporary prepayment invoice line buffer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostBalancingEntry(var SalesHeader: Record "Sales Header"; var TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Raised before opening the progress window in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeWindowOpen(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    /// <summary>
    /// Raised after calculating whether to set pending prepayment status in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesInvoiceHeader">The posted prepayment invoice header.</param>
    /// <param name="SalesCrMemoHeader">The posted prepayment credit memo header.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="ShouldSetPendingPrepaymentStatus">Indicates whether pending prepayment status should be set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldSetPendingPrepaymentStatus(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocumentType: Option Invoice,"Credit Memo"; PreviewMode: Boolean; var ShouldSetPendingPrepaymentStatus: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before inserting a sales invoice line during extended text insertion.
    /// </summary>
    /// <param name="SalesInvoiceLine">The sales invoice line to be inserted.</param>
    /// <param name="TabNo">The table number.</param>
    /// <param name="DocNo">The document number.</param>
    /// <param name="NextLineNo">The next line number.</param>
    /// <param name="TempExtendedTextLine">The temporary extended text line.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertExtendedTextOnBeforeSalesInvLineInsert(var SalesInvoiceLine: Record "Sales Invoice Line"; TabNo: Integer; DocNo: Code[20]; NextLineNo: Integer; var TempExtendedTextLine: Record "Extended Text Line" temporary; SalesHeader: Record "Sales Header");
    begin
    end;

    /// <summary>
    /// Raised before inserting a sales credit memo line during extended text insertion.
    /// </summary>
    /// <param name="SalesCrMemoLine">The sales credit memo line to be inserted.</param>
    /// <param name="TabNo">The table number.</param>
    /// <param name="DocNo">The document number.</param>
    /// <param name="NextLineNo">The next line number.</param>
    /// <param name="TempExtendedTextLine">The temporary extended text line.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertExtendedTextOnBeforeSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; TabNo: Integer; DocNo: Code[20]; NextLineNo: Integer; var TempExtendedTextLine: Record "Extended Text Line" temporary; SalesHeader: Record "Sales Header");
    begin
    end;

    /// <summary>
    /// Raised before running the general journal post line with check during balancing entry posting.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="CustLedgEntry">The customer ledger entry.</param>
    /// <param name="TotalPrepmtInvLineBuffer">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufferLCY">The total prepayment invoice line buffer in LCY.</param>
    /// <param name="CommitIsSuppressed">Indicates whether database commits are suppressed.</param>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocType">The general journal document type.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer"; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; CommitIsSuppressed: Boolean; SalesHeader: Record "Sales Header"; DocType: enum "Gen. Journal Document Type")
    begin
    end;

    /// <summary>
    /// Raised before incrementing amounts during the rounding process.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="PrepmtInvLineBuf">The prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBuf">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufLCY">The total prepayment invoice line buffer in LCY.</param>
    [IntegrationEvent(false, false)]
    local procedure OnRoundAmountsOnBeforeIncrAmounts(SalesHeader: Record "Sales Header"; var PrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer"; var TotalPrepmtInvLineBufLCY: Record "Prepayment Inv. Line Buffer")
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales line during credit memo prepayment document update.
    /// </summary>
    /// <param name="SalesLine">The sales line to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesDocumentOnBeforeModifyCreditMemoSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales line during invoice prepayment document update.
    /// </summary>
    /// <param name="SalesLine">The sales line to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesDocumentOnBeforeModifyInvoiceSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after getting the remainder during VAT update on lines.
    /// </summary>
    /// <param name="VATAmountLineRemainder">The VAT amount line remainder.</param>
    /// <param name="RemainderExists">Indicates whether a remainder exists.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterGetRemainder(var VATAmountLineRemainder: Record "VAT Amount Line"; var RemainderExists: Boolean)
    begin
    end;

    /// <summary>
    /// Raised after getting the VAT amount line during VAT update on lines.
    /// </summary>
    /// <param name="VATAmountLine">The VAT amount line that was retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterVATAmountLineGet(var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    /// <summary>
    /// Raised before modifying the sales line during VAT update on lines.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The sales line to be modified.</param>
    /// <param name="TempVATAmountLineRemainder">The temporary VAT amount line remainder.</param>
    /// <param name="NewAmount">The new amount.</param>
    /// <param name="NewAmountIncludingVAT">The new amount including VAT.</param>
    /// <param name="NewVATBaseAmount">The new VAT base amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeSalesLineModify(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    /// <summary>
    /// Raised before throwing a preview error.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed in preview mode.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowPreviewError(SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before checking if the sales line is negative.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <param name="IsHandled">Set to true to skip the default negative check logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLineIsNegative(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before getting sales lines for prepayment processing.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice, Credit Memo, or Statistic).</param>
    /// <param name="ToSalesLine">The sales line record to populate.</param>
    /// <param name="IsHandled">Set to true to skip the default get sales lines logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLines(SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo",Statistic; var ToSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating prepayment amounts on sales lines.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="NewTotalPrepmtAmount">The new total prepayment amount.</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmountOnSaleslines(SalesHeader: Record "Sales Header"; NewTotalPrepmtAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before inserting to the sales line in the GetSalesLines procedure.
    /// </summary>
    /// <param name="ToSalesLine">The sales line to be inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetSalesLinesOnBeforeInsertToSalesLine(var ToSalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised before inserting posted headers in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeInsertPostedHeaders(var SalesHeader: Record "Sales Header");
    begin
    end;

    /// <summary>
    /// Raised after updating document numbers for prepayment posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header that was updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDocNos(var SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Raised before filling the invoice line buffer in the BuildInvLineBuffer procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SalesLine">The source sales line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBuildInvLineBufferOnBeforeFillInvLineBuffer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Raised after setting the posting description in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="PostingDescription">The posting description that was set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostingDescriptionSet(var SalesHeader: Record "Sales Header"; DocumentType: Option Invoice,"Credit Memo"; var PostingDescription: Text[100])
    begin
    end;

    /// <summary>
    /// Raised before the PostCustomerEntry procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="TotalPrepmtInvLineBuffer">The total prepayment invoice line buffer.</param>
    /// <param name="TotalPrepmtInvLineBufferLCY">The total prepayment invoice line buffer in LCY.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    /// <param name="PostingDescription">The posting description.</param>
    /// <param name="DocType">The general journal document type.</param>
    /// <param name="DocNo">The document number.</param>
    /// <param name="ExtDocNo">The external document number.</param>
    /// <param name="SrcCode">The source code.</param>
    /// <param name="PostingNoSeriesCode">The posting number series code.</param>
    /// <param name="CalcPmtDisc">Indicates whether to calculate payment discount.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="IsHandled">Set to true to skip the default customer entry posting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerEntryProcedure(var SalesHeader: Record "Sales Header"; TotalPrepmtInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary; TotalPrepmtInvLineBufferLCY: Record "Prepayment Inv. Line Buffer"; DocumentType: Option Invoice,"Credit Memo"; PostingDescription: Text[100]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; ExtDocNo: Text[35]; SrcCode: Code[10]; PostingNoSeriesCode: Code[20]; CalcPmtDisc: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before calculating the prepayment amount.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="DocumentType">The document type (Invoice, Credit Memo, or Statistic).</param>
    /// <param name="Result">The calculated prepayment amount.</param>
    /// <param name="IsHandled">Set to true to skip the default calculation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepmtAmount(var SalesLine: Record "Sales Line"; DocumentType: Option Invoice,"Credit Memo",Statistic; var Result: Decimal; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before inserting a VAT amount line in the InsertVATAmount procedure.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="VATAmountLine">The VAT amount line to be inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    /// <summary>
    /// Raised after setting filters in the FindVATAmountLine procedure.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="VATAmountLine">The VAT amount line with filters applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnFindVATAmountLineOnAfterSetFilters(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    /// <summary>
    /// Raised before checking the prepayment document in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="DocumentType">The document type (Invoice or Credit Memo).</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckPrepmtDoc(var SalesHeader: Record "Sales Header"; var DocumentType: Option Invoice,"Credit Memo")
    begin
    end;

    /// <summary>
    /// Raised after getting the prepayment account number from the general posting setup.
    /// </summary>
    /// <param name="GenPostingSetup">The general posting setup used to retrieve the account.</param>
    /// <param name="PrepmtAccNo">The prepayment account number that was retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepmtAccNo(GenPostingSetup: Record "General Posting Setup"; var PrepmtAccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raised after getting the correction balancing account number.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="PositiveAmount">Indicates whether the amount is positive.</param>
    /// <param name="BalAccNo">The balancing account number that was retrieved.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCorrBalAccNo(SalesHeader: Record "Sales Header"; PositiveAmount: Boolean; var BalAccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Raised after setting the source code in the Code procedure.
    /// </summary>
    /// <param name="SalesHeader">The sales header being processed.</param>
    /// <param name="SourceCodeSetup">The source code setup record.</param>
    /// <param name="SrcCode">The source code that was set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSetSourceCode(var SalesHeader: Record "Sales Header"; SourceCodeSetup: Record "Source Code Setup"; var SrcCode: Code[10])
    begin
    end;
}
