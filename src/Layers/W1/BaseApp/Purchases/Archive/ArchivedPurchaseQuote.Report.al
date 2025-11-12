// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 415 "Archived Purchase Quote"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Archive/ArchivedPurchaseQuote.rdlc';
    Caption = 'Archived Purchase Quote';
    WordMergeDataItem = "Purchase Header Archive";

    dataset
    {
        dataitem("Purchase Header Archive"; "Purchase Header Archive")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Quote));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Archived Purchase Quote';
            column(Purchase_Header_Archive_Document_Type; "Document Type")
            {
            }
            column(Purchase_Header_Archive_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(STRSUBSTNO_Text002_CopyText_; StrSubstNo(Text002, CopyText))
                    {
                    }
                    column(VendAddr_1_; VendAddr[1])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(VendAddr_2_; VendAddr[2])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(VendAddr_3_; VendAddr[3])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(VendAddr_4_; VendAddr[4])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(VendAddr_5_; VendAddr[5])
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(VendAddr_6_; VendAddr[6])
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
                    column(Purchase_Header_Archive___Pay_to_Vendor_No__; "Purchase Header Archive"."Pay-to Vendor No.")
                    {
                    }
                    column(FORMAT__Purchase_Header_Archive___Document_Date__0_4_; Format("Purchase Header Archive"."Document Date", 0, 4))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(Purchase_Header_Archive___VAT_Registration_No__; "Purchase Header Archive"."VAT Registration No.")
                    {
                    }
                    column(Purchase_Header_Archive___Expected_Receipt_Date_; Format("Purchase Header Archive"."Expected Receipt Date"))
                    {
                    }
                    column(PurchaserText; PurchaserText)
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(Purchase_Header_Archive___No__; "Purchase Header Archive"."No.")
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(Purchase_Header_Archive___Your_Reference_; "Purchase Header Archive"."Your Reference")
                    {
                    }
                    column(VendAddr_7_; VendAddr[7])
                    {
                    }
                    column(VendAddr_8_; VendAddr[8])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
                    column(STRSUBSTNO_Text004__Purchase_Header_Archive___Version_No____Purchase_Header_Archive___No__of_Archived_Versions__; StrSubstNo(Text004, "Purchase Header Archive"."Version No.", "Purchase Header Archive"."No. of Archived Versions"))
                    {
                    }
                    column(OutpuNo; OutputNo)
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
                    column(Purchase_Header_Archive___Pay_to_Vendor_No__Caption; "Purchase Header Archive".FieldCaption("Pay-to Vendor No."))
                    {
                    }
                    column(Expected_DateCaption; Expected_DateCaptionLbl)
                    {
                    }
                    column(Quote_No_Caption; Quote_No_CaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Purchase Header Archive";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Purchase Line Archive"; "Purchase Line Archive")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Purchase Header Archive";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(PurchaseLineType; PurchaseLineArchiveType)
                        {
                        }
                        column(Purchase_Line_Archive__Description; "Purchase Line Archive".Description)
                        {
                        }
                        column(Purchase_Line_Archive__Quantity; "Purchase Line Archive".Quantity)
                        {
                        }
                        column(Purchase_Line_Archive___Unit_of_Measure_; "Purchase Line Archive"."Unit of Measure")
                        {
                        }
                        column(Purchase_Line_Archive___Expected_Receipt_Date_; Format("Purchase Line Archive"."Expected Receipt Date"))
                        {
                        }
                        column(Purchase_Line_Archive___Expected_Receipt_Date__Control55; Format("Purchase Line Archive"."Expected Receipt Date"))
                        {
                        }
                        column(Purchase_Line_Archive___Unit_of_Measure__Control54; "Purchase Line Archive"."Unit of Measure")
                        {
                        }
                        column(Purchase_Line_Archive__Quantity_Control53; "Purchase Line Archive".Quantity)
                        {
                        }
                        column(Purchase_Line_Archive__Description_Control52; "Purchase Line Archive".Description)
                        {
                        }
                        column(Purchase_Line_Archive___No__; "Purchase Line Archive"."No.")
                        {
                        }
                        column(Purchase_Line_Archive___Vendor_Item_No__; "Purchase Line Archive"."Vendor Item No.")
                        {
                        }
                        column(Purchase_Line_Archive___Expected_Receipt_Date__Control55Caption; Purchase_Line_Archive___Expected_Receipt_Date__Control55CaptionLbl)
                        {
                        }
                        column(Purchase_Line_Archive___Unit_of_Measure__Control54Caption; "Purchase Line Archive".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Purchase_Line_Archive__Quantity_Control53Caption; "Purchase Line Archive".FieldCaption(Quantity))
                        {
                        }
                        column(Purchase_Line_Archive__Description_Control52Caption; "Purchase Line Archive".FieldCaption(Description))
                        {
                        }
                        column(Purchase_Line_Archive___No__Caption; Purchase_Line_Archive___No__CaptionLbl)
                        {
                        }
                        column(Purchase_Line_Archive___Vendor_Item_No__Caption; Purchase_Line_Archive___Vendor_Item_No__CaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_Control60; DimText)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TempPurchaseLineArchive.Find('-')
                            else
                                TempPurchaseLineArchive.Next();
                            "Purchase Line Archive" := TempPurchaseLineArchive;

                            DimSetEntry2.SetRange("Dimension Set ID", "Purchase Line Archive"."Dimension Set ID");

                            PurchaseLineArchiveType := "Purchase Line Archive".Type.AsInteger();
                        end;

                        trigger OnPostDataItem()
                        begin
                            TempPurchaseLineArchive.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := TempPurchaseLineArchive.Find('+');
                            while MoreLines and (TempPurchaseLineArchive.Description = '') and (TempPurchaseLineArchive."Description 2" = '') and
                                  (TempPurchaseLineArchive."No." = '') and (TempPurchaseLineArchive.Quantity = 0) and
                                  (TempPurchaseLineArchive.Amount = 0)
                            do
                                MoreLines := TempPurchaseLineArchive.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempPurchaseLineArchive.SetRange("Line No.", 0, TempPurchaseLineArchive."Line No.");
                            SetRange(Number, 1, TempPurchaseLineArchive.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShipmentMethod_Description; ShipmentMethod.Description)
                        {
                        }
                        column(ShipmentMethod_DescriptionCaption; ShipmentMethod_DescriptionCaptionLbl)
                        {
                        }
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Purchase_Header_Archive___Buy_from_Vendor_No__; "Purchase Header Archive"."Buy-from Vendor No.")
                        {
                        }
                        column(Purchase_Header_Archive___Buy_from_Vendor_No__Caption; "Purchase Header Archive".FieldCaption("Buy-from Vendor No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if "Purchase Header Archive"."Buy-from Vendor No." = "Purchase Header Archive"."Pay-to Vendor No." then
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
                        column(Ship_to_AddressCaption; Ship_to_AddressCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if ("Purchase Header Archive"."Sell-to Customer No." = '') and (ShipToAddr[1] = '') then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    PurchLineArchive2: Record "Purchase Line Archive";
                begin
                    Clear(TempPurchaseLineArchive);
                    TempPurchaseLineArchive.DeleteAll();
                    PurchLineArchive2.SetRange("Document Type", "Purchase Header Archive"."Document Type");
                    PurchLineArchive2.SetRange("Document No.", "Purchase Header Archive"."No.");
                    PurchLineArchive2.SetRange("Version No.", "Purchase Header Archive"."Version No.");
                    if PurchLineArchive2.FindSet() then
                        repeat
                            TempPurchaseLineArchive := PurchLineArchive2;
                            TempPurchaseLineArchive.Insert();
                        until PurchLineArchive2.Next() = 0;

                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Purch.HeaderArch-Printed", "Purchase Header Archive");
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
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Purchase Header Archive");
                FormatDocumentFields("Purchase Header Archive");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                CalcFields("No. of Archived Versions");
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
                        ApplicationArea = Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Suite;
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
        CompanyInfo.Get();
    end;

    var
        ShipmentMethod: Record "Shipment Method";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyInfo: Record "Company Information";
        TempPurchaseLineArchive: Record "Purchase Line Archive" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        VendAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        PurchaserText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        OutputNo: Integer;
        PurchaseLineArchiveType: Integer;

#pragma warning disable AA0074
        Text002: Label 'Purchase - Quote Archived %1', Comment = '%1 = Document No.';
#pragma warning disable AA0470
        Text004: Label 'Version %1 of %2 ';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        Expected_DateCaptionLbl: Label 'Expected Date';
        Quote_No_CaptionLbl: Label 'Quote No.';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Purchase_Line_Archive___Expected_Receipt_Date__Control55CaptionLbl: Label 'Expected Date';
        Purchase_Line_Archive___No__CaptionLbl: Label 'Our No.';
        Purchase_Line_Archive___Vendor_Item_No__CaptionLbl: Label 'No.';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        ShipmentMethod_DescriptionCaptionLbl: Label 'Shipment Method';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var PurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
        FormatAddr.GetCompanyAddr(PurchaseHeaderArchive."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.PurchHeaderPayToArch(VendAddr, PurchaseHeaderArchive);
        FormatAddr.PurchHeaderShipToArch(ShipToAddr, PurchaseHeaderArchive);
    end;

    local procedure FormatDocumentFields(PurchaseHeaderArchive: Record "Purchase Header Archive")
    begin
        FormatDocument.SetPurchaser(SalesPurchPerson, PurchaseHeaderArchive."Purchaser Code", PurchaserText);
        FormatDocument.SetShipmentMethod(ShipmentMethod, PurchaseHeaderArchive."Shipment Method Code", PurchaseHeaderArchive."Language Code");

        ReferenceText := FormatDocument.SetText(PurchaseHeaderArchive."Your Reference" <> '', PurchaseHeaderArchive.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(PurchaseHeaderArchive."VAT Registration No." <> '', PurchaseHeaderArchive.FieldCaption("VAT Registration No."));
    end;
}

