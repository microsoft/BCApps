// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.API.Upgrade;

codeunit 5011 "Graph Mgt - Vendor Payments"
{
    trigger OnRun()
    begin
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";

    procedure SetVendorPaymentsTemplateAndBatch(var GenJournalLine: Record "Gen. Journal Line"; VendorPaymentBatchName: Code[10])
    begin
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultVendorPaymentsTemplateName());
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", VendorPaymentBatchName);
        GenJournalLine.SetRange("Journal Batch Name", VendorPaymentBatchName);
    end;

    procedure SetVendorPaymentsFilters(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultVendorPaymentsTemplateName());
    end;

    procedure SetVendorPaymentsValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
    begin
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);
        GraphMgtJournalLines.SetPaymentsValues(GenJournalLine, TempGenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds();
    end;

    procedure UpdateIds()
    begin
        UpdateIds(false);
    end;

    procedure UpdateIds(WithCommit: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);

        if GenJournalLine.FindSet() then begin
            repeat
                GenJournalLine.UpdateVendorID();
                GenJournalLine.UpdateAppliesToInvoiceID();
                GenJournalLine.UpdateJournalBatchID();
                GenJournalLine.Modify(false);
                if WithCommit then
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until GenJournalLine.Next() = 0;

            if WithCommit then
                Commit();
        end;
    end;
}