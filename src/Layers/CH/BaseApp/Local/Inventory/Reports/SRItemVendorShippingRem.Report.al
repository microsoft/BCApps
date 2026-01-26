// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Globalization;
using System.Utilities;

report 11581 "SR Item Vendor Shipping Rem."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/SRItemVendorShippingRem.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Vendor Shipping Reminder';
    Permissions =;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Vendor Posting Group", "Country/Region Code", "Language Code";
            column(No_Vendor; "No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(Adr8; Adr[8])
                {
                }
                column(Adr7; Adr[7])
                {
                }
                column(Adr6; Adr[6])
                {
                }
                column(FormattedKeyDate; Format(KeyDate))
                {
                }
                column(Adr5; Adr[5])
                {
                }
                column(VendorNo; Vendor."No.")
                {
                }
                column(Adr4; Adr[4])
                {
                }
                column(PurchaserName; Purchaser.Name)
                {
                }
                column(Adr3; Adr[3])
                {
                }
                column(CompanyInformationFaxNo; CompanyInformation."Fax No.")
                {
                }
                column(Adr2; Adr[2])
                {
                }
                column(CompanyInformationPhoneNo; CompanyInformation."Phone No.")
                {
                }
                column(Adr1; Adr[1])
                {
                }
                column(CompanyAdr6; CompanyAdr[6])
                {
                }
                column(CompanyAdr5; CompanyAdr[5])
                {
                }
                column(CompanyAdr4; CompanyAdr[4])
                {
                }
                column(CompanyAdr3; CompanyAdr[3])
                {
                }
                column(CompanyAdr2; CompanyAdr[2])
                {
                }
                column(CompanyAdr1; CompanyAdr[1])
                {
                }
                column(OpenQtyCaption; OpenQtyCaptionLbl)
                {
                }
                column(QtyCaption; QtyCaptionLbl)
                {
                }
                column(UnitCaption; UnitCaptionLbl)
                {
                }
                column(DeadlineCaption; DeadlineCaptionLbl)
                {
                }
                column(YourItemCaption; YourItemCaptionLbl)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(ItemNoCaption; ItemNoCaptionLbl)
                {
                }
                column(PosCaption; PosCaptionLbl)
                {
                }
                column(ReminderOfDeliveryCaption; ReminderOfDeliveryCaptionLbl)
                {
                }
                column(DateCaption; DateCaptionLbl)
                {
                }
                column(SupplierNoCaption; SupplierNoCaptionLbl)
                {
                }
                column(PurchaserCaption; PurchaserCaptionLbl)
                {
                }
                column(FaxCaption; FaxCaptionLbl)
                {
                }
                column(TelephoneCaption; TelephoneCaptionLbl)
                {
                }
                column(OrderLinesCouldYouPleaseCaption; OrderLinesCouldYouPleaseCaptionLbl)
                {
                }
                dataitem("Purchase Header"; "Purchase Header")
                {
                    DataItemTableView = sorting("Document Type", "Buy-from Vendor No.", "No.");
                    PrintOnlyIfDetail = true;
                    column(KayDateFormatted; Format(KeyDate))
                    {
                    }
                    column(NoOrderDateFormatted; "No." + ',  ' + Format("Order Date"))
                    {
                    }
                    column(PurchaseLineOutstandingQuantity; "Purchase Line"."Outstanding Quantity")
                    {
                    }
                    column(PurchaseHeaderSupplierNoCaption; SupplierNoCaptionLbl)
                    {
                    }
                    column(PurchaseHeaderOpenQtyCaption; OpenQtyCaptionLbl)
                    {
                    }
                    column(PurchaseHeaderUnitCaption; UnitCaptionLbl)
                    {
                    }
                    column(YourItemNoCaption; YourItemNoCaptionLbl)
                    {
                    }
                    column(PurchaseHeaderItemNoCaption; ItemNoCaptionLbl)
                    {
                    }
                    column(PurchaseHeaderReminderOfDeliveryCaption; ReminderOfDeliveryCaptionLbl)
                    {
                    }
                    column(OrderCaption; OrderCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(No_PurchaseHeader; "No.")
                    {
                    }
                    dataitem("Purchase Line"; "Purchase Line")
                    {
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                        RequestFilterFields = "Document No.", "Expected Receipt Date", Type, "No.", "Location Code";
                        column(VendorItemNo_PurchaseLine; "Vendor Item No.")
                        {
                        }
                        column(ExpectedReceiptDate_PurchaseLine; Format("Expected Receipt Date"))
                        {
                        }
                        column(Description_PurchaseLine; Description)
                        {
                        }
                        column(Quantity_PurchaseLine; Quantity)
                        {
                        }
                        column(OutstandingQuantity_PurchaseLine; "Outstanding Quantity")
                        {
                        }
                        column(No_PurchaseLine; "No.")
                        {
                        }
                        column(Pos; Pos)
                        {
                        }
                        column(Due; Due)
                        {
                        }
                        column(UnitofMeasureCode_PurchaseLine; "Unit of Measure Code")
                        {
                        }
                        column(DocumentNo_PurchaseLine; "Document No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Pos := Pos + 10;

                            if "Expected Receipt Date" < KeyDate then
                                Due := '*'
                            else
                                Due := '';
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Document Type", "Purchase Header"."Document Type");
                            SetRange("Document No.", "Purchase Header"."No.");
                            SetRange(Type, Type::"G/L Account", Type::Item);
                            SetFilter("Outstanding Quantity", '<>%1', 0);
                            if OnlyDueEntries then
                                SetFilter("Expected Receipt Date", '<%1', KeyDate);
                            Clear("Outstanding Quantity");
                        end;
                    }

                    trigger OnPreDataItem()
                    begin
                        SetRange("Buy-from Vendor No.", Vendor."No.");
                        SetRange("Document Type", "Document Type"::Order);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAdr.Vendor(Adr, Vendor);
                if not Purchaser.Get("Purchaser Code") then
                    Clear(Purchaser);

                Pos := 0;

                CurrReport.Language := GlobalLanguage.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := GlobalLanguage.GetFormatRegionOrDefault("Format Region");
            end;

            trigger OnPreDataItem()
            begin
                CompanyInformation.Get();
                FormatAdr.Company(CompanyAdr, CompanyInformation);
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
                    field(KeyDate; KeyDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Key date';
                        ToolTip = 'Specifies the date to calculate time columns.';
                    }
                    field(OnlyDueEntries; OnlyDueEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only due shipments';
                        ToolTip = 'Specifies that you want to include only the items that have a late shipment date. Otherwise, all purchase order lines that have a remaining balance will be shown.';
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
        KeyDate := WorkDate();
    end;

    var
        CompanyInformation: Record "Company Information";
        Purchaser: Record "Salesperson/Purchaser";
        GlobalLanguage: Codeunit Language;
        FormatAdr: Codeunit "Format Address";
        KeyDate: Date;
        OnlyDueEntries: Boolean;
        CompanyAdr: array[8] of Text[100];
        Adr: array[8] of Text[100];
        Pos: Integer;
        Due: Text[1];
        OpenQtyCaptionLbl: Label 'Open Qty';
        QtyCaptionLbl: Label 'Qty';
        UnitCaptionLbl: Label 'Unit';
        DeadlineCaptionLbl: Label 'Deadline';
        YourItemCaptionLbl: Label 'Your Item';
        DescriptionCaptionLbl: Label 'Description';
        ItemNoCaptionLbl: Label 'Item No.';
        PosCaptionLbl: Label 'Pos.';
        ReminderOfDeliveryCaptionLbl: Label 'Reminder of delivery';
        DateCaptionLbl: Label 'Date';
        SupplierNoCaptionLbl: Label 'Supplier No.';
        PurchaserCaptionLbl: Label 'Purchaser';
        FaxCaptionLbl: Label 'Fax';
        TelephoneCaptionLbl: Label 'Telephone';
        OrderLinesCouldYouPleaseCaptionLbl: Label 'The following Order Lines are presently open. Delivery dates that are already overdue are marked with an *. Could you please provide updated information on planned delivery dates?';
        YourItemNoCaptionLbl: Label 'Your Item No.';
        OrderCaptionLbl: Label 'Order:';
        TotalCaptionLbl: Label 'Total';
}

