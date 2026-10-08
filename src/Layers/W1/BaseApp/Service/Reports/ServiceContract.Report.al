// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 5970 "Service Contract"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceContract.rdlc';

    Caption = 'Service Contract';
    WordMergeDataItem = "Service Contract Header";

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            CalcFields = "Bill-to Name", "Ship-to Phone No.";
            DataItemTableView = sorting("Contract Type", "Contract No.") where("Contract Type" = const(Contract));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Contract No.", "Customer No.";
            column(ContractType_ServContract; "Contract Type")
            {
            }
            column(ContractNo_ServContract; "Contract No.")
            {
                IncludeCaption = true;
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(OutputNo; OutputNo)
                {
                }
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfoPicture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(AnnualAmount_ServContract; "Service Contract Header"."Annual Amount")
                    {
                        IncludeCaption = true;
                    }
                    column(NextInvoiceDate_ServContract; Format("Service Contract Header"."Next Invoice Date"))
                    {
                    }
                    column(InvoicePeriod_ServContract; "Service Contract Header"."Invoice Period")
                    {
                        IncludeCaption = true;
                    }
                    column(StartingDate_ServContract; Format("Service Contract Header"."Starting Date"))
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
                    column(BilltoCustNo_ServContract; "Service Contract Header"."Bill-to Customer No.")
                    {
                        IncludeCaption = true;
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
                    column(ServiceContract; StrSubstNo(Text001, CopyText))
                    {
                    }
                    column(Status_ServContract; "Service Contract Header".Status)
                    {
                        IncludeCaption = true;
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(Email_ServContract; "Service Contract Header"."E-Mail")
                    {
                    }
                    column(PhoneNo_ServContract; "Service Contract Header"."Phone No.")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(NextInvoiceDate_ServContractCaption; NextInvoiceDate_ServContractCaptionLbl)
                    {
                    }
                    column(StartingDate_ServContractCaption; StartingDate_ServContractCaptionLbl)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(PhoneNo_ServContractCaption; PhoneNo_ServContractCaptionLbl)
                    {
                    }
                    column(Email_ServContractCaption; Email_ServContractCaptionLbl)
                    {
                    }
                    column(InvoicePeriod_ServContractML; Format("Service Contract Header"."Invoice Period"))
                    {
                        IncludeCaption = false;
                    }
                    column(Status_ServContractML; Format("Service Contract Header".Status))
                    {
                        IncludeCaption = false;
                    }
                    dataitem("Contract/Service Discount"; "Contract/Service Discount")
                    {
                        DataItemLink = "Contract Type" = field("Contract Type"), "Contract No." = field("Contract No.");
                        DataItemLinkReference = "Service Contract Header";
                        DataItemTableView = sorting("Contract Type", "Contract No.", Type, "No.", "Starting Date");
                        column(Type_ContractDisc; Type)
                        {
                            IncludeCaption = true;
                        }
                        column(No_ContractDisc; "No.")
                        {
                            IncludeCaption = true;
                        }
                        column(StartingDate_ContractDisc; Format("Starting Date"))
                        {
                        }
                        column(Discount_ContractDisc; "Discount %")
                        {
                            IncludeCaption = true;
                        }
                        column(ContractNo_ContractDisc; "Contract No.")
                        {
                        }
                        column(StartingDate_ContractDiscCaption; StartingDate_ContractDiscCaptionLbl)
                        {
                        }
                        column(ServiceDiscountsCaption; ServiceDiscountsCaptionLbl)
                        {
                        }
                    }
                    dataitem("Service Contract Line"; "Service Contract Line")
                    {
                        DataItemLink = "Contract Type" = field("Contract Type"), "Contract No." = field("Contract No.");
                        DataItemLinkReference = "Service Contract Header";
                        DataItemTableView = sorting("Contract Type", "Contract No.", "Line No.") order(ascending);
                        column(ServItemNo_ServContractLine; "Service Item No.")
                        {
                            IncludeCaption = true;
                        }
                        column(Desc_ServContractLine; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(ItemNo_ServContractLine; "Item No.")
                        {
                            IncludeCaption = true;
                        }
                        column(SerialNo_ServContractLine; "Serial No.")
                        {
                            IncludeCaption = true;
                        }
                        column(ServPeriod_ServContractLine; "Service Period")
                        {
                            IncludeCaption = true;
                        }
                        column(LineValue_ServContractLine; "Line Value")
                        {
                            IncludeCaption = true;
                        }
                        column(UOMCode_ServContractLine; "Unit of Measure Code")
                        {
                            IncludeCaption = true;
                        }
                        column(RespTime_ServContractLine; "Response Time (Hours)")
                        {
                            IncludeCaption = true;
                        }
                        column(ContractType_ServContractLine; "Contract Type")
                        {
                        }
                        column(ContractNo_ServContractLine; "Contract No.")
                        {
                        }
                        column(LineNo_ServContractLine; "Line No.")
                        {
                        }
                        dataitem("Service Comment Line"; "Service Comment Line")
                        {
                            DataItemLink = "Table Subtype" = field("Contract Type"), "Table Line No." = field("Line No."), "No." = field("Contract No.");
                            DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") order(ascending) where("Table Name" = filter("Service Contract"));
                            column(ShowComments; ShowComments)
                            {
                            }
                            column(Date_ServCommentLine; Format(Date))
                            {
                            }
                            column(Comm_ServCommentLine; Comment)
                            {
                                IncludeCaption = true;
                            }
                            column(TableSubtype_ServCommentLine; "Table Subtype")
                            {
                            }
                            column(Type_ServCommentLine; Type)
                            {
                            }
                            column(LineNo_ServCommentLine; "Line No.")
                            {
                            }
                            column(Date_ServCommentLineCaption; Date_ServCommentLineCaptionLbl)
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                if not ShowComments then
                                    CurrReport.Break();
                            end;
                        }
                    }
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
                    column(ShipToCode; "Service Contract Header"."Ship-to Code")
                    {
                    }
                    column(ShiptoAddressCaption; ShiptoAddressCaptionLbl)
                    {
                    }
                    column(ShipToPhoneNo; "Service Contract Header"."Ship-to Phone No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ShowShippingAddr then
                            CurrReport.Break();
                    end;
                }
                dataitem(ServCommentLine2; "Service Comment Line")
                {
                    DataItemLink = "No." = field("Contract No."), "Table Subtype" = field("Contract Type");
                    DataItemLinkReference = "Service Contract Header";
                    DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") order(ascending) where("Table Name" = filter("Service Contract"), "Table Line No." = filter(0));
                    column(ShowComments1; ShowComments)
                    {
                    }
                    column(Date_servcommentline2; Format(Date))
                    {
                    }
                    column(Comm_servcommentline2; Comment)
                    {
                        IncludeCaption = true;
                    }
                    column(TblSubtype_servcommentline2; "Table Subtype")
                    {
                    }
                    column(Type_servcommentline2; Type)
                    {
                    }
                    column(LineNo_servcommentline2; "Line No.")
                    {
                    }
                    column(CommentsCaption; CommentsCaptionLbl)
                    {
                    }
                    column(Date_servcommentline2Caption; Date_servcommentline2CaptionLbl)
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ShowComments then
                            CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text000;
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
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Service Contract Header");
                FormatDocumentFields("Service Contract Header");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Contract';
        AboutText = 'Get an overview of all your service contracts.';
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
                    field(ShowComments; ShowComments)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Comments';
                        ToolTip = 'Specifies if you want the printed report to show any service comments.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Service;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want the service contract quotes that you print to be recorded as interactions and to be added to the Interaction Log Entry table.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Service Contract") <> '';
            LogInteractionEnable := LogInteraction;
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
            if "Service Contract Header".FindSet() then
                repeat
                    if "Service Contract Header"."Contact No." <> '' then
                        SegManagement.LogDocument(23, "Service Contract Header"."Contract No.", 0, 0, Database::Contact,
                          "Service Contract Header"."Contact No.", "Service Contract Header"."Salesperson Code", '', '', '')
                    else
                        SegManagement.LogDocument(23, "Service Contract Header"."Contract No.", 0, 0, Database::Customer,
                          "Service Contract Header"."Customer No.", "Service Contract Header"."Salesperson Code", '', '', '')
                until "Service Contract Header".Next() = 0;
    end;

    var
        SalesPurchPerson: Record "Salesperson/Purchaser";
        ServiceSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[20];
        ShowShippingAddr: Boolean;
        ShowComments: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        LogInteraction: Boolean;
        OutputNo: Integer;
        LogInteractionEnable: Boolean;

#pragma warning disable AA0074
        Text000: Label 'COPY';
#pragma warning disable AA0470
        Text001: Label 'Service Contract %1';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NextInvoiceDate_ServContractCaptionLbl: Label 'Next Invoice Date';
        StartingDate_ServContractCaptionLbl: Label 'Starting Date';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        PhoneNo_ServContractCaptionLbl: Label 'Phone No.';
        Email_ServContractCaptionLbl: Label 'Email';
        StartingDate_ContractDiscCaptionLbl: Label 'Starting Date';
        ServiceDiscountsCaptionLbl: Label 'Service Discounts';
        Date_ServCommentLineCaptionLbl: Label 'Date';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        CommentsCaptionLbl: Label 'Comments';
        Date_servcommentline2CaptionLbl: Label 'Date';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    procedure InitializeRequest(ShowCommentsFrom: Boolean)
    begin
        ShowComments := ShowCommentsFrom;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        FormatAddr.GetCompanyAddr(ServiceContractHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        ServiceFormatAddress.ServContractSellto(CustAddr, ServiceContractHeader);
        ShowShippingAddr := ServiceContractHeader."Ship-to Code" <> '';
        if ShowShippingAddr then
            ServiceFormatAddress.ServContractShipto(ShipToAddr, ServiceContractHeader);
    end;

    local procedure FormatDocumentFields(ServiceContractHeader: Record "Service Contract Header")
    begin
        FormatDocument.SetSalesPerson(SalesPurchPerson, ServiceContractHeader."Salesperson Code", SalesPersonText);
    end;
}

