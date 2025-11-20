// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 304 "Item Entry Statistics"
{
    Caption = 'Item Entry Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group("Most Recently Posted")
            {
                Caption = 'Most Recently Posted';
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group(Date)
                    {
                        Caption = 'Date';
#pragma warning disable AA0100
                        field("ItemLedgEntry[5].""Posting Date"""; ItemLedgEntry[5]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Receipt';
                            ToolTip = 'Specifies item ledger entries that are related to purchase receipts.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[1].""Posting Date"""; ValueEntry[1]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Purchases';
                            ToolTip = 'Specifies item ledger entries that are related to purchases.';
                        }
#pragma warning disable AA0100
                        field("ItemLedgEntry[3].""Posting Date"""; ItemLedgEntry[3]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Positive Adjustment';
                            ToolTip = 'Specifies item ledger entries that are related to positive adjustment through an inventory journal.';
                        }
#pragma warning disable AA0100
                        field("ItemLedgEntry[6].""Posting Date"""; ItemLedgEntry[6]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Shipment';
                            ToolTip = 'Specifies item ledger entries that are related to sales shipments.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[2].""Posting Date"""; ValueEntry[2]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales';
                            ToolTip = 'Specifies item ledger entries that are related to sales.';
                        }
#pragma warning disable AA0100
                        field("ItemLedgEntry[4].""Posting Date"""; ItemLedgEntry[4]."Posting Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Negative Adjustment';
                            ToolTip = 'Specifies item ledger entries that are related to negative adjustment through an inventory journal.';
                        }
                    }
                    group("Document No.")
                    {
                        Caption = 'Document No.';
#pragma warning disable AA0100
                        field("ItemLedgEntry[5].""Document No."""; ItemLedgEntry[5]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[1].""Document No."""; ValueEntry[1]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("ItemLedgEntry[3].""Document No."""; ItemLedgEntry[3]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("ItemLedgEntry[6].""Document No."""; ItemLedgEntry[6]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[2].""Document No."""; ValueEntry[2]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
#pragma warning disable AA0100
                        field("ItemLedgEntry[4].""Document No."""; ItemLedgEntry[4]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies the number of the document that the statistic is based on.';
                        }
                    }
                    group(Quantity)
                    {
                        Caption = 'Quantity';
#pragma warning disable AA0100
                        field("ValueEntry[5].""Valued Quantity"""; ValueEntry[5]."Valued Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[1].""Invoiced Quantity"""; ValueEntry[1]."Invoiced Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                        field("ItemLedgEntry[3].Quantity"; ItemLedgEntry[3].Quantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
#pragma warning disable AA0100
                        field("-ValueEntry[6].""Valued Quantity"""; -ValueEntry[6]."Valued Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
#pragma warning disable AA0100
                        field("-ValueEntry[2].""Invoiced Quantity"""; -ValueEntry[2]."Invoiced Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                        field("-ItemLedgEntry[4].Quantity"; -ItemLedgEntry[4].Quantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            DecimalPlaces = 0 : 5;
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                    }
                    group("Unit Amount")
                    {
                        Caption = 'Unit Amount';
                        field("UnitAmount[5]"; UnitAmount[5])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                        field("UnitAmount[1]"; UnitAmount[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                        field("UnitAmount[3]"; UnitAmount[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                        field("UnitAmount[6]"; UnitAmount[6])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                        field("UnitAmount[2]"; UnitAmount[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                        field("UnitAmount[4]"; UnitAmount[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                    }
                    group("Discount Amount")
                    {
                        Caption = 'Discount Amount';
#pragma warning disable AA0100
                        field("ValueEntry[5].""Discount Amount"""; ValueEntry[5]."Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[1].""Discount Amount"""; ValueEntry[1]."Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[3].""Discount Amount"""; ValueEntry[3]."Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("-ValueEntry[6].""Discount Amount"""; -ValueEntry[6]."Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("-ValueEntry[2].""Discount Amount"""; -ValueEntry[2]."Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("-ValueEntry[4].""Discount Amount"""; -ValueEntry[4]."Discount Amount")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
#pragma warning disable AA0100
                        field("ValueEntry[5].""Cost Amount (Actual)"""; ValueEntry[5]."Cost Amount (Actual)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[1].""Cost Amount (Actual)"""; ValueEntry[1]."Cost Amount (Actual)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[3].""Cost Amount (Actual)"""; ValueEntry[3]."Cost Amount (Actual)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[6].""Sales Amount (Actual)"""; ValueEntry[6]."Sales Amount (Actual)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("ValueEntry[2].""Sales Amount (Actual)"""; ValueEntry[2]."Sales Amount (Actual)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
#pragma warning disable AA0100
                        field("-ValueEntry[4].""Cost Amount (Actual)"""; -ValueEntry[4]."Cost Amount (Actual)")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Amount';
                            ToolTip = 'Specifies the net amount of all the lines in the item entry.';
                        }
                    }
                }
            }
            group("To Be Posted")
            {
                Caption = 'To Be Posted';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group(Control1900206001)
                    {
                        Caption = 'Date';
#pragma warning disable AA0100
                        field("PurchOrderLine[1].""Expected Receipt Date"""; PurchOrderLine[1]."Expected Receipt Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Next Receipt';
                            ToolTip = 'Specifies information for the next expected receipt of the item.';
                        }
#pragma warning disable AA0100
                        field("PurchOrderLine[2].""Expected Receipt Date"""; PurchOrderLine[2]."Expected Receipt Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Last Receipt';
                            ToolTip = 'Specifies information about the last receipt that was posted for the item.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[1].""Shipment Date"""; SalesLine[1]."Shipment Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Next Shipment';
                            ToolTip = 'Specifies information about the next shipment that is expected for the item.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[2].""Shipment Date"""; SalesLine[2]."Shipment Date")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Last Shipment';
                            ToolTip = 'Specifies information about the last shipment that was posted for the item.';
                        }
                    }
                    group("Order No.")
                    {
                        Caption = 'Order No.';
#pragma warning disable AA0100
                        field("PurchOrderLine[1].""Document No."""; PurchOrderLine[1]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Order No.';
                            ToolTip = 'Specifies the number of the order that the item was handled on.';
                        }
#pragma warning disable AA0100
                        field("PurchOrderLine[2].""Document No."""; PurchOrderLine[2]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Order No.';
                            ToolTip = 'Specifies the number of the order that the item was handled on.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[1].""Document No."""; SalesLine[1]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Order No.';
                            ToolTip = 'Specifies the number of the order that the item was handled on.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[2].""Document No."""; SalesLine[2]."Document No.")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Order No.';
                            ToolTip = 'Specifies the number of the order that the item was handled on.';
                        }
                    }
                    group(Control1903098801)
                    {
                        Caption = 'Quantity';
                        field("PurchOrderLine[1].Quantity"; PurchOrderLine[1].Quantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                        field("PurchOrderLine[2].Quantity"; PurchOrderLine[2].Quantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                        field("SalesLine[1].Quantity"; SalesLine[1].Quantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                        field("SalesLine[2].Quantity"; SalesLine[2].Quantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Quantity';
                            ToolTip = 'Specifies the total quantity of items in the entry.';
                        }
                    }
                    group(Control1900545201)
                    {
                        Caption = 'Unit Amount';
#pragma warning disable AA0100
                        field("PurchOrderLine[1].""Direct Unit Cost"""; PurchOrderLine[1]."Direct Unit Cost")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
#pragma warning disable AA0100
                        field("PurchOrderLine[2].""Direct Unit Cost"""; PurchOrderLine[2]."Direct Unit Cost")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[1].""Unit Price"""; SalesLine[1]."Unit Price")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[2].""Unit Price"""; SalesLine[2]."Unit Price")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 2;
                            Caption = 'Unit Amount';
                            ToolTip = 'Specifies the value per unit on the item ledger entry.';
                        }
                    }
                    group("Qty. on Order")
                    {
                        Caption = 'Qty. on Order';
#pragma warning disable AA0100
                        field("PurchOrderLine[1].""Outstanding Quantity"""; PurchOrderLine[1]."Outstanding Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Qty. on Order';
                            ToolTip = 'Specifies the quantity on the order that the item was handled on.';
                        }
#pragma warning disable AA0100
                        field("PurchOrderLine[2].""Outstanding Quantity"""; PurchOrderLine[2]."Outstanding Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Qty. on Order';
                            ToolTip = 'Specifies the quantity on the order that the item was handled on.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[1].""Outstanding Quantity"""; SalesLine[1]."Outstanding Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Qty. on Order';
                            ToolTip = 'Specifies the quantity on the order that the item was handled on.';
                        }
#pragma warning disable AA0100
                        field("SalesLine[2].""Outstanding Quantity"""; SalesLine[2]."Outstanding Quantity")
#pragma warning restore AA0100
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Qty. on Order';
                            ToolTip = 'Specifies the quantity on the order that the item was handled on.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll();

        ItemLedgEntry2.SetCurrentKey(
          "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");

        ValueEntry2.SetCurrentKey(
          "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type",
          "Item Charge No.", "Location Code", "Variant Code", "Entry No.");

        ItemLedgEntry2.SetRange("Item No.", Rec."No.");
        ValueEntry2.SetRange("Item No.", Rec."No.");

        for j := 1 to 4 do begin
            ItemLedgEntry2.SetRange("Entry Type", j - 1); // Purchase,Positive Adjustment,Sale,Negative Adjustment
            Rec.CopyFilter("Variant Filter", ItemLedgEntry2."Variant Code");
            Rec.CopyFilter("Drop Shipment Filter", ItemLedgEntry2."Drop Shipment");
            Rec.CopyFilter("Location Filter", ItemLedgEntry2."Location Code");

            ValueEntry2.SetRange("Item Ledger Entry Type", j - 1);
            ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::"Direct Cost");
            Rec.CopyFilter("Variant Filter", ValueEntry2."Variant Code");
            Rec.CopyFilter("Drop Shipment Filter", ValueEntry2."Drop Shipment");
            Rec.CopyFilter("Location Filter", ValueEntry2."Location Code");

            if j in [1, 2] then begin // Purchase,Sale
                ValueEntry2.SetFilter("Invoiced Quantity", '<>0');
                FindLastValueEntry(j);
                ValueEntry2.SetRange("Invoiced Quantity");

                FindLastItemEntry(j + 4); // Receipt,Shipment
                ValueEntry2.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
                FindLastValueEntry(j + 4);
                ValueEntry2.SetRange("Item Ledger Entry No.");
            end else begin
                FindLastItemEntry(j);
                ValueEntry2.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
                FindLastValueEntry(j);
                ValueEntry2.SetRange("Item Ledger Entry No.");
            end;
        end;

        PurchLine2.Reset();
        PurchLine2.SetCurrentKey(
          "Document Type", Type, "No.", "Variant Code",
          "Drop Shipment", "Location Code", "Expected Receipt Date");
        PurchLine2.SetRange("Document Type", PurchLine2."Document Type"::Order);
        PurchLine2.SetRange(Type, PurchLine2.Type::Item);
        PurchLine2.SetRange("No.", Rec."No.");
        PurchLine2.SetFilter("Outstanding Quantity", '<>0');
        Rec.CopyFilter("Variant Filter", PurchLine2."Variant Code");
        Rec.CopyFilter("Drop Shipment Filter", PurchLine2."Drop Shipment");
        Rec.CopyFilter("Location Filter", PurchLine2."Location Code");
        if PurchLine2.Find('-') then begin
            PurchOrderLine[1] := PurchLine2;
            repeat
                if (PurchLine2."Expected Receipt Date" < PurchOrderLine[1]."Expected Receipt Date") or
                   ((PurchLine2."Expected Receipt Date" = PurchOrderLine[1]."Expected Receipt Date") and
                    (PurchLine2."Document No." < PurchOrderLine[1]."Document No."))
                then
                    PurchOrderLine[1] := PurchLine2;

                PurchLine2.SetRange("Variant Code", PurchLine2."Variant Code");
                PurchLine2.SetRange("Drop Shipment", PurchLine2."Drop Shipment");
                PurchLine2.SetRange("Location Code", PurchLine2."Location Code");
                PurchLine2.Find('+');

                if (PurchLine2."Expected Receipt Date" > PurchOrderLine[2]."Expected Receipt Date") or
                   ((PurchLine2."Expected Receipt Date" = PurchOrderLine[2]."Expected Receipt Date") and
                    (PurchLine2."Document No." > PurchOrderLine[2]."Document No."))
                then
                    PurchOrderLine[2] := PurchLine2;

                Rec.CopyFilter("Variant Filter", PurchLine2."Variant Code");
                Rec.CopyFilter("Location Filter", PurchLine2."Location Code");
                Rec.CopyFilter("Drop Shipment Filter", PurchLine2."Drop Shipment");
            until PurchLine2.Next() = 0;
        end;

        SalesLine2.Reset();
        SalesLine2.SetCurrentKey(
          "Document Type", Type, "No.", "Variant Code",
          "Drop Shipment", "Location Code", "Shipment Date");
        SalesLine2.SetRange("Document Type", SalesLine2."Document Type"::Order);
        SalesLine2.SetRange(Type, SalesLine2.Type::Item);
        SalesLine2.SetRange("No.", Rec."No.");
        Rec.CopyFilter("Variant Filter", SalesLine2."Variant Code");
        SalesLine2.SetFilter("Outstanding Quantity", '<>0');
        Rec.CopyFilter("Drop Shipment Filter", SalesLine2."Drop Shipment");
        Rec.CopyFilter("Location Filter", SalesLine2."Location Code");
        if SalesLine2.Find('-') then begin
            SalesLine[1] := SalesLine2;
            repeat
                if (SalesLine2."Shipment Date" < SalesLine[1]."Shipment Date") or
                   ((SalesLine2."Shipment Date" = SalesLine[1]."Shipment Date") and
                    (SalesLine2."Document No." < SalesLine[1]."Document No."))
                then
                    SalesLine[1] := SalesLine2;

                SalesLine2.SetRange("Variant Code", SalesLine2."Variant Code");
                SalesLine2.SetRange("Drop Shipment", SalesLine2."Drop Shipment");
                SalesLine2.SetRange("Location Code", SalesLine2."Location Code");
                SalesLine2.Find('+');

                if (SalesLine2."Shipment Date" > SalesLine[2]."Shipment Date") or
                   ((SalesLine2."Shipment Date" = SalesLine[2]."Shipment Date") and
                    (SalesLine2."Document No." > SalesLine[2]."Document No."))
                then
                    SalesLine[2] := SalesLine2;

                Rec.CopyFilter("Variant Filter", SalesLine2."Variant Code");
                Rec.CopyFilter("Location Filter", SalesLine2."Location Code");
                Rec.CopyFilter("Drop Shipment Filter", SalesLine2."Drop Shipment");
            until SalesLine2.Next() = 0;
        end;
    end;

    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntry2: Record "Value Entry";
        PurchLine2: Record "Purchase Line";
        SalesLine2: Record "Sales Line";
        ItemLedgEntry: array[6] of Record "Item Ledger Entry";
        ValueEntry: array[6] of Record "Value Entry";
        PurchOrderLine: array[2] of Record "Purchase Line";
        SalesLine: array[2] of Record "Sales Line";
        j: Integer;
        UnitAmount: array[6] of Decimal;

    local procedure FindLastItemEntry(k: Integer)
    begin
        if ItemLedgEntry2.Find('-') then
            repeat
                ItemLedgEntry2.SetRange("Variant Code", ItemLedgEntry2."Variant Code");
                ItemLedgEntry2.SetRange("Drop Shipment", ItemLedgEntry2."Drop Shipment");
                ItemLedgEntry2.SetRange("Location Code", ItemLedgEntry2."Location Code");
                ItemLedgEntry2.Find('+');

                if (ItemLedgEntry2."Posting Date" > ItemLedgEntry[k]."Posting Date") or
                   ((ItemLedgEntry2."Posting Date" = ItemLedgEntry[k]."Posting Date") and
                    (ItemLedgEntry2."Entry No." > ItemLedgEntry[k]."Entry No."))
                then
                    ItemLedgEntry[k] := ItemLedgEntry2;

                Rec.CopyFilter("Variant Filter", ItemLedgEntry2."Variant Code");
                Rec.CopyFilter("Drop Shipment Filter", ItemLedgEntry2."Drop Shipment");
                Rec.CopyFilter("Location Filter", ItemLedgEntry2."Location Code");
            until ItemLedgEntry2.Next() = 0;
    end;

    local procedure FindLastValueEntry(k: Integer)
    begin
        if ValueEntry2.Find('-') then
            repeat
                ValueEntry2.SetRange("Variant Code", ValueEntry2."Variant Code");
                ValueEntry2.SetRange("Drop Shipment", ValueEntry2."Drop Shipment");
                ValueEntry2.SetRange("Location Code", ValueEntry2."Location Code");
                ValueEntry2.Find('+');

                if (ValueEntry2."Posting Date" > ValueEntry[k]."Posting Date") or
                   ((ValueEntry2."Posting Date" = ValueEntry[k]."Posting Date") and
                    (ValueEntry2."Entry No." > ValueEntry[k]."Entry No."))
                then begin
                    ValueEntry[k] := ValueEntry2;
                    if ValueEntry2."Valued Quantity" <> 0 then begin
                        if ValueEntry2."Item Ledger Entry Type" = ValueEntry2."Item Ledger Entry Type"::Sale then
                            UnitAmount[k] :=
                              -(ValueEntry2."Sales Amount (Actual)" - ValueEntry2."Discount Amount") / ValueEntry2."Valued Quantity"
                        else
                            UnitAmount[k] :=
                              (ValueEntry2."Cost Amount (Actual)" + ValueEntry2."Discount Amount") / ValueEntry2."Valued Quantity"
                    end else
                        UnitAmount[k] := 0;
                end;
                Rec.CopyFilter("Variant Filter", ValueEntry2."Variant Code");
                Rec.CopyFilter("Drop Shipment Filter", ValueEntry2."Drop Shipment");
                Rec.CopyFilter("Location Filter", ValueEntry2."Location Code");
            until ValueEntry2.Next() = 0;
    end;
}

