// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Navigate;

page 315 "VAT Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    AboutTitle = 'About VAT Entries';
    AboutText = 'Review and manage all VAT-related entries posted in the system, including amounts, dates, and document details, with the ability to correct VAT dates for open periods and ensure consistency across related transactions.';
    Permissions = TableData "VAT Entry" = m;
    SourceTable = "VAT Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = IsVATDateEditable;
                    Visible = IsVATDateEnabled;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(NonDeductibleVATBase; Rec."Non-Deductible VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field(NonDeductibleVATAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field("Unrealized Amount"; Rec."Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsUnrealizedVATEnabled;
                }
                field("Unrealized Base"; Rec."Unrealized Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsUnrealizedVATEnabled;
                }
                field("Remaining Unrealized Amount"; Rec."Remaining Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsUnrealizedVATEnabled;
                }
                field("Remaining Unrealized Base"; Rec."Remaining Unrealized Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsUnrealizedVATEnabled;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Additional-Currency Base"; Rec."Additional-Currency Base")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(NonDeductibleVATBaseACY; Rec."Non-Deductible VAT Base ACY")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field(NonDeductibleVATAmountACY; Rec."Non-Deductible VAT Amount ACY")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field(NonDedVATDiff; Rec."Non-Deductible VAT Diff.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = NonDeductibleVATVisible;
                }
                field("Add.-Curr. VAT Difference"; Rec."Add.-Curr. VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Calculation Type"; Rec."VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; Rec."Ship-to/Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Suite;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Closed by Entry No."; Rec."Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                SubPageLink = "Posting Date" = field("Posting Date"), "Document No." = field("Document No.");
            }
            part(GLEntriesPart; "G/L Entries Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Related G/L Entries';
                ShowFilter = false;
                SubPageLink = "Posting Date" = field("Posting Date"), "Document No." = field("Document No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnBeforeActionNavigate(Rec, IsHandled);
                    if IsHandled then
                        exit;

                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
            action(SetGLAccountNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set G/L Account No.';
                Image = AdjustEntries;
                ToolTip = 'Fill the G/L Account No. field in VAT entries that are linked to G/L entries.';

                trigger OnAction()
                var
                    VATEntry: Record "VAT Entry";
                    Window: Dialog;
                    BucketIndex: Integer;
                    SizeOfBucket: Integer;
                    LastEntryNo: Integer;
                    NoOfBuckets: Integer;
                begin
                    SizeOfBucket := 1000;

                    if not VATEntry.FindLast() then
                        exit;

                    Window.Open(AdjustTitleMsg + ProgressMsg);

                    LastEntryNo := VATEntry."Entry No.";
                    NoOfBuckets := LastEntryNo div SizeOfBucket + 1;

                    for BucketIndex := 1 to NoOfBuckets do begin
                        VATEntry.SetRange("Entry No.", (BucketIndex - 1) * SizeOfBucket, BucketIndex * SizeOfBucket);
                        VATEntry.SetGLAccountNo(false);
                        Commit();
                        Window.Update(2, Round(BucketIndex / NoOfBuckets * 10000, 1));
                    end;

                    Window.Close();
                end;
            }
            group(IncomingDocument)
            {
                Caption = 'Incoming Document';
                Image = Documents;
                action(IncomingDocCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View Incoming Document';
                    Enabled = HasIncomingDocument;
                    Image = ViewOrder;
                    ToolTip = 'View any incoming document records and file attachments that exist for the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.ShowCard(Rec."Document No.", Rec."Posting Date");
                    end;
                }
                action(SelectIncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Incoming Document';
                    Enabled = not HasIncomingDocument;
                    Image = SelectLineToApply;
                    ToolTip = 'Select an incoming document record and file attachment that you want to link to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.SelectIncomingDocumentForPostedDocument(Rec."Document No.", Rec."Posting Date", Rec.RecordId);
                    end;
                }
                action(IncomingDocAttachFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Incoming Document from File';
                    Ellipsis = true;
                    Enabled = not HasIncomingDocument;
                    Image = Attach;
                    ToolTip = 'Create an incoming document record by selecting a file to attach, and then link the incoming document record to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    begin
                        IncomingDocumentAttachment.NewAttachmentFromPostedDocument(Rec."Document No.", Rec."Posting Date");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        HasIncomingDocument := IncomingDocument.PostedDocExists(Rec."Document No.", Rec."Posting Date");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"VAT Entry - Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
    begin
        if GeneralLedgerSetup.Get() then
            IsUnrealizedVATEnabled := GeneralLedgerSetup."Unrealized VAT" or GeneralLedgerSetup."Prepayment Unrealized VAT";
        IsVATDateEditable := VATReportingDateMgt.IsVATDateModifiable();
        IsVATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        NonDeductibleVATVisible := NonDeductibleVAT.IsNonDeductibleVATEnabled();
    end;

    var
        Navigate: Page Navigate;
        HasIncomingDocument: Boolean;
        IsUnrealizedVATEnabled: Boolean;
        IsVATDateEditable: Boolean;
        IsVATDateEnabled: Boolean;
        NonDeductibleVATVisible: Boolean;
        AdjustTitleMsg: Label 'Adjust G/L account number in VAT entries.\';
        ProgressMsg: Label 'Processed: @2@@@@@@@@@@@@@@@@@\';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeActionNavigate(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean)
    begin
    end;
}

