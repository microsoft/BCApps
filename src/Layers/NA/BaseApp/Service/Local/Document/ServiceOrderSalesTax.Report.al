// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 10470 "Service Order-Sales Tax"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Local/Document/ServiceOrderSalesTax.rdlc';
    Caption = 'Service Order';
    WordMergeDataItem = "Service Header";

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Customer No.";
            column(Service_Header_Document_Type; "Document Type")
            {
            }
            column(No_ServHeader; "No.")
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
                    column(Service_Header___Contract_No__; "Service Header"."Contract No.")
                    {
                    }
                    column(Service_Header___Order_Time_; "Service Header"."Order Time")
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
                    column(Service_Header___Order_Date_; Format("Service Header"."Order Date"))
                    {
                    }
                    column(CustAddr_3_; CustAddr[3])
                    {
                    }
                    column(Service_Header__Status; "Service Header".Status)
                    {
                    }
                    column(CustAddr_2_; CustAddr[2])
                    {
                    }
                    column(Service_Header___No__; "Service Header"."No.")
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
                    column(Service_Header___Phone_No__; "Service Header"."Phone No.")
                    {
                    }
                    column(Service_Header___E_Mail_; "Service Header"."E-Mail")
                    {
                    }
                    column(Service_Header__Description; "Service Header".Description)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ' '))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(Contract_No_Caption; Contract_No_CaptionLbl)
                    {
                    }
                    column(Service_Header___Order_Time_Caption; "Service Header".FieldCaption("Order Time"))
                    {
                    }
                    column(Service_Header___Order_Date_Caption; Service_Header___Order_Date_CaptionLbl)
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
                    column(Service_Header__DescriptionCaption; "Service Header".FieldCaption(Description))
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimText_Control11; DimText)
                        {
                        }
                        column(DimensionLoop1_Number; Number)
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
                        column(Service_Order_Comment_Comment; Comment)
                        {
                        }
                        column(ServiceOrderComment_TabName; "Table Name")
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
                        column(Service_Order_Comment_Line_No_; "Line No.")
                        {
                        }
                    }
                    dataitem("Service Item Line"; "Service Item Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(Service_Item_Line___Line_No__; "Service Item Line"."Line No.")
                        {
                        }
                        column(SerialNo_ServItemLine; "Serial No.")
                        {
                        }
                        column(Service_Item_Line_Description; Description)
                        {
                        }
                        column(Service_Item_Line__Service_Item_No__; "Service Item No.")
                        {
                        }
                        column(ServItemGroupCode_ServItemLine; "Service Item Group Code")
                        {
                        }
                        column(Service_Item_Line_Warranty; Format(Warranty))
                        {
                        }
                        column(Service_Item_Line__Loaner_No__; "Loaner No.")
                        {
                        }
                        column(Service_Item_Line__Repair_Status_Code_; "Repair Status Code")
                        {
                        }
                        column(Service_Item_Line__Service_Shelf_No__; "Service Shelf No.")
                        {
                        }
                        column(Service_Item_Line__Response_Time_; Format("Response Time"))
                        {
                        }
                        column(Service_Item_Line__Response_Date_; Format("Response Date"))
                        {
                        }
                        column(Service_Item_Line_Document_Type; "Document Type")
                        {
                        }
                        column(Service_Item_Line_Document_No_; "Document No.")
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
                        column(Service_Item_Line_WarrantyCaption; CaptionClassTranslate(FieldCaption(Warranty)))
                        {
                        }
                        column(Service_Item_LinesCaption; Service_Item_LinesCaptionLbl)
                        {
                        }
                        column(Service_Item_Line__Loaner_No__Caption; FieldCaption("Loaner No."))
                        {
                        }
                        column(Service_Item_Line__Repair_Status_Code_Caption; FieldCaption("Repair Status Code"))
                        {
                        }
                        column(Service_Item_Line__Service_Shelf_No__Caption; FieldCaption("Service Shelf No."))
                        {
                        }
                        column(Service_Item_Line__Response_Date_Caption; Service_Item_Line__Response_Date_CaptionLbl)
                        {
                        }
                        column(Service_Item_Line__Response_Time_Caption; Service_Item_Line__Response_Time_CaptionLbl)
                        {
                        }
                        dataitem("Fault Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Fault));
                            column(Comment_FaultComment; Comment)
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
                        }
                        dataitem("Resolution Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Resolution));
                            column(Comment_ResolutionComment; Comment)
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
                        }
                    }
                    dataitem("Service Line"; "Service Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(Service_Line___Line_No__; "Service Line"."Line No.")
                        {
                        }
                        column(TotalAmt; TotalAmt)
                        {
                        }
                        column(TotalGrossAmt; TotalGrossAmt)
                        {
                        }
                        column(Service_Line__Service_Item_Serial_No__; "Service Item Serial No.")
                        {
                        }
                        column(Type_ServLine; Type)
                        {
                        }
                        column(Service_Line__No__; "No.")
                        {
                        }
                        column(Service_Line__Variant_Code_; "Variant Code")
                        {
                        }
                        column(Service_Line_Description; Description)
                        {
                        }
                        column(Qty; Qty)
                        {
                        }
                        column(UnitPrice_ServLine; "Unit Price")
                        {
                        }
                        column(Service_Line__Line_Discount___; "Line Discount %")
                        {
                        }
                        column(Amt; Amt)
                        {
                        }
                        column(GrossAmt; GrossAmt)
                        {
                        }
                        column(Service_Line__Quantity_Consumed_; "Quantity Consumed")
                        {
                        }
                        column(Service_Line__Qty__to_Consume_; "Qty. to Consume")
                        {
                        }
                        column(Amt_Control63; Amt)
                        {
                        }
                        column(GrossAmt_Control65; GrossAmt)
                        {
                        }
                        column(Service_Line_Document_Type; "Document Type")
                        {
                        }
                        column(DocumentNo_ServLine; "Document No.")
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
                        column(QtyCaption; QtyCaptionLbl)
                        {
                        }
                        column(Service_LinesCaption; Service_LinesCaptionLbl)
                        {
                        }
                        column(Service_Line__Unit_Price_Caption; FieldCaption("Unit Price"))
                        {
                        }
                        column(Service_Line__Line_Discount___Caption; FieldCaption("Line Discount %"))
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Gross_AmountCaption; Gross_AmountCaptionLbl)
                        {
                        }
                        column(Service_Line__Quantity_Consumed_Caption; FieldCaption("Quantity Consumed"))
                        {
                        }
                        column(Service_Line__Qty__to_Consume_Caption; FieldCaption("Qty. to Consume"))
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_Control13; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
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
                        var
                            ExchangeFactor: Decimal;
                            ServSalesTaxCalculate: Codeunit "Serv. Sales Tax Calculate";
                            TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
                        begin
                            if ShowQty = ShowQty::Quantity then begin
                                Qty := Quantity;
                                Amt := "Line Amount";
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
                            end else begin
                                if "Quantity Invoiced" = 0 then
                                    CurrReport.Skip();
                                Qty := "Quantity Invoiced";

                                Amt := Round((Qty * "Unit Price") * (1 - "Line Discount %" / 100));
                                GrossAmt := (1 + "VAT %" / 100) * Amt;
                            end;

                            TotalAmt += Amt;
                            TotalGrossAmt += GrossAmt;
                        end;

                        trigger OnPreDataItem()
                        begin
                            Clear(Amt);
                            Clear(GrossAmt);

                            TotalAmt := 0;
                            TotalGrossAmt := 0;
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
                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;
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
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Header");

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                if not IsReportInPreviewMode() and
                   ((CurrReport.UseRequestPage()) and ArchiveDocument or
                   not (CurrReport.UseRequestPage()) and (ServiceSetup."Archive Orders"))
                then begin
                    CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault(LanguageMgt.GetUserLanguageCode()));
                    ServiceDocumentArchiveMgmt.ArchServiceDocumentNoConfirm("Service Header");
                    CurrReport.Language(LanguageMgt.GetLanguageIdOrDefault("Language Code"));
                end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Order';
        AboutText = 'Generate a service order document that you can send to your customer.';

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
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Service;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies if the document is archived after you preview or print it.';
                    }
                    field(ShowQty; ShowQty)
                    {
                        ApplicationArea = Service;
                        Caption = 'Amounts Based on';
                        OptionCaption = 'Quantity,Quantity Invoiced';
                        ToolTip = 'Specifies the amounts that the service order is based on.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ArchiveDocument := ServiceSetup."Archive Orders";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInfo.Get();
        ServiceSetup.Get();

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
    end;

    var
        ServiceSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        ShowShippingAddr: Boolean;
        ArchiveDocument: Boolean;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[120];
        Qty: Decimal;
        Amt: Decimal;
        ShowQty: Option Quantity,"Quantity Invoiced";
        GrossAmt: Decimal;
        TotalAmt: Decimal;
        TotalGrossAmt: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Service Order %1';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Contract_No_CaptionLbl: Label 'Contract No.';
        Service_Header___Order_Date_CaptionLbl: Label 'Order Date';
        Invoice_toCaptionLbl: Label 'Invoice to';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        Service_Header___Phone_No__CaptionLbl: Label 'Phone No.';
        Service_Header___E_Mail_CaptionLbl: Label 'Email';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Service_Item_LinesCaptionLbl: Label 'Service Item Lines';
        Service_Item_Line__Response_Date_CaptionLbl: Label 'Response Date';
        Service_Item_Line__Response_Time_CaptionLbl: Label 'Response Time';
        Fault_CommentsCaptionLbl: Label 'Fault Comments';
        Resolution_CommentsCaptionLbl: Label 'Resolution Comments';
        QtyCaptionLbl: Label 'Quantity';
        Service_LinesCaptionLbl: Label 'Service Lines';
        AmountCaptionLbl: Label 'Amount';
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
        exit(CurrReport.Preview() or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitializeRequest(ShowInternalInfoFrom: Boolean; ShowQtyFrom: Option)
    begin
        ShowInternalInfo := ShowInternalInfoFrom;
        ShowQty := ShowQtyFrom;
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTax(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line")
    begin
    end;
}

