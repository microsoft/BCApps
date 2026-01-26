// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 7000011 "Posted Payment Order Listing"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/History/PostedPaymentOrderListing.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Payment Order Listing';
    Permissions = TableData "Posted Payment Order" = r;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(PostedPmtOrd; "Posted Payment Order")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(PostedPmtOrd_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(PostedPmtOrd__No__; PostedPmtOrd."No.")
                    {
                    }
                    column(STRSUBSTNO_Text1100001_CopyText_; StrSubstNo(Text1100001, CopyText))
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
                    column(PostedPmtOrd__Posting_Date_; Format(PostedPmtOrd."Posting Date"))
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
                    column(PostedPmtOrd__Currency_Code_; PostedPmtOrd."Currency Code")
                    {
                    }
                    column(PrintAmountsInLCY; PrintAmountsInLCY)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(PostedPmtOrd__No__Caption; PostedPmtOrd__No__CaptionLbl)
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
                    column(PostedPmtOrd__Posting_Date_Caption; PostedPmtOrd__Posting_Date_CaptionLbl)
                    {
                    }
                    column(PostedPmtOrd__Currency_Code_Caption; PostedPmtOrd__Currency_Code_CaptionLbl)
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    dataitem(PostedDoc; "Posted Cartera Doc.")
                    {
                        DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                        DataItemLinkReference = PostedPmtOrd;
                        DataItemTableView = sorting("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date") where("Collection Agent" = const(Bank), Type = const(Payable));
                        column(AmtForCollection; AmtForCollection)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtForCollection_Control32; AmtForCollection)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Vendor_City; Vendor.City)
                        {
                        }
                        column(Vendor_County; Vendor.County)
                        {
                        }
                        column(Vendor__Post_Code_; Vendor."Post Code")
                        {
                        }
                        column(Vendor_Name; Vendor.Name)
                        {
                        }
                        column(PostedDoc__Account_No__; "Account No.")
                        {
                        }
                        column(PostedDoc__Honored_Rejtd__at_Date_; "Honored/Rejtd. at Date")
                        {
                        }
                        column(PostedDoc_Status; Status)
                        {
                        }
                        column(PostedDoc__Document_No__; "Document No.")
                        {
                        }
                        column(PostedDoc__Document_Type_; "Document Type")
                        {
                        }
                        column(PostedDoc__Due_Date_; Format("Due Date"))
                        {
                        }
                        column(Vendor_Name_Control28; Vendor.Name)
                        {
                        }
                        column(Vendor_City_Control30; Vendor.City)
                        {
                        }
                        column(AmtForCollection_Control31; AmtForCollection)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Vendor_County_Control35; Vendor.County)
                        {
                        }
                        column(PostedDoc__Document_No___Control3; "Document No.")
                        {
                        }
                        column(PostedDoc__No__; "No.")
                        {
                        }
                        column(Vendor__Post_Code__Control9; Vendor."Post Code")
                        {
                        }
                        column(PostedDoc_Status_Control78; Status)
                        {
                        }
                        column(PostedDoc__Honored_Rejtd__at_Date__Control80; "Honored/Rejtd. at Date")
                        {
                        }
                        column(PostedDoc__Due_Date__Control8; Format("Due Date"))
                        {
                        }
                        column(PostedDoc__Account_No___Control1; "Account No.")
                        {
                        }
                        column(PostedDoc__Document_Type__Control23; "Document Type")
                        {
                        }
                        column(AmtForCollection_Control36; AmtForCollection)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmtForCollection_Control39; AmtForCollection)
                        {
                            AutoFormatExpression = GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(PostedDoc_Type; Type)
                        {
                        }
                        column(PostedDoc_Entry_No_; "Entry No.")
                        {
                        }
                        column(PostedDoc_Bill_Gr__Pmt__Order_No_; "Bill Gr./Pmt. Order No.")
                        {
                        }
                        column(All_amounts_are_in_LCYCaption; All_amounts_are_in_LCYCaptionLbl)
                        {
                        }
                        column(Document_No_Caption; Document_No_CaptionLbl)
                        {
                        }
                        column(Bill_No_Caption; Bill_No_CaptionLbl)
                        {
                        }
                        column(Vendor_Name_Control28Caption; Vendor_Name_Control28CaptionLbl)
                        {
                        }
                        column(Vendor__Post_Code__Control9Caption; Vendor__Post_Code__Control9CaptionLbl)
                        {
                        }
                        column(Vendor_City_Control30Caption; Vendor_City_Control30CaptionLbl)
                        {
                        }
                        column(AmtForCollection_Control31Caption; AmtForCollection_Control31CaptionLbl)
                        {
                        }
                        column(Vendor_County_Control35Caption; Vendor_County_Control35CaptionLbl)
                        {
                        }
                        column(PostedDoc_Status_Control78Caption; FieldCaption(Status))
                        {
                        }
                        column(PostedDoc__Honored_Rejtd__at_Date__Control80Caption; FieldCaption("Honored/Rejtd. at Date"))
                        {
                        }
                        column(PostedDoc__Due_Date__Control8Caption; PostedDoc__Due_Date__Control8CaptionLbl)
                        {
                        }
                        column(PostedDoc__Account_No___Control1Caption; PostedDoc__Account_No___Control1CaptionLbl)
                        {
                        }
                        column(PostedDoc__Document_Type__Control23Caption; FieldCaption("Document Type"))
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
                            Vendor.Get("Account No.");
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
                    if Number > 1 then
                        CopyText := Text1100000;
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
                BankAcc.Get(PostedPmtOrd."Bank Account No.");
                FormatAddress.FormatAddr(
                  BankAccAddr, BankAcc.Name, BankAcc."Name 2", '', BankAcc.Address, BankAcc."Address 2",
                  BankAcc.City, BankAcc."Post Code", BankAcc.County, BankAcc."Country/Region Code");
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
        Text1100000: Label 'COPY';
        Text1100001: Label 'Payment Order %1';
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
        Vendor: Record Vendor;
        FormatAddress: Codeunit "Format Address";
        BankAccAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        NoOfLoops: Integer;
        NoOfCopies: Integer;
        CopyText: Text[30];
        PrintAmountsInLCY: Boolean;
        AmtForCollection: Decimal;
        OutputNo: Integer;
        PostedPmtOrd__No__CaptionLbl: Label 'Payment Order No.';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        PostedPmtOrd__Posting_Date_CaptionLbl: Label 'Date';
        PostedPmtOrd__Currency_Code_CaptionLbl: Label 'Currency Code';
        PageCaptionLbl: Label 'Page';
        All_amounts_are_in_LCYCaptionLbl: Label 'All amounts are in LCY';
        Document_No_CaptionLbl: Label 'Document No.';
        Bill_No_CaptionLbl: Label 'Bill No.';
        Vendor_Name_Control28CaptionLbl: Label 'Name';
        Vendor__Post_Code__Control9CaptionLbl: Label 'Post Code';
        Vendor_City_Control30CaptionLbl: Label 'City /';
        AmtForCollection_Control31CaptionLbl: Label 'Amount for Collection';
        Vendor_County_Control35CaptionLbl: Label 'County';
        PostedDoc__Due_Date__Control8CaptionLbl: Label 'Due Date';
        PostedDoc__Account_No___Control1CaptionLbl: Label 'Vendor No.';
        ContinuedCaptionLbl: Label 'Continued';
        EmptyStringCaptionLbl: Label '/', Locked = true;
        ContinuedCaption_Control15Lbl: Label 'Continued';
        TotalCaptionLbl: Label 'Total';

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if PrintAmountsInLCY then
            exit('');

        exit(PostedDoc."Currency Code");
    end;
}

