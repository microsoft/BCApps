// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Service.Contract;
using Microsoft.Service.Ledger;
using System.Utilities;

report 5984 "Contract Invoicing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ContractInvoicing.rdlc';
    Caption = 'Contract Invoicing - Test';

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            DataItemTableView = sorting("Bill-to Customer No.", "Contract Type", "Combine Invoices", "Next Invoice Date") where("Contract Type" = const(Contract), Status = const(Signed));
            RequestFilterFields = "Bill-to Customer No.", "Contract No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(InvoiceToDate; Format(InvoiceToDate))
            {
            }
            column(PostingDate; Format(PostingDate))
            {
            }
            column(TblCptnServContractFilters; TableCaption + ': ' + ServContractFilters)
            {
            }
            column(ServContractFilters; ServContractFilters)
            {
            }
            column(ContractInvoicingTestCaption; ContractInvoicingTestCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(InvoiceToDateCaption; InvoiceToDateCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(InvoicePeriodCaption; InvoicePeriodCaptionLbl)
            {
            }
            column(NoofInvoicesCaption; NoofInvoicesCaptionLbl)
            {
            }
            column(LastInvDateCaption; LastInvDateCaptionLbl)
            {
            }
            column(NextInvDateCaption; NextInvDateCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(AmountPerPeriodCaption; AmountPerPeriodCaptionLbl)
            {
            }
            column(ContractNoCaption; ContractNoCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
            }
            dataitem(ContrHeader; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CustNo_ServContract; "Service Contract Header"."Customer No.")
                {
                }
                column(Name_ServContract; "Service Contract Header".Name)
                {
                }
                column(ContractNo1_ServContract; "Service Contract Header"."Contract No.")
                {
                }
                column(InvPeriod_ServContract; "Service Contract Header"."Invoice Period")
                {
                }
                column(AmtPerPeriod_ServContract; "Service Contract Header"."Amount per Period")
                {
                }
                column(NoOfInvoices; NoOfInvoices)
                {
                    AutoFormatType = 1;
                }
                column(LastInvDate_ServContract; Format("Service Contract Header"."Last Invoice Date"))
                {
                }
                column(NextInvDate_ServContract; Format("Service Contract Header"."Next Invoice Date"))
                {
                }
                column(IndicatorValue; '1')
                {
                }
            }
            dataitem(InvPeriod; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ContractInvPeriod; TempServiceLedgerEntry."Contract Invoice Period")
                {
                }
                column(ServLedgEntryAmt; TempServiceLedgerEntry.Amount)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        TempServiceLedgerEntry.FindSet()
                    else
                        TempServiceLedgerEntry.Next();
                    if (TempServiceLedgerEntry."Posting Date" < "Service Contract Header"."Next Invoice Date") and
                        ("Service Contract Header".Prepaid) and
                        (not ("Service Contract Header"."Invoice Period" = "Service Contract Header"."Invoice Period"::Year)) then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempServiceLedgerEntry.Count);
                end;
            }
            dataitem(ContrSum; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(InvSum; InvoiceSum)
                {
                }
                column(InvoiceTotalCaption; InvoiceTotalCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Starting Date" = 0D then
                    CurrReport.Skip();
                InvoiceSum := 0;
                CalcFields(Name);
                BuildInvoicePlan("Service Contract Header");
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if PostingDate = 0D then
                    Error(Text000);

                if PostingDate > WorkDate() then
                    if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                        Error(Text002);

                if InvoiceToDate = 0D then
                    Error(Text003);

                if InvoiceToDate > WorkDate() then
                    if not ConfirmManagement.GetResponseOrDefault(Text004, true) then
                        Error(Text002);

                Currency.InitRoundingPrecision();

                SetFilter("Next Invoice Date", '<>%1&<=%2', 0D, InvoiceToDate);
                if GetFilter("Invoice Period") <> '' then
                    SetFilter("Invoice Period", GetFilter("Invoice Period") + '&<>%1', "Invoice Period"::None)
                else
                    SetFilter("Invoice Period", '<>%1', "Invoice Period"::None);

                OnAfterServiceContractHeaderOnPreDataItem("Service Contract Header", PostingDate, InvoiceToDate);

                DateSep := '..';
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Contract Invoicing - Test';
        AboutText = 'Find service contracts that are due for invoicing up to a date that you specify.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate1; PostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the posting date on the service invoices that are created.';
                    }
                    field(InvoiceDate1; InvoiceToDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Invoice to Date';
                        ToolTip = 'Specifies the date up to which you want to invoice contracts. The report includes contracts with the next invoice dates on or before this date.';
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
        if PostingDate = 0D then
            PostingDate := WorkDate();
    end;

    trigger OnPreReport()
    begin
        ServContractFilters := "Service Contract Header".GetFilters();
    end;

    var
        Currency: Record Currency;
        TempServiceLedgerEntry: Record "Service Ledger Entry" temporary;
        ServContractMgt: Codeunit ServContractManagement;
        ServContractFilters: Text;
        NoOfInvoices: Integer;
        PostingDate: Date;
        InvoiceToDate: Date;
        InvoiceFrom: Date;
        InvoiceTo: Date;
        EntryNo: Integer;
        DateSep: Text[10];
        InvoiceSum: Decimal;

#pragma warning disable AA0074
        Text000: Label 'You have not filled in the posting date.';
        Text001: Label 'The posting date is later than the work date.\\Confirm that this is the correct date.';
        Text002: Label 'The program has stopped the batch job at your request.';
        Text003: Label 'You must fill in the Invoice-to Date field.';
        Text004: Label 'The Invoice-to Date is later than the work date.\\Confirm that this is the correct date.';
#pragma warning restore AA0074
        ContractInvoicingTestCaptionLbl: Label 'Contract Invoicing - Test';
        PageNoCaptionLbl: Label 'Page';
        InvoiceToDateCaptionLbl: Label 'Invoice to Date';
        PostingDateCaptionLbl: Label 'Posting Date';
        InvoicePeriodCaptionLbl: Label 'Invoice Period';
        NoofInvoicesCaptionLbl: Label 'No. of Invoices';
        LastInvDateCaptionLbl: Label 'Last Inv. Date';
        NextInvDateCaptionLbl: Label 'Next Invoice Date';
        DescriptionCaptionLbl: Label 'Expected invoice amount';
        AmountPerPeriodCaptionLbl: Label 'Amount per Period';
        ContractNoCaptionLbl: Label 'Contract No.';
        NameCaptionLbl: Label 'Name';
        CustomerNoCaptionLbl: Label 'Customer No.';
        InvoiceTotalCaptionLbl: Label 'Invoice Total';

    procedure InitVariables(LocalPostingDate: Date; LocalInvoiceToDate: Date)
    begin
        PostingDate := LocalPostingDate;
        InvoiceToDate := LocalInvoiceToDate;
    end;

    local procedure BuildInvoicePlan(ServContrHeader: Record "Service Contract Header")
    var
        DateFormula: DateFormula;
        InvoicePeriod: Code[10];
        Stop: Boolean;
    begin
        TempServiceLedgerEntry.DeleteAll();
        InvoicePeriod := ServContractMgt.GetInvoicePeriodText(ServContrHeader."Invoice Period");
        Evaluate(DateFormula, InvoicePeriod);
        EntryNo := 0;
        InvoiceFrom := ServContrHeader."Next Invoice Period Start";
        InvoiceTo := CalcDate(DateFormula, InvoiceFrom);
        InvoiceTo := CalcDate('<-CM-1D>', InvoiceTo);
        OnAfterSetInvoiceDates(ServContrHeader, InvoiceFrom, InvoiceTo);
        if ServContrHeader."Expiration Date" <> 0D then
            InvoiceTo := FirstDate(InvoiceTo, ServContrHeader."Expiration Date");
        InsertServLedgEntry(InvoiceFrom, InvoiceTo);
        Stop := false;
        while (InvoiceFrom <= InvoiceToDate) and (not Stop) do begin
            InvoiceFrom := CalcDate('<1D>', InvoiceTo);
            InvoiceTo := CalcDate(DateFormula, InvoiceFrom);
            InvoiceTo := CalcDate('<-CM-1D>', InvoiceTo);
            if ServContrHeader."Expiration Date" <> 0D then
                InvoiceTo := FirstDate(InvoiceTo, ServContrHeader."Expiration Date");
            if InvoiceFrom <= InvoiceToDate then
                InsertServLedgEntry(InvoiceFrom, InvoiceTo);
            if (InvoiceTo = ServContrHeader."Expiration Date") or (InvoiceTo >= InvoiceToDate) then
                Stop := true;
        end;
    end;

    local procedure FirstDate(Date1: Date; Date2: Date): Date
    begin
        if Date1 < Date2 then
            exit(Date1);

        exit(Date2);
    end;

    local procedure InsertServLedgEntry(DateFrom: Date; DateTo: Date)
    begin
        EntryNo += 1;
        TempServiceLedgerEntry.Init();
        TempServiceLedgerEntry."Entry No." := EntryNo;
        TempServiceLedgerEntry."Posting Date" := DateFrom;
        TempServiceLedgerEntry."Contract Invoice Period" := Format(DateFrom) + DateSep + Format(DateTo);
        TempServiceLedgerEntry.Amount := CalcContrAmt("Service Contract Header", DateFrom, DateTo);
        if (DateFrom >= "Service Contract Header"."Next Invoice Date") or
            ((not "Service Contract Header".Prepaid) and
            ("Service Contract Header"."Invoice Period" = "Service Contract Header"."Invoice Period"::Year)) then
            InvoiceSum := InvoiceSum + TempServiceLedgerEntry.Amount;
        TempServiceLedgerEntry.Insert();
    end;

    local procedure CalcContrAmt(ServContHeader: Record "Service Contract Header"; DateFrom: Date; DateTo: Date): Decimal
    var
        ServContractLine: Record "Service Contract Line";
        ContAmt: Decimal;
    begin
        Clear(ServContractLine);
        ServContractLine.SetRange("Contract Type", ServContHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContHeader."Contract No.");
        ContAmt := 0;
        if ServContractLine.FindSet() then
            repeat
                ContAmt := ContAmt + Round(ServContractMgt.CalcContractLineAmount(ServContractLine."Line Amount", DateFrom, DateTo));
            until ServContractLine.Next() = 0;
        exit(Round(ContAmt));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInvoiceDates(var ServiceContractHeader: Record "Service Contract Header"; var InvoiceFrom: Date; var InvoiceTo: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceContractHeaderOnPreDataItem(var ServiceContractHeader: Record "Service Contract Header"; PostingDate: Date; InvoiceToDate: Date)
    begin
    end;
}

