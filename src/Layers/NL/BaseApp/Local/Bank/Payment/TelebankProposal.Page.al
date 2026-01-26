// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Telemetry;

page 11000001 "Telebank Proposal"
{
    Caption = 'Telebank Proposal';
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Proposal Line";
    SourceTableView = sorting("Our Bank No.", "Line No.");

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(BankAccFilter; BankAccFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank';
                    LookupPageID = "Telebank - Bank Overview";
                    NotBlank = true;
                    TableRelation = "Bank Account"."No.";
                    ToolTip = 'Specifies the name of the bank account to be shown in the window.';

                    trigger OnValidate()
                    begin
                        BankAccFilterOnAfterValidate();
                    end;
                }
                field("Bnk.""Currency Code"""; BankAccount."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code';
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the amounts on the proposal line.';
                }
                field(BankAccountNo; BankAccount."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer or vendor bank account that the proposal is made for. ';
                }
                field(BankAccountBalance; BankAccount.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = BankAccount."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Control30; Rec.Process)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the proposal line will be processed into a payment history.';

                    trigger OnValidate()
                    begin
                        ProcessOnAfterValidate();
                    end;
                }
                field(Docket; Rec.Docket)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you want a docket to be generated for this payment.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account for which the proposal line will be created.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account that the proposal line will be created for.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account name associated with the proposal line.';
                    Visible = false;
                }
                field("Transaction Mode"; Rec."Transaction Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction mode used in telebanking.';
                }
                field("Order"; Rec.Order)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order type of the proposal line.';
                    Visible = false;
                }
                field(Bank; Rec.Bank)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number for the bank you want to perform payments to, or collections from.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account number you want to perform payments to, or collections from.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank account number for the line Bank Account No. field.';
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank as given in the Bank field.';
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "SEPA Direct Debit Mandates";
                    TableRelation = "Direct Debit Collection".Identifier where(Identifier = field("Direct Debit Mandate ID"));
                    ToolTip = 'Specifies the direct debit mandate of the customer that this collection proposal is for.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total amount (including VAT) for the proposal line.';
                    Visible = true;

                    trigger OnValidate()
                    begin
                        Rec.CalcFields("Number of Detail Lines");
                        if Rec."Number of Detail Lines" > 0 then
                            Error(Text1000000 + Text1000001, Rec.FieldCaption(Amount));
                    end;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the total amount (including VAT) on the proposal line in LCY.';
                    Visible = false;
                }
                field("Foreign Currency"; Rec."Foreign Currency")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Currency';
                    ToolTip = 'Specifies the currency code of the documents from which the proposal line is created. If the field is empty, the document currency is either the local currency or the bank''s currency.';
                }
                field("Foreign Amount"; Rec."Foreign Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount in Document Currency';
                    ToolTip = 'Specifies the total amount for the proposal line in the currency specified in the Document Currency field. The value is specified when the document currency differs from the bank''s currency.';
                }
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when you want the payment or collection to be performed.';
                }
                field(Identification; Rec.Identification)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies the identification number for the proposal line.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.IdentificationAssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Description 1"; Rec."Description 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the proposal line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the proposal line.';
                    Visible = false;
                }
                field("Description 3"; Rec."Description 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the proposal line.';
                    Visible = false;
                }
                field("Description 4"; Rec."Description 4")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the proposal line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the amounts on the proposal line.';
                    Visible = false;
                }
                field("Account Holder Name"; Rec."Account Holder Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s name.';
                    Visible = false;
                }
                field("Account Holder Address"; Rec."Account Holder Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s address.';
                    Visible = false;
                }
                field("Account Holder Post Code"; Rec."Account Holder Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s postal code.';
                    Visible = false;
                }
                field("Account Holder City"; Rec."Account Holder City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account owner''s city.';
                    Visible = false;
                }
                field("Acc. Hold. Country/Region Code"; Rec."Acc. Hold. Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the bank account holder.';
                    Visible = false;
                }
                field("Bank Name"; Rec."Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank you want to perform payments to, or collections from.';
                    Visible = false;
                }
                field("Bank Address"; Rec."Bank Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the bank you want to perform payments to, or collections from.';
                    Visible = false;
                }
                field("Bank City"; Rec."Bank City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                    Visible = false;
                }
                field("Bank Country/Region Code"; Rec."Bank Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the bank number.';
                    Visible = false;
                }
                field("National Bank Code"; Rec."National Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification code of the national bank associated with the telebanking payment or collection proposal.';
                    Visible = false;
                }
                field("Transfer Cost Foreign"; Rec."Transfer Cost Foreign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who will bear the expenses of the payment or collection charged by the foreign bank.';
                    Visible = false;
                }
                field("Transfer Cost Domestic"; Rec."Transfer Cost Domestic")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who will bear the expenses of the payment or collection.';
                    Visible = false;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a message when an error occurs while entering the proposal line.';
                    Visible = false;
                }
                field(Warning; Rec.Warning)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a warning message concerning the proposal line.';
                    Visible = false;
                }
                field("Description Payment"; Rec."Description Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description related to the nature of the payment.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number the Dutch Central Bank (DNB) issues to transito traders, to identify goods being sold and purchased by these traders.';
                    Visible = false;
                }
                field("Traders No."; Rec."Traders No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the Dutch Central Bank (DNB) has issued to transito traders.';
                    Visible = false;
                }
                field(Urgent; Rec.Urgent)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the payment should be performed urgently.';
                    Visible = false;
                }
                field("Registration No. DNB"; Rec."Registration No. DNB")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the Dutch Central Bank (DNB) issued to the account owner, to identify a number of types of foreign payments.';
                    Visible = false;
                }
                field("Nature of the Payment"; Rec."Nature of the Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the nature of the payment for the proposal line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code associated with the proposal.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the dimension value code that the proposal line will be associated with.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Suite;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
            group(Control39)
            {
                ShowCaption = false;
                label(MessageLabel)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(ErrorWarningLabelText());
                    Editable = false;
                }
                field(Message; ErrorWarningText())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error message';
                    Editable = false;
                    Enabled = MessageEnable;
                    ToolTip = 'Specifies the text of any warning or error message concerning the proposal line.';
                }
                field("Bnk.""Credit limit"""; BankAccount.GetCreditLimit())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = BankAccount."Currency Code";
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Credit Limit';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount available to use for payments.';
                }
                field(TotalAmount; TotAmount())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = BankAccount."Currency Code";
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Total Amount';
                    Editable = false;
                    Enabled = TotalAmountEnable;
                    ToolTip = 'Specifies the total of all Amount fields of all proposal lines.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Pr&oposal")
            {
                Caption = 'Pr&oposal';
                Image = SuggestElectronicDocument;
                action(HeaderDimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowHeaderDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Detail Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detail Information';
                    Image = ViewDetails;
                    RunObject = Page "Proposal Detail Line";
                    RunPageLink = "Our Bank No." = field("Our Bank No."),
                                  "Line No." = field("Line No.");
                    RunPageView = sorting("Our Bank No.", "Line No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View invoice-level information for the line.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions - Single")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Dimensions - Single';
                        Image = Dimensions;
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        begin
                            Rec.ShowDimensions();
                            CurrPage.SaveRecord();
                        end;
                    }
                }
                separator(Action1000006)
                {
                }
                action(Action1000013)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To Other Bank';
                    Ellipsis = true;
                    Image = ExportToBank;
                    ToolTip = 'Transfer the selected proposal to another bank account from where you want to process it. ';

                    trigger OnAction()
                    var
                        BankAcc: Record "Bank Account";
                        "Bank Account List": Page "Bank Account List";
                        PropLine: Record "Proposal Line";
                    begin
                        BankAcc.Get(Rec."Our Bank No.");
                        "Bank Account List".SetRecord(BankAcc);
                        "Bank Account List".LookupMode(true);
                        if "Bank Account List".RunModal() = ACTION::LookupOK then begin
                            "Bank Account List".GetRecord(BankAcc);
                            if BankAcc."No." <> Rec."Our Bank No." then begin
                                BankAcc.TestField("Currency Code", Rec."Currency Code");
                                if Confirm(StrSubstNo(Text1000002, Rec.TableCaption(), Rec."Our Bank No.", BankAcc."No.")) then begin
                                    PropLine.SetCurrentKey("Our Bank No.");
                                    PropLine.SetRange("Our Bank No.", BankAcc."No.");
                                    if PropLine.FindLast() then
                                        Rename(BankAcc."No.", Format(PropLine."Line No." + 10000))
                                    else
                                        Rename(BankAcc."No.", Format(10000));
                                end;
                            end;
                        end;
                    end;
                }
                group("A&ccount")
                {
                    Caption = 'A&ccount';
                    Image = ChartOfAccounts;
                    action("&Card")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Card';
                        Image = EditLines;
                        ShortCutKey = 'Shift+F7';
                        ToolTip = 'View detailed information about the Telebank proposal.';

                        trigger OnAction()
                        var
                            Vend: Record Vendor;
                            Cust: Record Customer;
                            Empl: Record Employee;
                        begin
                            case Rec."Account Type" of
                                Rec."Account Type"::Vendor:
                                    begin
                                        Vend.Get(Rec."Account No.");
                                        PAGE.Run(PAGE::"Vendor Card", Vend);
                                    end;
                                Rec."Account Type"::Customer:
                                    begin
                                        Cust.Get(Rec."Account No.");
                                        PAGE.Run(PAGE::"Customer Card", Cust);
                                    end;
                                Rec."Account Type"::Employee:
                                    begin
                                        Empl.Get(Rec."Account No.");
                                        PAGE.Run(PAGE::"Employee Card", Empl);
                                    end;
                            end;
                        end;
                    }
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the bank ledger entries.';

                        trigger OnAction()
                        var
                            VendLedgEntry: Record "Vendor Ledger Entry";
                            CustLedgEntry: Record "Cust. Ledger Entry";
                            EmplLedgEntry: Record "Employee Ledger Entry";
                        begin
                            case Rec."Account Type" of
                                Rec."Account Type"::Vendor:
                                    begin
                                        VendLedgEntry.SetRange("Vendor No.", Rec."Account No.");
                                        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                                    end;
                                Rec."Account Type"::Customer:
                                    begin
                                        CustLedgEntry.SetRange("Customer No.", Rec."Account No.");
                                        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                                    end;
                                Rec."Account Type"::Employee:
                                    begin
                                        EmplLedgEntry.SetRange("Employee No.", Rec."Account No.");
                                        PAGE.Run(PAGE::"Employee Ledger Entries", EmplLedgEntry);
                                    end;
                            end;
                        end;
                    }
                }
            }
        }
        area(processing)
        {
            separator(Action1000002)
            {
            }
            action(GetEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Entries';
                Ellipsis = true;
                Image = GetEntries;
                ToolTip = 'Generate proposal lines for payments or collections based on vendor or customer ledger entries.';

                trigger OnAction()
                var
                    TrMode: Record "Transaction Mode";
                begin
                    FeatureTelemetry.LogUptake('1000HT1', NLTeleBankingTok, Enum::"Feature Uptake Status"::"Set up");
                    TrMode.SetRange("Our Bank", BankAccFilter);
                    REPORT.RunModal(REPORT::"Get Proposal Entries", true, true, TrMode);
                    if Rec.Find('+') then;
                    CurrPage.Update(false);
                end;
            }
            separator(Action1000004)
            {
            }
            action(Check)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check';
                Image = Check;
                RunPageOnRec = false;
                ShortCutKey = 'Shift+F9';
                ToolTip = 'Validate the proposal line before you process it.';

                trigger OnAction()
                begin
                    ProcessingLines.Run(Rec);
                    ProcessingLines.CheckProposallines();
                end;
            }
            action(Process)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Process';
                Image = Setup;
                ShortCutKey = 'F9';
                ToolTip = 'Process the payment or collection proposals. After you processed a proposal, the proposal will be empty and the payments/collections will be posted to the payment history.';

                trigger OnAction()
                begin
                    ProcessingLines.Run(Rec);
                    ProcessingLines.ProcessProposallines();
                end;
            }
            separator(Action1000005)
            {
            }
            action("To Other Bank")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'To Other Bank';
                Ellipsis = true;
                Image = ExportToBank;
                ToolTip = 'Transfer the selected proposal to another bank account from where you want to process it. ';

                trigger OnAction()
                var
                    BankAcc: Record "Bank Account";
                    "Bank Account List": Page "Bank Account List";
                    Propline: Record "Proposal Line";
                begin
                    BankAcc.Get(Rec."Our Bank No.");
                    "Bank Account List".SetRecord(BankAcc);
                    "Bank Account List".LookupMode(true);
                    if "Bank Account List".RunModal() = ACTION::LookupOK then begin
                        "Bank Account List".GetRecord(BankAcc);
                        if BankAcc."No." <> Rec."Our Bank No." then begin
                            BankAcc.TestField("Currency Code", Rec."Currency Code");
                            if Confirm(StrSubstNo(Text1000002, Rec.TableCaption(), Rec."Our Bank No.", BankAcc."No.")) then
                                case StrMenu(Text1000005) of
                                    1:
                                        MoveLineToOtherBank(Propline, BankAcc);
                                    2:
                                        if Rec.Find('-') then
                                            repeat
                                                MoveLineToOtherBank(Propline, BankAcc);
                                            until Rec.Next() = 0;
                                    else
                                        exit;
                                end;
                        end;
                    end;
                end;
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the information in the window.';

                trigger OnAction()
                var
                    Bnk2: Record "Bank Account";
                begin
                    Bnk2.SetFilter("No.", BankAccFilter);
                    REPORT.Run(REPORT::"Proposal Overview", true, true, Bnk2);
                end;
            }
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Select All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select All';
                    Image = AllLines;
                    ToolTip = 'Select the Process check box on all lines.';

                    trigger OnAction()
                    begin
                        Rec.SelectAll();
                    end;
                }
                action("Deselect All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Deselect All';
                    Image = CancelAllLines;
                    ToolTip = 'Deselect the Process check box on all lines.';

                    trigger OnAction()
                    begin
                        Rec.DeselectAll();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GetEntries_Promoted; GetEntries)
                {
                }
                actionref(Process_Promoted; Process)
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Select All_Promoted"; "Select All")
                {
                }
                actionref("Deselect All_Promoted"; "Deselect All")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        BankAccFilterOnFormat();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        MessageEnable := true;
        TotalAmountEnable := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Prop: Record "Proposal Line";
    begin
        if Rec."Our Bank No." = '' then
            exit(false);

        Prop := xRec;
        Prop.SetRange("Our Bank No.", Rec."Our Bank No.");

        if BelowxRec or (xRec."Our Bank No." <> Rec."Our Bank No.") then begin
            if Prop.FindLast() then
                Rec."Line No." := Prop."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end else begin
            Prop.SetFilter("Line No.", '<%1', xRec."Line No.");
            if Prop.FindLast() then
                Rec."Line No." := Round((Prop."Line No." + xRec."Line No.") / 2, 1)
            else
                Rec."Line No." := Round(xRec."Line No." / 2, 1);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    begin
        if Rec.GetFilter("Our Bank No.") = '' then begin
            Clear(BankAccount);
            BankAccount.FindFirst();
            Rec.SetRange("Our Bank No.", BankAccount."No.");
            BankAccFilter := BankAccount."No.";
        end;

        BankAccFilterOnFormat();
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NLTeleBankingTok: Label 'NL Telebanking', Locked = true;
        Text1000000: Label '%1 cannot be processed manually when detail information is present.\';
        Text1000001: Label 'To modify go to line detail information.';
        Text1000002: Label 'Moving %1 from %2 to %3';
        Text1000003: Label 'Error Message';
        Text1000004: Label 'Warning';
        BankAccount: Record "Bank Account";
        ProcessingLines: Codeunit "Process Proposal Lines";
        Text1000005: Label 'Current Line,All Lines';
        ShortcutDimCode: array[8] of Code[20];
        TotalAmountEnable: Boolean;
        MessageEnable: Boolean;

    protected var
        BankAccFilter: Code[80];

    [Scope('OnPrem')]
    procedure MoveLineToOtherBank(var PropLine: Record "Proposal Line"; var BankAcc: Record "Bank Account")
    var
        PropLine2: Record "Proposal Line";
    begin
        PropLine2 := Rec;
        PropLine2.CopyFilters(Rec);
        PropLine.SetCurrentKey("Our Bank No.");
        PropLine.SetRange("Our Bank No.", BankAcc."No.");
        if PropLine.Find('+') then
            PropLine2.Rename(BankAcc."No.", PropLine."Line No." + 10000)
        else
            PropLine2.Rename(BankAcc."No.", 10000);
    end;

    [Scope('OnPrem')]
    procedure TotAmount() Res: Decimal
    var
        Propline: Record "Proposal Line";
    begin
        Propline := Rec;
        Propline.CopyFilters(Rec);
        Propline.SetRange(Process, true);
        Propline.SetCurrentKey(
          "Our Bank No.", Process, "Account Type", "Account No.", Bank, "Transaction Mode", "Currency Code", "Transaction Date");

        if Propline.CalcSums(Amount) then begin
            TotalAmountEnable := true;
            Res := Propline.Amount;
        end else begin
            TotalAmountEnable := false;
            Res := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ErrorWarningLabelText() Text: Text[100]
    begin
        case true of
            Rec."Error Message" <> '':
                Text := Text1000003;
            Rec.Warning <> '':
                Text := Text1000004;
            else
                Text := '';
        end;
    end;

    [Scope('OnPrem')]
    procedure ErrorWarningText() Text: Text[125]
    begin
        case true of
            Rec."Error Message" <> '':
                Text := Rec."Error Message";
            Rec.Warning <> '':
                Text := Rec.Warning;
            else
                Text := '';
        end;

        MessageEnable := Text <> '';
    end;

    local procedure ProcessOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure BankAccFilterOnAfterValidate()
    begin
        Rec.SetFilter("Our Bank No.", BankAccFilter);
        CurrPage.Update();
    end;

    local procedure BankAccFilterOnFormat()
    begin
        if (BankAccFilter <> '') and (BankAccFilter = BankAccount."No.") then
            exit;

        Clear(BankAccount);
        BankAccount.Get(Rec.GetFilter("Our Bank No."));
        BankAccount.CalcFields(Balance);
        BankAccFilter := BankAccount."No.";
    end;
}

