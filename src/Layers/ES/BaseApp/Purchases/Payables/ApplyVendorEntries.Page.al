// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.CRM.Outlook;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

page 233 "Apply Vendor Entries"
{
    Caption = 'Apply Vendor Entries';
    DataCaptionFields = "Vendor No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Vendor Ledger Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("ApplyingVendLedgEntry.""Posting Date"""; TempApplyingVendLedgEntry."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the entry to be applied. This date is used to find the correct exchange rate when applying entries in different currencies.';
                }
                field("ApplyingVendLedgEntry.""Document Type"""; TempApplyingVendLedgEntry."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type of the entry to be applied.';
                }
                field("ApplyingVendLedgEntry.""Document No."""; TempApplyingVendLedgEntry."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
                field(ApplyingVendorNo; TempApplyingVendLedgEntry."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor No.';
                    Editable = false;
                    ToolTip = 'Specifies the vendor number of the entry to be applied.';
                    Visible = false;
                }
                field(ApplyingVendorName; TempApplyingVendLedgEntry."Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    Editable = false;
                    ToolTip = 'Specifies the vendor name of the entry to be applied.';
                    Visible = VendNameVisible;
                }
                field(ApplyingDescription; TempApplyingVendLedgEntry.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the entry to be applied.';
                    Visible = false;
                }
                field("ApplyingVendLedgEntry.""Currency Code"""; TempApplyingVendLedgEntry."Currency Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';
                }
                field("ApplyingVendLedgEntry.Amount"; TempApplyingVendLedgEntry.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
                field("ApplyingVendLedgEntry.""Remaining Amount"""; TempApplyingVendLedgEntry."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be applied.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(AppliesToID; Rec."Applies-to ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = AppliesToIDVisible;

                    trigger OnValidate()
                    begin
                        if Rec."Applies-to ID" = xRec."Applies-to ID" then
                            exit;

                        if (CalcType = CalcType::"Gen. Jnl. Line") and (ApplnType = ApplnType::"Applies-to Doc. No.") then
                            Error(CannotSetAppliesToIDErr);

                        SetVendApplId(true);
                        Rec.Get(Rec."Entry No.");
                        if Rec."Applies-to ID" <> '' then
                            UpdateCustomAppliesToIDForGenJournal(Rec."Applies-to ID");

                        CurrPage.Update(false);
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the document type that the vendor entry belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the vendor entry''s document number.';
                }
                field("Bill No."; Rec."Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bill number related to the vendor ledger entry.';
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Document Situation"; Rec."Document Situation")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document location.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the vendor account that the entry is linked to.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the vendor account that the entry is linked to.';
                    Visible = VendNameVisible;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the vendor entry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the original entry.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry.';
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("CalcApplnRemainingAmount(""Remaining Amount"")"; CalcApplnRemainingAmount(Rec."Remaining Amount"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Remaining Amount';
                    ToolTip = 'Specifies the amount that remains to be applied to before the entry is totally applied to.';
                }
                field("Amount to Apply"; Rec."Amount to Apply")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount to apply.';

                    trigger OnValidate()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", Rec);

                        if (xRec."Amount to Apply" = 0) or (Rec."Amount to Apply" = 0) and
                           ((ApplnType = ApplnType::"Applies-to ID") or (CalcType = CalcType::Direct))
                        then
                            SetVendApplId(false);
                        Rec.Get(Rec."Entry No.");
                        AmountToApplyOnAfterValidate();
                    end;
                }
                field(ApplnAmountToApply; CalcApplnAmountToApply(Rec."Amount to Apply"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Amount to Apply';
                    ToolTip = 'Specifies the amount to apply.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the due date on the entry.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';

                    trigger OnValidate()
                    begin
                        RecalcApplnAmount();
                    end;
                }
                field("Pmt. Disc. Tolerance Date"; Rec."Pmt. Disc. Tolerance Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest date the amount in the entry must be paid in order for payment discount tolerance to be granted.';
                }
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment of the purchase invoice.';
                }
                field("Original Pmt. Disc. Possible"; Rec."Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount that you can obtain if the entry is applied to before the payment discount date.';
                    Visible = false;
                }
                field("Remaining Pmt. Disc. Possible"; Rec."Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining payment discount which can be received if the payment is made before the payment discount date.';

                    trigger OnValidate()
                    begin
                        RecalcApplnAmount();
                    end;
                }
                field("Pmt. Disc. Rcd.(LCY)"; Rec."Pmt. Disc. Rcd.(LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount that has been received, in LCY.';
                }
                field("CalcApplnRemainingAmount(""Remaining Pmt. Disc. Possible"")"; CalcApplnRemainingAmount(Rec."Remaining Pmt. Disc. Possible"))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = ApplnCurrencyCode;
                    AutoFormatType = 1;
                    Caption = 'Appln. Pmt. Disc. Possible';
                    ToolTip = 'Specifies the discount that you can obtain if the entry is applied to before the payment discount date.';
                }
                field("Max. Payment Tolerance"; Rec."Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum tolerated amount the entry can differ from the amount on the invoice or credit memo.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the amount on the entry has been fully paid or there is still a remaining amount that must be applied to.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the entry to be applied is positive.';
                }
                field("Remit-to Code"; Rec."Remit-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address for the remit-to code.';
                    Visible = true;
                    TableRelation = "Remit Address".Code where("Vendor No." = field("Vendor No."));
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
            }
            group(Control41)
            {
                ShowCaption = false;
                fixed(Control1903222401)
                {
                    ShowCaption = false;
                    group("Appln. Currency")
                    {
                        Caption = 'Appln. Currency';
                        field(ApplnCurrencyCode; ApplnCurrencyCode)
                        {
                            ApplicationArea = Suite;
                            Editable = false;
                            ShowCaption = false;
                            TableRelation = Currency;
                            ToolTip = 'Specifies the currency code that the amount will be applied in, in case of different currencies.';
                        }
                    }
                    group(Control1900545201)
                    {
                        Caption = 'Amount to Apply';
                        field(AmountToApply; AppliedAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Amount to Apply';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts on all the selected vendor ledger entries that will be applied by the entry shown in the Available Amount field. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Pmt. Disc. Amount")
                    {
                        Caption = 'Pmt. Disc. Amount';
                        field(PmtDiscountAmount; -PmtDiscAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Amount';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the payment discount amounts granted on all the selected vendor ledger entries that will be applied by the entry shown in the Available Amount field. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group(Rounding)
                    {
                        Caption = 'Rounding';
                        field(ApplnRounding; ApplnRounding)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Rounding';
                            Editable = false;
                            ToolTip = 'Specifies the rounding difference when you apply entries in different currencies to one another. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Applied Amount")
                    {
                        Caption = 'Applied Amount';
                        field(AppliedAmount; AppliedAmount + (-PmtDiscAmount) + ApplnRounding)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Applied Amount';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the amounts in the Amount to Apply field, Pmt. Disc. Amount field, and the Rounding. The amount is in the currency represented by the code in the Currency Code field.';
                        }
                    }
                    group("Available Amount")
                    {
                        Caption = 'Available Amount';
                        field(ApplyingAmount; ApplyingAmount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Available Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the journal entry, purchase credit memo, or current vendor ledger entry that you have selected as the applying entry.';
                        }
                    }
                    group(Balance)
                    {
                        Caption = 'Balance';
                        field(ControlBalance; AppliedAmount + (-PmtDiscAmount) + ApplyingAmount + ApplnRounding)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ApplnCurrencyCode;
                            AutoFormatType = 1;
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies any extra amount that will remain after the application.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied Vendor Entries";
                    RunPageOnRec = true;
                    ToolTip = 'View the ledger entries that have been applied to this record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Vendor Ledg. Entries";
                    RunPageLink = "Vendor Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Vendor Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of the all posted entries and adjustments related to a specific vendor ledger entry.';
                }
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    Visible = not IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                        Navigate.Run();
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action(ActionSetAppliesToID)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = AppliesToIDVisible;
                    Caption = 'Set Applies-to ID';
                    Image = SelectLineToApply;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Set the Applies-to ID field on the posted entry to automatically be filled in with the document number of the entry in the journal.';

                    trigger OnAction()
                    begin
                        if (CalcType = CalcType::"Gen. Jnl. Line") and (ApplnType = ApplnType::"Applies-to Doc. No.") then
                            Error(CannotSetAppliesToIDErr);

                        SetVendApplId(false);
                    end;
                }
                action(ActionPostApplication)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = CalledFromEntry;
                    Caption = 'Post Application';
                    Ellipsis = true;
                    Image = PostApplication;
                    ShortCutKey = 'F9';
                    ToolTip = 'Define the document number of the ledger entry to use to perform the application. In addition, you specify the Posting Date for the application.';

                    trigger OnAction()
                    begin
                        PostDirectApplication(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = CalledFromEntry;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        PostDirectApplication(true);
                    end;
                }
                separator("-")
                {
                    Caption = '-';
                }
                action("Show Only Selected Entries to Be Applied")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Only Selected Entries to Be Applied';
                    Image = ShowSelected;
                    ToolTip = 'View the selected ledger entries that will be applied to the specified record.';

                    trigger OnAction()
                    begin
                        ShowAppliedEntries := not ShowAppliedEntries;
                        if ShowAppliedEntries then
                            if CalcType = CalcType::"Gen. Jnl. Line" then
                                Rec.SetRange("Applies-to ID", GenJnlLine."Applies-to ID")
                            else begin
                                VendEntryApplID := CopyStr(UserId(), 1, MaxStrLen(VendEntryApplID));
                                if VendEntryApplID = '' then
                                    VendEntryApplID := '***';
                                Rec.SetRange("Applies-to ID", VendEntryApplID);
                            end
                        else
                            Rec.SetRange("Applies-to ID");
                    end;
                }
            }
            action(ShowPostedDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Posted Document';
                Image = Document;
                ToolTip = 'Show details for the posted payment, invoice, or credit memo.';

                trigger OnAction()
                begin
                    Rec.ShowDoc();
                end;
            }
            action(ShowDocumentAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Document Attachment';
                Enabled = HasDocumentAttachment;
                Image = Attach;
                ToolTip = 'View documents or images that are attached to the posted invoice or credit memo.';

                trigger OnAction()
                begin
                    Rec.ShowPostedDocAttachment();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ActionSetAppliesToID_Promoted; ActionSetAppliesToID)
                {
                }
                actionref(ActionPostApplication_Promoted; ActionPostApplication)
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref(ShowPostedDocument_Promoted; ShowPostedDocument)
                    {
                    }
                    actionref(ShowDocumentAttachment_Promoted; ShowDocumentAttachment)
                    {
                    }
                }
                actionref(Preview_Promoted; Preview)
                {
                }
                actionref("Show Only Selected Entries to Be Applied_Promoted"; "Show Only Selected Entries to Be Applied")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category5)
            {
                Caption = 'Entry', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                {
                }
                actionref("Detailed &Ledger Entries_Promoted"; "Detailed &Ledger Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ApplnType = ApplnType::"Applies-to Doc. No." then
            CalcApplnAmount();
        HasDocumentAttachment := Rec.HasPostedDocAttachment();
    end;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.SetStyle();
    end;

    trigger OnInit()
    begin
        AppliesToIDVisible := true;
    end;

    trigger OnModifyRecord(): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnModifyRecordOnBeforeRunCodeunitVendEntryEdit(CalcType, AppliedVendLedgEntry, IsHandled);
        if not IsHandled then
            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", Rec);
        if Rec."Applies-to ID" <> xRec."Applies-to ID" then
            CalcApplnAmount();
        exit(false);
    end;

    local procedure JournalHasDocumentNo(AppliesToIDCode: Code[50]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJournalLine.SetRange("Document No.", CopyStr(AppliesToIDCode, 1, MaxStrLen(GenJournalLine."Document No.")));
        exit(not GenJournalLine.IsEmpty());
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        if CalcType = CalcType::Direct then begin
            Vend.Get(Rec."Vendor No.");
            ApplnCurrencyCode := Vend."Currency Code";
            FindApplyingEntry();
        end;

        ActivateFields();
        PurchSetup.Get();
        VendNameVisible := PurchSetup."Copy Vendor Name to Entries";


        GLSetup.Get();

        if CalcType = CalcType::"Gen. Jnl. Line" then
            CalcApplnAmount();
        PostingDone := false;
        IsOfficeAddin := OfficeMgt.IsAvailable();

        OnAfterOpenPage(Rec, TempApplyingVendLedgEntry);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        RaiseError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnQueryClosePage(CloseAction, TempApplyingVendLedgEntry, ApplnType, Rec, CalcType, IsHandled);
        if not IsHandled then begin
            if CloseAction = ACTION::LookupOK then
                LookupOKOnPush();
            if ApplnType = ApplnType::"Applies-to Doc. No." then begin
                if OK then begin
                    RaiseError := TempApplyingVendLedgEntry."Posting Date" < Rec."Posting Date";
                    OnBeforeEarlierPostingDateError(TempApplyingVendLedgEntry, Rec, RaiseError, CalcType.AsInteger(), PmtDiscAmount);
                    if RaiseError then begin
                        OK := false;
                        Error(
                          EarlierPostingDateErr, TempApplyingVendLedgEntry."Document Type", TempApplyingVendLedgEntry."Document No.",
                          Rec."Document Type", Rec."Document No.");
                    end;

                    OnQueryClosePageOnAfterEarlierPostingDateTest(TempApplyingVendLedgEntry, Rec, CalcType, OK);
                end;
                if OK then begin
                    if Rec."Amount to Apply" = 0 then
                        Rec."Amount to Apply" := Rec."Remaining Amount";
                    RunVendEntryEdit(Rec);
                end;
            end;

            if CheckActionPerformed() then begin
                Rec := TempApplyingVendLedgEntry;
                Rec."Applying Entry" := false;
                if AppliesToID = '' then begin
                    Rec."Applies-to ID" := '';
                    Rec."Amount to Apply" := 0;
                end;

                RunVendEntryEdit(Rec);
            end;
        end;
    end;

    var
        PurchHeader: Record "Purchase Header";
        Vend: Record Vendor;
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        PurchPost: Codeunit "Purch.-Post";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        Navigate: Page Navigate;
        GenJnlLineApply: Boolean;
        StyleTxt: Text;
        CustomAppliesToID: Code[50];
        ValidExchRate: Boolean;
        MustSelectEntryErr: Label 'You must select an applying entry before you can post the application.';
        PostingInWrongContextErr: Label 'You must post the application from the window where you entered the applying entry.';
        CannotSetAppliesToIDErr: Label 'You cannot set Applies-to ID while selecting Applies-to Doc. No.';
        TimesSetCustomAppliesToID: Integer;
        CalledFromEntry: Boolean;
        ShowAppliedEntries: Boolean;
        OK: Boolean;
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.\\Instead, post the document of type %1 with the number %2 and then apply it to the document of type %3 with the number %4.', Comment = '%1 - document type, %2 - document number,%3 - document type,%4 - document number';
        AppliesToIDVisible: Boolean;
        ApplicationPostedMsg: Label 'The application was successfully posted.';
#pragma warning disable AA0470
        ApplicationDateErr: Label 'The %1 entered must not be before the %1 on the %2.';
#pragma warning restore AA0470
        IsOfficeAddin: Boolean;
        HasDocumentAttachment: Boolean;
        VendNameVisible: Boolean;

    protected var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        TempApplyingVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        ApplnDate: Date;
        ApplnRoundingPrecision: Decimal;
        ApplnRounding: Decimal;
        ApplnType: Enum "Vendor Apply-to Type";
        AmountRoundingPrecision: Decimal;
        VATAmount: Decimal;
        VATAmountText: Text[30];
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        PmtDiscAmount: Decimal;
        VendEntryApplID: Code[50];
        ApplnCurrencyCode: Code[10];
        AppliesToID: Code[50];
        DifferentCurrenciesInAppln: Boolean;
        CalcType: Enum "Vendor Apply Calculation Type";
        PostingDone: Boolean;

    procedure SetGenJnlLine(NewGenJnlLine: Record "Gen. Journal Line"; ApplnTypeSelect: Integer)
    begin
        GenJnlLine := NewGenJnlLine;
        GenJnlLineApply := true;

        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then
            ApplyingAmount := GenJnlLine.Amount;
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor then
            ApplyingAmount := -GenJnlLine.Amount;
        ApplnDate := GenJnlLine."Posting Date";
        ApplnCurrencyCode := GenJnlLine."Currency Code";
        CalcType := CalcType::"Gen. Jnl. Line";

        case ApplnTypeSelect of
            GenJnlLine.FieldNo("Applies-to Doc. No."):
                ApplnType := ApplnType::"Applies-to Doc. No.";
            GenJnlLine.FieldNo("Applies-to ID"):
                ApplnType := ApplnType::"Applies-to ID";
        end;

        SetApplyingVendLedgEntry();
    end;

    internal procedure GetCustomAppliesToID(): Code[50]
    begin
        if TimesSetCustomAppliesToID <> 1 then
            exit('');
        exit(CustomAppliesToID);
    end;

    local procedure UpdateCustomAppliesToIDForGenJournal(NewAppliesToID: Code[50])
    begin
        if (not GenJnlLineApply) or (ApplnType <> ApplnType::"Applies-to ID") then
            exit;
        if JournalHasDocumentNo(NewAppliesToID) then
            exit;
        if (CustomAppliesToID = '') or ((CustomAppliesToID <> '') and (CustomAppliesToID <> NewAppliesToID)) then
            TimesSetCustomAppliesToID += 1;

        CustomAppliesToID := NewAppliesToID;
    end;

    local procedure RunVendEntryEdit(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        OnBeforeRunVendEntryEdit(VendorLedgerEntry);
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry);
    end;

    procedure SetPurch(NewPurchHeader: Record "Purchase Header"; var NewVendLedgEntry: Record "Vendor Ledger Entry"; ApplnTypeSelect: Integer)
    begin
        PurchHeader := NewPurchHeader;
        Rec.CopyFilters(NewVendLedgEntry);

        PurchPost.SumPurchLines(
          PurchHeader, 0, TotalPurchLine, TotalPurchLineLCY,
          VATAmount, VATAmountText);

        case PurchHeader."Document Type" of
            PurchHeader."Document Type"::"Return Order",
            PurchHeader."Document Type"::"Credit Memo":
                ApplyingAmount := TotalPurchLine."Amount Including VAT"
            else
                ApplyingAmount := -TotalPurchLine."Amount Including VAT";
        end;

        ApplnDate := PurchHeader."Posting Date";
        ApplnCurrencyCode := PurchHeader."Currency Code";
        CalcType := CalcType::"Purchase Header";

        case ApplnTypeSelect of
            PurchHeader.FieldNo("Applies-to Doc. No."):
                ApplnType := ApplnType::"Applies-to Doc. No.";
            PurchHeader.FieldNo("Applies-to ID"):
                ApplnType := ApplnType::"Applies-to ID";
        end;

        SetApplyingVendLedgEntry();
    end;

    procedure SetVendLedgEntry(NewVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        Rec := NewVendLedgEntry;
    end;

    procedure SetApplyingVendLedgEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApplyingVendLedgEntry(TempApplyingVendLedgEntry, GenJnlLine, PurchHeader, CalcType, IsHandled);
        if not IsHandled then begin
            case CalcType of
                CalcType::"Purchase Header":
                    SetApplyingVendLedgEntryPurchaseHeader();
                CalcType::"Gen. Jnl. Line":
                    SetApplyingVendLedgEntryGenJnlLine();
                CalcType::Direct:
                    SetApplyingVendLedgEntryDirect();
            end;

            CalcApplnAmount();
        end;

        OnAfterSetApplyingVendLedgEntry(TempApplyingVendLedgEntry, GenJnlLine, PurchHeader, CalcType);
    end;

    local procedure SetApplyingVendLedgEntryPurchaseHeader()
    begin
        TempApplyingVendLedgEntry."Posting Date" := PurchHeader."Posting Date";
        if PurchHeader."Document Type" = PurchHeader."Document Type"::"Return Order" then
            TempApplyingVendLedgEntry."Document Type" := TempApplyingVendLedgEntry."Document Type"::"Credit Memo"
        else
            TempApplyingVendLedgEntry."Document Type" := TempApplyingVendLedgEntry."Document Type"::Invoice;
        TempApplyingVendLedgEntry."Document No." := PurchHeader."No.";
        TempApplyingVendLedgEntry."Vendor No." := PurchHeader."Pay-to Vendor No.";
        TempApplyingVendLedgEntry.Description := PurchHeader."Posting Description";
        TempApplyingVendLedgEntry."Currency Code" := PurchHeader."Currency Code";
        if TempApplyingVendLedgEntry."Document Type" = TempApplyingVendLedgEntry."Document Type"::"Credit Memo" then begin
            TempApplyingVendLedgEntry.Amount := TotalPurchLine."Amount Including VAT";
            TempApplyingVendLedgEntry."Remaining Amount" := TotalPurchLine."Amount Including VAT";
        end else begin
            TempApplyingVendLedgEntry.Amount := -TotalPurchLine."Amount Including VAT";
            TempApplyingVendLedgEntry."Remaining Amount" := -TotalPurchLine."Amount Including VAT";
        end;
        TempApplyingVendLedgEntry."Remit-to Code" := PurchHeader."Remit-to Code";

        OnAfterSetApplyingVendLedgEntryPurchaseHeader(TempApplyingVendLedgEntry, PurchHeader);
    end;

    local procedure SetApplyingVendLedgEntryGenJnlLine()
    var
        Vendor: Record Vendor;
    begin
        TempApplyingVendLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        TempApplyingVendLedgEntry."Document Type" := GenJnlLine."Document Type";
        TempApplyingVendLedgEntry."Document No." := GenJnlLine."Document No.";
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor then begin
            TempApplyingVendLedgEntry."Vendor No." := GenJnlLine."Bal. Account No.";
            Vendor.Get(TempApplyingVendLedgEntry."Vendor No.");
            TempApplyingVendLedgEntry.Description := Vendor.Name;
        end else begin
            TempApplyingVendLedgEntry."Vendor No." := GenJnlLine."Account No.";
            TempApplyingVendLedgEntry.Description := GenJnlLine.Description;
        end;
        TempApplyingVendLedgEntry."Currency Code" := GenJnlLine."Currency Code";
        TempApplyingVendLedgEntry.Amount := GenJnlLine.Amount;
        TempApplyingVendLedgEntry."Remaining Amount" := GenJnlLine.Amount;
        TempApplyingVendLedgEntry."Remit-to Code" := GenJnlLine."Remit-to Code";

        OnAfterSetApplyingVendLedgEntryGenJnlLine(TempApplyingVendLedgEntry, GenJnlLine);
    end;

    local procedure SetApplyingVendLedgEntryDirect()
    begin
        if Rec."Applying Entry" then begin
            if TempApplyingVendLedgEntry."Entry No." <> 0 then
                VendLedgEntry := TempApplyingVendLedgEntry;
            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", Rec);
            if Rec."Applies-to ID" = '' then
                SetVendApplId(false);
            Rec.CalcFields(Amount);
            TempApplyingVendLedgEntry := Rec;
            if VendLedgEntry."Entry No." <> 0 then begin
                Rec := VendLedgEntry;
                Rec."Applying Entry" := false;
                SetVendApplId(false);
            end;
            Rec.SetFilter("Entry No.", '<> %1', TempApplyingVendLedgEntry."Entry No.");
            ApplyingAmount := TempApplyingVendLedgEntry."Remaining Amount";
            ApplnDate := TempApplyingVendLedgEntry."Posting Date";
            ApplnCurrencyCode := TempApplyingVendLedgEntry."Currency Code";
            Rec."Remit-to Code" := TempApplyingVendLedgEntry."Remit-to Code";
        end;
        OnSetApplyingVendLedgEntryOnBeforeCalcTypeDirectCalcApplnAmount(ApplyingAmount, TempApplyingVendLedgEntry, Rec);
    end;

    procedure SetVendApplId(CurrentRec: Boolean)
    begin
        CurrPage.SetSelectionFilter(VendLedgEntry);
        CheckVendLedgEntry(VendLedgEntry);
        OnSetVendApplIdOnAfterCheckAgainstApplnCurrency(Rec, CalcType.AsInteger(), GenJnlLine, PurchHeader, TempApplyingVendLedgEntry);

        VendLedgEntry.Copy(Rec);
        if CurrentRec then
            VendLedgEntry.SetRecFilter()
        else
            CurrPage.SetSelectionFilter(VendLedgEntry);

        OnSetVendApplIdOnAfterSetFilter(Rec, CurrentRec, VendLedgEntry, TempApplyingVendLedgEntry);

        CallVendEntrySetApplIDSetApplId();

        CalcApplnAmount();
    end;

    local procedure CallVendEntrySetApplIDSetApplId()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallVendEntrySetApplIDSetApplId(VendEntrySetApplID, VendLedgEntry, TempApplyingVendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLineApply then
            VendEntrySetApplID.SetApplId(VendLedgEntry, TempApplyingVendLedgEntry, GenJnlLine."Applies-to ID")
        else
            VendEntrySetApplID.SetApplId(VendLedgEntry, TempApplyingVendLedgEntry, PurchHeader."Applies-to ID");
    end;

    procedure CheckVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        if VendorLedgerEntry.FindSet() then
            repeat
                if CalcType = CalcType::"Gen. Jnl. Line" then begin
                    RaiseError := TempApplyingVendLedgEntry."Posting Date" < VendorLedgerEntry."Posting Date";
                    OnBeforeEarlierPostingDateError(
                        TempApplyingVendLedgEntry, VendorLedgerEntry, RaiseError, CalcType.AsInteger(), PmtDiscAmount);
                    if RaiseError then
                        Error(
                            EarlierPostingDateErr, TempApplyingVendLedgEntry."Document Type", TempApplyingVendLedgEntry."Document No.",
                            VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.");

                    OnCheckVendLedgEntryOnAfterEarlierPostingDateTest(TempApplyingVendLedgEntry, VendorLedgerEntry, CalcType, OK);
                end;

                if TempApplyingVendLedgEntry."Entry No." <> 0 then begin
                    OnCheckVendLedgEntryOnBeforeCheckAgainstApplnCurrency(GenJnlLine, VendorLedgerEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                        ApplnCurrencyCode, VendorLedgerEntry."Currency Code", GenJnlLine."Account Type"::Vendor, true);
                end;
            until VendorLedgerEntry.Next() = 0;
    end;

    procedure CalcApplnAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcApplnAmount(Rec, GenJnlLine, PurchHeader, AppliedVendLedgEntry, CalcType, ApplnType, IsHandled);
        if not IsHandled then begin
            AppliedAmount := 0;
            PmtDiscAmount := 0;
            DifferentCurrenciesInAppln := false;

            case CalcType of
                CalcType::Direct:
                    begin
                        FindAmountRounding();
                        VendEntryApplID := CopyStr(UserId(), 1, MaxStrLen(VendEntryApplID));
                        if VendEntryApplID = '' then
                            VendEntryApplID := '***';

                        VendLedgEntry := TempApplyingVendLedgEntry;

                        AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                        AppliedVendLedgEntry.SetRange("Vendor No.", Rec."Vendor No.");
                        AppliedVendLedgEntry.SetRange(Open, true);
                        if AppliesToID = '' then
                            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID)
                        else
                            AppliedVendLedgEntry.SetRange("Applies-to ID", AppliesToID);

                        if TempApplyingVendLedgEntry."Entry No." <> 0 then begin
                            VendLedgEntry.CalcFields("Remaining Amount");
                            AppliedVendLedgEntry.SetFilter("Entry No.", '<>%1', VendLedgEntry."Entry No.");

                            OnCalcApplnAmountOnAfterAppliedVendLedgEntrySetFilter(AppliedVendLedgEntry, VendLedgEntry, Rec);
                        end;

                        HandleChosenEntries(
                            CalcType::Direct, VendLedgEntry."Remaining Amount", VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                    end;
                CalcType::"Gen. Jnl. Line":
                    begin
                        FindAmountRounding();
                        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor then
                            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

                        case ApplnType of
                            ApplnType::"Applies-to Doc. No.":
                                begin
                                    AppliedVendLedgEntry := Rec;
                                    AppliedVendLedgEntry.CalcFields("Remaining Amount");
                                    if AppliedVendLedgEntry."Currency Code" <> ApplnCurrencyCode then begin
                                        AppliedVendLedgEntry."Remaining Amount" :=
                                        CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, AppliedVendLedgEntry."Currency Code", ApplnCurrencyCode, AppliedVendLedgEntry."Remaining Amount");
                                        AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                                        CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, AppliedVendLedgEntry."Currency Code", ApplnCurrencyCode, AppliedVendLedgEntry."Remaining Pmt. Disc. Possible");
                                        AppliedVendLedgEntry."Amount to Apply" :=
                                        CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, AppliedVendLedgEntry."Currency Code", ApplnCurrencyCode, AppliedVendLedgEntry."Amount to Apply");
                                    end;

                                    if AppliedVendLedgEntry."Amount to Apply" <> 0 then
                                        AppliedAmount := Round(AppliedVendLedgEntry."Amount to Apply", AmountRoundingPrecision)
                                    else
                                        AppliedAmount := Round(AppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);

                                    if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(
                                        GenJnlLine, AppliedVendLedgEntry, 0, false) and
                                    ((Abs(GenJnlLine.Amount) + ApplnRoundingPrecision >=
                                        Abs(AppliedAmount - AppliedVendLedgEntry."Remaining Pmt. Disc. Possible")) or
                                        (GenJnlLine.Amount = 0))
                                    then
                                        PmtDiscAmount := AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";

                                    if not DifferentCurrenciesInAppln then
                                        DifferentCurrenciesInAppln := ApplnCurrencyCode <> AppliedVendLedgEntry."Currency Code";
                                    CheckRounding();
                                end;
                            ApplnType::"Applies-to ID":
                                begin
                                    GenJnlLine2 := GenJnlLine;
                                    AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                                    AppliedVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                                    AppliedVendLedgEntry.SetRange(Open, true);
                                    AppliedVendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

                                    HandleChosenEntries(
                                        CalcType::"Gen. Jnl. Line", GenJnlLine2.Amount, GenJnlLine2."Currency Code", GenJnlLine2."Posting Date");
                                end;
                        end;
                    end;
                CalcType::"Purchase Header":
                    begin
                        FindAmountRounding();

                        case ApplnType of
                            ApplnType::"Applies-to Doc. No.":
                                begin
                                    AppliedVendLedgEntry := Rec;
                                    AppliedVendLedgEntry.CalcFields("Remaining Amount");

                                    if AppliedVendLedgEntry."Currency Code" <> ApplnCurrencyCode then
                                        AppliedVendLedgEntry."Remaining Amount" :=
                                        CurrExchRate.ExchangeAmtFCYToFCY(
                                            ApplnDate, AppliedVendLedgEntry."Currency Code", ApplnCurrencyCode, AppliedVendLedgEntry."Remaining Amount");

                                    AppliedAmount := AppliedAmount + Round(AppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);

                                    if not DifferentCurrenciesInAppln then
                                        DifferentCurrenciesInAppln := ApplnCurrencyCode <> AppliedVendLedgEntry."Currency Code";
                                    CheckRounding();
                                end;
                            ApplnType::"Applies-to ID":
                                begin
                                    AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                                    AppliedVendLedgEntry.SetRange("Vendor No.", PurchHeader."Pay-to Vendor No.");
                                    AppliedVendLedgEntry.SetRange(Open, true);
                                    AppliedVendLedgEntry.SetRange("Applies-to ID", PurchHeader."Applies-to ID");

                                    HandleChosenEntries(CalcType::"Purchase Header", ApplyingAmount, ApplnCurrencyCode, ApplnDate);
                                end;
                        end;
                    end;
            end;
        end;

        OnAfterCalcApplnAmount(Rec, AppliedAmount, ApplyingAmount, CalcType, AppliedVendLedgEntry, GenJnlLine);
    end;

    protected procedure CalcApplnRemainingAmount(Amount: Decimal): Decimal
    var
        ApplnRemainingAmount: Decimal;
    begin
        ValidExchRate := true;
        if ApplnCurrencyCode = Rec."Currency Code" then
            exit(Amount);

        if ApplnDate = 0D then
            ApplnDate := Rec."Posting Date";
        ApplnRemainingAmount :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, Rec."Currency Code", ApplnCurrencyCode, Amount, ValidExchRate);

        OnAfterCalcApplnRemainingAmount(Rec, ApplnRemainingAmount);
        exit(ApplnRemainingAmount);
    end;

    local procedure CalcApplnAmountToApply(AmountToApply: Decimal): Decimal
    var
        ApplnAmountToApply: Decimal;
    begin
        ValidExchRate := true;

        if ApplnCurrencyCode = Rec."Currency Code" then
            exit(AmountToApply);

        if ApplnDate = 0D then
            ApplnDate := Rec."Posting Date";
        ApplnAmountToApply :=
          CurrExchRate.ApplnExchangeAmtFCYToFCY(
            ApplnDate, Rec."Currency Code", ApplnCurrencyCode, AmountToApply, ValidExchRate);

        OnAfterCalcApplnAmountToApply(Rec, AmountToApply, ApplnAmountToApply);
        exit(ApplnAmountToApply);
    end;

    protected procedure FindAmountRounding()
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else
            if ApplnCurrencyCode <> Currency.Code then
                Currency.Get(ApplnCurrencyCode);

        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    procedure CheckRounding()
    begin
        ApplnRounding := 0;

        case CalcType of
            CalcType::"Purchase Header":
                exit;
            CalcType::"Gen. Jnl. Line":
                if (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment) and
                   (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund)
                then
                    exit;
        end;

        if ApplnCurrencyCode = '' then
            ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision"
        else begin
            if ApplnCurrencyCode <> Rec."Currency Code" then
                Currency.Get(ApplnCurrencyCode);
            ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
        end;

        if (Abs((AppliedAmount - PmtDiscAmount) + ApplyingAmount) <= ApplnRoundingPrecision) and DifferentCurrenciesInAppln then
            ApplnRounding := -((AppliedAmount - PmtDiscAmount) + ApplyingAmount);
    end;

    procedure GetVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry := Rec;
    end;

    local procedure FindApplyingEntry()
    begin
        if CalcType = CalcType::Direct then begin
            VendEntryApplID := CopyStr(UserId(), 1, MaxStrLen(VendEntryApplID));
            if VendEntryApplID = '' then
                VendEntryApplID := '***';

            VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
            VendLedgEntry.SetRange("Vendor No.", Rec."Vendor No.");
            if AppliesToID = '' then
                VendLedgEntry.SetRange("Applies-to ID", VendEntryApplID)
            else
                VendLedgEntry.SetRange("Applies-to ID", AppliesToID);
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.SetRange("Applying Entry", true);
            OnFindApplyingEntryOnAfterSetFilters(Rec, VendLedgEntry);
            if VendLedgEntry.FindFirst() then begin
                VendLedgEntry.CalcFields(Amount, "Remaining Amount");
                OnFindApplyingEntryOnBeforeAssignTempApplyingVendLedgEntry(VendLedgEntry);
                TempApplyingVendLedgEntry := VendLedgEntry;
                Rec.SetFilter("Entry No.", '<>%1', VendLedgEntry."Entry No.");
                ApplyingAmount := VendLedgEntry."Remaining Amount";
                ApplnDate := VendLedgEntry."Posting Date";
                ApplnCurrencyCode := VendLedgEntry."Currency Code";
            end;
            OnFindApplyingEntryOnBeforeCalcApplnAmount(Rec);
            CalcApplnAmount();
        end;
    end;

    protected procedure HandleChosenEntries(Type: Enum "Vendor Apply Calculation Type"; CurrentAmount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        PossiblePmtDisc: Decimal;
        OldPmtDisc: Decimal;
        CorrectionAmount: Decimal;
        RemainingAmountExclDiscounts: Decimal;
        CanUseDisc: Boolean;
        FromZeroGenJnl: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandledChosenEntries(Type.AsInteger(), CurrentAmount, CurrencyCode, PostingDate, AppliedVendLedgEntry, IsHandled, VendLedgEntry);
        if IsHandled then
            exit;

        if not AppliedVendLedgEntry.FindSet(false, false) then
            exit;

        repeat
            TempAppliedVendLedgEntry := AppliedVendLedgEntry;
            TempAppliedVendLedgEntry.Insert();
            OnHandleChosenEntriesOnAfterTempAppliedVendLedgEntryInsert(TempAppliedVendLedgEntry);
        until AppliedVendLedgEntry.Next() = 0;

        FromZeroGenJnl := (CurrentAmount = 0) and (Type = Type::"Gen. Jnl. Line");

        repeat
            if not FromZeroGenJnl then
                TempAppliedVendLedgEntry.SetRange(Positive, CurrentAmount < 0);
            if TempAppliedVendLedgEntry.FindFirst() then begin
                ExchangeLedgerEntryAmounts(Type, CurrencyCode, TempAppliedVendLedgEntry, PostingDate);

                case Type of
                    Type::Direct:
                        CanUseDisc := PaymentToleranceMgt.CheckCalcPmtDiscVend(VendLedgEntry, TempAppliedVendLedgEntry, 0, false, false);
                    Type::"Gen. Jnl. Line":
                        CanUseDisc := PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine2, TempAppliedVendLedgEntry, 0, false)
                    else
                        CanUseDisc := false;
                end;

                if CanUseDisc and
                   (Abs(TempAppliedVendLedgEntry."Amount to Apply") >=
                    Abs(TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible"))
                then
                    if Abs(CurrentAmount) >
                       Abs(TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible")
                    then begin
                        PmtDiscAmount += TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                        CurrentAmount += TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                    end else
                        if Abs(CurrentAmount) =
                           Abs(TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible")
                        then begin
                            PmtDiscAmount += TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                            CurrentAmount +=
                              TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                            AppliedAmount += CorrectionAmount;
                        end else
                            if FromZeroGenJnl then begin
                                PmtDiscAmount += TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                                CurrentAmount +=
                                  TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                            end else begin
                                PossiblePmtDisc := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                                RemainingAmountExclDiscounts :=
                                  TempAppliedVendLedgEntry."Remaining Amount" - PossiblePmtDisc - TempAppliedVendLedgEntry."Max. Payment Tolerance";
                                if Abs(CurrentAmount) + Abs(CalcOppositeEntriesAmount(TempAppliedVendLedgEntry)) >=
                                   Abs(RemainingAmountExclDiscounts)
                                then begin
                                    PmtDiscAmount += PossiblePmtDisc;
                                    AppliedAmount += CorrectionAmount;
                                end;
                                CurrentAmount +=
                                  TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                            end
                else begin
                    if ((CurrentAmount + TempAppliedVendLedgEntry."Amount to Apply") * CurrentAmount) >= 0 then
                        AppliedAmount += CorrectionAmount;
                    CurrentAmount += TempAppliedVendLedgEntry."Amount to Apply";
                end;
            end else begin
                TempAppliedVendLedgEntry.SetRange(Positive);
                TempAppliedVendLedgEntry.FindFirst();
                ExchangeLedgerEntryAmounts(Type, CurrencyCode, TempAppliedVendLedgEntry, PostingDate);
            end;

            if OldPmtDisc <> PmtDiscAmount then
                AppliedAmount += TempAppliedVendLedgEntry."Remaining Amount"
            else
                AppliedAmount += TempAppliedVendLedgEntry."Amount to Apply";
            OldPmtDisc := PmtDiscAmount;

            if PossiblePmtDisc <> 0 then
                CorrectionAmount := TempAppliedVendLedgEntry."Remaining Amount" - TempAppliedVendLedgEntry."Amount to Apply"
            else
                CorrectionAmount := 0;

            if not DifferentCurrenciesInAppln then
                DifferentCurrenciesInAppln := ApplnCurrencyCode <> TempAppliedVendLedgEntry."Currency Code";

            TempAppliedVendLedgEntry.Delete();
            TempAppliedVendLedgEntry.SetRange(Positive);

        until not TempAppliedVendLedgEntry.FindFirst();
        CheckRounding();
    end;

    local procedure AmountToApplyOnAfterValidate()
    begin
        if ApplnType <> ApplnType::"Applies-to Doc. No." then begin
            CalcApplnAmount();
            CurrPage.Update(false);
        end;
    end;

    local procedure RecalcApplnAmount()
    begin
        CurrPage.Update(true);
        CalcApplnAmount();
    end;

    local procedure LookupOKOnPush()
    begin
        OK := true;
    end;

    local procedure PostDirectApplication(PreviewMode: Boolean)
    var
        RecBeforeRunPostApplicationVendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        NewApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        PostApplication: Page "Post Application";
        Applied: Boolean;
        ApplicationDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDirectApplication(Rec, PreviewMode, IsHandled, TempApplyingVendLedgEntry);
        if IsHandled then
            exit;

        if CalcType = CalcType::Direct then begin
            if TempApplyingVendLedgEntry."Entry No." <> 0 then begin
                Rec := TempApplyingVendLedgEntry;
                IsTheApplicationValid();
                ApplicationDate := VendEntryApplyPostedEntries.GetApplicationDate(Rec);

                OnPostDirectApplicationBeforeSetValues(ApplicationDate);
                Clear(ApplyUnapplyParameters);
                ApplyUnapplyParameters.CopyFromVendLedgEntry(Rec);
                GLSetup.GetRecordOnce();
                ApplyUnapplyParameters."Posting Date" := ApplicationDate;
                if GLSetup."Journal Templ. Name Mandatory" then begin
                    GLSetup.TestField("Apply Jnl. Template Name");
                    GLSetup.TestField("Apply Jnl. Batch Name");
                    ApplyUnapplyParameters."Journal Template Name" := GLSetup."Apply Jnl. Template Name";
                    ApplyUnapplyParameters."Journal Batch Name" := GLSetup."Apply Jnl. Batch Name";
                end;
                PostApplication.SetParameters(ApplyUnapplyParameters);
                RecBeforeRunPostApplicationVendorLedgerEntry := Rec;
                if ACTION::OK = PostApplication.RunModal() then begin
                    if Rec."Entry No." <> RecBeforeRunPostApplicationVendorLedgerEntry."Entry No." then
                        Rec := RecBeforeRunPostApplicationVendorLedgerEntry;
                    PostApplication.GetParameters(NewApplyUnapplyParameters);
                    IsHandled := false;
                    OnPostDirectApplicationOnBeforeCheckApplicationDate(Rec, NewApplyUnapplyParameters, ApplicationDate, PreviewMode, IsHandled);
                    if not IsHandled then
                        if NewApplyUnapplyParameters."Posting Date" < ApplicationDate then
                            Error(ApplicationDateErr, Rec.FieldCaption("Posting Date"), Rec.TableCaption());
                end else
                    exit;
                OnPostDirectApplicationBeforeApply(GLSetup, NewApplyUnapplyParameters);
                if PreviewMode then
                    VendEntryApplyPostedEntries.PreviewApply(Rec, NewApplyUnapplyParameters)
                else
                    Applied := VendEntryApplyPostedEntries.Apply(Rec, NewApplyUnapplyParameters);

                OnPostDirectApplicationOnAfterApply(Rec, NewApplyUnapplyParameters, PreviewMode, Applied);

                if (not PreviewMode) and Applied then begin
                    Message(ApplicationPostedMsg);
                    PostingDone := true;
                    CurrPage.Close();
                end;
            end else
                Error(MustSelectEntryErr);
        end else
            Error(PostingInWrongContextErr);
    end;

    local procedure CheckActionPerformed() Result: Boolean
    var
        IsHandled: Boolean;
        ActionPerformed: Boolean;
    begin
        ActionPerformed := false;

        IsHandled := false;
        OnBeforeCheckActionPerformed(
            ActionPerformed, OK, CalcType.AsInteger(), PostingDone, TempApplyingVendLedgEntry, ApplnType.AsInteger(), Result, IsHandled, AppliesToID);
        if IsHandled then
            exit(Result);

        if (not (CalcType = CalcType::Direct) and not OK and not PostingDone) or
           (ApplnType = ApplnType::"Applies-to Doc. No.")
        then
            exit(false);
        exit((CalcType = CalcType::Direct) and not OK and not PostingDone);
    end;

    procedure SetAppliesToID(AppliesToID2: Code[50])
    begin
        AppliesToID := AppliesToID2;
    end;

    protected procedure ExchangeLedgerEntryAmounts(Type: Enum "Vendor Apply Calculation Type"; CurrencyCode: Code[10]; var CalcVendLedgEntry: Record "Vendor Ledger Entry"; PostingDate: Date)
    var
        CalculateCurrency: Boolean;
        IsHandled: Boolean;
    begin
        CalcVendLedgEntry.CalcFields("Remaining Amount");

        if Type = Type::Direct then
            CalculateCurrency := TempApplyingVendLedgEntry."Entry No." <> 0
        else
            CalculateCurrency := true;

        OnExchangeLedgerEntryAmountsOnBeforeCalculateAmounts(CalcVendLedgEntry, VendLedgEntry, CurrencyCode, CalculateCurrency, IsHandled);
        if IsHandled then
            exit;

        if (CurrencyCode <> CalcVendLedgEntry."Currency Code") and CalculateCurrency then begin
            CalcVendLedgEntry."Remaining Amount" :=
              CurrExchRate.ExchangeAmount(
                CalcVendLedgEntry."Remaining Amount", CalcVendLedgEntry."Currency Code", CurrencyCode, PostingDate);
            CalcVendLedgEntry."Remaining Pmt. Disc. Possible" :=
              CurrExchRate.ExchangeAmount(
                CalcVendLedgEntry."Remaining Pmt. Disc. Possible", CalcVendLedgEntry."Currency Code", CurrencyCode, PostingDate);
            CalcVendLedgEntry."Amount to Apply" :=
              CurrExchRate.ExchangeAmount(
                CalcVendLedgEntry."Amount to Apply", CalcVendLedgEntry."Currency Code", CurrencyCode, PostingDate);
        end;

        OnAfterExchangeLedgerEntryAmounts(CalcVendLedgEntry, VendLedgEntry, CurrencyCode);
    end;

    local procedure IsTheApplicationValid()
    var
        ApplyToVendorLedgerEntry: Record "Vendor Ledger Entry";
        IsFirst, IsPositiv, ThereAreEntriesToApply : boolean;
        Counter: Integer;
        AllEntriesHaveTheSameSignErr: Label 'All entries have the same sign this will not lead to an application. Update the application by including entries with opposite sign.';
    begin
        IsFirst := true;
        ThereAreEntriesToApply := false;
        Counter := 0;
        ApplyToVendorLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID");
        ApplyToVendorLedgerEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        ApplyToVendorLedgerEntry.SetRange("Applies-to ID", VendLedgEntry."Applies-to ID");
        if ApplyToVendorLedgerEntry.FindSet() then
            repeat
                if not IsFirst then
                    ThereAreEntriesToApply := (IsPositiv <> ApplyToVendorLedgerEntry.Positive)
                else
                    IsPositiv := ApplyToVendorLedgerEntry.Positive;
                IsFirst := false;
                Counter += 1;
            until (ApplyToVendorLedgerEntry.next() = 0) or ThereAreEntriesToApply;
        if not ThereAreEntriesToApply and (Counter > 1) then
            error(AllEntriesHaveTheSameSignErr)
    end;

    local procedure ActivateFields()
    begin
        CalledFromEntry := CalcType = CalcType::Direct;
        AppliesToIDVisible := ApplnType <> ApplnType::"Applies-to Doc. No.";
    end;


    procedure CalcOppositeEntriesAmount(var TempAppliedVendorLedgerEntry: Record "Vendor Ledger Entry" temporary) Result: Decimal
    var
        SavedAppliedVendorLedgerEntry: Record "Vendor Ledger Entry";
        CurrPosFilter: Text;
    begin
        CurrPosFilter := TempAppliedVendorLedgerEntry.GetFilter(Positive);
        if CurrPosFilter <> '' then begin
            SavedAppliedVendorLedgerEntry := TempAppliedVendorLedgerEntry;
            TempAppliedVendorLedgerEntry.SetRange(Positive, not TempAppliedVendorLedgerEntry.Positive);
            if TempAppliedVendorLedgerEntry.FindSet() then
                repeat
                    TempAppliedVendorLedgerEntry.CalcFields("Remaining Amount");
                    Result += TempAppliedVendorLedgerEntry."Remaining Amount";
                until TempAppliedVendorLedgerEntry.Next() = 0;
            TempAppliedVendorLedgerEntry.SetFilter(Positive, CurrPosFilter);
            TempAppliedVendorLedgerEntry := SavedAppliedVendorLedgerEntry;
        end;
    end;

    procedure GetApplnCurrencyCode(): Code[10]
    begin
        exit(ApplnCurrencyCode);
    end;

    procedure GetCalcType(): Integer
    begin
        exit(CalcType.AsInteger());
    end;

    procedure SetCalcType(NewCalcType: Enum "Vendor Apply Calculation Type")
    begin
        CalcType := NewCalcType;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcApplnAmount(VendorLedgerEntry: Record "Vendor Ledger Entry"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; CalcType: Enum "Vendor Apply Calculation Type"; var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnAmountToApply(VendorLedgerEntry: Record "Vendor Ledger Entry"; var ApplnAmountToApply: Decimal; var ApplnAmtToApply: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcApplnRemainingAmount(VendorLedgerEntry: Record "Vendor Ledger Entry"; var ApplnRemainingAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExchangeLedgerEntryAmounts(var CalcVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var ApplyingVendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetApplyingVendLedgEntry(var TempApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header"; CalcType: Enum "Vendor Apply Calculation Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCallVendEntrySetApplIDSetApplId(VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempApplyingVendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcApplnAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: record "Purchase Header"; AppliedVendLedgEntry: Record "Vendor Ledger Entry"; CalcType: Enum "Vendor Apply Calculation Type"; ApplnType: Enum "Vendor Apply-to Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckActionPerformed(ActionPerformed: Boolean; OK: Boolean; CalcType: Option Direct,GenJnlLine,PurchHeader; PostingDone: Boolean; ApplyingVendLedgEntry: Record "Vendor Ledger Entry" temporary; ApplnType: Option " ","Applies-to Doc. No.","Applies-to ID"; var Result: Boolean; var IsHandled: Boolean; AppliesToID: Code[50])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindApplyingEntryOnBeforeCalcApplnAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindApplyingEntryOnBeforeAssignTempApplyingVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeHandledChosenEntries(Type: Option Direct,GenJnlLine,PurchHeader; CurrentAmount: Decimal; CurrencyCode: Code[10]; PostingDate: Date; var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEarlierPostingDateError(ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var RaiseError: Boolean; CalcType: Option; PmtDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDirectApplication(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PreviewMode: Boolean; var IsHandled: Boolean; var TempApplyingVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetApplyingVendLedgEntry(var ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; var CalcType: enum "Vendor Apply Calculation Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunVendEntryEdit(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindApplyingEntryOnAfterSetFilters(ApplyingVendLedgEntry: Record "Vendor Ledger Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnHandleChosenEntriesOnAfterTempAppliedVendLedgEntryInsert(var TempAppliedVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDirectApplicationBeforeSetValues(var ApplicationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDirectApplicationBeforeApply(GLSetup: Record "General Ledger Setup"; var NewApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSetApplyingVendLedgEntryOnBeforeCalcTypeDirectCalcApplnAmount(var ApplyingAmount: Decimal; var ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetVendApplIdOnAfterCheckAgainstApplnCurrency(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CalcType: Option Direct,GenJnlLine,PurchHeader; GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; ApplyingVendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyingVendLedgEntryPurchaseHeader(var TempApplyingVendLedgEntry: Record "Vendor Ledger Entry" temporary; var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyingVendLedgEntryGenJnlLine(var TempApplyingVendLedgEntry: Record "Vendor Ledger Entry" temporary; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendLedgEntryOnBeforeCheckAgainstApplnCurrency(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendLedgEntryOnAfterEarlierPostingDateTest(ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CalcType: Enum "Vendor Apply Calculation Type"; var OK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQueryClosePageOnAfterEarlierPostingDateTest(ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CalcType: Enum "Vendor Apply Calculation Type"; var OK: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcApplnAmountOnAfterAppliedVendLedgEntrySetFilter(var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var RecVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetVendApplIdOnAfterSetFilter(var RecVendorLedgerEntry: Record "Vendor Ledger Entry"; CurrentRec: Boolean; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempApplyingVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordOnBeforeRunCodeunitVendEntryEdit(VendorApplyCalculationType: Enum "Vendor Apply Calculation Type"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnQueryClosePage(CloseAction: Action; ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry"; ApplnType: Enum "Vendor Apply-to Type"; VendorLedgerEntry: Record "Vendor Ledger Entry"; CalcType: Enum "Vendor Apply Calculation Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDirectApplicationOnBeforeCheckApplicationDate(VendorLedgerEntry: Record "Vendor Ledger Entry"; NewApplyUnapplyParameters: Record "Apply Unapply Parameters"; ApplicationDate: Date; PreviewMode: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExchangeLedgerEntryAmountsOnBeforeCalculateAmounts(var CalcVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; CalculateCurrency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDirectApplicationOnAfterApply(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var NewApplyUnapplyParameters: Record "Apply Unapply Parameters"; PreviewMode: Boolean; Applied: Boolean)
    begin
    end;
}
