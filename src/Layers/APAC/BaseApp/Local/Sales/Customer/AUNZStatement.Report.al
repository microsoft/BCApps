// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 17110 "AU/NZ Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Customer/AUNZStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'AU/NZ Statement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Print Statements", "Date Filter";
            column(Customer_No_; "No.")
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            dataitem(HeaderFooter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CustomerAddress_1_; CustomerAddress[1])
                {
                }
                column(CustomerAddress_2_; CustomerAddress[2])
                {
                }
                column(CustomerAddress_3_; CustomerAddress[3])
                {
                }
                column(CustomerAddress_4_; CustomerAddress[4])
                {
                }
                column(CustomerAddress_5_; CustomerAddress[5])
                {
                }
                column(CustomerAddress_6_; CustomerAddress[6])
                {
                }
                column(CustomerAddress_7_; CustomerAddress[7])
                {
                }
                column(CustomerAddress_8_; CustomerAddress[8])
                {
                }
                column(FORMAT_ToDate_; Format(ToDate))
                {
                }
                column(Customer__No__; Customer."No.")
                {
                }
                column(CurrencyLabel; CurrencyLabel)
                {
                }
                column(CompanyAddress_4_; CompanyAddress[4])
                {
                }
                column(CompanyAddress_3_; CompanyAddress[3])
                {
                }
                column(CompanyAddress_2_; CompanyAddress[2])
                {
                }
                column(CompanyAddress_1_; CompanyAddress[1])
                {
                }
                column(CompanyAddress_5_; CompanyAddress[5])
                {
                }
                column(PhoneNo; PhoneNo)
                {
                }
                column(FaxNo; FaxNo)
                {
                }
                column(VATRegNo; VATRegNo)
                {
                }
                column(GiroNo; GiroNo)
                {
                }
                column(Bank; Bank)
                {
                }
                column(AccountNo; AccountNo)
                {
                }
                column(CompanyInformation__Bank_Account_No__; CompanyInformation."Bank Account No.")
                {
                }
                column(CompanyInformation__Bank_Name_; CompanyInformation."Bank Name")
                {
                }
                column(CompanyInformation__Giro_No__; CompanyInformation."Giro No.")
                {
                }
                column(CompanyInformation__VAT_Registration_No__; CompanyInformation."VAT Registration No.")
                {
                }
                column(CompanyInformation__Fax_No__; CompanyInformation."Fax No.")
                {
                }
                column(CompanyInformation__Phone_No__; CompanyInformation."Phone No.")
                {
                }
                column(PrintLCY; PrintLCY)
                {
                }
                column(StatementStyle; StatementStyle)
                {
                }
                column(AgingMethod; AgingMethod)
                {
                }
                column(DebitBalance; DebitBalance)
                {
                }
                column(CreditBalance; -CreditBalance)
                {
                }
                column(StatementBalance; StatementBalance)
                {
                }
                column(HeaderFooter_Number; Number)
                {
                }
                column(STATEMENTCaption; STATEMENTCaptionLbl)
                {
                }
                column(Statement_Date_Caption; Statement_Date_CaptionLbl)
                {
                }
                column(Account_Number_Caption; Account_Number_CaptionLbl)
                {
                }
                column(Currency_Caption; Currency_CaptionLbl)
                {
                }
                column(Page_Caption; Page_CaptionLbl)
                {
                }
                column(BalanceCaption; BalanceCaptionLbl)
                {
                }
                column(CreditsCaption; CreditsCaptionLbl)
                {
                }
                column(DebitsCaption; DebitsCaptionLbl)
                {
                }
                column(Due_DateCaption; Due_DateCaptionLbl)
                {
                }
                column(No_Caption; No_CaptionLbl)
                {
                }
                column(DocumentCaption; DocumentCaptionLbl)
                {
                }
                column(DateCaption; DateCaptionLbl)
                {
                }
                column(Statement_BalanceCaption; Statement_BalanceCaptionLbl)
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    CalcFields = "Remaining Amt. (LCY)", "Remaining Amount";
                    DataItemLink = "Customer No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", Open) where("Remaining Amount" = filter(<> 0));

                    trigger OnPreDataItem()
                    begin
                        if (AgingMethod = AgingMethod::None) and (StatementStyle = StatementStyle::Balance) then
                            CurrReport.Break();    // Optimization
                        // Find ledger entries which are open and posted before the statement date.
                        LedgEntryLast := 0;
                        if StatementStyle = StatementStyle::"Open Item" then
                            SetRange("Date Filter", 0D, ToDate);
                        SetRange("Posting Date", 0D, ToDate);
                    end;
                }
                dataitem("Balance Forward"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(BalanceToPrintLCY; BalanceToPrintLCY)
                    {
                    }
                    column(FORMAT_FromDate___1_; Format(FromDate - 1))
                    {
                    }
                    column(Balance_Forward_Number; Number)
                    {
                    }
                    column(Balance_ForwardCaption; Balance_ForwardCaptionLbl)
                    {
                    }
                    column(Bal_FwdCaption; Bal_FwdCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if StatementStyle <> StatementStyle::Balance then
                            CurrReport.Break();
                    end;
                }
                dataitem(CustLedgerEntry3; "Cust. Ledger Entry")
                {
                    CalcFields = Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)";
                    DataItemLink = "Customer No." = field("No.");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date") where("Remaining Amount" = filter(<> 0));
                    column(BalanceToPrint; BalanceToPrint)
                    {
                    }
                    column(FORMAT__Due_Date__; Format("Due Date"))
                    {
                    }
                    column(CustLedgerEntry3__Document_No__; "Document No.")
                    {
                    }
                    column(CustLedgerEntry3__Document_Type_; "Document Type")
                    {
                    }
                    column(FORMAT__Posting_Date__; Format("Posting Date"))
                    {
                    }
                    column(OpenDrBal; OpenDrBal)
                    {
                    }
                    column(OpenCrBal; Abs(OpenCrBal))
                    {
                    }
                    column(BalanceToPrintLCY_Control1500085; BalanceToPrintLCY)
                    {
                    }
                    column(CustLedgerEntry3__Due_Date__Control1500088; Format("Due Date"))
                    {
                    }
                    column(CustLedgerEntry3__Document_No___Control1500089; "Document No.")
                    {
                    }
                    column(CustLedgerEntry3__Document_Type__Control1500090; "Document Type")
                    {
                    }
                    column(CustLedgerEntry3__Currency_Code_; "Currency Code")
                    {
                    }
                    column(FORMAT__Posting_Date___Control1500091; Format("Posting Date"))
                    {
                    }
                    column(OpenDrBalLCY; OpenDrBalLCY)
                    {
                    }
                    column(OpenCrBalLCY; OpenCrBalLCY)
                    {
                    }
                    column(CustLedgerEntry3_Entry_No_; "Entry No.")
                    {
                    }
                    column(CustLedgerEntry3_Customer_No_; "Customer No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        OpenCrBal := 0;
                        OpenDrBal := 0;
                        OpenCrBalLCY := 0;
                        OpenDrBalLCY := 0;
                        if PrintLCY then begin
                            BalanceToPrintLCY := BalanceToPrintLCY + "Remaining Amt. (LCY)";
                            if "Remaining Amt. (LCY)" >= 0 then begin
                                DebitBalance := DebitBalance + "Remaining Amt. (LCY)";
                                OpenDrBalLCY := "Remaining Amt. (LCY)";
                            end
                            else begin
                                CreditBalance := CreditBalance + "Remaining Amt. (LCY)";
                                OpenCrBalLCY := "Remaining Amt. (LCY)";
                            end
                        end else begin
                            BalanceToPrint := BalanceToPrint + "Remaining Amt. (LCY)";
                            if "Remaining Amount" >= 0 then begin
                                DebitBalance := DebitBalance + "Remaining Amt. (LCY)";
                                OpenDrBal := "Remaining Amount";
                            end else begin
                                CreditBalance := CreditBalance + "Remaining Amt. (LCY)";
                                OpenCrBal := "Remaining Amount";
                            end
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if StatementStyle = StatementStyle::Balance then
                            CurrReport.Break();
                        SetRange("Posting Date", 0D, ToDate);
                        SetRange("Date Filter", 0D, ToDate);
                    end;
                }
                dataitem("AgingCust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    CalcFields = "Remaining Amount", "Remaining Amt. (LCY)";
                    DataItemLink = "Customer No." = field("No.");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date") where("Remaining Amount" = filter(<> 0));

                    trigger OnAfterGetRecord()
                    begin
                        case AgingMethod of
                            AgingMethod::"Due Date":
                                begin
                                    if ("Due Date" >= Periodstartdate[1]) and ("Due Date" <= PeriodEndingDate[1]) then begin
                                        TempCustLedgerEntry1.Init();
                                        TempCustLedgerEntry1 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry1.Insert();
                                    end;
                                    if ("Due Date" >= Periodstartdate[2]) and ("Due Date" <= PeriodEndingDate[2]) then begin
                                        TempCustLedgerEntry2.Init();
                                        TempCustLedgerEntry2 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry2.Insert();
                                    end;
                                    if ("Due Date" >= Periodstartdate[3]) and ("Due Date" <= PeriodEndingDate[3]) then begin
                                        TempCustLedgerEntry3.Init();
                                        TempCustLedgerEntry3 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry3.Insert();
                                    end;
                                    if ("Due Date" >= Periodstartdate[4]) and ("Due Date" <= PeriodEndingDate[4]) then begin
                                        TempCustLedgerEntry4.Init();
                                        TempCustLedgerEntry4 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry4.Insert();
                                    end;
                                end;
                            AgingMethod::"Trans Date", AgingMethod::None:
                                begin
                                    if ("Posting Date" >= Periodstartdate[1]) and ("Posting Date" <= PeriodEndingDate[1]) then begin
                                        TempCustLedgerEntry1.Init();
                                        TempCustLedgerEntry1 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry1.Insert();
                                    end;
                                    if ("Posting Date" >= Periodstartdate[2]) and ("Posting Date" <= PeriodEndingDate[2]) then begin
                                        TempCustLedgerEntry2.Init();
                                        TempCustLedgerEntry2 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry2.Insert();
                                    end;
                                    if ("Posting Date" >= Periodstartdate[3]) and ("Posting Date" <= PeriodEndingDate[3]) then begin
                                        TempCustLedgerEntry3.Init();
                                        TempCustLedgerEntry3 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry3.Insert();
                                    end;
                                    if ("Posting Date" >= Periodstartdate[4]) and ("Posting Date" <= PeriodEndingDate[4]) then begin
                                        TempCustLedgerEntry4.Init();
                                        TempCustLedgerEntry4 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry4.Insert();
                                    end;
                                end;
                            AgingMethod::"Doc Date":
                                begin
                                    if ("Document Date" >= Periodstartdate[1]) and ("Document Date" <= PeriodEndingDate[1]) then begin
                                        TempCustLedgerEntry1.Init();
                                        TempCustLedgerEntry1 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry1.Insert();
                                    end;
                                    if ("Document Date" >= Periodstartdate[2]) and ("Document Date" <= PeriodEndingDate[2]) then begin
                                        TempCustLedgerEntry2.Init();
                                        TempCustLedgerEntry2 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry2.Insert();
                                    end;
                                    if ("Document Date" >= Periodstartdate[3]) and ("Document Date" <= PeriodEndingDate[3]) then begin
                                        TempCustLedgerEntry3.Init();
                                        TempCustLedgerEntry3 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry3.Insert();
                                    end;
                                    if ("Document Date" >= Periodstartdate[4]) and ("Document Date" <= PeriodEndingDate[4]) then begin
                                        TempCustLedgerEntry4.Init();
                                        TempCustLedgerEntry4 := "AgingCust. Ledger Entry";
                                        TempCustLedgerEntry4.Insert();
                                    end;
                                end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Posting Date", 0D, ToDate);
                        SetRange("Date Filter", 0D, ToDate);
                    end;
                }
                dataitem(CustLedgerEntry4; "Cust. Ledger Entry")
                {
                    CalcFields = Amount, "Amount (LCY)";
                    DataItemLink = "Customer No." = field("No.");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date");
                    column(BalanceToPrint_Control1500052; BalanceToPrint)
                    {
                    }
                    column(Cust__Ledg__Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(Cust__Ledg__Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(FORMAT_DueDate_; Format("Due Date"))
                    {
                    }
                    column(Cust__Ledg__Entry__Document_No__; "Document No.")
                    {
                    }
                    column(Cust__Ledg__Entry__Document_Type_; "Document Type")
                    {
                    }
                    column(FORMAT__Posting_Date___Control1500058; Format("Posting Date"))
                    {
                    }
                    column(BalanceToPrintLCY_Control1500059; BalanceToPrintLCY)
                    {
                    }
                    column(Cust__Ledg__Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledg__Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                    {
                    }
                    column(FORMAT_DueDate__Control1500062; Format("Due Date"))
                    {
                    }
                    column(Cust__Ledg__Entry__Document_No___Control1500063; "Document No.")
                    {
                    }
                    column(Cust__Ledg__Entry__Document_Type__Control1500064; "Document Type")
                    {
                    }
                    column(FORMAT__Posting_Date___Control1500065; Format("Posting Date"))
                    {
                    }
                    column(StatementComplete; StatementComplete)
                    {
                    }
                    column(Cust__Ledg__Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Cust__Ledg__Entry_Customer_No_; "Customer No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if PrintLCY then begin
                            BalanceToPrintLCY := BalanceToPrintLCY + "Amount (LCY)";
                            if "Amount (LCY)" >= 0 then
                                DebitBalance := DebitBalance + "Amount (LCY)"
                            else
                                CreditBalance := CreditBalance + "Amount (LCY)";
                        end else begin
                            BalanceToPrint := BalanceToPrint + Amount;
                            if Amount >= 0 then
                                DebitBalance := DebitBalance + Amount
                            else
                                CreditBalance := CreditBalance + Amount;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if StatementStyle <> StatementStyle::Balance then
                            CurrReport.Break();
                        SetRange("Posting Date", FromDate, ToDate);
                    end;
                }
                dataitem(EndOfCustomer; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(Just_For_Adding_One_Record_to_Dataset_; 'Just For Adding One Record to Dataset')
                    {
                    }
                    column(EndOfCustomer_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        StatementComplete := true;
                        if UpdateNumbers and (not CurrReport.Preview) then begin
                            Customer.Modify(); // just update the Last Statement No
                            Commit();
                        end;

                        CalcOpenLedgEntry();
                        if AgingMethod = AgingMethod::"Due Date" then
                            AgingDaysText := Text1500009
                        else
                            AgingDaysText := Text1500010;

                        if PrintLCY then
                            StatementBalance := BalanceToPrintLCY
                        else
                            StatementBalance := BalanceToPrint;
                    end;
                }
            }
            dataitem(PrintFooter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Testdec_Control1000000001; AgingAmount[4])
                {
                }
                column(AgingAmount_3__Control1000000000; AgingAmount[3])
                {
                }
                column(AgingAmount_2__Control1000000002; AgingAmount[2])
                {
                }
                column(AgingAmount_1__Control1000000003; AgingAmount[1])
                {
                }
                column(StatementBalance_Control1000000004; StatementBalance)
                {
                }
                column(CreditBalance_Control1000000005; -CreditBalance)
                {
                }
                column(DebitBalance_Control1000000006; DebitBalance)
                {
                }
                column(AgingDaysText_Control1000000010; AgingDaysText)
                {
                }
                column(AgingHead_4__Control1000000008; AgingHead[4])
                {
                }
                column(AgingHead_3__Control1000000011; AgingHead[3])
                {
                }
                column(AgingHead_2__Control1000000013; AgingHead[2])
                {
                }
                column(AgingHead_1__Control1000000014; AgingHead[1])
                {
                }
                column(test2_test2_Number; Number)
                {
                }
                column(StatementComplete_Control1000000016; StatementComplete)
                {
                }
                column(AgingMethod_Control1000000017; AgingMethod)
                {
                }
                column(Statement_BalanceCaption_Control1000000007; Statement_BalanceCaption_Control1000000007Lbl)
                {
                }
                column(Statement_Aging_Caption_Control1000000009; Statement_Aging_Caption_Control1000000009Lbl)
                {
                }
                column(Aged_Amounts_Caption_Control1000000012; Aged_Amounts_Caption_Control1000000012Lbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                DebitBalance := 0;
                CreditBalance := 0;
                Clear(AmountDue);
                Print := false;
                if AllHavingBalance then begin
                    SetRange("Date Filter", 0D, ToDate);
                    CalcFields("Net Change");
                    Print := "Net Change" <> 0;
                end;
                if (not Print) and AllHavingEntries then begin
                    "Cust. Ledger Entry".Reset();
                    if StatementStyle = StatementStyle::Balance then begin
                        "Cust. Ledger Entry".SetCurrentKey("Customer No.", "Posting Date");
                        "Cust. Ledger Entry".SetRange("Posting Date", FromDate, ToDate);
                    end else begin
                        "Cust. Ledger Entry".SetCurrentKey("Customer No.", "Posting Date");
                        "Cust. Ledger Entry".SetRange("Posting Date", FromDate, ToDate);
                        "Cust. Ledger Entry".SetRange(Open, true);
                    end;
                    "Cust. Ledger Entry".SetRange("Customer No.", "No.");
                    Print := "Cust. Ledger Entry".Find('-');
                end;

                if not Print then
                    CurrReport.Skip();
                if StatementStyle = StatementStyle::Balance then begin
                    SetRange("Date Filter", 0D, FromDate - 1);
                    CalcFields("Net Change", "Net Change (LCY)");
                    BalanceToPrint := "Net Change";
                    SetRange("Date Filter");
                    if PrintLCY then
                        BalanceToPrintLCY := "Net Change (LCY)"
                    else
                        BalanceToPrintLCY := "Net Change";
                end else begin
                    BalanceToPrint := 0;
                    BalanceToPrintLCY := 0;
                end;

                /* Update Statement Number so it can be printed on the document. However,
                  defer actually updating the customer file until the statement is complete. */
                if "Last Statement No." >= 9999 then
                    "Last Statement No." := 1
                else
                    "Last Statement No." := "Last Statement No." + 1;

                FormatAddress.Customer(CustomerAddress, Customer);
                LedgEntryLast := 0;
                StatementComplete := false;

            end;

            trigger OnPreDataItem()
            begin
                // IF STRPOS(OSVERSION,'NT') = 0 THEN
                // OSSystem := OSSystem::Windows
                // else
                // OSSystem := OSSystem::NT;

                /* remove user-entered date filter; info now in FromDate & ToDate */
                SetRange("Date Filter");
                CalcAging();

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
                    field(PrintAllWithEntries; AllHavingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print All with Entries';
                        ToolTip = 'Specifies that you want to include all accounts with entries.';
                    }
                    field(PrintAllWithBalance; AllHavingBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print All with Balance';
                        ToolTip = 'Specifies that you want to include all accounts with a balance.';
                    }
                    field(UpdateStatementNo; UpdateNumbers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Statement No.';
                        ToolTip = 'Specifies that this is an update of an existing statement.';
                    }
                    field(PrintCompanyAddress; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies that you want to include the company address.';
                    }
                    field(PrintInLCY; PrintLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print in LCY';
                        ToolTip = 'Specifies that you want to print amounts in your currency.';
                    }
                    field(StatementStyle; StatementStyle)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Style';
                        OptionCaption = 'Open Item,Balance';
                        ToolTip = 'Specifies the style of the statement as based on open items or the balance.';
                    }
                    field(AgedBy; AgingMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged By';
                        OptionCaption = 'None,Due Date,Trans Date,Doc Date';
                        ToolTip = 'Specifies what you want to use as the aging method. Use Due Date to age by the number of days that the transaction is overdue. Use Trans Date to age documents by the number of days since the transaction posting date. use Document Date to age documents by the number of days since the document date.';
                    }
                    field(LengthOfAgingPeriods; PeriodCalculation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Aging Periods';
                        ToolTip = 'Specifies how long the aging periods must be.';

                        trigger OnValidate()
                        begin
                            if (AgingMethod <> AgingMethod::None) and (PeriodCalculation = '') then
                                Error('You must enter a Length of Aging Periods if you select aging.');
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (not AllHavingEntries) and (not AllHavingBalance) then
                AllHavingBalance := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if PrintLCY then begin
            CurrencyLabel := 'Local (LCY)';
            BalanceCaptionLbl := 'Balance'
        end else begin
            CurrencyLabel := 'Customer';
            BalanceCaptionLbl := 'Balance (LCY)';
        end;

        if (not AllHavingEntries) and (not AllHavingBalance) then
            Error(Text1500001);
        if UpdateNumbers and CurrReport.Preview then
            Error(Text1500002);
        FromDate := Customer.GetRangeMin("Date Filter");
        ToDate := Customer.GetRangeMax("Date Filter");

        if (StatementStyle = StatementStyle::Balance) and (FromDate = ToDate) then
            Error(Text1500003);

        if (AgingMethod <> AgingMethod::None) and (PeriodCalculation = '') then
            Error(Text1500004);

        if PrintCompany then begin
            CompanyInformation.Get('');
            FormatAddress.Company(CompanyAddress, CompanyInformation);
            PhoneNo := 'Phone No.';
            FaxNo := 'Fax No.';
            VATRegNo := 'VAT Reg. No.';
            GiroNo := 'GIRO No.';
            Bank := 'Bank';
            AccountNo := 'Account No.';
        end else
            Clear(CompanyAddress);
    end;

    var
        OpenDrBal: Decimal;
        OpenDrBalLCY: Decimal;
        OpenCrBal: Decimal;
        OpenCrBalLCY: Decimal;
        Periodstartdate: array[5] of Date;
        StatementBalance: Decimal;
        PeriodLength2: DateFormula;
        FaxNo: Text[50];
        VATRegNo: Text[50];
        GiroNo: Text[50];
        Bank: Text[50];
        AccountNo: Text[50];
        CompanyInformation: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        StatementStyle: Option "Open Item",Balance;
        AllHavingEntries: Boolean;
        AllHavingBalance: Boolean;
        UpdateNumbers: Boolean;
        PhoneNo: Text[50];
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
        PrintCompany: Boolean;
        PeriodCalculation: Code[10];
        Print: Boolean;
        FromDate: Date;
        ToDate: Date;
        CustomerAddress: array[8] of Text[100];
        CompanyAddress: array[8] of Text[100];
        BalanceToPrint: Decimal;
        BalanceToPrintLCY: Decimal;
        DebitBalance: Decimal;
        CreditBalance: Decimal;
        AgingHead: array[4] of Text[14];
        CurrencyLabel: Text[30];
        AmountDue: array[4] of Decimal;
        AgingDaysText: Text[16];
        PeriodEndingDate: array[5] of Date;
        StatementComplete: Boolean;
        PrintLCY: Boolean;
        i: Integer;
        LedgEntryLast: Integer;
        Text1500001: Label 'You must select either All with Entries or All with Balance.';
        Text1500002: Label 'You must print statements if you want to update statement numbers.';
        Text1500003: Label 'You must enter a range of dates (not just one date) in the Date Filter if you want to print Balance Forward Statements.';
        Text1500004: Label 'You must enter a Length of Aging Periods if you select aging.';
        Text1500005: Label 'days';
        Text1500006: Label 'Over';
        Text1500007: Label 'Upto';
        Text1500008: Label 'The Date Formula %1 cannot be used. Try to restate it. E.g. 1M+CM instead of CM+1M.';
        TempCustLedgerEntry1: Record "Cust. Ledger Entry" temporary;
        TempCustLedgerEntry2: Record "Cust. Ledger Entry" temporary;
        TempCustLedgerEntry3: Record "Cust. Ledger Entry" temporary;
        TempCustLedgerEntry4: Record "Cust. Ledger Entry" temporary;
        AgingAmount: array[4] of Decimal;
        Text1500009: Label 'Days overdue:';
        Text1500010: Label 'Days old:';
        STATEMENTCaptionLbl: Label 'STATEMENT';
        Statement_Date_CaptionLbl: Label 'Statement Date:';
        Account_Number_CaptionLbl: Label 'Account Number:';
        Currency_CaptionLbl: Label 'Currency:';
        Page_CaptionLbl: Label 'Page:';
        BalanceCaptionLbl: Text;
        CreditsCaptionLbl: Label 'Credits';
        DebitsCaptionLbl: Label 'Debits';
        Due_DateCaptionLbl: Label 'Due Date';
        No_CaptionLbl: Label 'No.';
        DocumentCaptionLbl: Label 'Document';
        DateCaptionLbl: Label 'Date';
        Statement_BalanceCaptionLbl: Label 'Statement Balance';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Bal_FwdCaptionLbl: Label 'Bal Fwd';
        Statement_BalanceCaption_Control1000000007Lbl: Label 'Statement Balance';
        Statement_Aging_Caption_Control1000000009Lbl: Label 'Statement Aging:';
        Aged_Amounts_Caption_Control1000000012Lbl: Label 'Aged Amounts:';

    [Scope('OnPrem')]
    procedure GetTermsString(var CustLedgerEntry: Record "Cust. Ledger Entry"): Text[250]
    var
        InvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
    begin
        if (CustLedgerEntry."Document No." = '') or (CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice) then
            exit('');

        if InvoiceHeader.ReadPermission then
            if InvoiceHeader.Get(CustLedgerEntry."Document No.") then
                if PaymentTerms.Get(InvoiceHeader."Payment Terms Code") then begin
                    if PaymentTerms.Description <> '' then
                        exit(PaymentTerms.Description);

                    exit(InvoiceHeader."Payment Terms Code");
                end else
                    exit(InvoiceHeader."Payment Terms Code");

        if Customer."Payment Terms Code" <> '' then
            if PaymentTerms.Get(Customer."Payment Terms Code") then begin
                if PaymentTerms.Description <> '' then
                    exit(PaymentTerms.Description);

                exit(Customer."Payment Terms Code");
            end else
                exit(Customer."Payment Terms Code");

        exit('');
    end;

    [Scope('OnPrem')]
    procedure CalcAging()
    begin
        if AgingMethod = AgingMethod::None then
            exit;
        AgingDaysText := '';
        Evaluate(PeriodLength2, '-' + Format(PeriodCalculation));
        if AgingMethod = AgingMethod::"Due Date" then begin
            PeriodEndingDate[1] := 99991231D;
            Periodstartdate[1] := ToDate + 1;
        end else begin
            PeriodEndingDate[1] := ToDate;
            Periodstartdate[1] := CalcDate(PeriodLength2, ToDate + 1);
        end;
        for i := 2 to 4 do begin
            PeriodEndingDate[i] := Periodstartdate[i - 1] - 1;
            Periodstartdate[i] := CalcDate(PeriodLength2, PeriodEndingDate[i] + 1);
        end;
        Periodstartdate[i] := 0D;
        for i := 1 to 4 do
            if PeriodEndingDate[i] < Periodstartdate[i] then
                Error(Text1500008, PeriodCalculation);
        if AgingMethod = AgingMethod::"Due Date" then begin
            i := 2;
            while i < 4 do begin
                AgingHead[i] := StrSubstNo('%1 - %2 %3', ToDate - PeriodEndingDate[i] + 1, ToDate - Periodstartdate[i] + 1, Text1500005);
                i := i + 1;
            end;
            AgingHead[1] := 'Current';
            AgingHead[2] := StrSubstNo('%1 %2 %3', Text1500007, ToDate - Periodstartdate[2] + 1, Text1500005);
        end else
            i := 1;

        while i < 4 do begin
            AgingHead[1] := 'Current';
            AgingHead[i] := StrSubstNo('%1 - %2 %3', ToDate - PeriodEndingDate[i] + 1, ToDate - Periodstartdate[i] + 1, Text1500005);
            i := i + 1;
        end;
        AgingHead[i] := StrSubstNo('%1 %2 %3', Text1500006, ToDate - Periodstartdate[i - 1] + 1, Text1500005);
    end;

    [Scope('OnPrem')]
    procedure CalcOpenLedgEntry()
    begin
        Clear(AgingAmount);
        if not PrintLCY then begin
            TempCustLedgerEntry1.Reset();
            TempCustLedgerEntry1.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry1.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry1.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry1.Find('-') then
                repeat
                    TempCustLedgerEntry1.CalcFields("Remaining Amount");
                    AgingAmount[1] += TempCustLedgerEntry1."Remaining Amount";
                until TempCustLedgerEntry1.Next() = 0;
        end else begin
            TempCustLedgerEntry1.Reset();
            TempCustLedgerEntry1.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry1.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry1.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry1.Find('-') then
                repeat
                    TempCustLedgerEntry1.CalcFields("Remaining Amt. (LCY)");
                    AgingAmount[1] += TempCustLedgerEntry1."Remaining Amt. (LCY)";
                until TempCustLedgerEntry1.Next() = 0;
        end;
        if not PrintLCY then begin
            TempCustLedgerEntry2.Reset();
            TempCustLedgerEntry2.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry2.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry2.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry2.Find('-') then
                repeat
                    TempCustLedgerEntry2.CalcFields("Remaining Amount");
                    AgingAmount[2] += TempCustLedgerEntry2."Remaining Amount";
                until TempCustLedgerEntry2.Next() = 0;
        end else begin
            TempCustLedgerEntry2.Reset();
            TempCustLedgerEntry2.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry2.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry2.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry2.Find('-') then
                repeat
                    TempCustLedgerEntry2.CalcFields("Remaining Amt. (LCY)");
                    AgingAmount[2] += TempCustLedgerEntry2."Remaining Amt. (LCY)";
                until TempCustLedgerEntry2.Next() = 0;
        end;
        if not PrintLCY then begin
            TempCustLedgerEntry3.Reset();
            TempCustLedgerEntry3.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry3.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry3.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry3.Find('-') then
                repeat
                    TempCustLedgerEntry3.CalcFields("Remaining Amount");
                    AgingAmount[3] += TempCustLedgerEntry3."Remaining Amount";
                until TempCustLedgerEntry3.Next() = 0;
        end else begin
            TempCustLedgerEntry3.Reset();
            TempCustLedgerEntry3.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry3.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry3.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry3.Find('-') then
                repeat
                    TempCustLedgerEntry3.CalcFields("Remaining Amount");
                    AgingAmount[3] += TempCustLedgerEntry3."Remaining Amount";
                until TempCustLedgerEntry3.Next() = 0;
        end;
        if not PrintLCY then begin
            TempCustLedgerEntry4.Reset();
            TempCustLedgerEntry4.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry4.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry4.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry4.Find('-') then
                repeat
                    TempCustLedgerEntry4.CalcFields("Remaining Amount");
                    AgingAmount[4] += TempCustLedgerEntry4."Remaining Amount";
                until TempCustLedgerEntry4.Next() = 0;
        end else begin
            TempCustLedgerEntry4.Reset();
            TempCustLedgerEntry4.SetRange("Customer No.", "AgingCust. Ledger Entry"."Customer No.");
            TempCustLedgerEntry4.SetRange("Date Filter", 0D, ToDate);
            TempCustLedgerEntry4.SetRange("Posting Date", 0D, ToDate);
            if TempCustLedgerEntry4.Find('-') then
                repeat
                    TempCustLedgerEntry4.CalcFields("Remaining Amount");
                    AgingAmount[4] += TempCustLedgerEntry4."Remaining Amount";
                until TempCustLedgerEntry4.Next() = 0;
        end;
    end;
}

