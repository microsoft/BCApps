// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Vendor;
using System.Security.User;
using System.Utilities;

page 624 "Unapply Vendor Entries"
{
    Caption = 'Unapply Vendor Entries';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Detailed Vendor Ledg. Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DocuNo; DocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number that will be assigned to the entries that will be created when you click Unapply.';
                }
                field(PostDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date that will be assigned to the general ledger entries that will be created when you click Unapply.';
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Initial Document Type"; Rec."Initial Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(DocumentNo; GetDocumentNo())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Initial Document No.';
                    ToolTip = 'Specifies the number of the document for which the entry is unapplied.';
                }
                field("Initial Entry Global Dim. 1"; Rec."Initial Entry Global Dim. 1")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Initial Entry Global Dim. 2"; Rec."Initial Entry Global Dim. 2")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Debit Amount (LCY)"; Rec."Debit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Credit Amount (LCY)"; Rec."Credit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
                    Visible = false;
                }
                field("Initial Entry Due Date"; Rec."Initial Entry Due Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "User Lookup";
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Vendor Ledger Entry No."; Rec."Vendor Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Unapply)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Unapply';
                Image = UnApply;
                ToolTip = 'Unselect one or more ledger entries that you want to unapply this record.';

                trigger OnAction()
                var
                    VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if Rec.IsEmpty() then
                        Error(Text010);
                    if not ConfirmManagement.GetResponseOrDefault(Text011, true) then
                        exit;

                    ApplyUnapplyParameters."Document No." := DocNo;
                    ApplyUnapplyParameters."Posting Date" := PostingDate;
                    VendEntryApplyPostedEntries.PostUnApplyVendor(DtldVendLedgEntry2, ApplyUnapplyParameters);
                    PostingDate := 0D;
                    DocNo := '';
                    Rec.DeleteAll();
                    Message(Text009);

                    CurrPage.Close();
                end;
            }
            action(Preview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview Unapply';
                Image = ViewPostedOrder;
                ToolTip = 'Preview how unapplying one or more ledger entries will look like.';

                trigger OnAction()
                var
                    VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
                begin
                    if Rec.IsEmpty() then
                        Error(Text010);

                    ApplyUnapplyParameters."Document No." := DocNo;
                    ApplyUnapplyParameters."Posting Date" := PostingDate;
                    VendEntryApplyPostedEntries.PreviewUnapply(DtldVendLedgEntry2, ApplyUnapplyParameters);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Unapply_Promoted; Unapply)
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        InsertEntries();
    end;

    var
#pragma warning disable AA0074
        Text009: Label 'The entries were successfully unapplied.';
        Text010: Label 'There is nothing to unapply.';
        Text011: Label 'To unapply these entries, correcting entries will be posted.\Do you want to unapply the entries?';
#pragma warning restore AA0074

    protected var
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        Vend: Record Vendor;
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        DocNo: Code[20];
        PostingDate: Date;
        VendLedgEntryNo: Integer;

    procedure SetDtldVendLedgEntry(EntryNo: Integer)
    begin
        DtldVendLedgEntry2.Get(EntryNo);
        VendLedgEntryNo := DtldVendLedgEntry2."Vendor Ledger Entry No.";
        PostingDate := DtldVendLedgEntry2."Posting Date";
        DocNo := DtldVendLedgEntry2."Document No.";
        Vend.Get(DtldVendLedgEntry2."Vendor No.");
    end;

    local procedure InsertEntries()
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        if DtldVendLedgEntry2."Transaction No." = 0 then begin
            DtldVendLedgEntry.SetCurrentKey("Application No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Application No.", DtldVendLedgEntry2."Application No.");
        end else begin
            DtldVendLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DtldVendLedgEntry.SetRange("Transaction No.", DtldVendLedgEntry2."Transaction No.");
        end;
        DtldVendLedgEntry.SetRange("Vendor No.", DtldVendLedgEntry2."Vendor No.");
        Rec.DeleteAll();
        if DtldVendLedgEntry.Find('-') then
            repeat
                if (DtldVendLedgEntry."Entry Type" <> DtldVendLedgEntry."Entry Type"::"Initial Entry") and
                   not DtldVendLedgEntry.Unapplied
                then begin
                    Rec := DtldVendLedgEntry;
                    OnBeforeRecInsert(Rec, DtldVendLedgEntry, DtldVendLedgEntry2);
                    Rec.Insert();
                end;
            until DtldVendLedgEntry.Next() = 0;
    end;

    local procedure GetDocumentNo(): Code[20]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgEntry.Get(Rec."Vendor Ledger Entry No.") then;
        exit(VendLedgEntry."Document No.");
    end;

    procedure Caption(): Text
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        exit(StrSubstNo(
            '%1 %2 %3 %4',
            Vend."No.",
            Vend.Name,
            VendLedgEntry.FieldCaption("Entry No."),
            VendLedgEntryNo));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecInsert(var RecDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
    end;
}

