// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 3010832 "LSV Collection Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/LSVCollectionJournal.rdlc';
    Caption = 'LSV Collection Journal';

    dataset
    {
        dataitem("LSV Journal Line"; "LSV Journal Line")
        {
            DataItemTableView = sorting("LSV Journal No.", "Line No.") order(ascending);
            column(LSVJnlNo_LSVJnlLine; "LSV Journal No.")
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustNo_LSVJnlLine; "Customer No.")
            {
            }
            column(CreditDate_LsvJournal; LsvJournal."Credit Date")
            {
            }
            column(DueDate_CustLedgEntry; CustLedgEntry."Due Date")
            {
            }
            column(AppliesToDocNo_LSVJnlLine; "Applies-to Doc. No.")
            {
            }
            column(BankBranchNo_DebBank; DebBank."Bank Branch No.")
            {
            }
            column(xTxt; xTxt)
            {
            }
            column(CollectionAmt_LSVJnlLine; "Collection Amount")
            {
            }
            column(BankAcc; BankAcc)
            {
            }
            column(Amt_CustLedgEntry; CustLedgEntry.Amount)
            {
            }
            column(OriginalPmtDiscPossible_CustLedgEntry; CustLedgEntry."Remaining Pmt. Disc. Possible")
            {
            }
            column(WithBlankLine; WithBlankLine)
            {
            }
            column(NoOfLines; NoOfLines)
            {
            }
            column(LargestAmt; LargestAmt)
            {
            }
            column(LSVCurrCode_LsvSetup; LsvSetup."LSV Currency Code")
            {
            }
            column(BatchNameCaption; BatchNameCaptionLbl)
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(DueCaption; DueCaptionLbl)
            {
            }
            column(ApplicationCaption; ApplicationCaptionLbl)
            {
            }
            column(ClearingCaption; ClearingCaptionLbl)
            {
            }
            column(CommentCaption; CommentCaptionLbl)
            {
            }
            column(CollectionAmtCaption; CollectionAmtCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(LSVCollectionJournalCaption; LSVCollectionJournalCaptionLbl)
            {
            }
            column(AccountCaption; AccountCaptionLbl)
            {
            }
            column(CustEntryCaption; CustEntryCaptionLbl)
            {
            }
            column(CashDiscCaption; CashDiscCaptionLbl)
            {
            }
            column(NoofEntriesCaption; NoofEntriesCaptionLbl)
            {
            }
            column(MaximumAmtCaption; MaximumAmtCaptionLbl)
            {
            }
            column(TotalAmtCaption; TotalAmtCaptionLbl)
            {
            }
            column(LineNo_LSVJnlLine; "Line No.")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ("Customer No." = '') and ("Collection Amount" = 0) then
                    CurrReport.Skip();

                xTxt := '';
                BankAcc := '';
                Clear(CustLedgEntry);
                Clear(DebBank);

                NoOfLines := NoOfLines + 1;

                if "Collection Amount" > LargestAmt then
                    LargestAmt := "Collection Amount";

                // Customer Entries
                if "Applies-to Doc. No." = '' then
                    xTxt := Text000
                else begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                    CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", "Customer No.");

                    if not CustLedgEntry.FindFirst() then
                        xTxt := Text001;
                    if not CustLedgEntry.Open then
                        xTxt := Text002;
                    if not (CustLedgEntry."Currency Code" in [LsvSetup."LSV Currency Code", '']) then
                        xTxt := Text003;

                    CustLedgEntry.CalcFields(Amount, "Remaining Amount");
                    if "Collection Amount" <> CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible" then
                        xTxt := Text004;
                end;

                // Credit Memos exist
                CrMemoCustEntry.SetCurrentKey("Customer No.", Open, Positive);
                CrMemoCustEntry.SetRange("Customer No.", "Customer No.");
                CrMemoCustEntry.SetRange(Open, true);
                CrMemoCustEntry.SetRange(Positive, false);
                if CrMemoCustEntry.FindFirst() then
                    xTxt := Text005;

                // Cust. Bank
                DebBank.Reset();
                DebBank.SetRange("Customer No.", "Customer No.");
                if DebBank.Count > 1 then
                    DebBank.SetRange(Code, LsvSetup."LSV Customer Bank Code");

                if not DebBank.FindFirst() then
                    xTxt := Text006;

                if LsvSetup."DebitDirect Customerno." = '' then begin
                    if DebBank."Bank Branch No." = '' then
                        xTxt := Text007;
                    if (DebBank."Bank Account No." = '') and (DebBank.IBAN = '') then
                        xTxt := Text008;
                end else
                    if DebBank."Giro Account No." = '' then
                        xTxt := Text009;

                if DebBank.IBAN <> '' then
                    BankAcc := DebBank.IBAN
                else
                    BankAcc := DebBank."Bank Account No.";
            end;

            trigger OnPreDataItem()
            begin
                "LSV Journal Line".SetRange("LSV Journal No.", LsvJournal."No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("LsvJournal.""No."""; LsvJournal."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No.';
                        Editable = false;
                        ToolTip = 'Specifies the number.';
                    }
                    field("LsvSetup.""Bank Code"""; LsvSetup."Bank Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'LSV Bank Code';
                        Editable = false;
                        ToolTip = 'Specifies the LSV bank code that you want to print on the report.';
                    }
                    field(WithBlankLine; WithBlankLine)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'With blank line';
                        ToolTip = 'Specifies if you want to include blank lines on the report.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if LsvJournal."LSV Bank Code" = '' then
            Error(Text020);
    end;

    var
        Text000: Label 'Missing application no.';
        Text001: Label 'Customer ledger entry not found';
        Text002: Label 'Customer entry is not open';
        Text003: Label 'Invalid currency code';
        Text004: Label 'Collection amount not equal open amount.';
        Text005: Label 'Customer has open credit memos';
        Text006: Label 'No valid LSV bank';
        Text007: Label 'Clearingno. missing';
        Text008: Label 'Bank Account No. or IBAN missing';
        Text009: Label 'Post Account missing';
        Text020: Label 'You can start this report only from LSV Journal.';
        LsvSetup: Record "LSV Setup";
        DebBank: Record "Customer Bank Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CrMemoCustEntry: Record "Cust. Ledger Entry";
        LsvJournal: Record "LSV Journal";
        NoOfLines: Integer;
        WithBlankLine: Boolean;
        xTxt: Text[80];
        BankAcc: Text[34];
        LargestAmt: Decimal;
        BatchNameCaptionLbl: Label 'Batch Name';
        CustomerCaptionLbl: Label 'Customer';
        DateCaptionLbl: Label 'Date';
        DueCaptionLbl: Label 'Due';
        ApplicationCaptionLbl: Label 'Application';
        ClearingCaptionLbl: Label 'Clearing';
        CommentCaptionLbl: Label 'Comment';
        CollectionAmtCaptionLbl: Label 'CollectionAmt';
        PageNoCaptionLbl: Label 'Page';
        LSVCollectionJournalCaptionLbl: Label 'LSV Collection Journal';
        AccountCaptionLbl: Label 'Account';
        CustEntryCaptionLbl: Label 'Cust. Entry';
        CashDiscCaptionLbl: Label 'Cash Disc.';
        NoofEntriesCaptionLbl: Label 'No. of Entries';
        MaximumAmtCaptionLbl: Label 'Maximum Amount:';
        TotalAmtCaptionLbl: Label 'Total Amount:';

    [Scope('OnPrem')]
    procedure SetGlobals(ActualLSVJourLine: Record "LSV Journal Line")
    begin
        LsvJournal.Get(ActualLSVJourLine."LSV Journal No.");
        LsvJournal.TestField("LSV Bank Code");

        LsvSetup.Get(LsvJournal."LSV Bank Code");
    end;
}

