// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 32000001 "Ref. Payment Imported"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Payment/RefPaymentImported.rdlc';
    Caption = 'Ref. Payment Imported';

    dataset
    {
        dataitem(RefPmtImp; "Ref. Payment - Imported")
        {
            DataItemTableView = sorting("No.") order(ascending) where("Posted to G/L" = const(false));
            RequestFilterFields = "Banks Posting Date";
            column(Time; Time)
            {
            }
            column(Today; Today)
            {
            }
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(PayersName_RefPmtImp; "Payers Name")
            {
            }
            column(FilingCode_RefPmtImp; "Filing Code")
            {
            }
            column(ReferenceNo_RefPmtImp; "Reference No.")
            {
            }
            column(Amount_RefPmtImp; Amount)
            {
            }
            column(BanksPostingDate_RefPmtImp; "Banks Posting Date")
            {
            }
            column(ImportedReferencePaymentsCaption; ImportedReferencePaymentsCaptionLbl)
            {
            }
            column(AikaCaption; AikaCaptionLbl)
            {
            }
            column(PvmCaption; PvmCaptionLbl)
            {
            }
            column(PayersNameCaption_RefPmtImp; FieldCaption("Payers Name"))
            {
            }
            column(FilingCodeCaption_RefPmtImp; FieldCaption("Filing Code"))
            {
            }
            column(ReferenceNoCaption_RefPmtImp; FieldCaption("Reference No."))
            {
            }
            column(AmountCaption_RefPmtImp; FieldCaption(Amount))
            {
            }
            column(CustLedgerEntryRemainingAmtLCYCaption; "Cust. Ledger Entry".FieldCaption("Remaining Amt. (LCY)"))
            {
            }
            column(CustLedgerEntryOriginalAmtLCYCaption; "Cust. Ledger Entry".FieldCaption("Original Amt. (LCY)"))
            {
            }
            column(CustLedgerEntryDocumentNoCaption; "Cust. Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(RefPmtImpBanksPostingDateCaption; FieldCaption("Banks Posting Date"))
            {
            }
            column(No_RefPmtImp; "No.")
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                DataItemTableView = sorting("Entry No.");

                trigger OnAfterGetRecord()
                begin
                    "Cust. Ledger Entry".CalcFields("Original Amt. (LCY)", "Remaining Amt. (LCY)");
                end;
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = field("Customer No.");
                DataItemTableView = sorting("No.");
                column(CustomerName; Name)
                {
                }
                column(CustLedgerEntryReferenceNo; "Cust. Ledger Entry"."Reference No.")
                {
                }
                column(CustLedgerEntryDocumentNo; "Cust. Ledger Entry"."Document No.")
                {
                }
                column(CustLedgerEntryOriginalAmtLCY; "Cust. Ledger Entry"."Original Amt. (LCY)")
                {
                }
                column(CustLedgerEntryRemainingAmtLCY; "Cust. Ledger Entry"."Remaining Amt. (LCY)")
                {
                }
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                column(Number_IntegerLine; Number)
                {
                }
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                SetFilter("Record ID", '%1..%2', 3, 5);
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

    var
        CompanyInfo: Record "Company Information";
        FormatAddr: Codeunit "Format Address";
        CompanyAddr: array[8] of Text[100];
        ImportedReferencePaymentsCaptionLbl: Label 'Imported Reference payments';
        AikaCaptionLbl: Label 'Aika';
        PvmCaptionLbl: Label 'Pvm';
}

