// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

report 28023 "Deposit Slip"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Deposit/DepositSlip.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Deposit Slip';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Account Type", "Account No.", "Document Type", "Document No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(Gen__Journal_Line__Gen__Journal_Line___Account_Type_; "Gen. Journal Line"."Account Type")
            {
            }
            column(Gen__Journal_Line__Gen__Journal_Line___Account_No__; "Gen. Journal Line"."Account No.")
            {
            }
            column(Gen__Journal_Line__Gen__Journal_Line___Document_Type_; "Gen. Journal Line"."Document Type")
            {
            }
            column(CompanyInfo__IRD_No__; CompanyInfo."IRD No.")
            {
            }
            column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(BankAccount__Bank_Account_No__; BankAccount."Bank Account No.")
            {
            }
            column(BankAccount__Bank_Branch_No__; BankAccount."Bank Branch No.")
            {
            }
            column(BankAccount_Name; BankAccount.Name)
            {
            }
            column(CompanyInfo__Fax_No___Control1500018; CompanyInfo."Fax No.")
            {
            }
            column(CompanyInfo__Phone_No___Control1500020; CompanyInfo."Phone No.")
            {
            }
            column(BankAccount__Bank_Account_No___Control1500022; BankAccount."Bank Account No.")
            {
            }
            column(BankAccount__Bank_Branch_No___Control1500024; BankAccount."Bank Branch No.")
            {
            }
            column(BankAccount_Name_Control1500026; BankAccount.Name)
            {
            }
            column(Addr_1_; Addr[1])
            {
            }
            column(Addr_8_; Addr[8])
            {
            }
            column(Addr_7_; Addr[7])
            {
            }
            column(Addr_6_; Addr[6])
            {
            }
            column(Addr_5_; Addr[5])
            {
            }
            column(Addr_4_; Addr[4])
            {
            }
            column(Addr_3_; Addr[3])
            {
            }
            column(Addr_2_; Addr[2])
            {
            }
            column(Gen__Journal_Line__Posting_Date_; Format("Posting Date"))
            {
            }
            column(Gen__Journal_Line__Document_No__; "Document No.")
            {
            }
            column(Gen__Journal_Line_Description; Description)
            {
            }
            column(Gen__Journal_Line__Bank_Branch_No__; "Bank Branch No.")
            {
            }
            column(Gen__Journal_Line__Bank_Account_No__; "Bank Account No.")
            {
            }
            column(Gen__Journal_Line__Credit_Amount_; "Credit Amount")
            {
            }
            column(Gen__Journal_Line__Credit_Amount__Control1500048; "Credit Amount")
            {
            }
            column(Gen__Journal_Line_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Gen__Journal_Line_Journal_Batch_Name; "Journal Batch Name")
            {
            }
            column(Gen__Journal_Line_Line_No_; "Line No.")
            {
            }
            column(Deposit_SlipCaption; Deposit_SlipCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(BankAccount_NameCaption; BankAccount_NameCaptionLbl)
            {
            }
            column(CompanyInfo__IRD_No__Caption; CompanyInfo__IRD_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
            {
            }
            column(BankAccount__Bank_Account_No__Caption; BankAccount__Bank_Account_No__CaptionLbl)
            {
            }
            column(BankAccount__Bank_Branch_No__Caption; BankAccount__Bank_Branch_No__CaptionLbl)
            {
            }
            column(BankAccount_Name_Control1500026Caption; BankAccount_Name_Control1500026CaptionLbl)
            {
            }
            column(CompanyInfo__Fax_No___Control1500018Caption; CompanyInfo__Fax_No___Control1500018CaptionLbl)
            {
            }
            column(CompanyInfo__Phone_No___Control1500020Caption; CompanyInfo__Phone_No___Control1500020CaptionLbl)
            {
            }
            column(BankAccount__Bank_Account_No___Control1500022Caption; BankAccount__Bank_Account_No___Control1500022CaptionLbl)
            {
            }
            column(BankAccount__Bank_Branch_No___Control1500024Caption; BankAccount__Bank_Branch_No___Control1500024CaptionLbl)
            {
            }
            column(Gen__Journal_Line__Posting_Date_Caption; Gen__Journal_Line__Posting_Date_CaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(Gen__Journal_Line__Bank_Account_No__Caption; FieldCaption("Bank Account No."))
            {
            }
            column(Gen__Journal_Line__Bank_Branch_No__Caption; FieldCaption("Bank Branch No."))
            {
            }
            column(Gen__Journal_Line_DescriptionCaption; Gen__Journal_Line_DescriptionCaptionLbl)
            {
            }
            column(Gen__Journal_Line__Document_No__Caption; FieldCaption("Document No."))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                GenJnlBatch.Reset();
                GenJnlBatch.SetRange("Bal. Account Type", "Gen. Journal Line"."Account Type"::"Bank Account");
                GenJnlBatch.SetRange(Name, "Gen. Journal Line"."Journal Batch Name");
                if GenJnlBatch.FindFirst() then begin
                    BankAccount.Reset();
                    BankAccount.SetRange("No.", GenJnlBatch."Bal. Account No.");
                    if BankAccount.FindFirst() then;
                end;

                GenJnlCheckLine.Run("Gen. Journal Line");
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Account Type", '<>%1', "Account Type"::"Bank Account");
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        CompanyInfo.Get();
        FormatAddress.Company(Addr, CompanyInfo);
    end;

    var
        CompanyInfo: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        Addr: array[8] of Text[100];
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        Deposit_SlipCaptionLbl: Label 'Deposit Slip';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        BankAccount_NameCaptionLbl: Label 'Bank Name';
        CompanyInfo__IRD_No__CaptionLbl: Label 'IRD No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone';
        BankAccount__Bank_Account_No__CaptionLbl: Label 'Bank Account No.';
        BankAccount__Bank_Branch_No__CaptionLbl: Label 'Bank Branch No.';
        BankAccount_Name_Control1500026CaptionLbl: Label 'Bank Name';
        CompanyInfo__Fax_No___Control1500018CaptionLbl: Label 'Fax';
        CompanyInfo__Phone_No___Control1500020CaptionLbl: Label 'Phone';
        BankAccount__Bank_Account_No___Control1500022CaptionLbl: Label 'Bank Account No.';
        BankAccount__Bank_Branch_No___Control1500024CaptionLbl: Label 'Bank Branch No.';
        Gen__Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        AmountCaptionLbl: Label 'Amount';
        Gen__Journal_Line_DescriptionCaptionLbl: Label 'Drawer';
        TotalCaptionLbl: Label 'Total';
}

