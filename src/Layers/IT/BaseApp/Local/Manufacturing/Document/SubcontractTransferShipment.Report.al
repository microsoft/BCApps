// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 12154 "Subcontract. Transfer Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Manufacturing/Document/SubcontractTransferShipment.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Subcontracting Transfer Shipment';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Transfer-from Code", "Transfer-to Code";
            RequestFilterHeading = 'Posted Transfer Shipment';
            column(Transfer_Shipment_Header_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(Text1130001; Text1130001Lbl)
                    {
                    }
                    column(TransferToAddr_1_; TransferToAddr[1])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(TransferToAddr_2_; TransferToAddr[2])
                    {
                    }
                    column(TransferToAddr_3_; TransferToAddr[3])
                    {
                    }
                    column(TransferToAddr_4_; TransferToAddr[4])
                    {
                    }
                    column(TransferToAddr_5_; TransferToAddr[5])
                    {
                    }
                    column(TransferToAddr_6_; TransferToAddr[6])
                    {
                    }
                    column(Transfer_Shipment_Header___No__; "Transfer Shipment Header"."No.")
                    {
                    }
                    column(TransferToAddr_7_; TransferToAddr[7])
                    {
                    }
                    column(TransferToAddr_8_; TransferToAddr[8])
                    {
                    }
                    column(Transfer_Shipment_Header___Posting_Date_; Format("Transfer Shipment Header"."Posting Date"))
                    {
                    }
                    column(Transfer_Shipment_Header___Goods_Appearance_; "Transfer Shipment Header"."Goods Appearance")
                    {
                    }
                    column(CompanyInfo_Picture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyText_1_; CompanyText[1])
                    {
                    }
                    column(CompanyText_3_; CompanyText[3])
                    {
                    }
                    column(CompanyText_4_; CompanyText[4])
                    {
                    }
                    column(CompanyText_2_; CompanyText[2])
                    {
                    }
                    column(Transfer_Shipment_Header___Gross_Weight_; "Transfer Shipment Header"."Gross Weight")
                    {
                    }
                    column(Transfer_Shipment_Header___Net_Weight_; "Transfer Shipment Header"."Net Weight")
                    {
                    }
                    column(Transfer_Shipment_Header___Parcel_Units_; "Transfer Shipment Header"."Parcel Units")
                    {
                    }
                    column(Transfer_Shipment_Header___Freight_Type_; "Transfer Shipment Header"."Freight Type")
                    {
                    }
                    column(ShipmentMethod_Description; ShipmentMethod.Description)
                    {
                    }
                    column(TransportReasonCode_Description; TransportReasonCode.Description)
                    {
                    }
                    column(VendorAddr_6_; VendorAddr[6])
                    {
                    }
                    column(VendorAddr_5_; VendorAddr[5])
                    {
                    }
                    column(VendorAddr_4_; VendorAddr[4])
                    {
                    }
                    column(VendorAddr_3_; VendorAddr[3])
                    {
                    }
                    column(VendorAddr_2_; VendorAddr[2])
                    {
                    }
                    column(VendorAddr_1_; VendorAddr[1])
                    {
                    }
                    column(VendorAddr_7_; VendorAddr[7])
                    {
                    }
                    column(VendorAddr_8_; VendorAddr[8])
                    {
                    }
                    column(LablVendor; LablVendor)
                    {
                    }
                    column(CopyText; CopyText)
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text1130002, ''))
                    {
                    }
                    column(NoOfCopies; NoOfCopies)
                    {
                    }
                    column(ShowInternalInfo; ShowInternalInfo)
                    {
                    }
                    column(ShowDescr2; ShowDescr2)
                    {
                    }
                    column(Text1130001_Control1130557; Text1130001Lbl)
                    {
                    }
                    column(CopyText_Control1130558; CopyText)
                    {
                    }
                    column(CompanyAddr_2__Control1130565; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_3__Control1130566; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_5__Control1130567; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_4__Control1130568; CompanyAddr[4])
                    {
                    }
                    column(CompanyText_1__Control1130569; CompanyText[1])
                    {
                    }
                    column(CompanyText_3__Control1130570; CompanyText[3])
                    {
                    }
                    column(CompanyText_2__Control1130571; CompanyText[2])
                    {
                    }
                    column(CompanyInfo_Picture_Control1130572; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyText_4__Control1130574; CompanyText[4])
                    {
                    }
                    column(Transfer_Shipment_Header___Posting_Date__Control1130560; Format("Transfer Shipment Header"."Posting Date"))
                    {
                    }
                    column(Transfer_Shipment_Header___No___Control1130561; "Transfer Shipment Header"."No.")
                    {
                    }
                    column(Transfer_Shipment_Header___Shipping_Starting_Date_; "Transfer Shipment Header"."Shipping Starting Date")
                    {
                    }
                    column(Transfer_Shipment_Header___Shipping_Starting_Time_; "Transfer Shipment Header"."Shipping Starting Time")
                    {
                    }
                    column(ShippingAgent_Name; ShippingAgent.Name)
                    {
                    }
                    column(ShippingAgent_Address; ShippingAgent.Address)
                    {
                    }
                    column(Transfer_Shipment_Header___Shipping_Notes_; "Transfer Shipment Header"."Shipping Notes")
                    {
                    }
                    column(CopyText_Control1130554; CopyText)
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(Transfer_Shipment_Header___No__Caption; Transfer_Shipment_Header___No__CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Posting_Date_Caption; Transfer_Shipment_Header___Posting_Date_CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Goods_Appearance_Caption; "Transfer Shipment Header".FieldCaption("Goods Appearance"))
                    {
                    }
                    column(Ship_to_Caption; Ship_to_CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Gross_Weight_Caption; "Transfer Shipment Header".FieldCaption("Gross Weight"))
                    {
                    }
                    column(Transfer_Shipment_Header___Net_Weight_Caption; "Transfer Shipment Header".FieldCaption("Net Weight"))
                    {
                    }
                    column(Transfer_Shipment_Header___Parcel_Units_Caption; "Transfer Shipment Header".FieldCaption("Parcel Units"))
                    {
                    }
                    column(Transfer_Shipment_Header___Freight_Type_Caption; Transfer_Shipment_Header___Freight_Type_CaptionLbl)
                    {
                    }
                    column(ShipmentMethod_DescriptionCaption; ShipmentMethod_DescriptionCaptionLbl)
                    {
                    }
                    column(TransportReasonCode_DescriptionCaption; TransportReasonCode_DescriptionCaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___No___Control1130561Caption; Transfer_Shipment_Header___No___Control1130561CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Posting_Date__Control1130560Caption; Transfer_Shipment_Header___Posting_Date__Control1130560CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Shipping_Starting_Date_Caption; Transfer_Shipment_Header___Shipping_Starting_Date_CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Shipping_Starting_Time_Caption; Transfer_Shipment_Header___Shipping_Starting_Time_CaptionLbl)
                    {
                    }
                    column(Transfer_Shipment_Header___Shipping_Notes_Caption; Transfer_Shipment_Header___Shipping_Notes_CaptionLbl)
                    {
                    }
                    column(ShippingAgent_NameCaption; ShippingAgent_NameCaptionLbl)
                    {
                    }
                    column(ShippingAgent_AddressCaption; ShippingAgent_AddressCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Transfer Shipment Header";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimText_Control1130053; DimText)
                        {
                        }
                        column(DimensionLoop1_Number; Number)
                        {
                        }
                        column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            DimSetEntry: Record "Dimension Set Entry";
                        begin
                            if Number = 1 then begin
                                if "Transfer Shipment Header"."Dimension Set ID" = 0 then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();
                            Clear(DimText);
                            Continue := false;

                            DimSetEntry.SetRange("Dimension Set ID", "Transfer Shipment Header"."Dimension Set ID");
                            DimSetEntry.FindSet();
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo(
                                        '%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText,
                                        DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Transfer Shipment Line"; "Transfer Shipment Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Transfer Shipment Header";
                        DataItemTableView = sorting("Document No.", "Line No.") where(Quantity = filter(<> 0));
                        column(RefSubcOrd; RefSubcOrd)
                        {
                        }
                        column(EmptyString; '')
                        {
                        }
                        column(RefProdOrd; RefProdOrd)
                        {
                        }
                        column(Transfer_Shipment_Line__Transfer_Shipment_Line___Line_No__; "Transfer Shipment Line"."Line No.")
                        {
                        }
                        column(Transfer_Shipment_Line__Item_No__; "Item No.")
                        {
                        }
                        column(Transfer_Shipment_Line_Description; Description)
                        {
                        }
                        column(Transfer_Shipment_Line_Quantity; Quantity)
                        {
                        }
                        column(Transfer_Shipment_Line__Unit_of_Measure_; "Unit of Measure")
                        {
                        }
                        column(Transfer_Shipment_Line__Description_2_; "Description 2")
                        {
                        }
                        column(Text1130007; Text1130007Lbl)
                        {
                        }
                        column(Transfer_Shipment_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Transfer_Shipment_Line__Unit_of_Measure_Caption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Transfer_Shipment_Line_QuantityCaption; FieldCaption(Quantity))
                        {
                        }
                        column(Transfer_Shipment_Line_DescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(Transfer_Shipment_Line__Item_No__Caption; FieldCaption("Item No."))
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_Control1130071; DimText)
                            {
                            }
                            column(DimText_Control1130073; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            var
                                DimSetEntry: Record "Dimension Set Entry";
                            begin
                                if Number = 1 then begin
                                    if "Transfer Shipment Line"."Dimension Set ID" = 0 then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;

                                DimSetEntry.SetRange("Dimension Set ID", "Transfer Shipment Line"."Dimension Set ID");
                                DimSetEntry.FindFirst();
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo(
                                            '%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText,
                                            DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until (DimSetEntry.Next() = 0);
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if ("Subcontr. Purch. Order No." <> PrevSubcOrd) and ("Subcontr. Purch. Order No." <> '') then begin
                                PrevSubcOrd := "Subcontr. Purch. Order No.";
                                RefSubcOrd := FieldCaption("Subcontr. Purch. Order No.") + ' ' + "Subcontr. Purch. Order No.";
                            end else
                                RefSubcOrd := '';

                            if ("Prod. Order No." <> PrevProdOrd) and ("Prod. Order No." <> '') then begin
                                PrevProdOrd := "Prod. Order No.";
                                RefProdOrd := FieldCaption("Prod. Order No.") + ' ' + "Prod. Order No.";
                            end else
                                RefProdOrd := '';
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("Item No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    CopyText := Text1130004;
                    if Number = 2 then
                        CopyText := Text1130005;
                    if Number = 3 then
                        CopyText := Text1130006;
                    if Number > 3 then
                        CopyText := Text1130000;

                    if Number > 1 then
                        OutputNo += 1;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := 1 + Abs(NoOfCopies);
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);

                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.TransferShptTransferTo(TransferToAddr, "Transfer Shipment Header");
                if "Source Type" = "Source Type"::Vendor then begin
                    LablVendor := Text1130003;
                    Vendor.Get("Source No.");
                    FormatAddr.Vendor(VendorAddr, Vendor);
                end else begin
                    LablVendor := '';
                    Clear(VendorAddr);
                end;

                if not ShipmentMethod.Get("Shipment Method Code") then
                    ShipmentMethod.Init();

                if not ShippingAgent.Get("Shipping Agent Code") then
                    ShippingAgent.Init();

                if not TransportReasonCode.Get("Transport Reason Code") then
                    TransportReasonCode.Init();
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompanyInfo.CalcFields(Picture);
                FormatAddr.Company(CompanyAddr, CompanyInfo);

                i := 1;
                if CompanyInfo."REA No." <> '' then
                    CompanyText[i] := CompanyInfo.FieldCaption("REA No.") + ' ' + CompanyInfo."REA No." + '  ';

                if CompanyInfo."VAT Registration No." <> '' then begin
                    DummyText := CompanyInfo.FieldCaption("VAT Registration No.") + ' ' + CompanyInfo."VAT Registration No." + '  ';
                    TransferText();
                end;

                if CompanyInfo."Register Company No." <> '' then begin
                    DummyText := CompanyInfo.FieldCaption("Register Company No.") + ' ' + CompanyInfo."Register Company No." + '  ';
                    TransferText();
                end;

                i += 1;
                if CompanyInfo."Phone No." <> '' then
                    CompanyText[i] := CompanyInfo.FieldCaption("Phone No.") + ' ' + CompanyInfo."Phone No." + '  ';

                if CompanyInfo."Fax No." <> '' then begin
                    DummyText := CompanyInfo.FieldCaption("Fax No.") + ' ' + CompanyInfo."Fax No." + '  ';
                    TransferText();
                end;

                if CompanyInfo."E-Mail" <> '' then begin
                    DummyText := CompanyInfo.FieldCaption("E-Mail") + ' ' + CompanyInfo."E-Mail" + '  ';
                    TransferText();
                end;

                if CompanyInfo."Home Page" <> '' then begin
                    DummyText := CompanyInfo.FieldCaption("Home Page") + ' ' + CompanyInfo."Home Page" + '  ';
                    TransferText();
                end;
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
                        ToolTip = 'Specifies the number of copies.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want to see internal information.';
                    }
                    field(ShowDescr2; ShowDescr2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Description 2';
                        ToolTip = 'Specifies if you want to print additional information.';
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
        Text1130000: Label 'COPY';
        Text1130002: Label 'Page %1';
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        TransportReasonCode: Record "Transport Reason Code";
        FormatAddr: Codeunit "Format Address";
        TransferToAddr: array[8] of Text[100];
        VendorAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        CompanyText: array[4] of Text[60];
        DummyText: Text[60];
        LablVendor: Text[30];
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        RefSubcOrd: Text[50];
        RefProdOrd: Text[50];
        PrevSubcOrd: Code[20];
        PrevProdOrd: Code[20];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        Length: Integer;
        i: Integer;
        ShowInternalInfo: Boolean;
        ShowDescr2: Boolean;
        Continue: Boolean;
        Text1130003: Label 'Messrs.';
        Text1130004: Label 'ORIGINAL';
        Text1130005: Label 'AGENT COPY';
        Text1130006: Label 'CARRIAGE CONSIGNER COPY';
        OutputNo: Integer;
        Text1130001Lbl: Label 'Transfer Shipment ';
        Transfer_Shipment_Header___No__CaptionLbl: Label 'Shipment No.';
        Transfer_Shipment_Header___Posting_Date_CaptionLbl: Label 'Date';
        Ship_to_CaptionLbl: Label 'Ship to:';
        Transfer_Shipment_Header___Freight_Type_CaptionLbl: Label 'Freight Type';
        ShipmentMethod_DescriptionCaptionLbl: Label 'Shipment Method';
        TransportReasonCode_DescriptionCaptionLbl: Label 'Reason Code';
        Transfer_Shipment_Header___No___Control1130561CaptionLbl: Label 'Shipment No.';
        Transfer_Shipment_Header___Posting_Date__Control1130560CaptionLbl: Label 'Date';
        Transfer_Shipment_Header___Shipping_Starting_Date_CaptionLbl: Label 'Shipping Starting Date';
        Transfer_Shipment_Header___Shipping_Starting_Time_CaptionLbl: Label 'Shipping Starting Time';
        Transfer_Shipment_Header___Shipping_Notes_CaptionLbl: Label 'Notes:';
        ShippingAgent_NameCaptionLbl: Label 'Shipping Agent';
        ShippingAgent_AddressCaptionLbl: Label 'Shipping Agent Address';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Text1130007Lbl: Label 'Continue';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';

    [Scope('OnPrem')]
    procedure TransferText()
    begin
        Length := StrLen(DummyText);
        if Length <= MaxStrLen(CompanyText[i]) - StrLen(CompanyText[i]) then
            CompanyText[i] += DummyText
        else
            if i < ArrayLen(CompanyText) then begin
                i += 1;
                CompanyText[i] := DummyText;
            end;
    end;
}

