// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using System.Utilities;

report 5936 "Service Item Worksheet"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Reports/ServiceItemWorksheet.rdlc';
    ApplicationArea = Service;
    Caption = 'Service Item Worksheet';
    UsageCategory = Documents;

    dataset
    {
        dataitem("Service Item Line"; "Service Item Line")
        {
            DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
            RequestFilterFields = "Document Type", "Document No.", "Line No.";
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr7; CompanyAddr[7])
            {
            }
            column(CompanyAddr8; CompanyAddr[8])
            {
            }
            column(ServHeaderOrderDate; Format(ServHeader."Order Date"))
            {
            }
            column(ServHeaderOrderTime; ServHeader."Order Time")
            {
            }
            column(ContractNo_ServItemLine; "Contract No.")
            {
            }
            column(DocNo_ServItemLine; "Document No.")
            {
                IncludeCaption = true;
            }
            column(CompanyAddr4; CompanyAddr[4])
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
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(DocType_ServItemLine; "Document Type")
            {
                IncludeCaption = true;
            }
            column(SerialNo_ServItemLine; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(LineDesc_ServItemLine; Description)
            {
                IncludeCaption = true;
            }
            column(ServItemNo_ServItemLine; "Service Item No.")
            {
                IncludeCaption = true;
            }
            column(GroupCode_ServItemLine; "Service Item Group Code")
            {
                IncludeCaption = true;
            }
            column(Warranty_ServItemLine; Warranty)
            {
                IncludeCaption = true;
            }
            column(ItemNo_ServItemLine; "Item No.")
            {
                IncludeCaption = true;
            }
            column(RepStatusCode_ServItemLine; "Repair Status Code")
            {
                IncludeCaption = true;
            }
            column(ShelfNo_ServItemLine; "Service Shelf No.")
            {
                IncludeCaption = true;
            }
            column(Warranty1_ServItemLine; Format(Warranty))
            {
            }
            column(LineNo_ServItemLine; "Line No.")
            {
            }
            column(OrderDateCaption; OrderDateCaptionLbl)
            {
            }
            column(OrderTimeCaption; OrderTimeCaptionLbl)
            {
            }
            column(ContractNoCaption; ContractNoCaptionLbl)
            {
            }
            column(CustomerAddressCaption; CustomerAddressCaptionLbl)
            {
            }
            column(WorksheetCaption; WorksheetCaptionLbl)
            {
            }
            dataitem("Fault Comment"; "Service Comment Line")
            {
                DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Fault));
                column(Comment_ServCommentLine; Comment)
                {
                }
                column(TblLineNo_ServCommentLine; "Table Line No.")
                {
                }
                column(LineNo_ServCommentLine; "Line No.")
                {
                }
                column(FaultCommentsCaption; FaultCommentsCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not ShowComments then
                        CurrReport.Break();
                end;
            }
            dataitem("Resolution Comment"; "Service Comment Line")
            {
                DataItemLink = "Table Subtype" = field("Document Type"), "No." = field("Document No."), "Table Line No." = field("Line No.");
                DataItemTableView = sorting("Table Name", "Table Subtype", "No.", Type, "Table Line No.", "Line No.") where("Table Name" = const("Service Header"), Type = const(Resolution));
                column(Comment1_ServCommentLine; Comment)
                {
                }
                column(TblLineNo1_ServCommentLine; "Table Line No.")
                {
                }
                column(LineNo1_ServCommentLine; "Line No.")
                {
                }
                column(ResolutionCommentsCaption; ResolutionCommentsCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not ShowComments then
                        CurrReport.Break();
                end;
            }
            dataitem("Service Line"; "Service Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("Document No."), "Service Item Line No." = field("Line No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Service Item Line No.", Type, "No.");
                column(SerialNo1_ServLine; "Service Item Serial No.")
                {
                    IncludeCaption = true;
                }
                column(Type_ServLine; Type)
                {
                    IncludeCaption = true;
                }
                column(No_ServLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(VariantCode__ServLine; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(Desc_ServLine; Description)
                {
                    IncludeCaption = true;
                }
                column(Qty_ServLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(FaultAreaCode_ServLine; "Fault Area Code")
                {
                    IncludeCaption = true;
                }
                column(Symptom_ServLine; "Symptom Code")
                {
                    IncludeCaption = true;
                }
                column(FaultCode_ServLine; "Fault Code")
                {
                    IncludeCaption = true;
                }
                column(ResCode_ServLine; "Resolution Code")
                {
                    IncludeCaption = true;
                }
                column(LineNo_ServLine; "Service Item Line No.")
                {
                }
                column(ServiceLinesCaption; ServiceLinesCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            var
                ServiceFormatAddress: Codeunit "Service Format Address";
            begin
                ServHeader.Get("Document Type", "Document No.");

                if RespCenter.Get(ServHeader."Responsibility Center") then begin
                    FormatAddr.RespCenter(CompanyAddr, RespCenter);
                    CompanyInfo."Phone No." := RespCenter."Phone No.";
                    CompanyInfo."Fax No." := RespCenter."Fax No.";
                end else
                    FormatAddr.Company(CompanyAddr, CompanyInfo);

                ServiceFormatAddress.ServiceOrderSellto(CustAddr, ServHeader);
                ShowShippingAddr := "Ship-to Code" <> '';
                if "Ship-to Code" = '' then begin
                    FormatAddr.FormatAddr(
                      ShipToAddr,
                      ServHeader.Name,
                      ServHeader."Name 2",
                      ServHeader."Contact Name",
                      ServHeader.Address,
                      ServHeader."Address 2",
                      ServHeader.City,
                      ServHeader."Post Code",
                      ServHeader.County,
                      ServHeader."Country/Region Code");
                    ShipToPhone := ShiptoAddrRec."Phone No.";
                end else begin
                    ShiptoAddrRec.Get("Customer No.", "Ship-to Code");
                    FormatAddr.FormatAddr(
                      ShipToAddr,
                      ShiptoAddrRec.Name,
                      ShiptoAddrRec."Name 2",
                      ShiptoAddrRec.Contact,
                      ShiptoAddrRec.Address,
                      ShiptoAddrRec."Address 2",
                      ShiptoAddrRec.City,
                      ShiptoAddrRec."Post Code",
                      ShiptoAddrRec.County,
                      ShiptoAddrRec."Country/Region Code");
                    ShipToPhone := ShiptoAddrRec."Phone No.";
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
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
            column(ShipToPhone; ShipToPhone)
            {
            }
            column(ShiptoAddressCaption; ShiptoAddressCaptionLbl)
            {
            }

            trigger OnPreDataItem()
            begin
                if not ShowShippingAddr then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Service Item Worksheet';
        AboutText = 'Get an overview of what''s needed to complete a service repair task.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowComments; ShowComments)
                    {
                        ApplicationArea = Service;
                        Caption = 'Show Comments';
                        ToolTip = 'Specifies if you want the printed report to show any comments to a service item.';
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
        PageNoCaption = 'Page';
    }

    var
        ServHeader: Record "Service Header";
        CompanyInfo: Record "Company Information";
        RespCenter: Record "Responsibility Center";
        ShiptoAddrRec: Record "Ship-to Address";
        FormatAddr: Codeunit "Format Address";
        CustAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        ShowShippingAddr: Boolean;
        ShipToAddr: array[8] of Text[100];
        ShipToPhone: Text[30];
        ShowComments: Boolean;
        OrderDateCaptionLbl: Label 'Order Date';
        OrderTimeCaptionLbl: Label 'Order Time';
        ContractNoCaptionLbl: Label 'Contract No.';
        CustomerAddressCaptionLbl: Label 'Customer Address';
        WorksheetCaptionLbl: Label 'Service Item Worksheet';
        FaultCommentsCaptionLbl: Label 'Fault Comments';
        ResolutionCommentsCaptionLbl: Label 'Resolution Comments';
        ServiceLinesCaptionLbl: Label 'Service Lines';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';

    procedure InitializeRequest(ShowCommentsFrom: Boolean)
    begin
        ShowComments := ShowCommentsFrom;
    end;
}

