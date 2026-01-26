// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.History;
using System.Utilities;

report 10713 "Purchases - AutoCredit Memo"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/PurchasesAutoCreditMemo.rdlc';
    Caption = 'Purchases - AutoCredit Memo';

    dataset
    {
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
        {
            DataItemTableView = sorting("No.") where("Autocredit Memo No." = filter(<> ''));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Posted Purchase AutoCr. Memo';
            column(Purch__Cr__Memo_Hdr__No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(STRSUBSTNO_Text1100006_CopyText_; StrSubstNo(Text1100006, CopyText))
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
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfo__Bank_Name_; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(FORMAT__Purch__Cr__Memo_Hdr____Document_Date__0_4_; Format("Purch. Cr. Memo Hdr."."Document Date", 0, 4))
                    {
                    }
                    column(Purch__Cr__Memo_Hdr____No__; "Purch. Cr. Memo Hdr."."No.")
                    {
                    }
                    column(AppliedToText; AppliedToText)
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(Purch__Cr__Memo_Hdr____Posting_Date_; Format("Purch. Cr. Memo Hdr."."Posting Date"))
                    {
                    }
                    column(CompanyAddr_1__Control120; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr_2__Control121; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_3__Control122; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_4__Control123; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_5__Control124; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6__Control125; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
                    column(Purch__Cr__Memo_Hdr____Autocredit_Memo_No__; "Purch. Cr. Memo Hdr."."Autocredit Memo No.")
                    {
                    }
                    column(Currency; Currency)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(NoOfCopies; NoOfCopies)
                    {
                    }
                    column(Purch__Cr__Memo_Hdr____Prices_Including_VAT_; "Purch. Cr. Memo Hdr."."Prices Including VAT")
                    {
                    }
                    column(PageLoop_Number; Number)
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
                    column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
                    {
                    }
                    column(Original_Doc__No_Caption; Original_Doc__No_CaptionLbl)
                    {
                    }
                    column(Purch__Cr__Memo_Hdr____Posting_Date_Caption; Purch__Cr__Memo_Hdr____Posting_Date_CaptionLbl)
                    {
                    }
                    column(AutoCredit_Memo_No_Caption; AutoCredit_Memo_No_CaptionLbl)
                    {
                    }
                    column(Currency_CodeCaption; Currency_CodeCaptionLbl)
                    {
                    }
                    dataitem("Purch. Cr. Memo Line"; "Purch. Cr. Memo Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purch. Cr. Memo Hdr.";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Purch__Cr__Memo_Line_Description; Description)
                        {
                        }
                        column(Purch__Cr__Memo_Line__Purch__Cr__Memo_Line___Line_No__; "Purch. Cr. Memo Line"."Line No.")
                        {
                        }
                        column(TotalInvDiscAmount; TotalInvDiscAmount)
                        {
                        }
                        column(TotalVATAmount; TotalVATAmount)
                        {
                        }
                        column(TotalECAmount; TotalECAmount)
                        {
                        }
                        column(TotalAmount; TotalAmount)
                        {
                        }
                        column(TotalPmtDiscRcdAmount; TotalPmtDiscRcdAmount)
                        {
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                        }
                        column(PageCaption; StrSubstNo(Text1100007, ''))
                        {
                        }
                        column(Purch__Cr__Memo_Line__Purch__Cr__Memo_Line__Type; "Purch. Cr. Memo Line".Type)
                        {
                        }
                        column(PurchCrMLineBody3; Type = Type::" ")
                        {
                        }
                        column(DirectUnitCostCaption; GetDirectUnitCostCaption())
                        {
                        }
                        column(Purch__Cr__Memo_Line_Description_Control55; Description)
                        {
                        }
                        column(Purch__Cr__Memo_Line_Quantity; Quantity)
                        {
                        }
                        column(Purch__Cr__Memo_Line__Unit_of_Measure_; "Unit of Measure")
                        {
                        }
                        column(Purch__Cr__Memo_Line__Direct_Unit_Cost_; "Direct Unit Cost")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(Purch__Cr__Memo_Line__Line_Discount___; "Line Discount %")
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control60; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(PurchCrMLineBody4; Type = Type::"G/L Account")
                        {
                        }
                        column(PurchCrMLineBody5; (Type = Type::Item) or (Type = Type::"Fixed Asset"))
                        {
                        }
                        column(Purch__Cr__Memo_Line__No__; "No.")
                        {
                        }
                        column(Purch__Cr__Memo_Line_Description_Control62; Description)
                        {
                        }
                        column(Purch__Cr__Memo_Line_Quantity_Control63; Quantity)
                        {
                        }
                        column(Purch__Cr__Memo_Line__Unit_of_Measure__Control64; "Unit of Measure")
                        {
                        }
                        column(Purch__Cr__Memo_Line__Direct_Unit_Cost__Control65; "Direct Unit Cost")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(Purch__Cr__Memo_Line__Line_Discount____Control66; "Line Discount %")
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control67; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control76; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Inv__Discount_Amount_; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Pmt__Disc__Rcd__Amount_; -"Pmt. Discount Amount")
                        {
                        }
                        column(Purch__Cr__Memo_Line_Amount; Amount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount____VATAmountLine__VAT_Amount_; TotalVATAmount - TotalAmount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Amount_Including_VAT____VATAmountLine__EC_Amount____VATAmountLine__VAT_Amount_; TotalVATAmount - TotalAmount + Amount)
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(Purch__Cr__Memo_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Purch__Cr__Memo_Line__No__Caption; FieldCaption("No."))
                        {
                        }
                        column(Purch__Cr__Memo_Line_Description_Control62Caption; FieldCaption(Description))
                        {
                        }
                        column(Purch__Cr__Memo_Line_Quantity_Control63Caption; FieldCaption(Quantity))
                        {
                        }
                        column(Purch__Cr__Memo_Line__Unit_of_Measure__Control64Caption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Purch__Cr__Memo_Line__Direct_Unit_Cost__Control65Caption; FieldCaption("Direct Unit Cost"))
                        {
                        }
                        column(Purch__Cr__Memo_Line__Line_Discount____Control66Caption; Purch__Cr__Memo_Line__Line_Discount____Control66CaptionLbl)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control67Caption; Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control67CaptionLbl)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_Caption; Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_CaptionLbl)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control76Caption; Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control76CaptionLbl)
                        {
                        }
                        column(Inv__Discount_Amount_Caption; Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(Pmt__Disc__Rcd__Amount_Caption; Pmt__Disc__Rcd__Amount_CaptionLbl)
                        {
                        }
                        column(VAT_EC_AmountCaption; VAT_EC_AmountCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
                                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                                    TotalVATAmount := TotalVATAmount + Amount + (Amount * VATPostingSetup."VAT %") / 100;
                                TotalAmount := TotalAmount + Amount;
                                VATAmountLine.Init();
                                VATAmountLine."VAT Identifier" := "VAT Identifier";
                                VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                                VATAmountLine."Tax Group Code" := "Tax Group Code";
                                VATAmountLine."Use Tax" := "Use Tax";
                                VATAmountLine."Pmt. Discount Amount" := "Pmt. Discount Amount";
                                if "Allow Invoice Disc." then
                                    VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                                VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                                VATAmountLine."VAT %" := VATPostingSetup."VAT %";
                                VATAmountLine."EC %" := VATPostingSetup."EC %";
                                VATAmountLine."VAT Base" := Amount;
                                VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                                VATAmountLine.InsertLine();
                                VATAmountLine."VAT Amount" := (VATAmountLine."Amount Including VAT" * VATAmountLine."VAT %") / 100;
                                VATAmountLine."EC Amount" := (VATAmountLine."Amount Including VAT" * VATAmountLine."EC %") / 100;
                            end else
                                CurrReport.Skip();

                            TotalInvDiscAmount += "Inv. Discount Amount";
                            TotalPmtDiscRcdAmount += "Pmt. Discount Amount";
                            TotalAmountInclVAT += "Amount Including VAT";
                            TotalECAmount += VATAmountLine."EC Amount";
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATAmountLine.DeleteAll();
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLine__VAT_EC_Base_; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount_; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount_; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; VATAmountLine."VAT %")
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control98; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control99; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC___; VATAmountLine."EC %")
                        {
                        }
                        column(VATAmountLine__EC_Amount__Control81; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_EC_Base__Control102; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control103; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount__Control83; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_EC_Base__Control106; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control107; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount__Control88; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Cr. Memo Hdr."."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control98Caption; VATAmountLine__VAT_EC_Base__Control98CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Amount__Control99Caption; VATAmountLine__VAT_Amount__Control99CaptionLbl)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__EC___Caption; VATAmountLine__EC___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__EC_Amount__Control81Caption; VATAmountLine__EC_Amount__Control81CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base_Caption; VATAmountLine__VAT_EC_Base_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control102Caption; VATAmountLine__VAT_EC_Base__Control102CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control106Caption; VATAmountLine__VAT_EC_Base__Control106CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                            VATAmountLine."VAT Amount" := (VATAmountLine."Amount Including VAT" * VATAmountLine."VAT %") / 100;
                            VATAmountLine."EC Amount" := (VATAmountLine."Amount Including VAT" * VATAmountLine."EC %") / 100;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmountLine.Count < 1 then
                                CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Purch__Cr__Memo_Hdr____Buy_from_Vendor_No__; "Purch. Cr. Memo Hdr."."Buy-from Vendor No.")
                        {
                        }
                        column(Total_Number; Number)
                        {
                        }
                        column(Purch__Cr__Memo_Hdr____Buy_from_Vendor_No__Caption; "Purch. Cr. Memo Hdr.".FieldCaption("Buy-from Vendor No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Purch. Cr. Memo Hdr."."Buy-from Vendor No." = "Purch. Cr. Memo Hdr."."Pay-to Vendor No." then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShipToAddr_1_; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr_2_; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr_3_; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr_4_; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr_5_; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr_6_; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr_7_; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr_8_; ShipToAddr[8])
                        {
                        }
                        column(Total2_Number; Number)
                        {
                        }
                        column(Ship_to_AddressCaption; Ship_to_AddressCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if ShipToAddr[1] = '' then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text1100005;
                        OutputNo += 1;
                        TotalInvDiscAmount := 0;
                        TotalPmtDiscRcdAmount := 0;
                        TotalAmount := 0;
                        TotalECAmount := 0;
                        TotalVATAmount := 0;
                        TotalAmountInclVAT := 0;
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
                if "Purchaser Code" = '' then begin
                    SalesPurchPerson.Init();
                    PurchaserText := '';
                end else begin
                    SalesPurchPerson.Get("Purchaser Code");
                    PurchaserText := Text1100001
                end;
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := FieldCaption("VAT Registration No.");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text1100002, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text1100003, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text1100002, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text1100003, "Currency Code");
                end;
                if "Applies-to Doc. No." = '' then
                    AppliedToText := ''
                else
                    AppliedToText := StrSubstNo(Text1100004, "Applies-to Doc. Type", "Applies-to Doc. No.");

                FormatAddr.PurchCrMemoShipTo(ShipToAddr, "Purch. Cr. Memo Hdr.");

                if "Purch. Cr. Memo Hdr."."Currency Code" = '' then
                    Currency := GLSetup."LCY Code"
                else
                    Currency := "Purch. Cr. Memo Hdr."."Currency Code";

                TotalInvDiscAmount := 0;
                TotalPmtDiscRcdAmount := 0;
                TotalAmount := 0;
                TotalECAmount := 0;
                TotalVATAmount := 0;
                TotalAmountInclVAT := 0;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                if CompanyInfo."VAT Registration No." = '' then
                    Error(Text1100000);
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
        GLSetup.Get();
    end;

    var
        Text1100000: Label 'Please, specify the VAT Registration Nº of your Company in the Company information Window';
        Text1100001: Label 'Purchaser';
        Text1100002: Label 'Total %1';
        Text1100003: Label 'Total %1 Incl. VAT+EC';
        Text1100004: Label '(Applies to %1 %2)';
        Text1100005: Label 'COPY';
        Text1100006: Label 'AutoCredit Memo %1';
        Text1100007: Label 'Page %1';
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        VATAmountLine: Record "VAT Amount Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        FormatAddr: Codeunit "Format Address";
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        PurchaserText: Text[30];
        VATNoText: Text[30];
        ReferenceText: Text[30];
        AppliedToText: Text[40];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        Currency: Code[10];
        OutputNo: Integer;
        TotalInvDiscAmount: Decimal;
        TotalPmtDiscRcdAmount: Decimal;
        TotalAmount: Decimal;
        TotalECAmount: Decimal;
        TotalVATAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        Text1100008: Label 'Incl. VAT';
        Text1100009: Label 'Excl. VAT';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        Original_Doc__No_CaptionLbl: Label 'Original Doc. No.';
        Purch__Cr__Memo_Hdr____Posting_Date_CaptionLbl: Label 'Posting Date';
        AutoCredit_Memo_No_CaptionLbl: Label 'AutoCredit Memo No.';
        Currency_CodeCaptionLbl: Label 'Currency Code';
        Purch__Cr__Memo_Line__Line_Discount____Control66CaptionLbl: Label 'Disc. %';
        Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control67CaptionLbl: Label 'Amount';
        Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_CaptionLbl: Label 'Continued';
        Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control76CaptionLbl: Label 'Continued';
        Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        Pmt__Disc__Rcd__Amount_CaptionLbl: Label 'Pmt. Disc. Rcd. Amount';
        VAT_EC_AmountCaptionLbl: Label 'VAT+EC Amount';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_EC_Base__Control98CaptionLbl: Label 'VAT+EC Base';
        VATAmountLine__VAT_Amount__Control99CaptionLbl: Label 'VAT Amount';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__EC___CaptionLbl: Label 'EC %';
        VATAmountLine__EC_Amount__Control81CaptionLbl: Label 'EC Amount';
        VATAmountLine__VAT_EC_Base_CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_EC_Base__Control102CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_EC_Base__Control106CaptionLbl: Label 'Total';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';

    local procedure GetDirectUnitCostCaption(): Text[100]
    begin
        if "Purch. Cr. Memo Hdr."."Prices Including VAT" then
            exit("Purch. Cr. Memo Line".FieldCaption("Direct Unit Cost") + ' ' + Text1100008);

        exit("Purch. Cr. Memo Line".FieldCaption("Direct Unit Cost") + ' ' + Text1100009);
    end;
}

