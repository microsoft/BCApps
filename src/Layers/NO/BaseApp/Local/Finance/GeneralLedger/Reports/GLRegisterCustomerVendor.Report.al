// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 10603 "G/L Register Customer/Vendor"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/GLRegisterCustomerVendor.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Register Customer/Vendor';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Header; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(GLRegCustVendCaption; GLRegCustVendCaptionLbl)
            {
            }
            dataitem("G/L Register"; "G/L Register")
            {
                DataItemTableView = sorting("No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.";
                column(GLRegTableNameFilter; "G/L Register".TableName + ': ' + GLRegFilter)
                {
                }
                column(GLRegFilter; GLRegFilter)
                {
                }
                column(No_GLReg; "No.")
                {
                }
                column(Amount_GLEntry; "G/L Entry".Amount)
                {
                }
                column(VATAmount_GLEntry; "G/L Entry"."VAT Amount")
                {
                }
                column(PurchaseVAT; PurchaseVAT)
                {
                }
                column(VendorDebit; VendorDebit)
                {
                }
                column(VendorCredit; VendorCredit)
                {
                }
                column(SalesVAT; SalesVAT)
                {
                }
                column(CustomerDebit; CustomerDebit)
                {
                }
                column(CustomerCredit; CustomerCredit)
                {
                }
                column(VendorTotals_GLReg; VendorDebit - VendorCredit)
                {
                }
                column(CustomerTotals_GLReg; CustomerDebit - CustomerCredit)
                {
                }
                column(PostingDateGLEntry_Caption; PostingDateCaptionLbl)
                {
                }
                column(DocTypeGLEntry_Caption; DocTypeCaptionLbl)
                {
                }
                column(DocNoGLEntry_Caption; "G/L Entry".FieldCaption("Document No."))
                {
                }
                column(GLAccNoGLEntry_Caption; "G/L Entry".FieldCaption("G/L Account No."))
                {
                }
                column(EntryNoGLEntry_Caption; "G/L Entry".FieldCaption("Entry No."))
                {
                }
                column(VATAmtGLEntry_Caption; "G/L Entry".FieldCaption("VAT Amount"))
                {
                }
                column(AmountGLEntry_Caption; "G/L Entry".FieldCaption(Amount))
                {
                }
                column(GLAccNameCaption; GLAccNameCaptionLbl)
                {
                }
                column(GenPostingTypeCaption; GenPostingTypeCaptionLbl)
                {
                }
                column(CustomerOrVendorCaption; CustomerOrVendorCaptionLbl)
                {
                }
                column(CustomerVendorNoCaption; CustomerVendorNoCaptionLbl)
                {
                }
                column(RegisterNoCaption; RegisterNoCaptionLbl)
                {
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
                column(SalesVATCaption; SalesVATCaptionLbl)
                {
                }
                column(PurchaseVATCaption; PurchaseVATCaptionLbl)
                {
                }
                column(VendorsCaption; VendorsCaptionLbl)
                {
                }
                column(DebitLCYCaption; DebitLCYCaptionLbl)
                {
                }
                column(CreditLCYCaption; CreditLCYCaptionLbl)
                {
                }
                column(CustomersCaption; CustomersCaptionLbl)
                {
                }
                column(TotalLCYCaption; TotalLCYCaptionLbl)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemTableView = sorting("Entry No.");
                    column(PostingDate_GLEntry; Format("Posting Date"))
                    {
                    }
                    column(DocType_GLEntry; "Document Type")
                    {
                    }
                    column(DocNo_GLEntry; "Document No.")
                    {
                    }
                    column(GLAccNo_GLEntry; "G/L Account No.")
                    {
                    }
                    column(VATAmt_GLEntry; "VAT Amount")
                    {
                    }
                    column(GLEntryAmount; Amount)
                    {
                    }
                    column(EntryNo_GLEntry; "Entry No.")
                    {
                    }
                    column(GLAccName; GLAcc.Name)
                    {
                    }
                    column(CustomerOrVendor; CustomerOrVendor)
                    {
                    }
                    column(CustomerVendorNo; CustomerVendorNo)
                    {
                    }
                    column(GenPostingType__GLEntry; "Gen. Posting Type")
                    {
                    }
                    column(SalesVAT_GLEntry; SalesVAT)
                    {
                    }
                    column(PurchaseVAT_GLEntry; PurchaseVAT)
                    {
                    }
                    column(CustomerDebit_GLEntry; CustomerDebit)
                    {
                    }
                    column(VendorDebit_GLEntry; VendorDebit)
                    {
                    }
                    column(CustomerCredit_GLentry; CustomerCredit)
                    {
                    }
                    column(VendorCredit_GLEntry; VendorCredit)
                    {
                    }
                    column(VendorTotals_GLEntry; VendorDebit - VendorCredit)
                    {
                    }
                    column(CustomerTotals_GLEntry; CustomerDebit - CustomerCredit)
                    {
                    }
                    column(GLEntryAmtCaption_GLEntry; GLEntryAmtCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not GLAcc.Get("G/L Account No.") then
                            GLAcc.Init();

                        CustomerVendorNo := '';
                        CustomerOrVendor := '';
                        if CustomerEntry.Get("G/L Entry"."Entry No.") then begin
                            CustomerEntry.CalcFields("Amount (LCY)");
                            CustomerOrVendor := Text1080000;
                            CustomerVendorNo := CustomerEntry."Customer No.";
                            if CustomerEntry."Amount (LCY)" > 0 then
                                CustomerDebit := CustomerDebit + CustomerEntry."Amount (LCY)"
                            else
                                CustomerCredit := CustomerCredit - CustomerEntry."Amount (LCY)";
                        end;
                        if VendorEntry.Get("G/L Entry"."Entry No.") then begin
                            VendorEntry.CalcFields("Amount (LCY)");
                            CustomerOrVendor := Text1080001;
                            CustomerVendorNo := VendorEntry."Vendor No.";
                            if VendorEntry."Amount (LCY)" > 0 then
                                VendorDebit := VendorDebit + VendorEntry."Amount (LCY)"
                            else
                                VendorCredit := VendorCredit - VendorEntry."Amount (LCY)";
                        end;

                        case "G/L Entry"."Gen. Posting Type" of
                            "G/L Entry"."Gen. Posting Type"::Sale:
                                SalesVAT := SalesVAT + "G/L Entry"."VAT Amount";
                            "G/L Entry"."Gen. Posting Type"::Purchase:
                                PurchaseVAT := PurchaseVAT + "G/L Entry"."VAT Amount";
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Entry No.", "G/L Register"."From Entry No.", "G/L Register"."To Entry No.");

                        CustomerDebit := 0;
                        CustomerCredit := 0;
                        VendorDebit := 0;
                        VendorCredit := 0;
                        SalesVAT := 0;
                        PurchaseVAT := 0;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    Clear(CustomerDebit);
                    Clear(CustomerCredit);
                    Clear(VendorCredit);
                    Clear(VendorCredit);
                    Clear(SalesVAT);
                    Clear(PurchaseVAT);
                end;
            }
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
        GLRegFilter := "G/L Register".GetFilters();
    end;

    var
        GLAcc: Record "G/L Account";
        CustomerEntry: Record "Cust. Ledger Entry";
        VendorEntry: Record "Vendor Ledger Entry";
        GLRegFilter: Text[250];
        CustomerOrVendor: Text[30];
        CustomerVendorNo: Code[20];
        CustomerDebit: Decimal;
        CustomerCredit: Decimal;
        VendorDebit: Decimal;
        VendorCredit: Decimal;
        SalesVAT: Decimal;
        PurchaseVAT: Decimal;
        Text1080000: Label 'Customer';
        Text1080001: Label 'Vendor';
        PageCaptionLbl: Label 'Page';
        GLRegCustVendCaptionLbl: Label 'G/L Register Customer/Vendor';
        PostingDateCaptionLbl: Label 'Post date';
        DocTypeCaptionLbl: Label 'Document Type';
        GLAccNameCaptionLbl: Label 'Name';
        GenPostingTypeCaptionLbl: Label 'Gen. Posting Type';
        CustomerOrVendorCaptionLbl: Label 'Type';
        CustomerVendorNoCaptionLbl: Label 'No.';
        RegisterNoCaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
        SalesVATCaptionLbl: Label 'Sales VAT';
        PurchaseVATCaptionLbl: Label 'Purchase VAT';
        VendorsCaptionLbl: Label 'Vendors';
        DebitLCYCaptionLbl: Label 'Debit (LCY)';
        CreditLCYCaptionLbl: Label 'Credit (LCY)';
        CustomersCaptionLbl: Label 'Customers';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        GLEntryAmtCaptionLbl: Label 'Register Total';
}

