// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

report 11000000 "Get Proposal Entries"
{
    Caption = 'Get Proposal Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem(TransactionmodeTable; "Transaction Mode")
        {
            DataItemTableView = sorting("Include in Payment Proposal", "Our Bank") where("Include in Payment Proposal" = const(true));
            RequestFilterFields = "Our Bank", "Account Type", "Code";
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemLink = "Transaction Mode Code" = field(Code);
                DataItemTableView = sorting(Open, "On Hold", "Transaction Mode Code") where(Open = const(true), "On Hold" = const(''));
                RequestFilterFields = "Customer No.", "Recipient Bank Account";

                trigger OnAfterGetRecord()
                begin
                    NumeratorPostings := NumeratorPostings + 1;
                    BatchStatus.Update(1, Round(NumeratorPostings / NumberOfEntries * 10000, 1));

                    if "Due Date" > "Value Date" then
                        if TransactionmodeTable."Pmt. Disc. Possible" and
                           ("Original Pmt. Disc. Possible" <> 0) and
                           ("Pmt. Discount Date" >= "Value Date")
                        then begin
                            if "Pmt. Discount Date" > PmtDiscExpiryDate then
                                CurrReport.Skip();
                        end else // No Payment Discount possible
                            CurrReport.Skip();

                    Clear(DetailLine);
                    DetailLine."Account Type" := DetailLine."Account Type"::Customer;
                    DetailLine."Account No." := "Customer No.";
                    DetailLine.Date := "Value Date";
                    DetailLine."Transaction Mode" := "Transaction Mode Code";
                    DetailLine.Bank := "Recipient Bank Account";
                    DetailLine.InitRecord();

                    DetailLine.Validate("Serial No. (Entry)", "Entry No.");
                    IsHandled := false;
                    OnCustomerLedgerEntryOnAfterValidateSerialNoEntry("Cust. Ledger Entry", DetailLine, "Value Date", PmtDiscExpiryDate, NumberOfDetailLines, IsHandled);
                    if not IsHandled then
                        if DetailLine."Amount (Entry)" <> 0 then begin
                            NumberOfDetailLines := NumberOfDetailLines + 1;
                            DetailLine.Insert(true);
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    OnCustLedgerEntryOnBeforePreDataItem("Cust. Ledger Entry");
                    if TransactionmodeTable."Account Type" <> TransactionmodeTable."Account Type"::Customer then
                        CurrReport.Break();
                end;
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemLink = "Transaction Mode Code" = field(Code);
                DataItemTableView = sorting(Open, "On Hold", "Transaction Mode Code") where(Open = const(true), "On Hold" = const(''));
                RequestFilterFields = "Vendor No.", "Recipient Bank Account";

                trigger OnAfterGetRecord()
                var
                    Vend: Record Vendor;
                begin
                    NumeratorPostings := NumeratorPostings + 1;
                    BatchStatus.Update(1, Round(NumeratorPostings / NumberOfEntries * 10000, 1));

                    if "Due Date" > "Value Date" then
                        if TransactionmodeTable."Pmt. Disc. Possible" and
                           ("Original Pmt. Disc. Possible" <> 0) and
                           ("Pmt. Discount Date" >= "Value Date")
                        then begin
                            if "Pmt. Discount Date" > PmtDiscExpiryDate then
                                CurrReport.Skip();
                        end else // No Payment Discount possible
                            CurrReport.Skip();
                    Vend.Get("Vendor No.");
                    if Vend."Privacy Blocked" then
                        CurrReport.Skip();
                    if Vend.Blocked <> Vend.Blocked::" " then
                        CurrReport.Skip();

                    Clear(DetailLine);
                    DetailLine."Account Type" := DetailLine."Account Type"::Vendor;
                    DetailLine."Account No." := "Vendor No.";
                    DetailLine.Date := "Value Date";
                    DetailLine."Transaction Mode" := "Transaction Mode Code";
                    DetailLine.Bank := "Recipient Bank Account";
                    DetailLine.InitRecord();

                    DetailLine.Validate("Serial No. (Entry)", "Entry No.");
                    IsHandled := false;
                    OnVendorLedgerEntryOnAfterValidateSerialNoEntry("Vendor Ledger Entry", DetailLine, "Value Date", PmtDiscExpiryDate, NumberOfDetailLines, IsHandled);
                    if not IsHandled then
                        if DetailLine."Amount (Entry)" <> 0 then begin
                            NumberOfDetailLines := NumberOfDetailLines + 1;
                            DetailLine.Insert(true);
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    OnVendorLedgerEntryOnBeforePreDataItem("Vendor Ledger Entry");
                    if TransactionmodeTable."Account Type" <> TransactionmodeTable."Account Type"::Vendor then
                        CurrReport.Break();
                end;
            }
            dataitem("Employee Ledger Entry"; "Employee Ledger Entry")
            {
                DataItemLink = "Transaction Mode Code" = field(Code);
                DataItemTableView = sorting(Open, "Transaction Mode Code") where(Open = const(true));
                RequestFilterFields = "Employee No.";

                trigger OnAfterGetRecord()
                var
                    Empl: Record Employee;
                begin
                    NumeratorPostings := NumeratorPostings + 1;
                    BatchStatus.Update(1, Round(NumeratorPostings / NumberOfEntries * 10000, 1));

                    Empl.Get("Employee No.");

                    Clear(DetailLine);
                    DetailLine."Account Type" := DetailLine."Account Type"::Employee;
                    DetailLine."Account No." := "Employee No.";
                    DetailLine.Bank := "Employee No.";
                    DetailLine.Date := "Value Date";
                    DetailLine."Transaction Mode" := "Transaction Mode Code";
                    DetailLine.InitRecord();

                    DetailLine.Validate("Serial No. (Entry)", "Entry No.");
                    IsHandled := false;
                    OnEmployeeLedgerEntryOnAfterValidateSerialNoEntry("Employee Ledger Entry", DetailLine, "Value Date", PmtDiscExpiryDate, NumberOfDetailLines, IsHandled);
                    if not IsHandled then
                        if DetailLine."Amount (Entry)" <> 0 then begin
                            NumberOfDetailLines := NumberOfDetailLines + 1;
                            DetailLine.Insert(true);
                        end;
                end;

                trigger OnPreDataItem()
                begin
                    OnEmployeeLedgerEntryOnBeforePreDataItem("Employee Ledger Entry");
                    if TransactionmodeTable."Account Type" <> TransactionmodeTable."Account Type"::Employee then
                        CurrReport.Break();
                end;
            }

            trigger OnPreDataItem()
            begin
                if PartnerType <> "Partner Type"::" " then
                    SetRange("Partner Type", PartnerType);
            end;
        }
        dataitem("Detail Line"; "Detail Line")
        {
            DataItemTableView = sorting("Our Bank", Status, "Connect Batches", "Connect Lines", Date) where(Status = const(Proposal), "Connect Batches" = const(''), "Connect Lines" = const(0));

            trigger OnAfterGetRecord()
            var
                CustEntry: Record "Cust. Ledger Entry";
                VenEntry: Record "Vendor Ledger Entry";
                EmployeeLedgerEntry: Record "Employee Ledger Entry";
                CurrencyExchangeRate: Record "Currency Exchange Rate";
                NoSeries: Codeunit "No. Series";
                UseDocumentNo: Code[35];
            begin
                DetailLine := "Detail Line";
                TrMode.Get(DetailLine."Account Type", DetailLine."Transaction Mode");

                if TrMode."Combine Entries" then begin
                    ProposalLine.Reset();
                    ProposalLine.SetCurrentKey("Our Bank No.", Process, "Account Type", "Account No.", Bank, "Transaction Mode", "Currency Code",
                      "Transaction Date");
                    ProposalLine.SetRange("Our Bank No.", DetailLine."Our Bank");
                    ProposalLine.SetRange("Account Type", DetailLine."Account Type");
                    ProposalLine.SetRange("Account No.", DetailLine."Account No.");
                    ProposalLine.SetRange(Bank, DetailLine.Bank);
                    ProposalLine.SetRange("Transaction Mode", DetailLine."Transaction Mode");
                    ProposalLine.SetRange("Currency Code", "Currency Code");
                    ProposalLine.SetRange("Foreign Currency", "Currency Code (Entry)");
                    ProposalLine.SetRange("Transaction Date", DetailLine.Date);
                    OnAfterProposalLineSetFilters(ProposalLine, DetailLine);
                    Found := ProposalLine.FindLast()
                end else
                    Found := false;

                OnAfterGetRecordDetailLineOnBeforeCreateProposalLine(ProposalLine, DetailLine, Found);

                if not Found then begin
                    Clear(ProposalLine);
                    ProposalLine.SetRange("Our Bank No.", DetailLine."Our Bank");
                    if ProposalLine.FindLast() then
                        ProposalLine."Line No." := ProposalLine."Line No." + 10000
                    else
                        ProposalLine."Line No." := 10000;
                    ProposalLine."Our Bank No." := DetailLine."Our Bank";
                    ProposalLine.Init();
                    ProposalLine.Validate("Account Type", DetailLine."Account Type");
                    ProposalLine.Validate("Account No.", DetailLine."Account No.");
                    ProposalLine.Validate(Bank, DetailLine.Bank);
                    ProposalLine.Validate("Transaction Mode", DetailLine."Transaction Mode");
                    ProposalLine.Validate("Currency Code", DetailLine."Currency Code");
                    ProposalLine."Transaction Date" := DetailLine.Date;
                    ProposalLine.Validate("Identification No. Series", TrMode."Identification No. Series");
                    OnBeforeProposalLineInsert(ProposalLine, DetailLine);
                    ProposalLine.Insert(true);
                end;

                DetailLine."Connect Lines" := ProposalLine."Line No.";
                DetailLine.UpdateConnection();
                DetailLine.Modify();
                ProposalLine.Get(DetailLine."Our Bank", DetailLine."Connect Lines");
                if not ProcessProposalLines.CheckAProposalLine(ProposalLine) then begin
                    if ProposalLine."Error Message" = '' then
                        NoOfErrors := NoOfErrors + 1;
                end else
                    if ProposalLine."Error Message" <> '' then
                        NoOfErrors := NoOfErrors - 1;
                ProposalLine."Error Message" := ProcessProposalLines.FinalError();
                if ProposalLine.Warning = '' then begin
                    ProposalLine.Warning := ProcessProposalLines.FinalWarning();
                    if ProposalLine.Warning <> '' then
                        NumberOfWarnings := NumberOfWarnings + 1;
                end;
                case DetailLine."Account Type" of
                    DetailLine."Account Type"::Customer:
                        begin
                            CustEntry.Get(DetailLine."Serial No. (Entry)");
                            UseDocumentNo := CustEntry."Document No.";
                            if CustEntry."Document Type" <> CustEntry."Document Type"::Invoice then
                                ProposalLine.Docket := true;
                            ProposalLine.Validate("Salespers./Purch. Code", CustEntry."Salesperson Code");
                        end;
                    DetailLine."Account Type"::Vendor:
                        begin
                            VenEntry.Get(DetailLine."Serial No. (Entry)");
                            if VenEntry."External Document No." <> '' then
                                UseDocumentNo := VenEntry."External Document No."
                            else
                                UseDocumentNo := VenEntry."Document No.";
                            if VenEntry."Document Type" <> VenEntry."Document Type"::Invoice then
                                ProposalLine.Docket := true;
                            ProposalLine.Validate("Salespers./Purch. Code", VenEntry."Purchaser Code");
                        end;
                    DetailLine."Account Type"::Employee:
                        begin
                            EmployeeLedgerEntry.Get(DetailLine."Serial No. (Entry)");
                            UseDocumentNo := EmployeeLedgerEntry."Document No.";
                            if EmployeeLedgerEntry."Document Type" <> EmployeeLedgerEntry."Document Type"::Invoice then
                                ProposalLine.Docket := true;
                            ProposalLine.Validate("Salespers./Purch. Code", EmployeeLedgerEntry."Salespers./Purch. Code");
                        end;
                end;

                if not ProposalLine.Docket then begin
                    if ProposalLine."Description 1" = '' then
                        ProposalLine."Description 1" := Text1000015;
                    if StrLen(ProposalLine."Description 1" + ' ' + UseDocumentNo) < MaxStrLen(ProposalLine."Description 1") then
                        ProposalLine."Description 1" := DelChr(ProposalLine."Description 1" + ' ' + UseDocumentNo, '<>')
                    else
                        if StrLen(ProposalLine."Description 2" + ' ' + UseDocumentNo) < MaxStrLen(ProposalLine."Description 2") then
                            ProposalLine."Description 2" := DelChr(ProposalLine."Description 2" + ' ' + UseDocumentNo, '<>')
                        else
                            if StrLen(ProposalLine."Description 3" + ' ' + UseDocumentNo) < MaxStrLen(ProposalLine."Description 3") then
                                ProposalLine."Description 3" := DelChr(ProposalLine."Description 3" + ' ' + UseDocumentNo, '<>')
                            else
                                if StrLen(ProposalLine."Description 4" + ' ' + UseDocumentNo) < MaxStrLen(ProposalLine."Description 4") then
                                    ProposalLine."Description 4" := DelChr(ProposalLine."Description 4" + ' ' + UseDocumentNo, '<>')
                                else
                                    ProposalLine.Docket := true;
                end;

                FillDescription();

                if ProposalLine.Identification = '' then begin
                    TrMode.TestField("Identification No. Series");
                        ProposalLine."Identification No. Series" := TrMode."Identification No. Series";
                        ProposalLine.Identification := NoSeries.GetNextNo(ProposalLine."Identification No. Series", ProposalLine."Transaction Date");
                end;

                ProposalLine."Foreign Currency" := DetailLine."Currency Code (Entry)";
                if ProposalLine."Foreign Currency" <> ProposalLine."Currency Code"
                then
                    ProposalLine.Validate(
                      "Foreign Amount",
                      Round(
                        CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                          ProposalLine."Transaction Date", ProposalLine."Currency Code", ProposalLine."Foreign Currency", ProposalLine.Amount),
                        GetCurrencyAmountRoundingPrecision(ProposalLine."Foreign Currency")));

                ProposalLine.Modify();

                NumeratorDetailLines := NumeratorDetailLines + 1;
                BatchStatus.Update(2, Round(NumeratorDetailLines / NumberOfDetailLines * 10000, 1));
            end;

            trigger OnPostDataItem()
            begin
                BlankForeignCurrencyWithSameCurrencyCode();
            end;
        }
    }

    requestpage
    {
        Caption = 'Get proposal entries';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CurrencyDate; "Value Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Currency Date';
                        ToolTip = 'Specifies the date that will be used to find the exchange rate for the currency in the Currency Date field.';

                        trigger OnValidate()
                        begin
                            if PmtDiscExpiryDate < "Value Date" then
                                PmtDiscExpiryDate := "Value Date";
                        end;
                    }
                    field(PmtDiscountDate; PmtDiscExpiryDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pmt. Discount Date';
                        ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';

                        trigger OnValidate()
                        begin
                            if "Value Date" > PmtDiscExpiryDate then
                                "Value Date" := PmtDiscExpiryDate;
                        end;
                    }
                    field(PartnerType; PartnerType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Partner Type';
                        ToolTip = 'Specifies if the transaction mode is for a person or a company.';
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

    trigger OnInitReport()
    begin
        if "Value Date" = 0D then
            "Value Date" := Today + 1;
        if PmtDiscExpiryDate = 0D then
            PmtDiscExpiryDate := Today + 1;
    end;

    trigger OnPostReport()
    var
        Warningtext: Text[100];
    begin
        BatchStatus.Close();
        case NumberOfWarnings of
            0:
                Warningtext := '';
            1:
                Warningtext := Text1000008;
            else
                Warningtext := StrSubstNo(Text1000009, NumberOfWarnings);
        end;

        case NoOfErrors of
            0:
                if NumberOfWarnings > 0 then
                    Message(Text1000010 +
                      Text1000011);
            1:
                Message(Text1000012 +
                  Text1000013, Warningtext);
            else
                Message(Text1000014 +
                  Text1000013, NoOfErrors, Warningtext);
        end;
    end;

    trigger OnPreReport()
    var
        CustEntries: Record "Cust. Ledger Entry";
        VendEntries: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        ShouldShowPaymentReservationConfirm: Boolean;
    begin
        if "Value Date" < Today then
            Error(Text1000000);

        ShouldShowPaymentReservationConfirm := CopyStr(CompanyName, 1, 6) <> Text1000001;
        OnPreReportOnAfterCalcShouldShowPaymentReservationConfirm("Value Date", ShouldShowPaymentReservationConfirm);
        if ShouldShowPaymentReservationConfirm then
            if "Value Date" - Today > 14 then
                if not Confirm(
                     StrSubstNo(
                       Text1000002 +
                       Text1000003 +
                       Text1000004,
                       "Value Date" - Today), false)
                then
                    Error(Text1000005);

        OnPreReportOnAfterConfirm(TransactionmodeTable);
        BatchStatus.Open(Text1000006 + Text1000007);

        CustEntries.SetCurrentKey(Open, "On Hold", "Transaction Mode Code");
        CustEntries.SetRange(Open, true);
        CustEntries.SetRange("On Hold", '');
        CustEntries.SetFilter("Transaction Mode Code", '<>%1', '');

        VendEntries.SetCurrentKey(Open, "On Hold", "Transaction Mode Code");
        VendEntries.SetRange(Open, true);
        VendEntries.SetRange("On Hold", '');
        VendEntries.SetFilter("Transaction Mode Code", '<>%1', '');

        EmployeeLedgerEntry.SetCurrentKey(Open, "Transaction Mode Code");
        EmployeeLedgerEntry.SetRange(Open, true);
        EmployeeLedgerEntry.SetFilter("Transaction Mode Code", '<>%1', '');

        NumberOfEntries := CustEntries.Count + VendEntries.Count + EmployeeLedgerEntry.Count();

        CompanyInfo.Get();
    end;

    var
        Text1000000: Label 'The currency date cannot be in the past.';
        Text1000001: Label 'CRONUS';
        Text1000002: Label 'The currency date will be reached in %1 days,';
        Text1000003: Label ' and until then your bank must keep your payment orders';
        Text1000004: Label ' in reservation.\Do you want to continue?';
        Text1000005: Label 'Output cancelled';
        Text1000006: Label 'Read Entries @1@@@@@@@@@@\';
        Text1000007: Label 'Collect      @2@@@@@@@@@@';
        Text1000008: Label 'and a warning ';
        Text1000009: Label 'and %1 warnings ';
        Text1000010: Label 'A warning was created while generating proposal lines.\';
        Text1000011: Label 'A warning per line is shown at the bottom of the screen.';
        Text1000012: Label 'Error %1 was found while generating proposal lines.\';
        Text1000013: Label 'You can view the error in the lower part of the screen.';
        Text1000014: Label 'There are %1 errors %2found while generating proposal lines.\';
        Text1000015: Label 'Invoice';
        Text1000016: Label 'Collection order, see docket';
        Text1000017: Label 'Account No. %1';
        DetailLine: Record "Detail Line";
        ProposalLine: Record "Proposal Line";
        TrMode: Record "Transaction Mode";
        CompanyInfo: Record "Company Information";
        ProcessProposalLines: Codeunit "Process Proposal Lines";
        NumberOfEntries: Integer;
        NumeratorPostings: Integer;
        NumberOfDetailLines: Integer;
        NumeratorDetailLines: Integer;
        BatchStatus: Dialog;
        Found: Boolean;
        IsHandled: Boolean;
        NoOfErrors: Integer;
        NumberOfWarnings: Integer;
        "Value Date": Date;
        PmtDiscExpiryDate: Date;
        PartnerType: Enum "Partner Type";
        EmployeeNoMsg: Label 'Employee No. %1', Comment = '%1=Employee number;';

    local procedure FillDescription()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        Empl: Record Employee;
    begin
        if DetailLine."Account No." <> '' then
            case DetailLine."Account Type" of
                DetailLine."Account Type"::Customer:
                    begin
                        Cust.Get(DetailLine."Account No.");
                        UpdatePropLineDescription(ProposalLine, Cust."Our Account No.", Text1000017);
                    end;
                DetailLine."Account Type"::Vendor:
                    begin
                        Vend.Get(DetailLine."Account No.");
                        UpdatePropLineDescription(ProposalLine, Vend."Our Account No.", Text1000017);
                    end;
                DetailLine."Account Type"::Employee:
                    begin
                        Empl.Get(DetailLine."Account No.");
                        UpdatePropLineDescription(ProposalLine, Empl."No.", EmployeeNoMsg);
                    end;
            end;

        OnAfterFillDescription(ProposalLine, DetailLine);
    end;

    local procedure UpdatePropLineDescription(var ProposalLine: Record "Proposal Line"; OurAccountNo: Text[20]; CVDescriptionFormat: Text)
    begin
        if ProposalLine.Docket then begin
            if ProposalLine."Description 1" <> Text1000016 then
                ProposalLine."Description 1" := Text1000016;
            if OurAccountNo <> '' then
                ProposalLine."Description 2" :=
                  CopyStr(StrSubstNo(CVDescriptionFormat, OurAccountNo), 1, MaxStrLen(ProposalLine."Description 2"))
            else
                ProposalLine."Description 2" := CopyStr(CompanyInfo.Name, 1, MaxStrLen(ProposalLine."Description 2"));
            ProposalLine."Description 3" := '';
            ProposalLine."Description 4" := '';
        end;
    end;

    local procedure GetCurrencyAmountRoundingPrecision(FCYCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Initialize(FCYCode);
        exit(Currency."Amount Rounding Precision");
    end;

    local procedure BlankForeignCurrencyWithSameCurrencyCode()
    var
        ProposalLineLocal: Record "Proposal Line";
    begin
        ProposalLineLocal.SetRange("Our Bank No.", ProposalLine."Our Bank No.");
        if ProposalLineLocal.FindSet(true) then
            repeat
                if ProposalLineLocal."Foreign Currency" = ProposalLineLocal."Currency Code" then begin
                    ProposalLineLocal.Validate("Foreign Currency", '');
                    ProposalLineLocal.Validate("Foreign Amount", 0);
                    ProposalLineLocal.Modify();
                end;
            until ProposalLineLocal.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillDescription(var ProposalLine: Record "Proposal Line"; DetailLine: Record "Detail Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProposalLineSetFilters(var ProposalLine: Record "Proposal Line"; DetailLine: Record "Detail Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProposalLineInsert(var ProposalLine: Record "Proposal Line"; DetailLine: Record "Detail Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterConfirm(var TransactionMode: Record "Transaction Mode")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnAfterCalcShouldShowPaymentReservationConfirm(ValueDate: Date; var ShouldShowPaymentReservationConfirm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustomerLedgerEntryOnAfterValidateSerialNoEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailLine: Record "Detail Line"; ValueDate: Date; PmtDiscExpiryDate: Date; var NumberOfDetailLines: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendorLedgerEntryOnAfterValidateSerialNoEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; var DetailLine: Record "Detail Line"; ValueDate: Date; PmtDiscExpiryDate: Date; var NumberOfDetailLines: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEmployeeLedgerEntryOnAfterValidateSerialNoEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; var DetailLine: Record "Detail Line"; ValueDate: Date; PmtDiscExpiryDate: Date; var NumberOfDetailLines: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordDetailLineOnBeforeCreateProposalLine(var ProposalLine: Record "Proposal Line"; DetailLine: Record "Detail Line"; var Found: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCustLedgerEntryOnBeforePreDataItem(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVendorLedgerEntryOnBeforePreDataItem(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEmployeeLedgerEntryOnBeforePreDataItem(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;
}
