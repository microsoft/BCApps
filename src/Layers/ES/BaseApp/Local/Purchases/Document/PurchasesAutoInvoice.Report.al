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
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Purchases.History;
using System.Utilities;

report 10712 "Purchases - AutoInvoice"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Document/PurchasesAutoInvoice.rdlc';
    Caption = 'Purchases - AutoInvoice';

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            DataItemTableView = sorting("No.") where("Autoinvoice No." = filter(<> ''));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Posted Purchase AutoInvoice';
            column(Purch__Inv__Header_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(STRSUBSTNO_Text1100005_CopyText_; StrSubstNo(Text1100005, CopyText))
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr_1__Control5; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_2__Control7; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_3__Control9; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_4__Control11; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
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
                    column(FORMAT__Purch__Inv__Header___Document_Date__0_4_; Format("Purch. Inv. Header"."Document Date", 0, 4))
                    {
                    }
                    column(Purch__Inv__Header___Due_Date_; Format("Purch. Inv. Header"."Due Date"))
                    {
                    }
                    column(Purch__Inv__Header___Autoinvoice_No__; "Purch. Inv. Header"."Autoinvoice No.")
                    {
                    }
                    column(Purch__Inv__Header___No__; "Purch. Inv. Header"."No.")
                    {
                    }
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
                    column(CompanyAddr_5__Control49; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6__Control50; CompanyAddr[6])
                    {
                    }
                    column(Purch__Inv__Header___Posting_Date_; Format("Purch. Inv. Header"."Posting Date"))
                    {
                    }
                    column(Currency; Currency)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(Text1100007; Text1100007Lbl)
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
                    column(Purch__Inv__Header___Due_Date_Caption; Purch__Inv__Header___Due_Date_CaptionLbl)
                    {
                    }
                    column(AutoInvoice_No_Caption; AutoInvoice_No_CaptionLbl)
                    {
                    }
                    column(Purch__Inv__Header___Posting_Date_Caption; Purch__Inv__Header___Posting_Date_CaptionLbl)
                    {
                    }
                    column(Original_Doc__No_Caption; Original_Doc__No_CaptionLbl)
                    {
                    }
                    column(Currency_CodeCaption; Currency_CodeCaptionLbl)
                    {
                    }
                    dataitem("Purch. Inv. Line"; "Purch. Inv. Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Purch. Inv. Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(DirectUnitCostCaption; DirectUnitCostCaption)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Purch__Inv__Line_Description; Description)
                        {
                        }
                        column(ShowPurchInvLine1; Type = Type::" ")
                        {
                        }
                        column(Purch__Inv__Line_Description_Control58; Description)
                        {
                        }
                        column(Purch__Inv__Line_Quantity; Quantity)
                        {
                        }
                        column(Purch__Inv__Line__Unit_of_Measure_; "Unit of Measure")
                        {
                        }
                        column(Purch__Inv__Line__Direct_Unit_Cost_; "Direct Unit Cost")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(Purch__Inv__Line__Line_Discount___; "Line Discount %")
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control63; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ShowPurchInvLine2; Type = Type::"G/L Account")
                        {
                        }
                        column(Purch__Inv__Line__No__; "No.")
                        {
                        }
                        column(Purch__Inv__Line_Description_Control65; Description)
                        {
                        }
                        column(Purch__Inv__Line_Quantity_Control66; Quantity)
                        {
                        }
                        column(Purch__Inv__Line__Unit_of_Measure__Control67; "Unit of Measure")
                        {
                        }
                        column(Purch__Inv__Line__Direct_Unit_Cost__Control68; "Direct Unit Cost")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(Purch__Inv__Line__Line_Discount____Control69; "Line Discount %")
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control70; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ShowPurchInvLine3; (Type = Type::Item) or (Type = Type::"Fixed Asset"))
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control79; Amount + "Inv. Discount Amount" + "Pmt. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Inv__Discount_Amount_; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(ShowPurchInvLineFooter1; "Inv. Discount Amount" <> 0)
                        {
                        }
                        column(Pmt__Disc__Rcd__Amount_; -"Pmt. Discount Amount")
                        {
                        }
                        column(ShowPurchInvLineFooter2; "Pmt. Discount Amount" <> 0)
                        {
                        }
                        column(Purch__Inv__Line_Amount; Amount)
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalVATAmount___TotalAmount; TotalVATAmount - TotalAmount)
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalVATAmount_TotalAmount_Amount; TotalVATAmount - TotalAmount + Amount)
                        {
                            AutoFormatExpression = "Purch. Inv. Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(TotalVATAmountTotalAmountSum; TotalVATAmountTotalAmountSum)
                        {
                        }
                        column(Purch__Inv__Line_Document_No_; "Document No.")
                        {
                        }
                        column(Purch__Inv__Line_Line_No_; "Line No.")
                        {
                        }
                        column(Purch__Inv__Line__No__Caption; FieldCaption("No."))
                        {
                        }
                        column(Purch__Inv__Line_Description_Control65Caption; FieldCaption(Description))
                        {
                        }
                        column(Purch__Inv__Line_Quantity_Control66Caption; FieldCaption(Quantity))
                        {
                        }
                        column(Purch__Inv__Line__Unit_of_Measure__Control67Caption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Purch__Inv__Line__Direct_Unit_Cost__Control68Caption; FieldCaption("Direct Unit Cost"))
                        {
                        }
                        column(Purch__Inv__Line__Line_Discount____Control69Caption; Purch__Inv__Line__Line_Discount____Control69CaptionLbl)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control70Caption; Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control70CaptionLbl)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_Caption; Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_CaptionLbl)
                        {
                        }
                        column(Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control79Caption; Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control79CaptionLbl)
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
                        var
                            PurchInvHeader: Record "Purch. Inv. Header";
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
                                // END;
                                VATAmountLine."VAT Amount" := (VATAmountLine."Amount Including VAT" * VATAmountLine."VAT %") / 100;
                                VATAmountLine."EC Amount" := (VATAmountLine."Amount Including VAT" * VATAmountLine."EC %") / 100;
                            end else
                                CurrReport.Skip();

                            if not PurchInvHeader.Get("Document No.") then
                                PurchInvHeader.Init();

                            if PurchInvHeader."Prices Including VAT" then
                                DirectUnitCostCaption := StrSubstNo('%1 %2', FieldCaption("Direct Unit Cost"), Text1100009)
                            else
                                DirectUnitCostCaption := StrSubstNo('%1 %2', FieldCaption("Direct Unit Cost"), Text1100008);

                            TotalVATAmountTotalAmountSum := TotalVATAmount - TotalAmount;
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
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount_; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount_; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; VATAmountLine."VAT %")
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control101; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control102; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC___; VATAmountLine."EC %")
                        {
                        }
                        column(VATAmountLine__EC_Amount__Control84; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_EC_Base__Control105; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control106; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount__Control86; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_EC_Base__Control109; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control110; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__EC_Amount__Control91; VATAmountLine."EC Amount")
                        {
                            AutoFormatExpression = "Purch. Inv. Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control101Caption; VATAmountLine__VAT_EC_Base__Control101CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Amount__Control102Caption; VATAmountLine__VAT_Amount__Control102CaptionLbl)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__EC___Caption; VATAmountLine__EC___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__EC_Amount__Control84Caption; VATAmountLine__EC_Amount__Control84CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base_Caption; VATAmountLine__VAT_EC_Base_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control105Caption; VATAmountLine__VAT_EC_Base__Control105CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_EC_Base__Control109Caption; VATAmountLine__VAT_EC_Base__Control109CaptionLbl)
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
                        column(PaymentTerms_Description; PaymentTerms.Description)
                        {
                        }
                        column(ShipmentMethod_Description; ShipmentMethod.Description)
                        {
                        }
                        column(Total_Number; Number)
                        {
                        }
                        column(PaymentTerms_DescriptionCaption; PaymentTerms_DescriptionCaptionLbl)
                        {
                        }
                        column(ShipmentMethod_DescriptionCaption; ShipmentMethod_DescriptionCaptionLbl)
                        {
                        }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Purch__Inv__Header___Buy_from_Vendor_No__; "Purch. Inv. Header"."Buy-from Vendor No.")
                        {
                        }
                        column(Total2_Number; Number)
                        {
                        }
                        column(Purch__Inv__Header___Buy_from_Vendor_No__Caption; "Purch. Inv. Header".FieldCaption("Buy-from Vendor No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Purch. Inv. Header"."Buy-from Vendor No." = "Purch. Inv. Header"."Pay-to Vendor No." then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(Total3; "Integer")
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
                        column(Total3_Number; Number)
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

                    trigger OnAfterGetRecord()
                    begin
                        if "Purch. Inv. Header"."Currency Code" = '' then
                            Currency := GLSetup."LCY Code"
                        else
                            Currency := "Purch. Inv. Header"."Currency Code";
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text1100004;
                        OutputNo := OutputNo + 1;
                    end;
                    TotalVATAmount := 0;
                    TotalAmount := 0;
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
                    Clear(SalesPurchPerson);
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
                FormatAddr.PurchInvPayTo(VendAddr, "Purch. Inv. Header");

                if "Payment Terms Code" = '' then
                    PaymentTerms.Init()
                else
                    PaymentTerms.Get("Payment Terms Code");
                if "Shipment Method Code" = '' then
                    ShipmentMethod.Init()
                else
                    ShipmentMethod.Get("Shipment Method Code");

                TotalVATAmount := 0;
                TotalAmount := 0;

                FormatAddr.PurchInvShipTo(ShipToAddr, "Purch. Inv. Header");
                TotalVATAmountTotalAmountSum := 0;
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
        Text1100004: Label 'COPY';
        Text1100005: Label 'AutoInvoice %1';
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        VATAmountLine: Record "VAT Amount Line" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
        FormatAddr: Codeunit "Format Address";
        VendAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        PurchaserText: Text[30];
        VATNoText: Text[30];
        ReferenceText: Text[30];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        DirectUnitCostCaption: Text[80];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        CopyText: Text[10];
        Currency: Code[10];
        TotalVATAmount: Decimal;
        TotalAmount: Decimal;
        Text1100008: Label 'Excl. VAT';
        Text1100009: Label 'Incl. VAT';
        TotalVATAmountTotalAmountSum: Decimal;
        Text1100007Lbl: Label 'Page';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        Purch__Inv__Header___Due_Date_CaptionLbl: Label 'Due Date';
        AutoInvoice_No_CaptionLbl: Label 'AutoInvoice No.';
        Purch__Inv__Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Original_Doc__No_CaptionLbl: Label 'Original Doc. No.';
        Currency_CodeCaptionLbl: Label 'Currency Code';
        Purch__Inv__Line__Line_Discount____Control69CaptionLbl: Label 'Disc. %';
        Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control70CaptionLbl: Label 'Amount';
        Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount_CaptionLbl: Label 'Continued';
        Amount__Inv__Discount_Amount___Pmt__Disc__Rcd__Amount__Control79CaptionLbl: Label 'Continued';
        Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        Pmt__Disc__Rcd__Amount_CaptionLbl: Label 'Pmt. Disc. Rcd. Amount';
        VAT_EC_AmountCaptionLbl: Label 'VAT+EC Amount';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_EC_Base__Control101CaptionLbl: Label 'VAT+EC Base';
        VATAmountLine__VAT_Amount__Control102CaptionLbl: Label 'VAT Amount';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__EC___CaptionLbl: Label 'EC %';
        VATAmountLine__EC_Amount__Control84CaptionLbl: Label 'EC Amount';
        VATAmountLine__VAT_EC_Base_CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_EC_Base__Control105CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_EC_Base__Control109CaptionLbl: Label 'Total';
        PaymentTerms_DescriptionCaptionLbl: Label 'Payment Terms';
        ShipmentMethod_DescriptionCaptionLbl: Label 'Shipment Method';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';
}

