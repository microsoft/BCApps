// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

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
                    ToolTip = 'Specifies the number of the transaction that was reversed.';
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
                    ToolTip = 'Specifies the account number that the reversal was posted to.';
                }
                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies erroneous postings that you want to undo by using the Reverse function.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ClosingDates = true;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DescriptionEditable;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document type that the entry belongs to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number of the transaction that created the entry.';
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
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
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
                    ToolTip = 'Specifies the number of the general ledger register, where the general ledger entry in this record was posted.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies where the entry originated.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount on the entry to be reversed.';
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
                field("FA Posting Category"; Rec."FA Posting Category")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting category that is used for fixed assets.';
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
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
                        ReversalEntry.ShowGLEntries();
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
                        ReversalEntry.ShowCustLedgEntries();
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
                        ReversalEntry.ShowVendLedgEntries();
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
                        ReversalEntry.ShowBankAccLedgEntries();
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
                        ReversalEntry.ShowFALedgEntries();
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
                        ReversalEntry.ShowMaintenanceLedgEntries();
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
                        ReversalEntry.ShowVATEntries();
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
                action("Undo Bank Statement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Undo Bank Statement';
                    Image = Undo;
                    Visible = UndoBankStatementVisible;
                    ToolTip = 'Undo the Bank Statement related to these entries.';

                    trigger OnAction()
                    var
                        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
                    begin
                        if (BankAccountStatement."Statement No." <> '') and (BankAccountStatement."Bank Account No." <> '') then
                            if GuiAllowed then
                                if not Confirm(UndoBankStatementQst) then
                                    exit;
                        UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement, false);
                        Message(BankStatementUndoneMsg);
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
                actionref(UndoBankStatement_Promoted; "Undo Bank Statement")
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
        UndoBankStatementVisible: Boolean;
        DescriptionEditable: Boolean;

        ReverseTransactionEntriesLbl: Label 'Reverse Transaction Entries';
        ReverseRegisterEntriesLbl: Label 'Reverse Register Entries';
        UndoBankStatementQst: Label 'Do you want to reverse the bank statement associated to these entries?';
        BankStatementUndoneMsg: Label 'The Bank Account Statement has been undone.';

    procedure SetBankAccountStatement(NewBankAccountStatement: Record "Bank Account Statement")
    begin
        BankAccountStatement := NewBankAccountStatement;
        UndoBankStatementVisible := true;
    end;

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

    procedure Post(PrintRegister: Boolean)
    var
        ReversalPost: Codeunit "Reversal-Post";
    begin
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEntryTypeText(var ReversalEntry: Record "Reversal Entry"; var Text: Text; var IsHandled: Boolean)
    begin
    end;

}

