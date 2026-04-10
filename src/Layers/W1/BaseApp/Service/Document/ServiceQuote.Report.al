// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Dimension;
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
            column(DocumentType_ServHeader; "Document Type")
            {
            }
            column(No_ServHeader; "No.")
            {
            }
            column(HomePageCaption; HomePageCaptionLbl)
            {
            }
            column(EmailCaption; EmailCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(HomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(Email; CompanyInfo."E-Mail")
                    {
                    }
                    column(OrderTime_ServHeader; "Service Header"."Order Time")
                    {
                    }
                    column(OrderDate_ServHeader; Format("Service Header"."Order Date"))
                    {
                    }
                    column(Status_ServHeader; "Service Header".Status)
                    {
                    }
                    column(No1_ServHeader; "Service Header"."No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(BilltoName_ServHeader; "Service Header"."Bill-to Name")
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(OrderConfirmationCopyText; StrSubstNo(Text001, CopyText))
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(EMail_ServHeader; "Service Header"."E-Mail")
                    {
                    }
                    column(PhoneNo_ServHeader; "Service Header"."Phone No.")
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(SerHdrOrderDateCaption; SerHdrOrderDateCaptionLbl)
                    {
                    }
                    column(InvoicetoCaption; InvoicetoCaptionLbl)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(ServiceHeaderEMailCaption; ServiceHeaderEMailCaptionLbl)
                    {
                    }
                    column(OrderTime_ServHeaderCaption; "Service Header".FieldCaption("Order Time"))
                    {
                    }
                    column(Status_ServHeaderCaption; "Service Header".FieldCaption(Status))
                    {
                    }
                    column(No1_ServHeaderCaption; "Service Header".FieldCaption("No."))
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
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
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
                        column(LineNo_ServOrderComment; "Line No.")
                        {
                        }
                        column(TblSubtype_ServOrderComm; "Table Subtype")
                        {
                        }
                        column(Type_ServOrderComment; Type)
                        {
                        }
                    }
                    dataitem("Service Item Line"; "Service Item Line")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Service Header";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(SerialNo_ServLineType; "Serial No.")
                        {
                        }
                        column(Description_ServLineType; Description)
                        {
                        }
                        column(ServItemNo_ServLineType; "Service Item No.")
                        {
                        }
                        column(SerItmGrCode_ServLineType; "Service Item Group Code")
                        {
                        }
                        column(Warranty_ServLineType; Warranty)
                        {
                        }
                        column(ItemNo_ServLineType; "Item No.")
                        {
                        }
                        column(LoanerNo_ServLineType; "Loaner No.")
                        {
                        }
                        column(ServShelfNo_ServLineType; "Service Shelf No.")
                        {
                        }
                        column(Warranty1_ServLineType; Format(Warranty))
                        {
                        }
                        column(DocNo_ServLineType; "Document No.")
                        {
                        }
                        column(LineNo_ServLineType; "Line No.")
                        {
                        }
                        column(ServiceItemLinesCaption; ServiceItemLinesCaptionLbl)
                        {
                        }
                        column(SerialNo_ServLineTypeCaption; FieldCaption("Serial No."))
                        {
                        }
                        column(Description_ServLineTypeCaption; FieldCaption(Description))
                        {
                        }
                        column(ServItemNo_ServLineTypeCaption; FieldCaption("Service Item No."))
                        {
                        }
                        column(SerItmGrCode_ServLineTypeCaption; FieldCaption("Service Item Group Code"))
                        {
                        }
                        column(Warranty_ServLineTypeCaption; FieldCaption(Warranty))
                        {
                        }
                        column(ItemNo_ServLineTypeCaption; FieldCaption("Item No."))
                        {
                        }
                        column(LoanerNo_ServLineTypeCaption; FieldCaption("Loaner No."))
                        {
                        }
                        column(ServShelfNo_ServLineTypeCaption; FieldCaption("Service Shelf No."))
                        {
                        }
                        dataitem("Fault Comment"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Fault));
                            column(Comment_FaultComment; Comment)
                            {
                            }
                            column(Number_FaultComment; Number1)
                            {
                            }
                            column(TableSubtype_FaultComment; "Table Subtype")
                            {
                            }
                            column(Type_FaultComment; Type)
                            {
                            }
                            column(LineNo_FaultComment; "Line No.")
                            {
                            }
                            column(FaultCommentsCaption; FaultCommentsCaptionLbl)
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
                            column(Comment_ResolutionComment; Comment)
                            {
                            }
                            column(Number_ResolutionComment; Number2)
                            {
                            }
                            column(TblSubtype_ResolComment; "Table Subtype")
                            {
                            }
                            column(Type_ResolutionComment; Type)
                            {
                            }
                            column(LineNo_ResolutionComment; "Line No.")
                            {
                            }
                            column(ResolutionCommentsCaption; ResolutionCommentsCaptionLbl)
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
                        column(SerItemSlNo_ServLine; "Service Item Serial No.")
                        {
                        }
                        column(Type_ServLine; Type)
                        {
                        }
                        column(No_ServLine; "No.")
                        {
                        }
                        column(Description_ServLine; Description)
                        {
                        }
                        column(UnitPrice_ServLine; "Unit Price")
                        {
                        }
                        column(LineDiscount_ServLine; "Line Discount %")
                        {
                        }
                        column(Amt; Amt)
                        {
                        }
                        column(VariantCode_ServLine; "Variant Code")
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
                        column(DocumentNo_ServLine; "Document No.")
                        {
                        }
                        column(LineNo_ServLine; "Line No.")
                        {
                        }
                        column(ServiceLineCaption; ServiceLineCaptionLbl)
                        {
                        }
                        column(AmtCaption; AmtCaptionLbl)
                        {
                        }
                        column(GrossAmountCaption; GrossAmountCaptionLbl)
                        {
                        }
                        column(SerItemSlNo_ServLineCaption; FieldCaption("Service Item Serial No."))
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
                        {
                        }
                        column(Type_ServLineCaption; FieldCaption(Type))
                        {
                        }
                        column(No_ServLineCaption; FieldCaption("No."))
                        {
                        }
                        column(Description_ServLineCaption; FieldCaption(Description))
                        {
                        }
                        column(UnitPrice_ServLineCaption; FieldCaption("Unit Price"))
                        {
                        }
                        column(LineDiscount_ServLineCaption; FieldCaption("Line Discount %"))
                        {
                        }
                        column(VariantCode_ServLineCaption; FieldCaption("Variant Code"))
                        {
                        }
                        column(Quantity_ServLineCaption; FieldCaption(Quantity))
                        {
                        }
                        dataitem(DimesionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText1; DimText)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
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
                        begin
                            Amt := "Line Amount";
                            GrossAmt := "Amount Including VAT";

                            TotAmt := TotAmt + Amt;
                            TotGrossAmt := TotGrossAmt + GrossAmt;
                        end;
                    }
                    dataitem(Shipto; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
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
                        column(ShipToAddressCaption; ShipToAddressCaptionLbl)
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
        FormatDocument.SetLogoPosition(ServiceSetup."Logo Position on Documents", CompanyInfo1, CompanyInfo2, CompanyInfo3);
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
        CompanyInfo3: Record "Company Information";
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
        Text001: Label 'Service Quote%1';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SerHdrOrderDateCaptionLbl: Label 'Order Date';
        InvoicetoCaptionLbl: Label 'Invoice to';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        ServiceHeaderEMailCaptionLbl: Label 'Email';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        ServiceItemLinesCaptionLbl: Label 'Service Item Lines';
        FaultCommentsCaptionLbl: Label 'Fault Comments';
        ResolutionCommentsCaptionLbl: Label 'Resolution Comments';
        ServiceLineCaptionLbl: Label 'Service Line';
        AmtCaptionLbl: Label 'Amount';
        GrossAmountCaptionLbl: Label 'Gross Amount';
        TotalCaptionLbl: Label 'Total';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';
        ShipToAddressCaptionLbl: Label 'Ship-to Address';
        HomePageCaptionLbl: Label 'Home Page';
        EmailCaptionLbl: Label 'Email';

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
}

