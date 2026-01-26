// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 11401 "Bank/Giro Journal Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "CBG Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creation date of the statement line.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the CBG statement line of type Cash.';
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the statement line will be posted to.';

                    trigger OnValidate()
                    begin
                        SetAccountName();
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry on the statement line will be posted to.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        SetAccountName();
                    end;
                }
                field(AccountName; AccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the account name that the entry on the statement line will be posted to.';
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that will be applied to, if the journal line will be applied to an already-posted sales or purchase document.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that will be applied to, if the journal line will be applied to an already-posted sales or purchase document.';
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field(Identification; Rec.Identification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an ID number to link the statement line to a payment history line that was sent to and possibly received from the bank.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ShowExtraDescription(true);
                    end;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which salesperson/purchaser is assigned to the statement line.';
                    Visible = false;
                }
                field("Reconciliation Status"; Rec."Reconciliation Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to what extent automatic reconciliation could be performed when the bank statement is imported.';
                }
                field("VAT Type"; Rec."VAT Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT type that will be used when you post the entry on this statement line.';
                    Visible = false;
                }
                field("Amount incl. VAT"; Rec."Amount incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount in the Amount field includes VAT.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group code that will be used when you post the entry on the statement line.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s VAT specification to link transactions made for this vendor or customer with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage that will be used on the statement line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code that the CBG statement line is linked to.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code that the CBG statement line is linked to.';
                    Visible = false;
                }
                field("ShortcutDimcode[3]"; ShortcutDimcode[3])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,2,3';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupShortcutDimCode(3, ShortcutDimcode[3]);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimcode[3]);
                    end;
                }
                field("ShortcutDimcode[4]"; ShortcutDimcode[4])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,2,4';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupShortcutDimCode(4, ShortcutDimcode[4]);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimcode[4]);
                    end;
                }
                field("ShortcutDimcode[5]"; ShortcutDimcode[5])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,2,5';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupShortcutDimCode(5, ShortcutDimcode[5]);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimcode[5]);
                    end;
                }
                field("ShortcutDimcode[6]"; ShortcutDimcode[6])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,2,6';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupShortcutDimCode(6, ShortcutDimcode[6]);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimcode[6]);
                    end;
                }
                field("ShortcutDimcode[7]"; ShortcutDimcode[7])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,2,7';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupShortcutDimCode(7, ShortcutDimcode[7]);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimcode[7]);
                    end;
                }
                field("ShortcutDimcode[8]"; ShortcutDimcode[8])
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,2,8';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupShortcutDimCode(8, ShortcutDimcode[8]);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimcode[8]);
                    end;
                }
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this is a corrective entry.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount (including VAT), that the statement line consists of.';
                    Visible = false;
                }
                field(Debit; Rec.Debit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount (excluding VAT) that the statement line consists of, if it is a debit amount.';
                }
                field(Credit; Rec.Credit)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount (excluding VAT) that the statement line consists of, if it is a credit amount.';
                }
                field("CBGStatement.""Opening Balance"" - TotalNetChange(Text1000000)"; CBGStatement."Opening Balance" - Rec.TotalNetChange(Text1000000))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    Caption = 'Current Balance';
                    Editable = false;
                    ToolTip = 'Specifies the updated balance on the account for the current CBG statement.';
                    Visible = false;
                }
                field("Current net change"; -Rec.TotalNetChange(Text1000000))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    Caption = 'Current Net Change';
                    Editable = false;
                    ToolTip = 'Specifies the updated net change on the account for the current CBG statement.';
                    Visible = false;
                }
                field("Debit VAT"; Rec."Debit VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the debit VAT amount that the statement line consists of.';
                    Visible = false;
                }
                field("Credit VAT"; Rec."Credit VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the credit VAT amount that the statement line consists of.';
                    Visible = false;
                }
                field("Debit Incl. VAT"; Rec."Debit Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total debit amount (including VAT) that the statement line consists of.';
                    Visible = false;
                }
                field("Credit Incl. VAT"; Rec."Credit Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CBGStatement.Currency;
                    AutoFormatType = 1;
                    BlankZero = true;
                    ToolTip = 'Specifies the total credit amount (including VAT) that the statement line consists of.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this entry to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    begin
                        StartApplieFunction();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the account on the line.';

                    trigger OnAction()
                    begin
                        OpenCard();
                    end;
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the bank ledger entries.';

                    trigger OnAction()
                    begin
                        OpenEntries();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(ShowStatementLineDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SEPA Bank Statement Details';
                    RunObject = Page "Bank Statement Line Details";
                    RunPageLink = "Data Exch. No." = field("Data Exch. Entry No."),
                                  "Line No." = field("Data Exch. Line No.");
                    ToolTip = 'View details of an imported bank statement file of type SEPA CAMT.';
                }
            }
            group("&Telebank")
            {
                Caption = '&Telebank';
                Image = ElectronicBanking;
                action("Additional Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Additional Information';
                    ToolTip = 'View or edit additional information about the journal line.';

                    trigger OnAction()
                    begin
                        ShowExtraDescription(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetHeader();
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        SetAccountName();
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimcode);
        Clear(AccName);
        GetHeader();
        if CBGStatement."No." <> 0 then
            Rec.InitRecord(xRec);
        AfterGetCurrentRecord();
    end;

    var
        Text1000000: Label 'CBI';
        CBGStatement: Record "CBG Statement";
        ShortcutDimcode: array[8] of Code[20];
        AccName: Text[100];
        VATStatusEnable: Boolean;
        StatusVATAmountEnable: Boolean;

    [Scope('OnPrem')]
    procedure OpenCard()
    begin
        Rec.OpenAccountCard();
    end;

    [Scope('OnPrem')]
    procedure OpenEntries()
    begin
        Rec.OpenAccountEntries();
    end;

    [Scope('OnPrem')]
    procedure StartApplieFunction()
    var
        GenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        IDCreated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStartApplieFunction(Rec, CBGStatement, IsHandled);
        if IsHandled then
            exit;

        Rec.CreateGenJournalLine(GenJnlLine);
        if GenJnlLine."Applies-to ID" = '' then begin
            GenJnlLine."Applies-to ID" := Rec."New Applies-to ID"();
            IDCreated := true;
        end;
        GenJnlApply.Run(GenJnlLine);
        if not GenJnlApply.GetEntrySelected() then begin
            if IDCreated then
                GenJnlLine."Applies-to ID" := ''
        end else
            Rec.ReadGenJournalLine(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ChangedHeader(Header: Record "CBG Statement")
    begin
        CBGStatement := Header;
    end;

    [Scope('OnPrem')]
    procedure GetHeader()
    var
        UseNumber: Integer;
        UseTemplate: Code[10];
    begin
        Rec.FilterGroup(4);
        UseTemplate := DelChr(Rec.GetFilter("Journal Template Name"), '<>', '''');
        Evaluate(UseNumber, '0' + Rec.GetFilter("No."));
        Rec.FilterGroup(0);

        if UseNumber <> 0 then
            if (CBGStatement."Journal Template Name" <> UseTemplate) or
               (CBGStatement."No." <> UseNumber)
            then
                if not CBGStatement.Get(UseTemplate, UseNumber) then
                    Clear(CBGStatement);
    end;

    [Scope('OnPrem')]
    procedure ShowExtraDescription(Lookup: Boolean)
    var
        CBGStatementlineDescription: Record "CBG Statement Line Add. Info.";
        CBGStatementlineDescriptionfrm: Page "CBG Statement Line Add. Info.";
    begin
        CBGStatementlineDescription.FilterGroup(2);
        CBGStatementlineDescription.SetCurrentKey("Journal Template Name", "CBG Statement No.", "CBG Statement Line No.", "Line No.");
        CBGStatementlineDescription.SetRange("Journal Template Name", Rec."Journal Template Name");
        CBGStatementlineDescription.SetRange("CBG Statement No.", Rec."No.");
        CBGStatementlineDescription.SetRange("CBG Statement Line No.", Rec."Line No.");
        CBGStatementlineDescription.FilterGroup(0);
        CBGStatementlineDescriptionfrm.SetTableView(CBGStatementlineDescription);
        CBGStatementlineDescriptionfrm.LookupMode(Lookup);
        if CBGStatementlineDescriptionfrm.RunModal() = ACTION::LookupOK then begin
            CBGStatementlineDescriptionfrm.GetRecord(CBGStatementlineDescription);
            Rec.Description := CopyStr(CBGStatementlineDescription.Description, 1, MaxStrLen(Rec.Description));
        end;
    end;

    [Scope('OnPrem')]
    procedure GetCurrentRecord(var CBGStatementLine: Record "CBG Statement Line")
    begin
        CBGStatementLine := Rec;
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        VATStatusEnable := Rec."Account Type" = Rec."Account Type"::"G/L Account";
        StatusVATAmountEnable := Rec."Account Type" = Rec."Account Type"::"G/L Account";
    end;

    local procedure SetAccountName()
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        GLAcc: Record "G/L Account";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Cust: Record Customer;
        [SecurityFiltering(SecurityFilter::Filtered)]
        Vend: Record Vendor;
        [SecurityFiltering(SecurityFilter::Filtered)]
        BankAcc: Record "Bank Account";
        [SecurityFiltering(SecurityFilter::Filtered)]
        Employee: Record Employee;
    begin
        if (Rec."Account Type" <> xRec."Account Type") or
           (Rec."Account No." <> xRec."Account No.")
        then begin
            AccName := '';
            if Rec."Account No." <> '' then
                case Rec."Account Type" of
                    Rec."Account Type"::"G/L Account":
                        begin
                            GLAcc.SetLoadFields(Name);
                            if GLAcc.Get(Rec."Account No.") then
                                AccName := GLAcc.Name;
                        end;
                    Rec."Account Type"::Customer:
                        begin
                            Cust.SetLoadFields(Name);
                            if Cust.Get(Rec."Account No.") then
                                AccName := Cust.Name;
                        end;
                    Rec."Account Type"::Vendor:
                        begin
                            Vend.SetLoadFields(Name);
                            if Vend.Get(Rec."Account No.") then
                                AccName := Vend.Name;
                        end;
                    Rec."Account Type"::"Bank Account":
                        begin
                            BankAcc.SetLoadFields(Name);
                            if BankAcc.Get(Rec."Account No.") then
                                AccName := BankAcc.Name;
                        end;
                    Rec."Account Type"::Employee:
                        begin
                            Employee.SetLoadFields("First Name", "Middle Name", "Last Name");
                            if Employee.Get(Rec."Account No.") then
                                AccName := Employee.FullName();
                        end;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartApplieFunction(var CBGStatementLine: Record "CBG Statement Line"; var CBGStatement: Record "CBG Statement"; var IsHandled: Boolean)
    begin
    end;
}

