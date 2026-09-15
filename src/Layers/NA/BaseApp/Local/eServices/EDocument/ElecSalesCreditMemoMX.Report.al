// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.Check;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Globalization;
using System.Utilities;

report 10476 "Elec. Sales Credit Memo MX"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/eServices/EDocument/ElecSalesCreditMemoMX.rdlc';
    Caption = 'Electronic Sales Credit Memo Mexico';
    Permissions = TableData "Sales Cr.Memo Line" = rimd;

    dataset
    {
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Ship-to Code", "No. Printed";
            RequestFilterHeading = 'Sales Credit Memo';
            column(Sales_Cr_Memo_Header_No_; "No.")
            {
            }
            column(DocumentFooter; DocumentFooterLbl)
            {
            }
            dataitem("Sales Cr.Memo Line"; "Sales Cr.Memo Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");
                dataitem(SalesLineComments; "Sales Comment Line")
                {
                    DataItemLink = "No." = field("Document No."), "Document Line No." = field("Line No.");
                    DataItemTableView = sorting("Document Type", "No.", "Document Line No.", "Line No.") where("Document Type" = const("Posted Credit Memo"), "Print On Credit Memo" = const(true));

                    trigger OnAfterGetRecord()
                    begin
                        TempSalesCrMemoLine.Init();
                        TempSalesCrMemoLine."Document No." := "Sales Cr.Memo Header"."No.";
                        TempSalesCrMemoLine."Line No." := HighestLineNo + 10;
                        HighestLineNo := TempSalesCrMemoLine."Line No.";
                        if StrLen(Comment) <= MaxStrLen(TempSalesCrMemoLine.Description) then begin
                            TempSalesCrMemoLine.Description := Comment;
                            TempSalesCrMemoLine."Description 2" := '';
                        end else begin
                            SpacePointer := MaxStrLen(TempSalesCrMemoLine.Description) + 1;
                            while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                                SpacePointer := SpacePointer - 1;
                            if SpacePointer = 1 then
                                SpacePointer := MaxStrLen(TempSalesCrMemoLine.Description) + 1;
                            TempSalesCrMemoLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
                            TempSalesCrMemoLine."Description 2" :=
                              CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempSalesCrMemoLine."Description 2"));
                        end;
                        TempSalesCrMemoLine.Insert();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempSalesCrMemoLine := "Sales Cr.Memo Line";
                    TempSalesCrMemoLine.Insert();
                    HighestLineNo := "Line No.";
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesCrMemoLine.Reset();
                    TempSalesCrMemoLine.DeleteAll();
                end;
            }
            dataitem("Sales Comment Line"; "Sales Comment Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("Document Type", "No.", "Document Line No.", "Line No.") where("Document Type" = const("Posted Credit Memo"), "Print On Credit Memo" = const(true), "Document Line No." = const(0));

                trigger OnAfterGetRecord()
                begin
                    TempSalesCrMemoLine.Init();
                    TempSalesCrMemoLine."Document No." := "Sales Cr.Memo Header"."No.";
                    TempSalesCrMemoLine."Line No." := HighestLineNo + 1000;
                    HighestLineNo := TempSalesCrMemoLine."Line No.";
                    if StrLen(Comment) <= MaxStrLen(TempSalesCrMemoLine.Description) then begin
                        TempSalesCrMemoLine.Description := Comment;
                        TempSalesCrMemoLine."Description 2" := '';
                    end else begin
                        SpacePointer := MaxStrLen(TempSalesCrMemoLine.Description) + 1;
                        while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                            SpacePointer := SpacePointer - 1;
                        if SpacePointer = 1 then
                            SpacePointer := MaxStrLen(TempSalesCrMemoLine.Description) + 1;
                        TempSalesCrMemoLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
                        TempSalesCrMemoLine."Description 2" :=
                          CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempSalesCrMemoLine."Description 2"));
                    end;
                    TempSalesCrMemoLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesCrMemoLine.Init();
                    TempSalesCrMemoLine."Document No." := "Sales Cr.Memo Header"."No.";
                    TempSalesCrMemoLine."Line No." := HighestLineNo + 1000;
                    HighestLineNo := TempSalesCrMemoLine."Line No.";
                    TempSalesCrMemoLine.Insert();
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInformation_Picture; CompanyInformation.Picture)
                    {
                    }
                    column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyAddress_1_; CompanyAddress[1])
                    {
                    }
                    column(CompanyAddress_2_; CompanyAddress[2])
                    {
                    }
                    column(CompanyAddress_3_; CompanyAddress[3])
                    {
                    }
                    column(CompanyAddress_4_; CompanyAddress[4])
                    {
                    }
                    column(CompanyAddress_5_; CompanyAddress[5])
                    {
                    }
                    column(CompanyAddress_6_; CompanyAddress[6])
                    {
                    }
                    column(CopyTxt; CopyTxt)
                    {
                    }
                    column(BillToAddress_1_; BillToAddressName)
                    {
                    }
                    column(BillToAddress_2_; BillToAddress[2])
                    {
                    }
                    column(BillToAddress_3_; BillToAddress[3])
                    {
                    }
                    column(BillToAddress_4_; BillToAddress[4])
                    {
                    }
                    column(BillToAddress_5_; BillToAddress[5])
                    {
                    }
                    column(BillToAddress_6_; BillToAddress[6])
                    {
                    }
                    column(BillToAddress_7_; BillToAddress[7])
                    {
                    }
                    column(Sales_Cr_Memo_Header___Shipment_Date_; "Sales Cr.Memo Header"."Shipment Date")
                    {
                    }
                    column(Sales_Cr_Memo_Header___Applies_to_Doc__Type_; "Sales Cr.Memo Header"."Applies-to Doc. Type")
                    {
                    }
                    column(Sales_Cr_Memo_Header___Applies_to_Doc__No__; "Sales Cr.Memo Header"."Applies-to Doc. No.")
                    {
                    }
                    column(ShipToAddress_1_; ShipToAddress[1])
                    {
                    }
                    column(ShipToAddress_2_; ShipToAddress[2])
                    {
                    }
                    column(ShipToAddress_3_; ShipToAddress[3])
                    {
                    }
                    column(ShipToAddress_4_; ShipToAddress[4])
                    {
                    }
                    column(ShipToAddress_5_; ShipToAddress[5])
                    {
                    }
                    column(ShipToAddress_6_; ShipToAddress[6])
                    {
                    }
                    column(ShipToAddress_7_; ShipToAddress[7])
                    {
                    }
                    column(Sales_Cr_Memo_Header___Bill_to_Customer_No__; "Sales Cr.Memo Header"."Bill-to Customer No.")
                    {
                    }
                    column(Sales_Cr_Memo_Header___Your_Reference_; "Sales Cr.Memo Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(CompanyAddress_7_; CompanyAddress[7])
                    {
                    }
                    column(CompanyAddress_8_; CompanyAddress[8])
                    {
                    }
                    column(BillToAddress_8_; BillToAddress[8])
                    {
                    }
                    column(ShipToAddress_8_; ShipToAddress[8])
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(CompanyInformation__RFC_No__; CompanyInformation."RFC Number")
                    {
                    }
                    column(Sales_Cr_Memo_Header___Certificate_Serial_No__; "Sales Cr.Memo Header"."Certificate Serial No.")
                    {
                    }
                    column(FolioText; "Sales Cr.Memo Header"."Fiscal Invoice Number PAC")
                    {
                    }
                    column(NoSeriesLine__Authorization_Code_; "Sales Cr.Memo Header"."Date/Time Stamped")
                    {
                    }
                    column(NoSeriesLine__Authorization_Year_; StrSubstNo(Text011, "Sales Cr.Memo Header"."Bill-to City", "Sales Cr.Memo Header"."Document Date"))
                    {
                    }
                    column(Customer__RFC_No__; Customer."RFC No.")
                    {
                    }
                    column(Sales_Cr_Memo_Header___No__; "Sales Cr.Memo Header"."No.")
                    {
                    }
                    column(Customer__Phone_No__; Customer."Phone No.")
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(CreditCaption; CreditCaptionLbl)
                    {
                    }
                    column(Ship_DateCaption; Ship_DateCaptionLbl)
                    {
                    }
                    column(Apply_to_TypeCaption; Apply_to_TypeCaptionLbl)
                    {
                    }
                    column(Apply_to_NumberCaption; Apply_to_NumberCaptionLbl)
                    {
                    }
                    column(Customer_IDCaption; Customer_IDCaptionLbl)
                    {
                    }
                    column(P_O__NumberCaption; P_O__NumberCaptionLbl)
                    {
                    }
                    column(SalesPersonCaption; SalesPersonCaptionLbl)
                    {
                    }
                    column(ShipCaption; ShipCaptionLbl)
                    {
                    }
                    column(CREDIT_MEMOCaption; CREDIT_MEMOCaptionLbl)
                    {
                    }
                    column(Page_Caption; Page_CaptionLbl)
                    {
                    }
                    column(CompanyInformation__RFC_No__Caption; CompanyInformation__RFC_No__CaptionLbl)
                    {
                    }
                    column(Sales_Cr_Memo_Header___Certificate_Serial_No__Caption; Sales_Cr_Memo_Header___Certificate_Serial_No__CaptionLbl)
                    {
                    }
                    column(FolioTextCaption; FolioTextCaptionLbl)
                    {
                    }
                    column(NoSeriesLine__Authorization_Code_Caption; NoSeriesLine__Authorization_Code_CaptionLbl)
                    {
                    }
                    column(NoSeriesLine__Authorization_Year_Caption; NoSeriesLine__Authorization_Year_CaptionLbl)
                    {
                    }
                    column(Customer__RFC_No__Caption; Customer__RFC_No__CaptionLbl)
                    {
                    }
                    column(Customer__Phone_No__Caption; Customer__Phone_No__CaptionLbl)
                    {
                    }
                    column(SATPaymentMethod; SATPaymentMethod)
                    {
                    }
                    column(SATPaymentTerm; SATPaymentTerm)
                    {
                    }
                    column(SATTaxRegimeClassification; SATTaxRegimeClassification)
                    {
                    }
                    column(TaxRegimeCaption; TaxRegimeLbl)
                    {
                    }
                    dataitem(SalesCrMemoLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(AmountExclInvDisc; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesCrMemoLine__No__; TempSalesCrMemoLine."No.")
                        {
                        }
                        column(TempSalesCrMemoLine__Unit_of_Measure_; TempSalesCrMemoLine."Unit of Measure")
                        {
                        }
                        column(TempSalesCrMemoLine_Quantity; TempSalesCrMemoLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(UnitPriceToPrint; UnitPriceToPrint)
                        {
                            DecimalPlaces = 2 : 5;
                        }
                        column(AmountExclInvDisc_Control53; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesCrMemoLine_Description_________TempSalesCrMemoLine__Description_2_; TempSalesCrMemoLine.Description + ' ' + TempSalesCrMemoLine."Description 2")
                        {
                        }
                        column(AmountExclInvDisc_Control40; AmountExclInvDisc)
                        {
                        }
                        column(AmountExclInvDisc_Control79; AmountExclInvDisc)
                        {
                        }
                        column(TempSalesCrMemoLine_Amount___AmountExclInvDisc; TempSalesCrMemoLine.Amount - AmountExclInvDisc)
                        {
                        }
                        column(TempSalesCrMemoLine__Amount_Including_VAT____TempSalesCrMemoLine_Amount; TempSalesCrMemoLine."Amount Including VAT" - TempSalesCrMemoLine.Amount)
                        {
                        }
                        column(TempSalesCrMemoLine__Amount_Including_VAT_; TempSalesCrMemoLine."Amount Including VAT")
                        {
                        }
                        column(AmountInWords_1_; AmountInWords[1])
                        {
                        }
                        column(AmountInWords_2_; AmountInWords[2])
                        {
                        }
                        column(SalesCrMemoLine_Number; Number)
                        {
                        }
                        column(Item_No_Caption; Item_No_CaptionLbl)
                        {
                        }
                        column(UnitCaption; UnitCaptionLbl)
                        {
                        }
                        column(DescriptionCaption; DescriptionCaptionLbl)
                        {
                        }
                        column(QuantityCaption; QuantityCaptionLbl)
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Total_PriceCaption; Total_PriceCaptionLbl)
                        {
                        }
                        column(Subtotal_Caption; Subtotal_CaptionLbl)
                        {
                        }
                        column(Invoice_Discount_Caption; Invoice_Discount_CaptionLbl)
                        {
                        }
                        column(Total_Caption; Total_CaptionLbl)
                        {
                        }
                        column(TempSalesCrMemoLine__Amount_Including_VAT____TempSalesCrMemoLine_AmountCaption; TempSalesCrMemoLine__Amount_Including_VAT____TempSalesCrMemoLine_AmountCaptionLbl)
                        {
                        }
                        column(Amount_in_words_Caption; Amount_in_words_CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;
                            if OnLineNumber = 1 then
                                TempSalesCrMemoLine.Find('-')
                            else
                                TempSalesCrMemoLine.Next();

                            if TempSalesCrMemoLine.Type = TempSalesCrMemoLine.Type::" " then begin
                                TempSalesCrMemoLine."No." := '';
                                TempSalesCrMemoLine."Unit of Measure" := '';
                                TempSalesCrMemoLine.Amount := 0;
                                TempSalesCrMemoLine."Amount Including VAT" := 0;
                                TempSalesCrMemoLine."Inv. Discount Amount" := 0;
                                TempSalesCrMemoLine.Quantity := 0;
                            end else
                                if TempSalesCrMemoLine.Type = TempSalesCrMemoLine.Type::"G/L Account" then
                                    TempSalesCrMemoLine."No." := '';

                            AmountExclInvDisc := TempSalesCrMemoLine.Amount + TempSalesCrMemoLine."Inv. Discount Amount";

                            if TempSalesCrMemoLine.Quantity = 0 then
                                UnitPriceToPrint := 0
                            // so it won't print
                            else
                                UnitPriceToPrint := Round(AmountExclInvDisc / TempSalesCrMemoLine.Quantity, 0.00001);

                            TotalAmountIncludingVAT += TempSalesCrMemoLine."Amount Including VAT";

                            if OnLineNumber = NumberOfLines then
                                ConvertAmounttoWords(TotalAmountIncludingVAT);
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(AmountExclInvDisc);
                            NumberOfLines := TempSalesCrMemoLine.Count();
                            SetRange(Number, 1, NumberOfLines);
                            OnLineNumber := 0;
                            TotalAmountIncludingVAT := 0;
                        end;
                    }
                    dataitem(OriginalStringLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(OriginalStringText; OriginalStringText)
                        {
                        }
                        column(OriginalStringLoop_Number; Number)
                        {
                        }
                        column(Original_StringCaption; Original_StringCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(OriginalStringText);
                            OriginalStringText := CopyStr(OriginalStringTextUnbounded, Position, MaxStrLen(OriginalStringText));
                            Position := Position + StrLen(OriginalStringText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(OriginalStringTextUnbounded) / MaxStrLen(OriginalStringText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(DigitalSignaturePACLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(DigitalSignaturePACText; DigitalSignaturePACText)
                        {
                        }
                        column(DigitalSignaturePACLoop_Number; Number)
                        {
                        }
                        column(Digital_StampCaption; Digital_StampCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(DigitalSignaturePACText);
                            DigitalSignaturePACText := CopyStr(DigitalSignaturePACTextUnbounded, Position, MaxStrLen(DigitalSignaturePACText));
                            Position := Position + StrLen(DigitalSignaturePACText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(DigitalSignaturePACTextUnbounded) / MaxStrLen(DigitalSignaturePACText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(DigitalSignatureLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(DigitalSignatureText; DigitalSignatureText)
                        {
                        }
                        column(DigitalSignatureLoop_Number; Number)
                        {
                        }
                        column(Digital_stampCaption_Control1020008; Digital_stampCaption_Control1020008Lbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(DigitalSignatureText);
                            DigitalSignatureText := CopyStr(DigitalSignatureTextUnbounded, Position, MaxStrLen(DigitalSignatureText));
                            Position := Position + StrLen(DigitalSignatureText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(DigitalSignatureTextUnbounded) / MaxStrLen(DigitalSignatureText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(QRCode; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Sales_Cr_Memo_Header___QR_Code_; "Sales Cr.Memo Header"."QR Code")
                        {
                        }
                        column(QRCode_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            "Sales Cr.Memo Header".CalcFields("QR Code");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            SalesCrMemoPrinted.Run("Sales Cr.Memo Header");
                        CurrReport.Break();
                    end;
                    CopyNo := CopyNo + 1;
                    if CopyNo = 1 then // Original
                        Clear(CopyTxt)
                    else
                        CopyTxt := Text000;
                end;

                trigger OnPreDataItem()
                begin
                    NoLoops := 1 + Abs(NoCopies);
                    if NoLoops <= 0 then
                        NoLoops := 1;
                    CopyNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            var
                SATUtilities: Codeunit "SAT Utilities";
                InStream: InStream;
            begin
                if "Source Code" = SourceCodeSetup."Deleted Document" then
                    Error(Text010);

                if PrintCompany then
                    if RespCenter.Get("Responsibility Center") then begin
                        FormatAddress.RespCenter(CompanyAddress, RespCenter);
                        CompanyInformation."Phone No." := RespCenter."Phone No.";
                        CompanyInformation."Fax No." := RespCenter."Fax No.";
                    end;
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if "Salesperson Code" = '' then
                    Clear(SalesPurchPerson)
                else
                    SalesPurchPerson.Get("Salesperson Code");

                if not Customer.Get("Bill-to Customer No.") then begin
                    Clear(Customer);
                    "Bill-to Name" := Text009;
                    "Ship-to Name" := Text009;
                end;

                FormatAddress.SalesCrMemoBillTo(BillToAddress, "Sales Cr.Memo Header");
                FormatAddress.SalesCrMemoShipTo(ShipToAddress, ShipToAddress, "Sales Cr.Memo Header");

                if Customer."CFDI Customer Name" <> '' then
                    BillToAddressName := Customer."CFDI Customer Name"
                else
                    BillToAddressName := BillToAddress[1];

                if LogInteraction then
                    if not CurrReport.Preview then
                        SegManagement.LogDocument(
                          6, "No.", 0, 0, DATABASE::Customer, "Sell-to Customer No.", "Salesperson Code",
                          "Campaign No.", "Posting Description", '');
                "Sales Cr.Memo Header".CalcFields("Original String", "Digital Stamp SAT", "Digital Stamp PAC");

                Clear(OriginalStringTextUnbounded);
                "Original String".CreateInStream(InStream);
                InStream.Read(OriginalStringTextUnbounded);

                Clear(DigitalSignatureTextUnbounded);
                "Digital Stamp SAT".CreateInStream(InStream);
                InStream.Read(DigitalSignatureTextUnbounded);

                Clear(DigitalSignaturePACTextUnbounded);
                "Digital Stamp PAC".CreateInStream(InStream);
                InStream.Read(DigitalSignaturePACTextUnbounded);

                SATPaymentMethod := SATUtilities.GetSATPaymentTermDescription("Payment Terms Code"); // MetodoPago
                SATPaymentTerm := SATUtilities.GetSATPaymentMethodDescription("Payment Method Code"); // FormaPago
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
                    field(NoCopies; NoCopies)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies to print of the document.';
                    }
                    field(PrintCompany; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if the printed document includes your company address.';
                        Visible = false;
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies that interactions with contact persons in connection with the report are logged.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Cr. Memo") <> '';
            LogInteractionEnable := LogInteraction;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        CompanyInformation.Get();
        SalesSetup.Get();
        SourceCodeSetup.Get();
        PrintCompany := true;

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                CompanyInformation.CalcFields(Picture);
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;

        if PrintCompany then
            FormatAddress.Company(CompanyAddress, CompanyInformation)
        else
            Clear(CompanyAddress);

        SATTaxRegimeClassification := SATUtilities.GetSATTaxSchemeDescription(CompanyInformation."SAT Tax Regime Classification");
    end;

    var
        UnitPriceToPrint: Decimal;
        AmountExclInvDisc: Decimal;
        TotalAmountIncludingVAT: Decimal;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        SalesSetup: Record "Sales & Receivables Setup";
        TempSalesCrMemoLine: Record "Sales Cr.Memo Line" temporary;
        RespCenter: Record "Responsibility Center";
        Customer: Record Customer;
        SourceCodeSetup: Record "Source Code Setup";
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        BillToAddressName: Text[300];
        CopyTxt: Text[10];
        PrintCompany: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        HighestLineNo: Integer;
        SpacePointer: Integer;
        SalesCrMemoPrinted: Codeunit "Sales Cr. Memo-Printed";
        FormatAddress: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        LogInteraction: Boolean;
        Text000: Label 'COPY';
        Position: Integer;
        Text009: Label 'VOID CREDIT MEMO';
        AmountInWords: array[2] of Text[80];
        OriginalStringText: Text[80];
        DigitalSignatureText: Text[80];
        DigitalSignaturePACText: Text[80];
        OriginalStringTextUnbounded: Text;
        DigitalSignatureTextUnbounded: Text;
        Text010: Label 'You can not sign or send or print a deleted document.';
        DigitalSignaturePACTextUnbounded: Text;
        Text011: Label '%1, %2';
        LogInteractionEnable: Boolean;
        CreditCaptionLbl: Label 'Credit-To:';
        Ship_DateCaptionLbl: Label 'Ship Date';
        Apply_to_TypeCaptionLbl: Label 'Apply to Type';
        Apply_to_NumberCaptionLbl: Label 'Apply to Number';
        Customer_IDCaptionLbl: Label 'Customer ID';
        P_O__NumberCaptionLbl: Label 'P.O. Number';
        SalesPersonCaptionLbl: Label 'SalesPerson';
        ShipCaptionLbl: Label 'Ship-To:';
        CREDIT_MEMOCaptionLbl: Label 'CREDIT MEMO';
        Page_CaptionLbl: Label 'Page:';
        CompanyInformation__RFC_No__CaptionLbl: Label 'Company RFC';
        Sales_Cr_Memo_Header___Certificate_Serial_No__CaptionLbl: Label 'Certificate Serial No.';
        FolioTextCaptionLbl: Label 'Folio:';
        NoSeriesLine__Authorization_Code_CaptionLbl: Label 'Date and time of certification:';
        NoSeriesLine__Authorization_Year_CaptionLbl: Label 'Location and Issue date:';
        Customer__RFC_No__CaptionLbl: Label 'Customer RFC';
        Customer__Phone_No__CaptionLbl: Label 'Phone number';
        Item_No_CaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        QuantityCaptionLbl: Label 'Quantity';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Total_PriceCaptionLbl: Label 'Total Price';
        Subtotal_CaptionLbl: Label 'Subtotal:';
        Invoice_Discount_CaptionLbl: Label 'Invoice Discount:';
        Total_CaptionLbl: Label 'Total:';
        TempSalesCrMemoLine__Amount_Including_VAT____TempSalesCrMemoLine_AmountCaptionLbl: Label 'VAT Amount';
        Amount_in_words_CaptionLbl: Label 'Amount in words:';
        Original_StringCaptionLbl: Label 'Original string of digital certificate complement from SAT';
        Digital_StampCaptionLbl: Label 'Digital stamp from SAT';
        Digital_stampCaption_Control1020008Lbl: Label 'Digital stamp';
        DocumentFooterLbl: Label 'This document is a printed version for electronic credit memo';
        TaxRegimeLbl: Label 'Regimen Fiscal:';
        SATPaymentMethod: Text[50];
        SATPaymentTerm: Text[50];
        SATTaxRegimeClassification: Text[100];

    protected var
        CompanyInformation: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

    procedure ConvertAmounttoWords(AmountLoc: Decimal)
    var
        TranslationManagement: Report "Check Translation Management";
        LanguageId: Integer;
    begin
        if CurrReport.Language in [1033, 3084, 2058, 4105] then
            LanguageId := CurrReport.Language
        else
            LanguageId := GlobalLanguage;
        TranslationManagement.FormatNoText(AmountInWords, AmountLoc,
          LanguageId, "Sales Cr.Memo Header"."Currency Code");
    end;
}

