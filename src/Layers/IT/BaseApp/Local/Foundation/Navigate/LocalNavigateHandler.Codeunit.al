// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.WithholdingTax;

codeunit 355 "Local Navigate Handler"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        VATBookEntry: Record "VAT Book Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLBookEntry: Record "GL Book Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WithholdingTax: Record "Withholding Tax";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ComputedContribution: Record "Computed Contribution";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Contributions: Record Contributions;
        [SecurityFiltering(SecurityFilter::Filtered)]
        IssuedCustBillHeader: Record "Issued Customer Bill Header";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if GLBookEntry.ReadPermission then begin
            SetGLBookEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"GL Book Entry", GLBookEntry.TableCaption(), GLBookEntry.Count);
        end;
        if VATBookEntry.ReadPermission then begin
            SetVATBookEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"VAT Book Entry", VATBookEntry.TableCaption(), VATBookEntry.Count);
        end;
        if ComputedWithholdingTax.ReadPermission then begin
            SetComputedWithholdingTaxFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Computed Withholding Tax", ComputedWithholdingTax.TableCaption(), ComputedWithholdingTax.Count);
        end;
        if WithholdingTax.ReadPermission then begin
            SetWithholdingTaxFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Withholding Tax", WithholdingTax.TableCaption(), WithholdingTax.Count);
        end;
        if ComputedContribution.ReadPermission then begin
            SetComputedContributionFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Computed Contribution", ComputedContribution.TableCaption(), ComputedContribution.Count);
        end;
        if Contributions.ReadPermission then begin
            SetContributionsFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::Contributions, Contributions.TableCaption(), Contributions.Count);
        end;
        if IssuedCustBillHeader.ReadPermission then begin
            SetIssuedCustBillHeaderFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Issued Customer Bill Header", IssuedCustBillHeader.TableCaption(), IssuedCustBillHeader.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"GL Book Entry":
                begin
                    SetGLBookEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, GLBookEntry);
                end;
            Database::"VAT Book Entry":
                begin
                    SetVATBookEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, VATBookEntry);
                end;
            Database::"Computed Withholding Tax":
                begin
                    SetComputedWithholdingTaxFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, ComputedWithholdingTax);
                end;
            Database::"Withholding Tax":
                begin
                    SetWithholdingTaxFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, WithholdingTax);
                end;
            Database::"Computed Contribution":
                begin
                    SetComputedContributionFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, ComputedContribution);
                end;
            Database::Contributions:
                begin
                    SetContributionsFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, Contributions);
                end;
            Database::"Issued Customer Bill Header":
                begin
                    SetIssuedCustBillHeaderFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, IssuedCustBillHeader);
                end;
        end;
    end;

    local procedure SetGLBookEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        GLBookEntry.Reset();
        GLBookEntry.SetCurrentKey("Document No.", "Posting Date");
        GLBookEntry.SetFilter("Document No.", DocNoFilter);
        GLBookEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetVATBookEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        VATBookEntry.Reset();
        VATBookEntry.SetCurrentKey("Document No.", "Posting Date");
        VATBookEntry.SetFilter("Document No.", DocNoFilter);
        VATBookEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetComputedWithholdingTaxFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        ComputedWithholdingTax.Reset();
        ComputedWithholdingTax.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
        ComputedWithholdingTax.SetFilter("Document No.", DocNoFilter);
        ComputedWithholdingTax.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetWithholdingTaxFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        WithholdingTax.Reset();
        WithholdingTax.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
        WithholdingTax.SetFilter("Document No.", DocNoFilter);
        WithholdingTax.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetComputedContributionFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        ComputedContribution.Reset();
        ComputedContribution.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
        ComputedContribution.SetFilter("Document No.", DocNoFilter);
        ComputedContribution.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetContributionsFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        Contributions.Reset();
        Contributions.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
        Contributions.SetFilter("Document No.", DocNoFilter);
        Contributions.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetIssuedCustBillHeaderFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        IssuedCustBillHeader.Reset();
        IssuedCustBillHeader.SetCurrentKey("Posting Date", "No.");
        IssuedCustBillHeader.SetFilter("No.", DocNoFilter);
        IssuedCustBillHeader.SetFilter("Posting Date", PostingDateFilter);
    end;
}
