// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Bank.Payment;
using Microsoft.Finance.WithholdingTax;

codeunit 12115 "WHT Navigate Handler IT"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ComputedContribution: Record "Computed Contribution";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Contributions: Record Contributions;
        [SecurityFiltering(SecurityFilter::Filtered)]
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WithholdingTax: Record "Withholding Tax";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if ComputedContribution.ReadPermission then begin
            SetComputedContributionFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Computed Contribution", ComputedContribution.TableCaption(), ComputedContribution.Count);
        end;
        if Contributions.ReadPermission then begin
            SetContributionsFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::Contributions, Contributions.TableCaption(), Contributions.Count);
        end;
        if ComputedWithholdingTax.ReadPermission then begin
            SetComputedWithholdingTaxFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Computed Withholding Tax", ComputedWithholdingTax.TableCaption(), ComputedWithholdingTax.Count);
        end;
        if WithholdingTax.ReadPermission then begin
            SetWithholdingTaxFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Withholding Tax", WithholdingTax.TableCaption(), WithholdingTax.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
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
        end;
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

}
