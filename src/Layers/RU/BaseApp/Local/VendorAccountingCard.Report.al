#pragma warning disable AA0247
report 12445 "Vendor Accounting Card"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/VendorAccountingCard.rdlc';
    Caption = 'Vendor Accounting Card';

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Vendor Posting Group", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Agreement Filter", "Date Filter";
            column(RequestFilter; RequestFilter)
            {
            }
            column(HeaderPeriodTitle; StrSubstNo(Text005, LocMgt.Date2Text(StartingDate), LocMgt.Date2Text(EndingDate)))
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
            column(Vendor_Accounting_CardCaption; Vendor_Accounting_CardCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor_No_; "No.")
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Vendor_Agreement_Filter; "Agreement Filter")
            {
            }
            column(Vendor_Date_Filter; "Date Filter")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(Vendor_Name; Vendor.Name)
                {
                }
                column(Vendor__No__; Vendor."No.")
                {
                }
                column(Vendor__Currency_Code_; Vendor."Currency Code")
                {
                }
                column(BalanceBegining; BalanceBegining)
                {
                }
                column(Text004_LocMgt_Date2Text_StartingDate_; Text004 + LocMgt.Date2Text(StartingDate))
                {
                }
                column(SignBalanceBegining; SignBalanceBegining)
                {
                }
                column(BalanceBegining_Control82; BalanceBegining)
                {
                }
                column(Text004_LocMgt_Date2Text_StartingDate__Control83; Text004 + LocMgt.Date2Text(StartingDate))
                {
                }
                column(SignBalanceBegining_Control84; SignBalanceBegining)
                {
                }
                column(Vendor_Name_Control42; Vendor.Name)
                {
                }
                column(Text004_LocMgt_Date2Text_EndingDate_; Text004 + LocMgt.Date2Text(EndingDate))
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(Text004_LocMgt_Date2Text_EndingDate__Control79; Text004 + LocMgt.Date2Text(EndingDate))
                {
                }
                column(SignBalanceEnding_Control80; SignBalanceEnding)
                {
                }
                column(BalanceEnding_Control81; BalanceEnding)
                {
                }
                column(Integer_Number; Number)
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Agreement No." = field("Agreement Filter"), "Posting Date" = field("Date Filter");
                    DataItemLinkReference = Vendor;
                    DataItemTableView = sorting("Vendor No.", "Posting Date", "Currency Code");
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
                    column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Vendor_Ledger_Entry_Vendor_No_; "Vendor No.")
                    {
                    }
                    column(Vendor_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Vendor_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    column(Vendor_Ledger_Entry_Agreement_No_; "Agreement No.")
                    {
                    }
                    column(Vendor_Ledger_Entry_Posting_Date; "Posting Date")
                    {
                    }
                    dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                    {
                        DataItemLink = "Vendor Ledger Entry No." = field("Entry No.");
                        DataItemTableView = sorting("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
                        column(Detailed_Vendor_Ledg__Entry__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Document_No__; "Document No.")
                        {
                        }
                        column(Vendor_Ledger_Entry__Description; "Vendor Ledger Entry".Description)
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                        {
                        }
                        column(Total_Detailed_Vendor_Ledg__Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                        {
                        }
                        column(Total_Detailed_Vendor_Ledg__Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Document_Type_; "Document Type")
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Entry_No__; "Entry No.")
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Entry_Type_; "Entry Type")
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry__Agreement_No__; "Agreement No.")
                        {
                        }
                        column(VendorNo; VendorNo)
                        {
                        }
                        column(Detailed_Vendor_Ledg__Entry_Vendor_Ledger_Entry_No_; "Vendor Ledger Entry No.")
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
                                "Entry Type"::"Unrealized Loss":
                                    begin
                                        DtldVendLedgEntry2.Reset();
                                        DtldVendLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.");
                                        DtldVendLedgEntry2.SetRange("Vendor Ledger Entry No.", "Vendor Ledger Entry"."Entry No.");
                                        DtldVendLedgEntry2.SetRange("Entry Type", "Entry Type"::"Realized Loss");
                                        DtldVendLedgEntry2.SetRange("Posting Date", "Posting Date");
                                        if DtldVendLedgEntry2.FindFirst() then
                                            if Abs("Amount (LCY)") >= Abs(DtldVendLedgEntry2."Amount (LCY)") then
                                                "Debit Amount (LCY)" := "Debit Amount (LCY)" - DtldVendLedgEntry2."Credit Amount (LCY)"
                                            else
                                                CurrReport.Skip();
                                    end;
                                "Entry Type"::"Realized Loss":
                                    begin
                                        DtldVendLedgEntry2.Reset();
                                        DtldVendLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.");
                                        DtldVendLedgEntry2.SetRange("Vendor Ledger Entry No.", "Vendor Ledger Entry"."Entry No.");
                                        DtldVendLedgEntry2.SetRange("Entry Type", "Entry Type"::"Unrealized Loss");
                                        DtldVendLedgEntry2.SetRange("Posting Date", "Posting Date");
                                        if DtldVendLedgEntry2.FindFirst() then
                                            if Abs("Amount (LCY)") >= Abs(DtldVendLedgEntry2."Amount (LCY)") then // print Realized Gain Debit
                                                "Credit Amount (LCY)" := "Credit Amount (LCY)" - DtldVendLedgEntry2."Debit Amount (LCY)"
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

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                    end;
                }

                trigger OnPostDataItem()
                begin
                    if NewPageForVendor then
                        VendorNo += 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, CalcDate('<-1D>', StartingDate));
                CalcFields("Net Change (LCY)");
                Value := "Net Change (LCY)";
                if Value < 0 then
                    SignBalanceBegining := Text002
                else
                    if Value > 0 then
                        SignBalanceBegining := Text003
                    else
                        SignBalanceBegining := '';
                BalanceBegining := Abs(Value);
                SetRange("Date Filter", 0D, EndingDate);
                CalcFields("Net Change (LCY)");
                Value := "Net Change (LCY)";
                if Value < 0 then
                    SignBalanceEnding := Text002
                else
                    if Value > 0 then
                        SignBalanceEnding := Text003
                    else
                        SignBalanceEnding := '';
                BalanceEnding := Abs(Value);
                SetRange("Date Filter", StartingDate, EndingDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                if ("Debit Amount (LCY)" = 0) and
                   ("Credit Amount (LCY)" = 0)
                then
                    CurrReport.Skip();
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
                    field(NewPageForVendor; NewPageForVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if you want to print the data for each vendor on a separate page.';
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
        RequestFilter := Vendor.GetFilters();
        if Vendor.GetRangeMin("Date Filter") > 0D then
            StartingDate := Vendor.GetRangeMin("Date Filter");
        EndingDate := Vendor.GetRangeMax("Date Filter");

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
        Text004: Label 'Balance at';
#pragma warning restore AA0074
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        LocMgt: Codeunit "Localisation Management";
        CurrentDate: Text[30];
        RequestFilter: Text;
        SignBalanceBegining: Text[10];
        SignBalanceEnding: Text[10];
        BalanceBegining: Decimal;
        BalanceEnding: Decimal;
        Value: Decimal;
        StartingDate: Date;
        EndingDate: Date;
        NewPageForVendor: Boolean;
        RowNumber: Integer;
        VendorNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'For Period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Vendor_Accounting_CardCaptionLbl: Label 'Vendor Accounting Card';
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
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetFilter("Entry Type", '%1|%2', DtldVendLedgEntry."Entry Type"::"Realized Gain", DtldVendLedgEntry."Entry Type"::"Realized Loss");
        DtldVendLedgEntry.SetRange("Transaction No.", TransactionNo);
        exit(not DtldVendLedgEntry.IsEmpty);
    end;

    local procedure IsCurrencyAdjEntry(): Boolean
    begin
        exit(("Detailed Vendor Ledg. Entry".Amount = 0) and ("Detailed Vendor Ledg. Entry"."Amount (LCY)" <> 0));
    end;
}

