// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System.Utilities;

report 7000002 "Closed Bill Group Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Receivables/ClosedBillGroupListing.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Closed Bill Group Listing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ClosedBillGr; "Closed Bill Group")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(No_ClosedBillGr; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(Operation; Operation)
                    {
                    }
                    column(CopyText; StrSubstNo(Text1100003, CopyText))
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(ClosedBillGrPostingDate; Format(ClosedBillGr."Posting Date"))
                    {
                    }
                    column(BankAccAddr4; BankAccAddr[4])
                    {
                    }
                    column(BankAccAddr5; BankAccAddr[5])
                    {
                    }
                    column(BankAccAddr6; BankAccAddr[6])
                    {
                    }
                    column(BankAccAddr7; BankAccAddr[7])
                    {
                    }
                    column(BankAccAddr3; BankAccAddr[3])
                    {
                    }
                    column(BankAccAddr2; BankAccAddr[2])
                    {
                    }
                    column(BankAccAddr1; BankAccAddr[1])
                    {
                    }
                    column(ClosedBillGrCurrencyCode; ClosedBillGr."Currency Code")
                    {
                    }
                    column(FactoringType; FactoringType)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                    }
                    column(BillGroupNoCaption; BillGroupNoCaptionLbl)
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(FaxNoCaption; FaxNoCaptionLbl)
                    {
                    }
                    column(VATRegistrationNoCaption; VATRegistrationNoCaptionLbl)
                    {
                    }
                    column(DateCaption; DateCaptionLbl)
                    {
                    }
                    column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    dataitem(ClosedDoc; "Closed Cartera Doc.")
                    {
                        DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                        DataItemLinkReference = ClosedBillGr;
                        DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Receivable));
                        column(AmtForCollection; AmtForCollection)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(CustomerCity; Customer.City)
                        {
                        }
                        column(CustomerCounty; Customer.County)
                        {
                        }
                        column(CustomerPostCode; Customer."Post Code")
                        {
                        }
                        column(CustomerName; Customer.Name)
                        {
                        }
                        column(AccountNo_ClosedDoc; "Account No.")
                        {
                        }
                        column(HonoredRejtdatDate_ClosedDoc; Format("Honored/Rejtd. at Date"))
                        {
                        }
                        column(Status_ClosedDoc; Status)
                        {
                        }
                        column(DocumentNo_ClosedDoc; "Document No.")
                        {
                        }
                        column(DocumentType_ClosedDoc; "Document Type")
                        {
                        }
                        column(DueDate_ClosedDoc; Format("Due Date"))
                        {
                        }
                        column(ClosedDocDocTypeNotBill; ClosedDoc."Document Type" <> ClosedDoc."Document Type"::Bill)
                        {
                        }
                        column(No_ClosedDoc; "No.")
                        {
                        }
                        column(ClosedDocDocTypeBill; ClosedDoc."Document Type" = ClosedDoc."Document Type"::Bill)
                        {
                        }
                        column(Type_ClosedDoc; Type)
                        {
                        }
                        column(EntryNo_ClosedDoc; "Entry No.")
                        {
                        }
                        column(BillGrPmtOrderNo_ClosedDoc; "Bill Gr./Pmt. Order No.")
                        {
                        }
                        column(AllAmtareinLCYCaption; AllAmtareinLCYCaptionLbl)
                        {
                        }
                        column(DocumentNoCaption; DocumentNoCaptionLbl)
                        {
                        }
                        column(BillNoCaption; BillNoCaptionLbl)
                        {
                        }
                        column(NameCaption; NameCaptionLbl)
                        {
                        }
                        column(PostCodeCaption; PostCodeCaptionLbl)
                        {
                        }
                        column(CityCaption; CityCaptionLbl)
                        {
                        }
                        column(AmtForCollectioCaption; AmtForCollectioCaptionLbl)
                        {
                        }
                        column(CountyCaption; CountyCaptionLbl)
                        {
                        }
                        column(StatusCaption_ClosedDoc; FieldCaption(Status))
                        {
                        }
                        column(HonoredRejtdatDateCaption; HonoredRejtdatDateCaptionLbl)
                        {
                        }
                        column(DueDateCaption; DueDateCaptionLbl)
                        {
                        }
                        column(CustomerNoCaption; CustomerNoCaptionLbl)
                        {
                        }
                        column(DocTypeCaption_ClosedDoc; FieldCaption("Document Type"))
                        {
                        }
                        column(EmptyStringCaption; EmptyStringCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Customer.Get("Account No.");
                            if PrintAmountsInLCY then
                                AmtForCollection := "Amt. for Collection (LCY)"
                            else
                                AmtForCollection := "Amount for Collection";
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(AmtForCollection);
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text1100002;
                        OutputNo := OutputNo + 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Dealing Type" = "Dealing Type"::Discount then
                    Operation := Text1100000
                else
                    Operation := Text1100001;
                FactoringType := GetFactoringType();

                BankAcc.Get(ClosedBillGr."Bank Account No.");
                FormatAddress.FormatAddr(
                  BankAccAddr, BankAcc.Name, BankAcc."Name 2", '', BankAcc.Address, BankAcc."Address 2",
                  BankAcc.City, BankAcc."Post Code", BankAcc.County, BankAcc."Country/Region Code");

                if not CurrReport.Preview then
                    PrintCounter.PrintCounter(DATABASE::"Closed Bill Group", "No.");
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddress.Company(CompanyAddr, CompanyInfo);
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
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

    var
        Text1100000: Label 'For Discount';
        Text1100001: Label 'For Collection';
        Text1100002: Label 'COPY';
        Text1100003: Label 'Bill Group %1';
        Text1100005: Label 'Risked Factoring';
        Text1100006: Label 'Unrisked Factoring';
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
        Customer: Record Customer;
        FormatAddress: Codeunit "Format Address";
        PrintCounter: Codeunit "BG/PO-Post and Print";
        BankAccAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        Operation: Text[80];
        NoOfLoops: Integer;
        NoOfCopies: Integer;
        CopyText: Text[30];
        PrintAmountsInLCY: Boolean;
        AmtForCollection: Decimal;
        FactoringType: Text[30];
        OutputNo: Integer;
        BillGroupNoCaptionLbl: Label 'Bill Group No.';
        PhoneNoCaptionLbl: Label 'Phone No.';
        FaxNoCaptionLbl: Label 'Fax No.';
        VATRegistrationNoCaptionLbl: Label 'VAT Reg. No.';
        DateCaptionLbl: Label 'Date';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        PageCaptionLbl: Label 'Page';
        AllAmtareinLCYCaptionLbl: Label 'All amounts are in LCY';
        DocumentNoCaptionLbl: Label 'Document No.';
        BillNoCaptionLbl: Label 'Bill No.';
        NameCaptionLbl: Label 'Name';
        PostCodeCaptionLbl: Label 'Post Code';
        CityCaptionLbl: Label 'City /';
        AmtForCollectioCaptionLbl: Label 'Amount for Collection';
        CountyCaptionLbl: Label 'County';
        HonoredRejtdatDateCaptionLbl: Label 'Honored/Rejtd. at Date';
        DueDateCaptionLbl: Label 'Due Date';
        CustomerNoCaptionLbl: Label 'Customer No.';
        EmptyStringCaptionLbl: Label '/', Locked = true;
        TotalCaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if PrintAmountsInLCY then
            exit('')
        else
            exit(ClosedDoc."Currency Code");
    end;

    [Scope('OnPrem')]
    procedure GetFactoringType(): Text[30]
    begin
        if ClosedBillGr.Factoring <> ClosedBillGr.Factoring::" " then
            if ClosedBillGr.Factoring = ClosedBillGr.Factoring::Risked then
                exit(Text1100005)
            else
                exit(Text1100006);
    end;
}

