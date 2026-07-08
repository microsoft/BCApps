// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Finance.WithholdingTax;

codeunit 12115 "WHT Navigate Handler IT"
{
    var
        ComputedWithholdingTax: Record "Computed Withholding Tax";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WithholdingTax: Record "Withholding Tax";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
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
