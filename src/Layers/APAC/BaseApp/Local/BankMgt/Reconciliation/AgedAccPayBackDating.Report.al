// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 17117 "Aged Acc. Pay. (BackDating)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Reconciliation/AgedAccPayBackDating.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Aged Acc. Pay. (BackDating)';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", Blocked;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(Aged_By_____DateTitle; 'Aged By ' + DateTitle)
            {
            }
            column(Vendor_TABLECAPTION__________AccountFilter; Vendor.TableCaption + ': ' + AccountFilter)
            {
            }
            column(AccountFilter; AccountFilter)
            {
            }
            column(UseCurrencyNo; UseCurrencyNo)
            {
            }
            column(VenRecordNo; VenRecordNo)
            {
            }
            column(PrintOnePrPage; PrintOnePrPage)
            {
            }
            column(ColumnHeader_3_; ColumnHeader[3])
            {
            }
            column(ColumnHeader_2_; ColumnHeader[2])
            {
            }
            column(ColumnHeader_4_; ColumnHeader[4])
            {
            }
            column(ColumnHeaderHeader; ColumnHeaderHeader)
            {
            }
            column(ColumnHeader_1_; ColumnHeader[1])
            {
            }
            column(DateTitle; DateTitle)
            {
            }
            column(ColumnHeader_5_; ColumnHeader[5])
            {
            }
            column(PrintEntryDetails; PrintEntryDetails)
            {
            }
            column(ColumnHeader_1__Control1450037; ColumnHeader[1])
            {
            }
            column(ColumnHeader_2__Control1450038; ColumnHeader[2])
            {
            }
            column(ColumnHeader_3__Control1450039; ColumnHeader[3])
            {
            }
            column(ColumnHeader_4__Control1450040; ColumnHeader[4])
            {
            }
            column(ColumnHeaderHeader_Control1450041; ColumnHeaderHeader)
            {
            }
            column(ColumnHeader_5__Control1450058; ColumnHeader[5])
            {
            }
            column(Vendor__No__; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Vendor__Phone_No__; "Phone No.")
            {
            }
            column(BlockedDescription; BlockedDescription)
            {
            }
            column(Vendor_Contact; Contact)
            {
            }
            column(AccountNetChange; AccountNetChange)
            {
            }
            column(GetCurrencyCode____; GetCurrencyCode(''))
            {
            }
            column(PrintAccountDetails; PrintAccountDetails)
            {
            }
            column(Vendor___Aged_Accounts_PayableCaption; Vendor___Aged_Accounts_PayableCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Amounts_are_in_Document_Currency__Totals_are_in_LCY_Caption; Amounts_are_in_Document_Currency__Totals_are_in_LCY_CaptionLbl)
            {
            }
            column(Amounts_are_in_Vendor_Currency__Totals_are_in_LCY_Caption; Amounts_are_in_Vendor_Currency__Totals_are_in_LCY_CaptionLbl)
            {
            }
            column(All_amounts_are_in_LCY_Caption; All_amounts_are_in_LCY_CaptionLbl)
            {
            }
            column(Currency_CodeCaption; Currency_CodeCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Document_TypeCaption; Document_TypeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(Currency_CodeCaption_Control1450042; Currency_CodeCaption_Control1450042Lbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(BalanceCaption_Control1450010; BalanceCaption_Control1450010Lbl)
            {
            }
            column(Vendor__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Vendor_ContactCaption; FieldCaption(Contact))
            {
            }
            column(Net_ChangeCaption; Net_ChangeCaptionLbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(EntryDate; Format(EntryDate))
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
                column(GetCurrencyCode_CurrencyCode_; GetCurrencyCode(CurrencyCode))
                {
                }
                column(EntryAmount_1_; EntryAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(EntryAmount_2_; EntryAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(EntryAmount_3_; EntryAmount[3])
                {
                    AutoFormatType = 1;
                }
                column(EntryAmount_4_; EntryAmount[4])
                {
                    AutoFormatType = 1;
                }
                column(EntryAmount_5__EntryAmount_4__EntryAmount_3__EntryAmount_2__EntryAmount_1_; EntryAmount[5] + EntryAmount[4] + EntryAmount[3] + EntryAmount[2] + EntryAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(EntryAmount_5_; EntryAmount[5])
                {
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }

                trigger OnAfterGetRecord()
                var
                    RemainingAmount: Decimal;
                    RemainingAmountLCY: Decimal;
                    i: Integer;
                begin
                    CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    RemainingAmount := "Remaining Amount";
                    RemainingAmountLCY := "Remaining Amt. (LCY)";

                    case UseAgingDate of
                        UseAgingDate::"Posting Date":
                            EntryDate := "Posting Date";
                        UseAgingDate::"Document Date":
                            EntryDate := "Document Date";
                        UseAgingDate::"Due Date":
                            EntryDate := "Due Date";
                    end;

                    case UseCurrency of
                        UseCurrency::"Document Currency":
                            CurrencyCode := "Currency Code";
                        UseCurrency::"Vendor Currency":
                            RemainingAmount :=
                              Round(
                                CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                                  PeriodStartDate[5],
                                  "Currency Code",
                                  CurrencyCode,
                                  "Remaining Amount"),
                                Currency."Amount Rounding Precision");
                        UseCurrency::LCY:
                            RemainingAmount := RemainingAmountLCY;
                    end;

                    for i := 1 to 5 do
                        if (EntryDate >= PeriodStartDate[i]) and
                           (EntryDate <= ClosingDate(CalcDate('-1D', PeriodStartDate[i + 1])))
                        then begin
                            EntryAmount[i] := RemainingAmount;
                            if PrintTotalsPerCurrency and (CurrencyCode <> '') then begin
                                UpdateTotal(
                                  CVLedgerEntryBuffer2, TempCurrency2, CurrencyCode, i, RemainingAmount, RemainingAmountLCY);
                                UpdateTotal(
                                  CVLedgerEntryBuffer3, TempCurrency3, CurrencyCode, i, RemainingAmount, RemainingAmountLCY);
                            end;
                            UpdateTotal(CVLedgerEntryBuffer4, TempCurrency4, '', i, 0, RemainingAmountLCY);
                            UpdateTotal(CVLedgerEntryBuffer5, TempCurrency4, '', i, 0, RemainingAmountLCY);
                        end else
                            EntryAmount[i] := 0;
                end;

                trigger OnPreDataItem()
                var
                    DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
                begin
                    Reset();
                    DtldVendorLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type");
                    DtldVendorLedgEntry.SetRange("Vendor No.", Vendor."No.");
                    DtldVendorLedgEntry.SetRange("Posting Date", CalcDate('<+1D>', PeriodStartDate[5]), PeriodStartDate[6]);
                    DtldVendorLedgEntry.SetRange("Entry Type", DtldVendorLedgEntry."Entry Type"::Application);
                    CopyDimFiltersFromVendor(DtldVendorLedgEntry);
                    if DtldVendorLedgEntry.Find('-') then
                        repeat
                            "Entry No." := DtldVendorLedgEntry."Vendor Ledger Entry No.";
                            Mark(true);
                        until DtldVendorLedgEntry.Next() = 0;

                    SetCurrentKey("Vendor No.", Open);
                    SetRange("Vendor No.", Vendor."No.");
                    SetRange(Open, true);
                    SetRange("Posting Date", 0D, PeriodStartDate[5]);
                    CopyDimFiltersFromVendor("Vendor Ledger Entry");
                    if Find('-') then
                        repeat
                            Mark(true);
                        until Next() = 0;

                    SetCurrentKey("Entry No.");
                    SetRange(Open);
                    MarkedOnly(true);
                    SetRange("Date Filter", 0D, PeriodStartDate[5]);
                end;
            }
            dataitem(AccountTotalsPerCurrency; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(GetCurrencyCode_TempCurrency2_Code_; GetCurrencyCode(TempCurrency2.Code))
                {
                }
                column(Vendor_Name_Control1450072; Vendor.Name)
                {
                }
                column(Vendor__No___Control1450073; Vendor."No.")
                {
                }
                column(AccountTotalPerCurrency_1_; AccountTotalPerCurrency[1])
                {
                    AutoFormatExpression = TempCurrency2.Code;
                    AutoFormatType = 1;
                }
                column(AccountTotalPerCurrency_2_; AccountTotalPerCurrency[2])
                {
                    AutoFormatExpression = TempCurrency2.Code;
                    AutoFormatType = 1;
                }
                column(AccountTotalPerCurrency_3_; AccountTotalPerCurrency[3])
                {
                    AutoFormatExpression = TempCurrency2.Code;
                    AutoFormatType = 1;
                }
                column(AccountTotalPerCurrency_4_; AccountTotalPerCurrency[4])
                {
                    AutoFormatExpression = TempCurrency2.Code;
                    AutoFormatType = 1;
                }
                column(AccTotalPerCurrency_5__AccTotalPerCurrency_4__AccTotalPerCurrency_3__AccTotalPerCurrency_2__AccTotalPerCurrency_1_; AccountTotalPerCurrency[5] + AccountTotalPerCurrency[4] + AccountTotalPerCurrency[3] + AccountTotalPerCurrency[2] + AccountTotalPerCurrency[1])
                {
                    AutoFormatExpression = TempCurrency2.Code;
                    AutoFormatType = 1;
                }
                column(AccountTotalPerCurrency_5_; AccountTotalPerCurrency[5])
                {
                    AutoFormatExpression = TempCurrency2.Code;
                    AutoFormatType = 1;
                }
                column(AccountTotalsPerCurrency_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                var
                    i: Integer;
                    OK: Boolean;
                begin
                    if Number = 1 then
                        OK := TempCurrency2.Find('-')
                    else
                        OK := TempCurrency2.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    for i := 1 to 5 do
                        AccountTotalPerCurrency[i] := GetAccountTotalPerCurrency(TempCurrency2.Code, i);
                end;
            }
            dataitem(AccountTotals; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GetCurrencyCode_____Control1450078; GetCurrencyCode(''))
                {
                }
                column(Vendor_Name_Control1450079; Vendor.Name)
                {
                }
                column(Vendor__No___Control1450080; Vendor."No.")
                {
                }
                column(AccountTotal_1_; AccountTotal[1])
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                }
                column(AccountTotal_2_; AccountTotal[2])
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                }
                column(AccountTotal_3_; AccountTotal[3])
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                }
                column(AccountTotal_4_; AccountTotal[4])
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                }
                column(AccountTotal_5__AccountTotal_4__AccountTotal_3__AccountTotal_2__AccountTotal_1_; AccountTotal[5] + AccountTotal[4] + AccountTotal[3] + AccountTotal[2] + AccountTotal[1])
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                }
                column(AccountTotal_5_; AccountTotal[5])
                {
                    AutoFormatExpression = '';
                    AutoFormatType = 1;
                }
                column(AccountTotals_Number; Number)
                {
                }
                column(Total__All_Currencies_Caption; Total__All_Currencies_CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    for i := 1 to 5 do
                        AccountTotal[i] := GetAccountTotal(i);
                end;
            }

            trigger OnAfterGetRecord()
            var
                VendorLedgerEntry: Record "Vendor Ledger Entry";
                CurrencyFactor: Decimal;
            begin
                if PrintTotalsPerCurrency then begin
                    CVLedgerEntryBuffer2.Reset();
                    CVLedgerEntryBuffer2.DeleteAll();
                    TempCurrency2.DeleteAll();
                end;
                CVLedgerEntryBuffer4.Reset();
                CVLedgerEntryBuffer4.DeleteAll();

                VendorLedgerEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date", "Currency Code");
                VendorLedgerEntry.SetRange("Vendor No.", "No.");
                VendorLedgerEntry.SetRange(Open, true);
                CopyDimFiltersFromVendor(VendorLedgerEntry);
                CalcFields("Net Change (LCY)");
                AccountNetChange := "Net Change (LCY)";
                VendorLedgerEntry.SetRange("Posting Date", 0D, PeriodStartDate[5]);
                if AccountNetChange = 0 then
                    if not VendorLedgerEntry.FindFirst() then
                        CurrReport.Skip();

                HasEntry := true;

                case UseCurrency of
                    UseCurrency::"Vendor Currency":
                        begin
                            CurrencyCode := "Currency Code";
                            if not Currency.Get("Currency Code") then
                                Currency.Init();
                            CurrencyFactor := CurrencyExchangeRate.ExchangeRate(PeriodStartDate[5], "Currency Code");
                        end;
                    UseCurrency::LCY, UseCurrency::"Document Currency":
                        CurrencyCode := '';
                end;

                if "Privacy Blocked" then
                    BlockedDescription := Text1450002Txt;

                case Blocked of
                    Blocked::All:
                        BlockedDescription := Text1450000;
                    Blocked::Payment:
                        BlockedDescription := Text1450001;
                    else
                        BlockedDescription := '';
                end;

                if (UseCurrency = UseCurrency::"Vendor Currency") and
                   ("Currency Code" <> '')
                then
                    AccountNetChange :=
                      Round(
                        CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                          PeriodStartDate[5],
                          "Currency Code",
                          CurrencyCode,
                          AccountNetChange),
                        Currency."Amount Rounding Precision");

                // SOLVE THE PROPERTY OF NEWPAGEPERRECORD
                if PrintOnePrPage then
                    VenRecordNo := VenRecordNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, PeriodStartDate[5]);

                // SOLVE OPTION VARIABLE
                UseCurrencyNo := UseCurrency;
            end;
        }
        dataitem(TotalsPerCurrency; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(GetCurrencyCode_TempCurrency3_Code_; GetCurrencyCode(TempCurrency3.Code))
            {
            }
            column(TotalPerCurrency_1_; TotalPerCurrency[1])
            {
                AutoFormatExpression = TempCurrency3.Code;
                AutoFormatType = 1;
            }
            column(TotalPerCurrency_2_; TotalPerCurrency[2])
            {
                AutoFormatExpression = TempCurrency3.Code;
                AutoFormatType = 1;
            }
            column(TotalPerCurrency_3_; TotalPerCurrency[3])
            {
                AutoFormatExpression = TempCurrency3.Code;
                AutoFormatType = 1;
            }
            column(TotalPerCurrency_4_; TotalPerCurrency[4])
            {
                AutoFormatExpression = TempCurrency3.Code;
                AutoFormatType = 1;
            }
            column(TotalPerCurrency_5__TotalPerCurrency_4__TotalPerCurrency_3__TotalPerCurrency_2__TotalPerCurrency_1_; TotalPerCurrency[5] + TotalPerCurrency[4] + TotalPerCurrency[3] + TotalPerCurrency[2] + TotalPerCurrency[1])
            {
                AutoFormatExpression = TempCurrency3.Code;
                AutoFormatType = 1;
            }
            column(TotalPerCurrency_5_; TotalPerCurrency[5])
            {
                AutoFormatExpression = TempCurrency3.Code;
                AutoFormatType = 1;
            }
            column(TotalsPerCurrency_Number; Number)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                OK: Boolean;
            begin
                if not HasEntry then
                    CurrReport.Break();
                if Number = 1 then
                    OK := TempCurrency3.Find('-')
                else
                    OK := TempCurrency3.Next() <> 0;
                if not OK then
                    CurrReport.Break();

                for i := 1 to 5 do
                    TotalPerCurrency[i] := GetTotalPerCurrency(TempCurrency3.Code, i);
            end;
        }
        dataitem(Totals; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(GetCurrencyCode_____Control1450066; GetCurrencyCode(''))
            {
            }
            column(Total_1_; Total[1])
            {
                AutoFormatExpression = '';
                AutoFormatType = 1;
            }
            column(Total_2_; Total[2])
            {
                AutoFormatExpression = '';
                AutoFormatType = 1;
            }
            column(Total_3_; Total[3])
            {
                AutoFormatExpression = '';
                AutoFormatType = 1;
            }
            column(Total_4_; Total[4])
            {
                AutoFormatExpression = '';
                AutoFormatType = 1;
            }
            column(Total_5__Total_4__Total_3__Total_2__Total_1_; Total[5] + Total[4] + Total[3] + Total[2] + Total[1])
            {
                AutoFormatExpression = '';
                AutoFormatType = 1;
            }
            column(Total_5_; Total[5])
            {
                AutoFormatExpression = '';
                AutoFormatType = 1;
            }
            column(Totals_Number; Number)
            {
            }
            column(TotalCaption_Control1450067; TotalCaption_Control1450067Lbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not HasEntry then
                    CurrReport.Break();
                for i := 1 to 5 do
                    Total[i] := GetTotal(i);
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
                    field(AgedAsOf; PeriodStartDate[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged As Of';
                        ToolTip = 'Specifies the date that aging is based on. Transactions posted after this date will not be used in this report. The default is the current date.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(UseAgingDate; UseAgingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Aging Date';
                        ToolTip = 'Specifies that you want to use the aging date.';
                    }
                    field(UseCurrency; UseCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Currency';
                        ToolTip = 'Specifies that you want to use the currency.';

                        trigger OnValidate()
                        begin
                            UpdateRequestForm();
                        end;
                    }
                    field(PrintTotalsPerCurrency; PrintTotalsPerCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Totals Per Currency';
                        Enabled = PrintTotalsPerCurrencyEnable;
                        ToolTip = 'Specifies that you want to print a total amount for each currency.';
                    }
                    field(PrintOnePrPage; PrintOnePrPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if information about each vendor is printed on a new page.';
                    }
                    field(PrintAccountDetails; PrintAccountDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Account Details';
                        ToolTip = 'Specifies that you want to print details about the account.';

                        trigger OnValidate()
                        begin
                            UpdateRequestForm();
                        end;
                    }
                    field(PrintEntryDetails; PrintEntryDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Entry Details';
                        Enabled = PrintEntryDetailsEnable;
                        ToolTip = 'Specifies that you want to include details about each entry.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrintTotalsPerCurrencyEnable := true;
            PrintEntryDetailsEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if PeriodStartDate[5] = 0D then
                PeriodStartDate[5] := WorkDate();
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<30D>');
            UpdateRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        i: Integer;
    begin
        AccountFilter := Vendor.GetFilters();
        EntryNo := 0;

        PeriodStartDate[6] := 99991231D;
        for i := 4 downto 2 do begin
            PeriodStartDate[i] := CalcDate('-' + Format(PeriodLength), PeriodStartDate[i + 1]);
            ColumnHeader[i] :=
              Format(PeriodStartDate[5] - PeriodStartDate[i + 1] + 1) + ' - ' +
              Format(PeriodStartDate[5] - PeriodStartDate[i]) +
              ' Days';
        end;

        ColumnHeader[1] := Text1450016 + Format(PeriodStartDate[5] - PeriodStartDate[2] + 1) + Text1450026;
        ColumnHeader[5] := Text1450008;
        SubTitle := '(';
        if PrintEntryDetails then
            SubTitle := Text1450027
        else
            SubTitle := Text1450028;
        SubTitle := '(' + SubTitle + Text1450029 + Format(PeriodStartDate[5], 0, 4) + ')';

        case UseAgingDate of
            UseAgingDate::"Due Date":
                begin
                    DateTitle := Text1450030;
                    ColumnHeaderHeader := Text1450033;
                end;
            UseAgingDate::"Posting Date":
                begin
                    DateTitle := Text1450031;
                    ColumnHeaderHeader := Text1450034;
                end;
            UseAgingDate::"Document Date":
                begin
                    DateTitle := Text1450032;
                    ColumnHeaderHeader := Text1450034;
                end;
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TempCurrency2: Record Currency temporary;
        TempCurrency3: Record Currency temporary;
        TempCurrency4: Record Currency temporary;
        CVLedgerEntryBuffer2: Record "CV Ledger Entry Buffer" temporary;
        CVLedgerEntryBuffer3: Record "CV Ledger Entry Buffer" temporary;
        CVLedgerEntryBuffer4: Record "CV Ledger Entry Buffer" temporary;
        CVLedgerEntryBuffer5: Record "CV Ledger Entry Buffer" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PeriodStartDate: array[6] of Date;
        EntryDate: Date;
        PeriodLength: DateFormula;
        AccountFilter: Text[250];
        ColumnHeader: array[5] of Text[30];
        ColumnHeaderHeader: Text[30];
        SubTitle: Text[88];
        DateTitle: Text[30];
        BlockedDescription: Text[50];
        CurrencyCode: Code[10];
        UseAgingDate: Option "Posting Date","Document Date","Due Date";
        UseCurrency: Option "Document Currency","Vendor Currency",LCY;
        PrintOnePrPage: Boolean;
        PrintAccountDetails: Boolean;
        PrintEntryDetails: Boolean;
        PrintTotalsPerCurrency: Boolean;
        HasGLSetup: Boolean;
        HasEntry: Boolean;
        EntryNo: Integer;
        Text1450000: Label '*** This vendor is blocked ***';
        Text1450001: Label '*** This vendor is blocked for payments ***';
        Text1450002Txt: Label '*** This vendor is blocked for privacy ***';
        Text1450016: Label 'Over ';
        Text1450026: Label ' Days';
        Text1450027: Label 'Detail';
        Text1450028: Label 'Summary';
        Text1450029: Label ', aged as of ';
        Text1450030: Label 'Due Date';
        Text1450031: Label 'Posting Date';
        Text1450032: Label 'Document Date';
        Text1450033: Label 'Aged Overdue Amounts';
        Text1450034: Label 'Aged Vendor Balances';
        EntryAmount: array[5] of Decimal;
        AccountNetChange: Decimal;
        Text1450008: Label 'Current';
        AccountTotal: array[5] of Decimal;
        AccountTotalPerCurrency: array[5] of Decimal;
        Total: array[5] of Decimal;
        TotalPerCurrency: array[5] of Decimal;
        UseCurrencyNo: Integer;
        VenRecordNo: Integer;
        i: Integer;
        PrintTotalsPerCurrencyEnable: Boolean;
        PrintEntryDetailsEnable: Boolean;
        Vendor___Aged_Accounts_PayableCaptionLbl: Label 'Vendor - Aged Accounts Payable';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Amounts_are_in_Document_Currency__Totals_are_in_LCY_CaptionLbl: Label 'Amounts are in Document Currency, Totals are in LCY.';
        Amounts_are_in_Vendor_Currency__Totals_are_in_LCY_CaptionLbl: Label 'Amounts are in Vendor Currency, Totals are in LCY.';
        All_amounts_are_in_LCY_CaptionLbl: Label 'All amounts are in LCY.';
        Currency_CodeCaptionLbl: Label 'Currency Code';
        DescriptionCaptionLbl: Label 'Description';
        Document_No_CaptionLbl: Label 'Document No.';
        Document_TypeCaptionLbl: Label 'Document Type';
        BalanceCaptionLbl: Label 'Balance';
        Currency_CodeCaption_Control1450042Lbl: Label 'Currency Code';
        NameCaptionLbl: Label 'Name';
        No_CaptionLbl: Label 'No.';
        BalanceCaption_Control1450010Lbl: Label 'Balance';
        Net_ChangeCaptionLbl: Label 'Net Change';
        Total__All_Currencies_CaptionLbl: Label 'Total (All Currencies)';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control1450067Lbl: Label 'Total';

    local procedure UpdateTotal(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; var TempCurrency: Record Currency; CurrencyCode: Code[20]; i: Integer; Amount: Decimal; AmountLCY: Decimal)
    begin
        if not TempCurrency.Get(CurrencyCode) then begin
            TempCurrency.Init();
            TempCurrency.Code := CurrencyCode;
            TempCurrency.Insert();
        end;
        CVLedgerEntryBuffer.Reset();
        CVLedgerEntryBuffer.SetRange("Currency Code", CurrencyCode);
        CVLedgerEntryBuffer.SetRange("Transaction No.", i);
        if CVLedgerEntryBuffer.Find('-') then begin
            CVLedgerEntryBuffer.Amount := CVLedgerEntryBuffer.Amount + Amount;
            CVLedgerEntryBuffer."Amount (LCY)" := CVLedgerEntryBuffer."Amount (LCY)" + AmountLCY;
            CVLedgerEntryBuffer.Modify();
        end else begin
            EntryNo := EntryNo + 1;
            CVLedgerEntryBuffer."Entry No." := EntryNo;
            CVLedgerEntryBuffer."Currency Code" := CurrencyCode;
            CVLedgerEntryBuffer."Transaction No." := i;
            CVLedgerEntryBuffer.Amount := Amount;
            CVLedgerEntryBuffer."Amount (LCY)" := AmountLCY;
            CVLedgerEntryBuffer.Insert();
        end;
    end;

    local procedure GetTotalPerCurrency(CurrencyCode: Code[20]; i: Integer): Decimal
    begin
        CVLedgerEntryBuffer3.Reset();
        CVLedgerEntryBuffer3.SetRange("Currency Code", CurrencyCode);
        CVLedgerEntryBuffer3.SetRange("Transaction No.", i);
        if CVLedgerEntryBuffer3.Find('-') then
            exit(CVLedgerEntryBuffer3.Amount);

        exit(0);
    end;

    local procedure GetAccountTotalPerCurrency(CurrencyCode: Code[20]; i: Integer): Decimal
    begin
        CVLedgerEntryBuffer2.Reset();
        CVLedgerEntryBuffer2.SetRange("Currency Code", CurrencyCode);
        CVLedgerEntryBuffer2.SetRange("Transaction No.", i);
        if CVLedgerEntryBuffer2.Find('-') then
            exit(CVLedgerEntryBuffer2.Amount);

        exit(0);
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode = '' then begin
            if not HasGLSetup then
                HasGLSetup := GLSetup.Get();
            exit(GLSetup."LCY Code");
        end;
        exit(CurrencyCode);
    end;

    local procedure UpdateRequestForm()
    begin
        PageUpdateRequestForm();
    end;

    local procedure GetTotal(i: Integer): Decimal
    begin
        CVLedgerEntryBuffer5.Reset();
        CVLedgerEntryBuffer5.SetRange("Currency Code", '');
        CVLedgerEntryBuffer5.SetRange("Transaction No.", i);
        if CVLedgerEntryBuffer5.Find('-') then
            exit(CVLedgerEntryBuffer5."Amount (LCY)");

        exit(0);
    end;

    local procedure GetAccountTotal(i: Integer): Decimal
    begin
        CVLedgerEntryBuffer4.Reset();
        CVLedgerEntryBuffer4.SetRange("Currency Code", '');
        CVLedgerEntryBuffer4.SetRange("Transaction No.", i);
        if CVLedgerEntryBuffer4.Find('-') then
            exit(CVLedgerEntryBuffer4."Amount (LCY)");

        exit(0);
    end;

    local procedure PageUpdateRequestForm()
    begin
        PrintTotalsPerCurrencyEnable := UseCurrency <> UseCurrency::LCY;
        if PrintTotalsPerCurrencyEnable = false then
            PrintTotalsPerCurrency := false;
        PrintEntryDetailsEnable := PrintAccountDetails = true;
        if PrintEntryDetailsEnable = false then
            PrintEntryDetails := false;
    end;

    local procedure CopyDimFiltersFromVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if Vendor.GetFilter("Global Dimension 1 Filter") <> '' then
            VendorLedgerEntry.SetFilter("Global Dimension 1 Code", Vendor.GetFilter("Global Dimension 1 Filter"));
        if Vendor.GetFilter("Global Dimension 2 Filter") <> '' then
            VendorLedgerEntry.SetFilter("Global Dimension 2 Code", Vendor.GetFilter("Global Dimension 2 Filter"));
        CopyDimFiltersFromVendorToVendorLedgerEntry(VendorLedgerEntry, Vendor);
    end;

    local procedure CopyDimFiltersFromVendor(var DtldVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        if Vendor.GetFilter("Global Dimension 1 Filter") <> '' then
            DtldVendorLedgEntry.SetFilter("Initial Entry Global Dim. 1", Vendor.GetFilter("Global Dimension 1 Filter"));
        if Vendor.GetFilter("Global Dimension 2 Filter") <> '' then
            DtldVendorLedgEntry.SetFilter("Initial Entry Global Dim. 2", Vendor.GetFilter("Global Dimension 2 Filter"));
        CopyDimFiltersFromVendorToDetailedVendorLedgEntry(DtldVendorLedgEntry, Vendor);
    end;

    [IntegrationEvent(false, false)]
    local procedure CopyDimFiltersFromVendorToVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CopyDimFiltersFromVendorToDetailedVendorLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; var Vendor: Record Vendor)
    begin
    end;
}

