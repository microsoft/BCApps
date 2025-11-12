// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Security.User;

table 9055 "Purchase Cue"
{
    Caption = 'Purchase Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "To Send or Confirm"; Integer)
        {
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         Status = filter(Open),
                                                         "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'To Send or Confirm';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Upcoming Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         Status = filter(Released),
                                                         "Expected Receipt Date" = field("Date Filter"),
                                                         "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Upcoming Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Outstanding Purchase Orders"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         Status = filter(Released),
                                                         "Completely Received" = filter(false),
                                                         "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Outstanding Purchase Orders';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Purchase Return Orders - All"; Integer)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter("Return Order"),
                                                         "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Purchase Return Orders - All';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Not Invoiced"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         "Completely Received" = filter(true),
                                                         Invoice = filter(false),
                                                         "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Partially Invoiced"; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = filter(Order),
                                                         "Completely Received" = filter(true),
                                                         Invoice = filter(true),
                                                         "Responsibility Center" = field("Responsibility Center Filter")));
            Caption = 'Partially Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Responsibility Center Filter"; Code[10])
        {
            Caption = 'Responsibility Center Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetRespCenterFilter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        RespCenterCode: Code[10];
    begin
        RespCenterCode := UserSetupMgt.GetPurchasesFilter();
        if RespCenterCode <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center Filter", RespCenterCode);
            FilterGroup(0);
        end;
    end;

    procedure CountOrders(FieldNumber: Integer): Integer
    var
        PurchaseHeader: Record "Purchase Header";
        CountPurchOrders: Query "Count Purchase Orders";
        Result: Integer;
    begin
        case FieldNumber of
            FieldNo("Outstanding Purchase Orders"):
                begin
                    CountPurchOrders.SetRange(Status, PurchaseHeader.Status::Released);
                    CountPurchOrders.SetRange(Completely_Received, false);
                end;
            FieldNo("Not Invoiced"):
                begin
                    CountPurchOrders.SetRange(Completely_Received, true);
                    CountPurchOrders.SetRange(Partially_Invoiced, false);
                end;
            FieldNo("Partially Invoiced"):
                begin
                    CountPurchOrders.SetRange(Completely_Received, true);
                    CountPurchOrders.SetRange(Partially_Invoiced, true);
                end;
        end;
        FilterGroup(2);
        CountPurchOrders.SetFilter(Responsibility_Center, GetFilter("Responsibility Center Filter"));
        OnCountOrdersOnAfterCountPurchOrdersSetFilters(CountPurchOrders);
        FilterGroup(0);

        CountPurchOrders.Open();
        CountPurchOrders.Read();
        Result := CountPurchOrders.Count_Orders;

        exit(Result);
    end;

    procedure ShowOrders(FieldNumber: Integer)
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        case FieldNumber of
            FieldNo("Outstanding Purchase Orders"):
                begin
                    PurchHeader.SetRange(Status, PurchHeader.Status::Released);
                    PurchHeader.SetRange("Completely Received", false);
                    PurchHeader.SetRange(Invoice);
                end;
            FieldNo("Not Invoiced"):
                begin
                    PurchHeader.SetRange(Status);
                    PurchHeader.SetRange("Completely Received", true);
                    PurchHeader.SetRange(Invoice, false);
                end;
            FieldNo("Partially Invoiced"):
                begin
                    PurchHeader.SetRange(Status);
                    PurchHeader.SetRange("Completely Received", true);
                    PurchHeader.SetRange(Invoice, true);
                end;
        end;
        FilterGroup(2);
        PurchHeader.SetFilter("Responsibility Center", GetFilter("Responsibility Center Filter"));
        OnShowOrdersOnAfterPurchHeaderSetFilters(PurchHeader);
        FilterGroup(0);

        PAGE.Run(PAGE::"Purchase Order List", PurchHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCountOrdersOnAfterCountPurchOrdersSetFilters(var CountPurchOrders: Query "Count Purchase Orders")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowOrdersOnAfterPurchHeaderSetFilters(var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

