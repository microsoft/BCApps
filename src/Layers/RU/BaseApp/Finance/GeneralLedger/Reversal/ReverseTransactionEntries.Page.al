// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Interactive interface for reviewing and executing reversal operations on posted ledger entries.
/// Provides comprehensive entry validation, confirmation dialogs, and posting integration for transaction and register reversals.
/// </summary>
/// <remarks>
/// Key workflows: Entry selection and validation, reversal confirmation, posting execution with optional G/L register printing.
/// Integration: Bank account statement reversals, detailed ledger entry validation, and extensible posting framework.
/// Extensibility: Integration events for custom entry type handling and text formatting customization.
/// </remarks>
page 183 "Reverse Transaction Entries"
{
    Caption = 'Reverse Entries';
    DataCaptionExpression = Rec.Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Reversal Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(EntryTypeText; GetEntryTypeText())
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Rec.FieldCaption("Entry Type");
                    Editable = false;
                    ShowCaption = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ClosingDates = true;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DescriptionEditable;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Debit Amount (LCY)"; Rec."Debit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits, expressed in LCY.';
                    Visible = false;
                }
                field("Credit Amount (LCY)"; Rec."Credit Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits, expressed in LCY.';
                    Visible = false;
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("FA Posting Category"; Rec."FA Posting Category")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
        }
        area(factboxes)
        {
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
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action("General Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Ledger';
                    Image = GLRegisters;
                    ToolTip = 'View postings that you have made in general ledger.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowGLEntries();
                    end;
                }
                action("Customer Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Ledger';
                    Image = CustomerLedger;
                    ToolTip = 'View postings that you have made in customer ledger.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowCustLedgEntries();
                    end;
                }
                action("Vendor Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Ledger';
                    Image = VendorLedger;
                    ToolTip = 'View postings that you have made in vendor ledger.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowVendLedgEntries();
                    end;
                }
                action("Bank Account Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Ledger';
                    Image = BankAccountLedger;
                    ToolTip = 'View postings that you have made in bank account ledger.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowBankAccLedgEntries();
                    end;
                }
                action("Fixed Asset Ledger")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Asset Ledger';
                    Image = FixedAssetLedger;
                    ToolTip = 'View reversal postings that you have made involving fixed assets.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowFALedgEntries();
                    end;
                }
                action("Maintenance Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Maintenance Ledger';
                    Image = MaintenanceLedgerEntries;
                    ToolTip = 'View postings that you have made in maintenance ledger.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowMaintenanceLedgEntries();
                    end;
                }
                action("VAT Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Ledger';
                    Image = VATLedger;
                    ToolTip = 'View postings that you have made in Tax ledger.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowVATEntries();
                    end;
                }
                action("Tax Difference Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Difference Entry';
                    Image = LedgerEntries;
                    ToolTip = 'View the related entry as a result of posted variations in tax amounts caused by the different rules for recognizing income and expenses between entries for book accounting and tax accounting.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowTaxDiffEntries();
                    end;
                }
                action("Value Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value Entry';
                    Image = VATEntries;
                    ToolTip = 'View the related value entry.';

                    trigger OnAction()
                    begin
                        SetShowFilter();
                        ReversalEntry2.ShowValueEntries();
                    end;
                }
            }
        }
        area(processing)
        {
            group("Re&versing")
            {
                Caption = 'Re&versing';
                Image = Restore;
                action(Reverse)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse';
                    Image = Undo;
                    ShortCutKey = 'F9';
                    ToolTip = 'Reverse selected entries.';

                    trigger OnAction()
                    begin
                        Post(false);
                    end;
                }
                action("Reverse and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse and &Print';
                    Image = Undo;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Reverse and print selected entries.';

                    trigger OnAction()
                    begin
                        Post(true);
                    end;
                }
                action(ReverseOnDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reverse on &Date';
                    Image = Undo;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Reverse all entries with a certain date.';

                    trigger OnAction()
                    begin
                        PostOnDate();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Reverse_Promoted; Reverse)
                {
                }
                actionref("Reverse and &Print_Promoted"; "Reverse and &Print")
                {
                }
                actionref(ReverseOnDate_Promoted; ReverseOnDate)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DescriptionEditable := Rec."Entry Type" <> Rec."Entry Type"::VAT;
    end;

    trigger OnInit()
    begin
        DescriptionEditable := true;
    end;

    trigger OnOpenPage()
    begin
        InitializeFilter();
    end;

    protected var
        ReversalEntry: Record "Reversal Entry";

    var
        BankAccountStatement: Record "Bank Account Statement";
        ReversalEntry2: Record "Reversal Entry";
        MustBe1Or2Msg: Label 'must be %1 or %2', Comment = '%1 - Type of entry GLEntry, %2 - Type of entry VATEntry';
        NotAllowedReverseErr: Label 'You are not allowed to reverse a transaction with an earlier posting date.';
        DescriptionEditable: Boolean;
        UndoBankStatementVisible: Boolean;

        ReverseTransactionEntriesLbl: Label 'Reverse Transaction Entries';
        ReverseRegisterEntriesLbl: Label 'Reverse Register Entries';

    /// <summary>
    /// Sets the bank account statement context for bank reconciliation reversal operations.
    /// </summary>
    /// <param name="NewBankAccountStatement">Bank account statement record to associate with the reversal</param>
    procedure SetBankAccountStatement(NewBankAccountStatement: Record "Bank Account Statement")
    begin
        BankAccountStatement := NewBankAccountStatement;
        UndoBankStatementVisible := true;
    end;

    /// <summary>
    /// Populates the page with reversal entries from a temporary record set for user review.
    /// </summary>
    /// <param name="TempReversalEntry">Temporary reversal entry records to display on the page</param>
    procedure SetReversalEntries(var TempReversalEntry: Record "Reversal Entry" temporary)
    begin
        if not TempReversalEntry.FindSet() then
            exit;
        repeat
            Clear(Rec);
            Rec.Copy(TempReversalEntry);
            Rec.Insert();
        until TempReversalEntry.Next() = 0;
    end;

    /// <summary>
    /// Executes the reversal posting process for selected transaction entries.
    /// </summary>
    /// <param name="PrintRegister">Specifies whether to print the register after posting</param>
    procedure Post(PrintRegister: Boolean)
    var
        ReversalPost: Codeunit "Reversal-Post";
    begin
        OnBeforePost(Rec);
        ReversalPost.SetPrint(PrintRegister);
        ReversalPost.Run(Rec);
        CurrPage.Update(false);
        CurrPage.Close();
    end;

    local procedure GetEntryTypeText() EntryTypeText: Text
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        VATEntry: Record "VAT Entry";
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetEntryTypeText(Rec, EntryTypeText, IsHandled);
        if IsHandled then
            exit(EntryTypeText);

        case Rec."Entry Type" of
            Rec."Entry Type"::"G/L Account":
                exit(GLEntry.TableCaption());
            Rec."Entry Type"::Customer:
                exit(CustLedgEntry.TableCaption());
            Rec."Entry Type"::Vendor:
                exit(VendLedgEntry.TableCaption());
            Rec."Entry Type"::Employee:
                exit(EmployeeLedgerEntry.TableCaption());
            Rec."Entry Type"::"Bank Account":
                exit(BankAccLedgEntry.TableCaption());
            Rec."Entry Type"::"Fixed Asset":
                exit(FALedgEntry.TableCaption());
            Rec."Entry Type"::Maintenance:
                exit(MaintenanceLedgEntry.TableCaption());
            Rec."Entry Type"::VAT:
                exit(VATEntry.TableCaption());
            Rec."Entry Type"::"Tax Difference":
                exit(TaxDiffEntry.TableCaption());
            else
                exit(Format(Rec."Entry Type"));
        end;
    end;

    local procedure InitializeFilter()
    begin
        Rec.FindFirst();
        ReversalEntry := Rec;
        if Rec."Reversal Type" = Rec."Reversal Type"::Transaction then begin
            CurrPage.Caption := ReverseTransactionEntriesLbl;
            ReversalEntry.SetReverseFilter(Rec."Transaction No.", Rec."Reversal Type");
        end else begin
            CurrPage.Caption := ReverseRegisterEntriesLbl;
            ReversalEntry.SetReverseFilter(Rec."G/L Register No.", Rec."Reversal Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure PostOnDate()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        PostingDateForm: Page "VAT Reversal on Date";
        PostingDate: Date;
    begin
        Rec.Reset();
        Rec.SetFilter("Entry Type", '<>%1&<>%2', Rec."Entry Type"::"G/L Account", Rec."Entry Type"::VAT);
        if Rec.FindFirst() then
            Rec.FieldError("Entry Type",
              StrSubstNo(MustBe1Or2Msg, GLEntry.TableCaption(), VATEntry.TableCaption()));

        PostingDate := Rec."Posting Date";
        Clear(PostingDateForm);
        PostingDateForm.SetDate(PostingDate);
        if PostingDateForm.RunModal() = ACTION::Yes then begin
            PostingDate := PostingDateForm.GetDate();
            Rec.Reset();
            if PostingDate <> Rec."Posting Date" then begin
                if PostingDate < Rec."Posting Date" then
                    Error(NotAllowedReverseErr);
                GenJnlLine."Posting Date" := PostingDate;
                GenJnlCheckLine.CheckDateAllowed(GenJnlLine);

                Rec.ModifyAll("Corrected Period Date", Rec."Posting Date");
                Rec.ModifyAll("Posting Date", PostingDate);
                Rec.FindFirst();
                ReversalEntry := Rec;
            end;
            Post(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetShowFilter()
    begin
        if Rec."Reversal Type" = Rec."Reversal Type"::Transaction then
            ReversalEntry2.SetReverseFilter(Rec."Transaction No.", Rec."Reversal Type")
        else
            ReversalEntry2.SetReverseFilter(Rec."G/L Register No.", Rec."Reversal Type");
    end;

    /// <summary>
    /// Integration event raised before generating entry type display text for reversal entries.
    /// </summary>
    /// <param name="ReversalEntry">The reversal entry record for which to generate display text</param>
    /// <param name="Text">Variable to store the generated entry type text</param>
    /// <param name="IsHandled">Set to true to skip default entry type text generation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEntryTypeText(var ReversalEntry: Record "Reversal Entry"; var Text: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TempReversalEntry: Record "Reversal Entry" temporary)
    begin
    end;
}
