// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
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

report 5972 "Service Contract Quote"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceContractQuote.rdlc';
    Caption = 'Service Contract Quote';

    dataset
    {
        dataitem("Service Contract Header"; "Service Contract Header")
        {
            CalcFields = "Bill-to Name", "Ship-to Phone No.";
            DataItemTableView = sorting("Contract Type", "Contract No.") where("Contract Type" = filter(Quote));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Contract No.", "Customer No.";
            column(ContType_ServContractHdr; "Contract Type")
            {
            }
            column(ContNo_ServContractHdr; "Contract No.")
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
                    column(AnnualAmt_ServContractHdr; "Service Contract Header"."Annual Amount")
                    {
                        IncludeCaption = true;
                    }
                    column(InvPeriod_ServContractHdr; "Service Contract Header"."Invoice Period")
                    {
                        IncludeCaption = true;
                    }
                    column(StartDt_ServContractHdr; Format("Service Contract Header"."Starting Date"))
                    {
                    }
                    column(NextInvDate_ServContractHdr; Format("Service Contract Header"."Next Invoice Date"))
                    {
                    }
                    column(AcceptBef_ServContractHdr; "Service Contract Header"."Accept Before")
                    {
                        IncludeCaption = true;
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
                    column(ServContractQuote; StrSubstNo(Text001, CopyText))
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
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(BilltoNam_ServContractHdr; "Service Contract Header"."Bill-to Name")
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CompanyInfoFaxNo; CompanyInfo."Fax No.")
                    {
                    }
                    column(EMail_ServContractHdr; "Service Contract Header"."E-Mail")
                    {
                    }
                    column(PhoneNo_ServContractHdr; "Service Contract Header"."Phone No.")
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(ServContractStartDtCptn; ServContractStartDtCptnLbl)
                    {
                    }
                    column(ServContractNextInvDtCptn; ServContractNextInvDtCptnLbl)
                    {
                    }
                    column(InvoicetoCaption; InvoicetoCaptionLbl)
                    {
                    }
                    column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
                    {
                    }
                    column(CompanyInfoFaxNoCaption; CompanyInfoFaxNoCaptionLbl)
                    {
                    }
                    column(ServContractPhoneNoCptn; ServContractPhoneNoCptnLbl)
                    {
                    }
                    column(ServContractEMailCaption; ServContractEMailCaptionLbl)
                    {
                    }
                    dataitem("Contract/Service Discount"; "Contract/Service Discount")
                    {
                        DataItemLink = "Contract Type" = field("Contract Type"), "Contract No." = field("Contract No.");
                        DataItemLinkReference = "Service Contract Header";
                        DataItemTableView = sorting("Contract Type", "Contract No.", Type, "No.", "Starting Date");
                        column(Type_ContractServDisc; Type)
                        {
                            IncludeCaption = true;
                        }
                        column(No_ContractServDisc; "No.")
                        {
                            IncludeCaption = true;
                        }
                        column(StartDt_ContractServDisc; Format("Starting Date"))
                        {
                        }
                        column(Discount_ContractServDisc; "Discount %")
                        {
                            IncludeCaption = true;
                        }
                        column(ContNo_ContractServDisc; "Contract No.")
                        {
                        }
                        column(ContractServDiscStrtDtCptn; ContractServDiscStrtDtCptnLbl)
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
                        DataItemTableView = sorting("Contract Type", "Contract No.", "Line No.");
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
                        column(SlNo_ServContractLine; "Serial No.")
                        {
                            IncludeCaption = true;
                        }
                        column(ServicePeriod_ServContractLine; "Service Period")
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
                        column(LineValue_ServContractLine; "Line Value")
                        {
                            IncludeCaption = true;
                        }
                        column(ContType_ServContractLine; "Contract Type")
                        {
                        }
                        column(ContNo_ServContractLine; "Contract No.")
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
                            column(Date_ServiceCommentLine; Format(Date))
                            {
                            }
                            column(Comment_ServCommentLine; Comment)
                            {
                                IncludeCaption = true;
                            }
                            column(TblSbtype_ServiceCommLine; "Table Subtype")
                            {
                            }
                            column(Type_ServiceCommentLine; Type)
                            {
                            }
                            column(LineNo_ServiceCommentLine; "Line No.")
                            {
                            }
                            column(ServCommentLineDtCaption; ServCommentLineDtCaptionLbl)
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
                    column(Date_ServCommentLine2; Format(Date))
                    {
                    }
                    column(Comment_ServCommentLine2; Comment)
                    {
                        IncludeCaption = true;
                    }
                    column(ServCommentLine2TableSubtype; "Table Subtype")
                    {
                    }
                    column(Type_ServCommentLine2; Type)
                    {
                    }
                    column(LineNo_ServCommentLine2; "Line No.")
                    {
                    }
                    column(CommentsCaption; CommentsCaptionLbl)
                    {
                    }
                    column(ServCommentLine2DtCaption; ServCommentLine2DtCaptionLbl)
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
                ServiceFormatAddress: Codeunit "Service Format Address";
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddr.GetCompanyAddr("Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
                ServiceFormatAddress.ServContractSellto(CustAddr, "Service Contract Header");
                ShowShippingAddr := "Ship-to Code" <> '';
                if ShowShippingAddr then
                    ServiceFormatAddress.ServContractShipto(ShipToAddr, "Service Contract Header");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Contract Quote';
        AboutText = 'Generate a service contract quote that you can send to your customer.';
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
                        ToolTip = 'Specifies if you want the printed report to show any comments to a service contract quote item.';
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
            LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Service Contract Quote") <> '';
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
                        SegManagement.LogDocument(24, "Service Contract Header"."Contract No.", 0, 0, Database::Contact,
                          "Service Contract Header"."Contact No.", "Service Contract Header"."Salesperson Code", '', '', '')
                    else
                        SegManagement.LogDocument(24, "Service Contract Header"."Contract No.", 0, 0, Database::Customer,
                          "Service Contract Header"."Customer No.", "Service Contract Header"."Salesperson Code", '', '', '')
                until "Service Contract Header".Next() = 0;
    end;

    var
        ServiceSetup: Record "Service Mgt. Setup";
        RespCenter: Record "Responsibility Center";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        SegManagement: Codeunit SegManagement;
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        ShowShippingAddr: Boolean;
        ShowComments: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Service Contract Quote %1';
        Text002: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LogInteraction: Boolean;
        OutputNo: Integer;
        LogInteractionEnable: Boolean;
        ServContractStartDtCptnLbl: Label 'Starting Date';
        ServContractNextInvDtCptnLbl: Label 'Next Invoice Date';
        InvoicetoCaptionLbl: Label 'Invoice to';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoFaxNoCaptionLbl: Label 'Fax No.';
        ServContractPhoneNoCptnLbl: Label 'Phone No.';
        ServContractEMailCaptionLbl: Label 'Email';
        ContractServDiscStrtDtCptnLbl: Label 'Starting Date';
        ServiceDiscountsCaptionLbl: Label 'Service Discounts';
        ServCommentLineDtCaptionLbl: Label 'Date';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        CommentsCaptionLbl: Label 'Comments';
        ServCommentLine2DtCaptionLbl: Label 'Date';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        CompanyInfo3: Record "Company Information";

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    procedure InitializeRequestComment(ShowCommentsFrom: Boolean)
    begin
        ShowComments := ShowCommentsFrom;
    end;
}

