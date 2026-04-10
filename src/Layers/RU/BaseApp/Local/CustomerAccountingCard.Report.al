#pragma warning disable AA0247
report 12441 "Customer Accounting Card"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/CustomerAccountingCard.rdlc';
    Caption = 'Customer Accounting Card';

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Customer Posting Group", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Agreement Filter", "Date Filter";
            column(RequestFilter; RequestFilter)
            {
            }
            column(HeaderPeriodTitle; StrSubstNo(Text006, LocMgt.Date2Text(StartingDate), LocMgt.Date2Text(EndingDate)))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Customer_Accounting_CardCaption; Customer_Accounting_CardCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Customer_No_; "No.")
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Customer_Agreement_Filter; "Agreement Filter")
            {
            }
            column(Customer_Date_Filter; "Date Filter")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(Customer_Name; Customer.Name)
                {
                }
                column(Customer__No__; Customer."No.")
                {
                }
                column(Customer__Currency_Code_; Customer."Currency Code")
                {
                }
                column(StartingBalance; StartingBalance)
                {
                }
                column(Text004_LocMgt_Date2Text_StartingDate_; Text004 + LocMgt.Date2Text(StartingDate))
                {
                }
                column(SignBalanceBegining; SignBalanceBegining)
                {
                }
                column(StartingBalance_Control16; StartingBalance)
                {
                }
                column(SignBalanceBegining_Control12; SignBalanceBegining)
                {
                }
                column(Text004_LocMgt_Date2Text_StartingDate__Control10; Text004 + LocMgt.Date2Text(StartingDate))
                {
                }
                column(Customer_Name_Control42; Customer.Name)
                {
                }
                column(Text005_LocMgt_Date2Text_EndingDate_; Text005 + LocMgt.Date2Text(EndingDate))
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(EndingBalance; EndingBalance)
                {
                }
                column(NewPageForCustomer; NewPageForCustomer)
                {
                }
                column(Text005_LocMgt_Date2Text_EndingDate__Control8; Text005 + LocMgt.Date2Text(EndingDate))
                {
                }
                column(SignBalanceEnding_Control9; SignBalanceEnding)
                {
                }
                column(EndingBalance_Control53; EndingBalance)
                {
                }
                column(Integer_Number; Number)
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    CalcFields = "Debit Amount (LCY)", "Credit Amount (LCY)";
                    DataItemLink = "Customer No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Agreement No." = field("Agreement Filter"), "Posting Date" = field("Date Filter");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date", "Currency Code", "Agreement No.");
                    column(Posting_DateCaption; Posting_DateCaptionLbl)
                    {
                    }
                    column(Document_No_Caption; Document_No_CaptionLbl)
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(Net_ChangeCaption; Net_ChangeCaptionLbl)
                    {
                    }
                    column(DebitCaption; DebitCaptionLbl)
                    {
                    }
                    column(CreditCaption; CreditCaptionLbl)
                    {
                    }
                    column(Entry_No_Caption; Entry_No_CaptionLbl)
                    {
                    }
                    column(Document_TypeCaption; Document_TypeCaptionLbl)
                    {
                    }
                    column(Agreement_No_Caption; Agreement_No_CaptionLbl)
                    {
                    }
                    column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Cust__Ledger_Entry_Customer_No_; "Customer No.")
                    {
                    }
                    column(Cust__Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Cust__Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    column(Cust__Ledger_Entry_Agreement_No_; "Agreement No.")
                    {
                    }
                    column(Cust__Ledger_Entry_Posting_Date; "Posting Date")
                    {
                    }
                    dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                    {
                        DataItemLink = "Cust. Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
                        column(Detailed_Cust__Ledg__Entry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Document_No__; "Document No.")
                        {
                        }
                        column(Cust__Ledger_Entry__Description; "Cust. Ledger Entry".Description)
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                        {
                        }
                        column(Total_Detailed_Cust__Ledg__Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                        {
                        }
                        column(Total_Detailed_Cust__Ledg__Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Entry_No__; "Entry No.")
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Document_Type_; "Document Type")
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Entry_Type_; "Entry Type")
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry__Agreement_No__; "Agreement No.")
                        {
                        }
                        column(RowNumber; RowNumber)
                        {
                        }
                        column(PageNo; PageNo)
                        {
                        }
                        column(Detailed_Cust__Ledg__Entry_Cust__Ledger_Entry_No_; "Cust. Ledger Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "Entry Type" = "Entry Type"::Application then
                                if "Prepmt. Diff." then begin
                                    if HasRelatedRealizedEntry("Transaction No.") or (not IsCurrencyAdjEntry()) then
                                        CurrReport.Skip();
                                end else
                                    CurrReport.Skip();

                            case "Entry Type" of
                                "Entry Type"::"Unrealized Gain":
                                    begin
                                        DtldCustLedgEntry2.Reset();
                                        DtldCustLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.");
                                        DtldCustLedgEntry2.SetRange("Cust. Ledger Entry No.", "Cust. Ledger Entry"."Entry No.");
                                        DtldCustLedgEntry2.SetRange("Entry Type", "Entry Type"::"Realized Gain");
                                        DtldCustLedgEntry2.SetRange("Posting Date", "Posting Date");
                                        if DtldCustLedgEntry2.FindFirst() then
                                            if Abs("Amount (LCY)") >= Abs(DtldCustLedgEntry2."Amount (LCY)") then
                                                "Credit Amount (LCY)" := "Credit Amount (LCY)" - DtldCustLedgEntry2."Debit Amount (LCY)"
                                            else
                                                CurrReport.Skip();
                                    end;
                                "Entry Type"::"Realized Gain":
                                    begin
                                        DtldCustLedgEntry2.Reset();
                                        DtldCustLedgEntry2.SetCurrentKey("Cust. Ledger Entry No.");
                                        DtldCustLedgEntry2.SetRange("Cust. Ledger Entry No.", "Cust. Ledger Entry"."Entry No.");
                                        DtldCustLedgEntry2.SetRange("Entry Type", "Entry Type"::"Unrealized Gain");
                                        DtldCustLedgEntry2.SetRange("Posting Date", "Posting Date");
                                        if DtldCustLedgEntry2.FindFirst() then
                                            if Abs("Amount (LCY)") >= Abs(DtldCustLedgEntry2."Amount (LCY)") then // print Realized Gain Debit
                                                "Debit Amount (LCY)" := "Debit Amount (LCY)" - DtldCustLedgEntry2."Credit Amount (LCY)"
                                            else
                                                CurrReport.Skip();
                                    end;
                            end;
                        end;

                        trigger OnPreDataItem()
                        begin
                            RowNumber := RowNumber + 1;
                        end;
                    }
                }

                trigger OnPostDataItem()
                begin
                    if NewPageForCustomer then
                        PageNo += 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, CalcDate('<-1D>', StartingDate));
                CalcFields("Net Change (LCY)");
                if "Net Change (LCY)" > 0 then
                    SignBalanceBegining := Text002
                else
                    if "Net Change (LCY)" < 0 then
                        SignBalanceBegining := Text003
                    else
                        SignBalanceBegining := '';
                StartingBalance := "Net Change (LCY)";
                SetRange("Date Filter", 0D, EndingDate);
                CalcFields("Net Change (LCY)");
                if "Net Change (LCY)" > 0 then
                    SignBalanceEnding := Text002
                else
                    if "Net Change (LCY)" < 0 then
                        SignBalanceEnding := Text003
                    else
                        SignBalanceEnding := '';
                EndingBalance := "Net Change (LCY)";
                SetRange("Date Filter", StartingDate, EndingDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                if ("Debit Amount (LCY)" = 0) and
                   ("Credit Amount (LCY)" = 0)
                then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                if GetRangeMin("Date Filter") <> 0D then
                    StartingDate := Customer.GetRangeMin("Date Filter");
                if GetRangeMax("Date Filter") <> 0D then
                    EndingDate := Customer.GetRangeMax("Date Filter")
                else
                    EndingDate := WorkDate();
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
                    field(NewPageForCustomer; NewPageForCustomer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New page for Customer';
                        ToolTip = 'Specifies if you want to print the data for each customer on a separate page.';
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
        RequestFilter := Customer.GetFilters();
        if Customer.GetRangeMin("Date Filter") > 0D then
            StartingDate := Customer.GetRangeMin("Date Filter");
        EndingDate := Customer.GetRangeMax("Date Filter");

        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Debit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Credit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'Starting Balance as of ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Ending Balance as of ';
#pragma warning restore AA0074
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        LocMgt: Codeunit "Localisation Management";
        CurrentDate: Text[30];
        RequestFilter: Text;
        SignBalanceBegining: Text[10];
        SignBalanceEnding: Text[10];
        StartingBalance: Decimal;
        EndingBalance: Decimal;
        StartingDate: Date;
        EndingDate: Date;
        NewPageForCustomer: Boolean;
        RowNumber: Integer;
        PageNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'For Period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Customer_Accounting_CardCaptionLbl: Label 'Customer Accounting Card';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Document_No_CaptionLbl: Label 'Document No.';
        DescriptionCaptionLbl: Label 'Description';
        Net_ChangeCaptionLbl: Label 'Net Change';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Entry_No_CaptionLbl: Label 'Entry\No.';
        Document_TypeCaptionLbl: Label 'Document Type';
        Agreement_No_CaptionLbl: Label 'Agreement No.';

    local procedure HasRelatedRealizedEntry(TransactionNo: Integer): Boolean
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetFilter("Entry Type", '%1|%2', DtldCustLedgEntry."Entry Type"::"Realized Gain", DtldCustLedgEntry."Entry Type"::"Realized Loss");
        DtldCustLedgEntry.SetRange("Transaction No.", TransactionNo);
        exit(not DtldCustLedgEntry.IsEmpty);
    end;

    local procedure IsCurrencyAdjEntry(): Boolean
    begin
        exit(("Detailed Cust. Ledg. Entry".Amount = 0) and ("Detailed Cust. Ledg. Entry"."Amount (LCY)" <> 0));
    end;
}

