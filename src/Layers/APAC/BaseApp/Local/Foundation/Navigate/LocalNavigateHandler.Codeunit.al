// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.WithholdingTax;

codeunit 355 "Local Navigate Handler"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GSTPurchEntry: Record "GST Purchase Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        GSTSalesEntry: Record "GST Sales Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WHTEntry: Record "WHT Entry";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if GSTPurchEntry.ReadPermission() then begin
            SetGSTPurchEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"GST Purchase Entry", GSTPurchEntry.TableCaption(), GSTPurchEntry.Count);
        end;
        if GSTSalesEntry.ReadPermission() then begin
            SetGSTSalesEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"GST Sales Entry", GSTSalesEntry.TableCaption(), GSTSalesEntry.Count);
        end;
        if WHTEntry.ReadPermission() then begin
            SetWHTEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"WHT Entry", WHTEntry.TableCaption(), WHTEntry.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"GST Purchase Entry":
                begin
                    SetGSTPurchEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, GSTPurchEntry);
                end;
            Database::"GST Sales Entry":
                begin
                    SetGSTSalesEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, GSTSalesEntry);
                end;
            Database::"WHT Entry":
                begin
                    SetWHTEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, WHTEntry);
                end;
        end;
    end;

    local procedure SetGSTPurchEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        GSTPurchEntry.Reset();
        GSTPurchEntry.SetCurrentKey("Document No.", "Posting Date");
        GSTPurchEntry.SetFilter("Document No.", DocNoFilter);
        GSTPurchEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetGSTSalesEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        GSTSalesEntry.Reset();
        GSTSalesEntry.SetCurrentKey("Document No.", "Posting Date");
        GSTSalesEntry.SetFilter("Document No.", DocNoFilter);
        GSTSalesEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetWHTEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        WHTEntry.Reset();
        WHTEntry.SetCurrentKey("Document No.", "Posting Date");
        WHTEntry.SetFilter("Document No.", DocNoFilter);
        WHTEntry.SetFilter("Posting Date", PostingDateFilter);
    end;
}
