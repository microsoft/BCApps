// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Posting;
using System.Globalization;
using System.Utilities;

report 10606 "Sales Order Picking List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Document/SalesOrderPickingList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Order Picking List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Sell-to Customer No.";
            RequestFilterHeading = 'Sales Order';
            column(DocType_SalesHdr; "Document Type")
            {
            }
            column(No_SalesHdr; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CopyText; StrSubstNo(Text004, CopyText))
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CompInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompInfoBankName; CompanyInfo."Bank Name")
                    {
                    }
                    column(CompInfoBankAcctNo; CompanyInfo."Bank Account No.")
                    {
                    }
                    column(BillToCustNo_SalesHdr; "Sales Header"."Bill-to Customer No.")
                    {
                    }
                    column(DocDate_SalesHdr; Format("Sales Header"."Document Date", 0, 4))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_SalesHdr; "Sales Header"."VAT Registration No.")
                    {
                    }
                    column(ShipmentDate_SalesHdr; "Sales Header"."Shipment Date")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No1_SalesHdr; "Sales Header"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(YourRef_SalesHdr; "Sales Header"."Your Reference")
                    {
                    }
                    column(FrmtYourRef_SalesHdr; Format("Sales Header"."Your Reference"))
                    {
                    }
                    column(CustAddr7; CustAddr[7])
                    {
                    }
                    column(CustAddr8; CustAddr[8])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(PageCaption; PageCaptionLbl)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(SalesLine_LineNo; SalesLine."Line No.")
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoVATRegNoCaption; CompanyInfoVATRegNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoGiroNoCaption; CompanyInfoGiroNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankNameCaption; CompanyInfoBankNameCaptionLbl)
                    {
                    }
                    column(CompanyInfoBankAcctNoCaption; CompanyInfoBankAcctNoCaptionLbl)
                    {
                    }
                    column(BillToCustNoCaption_SalesHdr; "Sales Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(ShipmentDateCaption_SalesHdr; "Sales Header".FieldCaption("Shipment Date"))
                    {
                    }
                    column(OrderNoCaption; OrderNoCaptionLbl)
                    {
                    }
                    column(ShipmentMethod_Description; ShipmentMethod.Description)
                    {
                    }
                    column(ShipmentMethodDescCaption; ShipmentMethodDescCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
                        {
                        }
                        column(DimensionLoop1_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            DimText := GetDimText();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Sales Line"; "Sales Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Sales Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(Desc_SalesLine; "Sales Line".Description)
                        {
                        }
                        column(SalesLine_Type; SalesLine.Type)
                        {
                        }
                        column(No_SalesLine; "Sales Line"."No.")
                        {
                        }
                        column(Qty_SalesLine; "Sales Line".Quantity)
                        {
                        }
                        column(UnitOfMeasure_SalesLine; "Sales Line"."Unit of Measure")
                        {
                        }
                        column(QtyToShip_SalesLine; "Sales Line"."Qty. to Ship")
                        {
                        }
                        column(NoCaption_SalesLine; "Sales Line".FieldCaption("No."))
                        {
                        }
                        column(DescCaption_SalesLine; "Sales Line".FieldCaption(Description))
                        {
                        }
                        column(UnitOfMeasureCaption_SalesLine; "Sales Line".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(QtyToShipCaption_SalesLine; "Sales Line".FieldCaption("Qty. to Ship"))
                        {
                        }
                        column(QuantityCaption_SalesLine; "Sales Line".FieldCaption(Quantity))
                        {
                        }
                        column(LineNo_SalesLine; "Sales Line"."Line No.")
                        {
                        }
                        column(EmptyStringCaption; EmptyStringCaptionLbl)
                        {
                        }
                        dataitem("Reservation Entry"; "Reservation Entry")
                        {
                            DataItemTableView = sorting("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Reservation Status", "Shipment Date", "Expected Receipt Date");
                            column(SerialNo_ReservationEntry; "Serial No.")
                            {
                            }
                            column(QtyToHandleBase_ReservationEntry; -"Qty. to Handle (Base)")
                            {
                                DecimalPlaces = 0 : 2;
                            }
                            column(Qty_ReservationEntry; -Quantity)
                            {
                                DecimalPlaces = 0 : 2;
                            }
                            column(LotNo_ReservationEntry; "Lot No.")
                            {
                            }
                            column(SerialNoCaption_ReservationEntry; FieldCaption("Serial No."))
                            {
                            }
                            column(LotNoCaption_ReservationEntry; FieldCaption("Lot No."))
                            {
                            }
                            column(EntryNo_ReservationEntry; "Entry No.")
                            {
                            }
                            column(Positive_ReservationEntry; Positive)
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                SetRange("Source Type", 37);
                                SetRange("Source Subtype", 1);
                                SetRange("Source ID", "Sales Header"."No.");
                                SetFilter("Source Batch Name", '%1', '');
                                SetRange("Source Prod. Order Line", 0);
                                SetRange("Source Ref. No.", "Sales Line"."Line No.");
                            end;
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_DimLoop2; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                DimText := GetDimText();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                DimSetEntry.SetRange("Dimension Set ID", "Sales Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                SalesLine.Find('-')
                            else
                                SalesLine.Next();
                            "Sales Line" := SalesLine;

                            if (SalesLine.Type = SalesLine.Type::"G/L Account") and (not ShowInternalInfo) then
                                "Sales Line"."No." := '';
                        end;

                        trigger OnPostDataItem()
                        begin
                            SalesLine.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := SalesLine.Find('+');
                            while MoreLines and (SalesLine.Description = '') and (SalesLine."Description 2" = '') and
                                  (SalesLine."No." = '') and (SalesLine.Quantity = 0) and
                                  (SalesLine.Amount = 0)
                            do
                                MoreLines := SalesLine.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SalesLine.SetRange("Line No.", 0, SalesLine."Line No.");
                            SetRange(Number, 1, SalesLine.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShipToAddr8; ShipToAddr[8])
                        {
                        }
                        column(ShipToAddr7; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddrCaption; ShipToAddrCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    SalesPost: Codeunit "Sales-Post";
                begin
                    Clear(SalesLine);
                    Clear(SalesPost);
                    SalesPost.GetSalesLines("Sales Header", SalesLine, 0);

                    if Number > 1 then begin
                        CopyText := Text003;
                        OutputNo += 1;
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
                CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := GlobalLanguage.GetFormatRegionOrDefault("Format Region");

                if RespCenter.Get("Responsibility Center") then begin
                    FormatAddr.RespCenter(CompanyAddr, RespCenter);
                    CompanyInfo."Phone No." := RespCenter."Phone No.";
                    CompanyInfo."Fax No." := RespCenter."Fax No.";
                end else
                    FormatAddr.Company(CompanyAddr, CompanyInfo);

                DimSetEntry.SetRange("Dimension Set ID", "Sales Header"."Dimension Set ID");

                if "Salesperson Code" = '' then begin
                    Clear(SalesPurchPerson);
                    SalesPersonText := '';
                end else begin
                    SalesPurchPerson.Get("Salesperson Code");
                    SalesPersonText := Text000;
                end;
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := FieldCaption("VAT Registration No.");
                FormatAddr.SalesHeaderBillTo(CustAddr, "Sales Header");

                if "Shipment Method Code" = '' then
                    ShipmentMethod.Init()
                else
                    ShipmentMethod.Get("Shipment Method Code");

                ShowShippingAddr := FormatAddr.SalesHeaderShipTo(ShipToAddr, CustAddr, "Sales Header");
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
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
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
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
        Text000: Label 'Salesperson';
        Text003: Label 'COPY', Comment = 'copy';
        Text004: Label 'Picking List %1';
        PageCaptionLbl: Label 'Page';
        GLSetup: Record "General Ledger Setup";
        ShipmentMethod: Record "Shipment Method";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo: Record "Company Information";
        SalesLine: Record "Sales Line" temporary;
        RespCenter: Record "Responsibility Center";
        DimSetEntry: Record "Dimension Set Entry";
        GlobalLanguage: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[30];
        VATNoText: Text[30];
        ReferenceText: Text[30];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        OutputNo: Integer;
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        CompanyInfoVATRegNoCaptionLbl: Label 'VAT Reg. No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAcctNoCaptionLbl: Label 'Account No.';
        OrderNoCaptionLbl: Label 'Order No.';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        EmptyStringCaptionLbl: Label 'Quantity delivered';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        ShipmentMethodDescCaptionLbl: Label 'Shipment Method';
        ShipToAddrCaptionLbl: Label 'Ship-to Address';

    local procedure GetDimText() DimText: Text[120]
    begin
        Clear(DimText);
        Continue := false;
        repeat
            OldDimText := DimText;
            if DimText = '' then
                DimText := StrSubstNo('%1 %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
            else
                DimText :=
                  StrSubstNo(
                    '%1, %2 %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                DimText := OldDimText;
                Continue := true;
                exit;
            end;
        until DimSetEntry.Next() = 0;
        exit(DimText);
    end;
}

