// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 134 "Posted Docs. With No Inc. Buf."
{
    Caption = 'Posted Docs. With No Inc. Buf.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(4; "First Posting Description"; Text[100])
        {
            Caption = 'First Posting Description';
            DataClassification = SystemMetadata;
        }
        field(5; "Incoming Document No."; Integer)
        {
            CalcFormula = lookup("Incoming Document"."Entry No." where("Document No." = field("Document No."),
                                                                        "Posting Date" = field("Posting Date")));
            Caption = 'Incoming Document No.';
            FieldClass = FlowField;
        }
        field(8; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(10; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(11; "G/L Account No. Filter"; Code[20])
        {
            Caption = 'G/L Account No. Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        OnlyFirst1000Msg: Label 'There are more than 1000 document numbers within the filter. Only the first 1000 are shown. Narrow your filter to get fewer document numbers.';
        AlreadyAssignedIncomingDocErr: Label 'This document no. and date already has an incoming document.';
        AlreadyIncomingDocErr: Label 'The specified incoming document no. has already been used for %1 %2.', Comment = '%1=document type, %2=document no., e.g. Invoice 1234.';

    procedure GetDocNosWithoutIncomingDoc(var PostedDocsWithNoIncBuf: Record "Posted Docs. With No Inc. Buf."; DateFilter: Text; DocNoFilter: Code[250]; GLAccFilter: Code[250]; ExternalDocNoFilter: Code[250])
    var
        PostedDocsWithNoIncDocQry: Query "Posted Docs. With No Inc. Doc.";
        NextNo: Integer;
        TableFilters: Text;
    begin
        TableFilters := PostedDocsWithNoIncBuf.GetView();
        PostedDocsWithNoIncBuf.Reset();
        PostedDocsWithNoIncBuf.DeleteAll();
        PostedDocsWithNoIncBuf.Init();
        if DateFilter <> '' then
            PostedDocsWithNoIncDocQry.SetFilter(PostingDate, DateFilter);

        if DocNoFilter <> '' then
            PostedDocsWithNoIncDocQry.SetFilter(DocumentNo, DocNoFilter);

        if GLAccFilter <> '' then
            PostedDocsWithNoIncDocQry.SetFilter(GLAccount, GLAccFilter);

        if ExternalDocNoFilter <> '' then
            PostedDocsWithNoIncDocQry.SetFilter(ExternalDocumentNo, ExternalDocNoFilter);

        if PostedDocsWithNoIncDocQry.Open() then
            while PostedDocsWithNoIncDocQry.Read() do begin
                NextNo += 1;
                if NextNo >= 1000 then begin
                    Message(OnlyFirst1000Msg);
                    exit;
                end;
                PostedDocsWithNoIncBuf."Line No." := NextNo;
                PostedDocsWithNoIncBuf."Document No." := PostedDocsWithNoIncDocQry.DocumentNo;
                PostedDocsWithNoIncBuf."Posting Date" := PostedDocsWithNoIncDocQry.PostingDate;
                PostedDocsWithNoIncBuf."First Posting Description" :=
                  GetFirstPostingDescription(PostedDocsWithNoIncBuf."Document No.", PostedDocsWithNoIncBuf."Posting Date", GLAccFilter);
                PostedDocsWithNoIncBuf."External Document No." := PostedDocsWithNoIncDocQry.ExternalDocumentNo;
                PostedDocsWithNoIncBuf."Debit Amount" := PostedDocsWithNoIncDocQry.DebitAmount;
                PostedDocsWithNoIncBuf."Credit Amount" := PostedDocsWithNoIncDocQry.CreditAmount;
                PostedDocsWithNoIncBuf.Insert();
            end;
        PostedDocsWithNoIncBuf.Reset();
        PostedDocsWithNoIncBuf.SetView(TableFilters);
    end;

    procedure UpdateIncomingDocuments()
    var
        IncomingDocument: Record "Incoming Document";
        PostedDocsWithNoIncBuf: Record "Posted Docs. With No Inc. Buf.";
        IncomingDocuments: Page "Incoming Documents";
        IsPosted: Boolean;
    begin
        CalcFields("Incoming Document No.");
        if "Incoming Document No." > 0 then
            Error(AlreadyAssignedIncomingDocErr);
        PostedDocsWithNoIncBuf := Rec;
        IncomingDocument.SetRange(Posted, false);
        IncomingDocuments.SetTableView(IncomingDocument);
        IncomingDocuments.LookupMode(true);
        if IncomingDocuments.RunModal() = ACTION::LookupOK then begin
            IncomingDocuments.GetRecord(IncomingDocument);
            CheckIfAssignedToUnpostedDoc(IncomingDocument."Entry No.");
            CODEUNIT.Run(CODEUNIT::"Release Incoming Document", IncomingDocument);
            IncomingDocument.SetPostedDocFields("Posting Date", "Document No.");
            IncomingDocument."Document Type" := IncomingDocument.GetRelatedDocType("Posting Date", "Document No.", IsPosted);
        end;
        Rec := PostedDocsWithNoIncBuf;
        if Find('=<>') then;
    end;

    local procedure GetFirstPostingDescription(DocumentNo: Code[20]; PostingDate: Date; GLAccFilter: Text): Text[100]
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLAccFilter <> '' then
            GLEntry.SetFilter("G/L Account No.", GLAccFilter);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetFilter(Description, '<>%1', '');
        if GLEntry.FindFirst() then
            exit(GLEntry.Description);
        exit('');
    end;

    local procedure CheckIfAssignedToUnpostedDoc(IncomingDocEntryNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingDocEntryNo);
        if PurchaseHeader.FindFirst() then
            Error(AlreadyIncomingDocErr, PurchaseHeader."Document Type", PurchaseHeader."No.");
        SalesHeader.SetRange("Incoming Document Entry No.", IncomingDocEntryNo);
        if SalesHeader.FindFirst() then
            Error(AlreadyIncomingDocErr, SalesHeader."Document Type", SalesHeader."No.");
        GenJournalLine.SetRange("Incoming Document Entry No.", IncomingDocEntryNo);
        if GenJournalLine.FindFirst() then
            Error(AlreadyIncomingDocErr, GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name");
    end;
}
