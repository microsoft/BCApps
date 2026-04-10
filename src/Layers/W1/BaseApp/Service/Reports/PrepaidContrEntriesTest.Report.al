// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Service.Contract;
using Microsoft.Service.Ledger;
using System.Utilities;

report 5986 "Prepaid Contr. Entries - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/PrepaidContrEntriesTest.rdlc';
    Caption = 'Prepaid Contr. Entries - Test';

    dataset
    {
        dataitem("Service Ledger Entry"; "Service Ledger Entry")
        {
            DataItemTableView = sorting("Service Contract No.", "Entry No.", "Entry Type", Type, "Moved from Prepaid Acc.", "Posting Date", Open, Prepaid) where(Type = const("Service Contract"), "Moved from Prepaid Acc." = const(false), Open = const(false));
            RequestFilterFields = "Service Contract No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Service_Ledger_Entry__User_ID_; "User ID")
            {
            }
            column(PostingDate; Format(PostingDate))
            {
            }
            column(UntilDate; Format(UntilDate))
            {
            }
            column(Service_Ledger_Entry__TABLECAPTION__________ServLedgerFilters; TableCaption + ': ' + ServLedgerFilters)
            {
            }
            column(ServLedgerFilters; ServLedgerFilters)
            {
            }
            column(Service_Ledger_Entry__Service_Contract_No__; "Service Contract No.")
            {
            }
            column(Service_Ledger_Entry__Serial_No___Serviced__; "Serial No. (Serviced)")
            {
            }
            column(Service_Ledger_Entry__Posting_Date_; Format("Posting Date"))
            {
            }
            column(Service_Ledger_Entry__Serv__Contract_Acc__Gr__Code_; "Serv. Contract Acc. Gr. Code")
            {
            }
            column(Service_Ledger_Entry__Amount__LCY__; "Amount (LCY)")
            {
            }
            column(Service_Ledger_Entry__Amount__LCY___Control7; "Amount (LCY)")
            {
            }
            column(Service_Ledger_Entry_Entry_No_; "Entry No.")
            {
            }
            column(Prepaid_Contract_Entries___TestCaption; Prepaid_Contract_Entries___TestCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(UntilDateCaption; UntilDateCaptionLbl)
            {
            }
            column(Service_Ledger_Entry__Service_Contract_No__Caption; FieldCaption("Service Contract No."))
            {
            }
            column(Service_Ledger_Entry__Serial_No___Serviced__Caption; FieldCaption("Serial No. (Serviced)"))
            {
            }
            column(Service_Ledger_Entry__Posting_Date_Caption; Service_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Service_Ledger_Entry__Serv__Contract_Acc__Gr__Code_Caption; FieldCaption("Serv. Contract Acc. Gr. Code"))
            {
            }
            column(Service_Ledger_Entry__Amount__LCY__Caption; FieldCaption("Amount (LCY)"))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem(ErrorLoop; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending);
                column(ErrorText; ErrorText)
                {
                }
                column(Warning_Caption; Warning_CaptionLbl)
                {
                }

                trigger OnPostDataItem()
                begin
                    ErrorCounter := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ErrorCounter);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ServContractHdr.SetFilter("Contract No.", "Service Contract No.");
                if ServContractHdr.FindFirst() then begin
                    ServContractHdr.CalcFields("No. of Unposted Credit Memos");
                    if ServContractHdr."No. of Unposted Credit Memos" <> 0 then
                        AddError(Text002);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if UntilDate = 0D then
                    Error(Text000);
                if PostingDate = 0D then
                    Error(Text001);

                SetRange("Posting Date", 0D, UntilDate);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UntilDate; UntilDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Post until Date';
                        ToolTip = 'Specifies the date up to which you want to post prepaid entries. The report includes service ledger entries with posting dates on or before this date.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the posting date on the service ledger entries.';
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
        ServLedgerFilters := "Service Ledger Entry".GetFilters();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You must fill in the Post Until Date field.';
        Text001: Label 'You must fill in the Posting Date field.';
#pragma warning restore AA0074
        ServContractHdr: Record "Service Contract Header";
        UntilDate: Date;
        PostingDate: Date;
        ErrorText: Text[250];
        ServLedgerFilters: Text;
#pragma warning disable AA0074
        Text002: Label 'There is at least one unposted credit memo linked to this contract.';
#pragma warning restore AA0074
        ErrorCounter: Integer;
        Prepaid_Contract_Entries___TestCaptionLbl: Label 'Prepaid Contract Entries - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        PostingDateCaptionLbl: Label 'Posting Date';
        UntilDateCaptionLbl: Label 'Post until Date';
        Service_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        TotalCaptionLbl: Label 'Total';
        Warning_CaptionLbl: Label 'Warning!';

    procedure InitVariables(LocalUntilDate: Date; LocalPostingDate: Date)
    begin
        UntilDate := LocalUntilDate;
        PostingDate := LocalPostingDate;
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter += 1;
        ErrorText := Text;
    end;
}

