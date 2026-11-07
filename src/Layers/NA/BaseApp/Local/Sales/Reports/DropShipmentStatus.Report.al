// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

report 10051 "Drop Shipment Status"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/DropShipmentStatus.rdlc';
    Caption = 'Drop Shipment Status';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Line"; "Sales Line")
        {
            DataItemTableView = sorting("Document Type", Type, "No.") where("Document Type" = const(Order), "Drop Shipment" = const(true), Type = const(Item));
            RequestFilterFields = "Bill-to Customer No.", "Document No.", Type, "No.", "Shipment Date";
            RequestFilterHeading = 'Drop Shipments';
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Subtitle; Subtitle)
            {
            }
            column(SortOpt; SortOpt)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Sales_Line__Bill_to_Customer_No__; "Bill-to Customer No.")
            {
            }
            column(Customer_Name; Customer.Name)
            {
            }
            column(Customer__Phone_No__; Customer."Phone No.")
            {
            }
            column(Customer_Contact; Customer.Contact)
            {
            }
            column(Sales_Line__No__; "No.")
            {
            }
            column(Sales_Line__Document_No__; "Document No.")
            {
            }
            column(Sales_Line__Shipment_Date_; "Shipment Date")
            {
            }
            column(StatusLine1; StatusLine1)
            {
            }
            column(Sales_Line_Quantity; Quantity)
            {
            }
            column(Sales_Line__Unit_of_Measure_; "Unit of Measure")
            {
            }
            column(CustInvQty; CustInvQty)
            {
            }
            column(PurchaseLine__Document_No__; PurchaseLine."Document No.")
            {
            }
            column(PurchaseLine__Buy_from_Vendor_No__; PurchaseLine."Buy-from Vendor No.")
            {
            }
            column(PurchaseLine__Expected_Receipt_Date_; PurchaseLine."Expected Receipt Date")
            {
            }
            column(StatusLine2; StatusLine2)
            {
            }
            column(VendOrdQty; VendOrdQty)
            {
            }
            column(PurchaseLine__Unit_of_Measure_; PurchaseLine."Unit of Measure")
            {
            }
            column(VendInvQty; VendInvQty)
            {
            }
            column(PurchaseLine_GET_1__Purchase_Order_No____Purch__Order_Line_No___; PurchaseLine.Get(1, "Purchase Order No.", "Purch. Order Line No."))
            {
            }
            column(Sales_Line__No___Control78; "No.")
            {
            }
            column(ItemDescription; ItemDescription)
            {
            }
            column(Sales_Line_Type; Type)
            {
            }
            column(FirstPass_Control1020002; FirstPass)
            {
            }
            column(Sales_Line__Document_No___Control82; "Document No.")
            {
            }
            column(Sales_Line__Bill_to_Customer_No___Control83; "Bill-to Customer No.")
            {
            }
            column(Sales_Line__Shipment_Date__Control84; "Shipment Date")
            {
            }
            column(StatusLine1_Control85; StatusLine1)
            {
            }
            column(Sales_Line_Quantity_Control86; Quantity)
            {
            }
            column(Sales_Line__Unit_of_Measure__Control87; "Unit of Measure")
            {
            }
            column(CustInvQty_Control88; CustInvQty)
            {
            }
            column(PurchaseLine__Document_No___Control90; PurchaseLine."Document No.")
            {
            }
            column(PurchaseLine__Buy_from_Vendor_No___Control91; PurchaseLine."Buy-from Vendor No.")
            {
            }
            column(PurchaseLine__Expected_Receipt_Date__Control92; PurchaseLine."Expected Receipt Date")
            {
            }
            column(StatusLine2_Control93; StatusLine2)
            {
            }
            column(VendOrdQty_Control94; VendOrdQty)
            {
            }
            column(PurchaseLine__Unit_of_Measure__Control95; PurchaseLine."Unit of Measure")
            {
            }
            column(VendInvQty_Control96; VendInvQty)
            {
            }
            column(PurchaseLine_GET_1__Purchase_Order_No____Purch__Order_Line_No____Control1020003; PurchaseLine.Get(1, "Purchase Order No.", "Purch. Order Line No."))
            {
            }
            column(Sales_Line__Document_No___Control98; "Document No.")
            {
            }
            column(Sales_Line__Bill_to_Customer_No___Control99; "Bill-to Customer No.")
            {
            }
            column(Customer_Name_Control100; Customer.Name)
            {
            }
            column(Customer__Phone_No___Control101; Customer."Phone No.")
            {
            }
            column(Sales_Line__No___Control104; "No.")
            {
            }
            column(Sales_Line__Shipment_Date__Control105; "Shipment Date")
            {
            }
            column(StatusLine1_Control106; StatusLine1)
            {
            }
            column(Sales_Line_Quantity_Control107; Quantity)
            {
            }
            column(Sales_Line__Unit_of_Measure__Control108; "Unit of Measure")
            {
            }
            column(CustInvQty_Control109; CustInvQty)
            {
            }
            column(PurchaseLine__Document_No___Control110; PurchaseLine."Document No.")
            {
            }
            column(PurchaseLine__Buy_from_Vendor_No___Control111; PurchaseLine."Buy-from Vendor No.")
            {
            }
            column(PurchaseLine__Expected_Receipt_Date__Control112; PurchaseLine."Expected Receipt Date")
            {
            }
            column(StatusLine2_Control113; StatusLine2)
            {
            }
            column(VendOrdQty_Control114; VendOrdQty)
            {
            }
            column(PurchaseLine__Unit_of_Measure__Control115; PurchaseLine."Unit of Measure")
            {
            }
            column(VendInvQty_Control116; VendInvQty)
            {
            }
            column(PurchaseLine_GET_1__Purchase_Order_No____Purch__Order_Line_No____Control1020006; PurchaseLine.Get(1, "Purchase Order No.", "Purch. Order Line No."))
            {
            }
            column(Sales_Line__Sales_Line__Quantity; "Sales Line".Quantity)
            {
            }
            column(Sales_Line__Sales_Line___Quantity_Invoiced_; "Sales Line"."Quantity Invoiced")
            {
            }
            column(PurchaseLine_GET_1__Purchase_Order_No____Purch__Order_Line_No____Control1020008; PurchaseLine.Get(1, "Purchase Order No.", "Purch. Order Line No."))
            {
            }
            column(Sales_Line_Document_Type; "Document Type")
            {
            }
            column(Sales_Line_Line_No_; "Line No.")
            {
            }
            column(Outstanding_Drop_Shipments_Status_ReportCaption; Outstanding_Drop_Shipments_Status_ReportCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Sales_Line__Bill_to_Customer_No__Caption; Sales_Line__Bill_to_Customer_No__CaptionLbl)
            {
            }
            column(Sales_Line__Document_No__Caption; Sales_Line__Document_No__CaptionLbl)
            {
            }
            column(Quantity_OrderedCaption; Quantity_OrderedCaptionLbl)
            {
            }
            column(Unit_of_MeasureCaption; Unit_of_MeasureCaptionLbl)
            {
            }
            column(Quantity_InvoicedCaption; Quantity_InvoicedCaptionLbl)
            {
            }
            column(Sales_Line__No__Caption; Sales_Line__No__CaptionLbl)
            {
            }
            column(PO_NumberCaption; PO_NumberCaptionLbl)
            {
            }
            column(PurchaseLine__Buy_from_Vendor_No__Caption; PurchaseLine__Buy_from_Vendor_No__CaptionLbl)
            {
            }
            column(Order_Status_and_NotesCaption; Order_Status_and_NotesCaptionLbl)
            {
            }
            column(Expected_DatesCaption; Expected_DatesCaptionLbl)
            {
            }
            column(Sales_Line__Document_No___Control82Caption; Sales_Line__Document_No___Control82CaptionLbl)
            {
            }
            column(Sales_Line__Bill_to_Customer_No___Control83Caption; Sales_Line__Bill_to_Customer_No___Control83CaptionLbl)
            {
            }
            column(Expected_DatesCaption_Control32; Expected_DatesCaption_Control32Lbl)
            {
            }
            column(Sales_Line__No___Control78Caption; Sales_Line__No___Control78CaptionLbl)
            {
            }
            column(PurchaseLine__Document_No___Control90Caption; PurchaseLine__Document_No___Control90CaptionLbl)
            {
            }
            column(PurchaseLine__Buy_from_Vendor_No___Control91Caption; PurchaseLine__Buy_from_Vendor_No___Control91CaptionLbl)
            {
            }
            column(Order_Status_and_NotesCaption_Control40; Order_Status_and_NotesCaption_Control40Lbl)
            {
            }
            column(Quantity_InvoicedCaption_Control4; Quantity_InvoicedCaption_Control4Lbl)
            {
            }
            column(Quantity_OrderedCaption_Control6; Quantity_OrderedCaption_Control6Lbl)
            {
            }
            column(Unit_of_MeasureCaption_Control8; Unit_of_MeasureCaption_Control8Lbl)
            {
            }
            column(Sales_Line__Document_No___Control98Caption; Sales_Line__Document_No___Control98CaptionLbl)
            {
            }
            column(Sales_Line__No___Control104Caption; Sales_Line__No___Control104CaptionLbl)
            {
            }
            column(PurchaseLine__Document_No___Control110Caption; PurchaseLine__Document_No___Control110CaptionLbl)
            {
            }
            column(Vendor_NoCaption; Vendor_NoCaptionLbl)
            {
            }
            column(Order_Status_and_NotesCaption_Control53; Order_Status_and_NotesCaption_Control53Lbl)
            {
            }
            column(Expected_DatesCaption_Control2; Expected_DatesCaption_Control2Lbl)
            {
            }
            column(Quantity_InvoicedCaption_Control5; Quantity_InvoicedCaption_Control5Lbl)
            {
            }
            column(Quantity_OrderedCaption_Control7; Quantity_OrderedCaption_Control7Lbl)
            {
            }
            column(Unit_of_MeasureCaption_Control9; Unit_of_MeasureCaption_Control9Lbl)
            {
            }
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(Contact_Caption; Contact_CaptionLbl)
            {
            }
            column(Purchase_Order_Caption; Purchase_Order_CaptionLbl)
            {
            }
            column(Type_Caption; Type_CaptionLbl)
            {
            }
            column(Sales_Order_Caption; Sales_Order_CaptionLbl)
            {
            }
            column(Purchase_Order_Caption_Control97; Purchase_Order_Caption_Control97Lbl)
            {
            }
            column(Customer_Caption; Customer_CaptionLbl)
            {
            }
            column(Phone_Caption_Control103; Phone_Caption_Control103Lbl)
            {
            }
            column(Purchase_Order_Caption_Control117; Purchase_Order_Caption_Control117Lbl)
            {
            }
            column(No_Purchase_Order_IssuedCaption; No_Purchase_Order_IssuedCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if FirstPass or
                   ((SortOption = SortOption::Customer) and ("Bill-to Customer No." <> xCustomer)) or
                   ((SortOption = SortOption::Item) and ("No." <> xItem)) or
                   ((SortOption = SortOption::"Sales Order") and ("Document No." <> xOrder))
                then begin
                    if not Customer.Get("Bill-to Customer No.") then begin
                        Customer.Name := '';
                        Customer.Contact := '';
                        Customer."Phone No." := '';
                    end;
                    ItemDescription := '';
                    if Type = Type::Item then
                        if Item.Get("No.") then
                            ItemDescription := Item.Description;
                    FirstPass := true;
                    xCustomer := "Bill-to Customer No.";
                    xItem := "No.";
                    xOrder := "Document No.";
                end;
                StatusLine1 := '';
                StatusLine2 := '';
                if "Quantity Invoiced" < Quantity then begin
                    if "Quantity Invoiced" = 0.0 then
                        CustInvQty := ''
                    else
                        CustInvQty := QFormat("Quantity Invoiced");
                end else
                    CustInvQty := 'Complete';
                if PurchaseLine.Get(1, "Purchase Order No.", "Purch. Order Line No.") then begin
                    if "Shipment Date" < PurchaseLine."Expected Receipt Date" then
                        StatusLine1 := Text001;  // lowest priority message
                    if PurchaseLine."Quantity Invoiced" < PurchaseLine.Quantity then begin
                        StatusLine2 := PendingVendConfirm;
                        if PurchaseLine."Quantity Invoiced" = 0.0 then
                            VendInvQty := ''
                        else
                            VendInvQty := QFormat(PurchaseLine."Quantity Invoiced");
                    end else
                        VendInvQty := Text002;
                    /*PROGRAMMERS NOTE:  As of today, the following situation cannot occur due
                     to a limitation of the program.  However, that is not to say that this
                     possibility will never occur, since the program may be improved some day.*/
                    if PurchaseLine.Quantity < Quantity - "Quantity Invoiced" then begin  // highest priority message
                        StatusLine1 := Text003;
                        StatusLine2 := '       ' + Text004;
                        if PurchaseLine.Quantity = 0.0 then
                            VendOrdQty := ''
                        else
                            VendOrdQty := QFormat(PurchaseLine.Quantity);
                    end else
                        VendOrdQty := Text002;
                end else
                    if "Quantity Invoiced" < Quantity then
                        StatusLine1 := Text005
                    else
                        StatusLine1 := Text006;
                if (StatusLine1 = '') and (StatusLine2 <> '') then
                    if StatusLine2 = PendingVendConfirm then begin
                        StatusLine1 := Text007;   // stretch out to more
                        StatusLine2 := '  ' + Text008;    // meaningful full phrasing
                    end else begin
                        StatusLine1 := StatusLine2;              // just move up to first line
                        StatusLine2 := '';
                    end;

            end;

            trigger OnPreDataItem()
            begin
                case SortOption of
                    SortOption::Customer:
                        SetCurrentKey("Document Type", "Bill-to Customer No.");
                    SortOption::Item:
                        SetCurrentKey("Document Type", Type, "No.");
                    SortOption::"Sales Order":
                        SetCurrentKey("Document Type", "Document No.");
                end;
                SortOpt := SortOption;
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
                    field(SortOption; SortOption)
                    {
                        Caption = 'Report By';
                        OptionCaption = 'Sales Order,Customer,Item';
                        ToolTip = 'Specifies how to report. Select Sales Order if you want the status reported by sales order number. Select Customer if you want the status reported by customer. Select Item if you want the status reported by inventory item.';
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

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FilterString := "Sales Line".GetFilters();
        xCustomer := '';
        xItem := '';
        xOrder := '';
        FirstPass := true;
        PendingVendConfirm := Text000;
    end;

    var
        CompanyInformation: Record "Company Information";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
        Item: Record Item;
        ItemDescription: Text[100];
        FilterString: Text;
        Subtitle: Text[126];
        SortOption: Option "Sales Order",Customer,Item;
        PendingVendConfirm: Text[22];
        StatusLine1: Text[22];
        StatusLine2: Text[22];
        FirstPass: Boolean;
        xCustomer: Code[20];
        xItem: Code[20];
        xOrder: Code[20];
        CustInvQty: Text;
        VendOrdQty: Text;
        VendInvQty: Text;
        TempStr: Text[30];
        SortOpt: Integer;
        Text000: Label 'Pending Vend Confirm';
        Text001: Label 'Order Expected Late';
        Text002: Label 'Complete';
        Text003: Label 'WARNING:  Entire Qty';
        Text004: Label 'Not Yet Ordered';
        Text005: Label 'WARNING:';
        Text006: Label 'Order Line Complete';
        Text007: Label 'Pending Vendor Ship-';
        Text008: Label 'ment Confirmation';
        j: Integer;
        Outstanding_Drop_Shipments_Status_ReportCaptionLbl: Label 'Outstanding Drop Shipments Status Report';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Sales_Line__Bill_to_Customer_No__CaptionLbl: Label 'Customer Number';
        Sales_Line__Document_No__CaptionLbl: Label 'Sales Order/';
        Quantity_OrderedCaptionLbl: Label 'Quantity Ordered';
        Unit_of_MeasureCaptionLbl: Label 'Unit of Measure';
        Quantity_InvoicedCaptionLbl: Label 'Quantity Invoiced';
        Sales_Line__No__CaptionLbl: Label 'Item Number';
        PO_NumberCaptionLbl: Label 'PO Number';
        PurchaseLine__Buy_from_Vendor_No__CaptionLbl: Label 'Vendor No.';
        Order_Status_and_NotesCaptionLbl: Label 'Order Status and Notes';
        Expected_DatesCaptionLbl: Label 'Expected Dates';
        Sales_Line__Document_No___Control82CaptionLbl: Label 'Sales Order/';
        Sales_Line__Bill_to_Customer_No___Control83CaptionLbl: Label 'Customer/';
        Expected_DatesCaption_Control32Lbl: Label 'Expected Dates';
        Sales_Line__No___Control78CaptionLbl: Label 'Item Number';
        PurchaseLine__Document_No___Control90CaptionLbl: Label 'PO Number';
        PurchaseLine__Buy_from_Vendor_No___Control91CaptionLbl: Label 'Vendor No.';
        Order_Status_and_NotesCaption_Control40Lbl: Label 'Order Status and Notes';
        Quantity_InvoicedCaption_Control4Lbl: Label 'Quantity Invoiced';
        Quantity_OrderedCaption_Control6Lbl: Label 'Quantity Ordered';
        Unit_of_MeasureCaption_Control8Lbl: Label 'Unit of Measure';
        Sales_Line__Document_No___Control98CaptionLbl: Label 'Sales Order Number';
        Sales_Line__No___Control104CaptionLbl: Label 'Item Number';
        PurchaseLine__Document_No___Control110CaptionLbl: Label 'PO Number';
        Vendor_NoCaptionLbl: Label 'Vendor No';
        Order_Status_and_NotesCaption_Control53Lbl: Label 'Order Status and Notes';
        Expected_DatesCaption_Control2Lbl: Label 'Expected Dates';
        Quantity_InvoicedCaption_Control5Lbl: Label 'Quantity Invoiced';
        Quantity_OrderedCaption_Control7Lbl: Label 'Quantity Ordered';
        Unit_of_MeasureCaption_Control9Lbl: Label 'Unit of Measure';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Purchase_Order_CaptionLbl: Label 'Purchase Order:';
        Type_CaptionLbl: Label 'Type:';
        Sales_Order_CaptionLbl: Label 'Sales Order:';
        Purchase_Order_Caption_Control97Lbl: Label 'Purchase Order:';
        Customer_CaptionLbl: Label 'Customer:';
        Phone_Caption_Control103Lbl: Label 'Phone:';
        Purchase_Order_Caption_Control117Lbl: Label 'Purchase Order:';
        No_Purchase_Order_IssuedCaptionLbl: Label 'No Purchase Order Issued';

    procedure QFormat(Qty: Decimal): Text[250]
    begin
        /* convert Decimal number to string, with 2 decimal places */
        TempStr := Format(Round(Qty));
        j := StrPos(TempStr, '.');
        if j = 0 then
            TempStr := TempStr + '.00'
        else
            if j = StrLen(TempStr) - 1 then
                TempStr := TempStr + '0';
        exit(TempStr);

    end;
}

