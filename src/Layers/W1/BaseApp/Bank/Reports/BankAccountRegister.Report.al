// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;

report 1403 "Bank Account Register"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/BankAccountRegister.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Register';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Register"; "G/L Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(G_L_Register__TABLECAPTION__________GLRegFilter; TableCaption + ': ' + GLRegFilter)
            {
            }
            column(GLRegFilter; GLRegFilter)
            {
            }
            column(G_L_Register__No__; "No.")
            {
            }
            column(Bank_Account_Ledger_Entry___Debit_Amount__LCY__; "Bank Account Ledger Entry"."Debit Amount (LCY)")
            {
            }
            column(Bank_Account_Ledger_Entry___Credit_Amount__LCY__; "Bank Account Ledger Entry"."Credit Amount (LCY)")
            {
            }
            column(Bank_Account_Ledger_Entry___Amount__LCY__; "Bank Account Ledger Entry"."Amount (LCY)")
            {
            }
            column(Bank_Account_RegisterCaption; Bank_Account_RegisterCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Posting_Date_Caption; Bank_Account_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Document_Type_Caption; Bank_Account_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Document_No__Caption; "Bank Account Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Bank_Account_Ledger_Entry_DescriptionCaption; "Bank Account Ledger Entry".FieldCaption(Description))
            {
            }
            column(Bank_Account_Ledger_Entry__Bank_Account_No__Caption; "Bank Account Ledger Entry".FieldCaption("Bank Account No."))
            {
            }
            column(BankAcc_NameCaption; BankAcc_NameCaptionLbl)
            {
            }
            column(BankAccAmountCaption; BankAccAmountCaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Entry_No__Caption; "Bank Account Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Bank_Account_Ledger_Entry_OpenCaption; CaptionClassTranslate("Bank Account Ledger Entry".FieldCaption(Open)))
            {
            }
            column(Bank_Account_Ledger_Entry__Remaining_Amount_Caption; "Bank Account Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(G_L_Register__No__Caption; G_L_Register__No__CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry___Debit_Amount__LCY__Caption; Bank_Account_Ledger_Entry___Debit_Amount__LCY__CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry___Credit_Amount__LCY__Caption; Bank_Account_Ledger_Entry___Credit_Amount__LCY__CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry___Amount__LCY__Caption; Bank_Account_Ledger_Entry___Amount__LCY__CaptionLbl)
            {
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(Bank_Account_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Bank_Account_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Bank_Account_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Description; Description)
                {
                }
                column(Bank_Account_Ledger_Entry__Bank_Account_No__; "Bank Account No.")
                {
                }
                column(BankAcc_Name; BankAcc.Name)
                {
                }
                column(BankAccAmount; BankAccAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Bank_Account_Ledger_Entry__Currency_Code_; "Currency Code")
                {
                }
                column(Bank_Account_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Open; Format(Open))
                {
                }
                column(Bank_Account_Ledger_Entry__Remaining_Amount_; "Remaining Amount")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not BankAcc.Get("Bank Account No.") then
                        BankAcc.Init();

                    if PrintAmountsInLCY then begin
                        BankAccAmount := "Amount (LCY)";
                        "Currency Code" := '';
                    end else
                        BankAccAmount := Amount;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
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
        GLRegFilter := "G/L Register".GetFilters();
    end;

    var
        BankAcc: Record "Bank Account";
        GLRegFilter: Text;
        BankAccAmount: Decimal;
        PrintAmountsInLCY: Boolean;
        Bank_Account_RegisterCaptionLbl: Label 'Bank Account Register';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY.';
        Bank_Account_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Bank_Account_Ledger_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        BankAcc_NameCaptionLbl: Label 'Name';
        BankAccAmountCaptionLbl: Label 'Amount';
        G_L_Register__No__CaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        Bank_Account_Ledger_Entry___Debit_Amount__LCY__CaptionLbl: Label 'Debit (LCY)';
        Bank_Account_Ledger_Entry___Credit_Amount__LCY__CaptionLbl: Label 'Credit (LCY)';
        Bank_Account_Ledger_Entry___Amount__LCY__CaptionLbl: Label 'Total (LCY)';
}

