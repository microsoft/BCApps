// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;

/// <summary>
/// List page for viewing and managing VAT entries with comprehensive filtering and navigation capabilities.
/// Provides access to VAT entry details, related documents, and G/L account adjustment functionality for audit and compliance.
/// </summary>
/// <remarks>
/// Primary interface for VAT ledger analysis with support for unrealized VAT, non-deductible VAT, and multi-currency display.
/// Integrates with navigation for finding related documents and supports incoming document management.
/// </remarks>
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
                    ToolTip = 'Specifies the VAT date on the VAT entry. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
                    Visible = false;
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
                field("Operation Occurred Date"; Rec."Operation Occurred Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the operation occurred date.';
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
                field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if you want to include the entry in the VAT transaction report.';
                }
                field("Refers To Period"; Rec."Refers To Period")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the period of time that is used to group and filter the transaction.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Related Entry No."; Rec."Related Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor ledger entry that identifies the related document associated with the purchase.';
                    Visible = false;
                }
                field(NonDeductibleVATBase; Rec."Non-Deductible VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';
                    Visible = false;
                }
                field(NonDeductibleVATAmount; Rec."Non-Deductible VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is not applied, due to the type of goods or services purchased.';
                    Visible = false;
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
                    ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased. The amount is in the additional reporting currency.';
                    Visible = false;
                }
                field(NonDeductibleVATAmountACY; Rec."Non-Deductible VAT Amount ACY")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is not applied, due to the type of goods or services purchased. The amount is in the additional reporting currency.';
                    Visible = false;
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
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the company''s primary activity.';
                }
                field("Service Tariff No."; Rec."Service Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the service tariff associated with the VAT entry.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transport method for the VAT entry.';
                }
                field("Payment Method"; Rec."Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method codes that can be applied to the VAT entry.';
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
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Nondeductible Amount"; Rec."Nondeductible Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT that is not deducted due to the type of goods or services purchased.';
                    Visible = false;
                }
                field("Nondeductible Base"; Rec."Nondeductible Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the transaction for which VAT is not applied, due to the type of goods or services purchased.';
                    Visible = false;
                }
                field("Tax Representative Type"; Rec."Tax Representative Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax representative is a customer, contact, or vendor.';
                    Visible = false;
                }
                field("Tax Representative No."; Rec."Tax Representative No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax representative for the transaction that created this VAT entry.';
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
    begin
        if GeneralLedgerSetup.Get() then
            IsUnrealizedVATEnabled := GeneralLedgerSetup."Unrealized VAT" or GeneralLedgerSetup."Prepayment Unrealized VAT";
    end;

    var
        Navigate: Page Navigate;
        HasIncomingDocument: Boolean;
        IsUnrealizedVATEnabled: Boolean;
        AdjustTitleMsg: Label 'Adjust G/L account number in VAT entries.\';
        ProgressMsg: Label 'Processed: @2@@@@@@@@@@@@@@@@@\';

    /// <summary>
    /// Integration event raised before executing the Navigate action for finding related entries and documents.
    /// Enables custom navigation logic or additional processing before standard navigation begins.
    /// </summary>
    /// <param name="VATEntry">VAT entry record for which navigation is being performed</param>
    /// <param name="IsHandled">Set to true to skip standard navigation processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeActionNavigate(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean)
    begin
    end;
}

