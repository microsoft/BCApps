#pragma warning disable AA0247
codeunit 355 "Local Navigate Handler"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedFADocHeader: Record "Posted FA Doc. Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GenJnlPostedLine: Record "Gen. Journal Line Archive";
        [SecurityFiltering(SecurityFilter::Filtered)]
        VATLedgLineSales: Record "VAT Ledger Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        VATLedgLinePurch: Record "VAT Ledger Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLCorrEntry: Record "G/L Correspondence Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if GLCorrEntry.ReadPermission() then begin
            SetGLCorrEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"G/L Correspondence Entry", GLCorrEntry.TableCaption(), GLCorrEntry.Count);
        end;
        if GenJnlPostedLine.ReadPermission() then begin
            SetGenJnlPostedLineFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"Gen. Journal Line Archive", GenJnlPostedLine.TableCaption(), GenJnlPostedLine.Count);
        end;
        if PostedFADocHeader.ReadPermission() then begin
            SetPostedFADocHeaderFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"Posted FA Doc. Header", PostedFADocHeader.TableCaption(), PostedFADocHeader.Count);
        end;
        if VATLedgLinePurch.ReadPermission() then begin
            SetVATLedgLinePurchFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"VAT Ledger Line", VATLedgLinePurch.TableCaption(), VATLedgLinePurch.Count);
        end;
        if VATLedgLineSales.ReadPermission() then begin
            SetVATLedgLineSalesFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"VAT Ledger Line", VATLedgLineSales.TableCaption(), VATLedgLineSales.Count);
        end;
        if TaxDiffLedgerEntry.ReadPermission() then begin
            SetTaxDiffLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"Tax Diff. Ledger Entry", TaxDiffLedgerEntry.TableCaption(), TaxDiffLedgerEntry.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"G/L Correspondence Entry":
                begin
                    SetGLCorrEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, GLCorrEntry);
                end;
            Database::"Gen. Journal Line Archive":
                begin
                    SetGenJnlPostedLineFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, GenJnlPostedLine);
                end;
            Database::"Posted FA Doc. Header":
                begin
                    SetPostedFADocHeaderFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, PostedFADocHeader);
                end;
            Database::"VAT Ledger Line":
                begin
                    SetVATLedgLinePurchFilters(DocNoFilter, PostingDateFilter);
                    if VATLedgLinePurch.FindFirst() then
                        PAGE.Run(PAGE::"VAT Purchase Ledger Subform", VATLedgLinePurch);
                    SetVATLedgLineSalesFilters(DocNoFilter, PostingDateFilter);
                    if VATLedgLineSales.FindFirst() then
                        PAGE.Run(PAGE::"VAT Sales Ledger Subform", VATLedgLineSales);
                end;
            Database::"Tax Diff. Ledger Entry":
                begin
                    SetTaxDiffLedgerEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, TaxDiffLedgerEntry);
                end;
        end;
    end;

    local procedure SetGLCorrEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        GLCorrEntry.Reset();
        GLCorrEntry.SetCurrentKey("Document No.", "Posting Date");
        GLCorrEntry.SetFilter("Document No.", DocNoFilter);
        GLCorrEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetGenJnlPostedLineFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        GenJnlPostedLine.Reset();
        GenJnlPostedLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
        GenJnlPostedLine.SetFilter("Document No.", DocNoFilter);
        GenJnlPostedLine.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetPostedFADocHeaderFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        PostedFADocHeader.Reset();
        PostedFADocHeader.SetFilter("No.", DocNoFilter);
        PostedFADocHeader.SetFilter("FA Posting Date", PostingDateFilter);
    end;

    local procedure SetVATLedgLinePurchFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        VATLedgLinePurch.Reset();
        VATLedgLinePurch.SetCurrentKey("Document No.", "Document Date");
        VATLedgLinePurch.SetFilter("Document No.", DocNoFilter);
        VATLedgLinePurch.SetFilter("Document Date", PostingDateFilter);
        VATLedgLinePurch.SetRange(Type, VATLedgLinePurch.Type::Purchase);
    end;

    local procedure SetVATLedgLineSalesFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        VATLedgLineSales.Reset();
        VATLedgLineSales.SetCurrentKey("Document No.", "Document Date");
        VATLedgLineSales.SetFilter("Document No.", DocNoFilter);
        VATLedgLineSales.SetFilter("Document Date", PostingDateFilter);
        VATLedgLineSales.SetRange(Type, VATLedgLineSales.Type::Sales);
    end;

    local procedure SetTaxDiffLedgerEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        TaxDiffLedgerEntry.Reset();
        TaxDiffLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        TaxDiffLedgerEntry.SetFilter("Document No.", DocNoFilter);
        TaxDiffLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
    end;
}
