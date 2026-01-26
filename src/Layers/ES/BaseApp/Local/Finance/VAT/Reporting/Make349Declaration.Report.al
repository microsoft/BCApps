// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System;
using System.IO;
using System.Telemetry;
using System.Text;
using System.Utilities;

report 10710 "Make 349 Declaration"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Make 349 Declaration Disk';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                if not Evaluate(NumFiscalYear, FiscalYear) then
                    Error(Text1100000);

                case true of
                    Period in [1 .. 12]:
                        begin
                            Evaluate(StartDateFormula, '<-CM>');
                            Evaluate(EndDateFormula, '<CM>');
                            FromDate := DMY2Date(1, Period, NumFiscalYear);
                            ToDate := CalcDate(EndDateFormula, FromDate);
                            if PeriodFreqChange then
                                FromDate := DMY2Date(1, Period - 1, NumFiscalYear);
                        end;
                    Period in [Period::"1T", Period::"2T", Period::"3T", Period::"4T"]:
                        begin
                            Evaluate(StartDateFormula, '<-CQ>');
                            Evaluate(EndDateFormula, '<CQ>');
                            Evaluate(NumPeriod, DelChr(GetPeriodAsText(), '=', 'T'));
                            FromDate := DMY2Date(1, (NumPeriod * 3) - 2, NumFiscalYear);
                            ToDate := CalcDate(EndDateFormula, FromDate);
                        end;
                    Period = Period::"0A":
                        begin
                            Evaluate(StartDateFormula, '<-CY>');
                            Evaluate(EndDateFormula, '<CY>');
                            FromDate := DMY2Date(1, 1, NumFiscalYear);
                            ToDate := CalcDate(EndDateFormula, FromDate);
                        end;
                    else
                        Error(Text1100000);
                end;
            end;
        }
        dataitem(CustomerWarnings; Customer)
        {
            DataItemTableView = sorting("VAT Registration No.");
            PrintOnlyIfDetail = false;

            trigger OnAfterGetRecord()
            begin
                while ("VAT Registration No." = PreVATRegNo) or ("VAT Registration No." = '') do
                    if Next() = 0 then
                        exit;
                PreVATRegNo := "VAT Registration No.";

                Customer2.Reset();
                Customer2.SetRange("VAT Registration No.", "VAT Registration No.");
                if Customer2.FindSet() then begin
                    repeat
                        VATCredSales.Reset();
                        VATCredSales.SetRange(Type, VATCredSales.Type::Sale);
                        VATCredSales.SetRange("Document Type", VATCredSales."Document Type"::"Credit Memo");
                        VATCredSales.SetRange("Bill-to/Pay-to No.", Customer2."No.");
                        VATCredSales.SetRange("VAT Reporting Date", FromDate, ToDate);
                        VATCredSales.SetFilter("Gen. Prod. Posting Group", FilterString);
                        if VATCredSales.FindSet() then
                            repeat
                                if IncludeIn349(VATCredSales, AmountToIncludein349, LocationDiffCountryCode) then
                                    if (VATCredSales."Country/Region Code" <> CountryCode) or
                                       ((VATCredSales."Country/Region Code" = CountryCode) and LocationDiffCountryCode) and
                                       (VATCredSales."Country/Region Code" <> CompanyInfo."Country/Region Code")
                                    then
                                        InsertCustWarning349(
                                          Customer2."No.", Customer2.Name, VATCredSales."VAT Reporting Date",
                                          VATCredSales."Document Type", VATCredSales."Document No.",
                                          VATCredSales."EU 3-Party Trade", VATCredSales."EU Service", VATCredSales.Base >= 0,
                                          VATCredSales."Entry No.", 0, VATCredSales."Delivery Operation Code", VATCredSales."Posting Date");
                            until VATCredSales.Next() = 0;

                        InsertCustWarningsFromSalesCrMemoLine();
                    until Customer2.Next() = 0;

                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            begin
                PreVATRegNo := '';
            end;
        }
        dataitem(VendorWarnings; Vendor)
        {
            DataItemTableView = sorting("VAT Registration No.");
            PrintOnlyIfDetail = false;

            trigger OnAfterGetRecord()
            begin
                while ("VAT Registration No." = PreVATRegNo) or ("VAT Registration No." = '') do
                    if Next() = 0 then
                        exit;
                PreVATRegNo := "VAT Registration No.";

                Vendor2.Reset();
                Vendor2.SetRange("VAT Registration No.", "VAT Registration No.");
                if Vendor2.FindSet() then begin
                    repeat
                        VATCredPurch.Reset();
                        VATCredPurch.SetRange(Type, VATCredPurch.Type::Purchase);
                        VATCredPurch.SetRange("Document Type", VATCredPurch."Document Type"::"Credit Memo");
                        VATCredPurch.SetRange("Bill-to/Pay-to No.", Vendor2."No.");
                        VATCredPurch.SetRange("VAT Reporting Date", FromDate, ToDate);
                        VATCredPurch.SetFilter("Gen. Prod. Posting Group", FilterString);
                        if VATCredPurch.FindSet() then
                            repeat
                                if IncludeIn349(VATCredPurch, AmountToIncludein349, LocationDiffCountryCode) then
                                    if (VATCredPurch."Country/Region Code" <> CountryCode) or
                                       ((VATCredPurch."Country/Region Code" = CountryCode) and LocationDiffCountryCode) and
                                       (VATCredPurch."Country/Region Code" <> CompanyInfo."Country/Region Code")
                                    then
                                        InsertVendWarning349(
                                          Vendor2."No.", Vendor2.Name, VATCredPurch."VAT Reporting Date",
                                          VATCredPurch."Document Type", VATCredPurch."Document No.",
                                          VATCredPurch."EU 3-Party Trade", VATCredPurch."EU Service", VATCredPurch.Base >= 0, VATCredPurch."Entry No.", 0, VATCredPurch."Posting Date");
                            until VATCredPurch.Next() = 0;

                        InsertVendWarningsFromPurchCrMemoLine();
                    until Vendor2.Next() = 0;

                    Commit();
                end;
            end;

            trigger OnPostDataItem()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnVendorWarningsOnBeforeOnPostDataItem(CustVendWarning349, IsHandled);
                if IsHandled then
                    exit;

                if CustVendWarning349.FindFirst() then
                    if not Confirm(Text1100008, false) then
                        Message(Text1100009)
                    else begin
                        CVWarning349.SetRecord(CustVendWarning349);
                        CVWarning349.SetExcludeGenProductPostingGroupFilter(FilterString);
                        if (CVWarning349.RunModal() in [ACTION::Cancel, ACTION::OK]) and CVWarning349.Cancelled() then begin
                            CustVendWarning349.Reset();
                            CustVendWarning349.DeleteAll();
                            Commit();
                            Error(Text1100011);
                        end;
                    end;
            end;

            trigger OnPreDataItem()
            begin
                PreVATRegNo := '';
            end;
        }
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = sorting("EU Country/Region Code");
            dataitem(Customer; Customer)
            {
                DataItemLink = "Country/Region Code" = field(Code);
                DataItemTableView = sorting("VAT Registration No.");
                PrintOnlyIfDetail = false;

                trigger OnAfterGetRecord()
                var
                    VATEntry: Record "VAT Entry";
                    Amount: array[3] of Decimal;
                    AccPrevDeclAmount: array[3] of Decimal;
                    AccOrigDeclAmount: array[3] of Decimal;
                    i: Integer;
                    NoTaxableNormalAmountSales: array[3] of Decimal;
                    CorrectedInvPostingDate: Date;
                begin
                    while (Customer."VAT Registration No." = PreVATRegNo) or (Customer."VAT Registration No." = '') do
                        if Customer.Next() = 0 then
                            exit;
                    PreVATRegNo := Customer."VAT Registration No.";

                    CustVendCountry.Get("Country/Region Code");
                    CustVendVatRegNo := CombineEUCountryAndVATRegNo(CustVendCountry, "VAT Registration No.");
                    AmountOpTri := 0;
                    NormalAmount := 0;
                    Clear(Amount);
                    Clear(AccPrevDeclAmount);
                    Clear(AccOrigDeclAmount);
                    AccumPrevDeclAmount := 0;
                    AccumOrigDeclAmount := 0;
                    AmountEUService := 0;
                    AccumPrevDeclAmountEUService := 0;
                    AccumOrigDeclAmountEUService := 0;
                    AccumPrevDeclAmountTri := 0;
                    AccumOrigDeclAmountTri := 0;
                    Customer2.Reset();
                    Customer2.SetRange("VAT Registration No.", "VAT Registration No.");
                    if Customer2.FindSet() then begin
                        repeat
                            FilterVATInvSalesEntries(VATInvSales, Customer2."No.", FromDate, ToDate, false, FilterString);
                            VATInvSales.SetRange("EU 3-Party Trade", true);
                            if VATInvSales.FindSet() then
                                repeat
                                    if IncludeIn349(VATInvSales, AmountToIncludein349, LocationDiffCountryCode) then
                                        if (VATInvSales."Country/Region Code" <> CountryCode) or
                                           ((VATInvSales."Country/Region Code" = CountryCode) and LocationDiffCountryCode)
                                        then
                                            if "VAT Registration No." <> '' then begin
                                                if AmountToIncludein349 <> 0 then
                                                    AmountOpTri += AmountToIncludein349
                                                else
                                                    AmountOpTri += VATInvSales.Base;
                                            end else
                                                EmptyVATRegNo := true;
                                until VATInvSales.Next() = 0;

                            FilterVATInvSalesEntries(VATInvSales, Customer2."No.", FromDate, ToDate, false, FilterString);
                            VATInvSales.SetRange("EU 3-Party Trade", false);
                            if VATInvSales.FindSet() then
                                repeat
                                    if IncludeIn349(VATInvSales, AmountToIncludein349, LocationDiffCountryCode) then
                                        if (VATInvSales."Country/Region Code" <> CountryCode) or
                                           ((VATInvSales."Country/Region Code" = CountryCode) and LocationDiffCountryCode)
                                        then
                                            if "VAT Registration No." <> '' then
                                                SummarizeBaseAmount(VATInvSales, AmountToIncludein349, Amount)
                                            else
                                                EmptyVATRegNo := true;
                                until VATInvSales.Next() = 0;

                            FilterVATInvSalesEntries(VATInvSales, Customer2."No.", FromDate, ToDate, true, FilterString);
                            if VATInvSales.FindSet() then
                                repeat
                                    if IncludeIn349(VATInvSales, AmountToIncludein349, LocationDiffCountryCode) then
                                        if (VATInvSales."Country/Region Code" <> CountryCode) or
                                           ((VATInvSales."Country/Region Code" = CountryCode) and LocationDiffCountryCode)
                                        then
                                            if "VAT Registration No." <> '' then begin
                                                if AmountToIncludein349 <> 0 then
                                                    AmountEUService += AmountToIncludein349
                                                else
                                                    AmountEUService += VATInvSales.Base + VATInvSales."Non-Deductible VAT Base";
                                            end else
                                                EmptyVATRegNo := true;
                                until VATInvSales.Next() = 0;

                            NoTaxableAmountOpTri := 0;
                            NoTaxableAmountEUService := 0;
                            Clear(NoTaxableNormalAmountSales);
                            CalcNoTaxableAmountCustomer(NoTaxableNormalAmountSales);

                            for i := 1 to 3 do
                                Amount[i] += NoTaxableNormalAmountSales[i];
                            AmountEUService += NoTaxableAmountEUService;
                            AmountOpTri += NoTaxableAmountOpTri;

                            CorrIncludedForOpTriAmount := false;

                            CustVendWarning349.Reset();
                            CustVendWarning349.SetRange(Type, CustVendWarning349.Type::Sale);
                            CustVendWarning349.SetRange("Customer/Vendor No.", Customer2."No.");
                            CustVendWarning349.SetRange("VAT Reporting Date", FromDate, ToDate);
                            CustVendWarning349.SetRange("Include Correction", true);
                            if CustVendWarning349.FindSet() then
                                repeat
                                    CorrectedInvPostingDate := GetCorrectedInvoicePostingDate(CustVendWarning349);
                                    if IsCorrectiveCrMemo(CustVendWarning349) and
                                       ((CorrectedInvPostingDate >= FromDate) and (CorrectedInvPostingDate <= ToDate))
                                    then begin
                                        // Credit Memo corrects Invoice from the same period
                                        if "VAT Registration No." <> '' then
                                            if CustVendWarning349."EU Service" then
                                                CorrectAmountEU()
                                            else
                                                if CustVendWarning349."EU 3-Party Trade" then begin
                                                    AmountOpTri += CustVendWarning349."Original Declared Amount";
                                                    CorrIncludedForOpTriAmount := true;
                                                end else begin
                                                    InitVATEntry(VATEntry, CustVendWarning349."VAT Entry No.");
                                                    SummarizeBaseAmount(VATEntry, -CustVendWarning349."Original Declared Amount", Amount);
                                                end;
                                    end else begin
                                        // Credit Memo corrects Invoice from previous period OR Credit Memo does not correct any Invoice OR \
                                        // (Credit Memo corrects Invoice from previous period AND Original Declaration Period was not changed on Customer/Vendor Warnings 349)
                                        TotalCorreAmt += CustVendWarning349."Original Declared Amount";
                                        NoOfCorrections += 1;

                                        AccumPrevDeclAmount := 0;
                                        AccumOrigDeclAmount := 0;
                                        AccumPrevDeclAmountEUService := 0;
                                        AccumOrigDeclAmountEUService := 0;
                                        AccumPrevDeclAmountTri := 0;
                                        AccumOrigDeclAmountTri := 0;
                                        Clear(AccPrevDeclAmount);
                                        Clear(AccOrigDeclAmount);

                                        CustVendWarning349_2 := CustVendWarning349;
                                        FilterCustVendWarnings(CustVendWarning349_2, CustVendWarning349, false, false);
                                        CustVendWarning349_2.SetRange("EU 3-Party Trade", false);
                                        AlreadyExported := false;

                                        if CustVendWarning349_2.FindSet() then begin
                                            if "VAT Registration No." <> '' then begin
                                                InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                if CustVendWarning349_2."Previous Declared Amount" <> 0 then    // if decalaration period was updated, then count Previous Declared Amount only once
                                                    AccPrevDeclAmount[MapDeliveryOperationCode(VATEntry."Delivery Operation Code")] := Abs(CustVendWarning349_2."Previous Declared Amount");
                                                repeat
                                                    InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                    if CustVendWarning349_2."Previous Declared Amount" = 0 then
                                                        AccPrevDeclAmount[MapDeliveryOperationCode(VATEntry."Delivery Operation Code")] += Abs(VATEntry.Base);
                                                    AccOrigDeclAmount[MapDeliveryOperationCode(VATEntry."Delivery Operation Code")] +=
                                                      CustVendWarning349_2."Original Declared Amount";
                                                    CustVendWarning349_2.Exported := true;
                                                    CustVendWarning349_2.Modify();
                                                until CustVendWarning349_2.Next() = 0;
                                            end;
                                        end else
                                            AlreadyExported := true;

                                        ThirdPartyAlreadyExported := false;
                                        EUServiceAlreadyExported := false;

                                        // EU Service
                                        CustVendWarning349_2.Reset();
                                        FilterCustVendWarnings(CustVendWarning349_2, CustVendWarning349, false, true);
                                        if CustVendWarning349_2.FindSet() then begin
                                            if "VAT Registration No." <> '' then begin
                                                if CustVendWarning349_2."Previous Declared Amount" <> 0 then    // if decalaration period was updated, then count Previous Declared Amount only once
                                                    AccumPrevDeclAmountEUService := Abs(CustVendWarning349_2."Previous Declared Amount");
                                                repeat
                                                    InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                    if CustVendWarning349_2."Previous Declared Amount" = 0 then
                                                        AccumPrevDeclAmountEUService += Abs(VATEntry.Base);
                                                    AccumOrigDeclAmountEUService += CustVendWarning349_2."Original Declared Amount";
                                                    CustVendWarning349_2.Exported := true;
                                                    CustVendWarning349_2.Modify();
                                                until CustVendWarning349_2.Next() = 0;
                                            end;
                                        end else
                                            EUServiceAlreadyExported := true;

                                        // EU 3-party trade
                                        CustVendWarning349_2.Reset();
                                        FilterCustVendWarnings(CustVendWarning349_2, CustVendWarning349, false, false);
                                        CustVendWarning349_2.SetRange("EU 3-Party Trade", true);
                                        if CustVendWarning349_2.FindSet() then begin
                                            if "VAT Registration No." <> '' then begin
                                                if CustVendWarning349_2."Previous Declared Amount" <> 0 then    // if decalaration period was updated, then count Previous Declared Amount only once
                                                    AccumPrevDeclAmountTri := Abs(CustVendWarning349_2."Previous Declared Amount");
                                                repeat
                                                    InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                    if CustVendWarning349_2."Previous Declared Amount" = 0 then
                                                        AccumPrevDeclAmountTri += Abs(VATEntry.Base);
                                                    AccumOrigDeclAmountTri += CustVendWarning349_2."Original Declared Amount";
                                                    CustVendWarning349_2.Exported := true;
                                                    CustVendWarning349_2.Modify();
                                                until CustVendWarning349_2.Next() = 0;
                                            end;
                                        end else
                                            ThirdPartyAlreadyExported := true;

                                        Sign := CustVendWarning349.Sign;

                                        if not (AlreadyExported and EUServiceAlreadyExported and ThirdPartyAlreadyExported) then
                                            if "VAT Registration No." <> '' then begin
                                                if CustVendWarning349."EU Service" then begin
                                                    TextAmount := CopyStr(FormatTextAmt(AccumOrigDeclAmountEUService), 3, 13);
                                                    TextAmount2 := CopyStr(FormatTextAmt(AccumPrevDeclAmountEUService), 3, 13);
                                                    Txt :=
                                                      '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                                        CustVendVatRegNo + PadStr(GetCustomerNameUpperNormalized(), 40, ' ') +
                                                        'S' + PadStr('', 13, ' ') +
                                                        CustVendWarning349."Original Declaration FY" + CustVendWarning349."Original Declaration Period" +
                                                        TextAmount + TextAmount2 + PadStr('', 322, ' ');
                                                    AppendLine(Txt);
                                                end else
                                                    if CustVendWarning349."EU 3-Party Trade" then begin
                                                        TextAmount := CopyStr(FormatTextAmt(AccumOrigDeclAmountTri), 3, 13);
                                                        TextAmount2 := CopyStr(FormatTextAmt(AccumPrevDeclAmountTri), 3, 13);
                                                        Txt :=
                                                          '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                                            CustVendVatRegNo + PadStr(GetCustomerNameUpperNormalized(), 40, ' ') +
                                                            'T' + PadStr('', 13, ' ') +
                                                            CustVendWarning349."Original Declaration FY" + CustVendWarning349."Original Declaration Period" +
                                                            TextAmount + TextAmount2 + PadStr('', 322, ' ');
                                                        AppendLine(Txt);
                                                    end else
                                                        for i := 1 to 3 do      // E, M, H types
                                                            if (AccPrevDeclAmount[i] <> 0) or (AccOrigDeclAmount[i] <> 0) then begin
                                                                TextAmount := CopyStr(FormatTextAmt(AccOrigDeclAmount[i]), 3, 13);
                                                                TextAmount2 := CopyStr(FormatTextAmt(AccPrevDeclAmount[i]), 3, 13);
                                                                Txt :=
                                                                  '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                                                    CustVendVatRegNo + PadStr(GetCustomerNameUpperNormalized(), 40, ' ') +
                                                                    OperationCode[i] + PadStr('', 13, ' ') +
                                                                    CustVendWarning349."Original Declaration FY" + CustVendWarning349."Original Declaration Period" +
                                                                    TextAmount + TextAmount2 + PadStr('', 322, ' ');
                                                                AppendLine(Txt);
                                                            end;
                                            end else
                                                EmptyVATRegNo := true;
                                    end;
                                until CustVendWarning349.Next() = 0;
                        until Customer2.Next() = 0;

                        if "VAT Registration No." <> '' then begin
                            for i := 1 to 3 do begin
                                Amount[i] := Abs(Amount[i]);
                                if Amount[i] <> 0 then begin
                                    TextAmount := CopyStr(FormatTextAmt(Amount[i]), 3, 13);
                                    Txt :=
                                      '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                      CustVendVatRegNo +
                                      PadStr(GetCustomerNameUpperNormalized(), 40, ' ') +
                                      OperationCode[i] + ConvertStr(TextAmount, ' ', '0') + PadStr('', 354, ' ');
                                    NoOperations += 1;
                                    TotalAmtShip += Amount[i];
                                    AppendLine(Txt);
                                end;
                            end;

                            AmountOpTri := Abs(AmountOpTri);
                            if CorrIncludedForOpTriAmount or (AmountOpTri <> 0) then begin
                                TextAmount := CopyStr(FormatTextAmt(AmountOpTri), 3, 13);
                                Txt :=
                                  '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                  CustVendVatRegNo +
                                  PadStr(GetCustomerNameUpperNormalized(), 40, ' ') +
                                  'T' + ConvertStr(TextAmount, ' ', '0') + PadStr('', 354, ' ');
                                NoOperations += 1;
                                TotalAmtShip += AmountOpTri;
                                AppendLine(Txt);
                            end;

                            AmountEUService := Abs(AmountEUService);
                            if AmountEUService <> 0 then begin
                                TextAmount := CopyStr(FormatTextAmt(AmountEUService), 3, 13);
                                Txt :=
                                  '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                  CustVendVatRegNo +
                                  PadStr(GetCustomerNameUpperNormalized(), 40, ' ') +
                                  'S' + ConvertStr(TextAmount, ' ', '0') + PadStr('', 354, ' ');
                                NoOperations += 1;
                                TotalAmtShip += AmountEUService;
                                AppendLine(Txt);
                            end;
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    PreVATRegNo := '';
                end;
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "Country/Region Code" = field(Code);
                DataItemTableView = sorting("VAT Registration No.");
                PrintOnlyIfDetail = false;

                trigger OnAfterGetRecord()
                var
                    VATEntry: Record "VAT Entry";
                    CorrectedInvPostingDate: Date;
                begin
                    while (Vendor."VAT Registration No." = PreVATRegNo) or (Vendor."VAT Registration No." = '') do
                        if Vendor.Next() = 0 then
                            exit;
                    PreVATRegNo := Vendor."VAT Registration No.";

                    CustVendCountry.Get("Country/Region Code");
                    CustVendVatRegNo := CombineEUCountryAndVATRegNo(CustVendCountry, "VAT Registration No.");
                    AmountOpTri := 0;
                    NormalAmount := 0;
                    AccumPrevDeclAmount := 0;
                    AccumOrigDeclAmount := 0;
                    AmountEUService := 0;
                    AccumPrevDeclAmountEUService := 0;
                    AccumOrigDeclAmountEUService := 0;
                    AccumPrevDeclAmountTri := 0;
                    AccumOrigDeclAmountTri := 0;
                    NoTaxableAmountEUService := 0;

                    Vendor2.Reset();
                    Vendor2.SetRange("VAT Registration No.", "VAT Registration No.");
                    if Vendor2.FindSet() then begin
                        repeat
                            FilterVATInvPurchEntries(VATInvPurch, Vendor2."No.", FromDate, ToDate, false, FilterString);
                            VATInvPurch.SetRange("EU 3-Party Trade", true);
                            if VATInvPurch.FindSet() then
                                repeat
                                    if IncludeIn349(VATInvPurch, AmountToIncludein349, LocationDiffCountryCode) then
                                        if (VATInvPurch."Country/Region Code" <> CountryCode) or
                                           ((VATInvPurch."Country/Region Code" = CountryCode) and LocationDiffCountryCode)
                                        then
                                            if "VAT Registration No." <> '' then begin
                                                if AmountToIncludein349 <> 0 then
                                                    AmountOpTri += AmountToIncludein349
                                                else
                                                    AmountOpTri += VATInvPurch.Base;
                                            end else
                                                EmptyVATRegNo := true;
                                until VATInvPurch.Next() = 0;

                            FilterVATInvPurchEntries(VATInvPurch, Vendor2."No.", FromDate, ToDate, false, FilterString);
                            VATInvPurch.SetRange("EU 3-Party Trade", false);
                            if VATInvPurch.FindSet() then
                                repeat
                                    if IncludeIn349(VATInvPurch, AmountToIncludein349, LocationDiffCountryCode) then
                                        if (VATInvPurch."Country/Region Code" <> CountryCode) or
                                           ((VATInvPurch."Country/Region Code" = CountryCode) and LocationDiffCountryCode)
                                        then
                                            if "VAT Registration No." <> '' then begin
                                                if (AmountToIncludein349 <> 0) and ("Currency Code" = '') then
                                                    NormalAmount += AmountToIncludein349
                                                else
                                                    NormalAmount += VATInvPurch.Base;
                                            end else
                                                EmptyVATRegNo := true;
                                until VATInvPurch.Next() = 0;

                            FilterVATInvPurchEntries(VATInvPurch, Vendor2."No.", FromDate, ToDate, true, FilterString);
                            if VATInvPurch.FindSet() then
                                repeat
                                    if IncludeIn349(VATInvPurch, AmountToIncludein349, LocationDiffCountryCode) then
                                        if (VATInvPurch."Country/Region Code" <> CountryCode) or
                                           ((VATInvPurch."Country/Region Code" = CountryCode) and LocationDiffCountryCode)
                                        then
                                            if "VAT Registration No." <> '' then begin
                                                if (AmountToIncludein349 <> 0) and ("Currency Code" = '') then
                                                    AmountEUService += AmountToIncludein349
                                                else
                                                    AmountEUService += VATInvPurch.Base + VATInvPurch."Non-Deductible VAT Base";
                                            end else
                                                EmptyVATRegNo := true;
                                until VATInvPurch.Next() = 0;

                            CalcNoTaxableAmountVendor(NormalAmount, AmountEUService, Vendor2."No.", FromDate, ToDate, FilterString);

                            CorrIncludedForOpTriAmount := false;

                            CustVendWarning349.Reset();
                            CustVendWarning349.SetRange(Type, CustVendWarning349.Type::Purchase);
                            CustVendWarning349.SetRange("Customer/Vendor No.", Vendor2."No.");
                            CustVendWarning349.SetRange("VAT Reporting Date", FromDate, ToDate);
                            CustVendWarning349.SetRange("Include Correction", true);
                            if CustVendWarning349.FindSet() then
                                repeat
                                    CorrectedInvPostingDate := GetCorrectedInvoicePostingDate(CustVendWarning349);
                                    if IsCorrectiveCrMemo(CustVendWarning349) and
                                    ((CorrectedInvPostingDate >= FromDate) and (CorrectedInvPostingDate <= ToDate))
                                    then begin
                                        // Credit Memo corrects Invoice from the same period
                                        if "VAT Registration No." <> '' then
                                            if CustVendWarning349."EU Service" then
                                                CorrectAmountEU()
                                            else
                                                if CustVendWarning349."EU 3-Party Trade" then begin
                                                    AmountOpTri -= CustVendWarning349."Original Declared Amount";
                                                    CorrIncludedForOpTriAmount := true;
                                                end else
                                                    CorrectAmountPurchNoEU();
                                    end else begin
                                        // Credit Memo corrects Invoice from previous period OR Credit Memo does not correct any Invoice OR \
                                        // (Credit Memo corrects Invoice from previous period AND Original Declaration Period was not changed on Customer/Vendor Warnings 349)
                                        TotalCorreAmt += CustVendWarning349."Original Declared Amount";
                                        NoOfCorrections += 1;
                                        AccumPrevDeclAmount := 0;
                                        AccumOrigDeclAmount := 0;
                                        AccumPrevDeclAmountEUService := 0;
                                        AccumOrigDeclAmountEUService := 0;
                                        AccumPrevDeclAmountTri := 0;
                                        AccumOrigDeclAmountTri := 0;

                                        CustVendWarning349_2 := CustVendWarning349;
                                        FilterCustVendWarnings(CustVendWarning349_2, CustVendWarning349, false, false);
                                        CustVendWarning349_2.SetRange("EU 3-Party Trade", false);
                                        AlreadyExported := false;

                                        if CustVendWarning349_2.FindSet() then begin
                                            if "VAT Registration No." <> '' then begin
                                                if CustVendWarning349_2."Previous Declared Amount" <> 0 then    // if decalaration period was updated, then count Previous Declared Amount only once
                                                    AccumPrevDeclAmount := Abs(CustVendWarning349_2."Previous Declared Amount");
                                                repeat
                                                    InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                    if CustVendWarning349_2."Previous Declared Amount" = 0 then
                                                        AccumPrevDeclAmount += Abs(VATEntry.Base);
                                                    AccumOrigDeclAmount += CustVendWarning349_2."Original Declared Amount";
                                                    CustVendWarning349_2.Exported := true;
                                                    CustVendWarning349_2.Modify();
                                                until CustVendWarning349_2.Next() = 0;
                                            end;
                                        end else
                                            AlreadyExported := true;

                                        ThirdPartyAlreadyExported := false;
                                        EUServiceAlreadyExported := false;

                                        // EU Service
                                        CustVendWarning349_2.Reset();
                                        FilterCustVendWarnings(CustVendWarning349_2, CustVendWarning349, false, true);
                                        if CustVendWarning349_2.FindSet() then begin
                                            if "VAT Registration No." <> '' then begin
                                                if CustVendWarning349_2."Previous Declared Amount" <> 0 then    // if decalaration period was updated, then count Previous Declared Amount only once
                                                    AccumPrevDeclAmountEUService := Abs(CustVendWarning349_2."Previous Declared Amount");
                                                repeat
                                                    InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                    if CustVendWarning349_2."Previous Declared Amount" = 0 then
                                                        AccumPrevDeclAmountEUService += Abs(VATEntry.Base);
                                                    AccumOrigDeclAmountEUService += CustVendWarning349_2."Original Declared Amount";
                                                    CustVendWarning349_2.Exported := true;
                                                    CustVendWarning349_2.Modify();
                                                until CustVendWarning349_2.Next() = 0;
                                            end;
                                        end else
                                            EUServiceAlreadyExported := true;

                                        // EU 3-party trade
                                        CustVendWarning349_2.Reset();
                                        FilterCustVendWarnings(CustVendWarning349_2, CustVendWarning349, false, false);
                                        CustVendWarning349_2.SetRange("EU 3-Party Trade", true);
                                        if CustVendWarning349_2.FindSet() then begin
                                            if "VAT Registration No." <> '' then begin
                                                if CustVendWarning349_2."Previous Declared Amount" <> 0 then    // if decalaration period was updated, then count Previous Declared Amount only once
                                                    AccumPrevDeclAmountTri := Abs(CustVendWarning349_2."Previous Declared Amount");
                                                repeat
                                                    InitVATEntry(VATEntry, CustVendWarning349_2."VAT Entry No.");
                                                    if CustVendWarning349_2."Previous Declared Amount" = 0 then
                                                        AccumPrevDeclAmountTri += Abs(VATEntry.Base);
                                                    AccumOrigDeclAmountTri += CustVendWarning349_2."Original Declared Amount";
                                                    CustVendWarning349_2.Exported := true;
                                                    CustVendWarning349_2.Modify();
                                                until CustVendWarning349_2.Next() = 0;
                                            end;
                                        end else
                                            ThirdPartyAlreadyExported := true;

                                        Sign := CustVendWarning349.Sign;

                                        if not (AlreadyExported and EUServiceAlreadyExported and ThirdPartyAlreadyExported) then begin
                                            if "VAT Registration No." <> '' then
                                                if CustVendWarning349."EU Service" then begin
                                                    TextAmount := CopyStr(FormatTextAmt(AccumOrigDeclAmountEUService), 3, 13);
                                                    TextAmount2 := CopyStr(FormatTextAmt(AccumPrevDeclAmountEUService), 3, 13);
                                                    Txt :=
                                                      '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                                        CustVendVatRegNo + PadStr(GetVendorNameUpperNormalized(), 40, ' ') +
                                                        'I' + PadStr('', 13, ' ') +
                                                        CustVendWarning349."Original Declaration FY" + CustVendWarning349."Original Declaration Period" +
                                                        TextAmount + TextAmount2 + PadStr('', 322, ' ');
                                                    AppendLine(Txt);
                                                end else
                                                    if CustVendWarning349."EU 3-Party Trade" then begin
                                                        TextAmount := CopyStr(FormatTextAmt(AccumOrigDeclAmountTri), 3, 13);
                                                        TextAmount2 := CopyStr(FormatTextAmt(AccumPrevDeclAmountTri), 3, 13);
                                                        Txt :=
                                                          '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                                            CustVendVatRegNo + PadStr(GetVendorNameUpperNormalized(), 40, ' ') +
                                                            'T' + PadStr('', 13, ' ') +
                                                            CustVendWarning349."Original Declaration FY" + CustVendWarning349."Original Declaration Period" +
                                                            TextAmount + TextAmount2 + PadStr('', 322, ' ');
                                                        AppendLine(Txt);
                                                    end else begin
                                                        TextAmount := CopyStr(FormatTextAmt(AccumOrigDeclAmount), 3, 13);
                                                        TextAmount2 := CopyStr(FormatTextAmt(AccumPrevDeclAmount), 3, 13);
                                                        Txt :=
                                                          '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                                            CustVendVatRegNo + PadStr(GetVendorNameUpperNormalized(), 40, ' ') +
                                                            'A' + PadStr('', 13, ' ') +
                                                            CustVendWarning349."Original Declaration FY" + CustVendWarning349."Original Declaration Period" +
                                                            TextAmount + TextAmount2 + PadStr('', 322, ' ');
                                                        AppendLine(Txt);
                                                    end;
                                        end else
                                            EmptyVATRegNo := true;
                                    end;
                                until CustVendWarning349.Next() = 0;
                        until Vendor2.Next() = 0;

                        if "VAT Registration No." <> '' then begin
                            NormalAmount := Abs(NormalAmount);
                            if NormalAmount <> 0 then begin
                                TextAmount := CopyStr(FormatTextAmt(NormalAmount), 3, 13);
                                Txt :=
                                  '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                  CustVendVatRegNo +
                                  PadStr(GetVendorNameUpperNormalized(), 40, ' ') +
                                  'A' + ConvertStr(TextAmount, ' ', '0') + PadStr('', 354, ' ');
                                NoOperations += 1;
                                TotalAmtReciv += NormalAmount;
                                AppendLine(Txt);
                            end;

                            AmountOpTri := Abs(AmountOpTri);
                            if CorrIncludedForOpTriAmount or (AmountOpTri <> 0) then begin
                                TextAmount := CopyStr(FormatTextAmt(AmountOpTri), 3, 13);
                                Txt :=
                                  '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                                  CustVendVatRegNo +
                                  PadStr(GetVendorNameUpperNormalized(), 40, ' ') +
                                  'T' + ConvertStr(TextAmount, ' ', '0') + PadStr('', 354, ' ');
                                NoOperations += 1;
                                TotalAmtReciv += AmountOpTri;
                                AppendLine(Txt);
                            end;
                        end;

                        AmountEUService := Abs(AmountEUService);
                        if AmountEUService <> 0 then begin
                            TextAmount := CopyStr(FormatTextAmt(AmountEUService), 3, 13);
                            Txt :=
                              '2' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') + PadStr('', 58, ' ') +
                              CustVendVatRegNo +
                              PadStr(GetVendorNameUpperNormalized(), 40, ' ') +
                              'I' + ConvertStr(TextAmount, ' ', '0') + PadStr('', 354, ' ');
                            NoOperations += 1;
                            TotalAmtReciv += AmountEUService;
                            AppendLine(Txt);
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    PreVATRegNo := '';
                end;
            }
        }
        dataitem(Integer4; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnPreDataItem()
            begin
                if EmptyVATRegNo then
                    if not Confirm(StrSubstNo(Text1100015, Customer.TableCaption(), Vendor.TableCaption(),
                           Customer.FieldCaption("VAT Registration No.")), false)
                    then begin
                        CustVendWarning349.Reset();
                        CustVendWarning349.DeleteAll();
                        Commit();
                        OutFile.Close();
                        Erase(FileName);
                        Error(Text1100011);
                    end;
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
                    group("Operations EU")
                    {
                        Caption = 'Operations EU';
                        field(FiscalYear; FiscalYear)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Fiscal Year';
                            Numeric = true;
                            ToolTip = 'Specifies the year of the reporting period. It must be 4 digits without spaces or special characters.';
                        }
                        field(Period; Period)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Period';
                            OptionCaption = 'Annual,January,February,March,April,May,June,July,August,September,October,November,December,1st Quarter,2nd Quarter,3rd Quarter,4th Quarter';
                            ToolTip = 'Specifies the period that the report covers, such as a year, a month, or a quarter.';

                            trigger OnValidate()
                            begin
                                PeriodFreqChange := false;
                                UpdateRequestForm();
                            end;
                        }
                        field(PeriodFrequencyChange; PeriodFreqChange)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Period Frequency Change';
                            Enabled = PeriodFrequencyChangeEnable;
                            ToolTip = 'Specifies the period frequency of the report.';
                        }
                        field(ContactName; ContactName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact Name';
                            ToolTip = 'Specifies the name of the person making the declaration.';
                        }
                        field(TelephoneNumber; ContactTelephone)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Telephone Number';
                            Numeric = true;
                            ToolTip = 'Specifies the telephone number of the contact person.';

                            trigger OnValidate()
                            begin
                                if StrLen(ContactTelephone) < 9 then
                                    Error(Text1100012);
                            end;
                        }
                        field(DeclarationNumber; DeclarationNum)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Declaration Number';
                            Numeric = true;
                            ToolTip = 'Specifies a number to identify the operations declaration.';

                            trigger OnValidate()
                            begin
                                if StrLen(DeclarationNum) <> 13 then
                                    Error(Text1100007);
                            end;
                        }
                        field(CompanyCountryRegion; CountryCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Company Country/Region';
                            TableRelation = "Country/Region";
                            ToolTip = 'Specifies the country/region for your company.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                if PAGE.RunModal(10, "Country/Region") = ACTION::LookupOK then
                                    CountryCode := "Country/Region".Code;
                            end;
                        }
                        field(DeclarationMediaType; DeclarationMediaType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Declaration Media Type';
                            OptionCaption = 'Physical support,Telematic';
                            ToolTip = 'Specifies the media type for the declaration. To submit the declaration electronically, select Telematic. To submit the declaration on a CD-ROM, select Physical support.';
                        }
                        field(ColumnGPPG; ColumnGPPG)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Excluded Gen. Product Posting Groups';
                            Editable = false;
                            ToolTip = 'Specifies the general product posting group that you do not want to include in the declaration.';

                            trigger OnAssistEdit()
                            var
                                GPPGSelectionBuf: Record "Gen. Prod. Post. Group Buffer";
                            begin
                                GPPGSelectionBuf.SetGPPGSelectionMultiple(ColumnGPPG, FilterString);
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PeriodFrequencyChangeEnable := true;
            if FiscalYear = '' then
                FiscalYear := '0000';
            DeclarationNum := '3490000000000';
            CountryCode := '';
        end;

        trigger OnOpenPage()
        begin
            UpdateRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        VatRegNo := CopyStr(DelChr(CompanyInfo."VAT Registration No.", '=', '.-/'), 1, 9);
        NoOperations := 0;
        OperationCode[Idx::E] := 'E';
        OperationCode[Idx::M] := 'M';
        OperationCode[Idx::H] := 'H';

        OnAfterInitReport();
    end;

    trigger OnPostReport()
    var
        FileManagement: Codeunit "File Management";
        TextLine: Text;
    begin
        if TotalAmtShip < 0 then
            TotalAmtShip := -TotalAmtShip;
        TextOpAmount := FormatTextAmt(TotalAmtShip + TotalAmtReciv);
        TextCorreAmount := FormatTextAmt(TotalCorreAmt);

        case DeclarationMediaType of
            DeclarationMediaType::Telematic:
                DeclarationMT := 'T';
            DeclarationMediaType::"Physical support":
                DeclarationMT := ' ';
        end;
        if PeriodFreqChange then
            PeriodChangeText := 'X'
        else
            PeriodChangeText := ' ';
        if TextList.Count <> 0 then begin
            Txt :=
              '1' + '349' + FiscalYear + PadStr(VatRegNo, 9, ' ') +
              PadStr(UpperCase(CompanyInfo.Name), 40, ' ') + DeclarationMT +
              ConvertStr(Format(ContactTelephone, 9), ' ', '0') +
              PadStr(UpperCase(ContactName), 40, ' ') +
              DeclarationNum +
              '  ' + PadStr('', 13, '0') + GetPeriodAsText() +
              ConvertStr(Format(NoOperations, 9), ' ', '0') + ConvertStr(TextOpAmount, ' ', '0') +
              ConvertStr(Format(NoOfCorrections, 9), ' ', '0') + ConvertStr(TextCorreAmount, ' ', '0') +
              PeriodChangeText + PadStr('', 314, ' ');

            InsertLine(Txt);
            OutFile.Seek(0);
            foreach TextLine in TextList do begin
                Txt := CopyStr(TextLine, 1, MaxStrLen(Txt));
                OutFile.Write(Txt);
            end;
            OutFile.Close();
            ConvertFileEncoding(FileName, Utf8Lbl, Iso88591Lbl);
        end else begin
            OutFile.Close();
            Erase(FileName);
            Message(Text1100013);
        end;

        CustVendWarning349.Reset();
        CustVendWarning349.DeleteAll();

        ToFile := Text1100016 + '.txt';
        if ReportFileName <> '' then
            FileManagement.CopyServerFile(FileName, ReportFileName, true)
        else
            if not Download(FileName, Text1100006, '', Text1100017, ToFile) then
                exit;
        Message(Text1100010, ToFile);
        FeatureTelemetry.LogUsage('1000HV6', ESReport349Tok, 'ES 349 Reports Created');
    end;

    local procedure ConvertFileEncoding(FileName: Text; OldEncodingCode: Text; NewEncodingCode: Text)
    var
        DotNetEncoding: Codeunit DotNet_Encoding;
        DotNetStreamWriter: Codeunit DotNet_StreamWriter;
        FileManagement: Codeunit "File Management";
        OriginalEncoding: Dotnet Encoding;
        NewEncoding: DotNet Encoding;
        FileContents: Text;
    begin
        OriginalEncoding := OriginalEncoding.GetEncoding(OldEncodingCode);
        NewEncoding := NewEncoding.GetEncoding(NewEncodingCode);
        DotNetEncoding.SetEncoding(NewEncoding);
        FileContents := FileManagement.GetFileContents(FileName);
        if not Erase(FileName) then
            exit;
        OutFile.Create(FileName);
        OutFile.CreateOutStream(OutStr);

        DotNetStreamWriter.StreamWriter(OutStr, DotNetEncoding);
        DotNetStreamWriter.Write(
            NewEncoding.GetString(
                NewEncoding.Convert(OriginalEncoding, NewEncoding, OriginalEncoding.GetBytes(FileContents))));
        DotNetStreamWriter.Close();
        OutFile.Close();
    end;

    trigger OnPreReport()
    var
        RBMgt: Codeunit "File Management";
        TempString: Text[9];
        TempString1: Text[1];
    begin
        if FiscalYear = '' then
            Error(Text1100000);
        if ContactName = '' then
            Error(Text1100001);
        if ContactTelephone = '' then
            Error(Text1100002);
        TempString := ContactTelephone;
        if StrLen(TempString) > 0 then
            repeat
                TempString1 := CopyStr(TempString, 1, 1);
                if not (TempString1 in ['0' .. '9']) then
                    Error(Text1100012);
                TempString := DelStr(TempString, 1, 1);
            until StrLen(TempString) = 0;
        if DeclarationNum = '' then
            Error(Text1100003);
        if CountryCode = '' then
            Error(Text1100004);

        FileName := RBMgt.ServerTempFileName('txt');

        Clear(OutFile);
        OutFile.TextMode := true;
        OutFile.WriteMode := true;
        if OutFile.Open(FileName) then begin
            if not Confirm(Text1100014, false) then
                Error(Text1100011);

            OutFile.Create(FileName, TextEncoding::UTF8);
        end else
            OutFile.Create(FileName, TextEncoding::UTF8);
        OutFile.CreateOutStream(OutStr);
        if ColumnGPPG = '' then
            Message(Text1100005)
        else
            if FilterString = '' then
                GetFilterStringFromColumnGPPG();
        GetCompInfShipToCountryRegCode(CompInfShipToCountryRegCode);
        GetCompanyCountryRegCode(ReqFormCountryRegCode);
        CheckIfEULocations(AllLocationsAreEU);
        CVWarning349.Initialize(FiscalYear, GetPeriodAsText());
        EmptyVATRegNo := false;
    end;

    var
        Text1100000: Label 'Incorrect Fiscal Year.';
        Text1100001: Label 'Contact name must be entered.';
        Text1100002: Label 'Contact telephone must be entered.';
        Text1100003: Label 'Receipt number must be entered.';
        CompanyInfo: Record "Company Information";
        CustEntries: Record "Cust. Ledger Entry";
        CustEntries2: Record "Cust. Ledger Entry";
        CustVendCountry: Record "Country/Region";
        VATInvSales: Record "VAT Entry";
        VATCredSales: Record "VAT Entry";
        VATInvPurch: Record "VAT Entry";
        VATCredPurch: Record "VAT Entry";
        Customer2: Record Customer;
        Vendor2: Record Vendor;
        CustVendWarning349: Record "Customer/Vendor Warning 349";
        CustVendWarning349_2: Record "Customer/Vendor Warning 349";
        TempSalesInvLines: Record "Sales Invoice Line" temporary;
        TempPurchInvLines: Record "Purch. Inv. Line" temporary;
        NoTaxableMgt: Codeunit "No Taxable Mgt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESReport349Tok: Label 'ES Create Report 349', Locked = true;
        TextList: List of [Text];
        OutFile: File;
        CVWarning349: Page "Customer/Vendor Warnings 349";
        FiscalYear: Code[4];
        RectFiscalYear: Code[4];
        ContactTelephone: Code[9];
        CountryCode: Code[10];
        OperationCode: array[3] of Code[1];
        NormalAmount: Decimal;
        NoOfCorrections: Decimal;
        TotalAmtShip: Decimal;
        TotalAmtReciv: Decimal;
        AmountOpTri: Decimal;
        TotalCorreAmt: Decimal;
        AccumPrevDeclAmount: Decimal;
        AccumOrigDeclAmount: Decimal;
        AmountToIncludein349: Decimal;
        Txt: Text[501];
        VatRegNo: Text[9];
        FileName: Text;
        Sign: Text[1];
        CustVendVatRegNo: Text[20];
        ContactName: Text[40];
        TextAmount: Text[13];
        TextAmount2: Text[13];
        TextOpAmount: Text[15];
        TextCorreAmount: Text[15];
        DeclarationNum: Text[13];
        ColumnGPPG: Text[1024];
        FilterString: Text[1024];
        DeclarationMT: Text[1];
        PreVATRegNo: Text[20];
        ToFile: Text[1024];
        NumFiscalYear: Integer;
        NoOperations: Integer;
        Period: Option "0A","01","02","03","04","05","06","07","08","09","10","11","12","1T","2T","3T","4T";
        DeclarationMediaType: Option "Physical support",Telematic;
        FromDate: Date;
        ToDate: Date;
        Text1100004: Label 'Company Country/Region must be entered.';
        Text1100005: Label 'Please be aware that this file will contain posted entries of services transactions of EU Customers/Vendors if you did not fill \"Excluding Gen. Prod. Posting Groups" field.';
        Text1100006: Label 'Path to export 349 file.';
        Text1100007: Label 'Lenght should be 13 digits for Declaration Number.';
        Text1100008: Label 'One or more Credit Memos were found for the specified period. \You can select the ones that require a correction entry in current declaration and specify the correction amount for them. \Would you like to specify these corrections?';
        Text1100009: Label 'No correction will be included in this declaration.';
        Text1100010: Label '349 Declaration has been exported successfully under %1.';
        AlreadyExported: Boolean;
        Text1100011: Label 'The process has been aborted. No file will be generated.';
        CompInfShipToCountryRegCode: Boolean;
        ReqFormCountryRegCode: Boolean;
        AllLocationsAreEU: Boolean;
        Text1100012: Label 'Telephone Number must be 9 digits without spaces or special characters.';
        Text1100013: Label 'The report is empty. File generation has been cancelled.';
        Text1100014: Label 'The file already exists, do you want to replace it?';
        Text1100015: Label 'At least one %1/%2 does not have any value in the %3 field. \Only Customers/Vendors with a value for %3 will be included in the file. \Do you still want to create the 349 Declaration file?';
        EmptyVATRegNo: Boolean;
        LocationDiffCountryCode: Boolean;
        Text1100016: Label 'Default';
        Text1100017: Label 'Txt Files|*.txt|All Files|*.*''';
        Iso88591Lbl: Label 'ISO-8859-1';
        Utf8Lbl: Label 'Utf-8';
        OutStr: OutStream;
        PeriodFreqChange: Boolean;
        PeriodChangeText: Text[1];
        AmountEUService: Decimal;
        NumPeriod: Integer;
        AccumPrevDeclAmountEUService: Decimal;
        AccumPrevDeclAmountTri: Decimal;
        AccumOrigDeclAmountEUService: Decimal;
        AccumOrigDeclAmountTri: Decimal;
        CorrIncludedForOpTriAmount: Boolean;
        EUServiceAlreadyExported: Boolean;
        ThirdPartyAlreadyExported: Boolean;
        PeriodFrequencyChangeEnable: Boolean;
        NoTaxableAmountOpTri: Decimal;
        NoTaxableAmountEUService: Decimal;
        Idx: Option ,E,M,H;
        ReportFileName: Text;
        StartDateFormula: DateFormula;
        EndDateFormula: DateFormula;

    [Scope('OnPrem')]
    procedure FormatTextAmt(Amount: Decimal): Text[15]
    var
        TextAmt: Text[15];
    begin
        TextAmt := Format(Amount, 0, '<Precision,2:2><Integer><Decimals>');
        TextAmt := DelChr(TextAmt, '=', '.,');
        while StrLen(TextAmt) < 15 do
            TextAmt := '0' + TextAmt;
        exit(TextAmt);
    end;

    [Scope('OnPrem')]
    procedure IncludeIn349(VATEntry: Record "VAT Entry"; var AmountIn349: Decimal; var LocationDifferentCountryCode: Boolean) Result: Boolean
    var
        EUCountryInLocCodeHeader: Boolean;
        EUCountryInLocCodeLines: Boolean;
        VATEntryEUCountryRegCode: Boolean;
        SkipEntry: Boolean;
    begin
        OnBeforeIncludeIn349(VATEntry, SkipEntry, AmountIn349, LocationDifferentCountryCode, Result);
        if SkipEntry then
            exit(Result);

        AmountIn349 := 0;
        VATEntryEUCountryRegCode := FindEUCountryRegionCode(VATEntry."Country/Region Code");
        if VATEntryEUCountryRegCode then
            if CompInfShipToCountryRegCode then begin
                if AllLocationsAreEU then
                    exit(true);

                GetPostedCountryLocCode(VATEntry."Document No.", VATEntry, AmountIn349, CompInfShipToCountryRegCode,
                  EUCountryInLocCodeHeader, EUCountryInLocCodeLines, LocationDifferentCountryCode, VATEntry."VAT Prod. Posting Group");
                if EUCountryInLocCodeHeader or EUCountryInLocCodeLines then
                    exit(true);
            end else begin
                GetPostedCountryLocCode(VATEntry."Document No.", VATEntry, AmountIn349, CompInfShipToCountryRegCode,
                  EUCountryInLocCodeHeader, EUCountryInLocCodeLines, LocationDifferentCountryCode, VATEntry."VAT Prod. Posting Group");
                if EUCountryInLocCodeHeader or EUCountryInLocCodeLines then
                    exit(true);
            end;
    end;

    local procedure AppendLine(Content: Text)
    begin
        TextList.Add(Content);
    end;

    local procedure InsertLine(Content: Text)
    begin
        TextList.Insert(1, Content);
    end;

    procedure FindEUCountryRegionCode(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        exit(CountryRegion.EUCountryFound(CountryCode));
    end;

    [Scope('OnPrem')]
    procedure GetCompInfShipToCountryRegCode(var CInfoShipToCountryRegCode: Boolean)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CInfoShipToCountryRegCode := FindEUCountryRegionCode(CompanyInfo."Ship-to Country/Region Code");
    end;

    [Scope('OnPrem')]
    procedure GetCompanyCountryRegCode(var EUCountryRegCode: Boolean)
    begin
        EUCountryRegCode := FindEUCountryRegionCode(CountryCode);
    end;

    [Scope('OnPrem')]
    procedure GetPostedCountryLocCode(DocNo: Code[20]; VATEntry: Record "VAT Entry"; var AmountToIncludeIn349: Decimal; CompInforShipToCountryCode: Boolean; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean; var LocationDifferentCountryCode: Boolean; VATPPG: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLines: Record "Sales Invoice Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLines: Record "Purch. Inv. Line";
        Location: Record Location;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CustLedgeEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        EUCountryHeaderLocationCode := false;
        EUCountryLinesLocationCode := false;
        LocationDifferentCountryCode := false;
        AmountToIncludeIn349 := 0;
        case VATEntry.Type of
            VATEntry.Type::Sale:
                case VATEntry."Document Type" of
                    VATEntry."Document Type"::Invoice:
                        begin
                            SourceCodeSetup.Get();
                            if VATEntry."Source Code" = SourceCodeSetup.Sales then begin
                                if SalesInvHeader.Get(DocNo) then
                                    if SalesInvHeader."Location Code" <> '' then begin
                                        if Location.Get(SalesInvHeader."Location Code") then begin
                                            EUCountryHeaderLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                            LocationDifferentCountryCode :=
                                                IsSalesLocationDifferentCountryCode(
                                                    EUCountryHeaderLocationCode, SalesInvHeader."Sell-to Customer No.", SalesInvHeader."Location Code");
                                        end;
                                    end else begin
                                        TempSalesInvLines.SetRange("Document No.", DocNo);
                                        TempSalesInvLines.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                        TempSalesInvLines.SetRange("VAT Prod. Posting Group", VATPPG);
                                        if not TempSalesInvLines.FindFirst() then begin
                                            SalesInvLines.SetRange("Document No.", DocNo);
                                            SalesInvLines.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                            SalesInvLines.SetRange("VAT Prod. Posting Group", VATPPG);
                                            if SalesInvLines.FindSet() then
                                                repeat
                                                    if SalesInvLines."Location Code" <> '' then begin
                                                        if Location.Get(SalesInvLines."Location Code") then
                                                            EUCountryLinesLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                                        if EUCountryLinesLocationCode then begin
                                                            AmountToIncludeIn349 +=
                                                                GetExportedAmountIn349(
                                                                    SalesInvHeader."Currency Code", SalesInvHeader."Currency Factor", SalesInvLines.Amount);
                                                            LocationDifferentCountryCode :=
                                                                IsSalesLocationDifferentCountryCode(
                                                                    true, SalesInvLines."Sell-to Customer No.", SalesInvLines."Location Code");
                                                            TempSalesInvLines := SalesInvLines;
                                                            TempSalesInvLines.Insert();
                                                        end;
                                                    end else
                                                        if CompInforShipToCountryCode then begin
                                                            EUCountryLinesLocationCode := true;
                                                            AmountToIncludeIn349 +=
                                                                GetExportedAmountIn349(
                                                                    SalesInvHeader."Currency Code", SalesInvHeader."Currency Factor", SalesInvLines.Amount);
                                                            TempSalesInvLines := SalesInvLines;
                                                            TempSalesInvLines.Insert();
                                                        end;
                                                until SalesInvLines.Next() = 0;
                                        end;
                                    end;
                            end else
                                if not GetPostedCountryLocCodeInvoice(DocNo, LocationDifferentCountryCode, CompInforShipToCountryCode, VATEntry, VATPPG, EUCountryHeaderLocationCode, EUCountryLinesLocationCode) then
                                    GetSalesEntryPostedByJournal(
                                        DocNo, AmountToIncludeIn349, EUCountryLinesLocationCode, CompInforShipToCountryCode);

                            AmountToIncludeIn349 := -AmountToIncludeIn349;
                        end;
                    VATEntry."Document Type"::"Credit Memo":
                        begin
                            SourceCodeSetup.Get();
                            if VATEntry."Source Code" = SourceCodeSetup.Sales then begin
                                if SalesCrMemoHeader.Get(DocNo) then
                                    if SalesCrMemoHeader."Location Code" <> '' then begin
                                        if Location.Get(SalesCrMemoHeader."Location Code") then begin
                                            EUCountryHeaderLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                            LocationDifferentCountryCode :=
                                                IsSalesLocationDifferentCountryCode(
                                                    EUCountryHeaderLocationCode, SalesCrMemoHeader."Sell-to Customer No.", SalesCrMemoHeader."Location Code");
                                        end;
                                    end else begin
                                        SalesCrMemoLine.SetRange("Document No.", DocNo);
                                        SalesCrMemoLine.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                        SalesCrMemoLine.SetRange("VAT Prod. Posting Group", VATPPG);
                                        if SalesCrMemoLine.Find('-') then
                                            repeat
                                                if SalesCrMemoLine."Location Code" <> '' then begin
                                                    if Location.Get(SalesCrMemoLine."Location Code") then begin
                                                        EUCountryLinesLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                                        LocationDifferentCountryCode :=
                                                            IsSalesLocationDifferentCountryCode(
                                                                EUCountryHeaderLocationCode, SalesCrMemoLine."Sell-to Customer No.", SalesCrMemoLine."Location Code");
                                                    end;
                                                end else
                                                    if CompInforShipToCountryCode then
                                                        EUCountryLinesLocationCode := true;
                                            until SalesCrMemoLine.Next() = 0;
                                    end;
                            end else
                                if not GetPostedCountryLocCodeServiceCrMemo(DocNo, CompInforShipToCountryCode, VATEntry, VATPPG, EUCountryHeaderLocationCode, EUCountryLinesLocationCode) then begin
                                    CustLedgeEntry.SetFilter("Journal Batch Name", '<>%1', '');
                                    CustLedgeEntry.SetRange("Document No.", DocNo);
                                    CustLedgeEntry.SetRange("Document Type", CustLedgeEntry."Document Type"::"Credit Memo");
                                    EUCountryLinesLocationCode := (not CustLedgeEntry.IsEmpty) and CompInforShipToCountryCode;
                                end;
                        end;
                end;
            VATEntry.Type::Purchase:
                case VATEntry."Document Type" of
                    VATEntry."Document Type"::Invoice:
                        if PurchInvHeader.Get(DocNo) then begin
                            if PurchInvHeader."Location Code" <> '' then begin
                                if Location.Get(PurchInvHeader."Location Code") then begin
                                    EUCountryHeaderLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                    LocationDifferentCountryCode :=
                                        IsPurchsLocationDifferentCountryCode(
                                            EUCountryHeaderLocationCode, PurchInvHeader."Pay-to Vendor No.", PurchInvHeader."Location Code");
                                end;
                            end else begin
                                TempPurchInvLines.SetRange("Document No.", DocNo);
                                TempPurchInvLines.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                TempPurchInvLines.SetRange("VAT Prod. Posting Group", VATPPG);
                                if not TempPurchInvLines.FindFirst() then begin
                                    PurchInvLines.SetRange("Document No.", DocNo);
                                    PurchInvLines.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                    PurchInvLines.SetRange("VAT Prod. Posting Group", VATPPG);
                                    if PurchInvLines.FindSet() then
                                        repeat
                                            if PurchInvLines."Location Code" <> '' then begin
                                                if Location.Get(PurchInvLines."Location Code") then
                                                    EUCountryLinesLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                                if EUCountryLinesLocationCode then begin
                                                    AmountToIncludeIn349 +=
                                                        GetExportedAmountIn349(
                                                            PurchInvHeader."Currency Code", PurchInvHeader."Currency Factor", PurchInvLines.Amount);
                                                    LocationDifferentCountryCode :=
                                                        IsPurchsLocationDifferentCountryCode(
                                                            true, PurchInvLines."Pay-to Vendor No.", PurchInvLines."Location Code");
                                                    TempPurchInvLines := PurchInvLines;
                                                    TempPurchInvLines.Insert();
                                                end;
                                            end else
                                                if CompInforShipToCountryCode then begin
                                                    EUCountryLinesLocationCode := true;
                                                    AmountToIncludeIn349 +=
                                                        GetExportedAmountIn349(
                                                            PurchInvHeader."Currency Code", PurchInvHeader."Currency Factor", PurchInvLines.Amount);
                                                    TempPurchInvLines := PurchInvLines;
                                                    TempPurchInvLines.Insert();
                                                end;
                                        until PurchInvLines.Next() = 0;
                                end;
                            end;
                        end else
                            GetPurchEntryPostedByJournal(
                                DocNo, AmountToIncludeIn349,
                                EUCountryLinesLocationCode, CompInforShipToCountryCode);
                    VATEntry."Document Type"::"Credit Memo":
                        if PurchCrMemoHdr.Get(DocNo) then begin
                            if PurchCrMemoHdr."Location Code" <> '' then begin
                                if Location.Get(PurchCrMemoHdr."Location Code") then begin
                                    EUCountryHeaderLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                    LocationDifferentCountryCode :=
                                        IsPurchsLocationDifferentCountryCode(
                                        EUCountryHeaderLocationCode, PurchCrMemoHdr."Pay-to Vendor No.", PurchCrMemoHdr."Location Code");
                                end;
                            end else begin
                                PurchCrMemoLine.SetRange("Document No.", DocNo);
                                PurchCrMemoLine.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                                PurchCrMemoLine.SetRange("VAT Prod. Posting Group", VATPPG);
                                if PurchCrMemoLine.Find('-') then
                                    repeat
                                        if PurchCrMemoLine."Location Code" <> '' then begin
                                            if Location.Get(PurchCrMemoLine."Location Code") then begin
                                                EUCountryLinesLocationCode := FindEUCountryRegionCode(Location."Country/Region Code");
                                                LocationDifferentCountryCode :=
                                                    IsPurchsLocationDifferentCountryCode(
                                                    EUCountryHeaderLocationCode, PurchCrMemoLine."Pay-to Vendor No.", PurchCrMemoLine."Location Code");
                                            end;
                                        end else
                                            if CompInforShipToCountryCode then
                                                EUCountryLinesLocationCode := true;
                                    until PurchCrMemoLine.Next() = 0;
                            end;
                        end else begin
                            VendLedgerEntry.SetFilter("Journal Batch Name", '<>%1', '');
                            VendLedgerEntry.SetRange("Document No.", DocNo);
                            VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::"Credit Memo");
                            EUCountryLinesLocationCode := (not VendLedgerEntry.IsEmpty) and CompInforShipToCountryCode;
                        end;
                end;
        end;
    end;

    local procedure GetPostedCountryLocCodeInvoice(DocNo: Code[20]; var LocationDifferentCountryCode: Boolean; CompInforShipToCountryCode: Boolean; VATEntry: Record "VAT Entry"; VATPPG: Code[20]; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean) Result: Boolean
    begin
        OnGetPostedCountryLocCodeInvoice(DocNo, LocationDifferentCountryCode, CompInforShipToCountryCode, VATEntry, VATPPG, EUCountryHeaderLocationCode, EUCountryLinesLocationCode, AmountToIncludeIn349, Result);
    end;

    local procedure GetPostedCountryLocCodeServiceCrMemo(DocNo: Code[20]; CompInforShipToCountryCode: Boolean; VATEntry: Record "VAT Entry"; VATPPG: Code[20]; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean) Result: Boolean
    begin
        OnGetPostedCountryLocCodeServiceCrMemo(DocNo, CompInforShipToCountryCode, VATEntry, VATPPG, EUCountryHeaderLocationCode, EUCountryLinesLocationCode, Result);
    end;

    [Scope('OnPrem')]
    procedure CheckIfEULocations(var EULocations: Boolean)
    var
        Location: Record Location;
        EULoc: Boolean;
    begin
        EULocations := true;
        if Location.Find('-') then
            repeat
                EULoc := FindEUCountryRegionCode(Location."Country/Region Code");
                if not EULoc then
                    EULocations := false;
            until Location.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetFilterStringFromColumnGPPG()
    var
        GPPGCode: Text[1024];
        Position: Integer;
    begin
        GPPGCode := ColumnGPPG;
        repeat
            Position := StrPos(GPPGCode, ';');
            if GPPGCode <> '' then begin
                if Position <> 0 then begin
                    FilterString := FilterString + '<>' + CopyStr(GPPGCode, 1, Position - 1);
                    GPPGCode := CopyStr(GPPGCode, Position + 1);
                end else begin
                    FilterString := FilterString + '<>' + CopyStr(GPPGCode, 1);
                    GPPGCode := '';
                end;
                if GPPGCode <> '' then
                    FilterString := FilterString + '&';
            end;
        until GPPGCode = '';
    end;

    [Scope('OnPrem')]
    procedure GetCountryfromLocation("Code": Code[10]): Code[10]
    var
        Location: Record Location;
    begin
        Location.Get(Code);
        exit(Location."Country/Region Code");
    end;

    [Scope('OnPrem')]
    procedure UpdateRequestForm()
    begin
        PageUpdateRequestForm();
    end;

    local procedure PageUpdateRequestForm()
    begin
        PeriodFrequencyChangeEnable := Period in [Period::"02", Period::"05", Period::"08", Period::"11"];
    end;

    local procedure SummarizeBaseAmount(VATEntry: Record "VAT Entry"; AmountToIncludein349: Decimal; var Amount: array[3] of Decimal)
    var
        IncAmount: Decimal;
    begin
        if AmountToIncludein349 <> 0 then
            IncAmount := AmountToIncludein349
        else
            IncAmount := VATEntry.Base;

        Amount[MapDeliveryOperationCode(VATEntry."Delivery Operation Code")] += IncAmount;
    end;

    local procedure MapDeliveryOperationCode(DeliveryOperationCode: Option " ","E - General","M - Imported Tax Exempt","H - Imported Tax Exempt (Representative)"): Integer
    begin
        if DeliveryOperationCode = DeliveryOperationCode::" " then
            exit(DeliveryOperationCode::"E - General");
        exit(DeliveryOperationCode);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(ReportTempFileName: Text)
    begin
        ReportFileName := ReportTempFileName;
    end;

    [Scope('OnPrem')]
    procedure SetFilterString(FilterStringNew: Text[1024])
    begin
        FilterString := FilterStringNew;
    end;

    local procedure GetExportedAmountIn349(CurrencyCode: Code[20]; CurrencyFactor: Decimal; LineAmount: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode <> '' then begin
            Currency.Get(CurrencyCode);
            exit(Round(LineAmount / CurrencyFactor, Currency."Amount Rounding Precision"))
        end;
        exit(LineAmount);
    end;

    local procedure GetSalesEntryPostedByJournal(DocNo: Code[20]; var AmountToIncludeIn349: Decimal; var EUCountryLinesLocationCode: Boolean; CompInforShipToCountryCode: Boolean)
    var
        CustLedgeEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgeEntry.SetFilter(CustLedgeEntry."Journal Batch Name", '<>%1', '');
        CustLedgeEntry.SetRange(CustLedgeEntry."Document No.", DocNo);
        CustLedgeEntry.SetRange(CustLedgeEntry."Document Type", CustLedgeEntry."Document Type"::Invoice);
        if CustLedgeEntry.FindFirst() and CompInforShipToCountryCode then begin
            CustLedgeEntry.CalcFields(CustLedgeEntry."Amount (LCY)");
            AmountToIncludeIn349 := CustLedgeEntry."Amount (LCY)";
            EUCountryLinesLocationCode := true;
        end;
    end;

    local procedure GetPurchEntryPostedByJournal(DocNo: Code[20]; var AmountToIncludeIn349: Decimal; var EUCountryLinesLocationCode: Boolean; CompInforShipToCountryCode: Boolean)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetFilter(VendLedgerEntry."Journal Batch Name", '<>%1', '');
        VendLedgerEntry.SetRange(VendLedgerEntry."Document No.", DocNo);
        VendLedgerEntry.SetRange(VendLedgerEntry."Document Type", VendLedgerEntry."Document Type"::Invoice);
        if VendLedgerEntry.FindFirst() and CompInforShipToCountryCode then begin
            VendLedgerEntry.CalcFields(VendLedgerEntry."Amount (LCY)");
            AmountToIncludeIn349 := Abs(VendLedgerEntry."Amount (LCY)");
            EUCountryLinesLocationCode := true;
        end;
    end;

    local procedure CalcVendDeclarationPeriodInfo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; VendNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document Type", DocType);
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.FindFirst();
        if (VendLedgEntry."Applies-to Doc. Type" in
            [VendLedgEntry."Applies-to Doc. Type"::Invoice, VendLedgEntry."Applies-to Doc. Type"::Reminder]) and
           (VendLedgEntry."Closed by Entry No." <> 0) and
           AppliedVendLedgEntry.Get(VendLedgEntry."Closed by Entry No.")
        then
            RectFiscalYear := Format(Date2DMY(AppliedVendLedgEntry."VAT Reporting Date", 3))
        else
            RectFiscalYear := Format(Date2DMY(VendLedgEntry."VAT Reporting Date", 3));
    end;

    local procedure CalcCustDeclarationPeriodInfo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; CustNo: Code[20])
    begin
        CustEntries.SetRange("Document Type", DocType);
        CustEntries.SetRange("Document No.", DocNo);
        CustEntries.SetRange("Customer No.", CustNo);
        CustEntries.FindFirst();
        if (CustEntries."Applies-to Doc. Type" in
            [CustEntries."Applies-to Doc. Type"::Invoice, CustEntries."Applies-to Doc. Type"::Reminder]) and
           (CustEntries."Closed by Entry No." <> 0) and
           CustEntries2.Get(CustEntries."Closed by Entry No.")
        then
            RectFiscalYear := Format(Date2DMY(CustEntries2."VAT Reporting Date", 3))
        else
            RectFiscalYear := Format(Date2DMY(CustEntries."VAT Reporting Date", 3));
    end;

    local procedure CalcNoTaxableAmountVendor(var NormalAmount: Decimal; var EUServiceAmount: Decimal; VendorNo: Code[20]; FromDate: Date; ToDate: Date; FilterString: Text[1024])
    begin
        if not CompInfShipToCountryRegCode then
            exit;
        NoTaxableMgt.CalcNoTaxableAmountVendor(
          NormalAmount, EUServiceAmount, VendorNo, FromDate, ToDate, FilterString);
    end;

    local procedure CalcNoTaxableAmountCustomer(var NoTaxableNormalAmountSales: array[3] of Decimal)
    begin
        if not CompInfShipToCountryRegCode then
            exit;
        NoTaxableMgt.CalcNoTaxableAmountCustomerWithDeliveryCode(
          NoTaxableNormalAmountSales, NoTaxableAmountEUService, NoTaxableAmountOpTri, Customer2."No.", FromDate, ToDate, FilterString);
    end;

    [Scope('OnPrem')]
    procedure GetPeriodAsText(): Code[2]
    var
        PeriodInt: Integer;
    begin
        if StrLen(Format(Period)) = 2 then
            exit(CopyStr(Format(Period), 1, 2));

        PeriodInt := Period;
        exit(Format(PeriodInt, 2, '<Integer,2><Filler Character,0>'));
    end;

    local procedure FilterVATInvPurchEntries(var VATEntry: Record "VAT Entry"; BillToPayNo: Code[20]; FromDate: Date; ToDate: Date; EUService: Boolean; GenProdPostingGroupFilter: Text)
    begin
        VATEntry.Reset();
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayNo);
        VATEntry.SetRange("VAT Reporting Date", FromDate, ToDate);
        VATEntry.SetRange("EU Service", EUService);
        VATEntry.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroupFilter);
    end;

    local procedure FilterVATInvSalesEntries(var VATEntry: Record "VAT Entry"; BillToPayNo: Code[20]; FromDate: Date; ToDate: Date; EUService: Boolean; GenProdPostingGroupFilter: Text)
    begin
        VATEntry.Reset();
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayNo);
        VATEntry.SetRange("VAT Reporting Date", FromDate, ToDate);
        VATEntry.SetRange("EU Service", EUService);
        VATEntry.SetFilter("Gen. Prod. Posting Group", GenProdPostingGroupFilter);
    end;

    local procedure FilterCustVendWarnings(var CustVendWarning349To: Record "Customer/Vendor Warning 349"; var CustVendWarning349From: Record "Customer/Vendor Warning 349"; IsExported: Boolean; EUService: Boolean)
    begin
        CustVendWarning349To.Copy(CustVendWarning349);
        CustVendWarning349To.SetRange("Original Declaration FY", CustVendWarning349From."Original Declaration FY");
        CustVendWarning349To.SetRange("Original Declaration Period", CustVendWarning349From."Original Declaration Period");
        CustVendWarning349To.SetRange(Exported, IsExported);
        CustVendWarning349To.SetRange("EU Service", EUService);
    end;

    procedure IsSalesLocationDifferentCountryCode(EUCountryHeaderLocationCode: Boolean; CustomerNo: Code[20]; LocationCode: Code[10]): Boolean
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(IsLocationDifferentCountryCode(EUCountryHeaderLocationCode, Customer."Country/Region Code", LocationCode));
    end;

    local procedure IsPurchsLocationDifferentCountryCode(EUCountryHeaderLocationCode: Boolean; VendorNo: Code[20]; LocationCode: Code[10]): Boolean
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        exit(IsLocationDifferentCountryCode(EUCountryHeaderLocationCode, Vendor."Country/Region Code", LocationCode));
    end;

    local procedure IsLocationDifferentCountryCode(EUCountryHeaderLocationCode: Boolean; CustVendCountryRegionCode: Code[10]; LocationCode: Code[10]): Boolean
    var
        LocationCountryCode: Code[10];
    begin
        if not EUCountryHeaderLocationCode then
            exit(false);
        if not FindEUCountryRegionCode(CustVendCountryRegionCode) then
            exit(false);
        LocationCountryCode := GetCountryfromLocation(LocationCode);
        exit(
          (LocationCountryCode <> CountryCode) xor
          (CustVendCountryRegionCode <> CountryCode));
    end;

    local procedure IsCorrectiveCrMemo(CustVendWarning349: Record "Customer/Vendor Warning 349") Result: Boolean
    var
        VATEntry: Record "VAT Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        SalesCrMemoFound: Boolean;
    begin
        InitVATEntry(VATEntry, CustVendWarning349."VAT Entry No.");
        if VATEntry."Document Type" <> "Gen. Journal Document Type"::"Credit Memo" then
            exit(false);

        case CustVendWarning349.Type of
            CustVendWarning349.Type::Sale:
                begin
                    SalesCrMemoFound := SalesCrMemoHeader.Get(CustVendWarning349."Document No.");
                    if SalesCrMemoFound then
                        exit(SalesCrMemoHeader."Corrected Invoice No." <> '');

                    OnIsCorrectiveCrMemoForSales(CustVendWarning349."Document No.", Result);
                end;
            CustVendWarning349.Type::Purchase:
                begin
                    if not PurchCrMemoHeader.Get(CustVendWarning349."Document No.") then
                        exit(false);
                    exit(PurchCrMemoHeader."Corrected Invoice No." <> '');
                end;
        end;
    end;

    local procedure GetCorrectedInvoicePostingDate(CustVendWarning349: Record "Customer/Vendor Warning 349"): Date
    var
        VATEntry: Record "VAT Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PostingDate: Date;
        ShouldExit: Boolean;
    begin
        InitVATEntry(VATEntry, CustVendWarning349."VAT Entry No.");
        if VATEntry."Document Type" <> "Gen. Journal Document Type"::"Credit Memo" then
            exit(0D);

        case CustVendWarning349.Type of
            CustVendWarning349.Type::Sale:
                begin
                    if SalesCrMemoHeader.Get(CustVendWarning349."Document No.") then
                        if SalesInvoiceHeader.Get(SalesCrMemoHeader."Corrected Invoice No.") then
                            exit(SalesInvoiceHeader."Posting Date");

                    ShouldExit := false;
                    OnGetCorrectedInvoicePostingDate(CustVendWarning349."Document No.", PostingDate, ShouldExit);
                    if ShouldExit then
                        exit(PostingDate);
                end;
            CustVendWarning349.Type::Purchase:
                if PurchCrMemoHeader.Get(CustVendWarning349."Document No.") then
                    if PurchInvHeader.Get(PurchCrMemoHeader."Corrected Invoice No.") then
                        exit(PurchInvHeader."Posting Date");
        end;

        exit(0D);
    end;

    local procedure CombineEUCountryAndVATRegNo(CountryRegion: Record "Country/Region"; VATRegistrationNo: Code[20]) CombinedVATRegNo: Text[17]
    begin
        if StrPos(VATRegistrationNo, CountryRegion."EU Country/Region Code") = 0 then
            VATRegistrationNo := CountryRegion."EU Country/Region Code" + VATRegistrationNo;

        CombinedVATRegNo :=
          Format(CountryRegion.GetVATRegistrationNoLimitedBySetup(VATRegistrationNo), MaxStrLen(CombinedVATRegNo));
    end;

    local procedure InsertVendWarning349(No: Code[20]; Name: Text[100]; VATReportingDate: Date; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; EU3PartyTrade: Boolean; EUService: Boolean; PositiveBase: Boolean; VATEntryNo: Integer; NoTaxableEntryNo: Integer; PostingDate: Date)
    begin
        CalcVendDeclarationPeriodInfo(DocType, DocNo, No);

        if CustVendWarning349.FindLast() then;
        CustVendWarning349.Init();
        CustVendWarning349."Entry No." := CustVendWarning349."Entry No." + 1;
        CustVendWarning349.Type := CustVendWarning349.Type::Purchase;
        CustVendWarning349."Customer/Vendor No." := No;
        CustVendWarning349."Customer/Vendor Name" := Name;
        CustVendWarning349."VAT Reporting Date" := VATReportingDate;
        CustVendWarning349."Document No." := DocNo;
        CustVendWarning349."EU 3-Party Trade" := EU3PartyTrade;
        CustVendWarning349."EU Service" := EUService;
        CustVendWarning349."Original Declaration FY" := RectFiscalYear;
        CustVendWarning349."Original Declaration Period" := GetPeriodAsText();
        CustVendWarning349."VAT Entry No." := VATEntryNo;
        CustVendWarning349."No Taxable Entry No." := NoTaxableEntryNo;
        CustVendWarning349."Posting Date" := PostingDate;

        if PositiveBase then
            CustVendWarning349.Sign := '-'
        else
            CustVendWarning349.Sign := '+';
        CustVendWarning349.Insert();
    end;

    local procedure InsertCustWarning349(No: Code[20]; Name: Text[100]; VATReportingDate: Date; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; EU3PartyTrade: Boolean; EUService: Boolean; PositiveBase: Boolean; VATEntryNo: Integer; NoTaxableEntryNo: Integer; DeliveryOperationCode: Option; PostingDate: Date)
    begin
        CalcCustDeclarationPeriodInfo(DocType, DocNo, No);

        if CustVendWarning349.FindLast() then;
        CustVendWarning349.Init();
        CustVendWarning349."Entry No." := CustVendWarning349."Entry No." + 1;
        CustVendWarning349.Type := CustVendWarning349.Type::Sale;
        CustVendWarning349."Customer/Vendor No." := No;
        CustVendWarning349."Customer/Vendor Name" := Name;
        CustVendWarning349."VAT Reporting Date" := VATReportingDate;
        CustVendWarning349."Document No." := DocNo;
        CustVendWarning349."EU 3-Party Trade" := EU3PartyTrade;
        CustVendWarning349."EU Service" := EUService;
        CustVendWarning349."Original Declaration FY" := RectFiscalYear;
        CustVendWarning349."Original Declaration Period" := GetPeriodAsText();
        CustVendWarning349."VAT Entry No." := VATEntryNo;
        CustVendWarning349."No Taxable Entry No." := NoTaxableEntryNo;
        CustVendWarning349."Delivery Operation Code" := DeliveryOperationCode;
        CustVendWarning349."Posting Date" := PostingDate;

        if PositiveBase then
            CustVendWarning349.Sign := '-'
        else
            CustVendWarning349.Sign := '+';
        CustVendWarning349.Insert();
    end;

    local procedure InsertCustWarningsFromSalesCrMemoLine()
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntriesForSourceWithVATReportingDate(
          "General Posting Type"::Sale.AsInteger(), Customer2."No.", "Gen. Journal Document Type"::"Credit Memo".AsInteger(),
          FromDate, ToDate, FilterString);
        if NoTaxableEntry.IsEmpty() then
            exit;

        NoTaxableEntry.FindSet();
        repeat
            InsertCustWarning349(
              Customer2."No.", Customer2.Name, NoTaxableEntry."VAT Reporting Date",
              NoTaxableEntry."Document Type"::"Credit Memo", NoTaxableEntry."Document No.",
              NoTaxableEntry."EU 3-Party Trade", NoTaxableEntry."EU Service", false, 0, NoTaxableEntry."Entry No.", 0, NoTaxableEntry."Posting Date");
        until NoTaxableEntry.Next() = 0;
    end;

    local procedure GetVendorNameUpperNormalized(): Text
    begin
        exit(ReplaceSpecialCharactersUpper(UpperCase(Vendor2.Name)));
    end;

    local procedure GetCustomerNameUpperNormalized(): Text
    begin
        exit(ReplaceSpecialCharactersUpper(UpperCase(Customer2.Name)))
    end;

    local procedure ReplaceSpecialCharactersUpper(UppercaseInputText: Text) Result: Text
    begin
        Result := ConvertStr(UppercaseInputText, 'ÁÀÉÈÊÍÌÓÒÛÚÙÑÜÇÄËÏØÖ', 'AAEEEIIOOUUUNUCAEIOO')
    end;

    local procedure InsertVendWarningsFromPurchCrMemoLine()
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        NoTaxableEntry.FilterNoTaxableEntriesForSourceWithVATReportingDate(
          "General Posting Type"::Purchase.AsInteger(), Vendor2."No.", "Gen. Journal Document Type"::"Credit Memo".AsInteger(),
          FromDate, ToDate, FilterString);
        if NoTaxableEntry.IsEmpty() then
            exit;

        NoTaxableEntry.FindSet();
        repeat
            InsertVendWarning349(
              Vendor2."No.", Vendor2.Name, NoTaxableEntry."VAT Reporting Date",
              NoTaxableEntry."Document Type"::"Credit Memo", NoTaxableEntry."Document No.",
              NoTaxableEntry."EU 3-Party Trade", NoTaxableEntry."EU Service", false, 0, NoTaxableEntry."Entry No.", NoTaxableEntry."Posting Date");
        until NoTaxableEntry.Next() = 0;
    end;

    local procedure CorrectAmountPurchNoEU()
    var
        VATEntry: Record "VAT Entry";
    begin
        InitVATEntry(VATEntry, CustVendWarning349."VAT Entry No.");

        if CustVendWarning349."Original Declared Amount" <> 0 then
            NormalAmount -= CustVendWarning349."Original Declared Amount"
        else
            NormalAmount += VATEntry.Base;
        CustVendWarning349.Exported := true;
        CustVendWarning349.Modify();
    end;

    local procedure CorrectAmountEU()
    var
        VATEntry: Record "VAT Entry";
    begin
        if CustVendWarning349."Original Declared Amount" = 0 then begin
            InitVATEntry(VATEntry, CustVendWarning349."VAT Entry No.");
            AmountEUService += VATEntry.Base;
        end else
            AmountEUService -= CustVendWarning349."Original Declared Amount";
        CustVendWarning349.Exported := true;
        CustVendWarning349.Modify();
    end;

    local procedure InitVATEntry(var VATEntry: Record "VAT Entry"; CustVendWarning349VATEntryNo: Integer)
    var
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        if CustVendWarning349VATEntryNo = 0 then begin
            VATEntry.Init();
            if CustVendWarning349."No Taxable Entry No." <> 0 then begin
                NoTaxableEntry.Get(CustVendWarning349."No Taxable Entry No.");
                VATEntry.TransferFields(NoTaxableEntry);
            end;
        end else
            VATEntry.Get(CustVendWarning349VATEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncludeIn349(VATEntry: Record "VAT Entry"; var SkipEntry: Boolean; var AmountIn349: Decimal; var LocationDifferentCountryCode: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendorWarningsOnBeforeOnPostDataItem(var CustVendWarning349: Record "Customer/Vendor Warning 349"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCorrectedInvoicePostingDate(DocumentNo: Code[20]; var PostingDate: Date; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCorrectiveCrMemoForSales(DocumentNo: Code[20]; var Result: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetPostedCountryLocCodeInvoice(DocNo: Code[20]; var LocationDifferentCountryCode: Boolean; CompInforShipToCountryCode: Boolean; VATEntry: Record "VAT Entry"; VATPPG: Code[20]; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean; var AmountToIncludeIn349: Decimal; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetPostedCountryLocCodeServiceCrMemo(DocNo: Code[20]; CompInforShipToCountryCode: Boolean; VATEntry: Record "VAT Entry"; VATPPG: Code[20]; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean; var Result: Boolean)
    begin
    end;
}

