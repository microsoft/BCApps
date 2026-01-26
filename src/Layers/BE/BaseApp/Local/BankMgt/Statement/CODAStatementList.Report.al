// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

report 2000041 "CODA Statement - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Statement/CODAStatementList.rdlc';
    Caption = 'CODA Statement - List';

    dataset
    {
        dataitem(CodBankStmt; "CODA Statement")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");
            RequestFilterFields = "Bank Account No.", "Statement No.";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(BankAcctNo_CodBankStmt; "Bank Account No.")
            {
            }
            column(StmtNo_CodBankStmt; "Statement No.")
            {
            }
            column(StmtEndingBal_CodBankStmt; "Statement Ending Balance")
            {
            }
            column(StmtDate_CodBankStmt; "Statement Date")
            {
            }
            column(BalLastStmt_CodBankStmt; "Balance Last Statement")
            {
            }
            column(PrintAll; PrintAll)
            {
            }
            column(CODAStmtUnappliedStmtLinesCaptionLbl; CODAStmtUnappliedStmtLinesCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BalLastStmtCaption_CodBankStmt; FieldCaption("Balance Last Statement"))
            {
            }
            column(StmtDateCaption_CodBankStmt; FieldCaption("Statement Date"))
            {
            }
            column(StmtEndingBalCaption_CodBankStmt; FieldCaption("Statement Ending Balance"))
            {
            }
            column(StmtNoCaption_CodBankStmt; FieldCaption("Statement No."))
            {
            }
            column(BankAcctNoCaption_CodBankStmt; FieldCaption("Bank Account No."))
            {
            }
            dataitem(CodBankStmtMessage; "CODA Statement Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type) where(ID = const("Free Message"), "Attached to Line No." = const(0));
                column(CodBankStmtMessage__Statement_Message_; "Statement Message")
                {
                }
                column(CodBankStmtMessage_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(CodBankStmtMessage_Statement_No_; "Statement No.")
                {
                }
                column(CodBankStmtMessage_Statement_Line_No_; "Statement Line No.")
                {
                }
            }
            dataitem(CodBankStmtLine; "CODA Statement Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type) where(ID = const(Movement));
                column(DocNo_CodBankStmtLine; "Document No.")
                {
                }
                column(StmtMessage_CodBankStmtLine; "Statement Message")
                {
                }
                column(PartDetails_CodBankStmtLine; "Name Other Party" + ' ' + "Address Other Party" + ' ' + "City Other Party")
                {
                }
                column(StmtAmt_CodBankStmtLine; "Statement Amount")
                {
                }
                column(PostingDate_CodBankStmtLine; "Posting Date")
                {
                }
                column(AcctType_CodBankStmtLine; "Account Type")
                {
                }
                column(AcctNo_CodBankStmtLine; "Account No.")
                {
                }
                column(ApplicationInfo_CodBankStmtLine; "Application Information")
                {
                }
                column(Desc_CodBankStmtLine; Description)
                {
                }
                column(Balance2; Balance[2])
                {
                }
                column(Balance1; Balance[1])
                {
                }
                column(DebitBalCaption; DebitBalCaptionLbl)
                {
                }
                column(CreditBalCaption; CreditBalCaptionLbl)
                {
                }
                column(BankAcctNo_CodBankStmtLine; "Bank Account No.")
                {
                }
                column(StmtNo_CodBankStmtLine; "Statement No.")
                {
                }
                column(StmtLineNo_CodBankStmtLine; "Statement Line No.")
                {
                }
                dataitem(InfoLine; "CODA Statement Line")
                {
                    DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No."), "Attached to Line No." = field("Statement Line No.");
                    DataItemTableView = sorting("Bank Account No.", "Statement No.", ID, "Attached to Line No.", Type) where(ID = const("Free Message"));
                    column(StmtMessage_InfoLine; "Statement Message")
                    {
                    }
                    column(BankAcctNo_InfoLine; "Bank Account No.")
                    {
                    }
                    column(StmtNo_InfoLine; "Statement No.")
                    {
                    }
                    column(StmtLineNo_InfoLine; "Statement Line No.")
                    {
                    }
                    column(AttachedtoLineNo_InfoLine; "Attached to Line No.")
                    {
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Type = Type::Global then
                        if "Statement Amount" > 0 then
                            Balance[1] := Balance[1] + "Statement Amount"
                        else
                            Balance[2] := Balance[2] - "Statement Amount";

                    if (PrintAll = false) and
                       ("Application Status" = "Application Status"::Applied) and
                       ("Application Information" = '')
                    then
                        CurrReport.Skip();
                end;
            }
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
                    field(PrintAll; PrintAll)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print all Lines';
                        ToolTip = 'Specifies if you want to print all the bank account statement lines or only the unapplied lines.';
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

    var
        PrintAll: Boolean;
        Balance: array[2] of Decimal;
        CODAStmtUnappliedStmtLinesCaptionLbl: Label 'CODA Statement - Unapplied Statement Lines';
        PageCaptionLbl: Label 'Page';
        DebitBalCaptionLbl: Label 'Debit Balance';
        CreditBalCaptionLbl: Label 'Credit Balance';

    procedure SetSelection(PrintingAll: Boolean)
    begin
        PrintAll := PrintingAll;
    end;
}

