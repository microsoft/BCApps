// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Sales.Customer;
using Microsoft.Service.History;

page 9086 "Service Hist. Bill-to FactBox"
{
    Caption = 'Bill-to Customer Service History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group(Control1)
            {
                ShowCaption = false;
                Visible = false;
                field(NoOfQuotes; NoOfQuotes)
                {
                    ApplicationArea = Service;
                    Caption = 'Quotes';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of quotes that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Quotes", ServiceHeader);
                    end;
                }
                field(NoOfOrders; NoOfOrders)
                {
                    ApplicationArea = Service;
                    Caption = 'Orders';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of posted orders that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Orders", ServiceHeader);
                    end;
                }
                field(NoOfInvoices; NoOfInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the invoice related to the customer service history.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Invoices", ServiceHeader);
                    end;
                }
                field(NoOfCreditMemos; NoOfCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies service credit memos relating to the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Credit Memos", ServiceHeader);
                    end;
                }
                field(NoOfPostedShipments; NoOfPostedShipments)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Shipments';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceShipmentHdr: Record "Service Shipment Header";
                    begin
                        ServiceShipmentHdr.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Posted Service Shipments", ServiceShipmentHdr);
                    end;
                }
                field(NoOfPostedInvoices; NoOfPostedInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceInvoiceHdr: Record "Service Invoice Header";
                    begin
                        ServiceInvoiceHdr.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Posted Service Invoices", ServiceInvoiceHdr);
                    end;
                }
                field(NoOfPostedCreditMemos; NoOfPostedCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceCrMemoHdr: Record "Service Cr.Memo Header";
                    begin
                        ServiceCrMemoHdr.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Posted Service Credit Memos", ServiceCrMemoHdr);
                    end;
                }
            }
            cuegroup(Control14)
            {
                ShowCaption = false;
                Visible = true;
                field(NoOfQuotesTile; NoOfQuotes)
                {
                    ApplicationArea = Service;
                    Caption = 'Quotes';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of quotes that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Quotes", ServiceHeader);
                    end;
                }
                field(NoOfOrdersTile; NoOfOrders)
                {
                    ApplicationArea = Service;
                    Caption = 'Orders';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of posted orders that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Orders", ServiceHeader);
                    end;
                }
                field(NoOfInvoicesTile; NoOfInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the invoice related to the customer service history.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Invoices", ServiceHeader);
                    end;
                }
                field(NoOfCreditMemosTile; NoOfCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies service credit memos relating to the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Service Credit Memos", ServiceHeader);
                    end;
                }
                field(NoOfPostedShipmentsTile; NoOfPostedShipments)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Shipments';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceShipmentHdr: Record "Service Shipment Header";
                    begin
                        ServiceShipmentHdr.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Posted Service Shipments", ServiceShipmentHdr);
                    end;
                }
                field(NoOfPostedInvoicesTile; NoOfPostedInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceInvoiceHdr: Record "Service Invoice Header";
                    begin
                        ServiceInvoiceHdr.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Posted Service Invoices", ServiceInvoiceHdr);
                    end;
                }
                field(NoOfPostedCreditMemosTile; NoOfPostedCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceCrMemoHdr: Record "Service Cr.Memo Header";
                    begin
                        ServiceCrMemoHdr.SetRange("Bill-to Customer No.", Rec."No.");
                        PAGE.Run(PAGE::"Posted Service Credit Memos", ServiceCrMemoHdr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnFindRecord(Which: Text): Boolean
    var
        Result: Boolean;
    begin
        if Rec.Find(Which) then begin
            Rec.FilterGroup(4);
            Rec."No." := Rec.GetBillToCustomerNo();
            Rec.FilterGroup(0);
            Result := true;
        end;

        CalcNoOfBillRecords();
        exit(Result);
    end;

    var
        NoOfQuotes: Integer;
        NoOfOrders: Integer;
        NoOfInvoices: Integer;
        NoOfCreditMemos: Integer;
        NoOfPostedShipments: Integer;
        NoOfPostedInvoices: Integer;
        NoOfPostedCreditMemos: Integer;
        TaskIdCalculateCue: Integer;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;

    local procedure CalcNoOfBillRecords()
    var
        CalcServiceHistFactBox: Codeunit "Calc. Service Hist Fact Box";
        Args: Dictionary of [Text, Text];
    begin
        if (TaskIdCalculateCue <> 0) then
            CurrPage.CancelBackgroundTask(TaskIdCalculateCue);

        NoOfQuotes := 0;
        NoOfOrders := 0;
        NoOfInvoices := 0;
        NoOfCreditMemos := 0;
        NoOfPostedShipments := 0;
        NoOfPostedInvoices := 0;
        NoOfPostedCreditMemos := 0;

        Args.Add(CalcServiceHistFactBox.GetBillToCustomerNoLbl(), Rec."No.");
        CurrPage.EnqueueBackgroundTask(TaskIdCalculateCue, Codeunit::"Calc. Service Hist Fact Box", Args);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CalcServiceHistFactBox: Codeunit "Calc. Service Hist Fact Box";
    begin
        if (TaskId <> TaskIdCalculateCue) or (Results.Count() = 0) then
            exit;

        NoOfQuotes := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfQuotesLbl());
        NoOfOrders := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfOrdersLbl());
        NoOfInvoices := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfInvoicesLbl());
        NoOfCreditMemos := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfCreditMemosLbl());
        NoOfPostedShipments := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfPostedShipmentsLbl());
        NoOfPostedInvoices := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfPostedInvoicesLbl());
        NoOfPostedCreditMemos := GetResultAsInt(Results, CalcServiceHistFactBox.GetNoOfPostedCreditMemosLbl());
    end;

    local procedure GetResultAsInt(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text): Integer
    var
        i: Integer;
    begin
        if not DictionaryToLookIn.ContainsKey(KeyToSearchFor) then
            exit(0);
        if Evaluate(i, DictionaryToLookIn.Get(KeyToSearchFor)) then;
        exit(i);
    end;
}

