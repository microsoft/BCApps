// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Dimension;
#if not CLEAN28
using Microsoft.Finance.SalesTax;
#endif
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 5902 "Service Quote"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Document/ServiceQuote.rdlc';
    Caption = 'Service Quote';
    WordMergeDataItem = "Service Header";

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Quote));
            RequestFilterFields = "No.", "Customer No.";
            column(Service_Header_Document_Type; "Document Type")
            {
            }
            column(Service_Header_No_; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo_Picture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(Service_Header___Order_Time_; "Service Header"."Order Time")
                    {
                    }
                    column(Service_Header___Order_Date_; Format("Service Header"."Order Date"))
                    {
                    }
                    column(Service_Header__Status; "Service Header".Status)
                    {
                    }
                    column(Service_Header___No__; "Service Header"."No.")
                    {
                    }
                    column(CustAddr_6_; CustAddr[6])
                    {
                    }
                    column(CustAddr_5_; CustAddr[5])
                    {
                    }
                    column(CustAddr_4_; CustAddr[4])
                    {
                    }
                    column(CustAddr_3_; CustAddr[3])
                    {
                    }
                    column(CustAddr_2_; CustAddr[2])
                    {
                    }
                    column(CustAddr_1_; CustAddr[1])
                    {
                    }
                    column(CompanyAddr_8_; CompanyAddr[8])
                    {
                    }
                    column(CompanyAddr_7_; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(Service_Header___Bill_to_Name_; "Service Header"."Bill-to Name")
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(STRSUBSTNO_Text001_CopyText_; StrSubstNo(Text001, CopyText))
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(Service_Header___E_Mail_; "Service Header"."E-Mail")
                    {
                    }
                    column(Service_Header___Phone_No__; "Service Header"."Phone No.")
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(Service_Header___Order_Date_Caption; Service_Header___Order_Date_CaptionLbl)
                    {
                    }
                    column(Service_Header___Order_Time_Caption; "Service Header".FieldCaption("Order Time"))
                    {
                    }
                    column(Service_Header__StatusCaption; "Service Header".FieldCaption(Status))
                    {
                    }
                    column(Service_Header___No__Caption; "Service Header".FieldCaption("No."))
                    {
                    }
                    column(Invoice_toCaption; Invoice_toCaptionLbl)
                    {
                    }
                    column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                    {
                    }
                    column(Service_Header___Phone_No__Caption; Service_Header___Phone_No__CaptionLbl)
                    {
                    }
                    column(Service_Header___E_Mail_Caption; Service_Header___E_Mail_CaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimensionLoopNumber; Number)
                        {
                        }
                        column(DimText_Control9; DimText)
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
                                    DimText := StrSubstNo('%1 %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1, %2 %3', DimText,
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
                    dataitem("Service Order Comment"; "Service Comment Line")
                    {
                        DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(General));
                        column(Service_Order_Comment__Line_No__; "Line No.")
                        {
                        }
                        column(Service_Order_Comment_Table_Name; "Table Name")
                        {
                        }
                        column(Service_Order_Comment_Table_Subtype; "Table Subtype")
                        {
                        }
                        column(Service_Order_Comment_No_; "No.")
                        {
                        }
                        column(Service_Order_Comment_Type; Type)
                        {
                        }
                        column(Service_Order_Comment_Table_Line_No_; "Table Line No.")
                        {
                        }
                    }
                    dataitem("Service Item Line"; "Service Item Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(NoOfCopies; NoOfCopies)
                        {
                        }
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(Service_Item_Line__Serial_No__; "Serial No.")
                        {
                        }
                        column(Description_ServLineType; Description)
                        {
                        }
                        column(ServItemNo_ServLineType; "Service Item No.")
                        {
                        }
                        column(Service_Item_Line__Service_Item_Group_Code_; "Service Item Group Code")
                        {
                        }
                        column(Service_Item_Line_Warranty; Warranty)
                        {
                        }
                        column(ItemNo_ServLineType; "Item No.")
                        {
                        }
                        column(Service_Item_Line__Loaner_No__; "Loaner No.")
                        {
                        }
                        column(Service_Item_Line__Service_Shelf_No__; "Service Shelf No.")
                        {
                        }
                        column(Warranty; Format(Warranty))
                        {
                        }
                        column(Service_Item_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Service_Item_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Service_Item_Line_Line_No_; "Line No.")
                        {
                        }
                        column(Service_Item_Line__Serial_No__Caption; FieldCaption("Serial No."))
                        {
                        }
                        column(Service_Item_Line_DescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(Service_Item_Line__Service_Item_No__Caption; FieldCaption("Service Item No."))
                        {
                        }
                        column(Service_Item_Line__Service_Item_Group_Code_Caption; FieldCaption("Service Item Group Code"))
                        {
                        }
                        column(Service_Item_Line__Item_No__Caption; FieldCaption("Item No."))
                        {
                        }
                        column(Service_Item_Line_WarrantyCaption; FieldCaption(Warranty))
                        {
                        }
                        column(Service_Item_LinesCaption; Service_Item_LinesCaptionLbl)
                        {
                        }
                        column(Service_Item_Line__Loaner_No__Caption; FieldCaption("Loaner No."))
                        {
                        }
                        column(Service_Item_Line__Service_Shelf_No__Caption; FieldCaption("Service Shelf No."))
                        {
                        }
                        dataitem("Fault Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Fault));
                            column(Fault_Comment_Comment; Comment)
                            {
                            }
                            column(FaultCommentNumber; Number1)
                            {
                            }
                            column(Fault_Comment_Table_Name; "Table Name")
                            {
                            }
                            column(Fault_Comment_Table_Subtype; "Table Subtype")
                            {
                            }
                            column(Fault_Comment_No_; "No.")
                            {
                            }
                            column(Fault_Comment_Type; Type)
                            {
                            }
                            column(Fault_Comment_Table_Line_No_; "Table Line No.")
                            {
                            }
                            column(Fault_Comment_Line_No_; "Line No.")
                            {
                            }
                            column(Fault_CommentsCaption; Fault_CommentsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Number2 := 0;
                                Number1 := Number1 + 1;
                            end;
                        }
                        dataitem("Resolution Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Resolution));
                            column(Resolution_Comment_Comment; Comment)
                            {
                            }
                            column(ResolutionCommentNumber; Number2)
                            {
                            }
                            column(Resolution_Comment_Table_Name; "Table Name")
                            {
                            }
                            column(Resolution_Comment_Table_Subtype; "Table Subtype")
                            {
                            }
                            column(Resolution_Comment_No_; "No.")
                            {
                            }
                            column(Resolution_Comment_Type; Type)
                            {
                            }
                            column(Resolution_Comment_Table_Line_No_; "Table Line No.")
                            {
                            }
                            column(Resolution_Comment_Line_No_; "Line No.")
                            {
                            }
                            column(Resolution_CommentsCaption; Resolution_CommentsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                Number1 := 0;
                                Number2 := Number2 + 1;
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Number1 := 0;
                            Number2 := 0;
                        end;
                    }
                    dataitem("Service Line"; "Service Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(Service_Line__Service_Item_Serial_No__; "Service Item Serial No.")
                        {
                        }
                        column(Type_ServLine; Type)
                        {
                        }
                        column(Service_Line__No__; "No.")
                        {
                        }
                        column(Service_Line_Description; Description)
                        {
                        }
                        column(Service_Line__Unit_Price_; "Unit Price")
                        {
                        }
                        column(LineDiscount_ServLine; "Line Discount %")
                        {
                        }
                        column(Amt; Amt)
                        {
                        }
                        column(Service_Line__Variant_Code_; "Variant Code")
                        {
                        }
                        column(GrossAmt; GrossAmt)
                        {
                        }
                        column(Quantity_ServLine; Quantity)
                        {
                        }
                        column(TotAmt; TotAmt)
                        {
                        }
                        column(TotGrossAmt; TotGrossAmt)
                        {
                        }
                        column(Service_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Service_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Service_Line_Line_No_; "Line No.")
                        {
                        }
                        column(Service_Line__Service_Item_Serial_No__Caption; FieldCaption("Service Item Serial No."))
                        {
                        }
                        column(Service_Line__No__Caption; FieldCaption("No."))
                        {
                        }
                        column(Service_Line_TypeCaption; FieldCaption(Type))
                        {
                        }
                        column(Service_Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                        {
                        }
                        column(Service_Line_DescriptionCaption; FieldCaption(Description))
                        {
                        }
                        column(Service_LineCaption; Service_LineCaptionLbl)
                        {
                        }
                        column(Service_Line__Unit_Price_Caption; FieldCaption("Unit Price"))
                        {
                        }
                        column(Service_Line__Line_Discount___Caption; FieldCaption("Line Discount %"))
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(Gross_AmountCaption; Gross_AmountCaptionLbl)
                        {
                        }
                        column(Service_Line_QuantityCaption; FieldCaption(Quantity))
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }
                        dataitem(DimesionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_Control12; DimText)
                            {
                            }
                            column(DimesionLoop2_Number; Number)
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
                                        DimText := StrSubstNo('%1 %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1, %2 %3', DimText,
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

                                DimSetEntry2.SetRange("Dimension Set ID", "Service Line"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
#if not CLEAN28
                        var
                            ExchangeFactor: Decimal;
                            ServSalesTaxCalculate: Codeunit "Serv. Sales Tax Calculate";
                            TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
#endif
                        begin
                            Amt := "Line Amount";
#if not CLEAN28
                            if "Service Header"."Currency Factor" = 0 then
                                ExchangeFactor := 1
                            else
                                ExchangeFactor := "Service Header"."Currency Factor";
                            ServSalesTaxCalculate.StartSalesTaxCalculation();
                            ServSalesTaxCalculate.AddServiceLine("Service Line");
                            ServSalesTaxCalculate.EndSalesTaxCalculation("Posting Date");
                            ServSalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmountLine);
                            OnAfterCalculateSalesTax("Service Header", "Service Line", TempSalesTaxAmountLine);
                            GrossAmt := Amt + TempSalesTaxAmountLine.GetTotalTaxAmountFCY();
#else
                            GrossAmt := "Amount Including VAT";
#endif
                            TotAmt := TotAmt + Amt;
                            TotGrossAmt := TotGrossAmt + GrossAmt;
                        end;
                    }
                    dataitem(Shipto; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(ShipToAddr_6_; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr_5_; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr_4_; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr_3_; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr_2_; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr_1_; ShipToAddr[1])
                        {
                        }
                        column(Shipto_Number; Number)
                        {
                        }
                        column(Ship_to_AddressCaption; Ship_to_AddressCaptionLbl)
                        {
                        }
                        column(ShipToPhoneNo; "Service Header"."Ship-to Phone")
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
                begin
                    TotAmt := 0;
                    TotGrossAmt := 0;

                    if Number > 1 then
                        CopyText := FormatDocument.GetCOPYText();
                    OutputNo += 1;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"Service-Printed", "Service Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    if NoOfLoops <= 0 then
                        NoOfLoops := 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
            begin
                CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault("Language Code"));
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Header");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                if not IsReportInPreviewMode() and
                   ((CurrReport.UseRequestPage()) and ArchiveDocument or
                   not (CurrReport.UseRequestPage()) and (ServiceSetup."Archive Quotes" <> ServiceSetup."Archive Quotes"::Never))
                then
                    case ServiceSetup."Archive Quotes" of
                        ServiceSetup."Archive Quotes"::Always:
                            ServiceDocumentArchiveMgmt.ArchServiceDocumentNoConfirm("Service Header");
                        ServiceSetup."Archive Quotes"::Question:
                            begin
                                CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault(LanguageMgt.GetUserLanguageCode()));
                                ServiceDocumentArchiveMgmt.ArchiveServiceDocument("Service Header");
                                CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault("Language Code"));
                            end;
                    end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Quote';
        AboutText = 'Generate a service quote that you can send to your customer.';
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
                        ApplicationArea = Service;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want the printed report to show information that is only for internal use.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Service;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the service quotes that you want to print as interactions and add them to the Interaction Log Entry table.';
                    }
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Service;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies if the document is archived after you preview or print it.';

                        trigger OnValidate()
                        begin
                            if not ArchiveDocument then
                                LogInteraction := false;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Service Quote") <> '';
            LogInteractionEnable := LogInteraction;
            ArchiveDocument := ServiceSetup."Archive Quotes" <> ServiceSetup."Archive Quotes"::Never;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        ServiceSetup.Get();

#if not CLEAN28
        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                CompanyInfo.CalcFields(Picture);
            ServiceSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
#else
        FormatDocument.SetLogoPosition(ServiceSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);
#endif
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Service Header".FindSet() then
                repeat
                    "Service Header".CalcFields("No. of Archived Versions");
                    if "Service Header"."Contact No." <> '' then
                        SegManagement.LogDocument(25, "Service Header"."No.", "Service Header"."Doc. No. Occurrence",
                         "Service Header"."No. of Archived Versions", Database::Contact, "Service Header"."Contact No.",
                          "Service Header"."Salesperson Code", '', '', '')
                    else
                        SegManagement.LogDocument(25, "Service Header"."No.", "Service Header"."Doc. No. Occurrence",
                        "Service Header"."No. of Archived Versions", Database::Customer, "Service Header"."Customer No.",
                          "Service Header"."Salesperson Code", '', '', '');
                until "Service Header".Next() = 0;
    end;

    var
#if CLEAN28
        CompanyInfo3: Record "Company Information";
#endif
        ServiceSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        Number1: Integer;
        Number2: Integer;
        ArchiveDocument: Boolean;
        ShowInternalInfo: Boolean;
        ShowShippingAddr: Boolean;
        Continue: Boolean;
        CopyText: Text[30];
        CompanyAddr: array[8] of Text[100];
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        DimText: Text[120];
        OldDimText: Text[120];
        Amt: Decimal;
        TotAmt: Decimal;
        LogInteraction: Boolean;
        GrossAmt: Decimal;
        TotGrossAmt: Decimal;
        OutputNo: Integer;
        LogInteractionEnable: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Service Quote %1';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Service_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Invoice_toCaptionLbl: Label 'Invoice to';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        Service_Header___Phone_No__CaptionLbl: Label 'Phone No.';
        Service_Header___E_Mail_CaptionLbl: Label 'Email';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Service_Item_LinesCaptionLbl: Label 'Service Item Lines';
        Fault_CommentsCaptionLbl: Label 'Fault Comments';
        Resolution_CommentsCaptionLbl: Label 'Resolution Comments';
        Service_LineCaptionLbl: Label 'Service Line';
        AmtCaptionLbl: Label 'Amount';
        Gross_AmountCaptionLbl: Label 'Gross Amount';
        TotalCaptionLbl: Label 'Total';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ServiceHeader: Record "Service Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        FormatAddr.GetCompanyAddr(ServiceHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        ServiceFormatAddress.ServiceOrderSellto(CustAddr, ServiceHeader);
        ShowShippingAddr := ServiceHeader."Ship-to Code" <> '';
        if ShowShippingAddr then
            ServiceFormatAddress.ServiceOrderShipto(ShipToAddr, ServiceHeader);
    end;

#if not CLEAN28
    internal procedure RunOnAfterCalculateSalesTax(var ServiceHeaderParm: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
        OnAfterCalculateSalesTax(ServiceHeaderParm, ServiceLine, SalesTaxAmountLineParm);
    end;

    [Obsolete('Replaced by report Sales Quote NA', '28.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTax(var ServiceHeaderParm: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLineParm: Record "Sales Tax Amount Line")
    begin
    end;
#endif
}

