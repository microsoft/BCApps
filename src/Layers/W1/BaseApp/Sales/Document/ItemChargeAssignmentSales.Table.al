// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

table 5809 "Item Charge Assignment (Sales)"
{
    Caption = 'Item Charge Assignment (Sales)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header"."No." where("Document Type" = field("Document Type"));
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = field("Document Type"),
                                                           "Document No." = field("Document No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            NotBlank = true;
            TableRelation = "Item Charge";
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Qty. to Assign"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                SalesReceivablesSetup: Record "Sales & Receivables Setup";
            begin
                SalesReceivablesSetup.Get();
                SalesLine.Get("Document Type", "Document No.", "Document Line No.");
                if Rec."Qty. to Assign" <> xRec."Qty. to Assign" then
                    if SalesReceivablesSetup."Default Quantity to Ship" <> SalesReceivablesSetup."Default Quantity to Ship"::Blank then
                        SalesLine.TestField("Qty. to Invoice");

                TestField("Applies-to Doc. Line No.");
                if ("Qty. to Assign" <> 0) and ("Applies-to Doc. Type" = "Document Type") then
                    if SalesLineInvoiced() then
                        Error(CannotAssignToInvoiced, SalesLine.TableCaption());
                Validate("Qty. to Handle", "Qty. to Assign");
                Validate("Amount to Assign");
            end;
        }
        field(9; "Qty. Assigned"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(10; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                Validate("Amount to Assign");
            end;
        }
        field(11; "Amount to Assign"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Assign';

            trigger OnValidate()
            var
                ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
            begin
                GetCurrency();
                "Amount to Assign" := Round("Qty. to Assign" * "Unit Cost", Currency."Amount Rounding Precision");
                ItemChargeAssgntSales.SuggestAssignmentFromLine(Rec);
            end;
        }
        field(12; "Applies-to Doc. Type"; Enum "Sales Applies-to Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(13; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            TableRelation = if ("Applies-to Doc. Type" = const(Order)) "Sales Header"."No." where("Document Type" = const(Order))
            else
            if ("Applies-to Doc. Type" = const(Invoice)) "Sales Header"."No." where("Document Type" = const(Invoice))
            else
            if ("Applies-to Doc. Type" = const("Return Order")) "Sales Header"."No." where("Document Type" = const("Return Order"))
            else
            if ("Applies-to Doc. Type" = const("Credit Memo")) "Sales Header"."No." where("Document Type" = const("Credit Memo"))
            else
            if ("Applies-to Doc. Type" = const(Shipment)) "Sales Shipment Header"."No."
            else
            if ("Applies-to Doc. Type" = const("Return Receipt")) "Return Receipt Header"."No.";
        }
        field(14; "Applies-to Doc. Line No."; Integer)
        {
            Caption = 'Applies-to Doc. Line No.';
            TableRelation = if ("Applies-to Doc. Type" = const(Order)) "Sales Line"."Line No." where("Document Type" = const(Order),
                                                                                                    "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const(Invoice)) "Sales Line"."Line No." where("Document Type" = const(Invoice),
                                                                                                                                                                                   "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const("Return Order")) "Sales Line"."Line No." where("Document Type" = const("Return Order"),
                                                                                                                                                                                                                                                                         "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const("Credit Memo")) "Sales Line"."Line No." where("Document Type" = const("Credit Memo"),
                                                                                                                                                                                                                                                                                                                                                              "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const(Shipment)) "Sales Shipment Line"."Line No." where("Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const("Return Receipt")) "Return Receipt Line"."Line No." where("Document No." = field("Applies-to Doc. No."));
        }
        field(15; "Applies-to Doc. Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Applies-to Doc. Line Amount';
        }
        field(16; "Qty. to Handle"; Decimal)
        {
            BlankZero = true;
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Handle" <> 0 then
                    TestField("Qty. to Handle", "Qty. to Assign");
                Validate("Amount to Handle");
            end;
        }
        field(17; "Amount to Handle"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Handle';

            trigger OnValidate()
            begin
                GetCurrency();
                "Amount to Handle" := Round("Qty. to Handle" * "Unit Cost", Currency."Amount Rounding Precision");
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.")
        {
        }
        key(Key3; "Applies-to Doc. Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Qty. Assigned", 0);
        Validate("Qty. to Assign", 0);
    end;

    var
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
#pragma warning disable AA0074
#pragma warning disable AA0470
        CannotAssignToInvoiced: Label 'You cannot assign item charges to the %1 because it has been invoiced. Instead you can get the posted document line and then assign the item charge to that line.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemChargeDeletionErr: Label 'You cannot delete posted documents that are applied as item charges to sales lines. This document applied to item %3 in %1 %2.', Comment = '%1 - Document Type; %2 - Document No., %3 - Item No.';

    local procedure GetCurrency()
    begin
        SalesLine.Get("Document Type", "Document No.", "Document Line No.");
        if not Currency.Get(SalesLine."Currency Code") then
            Currency.InitRoundingPrecision();
    end;

    procedure SalesLineInvoiced() Result: Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        Result := SalesLine.Quantity = SalesLine."Quantity Invoiced";
        OnAfterSalesLineInvoiced(Rec, SalesLine, Result);
    end;

    procedure CheckAssignment(AppliesToDocumentType: Enum "Sales Applies-to Document Type"; AppliesToDocumentNo: Code[20]; AppliesToDocumentLineNo: Integer)
    begin
        Reset();
        SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        SetRange("Applies-to Doc. Type", AppliesToDocumentType);
        SetRange("Applies-to Doc. No.", AppliesToDocumentNo);
        SetRange("Applies-to Doc. Line No.", AppliesToDocumentLineNo);
        if FindFirst() then
            error(ItemChargeDeletionErr, "Document Type", "Document No.", "Item No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineInvoiced(ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; var SalesLine: Record "Sales Line"; var Result: Boolean)
    begin
    end;
}

