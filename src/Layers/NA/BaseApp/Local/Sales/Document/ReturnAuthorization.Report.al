// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Utilities;

report 10081 "Return Authorization"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Document/ReturnAuthorization.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Return Authorization';
    UsageCategory = Documents;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Return Order"));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Sell-to Customer No.", "Bill-to Customer No.", "Ship-to Code", "No. Printed";
            RequestFilterHeading = 'Return Order';
            column(Sales_Header_Document_Type; "Document Type")
            {
            }
            column(Sales_Header_No_; "No.")
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const("Return Order"));
                dataitem(SalesLineComments; "Sales Comment Line")
                {
                    DataItemLink = "No." = field("Document No."), "Document Line No." = field("Line No.");
                    DataItemTableView = sorting("Document Type", "No.", "Document Line No.", "Line No.") where("Document Type" = const("Return Order"), "Print On Return Authorization" = const(true));

                    trigger OnAfterGetRecord()
                    begin
                        TempSalesLine.Init();
                        TempSalesLine."Document Type" := "Sales Header"."Document Type";
                        TempSalesLine."Document No." := "Sales Header"."No.";
                        TempSalesLine."Line No." := HighestLineNo + 10;
                        HighestLineNo := TempSalesLine."Line No.";
                        if StrLen(Comment) <= MaxStrLen(TempSalesLine.Description) then begin
                            TempSalesLine.Description := Comment;
                            TempSalesLine."Description 2" := '';
                        end else begin
                            SpacePointer := MaxStrLen(TempSalesLine.Description) + 1;
                            while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                                SpacePointer := SpacePointer - 1;
                            if SpacePointer = 1 then
                                SpacePointer := MaxStrLen(TempSalesLine.Description) + 1;
                            TempSalesLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
                            TempSalesLine."Description 2" := CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempSalesLine."Description 2"));
                        end;
                        TempSalesLine.Insert();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempSalesLine := "Sales Line";
                    TempSalesLine.Insert();
                    HighestLineNo := "Line No.";
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesLine.Reset();
                    TempSalesLine.DeleteAll();
                end;
            }
            dataitem("Sales Comment Line"; "Sales Comment Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("Document Type", "No.", "Document Line No.", "Line No.") where("Document Type" = const("Return Order"), "Print On Return Authorization" = const(true), "Document Line No." = const(0));

                trigger OnAfterGetRecord()
                begin
                    TempSalesLine.Init();
                    TempSalesLine."Document Type" := "Sales Header"."Document Type";
                    TempSalesLine."Document No." := "Sales Header"."No.";
                    TempSalesLine."Line No." := HighestLineNo + 1000;
                    HighestLineNo := TempSalesLine."Line No.";
                    if StrLen(Comment) <= MaxStrLen(TempSalesLine.Description) then begin
                        TempSalesLine.Description := Comment;
                        TempSalesLine."Description 2" := '';
                    end else begin
                        SpacePointer := MaxStrLen(TempSalesLine.Description) + 1;
                        while (SpacePointer > 1) and (Comment[SpacePointer] <> ' ') do
                            SpacePointer := SpacePointer - 1;
                        if SpacePointer = 1 then
                            SpacePointer := MaxStrLen(TempSalesLine.Description) + 1;
                        TempSalesLine.Description := CopyStr(Comment, 1, SpacePointer - 1);
                        TempSalesLine."Description 2" := CopyStr(CopyStr(Comment, SpacePointer + 1), 1, MaxStrLen(TempSalesLine."Description 2"));
                    end;
                    TempSalesLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    TempSalesLine.Init();
                    TempSalesLine."Document Type" := "Sales Header"."Document Type";
                    TempSalesLine."Document No." := "Sales Header"."No.";
                    TempSalesLine."Line No." := HighestLineNo + 1000;
                    HighestLineNo := TempSalesLine."Line No.";
                end;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
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
                    column(BillToAddress_1_; BillToAddress[1])
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
                    column(Sales_Header___Shipment_Date_; "Sales Header"."Shipment Date")
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
                    column(Sales_Header___Bill_to_Customer_No__; "Sales Header"."Bill-to Customer No.")
                    {
                    }
                    column(Sales_Header___Your_Reference_; "Sales Header"."Your Reference")
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(Sales_Header___No__; "Sales Header"."No.")
                    {
                    }
                    column(Sales_Header___Document_Date_; "Sales Header"."Document Date")
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
                    column(ShipmentMethod_Description; ShipmentMethod.Description)
                    {
                    }
                    column(Sales_Header___Order_Date_; "Sales Header"."Order Date")
                    {
                    }
                    column(TaxRegLabel; TaxRegLabel)
                    {
                    }
                    column(TaxRegNo; TaxRegNo)
                    {
                    }
                    column(CopyNo; CopyNo)
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(SalesHeaderExDocNo; "Sales Header"."External Document No.")
                    {
                    }
                    column(SoldCaption; SoldCaptionLbl)
                    {
                    }
                    column(To_Caption; To_CaptionLbl)
                    {
                    }
                    column(Ship_DateCaption; Ship_DateCaptionLbl)
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
                    column(To_Caption_Control89; To_Caption_Control89Lbl)
                    {
                    }
                    column(RETURN_AUTHORIZATIONCaption; RETURN_AUTHORIZATIONCaptionLbl)
                    {
                    }
                    column(Return_Authorization_Number_Caption; Return_Authorization_Number_CaptionLbl)
                    {
                    }
                    column(Return_Authorization_Date_Caption; Return_Authorization_Date_CaptionLbl)
                    {
                    }
                    column(Page_Caption; Page_CaptionLbl)
                    {
                    }
                    column(Ship_ViaCaption; Ship_ViaCaptionLbl)
                    {
                    }
                    column(P_O__DateCaption; P_O__DateCaptionLbl)
                    {
                    }
                    dataitem(SalesLine; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(TempSalesLine__No__; TempSalesLine."No.")
                        {
                        }
                        column(TempSalesLine__Unit_of_Measure_; TempSalesLine."Unit of Measure")
                        {
                        }
                        column(TempSalesLine_Quantity; TempSalesLine.Quantity)
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(TempSalesLine_Description_________TempSalesLine__Description_2_; TempSalesLine.Description + ' ' + TempSalesLine."Description 2")
                        {
                        }
                        column(SalesLine_Number; Number)
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

                        trigger OnAfterGetRecord()
                        begin
                            OnLineNumber := OnLineNumber + 1;
                            if OnLineNumber = 1 then
                                TempSalesLine.Find('-')
                            else
                                TempSalesLine.Next();

                            if TempSalesLine.Type = TempSalesLine.Type::" " then begin
                                TempSalesLine."No." := '';
                                TempSalesLine."Unit of Measure" := '';
                                TempSalesLine."Line Amount" := 0;
                                TempSalesLine."Inv. Discount Amount" := 0;
                                TempSalesLine.Quantity := 0;
                            end else
                                if TempSalesLine.Type = TempSalesLine.Type::"G/L Account" then
                                    TempSalesLine."No." := '';
                        end;

                        trigger OnPreDataItem()
                        begin
                            NumberOfLines := TempSalesLine.Count();
                            SetRange(Number, 1, NumberOfLines);
                            OnLineNumber := 0;
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if CopyNo = NoLoops then begin
                        if not CurrReport.Preview then
                            SalesPrinted.Run("Sales Header");
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
            begin
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

                if "Payment Terms Code" = '' then
                    Clear(PaymentTerms)
                else
                    PaymentTerms.Get("Payment Terms Code");

                if "Shipment Method Code" = '' then
                    Clear(ShipmentMethod)
                else
                    ShipmentMethod.Get("Shipment Method Code");

                FormatAddress.SalesHeaderSellTo(BillToAddress, "Sales Header");
                FormatAddress.SalesHeaderShipTo(ShipToAddress, ShipToAddress, "Sales Header");

                if LogInteraction then
                    if not CurrReport.Preview then
                        if "Bill-to Contact No." <> '' then
                            SegManagement.LogDocument(
                              18, "No.", 0, 0, DATABASE::Contact, "Bill-to Contact No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", '')
                        else
                            SegManagement.LogDocument(
                              18, "No.", 0, 0, DATABASE::Customer, "Bill-to Customer No.",
                              "Salesperson Code", "Campaign No.", "Posting Description", '');
            end;

            trigger OnPreDataItem()
            begin
                CompanyInformation.Get();
                if PrintCompany then
                    FormatAddress.Company(CompanyAddress, CompanyInformation)
                else
                    Clear(CompanyAddress);
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Number of Copies';
                        ToolTip = 'Specifies the number of copies of each document (in addition to the original) that you want to print.';
                    }
                    field(PrintCompany; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the related interactions with the involved contact person in the Interaction Log Entry table.';
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
            /* reactivate when HQ comes up with a code number for return authorizations
            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Blnkt. Ord") <> '';
            */
            LogInteractionEnable := LogInteraction;

        end;
    }

    labels
    {
    }

    var
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInformation: Record "Company Information";
        TempSalesLine: Record "Sales Line" temporary;
        RespCenter: Record "Responsibility Center";
        LanguageMgt: Codeunit Language;
        CompanyAddress: array[8] of Text[100];
        BillToAddress: array[8] of Text[100];
        ShipToAddress: array[8] of Text[100];
        CopyTxt: Text[10];
        PrintCompany: Boolean;
        NoCopies: Integer;
        NoLoops: Integer;
        CopyNo: Integer;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        HighestLineNo: Integer;
        SpacePointer: Integer;
        SalesPrinted: Codeunit "Sales-Printed";
        FormatAddress: Codeunit "Format Address";
        SegManagement: Codeunit SegManagement;
        Text000: Label 'COPY';
        LogInteraction: Boolean;
        TaxRegNo: Text[30];
        TaxRegLabel: Text[30];
        LogInteractionEnable: Boolean;
        SoldCaptionLbl: Label 'Sold';
        To_CaptionLbl: Label 'To:';
        Ship_DateCaptionLbl: Label 'Ship Date';
        Customer_IDCaptionLbl: Label 'Customer ID';
        P_O__NumberCaptionLbl: Label 'P.O. Number';
        SalesPersonCaptionLbl: Label 'SalesPerson';
        ShipCaptionLbl: Label 'Ship';
        To_Caption_Control89Lbl: Label 'To:';
        RETURN_AUTHORIZATIONCaptionLbl: Label 'RETURN AUTHORIZATION';
        Return_Authorization_Number_CaptionLbl: Label 'Return Authorization Number:';
        Return_Authorization_Date_CaptionLbl: Label 'Return Authorization Date:';
        Page_CaptionLbl: Label 'Page:';
        Ship_ViaCaptionLbl: Label 'Ship Via';
        P_O__DateCaptionLbl: Label 'P.O. Date';
        Item_No_CaptionLbl: Label 'Item No.';
        UnitCaptionLbl: Label 'Unit';
        DescriptionCaptionLbl: Label 'Description';
        QuantityCaptionLbl: Label 'Quantity';
}

