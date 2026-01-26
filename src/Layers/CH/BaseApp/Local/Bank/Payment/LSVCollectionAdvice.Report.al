// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

report 3010838 "LSV Collection Advice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Payment/LSVCollectionAdvice.rdlc';
    Caption = 'LSV Collection Advice';

    dataset
    {
        dataitem(Customer; Customer)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Payment Method Code", "Currency Code";
            column(MessageTxt; MessageTxt)
            {
            }
            column(CompanyAdr6; CompanyAdr[6])
            {
            }
            column(CompanyAdr5; CompanyAdr[5])
            {
            }
            column(CompanyAdr4; CompanyAdr[4])
            {
            }
            column(CompanyInfoCityTodayFormatted; CompanyInfo.City + ', ' + Format(Today, 0, 4))
            {
            }
            column(CustAdr1; CustAdr[1])
            {
            }
            column(CustAdr2; CustAdr[2])
            {
            }
            column(CustAdr3; CustAdr[3])
            {
            }
            column(CompanyAdr3; CompanyAdr[3])
            {
            }
            column(CustAdr4; CustAdr[4])
            {
            }
            column(CustAdr5; CustAdr[5])
            {
            }
            column(CustAdr6; CustAdr[6])
            {
            }
            column(CustAdr7; CustAdr[7])
            {
            }
            column(CustAdr8; CustAdr[8])
            {
            }
            column(CompanyAdr2; CompanyAdr[2])
            {
            }
            column(CompanyAdr1; CompanyAdr[1])
            {
            }
            column(RemainingAmountCaption; RemainingAmountCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(LSVCollectionAdviceCaption; LSVCollectionAdviceCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(TextCaption; TextCaptionLbl)
            {
            }
            column(PosCaption; PosCaptionLbl)
            {
            }
            column(DueCaption; DueCaptionLbl)
            {
            }
            column(CashDiscCaption; CashDiscCaptionLbl)
            {
            }
            column(No_Customer; "No.")
            {
            }
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("LSV No.", "Customer No.");
                column(PostingDateFormatted; Format("Posting Date"))
                {
                }
                column(Description_CustLedgerEntry; Description)
                {
                }
                column(DueDateFormatted; Format("Due Date"))
                {
                }
                column(DocumentNo_CustLedgerEntry; "Document No.")
                {
                }
                column(CollectionAmt; CollectionAmt)
                {
                }
                column(Amount_CustLedgerEntry; Amount)
                {
                }
                column(OriginalPmtDiscPossible; "Remaining Pmt. Disc. Possible")
                {
                }
                column(Pos; Pos)
                {
                }
                column(TotalCollectionAmt; TotalCollectionAmt)
                {
                }
                column(ResponsiblePerson; ResponsiblePerson)
                {
                }
                column(CompanyInfoName; CompanyInfo.Name)
                {
                }
                column(LsvJourCurrencyCode; LsvJour."Currency Code")
                {
                }
                column(BestregardsCaption; BestregardsCaptionLbl)
                {
                }
                column(TotalCollectionCaption; TotalCollectionCaptionLbl)
                {
                }
                column(EntryNo_CustLedgerEntry; "Entry No.")
                {
                }
                dataitem(PartPayment; "Cust. Ledger Entry")
                {
                    DataItemTableView = sorting("Closed by Entry No.");
                    column(DocumentType_PartPayment; "Document Type")
                    {
                    }
                    column(PostingDateFormatted_PartPayment; Format("Posting Date"))
                    {
                    }
                    column(DocumentNo_PartPayment; "Document No.")
                    {
                    }
                    column(AmountLCY_PartPayment; "Amount (LCY)")
                    {
                    }
                    column(Description_PartPayment; Description)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if "Cust. Ledger Entry"."Entry No." > 0 then
                            SetRange("Closed by Entry No.", "Cust. Ledger Entry"."Entry No.")
                        else
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Pos := Pos + 1;
                    NoOfEntries := NoOfEntries + 1;
                    "Cust. Ledger Entry".CalcFields("Remaining Amount");
                    CollectionAmt := "Cust. Ledger Entry"."Remaining Amount" - "Remaining Pmt. Disc. Possible";
                    TotalCollectionAmt := TotalCollectionAmt + CollectionAmt;
                end;

                trigger OnPostDataItem()
                begin
                    if Pos > 0 then
                        NoOfCust := NoOfCust + 1;
                end;

                trigger OnPreDataItem()
                begin
                    "Cust. Ledger Entry".SetCurrentKey("LSV No.", "Customer No.");
                    SetRange("LSV No.", LsvJour."No.");
                    SetRange("Customer No.", Customer."No.");
                    SetRange("Document Type", "Document Type"::Invoice);
                    Clear(CollectionAmt);
                    Pos := 0;

                    // Print only if a certain number of payments per customer
                    if Count < PrintFromNoOfCollPerCust then
                        CurrReport.Break();
                    TotalCollectionAmt := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FormatAdr.Customer(CustAdr, Customer);
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
                    field("LsvJour.""No."""; LsvJour."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'LSV Journal';
                        Editable = false;
                        TableRelation = "LSV Journal";
                        ToolTip = 'Specifies the LSV journal number for which you want to print the report.';
                    }
                    field(PrintFromNoOfCollPerCust; PrintFromNoOfCollPerCust)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print from no. collections per customer';
                        ToolTip = 'Specifies the number of collections that you want to print for each customer.';
                    }
                    field(ResponsiblePerson; ResponsiblePerson)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Person';
                        ToolTip = 'Specifies the person responsible.';
                    }
                    field(MessageTxt; MessageTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Message';
                        MultiLine = true;
                        ToolTip = 'Specifies a message to include on the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            User: Record User;
        begin
            if MessageTxt = '' then
                MessageTxt := Text002;

            if PrintFromNoOfCollPerCust = 0 then
                PrintFromNoOfCollPerCust := 1;

            if (ResponsiblePerson = '') and (UserId <> '') then begin
                User.SetRange("User Name", UserId);
                if User.FindFirst() then
                    ResponsiblePerson := User."Full Name";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(Text001, NoOfCust, NoOfEntries, LsvJour."No.");
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAdr.Company(CompanyAdr, CompanyInfo);

        GlSetup.Get();
        if GlSetup."LCY Code" = '' then
            GlSetup."LCY Code" := 'CHF';
    end;

    var
        Text001: Label 'Processed collection advice for %1 customers and %2 invoices from LSV journal %3.';
        Text002: Label 'We have adviced our bank to collect the following invoices in the near future.';
        LsvJour: Record "LSV Journal";
        CompanyInfo: Record "Company Information";
        GlSetup: Record "General Ledger Setup";
        FormatAdr: Codeunit "Format Address";
        PrintFromNoOfCollPerCust: Integer;
        ResponsiblePerson: Text[30];
        MessageTxt: Text[250];
        CompanyAdr: array[8] of Text[100];
        CustAdr: array[8] of Text[100];
        Pos: Integer;
        CollectionAmt: Decimal;
        NoOfCust: Integer;
        NoOfEntries: Integer;
        TotalCollectionAmt: Decimal;
        RemainingAmountCaptionLbl: Label 'Remaining Amount';
        AmountCaptionLbl: Label 'Amount';
        DocNoCaptionLbl: Label 'Doc. No.';
        LSVCollectionAdviceCaptionLbl: Label 'LSV Collection Advice';
        DateCaptionLbl: Label 'Date';
        TextCaptionLbl: Label 'Text';
        PosCaptionLbl: Label 'Pos.';
        DueCaptionLbl: Label 'Due';
        CashDiscCaptionLbl: Label 'Cash Disc.';
        BestregardsCaptionLbl: Label 'Best regards,';
        TotalCollectionCaptionLbl: Label 'Total Collection';

    [Scope('OnPrem')]
    procedure DefineJournalName(_LsvJour: Record "LSV Journal")
    begin
        LsvJour := _LsvJour;
    end;
}

