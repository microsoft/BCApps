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

report 7000000 "Bill Group Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Receivables/BillGroupListing.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bill Group Listing';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(BillGr; "Bill Group")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(BillGr_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(BillGr__No__; BillGr."No.")
                    {
                    }
                    column(STRSUBSTNO_Text1100003_CopyText_; StrSubstNo(Text1100003, CopyText))
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(BillGr__Posting_Date_; Format(BillGr."Posting Date"))
                    {
                    }
                    column(BankAccAddr_4_; BankAccAddr[4])
                    {
                    }
                    column(BankAccAddr_5_; BankAccAddr[5])
                    {
                    }
                    column(BankAccAddr_6_; BankAccAddr[6])
                    {
                    }
                    column(BankAccAddr_7_; BankAccAddr[7])
                    {
                    }
                    column(BankAccAddr_3_; BankAccAddr[3])
                    {
                    }
                    column(BankAccAddr_2_; BankAccAddr[2])
                    {
                    }
                    column(BankAccAddr_1_; BankAccAddr[1])
                    {
                    }
                    column(BillGr__Currency_Code_; BillGr."Currency Code")
                    {
                    }
                    column(Operation; Operation)
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
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(BillGr__No__Caption; BillGr__No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                    {
                    }
                    column(BillGr__Posting_Date_Caption; BillGr__Posting_Date_CaptionLbl)
                    {
                    }
                    column(BillGr__Currency_Code_Caption; BillGr__Currency_Code_CaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    dataitem("Cartera Doc."; "Cartera Doc.")
                    {
                        DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                        DataItemLinkReference = BillGr;
                        DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Receivable));
                        column(BillGrAmount; BillGrAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(BillGrAmount_Control23; BillGrAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Cust_City; Cust.City)
                        {
                        }
                        column(Cust_County; Cust.County)
                        {
                        }
                        column(Cust__Post_Code_; Cust."Post Code")
                        {
                        }
                        column(Cust_Name; Cust.Name)
                        {
                        }
                        column(Cartera_Doc___Account_No__; "Account No.")
                        {
                        }
                        column(Cartera_Doc___Document_No__; "Document No.")
                        {
                        }
                        column(Cartera_Doc___Due_Date_; Format("Due Date"))
                        {
                        }
                        column(Cartera_Doc___Document_Type_; "Document Type")
                        {
                        }
                        column(Cartera_Doc____Document_Type______Cartera_Doc____Document_Type___Bill; "Document Type" <> "Document Type"::Bill)
                        {
                        }
                        column(Cust_Name_Control28; Cust.Name)
                        {
                        }
                        column(Cust_City_Control30; Cust.City)
                        {
                        }
                        column(BillGrAmount_Control31; BillGrAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Cust_County_Control35; Cust.County)
                        {
                        }
                        column(Cartera_Doc___Document_No___Control3; "Document No.")
                        {
                        }
                        column(Cartera_Doc___No__; "No.")
                        {
                        }
                        column(Cust__Post_Code__Control9; Cust."Post Code")
                        {
                        }
                        column(Cartera_Doc___Due_Date__Control8; Format("Due Date"))
                        {
                        }
                        column(Cartera_Doc___Account_No___Control1; "Account No.")
                        {
                        }
                        column(Cartera_Doc___Document_Type__Control66; "Document Type")
                        {
                        }
                        column(Cartera_Doc____Document_Type_____Cartera_Doc____Document_Type___Bill; "Document Type" = "Document Type"::Bill)
                        {
                        }
                        column(BillGrAmount_Control36; BillGrAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(BillGrAmount_Control39; BillGrAmount)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Cartera_Doc__Type; Type)
                        {
                        }
                        column(Cartera_Doc__Entry_No_; "Entry No.")
                        {
                        }
                        column(Cartera_Doc__Bill_Gr__Pmt__Order_No_; "Bill Gr./Pmt. Order No.")
                        {
                        }
                        column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
                        {
                        }
                        column(Cartera_Doc___Account_No___Control1Caption; Cartera_Doc___Account_No___Control1CaptionLbl)
                        {
                        }
                        column(Cust_Name_Control28Caption; Cust_Name_Control28CaptionLbl)
                        {
                        }
                        column(Cust__Post_Code__Control9Caption; Cust__Post_Code__Control9CaptionLbl)
                        {
                        }
                        column(Cust_City_Control30Caption; Cust_City_Control30CaptionLbl)
                        {
                        }
                        column(BillGrAmount_Control31Caption; BillGrAmount_Control31CaptionLbl)
                        {
                        }
                        column(Cust_County_Control35Caption; Cust_County_Control35CaptionLbl)
                        {
                        }
                        column(Cartera_Doc___Due_Date__Control8Caption; Cartera_Doc___Due_Date__Control8CaptionLbl)
                        {
                        }
                        column(Bill_No_Caption; Bill_No_CaptionLbl)
                        {
                        }
                        column(Document_No_Caption; Document_No_CaptionLbl)
                        {
                        }
                        column(Cartera_Doc___Document_Type__Control66Caption; FieldCaption("Document Type"))
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(EmptyStringCaption; EmptyStringCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control15; ContinuedCaption_Control15Lbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Cust.Get("Account No.");

                            if PrintAmountsInLCY then
                                BillGrAmount := "Remaining Amt. (LCY)"
                            else
                                BillGrAmount := "Remaining Amount";
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(BillGrAmount);
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then
                        CopyText := Text1100002;
                    OutputNo := OutputNo + 1;
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

                BankAcc.Get(BillGr."Bank Account No.");
                FormatAddress.FormatAddr(
                  BankAccAddr, BankAcc.Name, BankAcc."Name 2", '', BankAcc.Address, BankAcc."Address 2",
                  BankAcc.City, BankAcc."Post Code", BankAcc.County, BankAcc."Country/Region Code");

                if not CurrReport.Preview then
                    PrintCounter.PrintCounter(DATABASE::"Bill Group", "No.");
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
                        Caption = 'Show Amounts in LCY';
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
        Cust: Record Customer;
        FormatAddress: Codeunit "Format Address";
        PrintCounter: Codeunit "BG/PO-Post and Print";
        BankAccAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        Operation: Text[80];
        NoOfLoops: Integer;
        NoOfCopies: Integer;
        CopyText: Text[30];
        PrintAmountsInLCY: Boolean;
        BillGrAmount: Decimal;
        FactoringType: Text[30];
        OutputNo: Integer;
        BillGr__No__CaptionLbl: Label 'Bill Group No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        BillGr__Posting_Date_CaptionLbl: Label 'Date';
        BillGr__Currency_Code_CaptionLbl: Label 'Currency Code';
        PageCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        Cartera_Doc___Account_No___Control1CaptionLbl: Label 'Customer No.';
        Cust_Name_Control28CaptionLbl: Label 'Name';
        Cust__Post_Code__Control9CaptionLbl: Label 'Post Code';
        Cust_City_Control30CaptionLbl: Label 'City /';
        BillGrAmount_Control31CaptionLbl: Label 'Remaining Amount';
        Cust_County_Control35CaptionLbl: Label 'County';
        Cartera_Doc___Due_Date__Control8CaptionLbl: Label 'Due Date';
        Bill_No_CaptionLbl: Label 'Bill No.';
        Document_No_CaptionLbl: Label 'Document No.';
        ContinuedCaptionLbl: Label 'Continued';
        EmptyStringCaptionLbl: Label '/', Locked = true;
        ContinuedCaption_Control15Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if PrintAmountsInLCY then
            exit('');

        exit("Cartera Doc."."Currency Code");
    end;

    [Scope('OnPrem')]
    procedure GetFactoringType(): Text[30]
    begin
        if BillGr.Factoring <> BillGr.Factoring::" " then begin
            if BillGr.Factoring = BillGr.Factoring::Risked then
                exit(Text1100005);

            exit(Text1100006);
        end;
    end;
}

