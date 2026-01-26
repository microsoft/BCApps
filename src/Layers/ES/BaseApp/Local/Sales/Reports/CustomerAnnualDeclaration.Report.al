// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 10702 "Customer - Annual Declaration"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerAnnualDeclaration.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Annual Declaration';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            CalcFields = "Inv. Amounts (LCY)", "Cr. Memo Amounts (LCY)";
            RequestFilterFields = "No.", "Customer Posting Group", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Customer_TABLECAPTION__________CustFilter; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(Text1100000___FORMAT_MinAmount_; Text1100000 + Format(MinAmount))
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(Customer__No__; "No.")
            {
            }
            column(CustAddr_1_; CustAddr[1])
            {
            }
            column(CustAddr_2_; CustAddr[2])
            {
            }
            column(CustAddr_3_; CustAddr[3])
            {
            }
            column(CustAddr_4_; CustAddr[4])
            {
            }
            column(CustAddr_5_; CustAddr[5])
            {
            }
            column(CustAddr_6_; CustAddr[6])
            {
            }
            column(CustAddr_7_; CustAddr[7])
            {
            }
            column(Customer__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(SalesAmt; SalesAmt)
            {
                DecimalPlaces = 0 : 2;
            }
            column(CustAddr_8_; CustAddr[8])
            {
            }
            column(AcumSalesAmount; AcumSalesAmount)
            {
                DecimalPlaces = 0 : 2;
            }
            column(Customers___Annual_DeclarationCaption; Customers___Annual_DeclarationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Customer__No__Caption; FieldCaption("No."))
            {
            }
            column(Customer__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
            {
            }
            column(Name_and_AddressCaption; Name_and_AddressCaptionLbl)
            {
            }
            column(SalesAmtCaption; SalesAmtCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                IgnoreAmt: Decimal;
                InvoiceAmt: Decimal;
                CrMemoAmt: Decimal;
            begin
                IgnoreAmt := 0;
                SalesAmt := 0;
                InvoiceAmt := 0;
                CrMemoAmt := 0;

                CustEntries.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");

                CustEntries.SetRange("Document Type", CustEntries."Document Type"::Invoice, CustEntries."Document Type"::"Credit Memo");
                CustEntries.SetRange("Customer No.", "No.");
                CustEntries.SetRange("Posting Date", GetRangeMin("Date Filter"), GetRangeMax("Date Filter"));
                if CustEntries.Find('-') then
                    repeat
                        case CustEntries."Document Type" of
                            CustEntries."Document Type"::Invoice:
                                InvoiceAmt := InvoiceAmt + CalcTotalSalesAmt(CustEntries."Entry No.");
                            CustEntries."Document Type"::"Credit Memo":
                                CrMemoAmt := CrMemoAmt - CalcTotalSalesAmt(CustEntries."Entry No.");
                        end;
                        GLEntries.SetCurrentKey("Document No.", "Posting Date");
                        GLEntries.SetRange("Document No.", CustEntries."Document No.");
                        GLEntries.SetRange("Posting Date", CustEntries."Posting Date");
                        GLEntries.SetRange("Gen. Posting Type", GLEntries."Gen. Posting Type"::Sale);
                        if GLEntries.Find('-') then
                            repeat
                                Account.Get(GLEntries."G/L Account No.");
                                if Account."Ignore in 347 Report" then
                                    IgnoreAmt := IgnoreAmt + GLEntries.Amount + GLEntries."VAT Amount";
                            until GLEntries.Next() = 0;
                    until CustEntries.Next() = 0;
                SalesAmt := InvoiceAmt - CrMemoAmt;
                if SalesAmt <= MinAmount then
                    CurrReport.Skip();

                SalesAmt := SalesAmt + IgnoreAmt;

                AcumSalesAmount := AcumSalesAmount + SalesAmt;

                FormatAddress.FormatAddr(
                  CustAddr, Name, "Name 2", '', Address, "Address 2",
                  City, "Post Code", County, "Country/Region Code");

                if (GroupNo = 0) and (Counter = 0) then
                    Counter := Counter + 1;
                if Counter = BlocksPerPage then begin
                    GroupNo := GroupNo + 1;
                    Counter := 0;
                end;
                Counter := Counter + 1;
            end;

            trigger OnPreDataItem()
            begin
                BlocksPerPage := 6;
                Counter := 0;
                GroupNo := 0;
            end;
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
                    field(MinAmount; MinAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amounts greater than';
                        ToolTip = 'Specifies the invoice amount that the customer must exceed to appear in the report.';
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
        CustFilter := Customer.GetFilters();
    end;

    var
        Text1100000: Label 'Amounts greater than ';
        CustEntries: Record "Cust. Ledger Entry";
        GLEntries: Record "G/L Entry";
        FormatAddress: Codeunit "Format Address";
        CustFilter: Text[250];
        CustAddr: array[8] of Text[100];
        SalesAmt: Decimal;
        MinAmount: Decimal;
        Account: Record "G/L Account";
        AcumSalesAmount: Decimal;
        GroupNo: Integer;
        Counter: Integer;
        BlocksPerPage: Integer;
        Customers___Annual_DeclarationCaptionLbl: Label 'Customers - Annual Declaration';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Name_and_AddressCaptionLbl: Label 'Name and Address';
        SalesAmtCaptionLbl: Label 'Amount (LCY)';

    [Scope('OnPrem')]
    procedure CalcTotalSalesAmt(EntryNo: Integer) TotalSalesAmt: Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Reset();
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
        DtldCustLedgEntry.CalcSums("Amount (LCY)");
        exit(DtldCustLedgEntry."Amount (LCY)");
    end;
}

