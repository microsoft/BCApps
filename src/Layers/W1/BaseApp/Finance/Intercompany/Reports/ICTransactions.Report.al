// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 512 "IC Transactions"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/Intercompany/Reports/ICTransactions.rdlc';
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Transactions';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(HeaderInt; "Integer")
        {
            DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO___1___2__ICPartner1_TABLECAPTION_ICPartnerFilter_; StrSubstNo('%1: %2', ICPartner1.TableCaption(), ICPartnerFilter))
            {
            }
            column(ICPartnerFilter; ICPartnerFilter)
            {
            }
            column(STRSUBSTNO___1___2___3__Text004_StartingDate_EndingDate_; StrSubstNo('%1: %2..%3', Text004, StartingDate, EndingDate))
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Intercompany_TransactionsCaption; Intercompany_TransactionsCaptionLbl)
            {
            }
            dataitem(ICPartner1; "IC Partner")
            {
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Code";
                column(STRSUBSTNO___1__2__3__TABLECAPTION_Code_Name_; StrSubstNo('%1 %2 %3', TableCaption(), Code, Name))
                {
                }
                column(ICPartner1_Code; Code)
                {
                }
                column(TempGLEntry__Credit_Amount__Control38Caption; TempGLEntry__Credit_Amount__Control38CaptionLbl)
                {
                }
                column(TempGLEntry__Debit_Amount__Control14Caption; TempGLEntry__Debit_Amount__Control14CaptionLbl)
                {
                }
                column(TempGLEntry__VAT_Amount__Control20Caption; TempGLEntry__VAT_Amount__Control20CaptionLbl)
                {
                }
                column(TempGLEntry_DescriptionCaption; TempGLEntry_DescriptionCaptionLbl)
                {
                }
                column(TempGLEntry__Document_No__Caption; TempGLEntry__Document_No__CaptionLbl)
                {
                }
                column(FORMAT_TempGLEntry__Document_Type__Caption; FORMAT_TempGLEntry__Document_Type__CaptionLbl)
                {
                }
                column(TempGLEntry__Posting_Date_Caption; TempGLEntry__Posting_Date_CaptionLbl)
                {
                }
                column(TempGLEntry__External_Document_No__Caption; TempGLEntry__External_Document_No__CaptionLbl)
                {
                }
                column(BalanceAmountCaption; BalanceAmountCaptionLbl)
                {
                }
                column(General_LedgerCaption; General_LedgerCaptionLbl)
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(STRSUBSTNO___1__2__3__GLAcc_TABLECAPTION_GLAcc__No___GLAcc_Name_; StrSubstNo('%1 %2 %3', GLAcc.TableCaption(), GLAcc."No.", GLAcc.Name))
                    {
                    }
                    dataitem(Integer2; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(TempGLEntry__Credit_Amount_; TempGLEntry."Credit Amount")
                        {
                        }
                        column(TempGLEntry__Debit_Amount_; TempGLEntry."Debit Amount")
                        {
                        }
                        column(TempGLEntry__VAT_Amount_; TempGLEntry."VAT Amount")
                        {
                        }
                        column(TempGLEntry__Debit_Amount__Control14; TempGLEntry."Debit Amount")
                        {
                        }
                        column(TempGLEntry__VAT_Amount__Control20; TempGLEntry."VAT Amount")
                        {
                        }
                        column(TempGLEntry_Description; TempGLEntry.Description)
                        {
                        }
                        column(TempGLEntry__Document_No__; TempGLEntry."Document No.")
                        {
                        }
                        column(FORMAT_TempGLEntry__Document_Type__; Format(TempGLEntry."Document Type"))
                        {
                        }
                        column(TempGLEntry__Posting_Date_; TempGLEntry."Posting Date")
                        {
                        }
                        column(TempGLEntry__Credit_Amount__Control38; TempGLEntry."Credit Amount")
                        {
                        }
                        column(TempGLEntry__External_Document_No__; TempGLEntry."External Document No.")
                        {
                        }
                        column(BalanceAmount; BalanceAmount)
                        {
                        }
                        column(STRSUBSTNO___1__2___3__GLAcc__No___GLAcc_Name_Text001_; StrSubstNo('%1 %2, %3', GLAcc."No.", GLAcc.Name, Text001))
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if TempGLEntry.Find('-') then;
                            end else
                                if TempGLEntry.Next() = 0 then;
                            TempGLEntry.Delete();
                            BalanceAmount += TempGLEntry.Amount;
                        end;

                        trigger OnPreDataItem()
                        begin
                            TempGLEntry.SetCurrentKey("G/L Account No.");
                            TempGLEntry.SetRange("G/L Account No.", TempTotGLEntry."G/L Account No.");
                            SetRange(Number, 1, TempGLEntry.Count);
                            BalanceAmount := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if TempTotGLEntry.Find('-') then;
                        end else
                            if TempTotGLEntry.Next() = 0 then;

                        GLAcc.Get(TempTotGLEntry."G/L Account No.");
                        TempTotGLEntry.Delete();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempTotGLEntry.Count);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    GLEntry: Record "G/L Entry";
                begin
                    GLEntry.SetCurrentKey("IC Partner Code");
                    GLEntry.SetRange("IC Partner Code", Code);
                    GLEntry.SetFilter("Posting Date", '..%1', EndingDate);
                    TempTotGLEntry.SetCurrentKey("G/L Account No.");
                    if GLEntry.Find('-') then
                        repeat
                            TempTotGLEntry.SetRange("G/L Account No.", GLEntry."G/L Account No.");
                            if not TempTotGLEntry.Find('-') then begin
                                TempTotGLEntry.Init();
                                TempTotGLEntry."Entry No." := GLEntry."Entry No.";
                                TempTotGLEntry."G/L Account No." := GLEntry."G/L Account No.";
                                TempTotGLEntry.Amount := 0;
                                TempTotGLEntry.Insert();
                            end;
                            TempTotGLEntry.Amount := TempTotGLEntry.Amount + GLEntry.Amount;
                            TempTotGLEntry."Debit Amount" := TempTotGLEntry."Debit Amount" + GLEntry."Debit Amount";
                            TempTotGLEntry."Credit Amount" := TempTotGLEntry."Credit Amount" + GLEntry."Credit Amount";
                            if (TempTotGLEntry.Amount = 0) and (GLEntry."Posting Date" < StartingDate) then
                                TempTotGLEntry.Delete()
                            else
                                TempTotGLEntry.Modify();

                            if GLEntry."Posting Date" < StartingDate then begin
                                TempGLEntry.SetRange("G/L Account No.", GLEntry."G/L Account No.");
                                if not TempGLEntry.Find('-') then begin
                                    TempGLEntry.Init();
                                    TempGLEntry."Entry No." := GLEntry."Entry No.";
                                    TempGLEntry."G/L Account No." := GLEntry."G/L Account No.";
                                    TempGLEntry."Posting Date" := 0D;
                                    TempGLEntry.Description := Text002Lbl;
                                    TempGLEntry.Insert();
                                end;
                                TempGLEntry.Amount := TempGLEntry.Amount + GLEntry.Amount;
                                TempGLEntry."Debit Amount" := TempGLEntry."Debit Amount" + GLEntry."Debit Amount";
                                TempGLEntry."Credit Amount" := TempGLEntry."Credit Amount" + GLEntry."Credit Amount";
                                if (TempGLEntry."Debit Amount" = 0) and (TempGLEntry."Credit Amount" = 0) then
                                    TempGLEntry.Delete()
                                else
                                    TempGLEntry.Modify();
                                TempGLEntry.SetRange("G/L Account No.");
                            end;
                            if GLEntry."Posting Date" >= StartingDate then begin
                                TempGLEntry := GLEntry;
                                TempGLEntry.Insert();
                            end;
                        until GLEntry.Next() = 0;
                    TempTotGLEntry.SetRange("G/L Account No.");
                end;
            }
            dataitem(ICPartner2; "IC Partner")
            {
                DataItemTableView = sorting(Code) order(ascending);
                PrintOnlyIfDetail = true;
                column(ICPartner2_Code; Code)
                {
                }
                column(Cust__Ledger_Entry_DescriptionCaption; "Cust. Ledger Entry".FieldCaption(Description))
                {
                }
                column(Cust__Ledger_Entry__External_Document_No__Caption; "Cust. Ledger Entry".FieldCaption("External Document No."))
                {
                }
                column(Cust__Ledger_Entry__Document_No__Caption; "Cust. Ledger Entry".FieldCaption("Document No."))
                {
                }
                column(Cust__Ledger_Entry__Document_Type_Caption; "Cust. Ledger Entry".FieldCaption("Document Type"))
                {
                }
                column(Cust__Ledger_Entry__Posting_Date_Caption; "Cust. Ledger Entry".FieldCaption("Posting Date"))
                {
                }
                column(Cust__Ledger_Entry__Amount__LCY___Control55Caption; "Cust. Ledger Entry".FieldCaption("Amount (LCY)"))
                {
                }
                column(Cust__Ledger_Entry__Currency_Code_Caption; "Cust. Ledger Entry".FieldCaption("Currency Code"))
                {
                }
                column(Cust__Ledger_Entry_AmountCaption; "Cust. Ledger Entry".FieldCaption(Amount))
                {
                }
                column(BalanceAmount_Control62Caption; BalanceAmount_Control62CaptionLbl)
                {
                }
                column(Customer_LedgerCaption; Customer_LedgerCaptionLbl)
                {
                }
                dataitem(Customer; Customer)
                {
                    DataItemLink = "No." = field("Customer No.");
                    DataItemTableView = sorting("No.") order(ascending);
                    PrintOnlyIfDetail = true;
                    column(STRSUBSTNO___1__2__3___4__5___TABLECAPTION__No___Name_ICPartner2_TABLECAPTION_ICPartner2_Code_; StrSubstNo('%1 %2 %3 (%4 %5)', TableCaption(), "No.", Name, ICPartner2.TableCaption(), ICPartner2.Code))
                    {
                    }
                    dataitem(CustInt; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                        column(Text002; Text002Lbl)
                        {
                        }
                        column(BalanceAmount_Control65; BalanceAmount)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            DtldCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                            DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                            DtldCustLedgEntry.SetFilter("Posting Date", '<%1', StartingDate);
                            DtldCustLedgEntry.CalcSums("Amount (LCY)");
                            BalanceAmount := DtldCustLedgEntry."Amount (LCY)";
                        end;
                    }
                    dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                    {
                        CalcFields = Amount, "Amount (LCY)";
                        DataItemLink = "Customer No." = field("No.");
                        DataItemTableView = sorting("Customer No.", "Posting Date", "Currency Code") order(ascending);
                        column(Cust__Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                        {
                        }
                        column(Cust__Ledger_Entry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Cust__Ledger_Entry__Document_Type_; "Document Type")
                        {
                        }
                        column(Cust__Ledger_Entry__Document_No__; "Document No.")
                        {
                        }
                        column(Cust__Ledger_Entry_Description; Description)
                        {
                        }
                        column(Cust__Ledger_Entry__External_Document_No__; "External Document No.")
                        {
                        }
                        column(Cust__Ledger_Entry__Amount__LCY___Control55; "Amount (LCY)")
                        {
                        }
                        column(Cust__Ledger_Entry_Amount; Amount)
                        {
                        }
                        column(Cust__Ledger_Entry__Currency_Code_; "Currency Code")
                        {
                        }
                        column(BalanceAmount_Control62; BalanceAmount)
                        {
                        }
                        column(STRSUBSTNO___1__2__3___4__Customer_TABLECAPTION_Customer__No___Customer_Name_Text001_; StrSubstNo('%1 %2 %3, %4', Customer.TableCaption(), Customer."No.", Customer.Name, Text001))
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            BalanceAmount += "Amount (LCY)";
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Posting Date", StartingDate, EndingDate);
                        end;
                    }
                }

                trigger OnPreDataItem()
                begin
                    CopyFilters(ICPartner1);
                end;
            }
            dataitem(ICPartner3; "IC Partner")
            {
                DataItemTableView = sorting(Code) order(ascending);
                PrintOnlyIfDetail = true;
                column(Vendor_Ledger_Entry_DescriptionCaption; "Vendor Ledger Entry".FieldCaption(Description))
                {
                }
                column(Vendor_Ledger_Entry__External_Document_No__Caption; "Vendor Ledger Entry".FieldCaption("External Document No."))
                {
                }
                column(Vendor_Ledger_Entry__Document_No__Caption; "Vendor Ledger Entry".FieldCaption("Document No."))
                {
                }
                column(Vendor_Ledger_Entry__Document_Type_Caption; "Vendor Ledger Entry".FieldCaption("Document Type"))
                {
                }
                column(Vendor_Ledger_Entry__Posting_Date_Caption; "Vendor Ledger Entry".FieldCaption("Posting Date"))
                {
                }
                column(Vendor_Ledger_Entry__Amount__LCY___Control96Caption; "Vendor Ledger Entry".FieldCaption("Amount (LCY)"))
                {
                }
                column(Vendor_Ledger_Entry__Currency_Code_Caption; "Vendor Ledger Entry".FieldCaption("Currency Code"))
                {
                }
                column(Vendor_Ledger_Entry_AmountCaption; "Vendor Ledger Entry".FieldCaption(Amount))
                {
                }
                column(BalanceAmount_Control97Caption; BalanceAmount_Control97CaptionLbl)
                {
                }
                column(Vendor_LedgerCaption; Vendor_LedgerCaptionLbl)
                {
                }
                dataitem(Vendor; Vendor)
                {
                    DataItemLink = "No." = field("Vendor No.");
                    DataItemTableView = sorting("No.") order(ascending);
                    PrintOnlyIfDetail = true;
                    column(STRSUBSTNO___1__2__3___4__5___TABLECAPTION__No___Name_ICPartner3_TABLECAPTION_ICPartner3_Code_; StrSubstNo('%1 %2 %3 (%4 %5)', TableCaption(), "No.", Name, ICPartner3.TableCaption(), ICPartner3.Code))
                    {
                    }
                    column(Vendor_No_; "No.")
                    {
                    }
                    dataitem(VendInt; "Integer")
                    {
                        DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                        column(Text002_Control87; Text002Lbl)
                        {
                        }
                        column(BalanceAmount_Control88; BalanceAmount)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                            DtldVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
                            DtldVendLedgEntry.SetFilter("Posting Date", '<%1', StartingDate);
                            DtldVendLedgEntry.CalcSums("Amount (LCY)");
                            BalanceAmount := DtldVendLedgEntry."Amount (LCY)";
                        end;
                    }
                    dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                    {
                        CalcFields = Amount, "Amount (LCY)";
                        DataItemLink = "Vendor No." = field("No.");
                        DataItemTableView = sorting("Vendor No.", "Posting Date", "Currency Code") order(ascending);
                        column(Vendor_Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                        {
                        }
                        column(Vendor_Ledger_Entry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Vendor_Ledger_Entry__Document_Type_; "Document Type")
                        {
                        }
                        column(Vendor_Ledger_Entry__Document_No__; "Document No.")
                        {
                        }
                        column(Vendor_Ledger_Entry_Description; Description)
                        {
                        }
                        column(Vendor_Ledger_Entry__External_Document_No__; "External Document No.")
                        {
                        }
                        column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
                        {
                        }
                        column(Vendor_Ledger_Entry_Amount; Amount)
                        {
                        }
                        column(Vendor_Ledger_Entry__Amount__LCY___Control96; "Amount (LCY)")
                        {
                        }
                        column(BalanceAmount_Control97; BalanceAmount)
                        {
                        }
                        column(STRSUBSTNO___1__2__3___4__Vendor_TABLECAPTION_Vendor__No___Vendor_Name_Text001_; StrSubstNo('%1 %2 %3, %4', Vendor.TableCaption(), Vendor."No.", Vendor.Name, Text001))
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            BalanceAmount += "Amount (LCY)";
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Posting Date", StartingDate, EndingDate);
                        end;
                    }
                }

                trigger OnPreDataItem()
                begin
                    CopyFilters(ICPartner1);
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About IC Transactions';
        AboutText = 'The **Intercompany Transactions** report lists all posted intercompany sales, purchases, and journal entries between internal entities. Use it for reviewing and reconciling intercompany activity before financial consolidation to ensure transparency and balance across companies.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period covered by the report that shows posted intercompany transactions.';

                        trigger OnValidate()
                        begin
                            if (EndingDate > 0D) and (EndingDate < StartingDate) then
                                EndingDate := StartingDate;
                        end;
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the end of the period covered by the report.';

                        trigger OnValidate()
                        begin
                            if (EndingDate > 0D) and (EndingDate < StartingDate) then
                                Error(Text003);
                        end;
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
        ICPartnerFilter := ICPartner1.GetFilters();
        if EndingDate = 0D then
            EndingDate := DMY2Date(31, 12, 9999);
    end;

    var
        TempGLEntry: Record "G/L Entry" temporary;
        TempTotGLEntry: Record "G/L Entry" temporary;
        GLAcc: Record "G/L Account";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        EndingDate: Date;
        StartingDate: Date;
#pragma warning disable AA0074
        Text001: Label 'Total';
#pragma warning restore AA0074
        BalanceAmount: Decimal;
#pragma warning disable AA0074
        Text003: Label 'Ending date must not be before starting date.';
        Text004: Label 'Period';
#pragma warning restore AA0074
        ICPartnerFilter: Text;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Intercompany_TransactionsCaptionLbl: Label 'Intercompany Transactions';
        TempGLEntry__Credit_Amount__Control38CaptionLbl: Label 'Credit Amount';
        TempGLEntry__Debit_Amount__Control14CaptionLbl: Label 'Debit Amount';
        TempGLEntry__VAT_Amount__Control20CaptionLbl: Label 'VAT Amount';
        TempGLEntry_DescriptionCaptionLbl: Label 'Description';
        TempGLEntry__Document_No__CaptionLbl: Label 'Document No.';
        FORMAT_TempGLEntry__Document_Type__CaptionLbl: Label 'Document Type';
        TempGLEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        TempGLEntry__External_Document_No__CaptionLbl: Label 'External Doc. No.';
        BalanceAmountCaptionLbl: Label 'Balance';
        General_LedgerCaptionLbl: Label 'General Ledger';
        BalanceAmount_Control62CaptionLbl: Label 'Balance (LCY)';
        Customer_LedgerCaptionLbl: Label 'Customer Ledger';
        Text002Lbl: Label 'Beginning balance';
        BalanceAmount_Control97CaptionLbl: Label 'Balance (LCY)';
        Vendor_LedgerCaptionLbl: Label 'Vendor Ledger';
}

