// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;

using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;

table 5805 "Item Charge Assignment (Purch)"
{
    Caption = 'Item Charge Assignment (Purch)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Purchase Header"."No." where("Document Type" = field("Document Type"));
        }
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = "Purchase Line"."Line No." where("Document Type" = field("Document Type"),
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
            ToolTip = 'Specifies the item number on the document line that this item charge is assigned to.';
            TableRelation = Item;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item on the document line that this item charge is assigned to.';
        }
        field(8; "Qty. to Assign"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. to Assign';
            ToolTip = 'Specifies how many units of the item charge will be assigned to the document line. If the document has more than one line of type Item, then this quantity reflects the distribution that you selected when you chose the Suggest Item Charge Assignment action.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                PurchasePayablesSetup: Record "Purchases & Payables Setup";
                IsHandled: Boolean;
            begin
                PurchasePayablesSetup.Get();
                PurchLine.Get("Document Type", "Document No.", "Document Line No.");
                if Rec."Qty. to Assign" <> xRec."Qty. to Assign" then
                    if PurchasePayablesSetup."Default Qty. to Receive" <> PurchasePayablesSetup."Default Qty. to Receive"::Blank then
                        PurchLine.TestField("Qty. to Invoice");

                IsHandled := false;
                OnValidateQtyToAssignOnBeforeTestFieldAppliesToDocLineNo(Rec, IsHandled);
                if not IsHandled then
                    TestField("Applies-to Doc. Line No.");
                if ("Qty. to Assign" <> 0) and ("Applies-to Doc. Type" = "Document Type") then
                    if PurchLineInvoiced() then
                        Error(CannotAssignToInvoicedErr, PurchLine.TableCaption());
                Validate("Qty. to Handle", "Qty. to Assign");
                Validate("Amount to Assign");
            end;
        }
        field(9; "Qty. Assigned"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. Assigned';
            ToolTip = 'Specifies the number of units of the item charge will be assigned to the document line.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(10; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                Validate("Amount to Assign");
            end;
        }
        field(11; "Amount to Assign"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount to Assign';
            ToolTip = 'Specifies the value of the item charge that is going to be assigned to the document line.';

            trigger OnValidate()
            var
                ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
            begin
                GetCurrency();
                "Amount to Assign" := Round("Qty. to Assign" * "Unit Cost", Currency."Amount Rounding Precision");
                ItemChargeAssgntPurch.SuggestAssgntFromLine(Rec);
            end;
        }
        field(12; "Applies-to Doc. Type"; Enum "Purchase Applies-to Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            ToolTip = 'Specifies the type of the document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        field(13; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            ToolTip = 'Specifies the number of the document that this document or journal line will be applied to when you post, for example to register payment.';
            TableRelation = if ("Applies-to Doc. Type" = const(Order)) "Purchase Header"."No." where("Document Type" = const(Order))
            else
            if ("Applies-to Doc. Type" = const(Invoice)) "Purchase Header"."No." where("Document Type" = const(Invoice))
            else
            if ("Applies-to Doc. Type" = const("Return Order")) "Purchase Header"."No." where("Document Type" = const("Return Order"))
            else
            if ("Applies-to Doc. Type" = const("Credit Memo")) "Purchase Header"."No." where("Document Type" = const("Credit Memo"))
            else
            if ("Applies-to Doc. Type" = const(Receipt)) "Purch. Rcpt. Header"."No."
            else
            if ("Applies-to Doc. Type" = const("Return Shipment")) "Return Shipment Header"."No.";
        }
        field(14; "Applies-to Doc. Line No."; Integer)
        {
            Caption = 'Applies-to Doc. Line No.';
            ToolTip = 'Specifies the number of the line on the document that this document or journal line will be applied to when you post, for example to register payment.';
            TableRelation = if ("Applies-to Doc. Type" = const(Order)) "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                                                                       "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const(Invoice)) "Purchase Line"."Line No." where("Document Type" = const(Invoice),
                                                                                                                                                                                         "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const("Return Order")) "Purchase Line"."Line No." where("Document Type" = const("Return Order"),
                                                                                                                                                                                                                                                                                  "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const("Credit Memo")) "Purchase Line"."Line No." where("Document Type" = const("Credit Memo"),
                                                                                                                                                                                                                                                                                                                                                                          "Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const(Receipt)) "Purch. Rcpt. Line"."Line No." where("Document No." = field("Applies-to Doc. No."))
            else
            if ("Applies-to Doc. Type" = const("Return Shipment")) "Return Shipment Line"."Line No." where("Document No." = field("Applies-to Doc. No."));
        }
        field(15; "Applies-to Doc. Line Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applies-to Doc. Line Amount';
        }
        field(16; "Qty. to Handle"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. to Handle';
            ToolTip = 'Specifies how many items the item charge will be assigned to on the line. It can be either equal to Qty. to Assign or to zero. If it is zero, the item charge will not be assigned to the line.';
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
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount to Handle';
            ToolTip = 'Specifies the value of the item charge that will be actually assigned to the document line.';

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
        PurchLine: Record "Purchase Line";
        Currency: Record Currency;
#pragma warning disable AA0470
        CannotAssignToInvoicedErr: Label 'You cannot assign item charges to the %1 because it has been invoiced. Instead you can get the posted document line and then assign the item charge to that line.';
#pragma warning restore AA0470
        ItemChargeDeletionErr: Label 'You cannot delete posted documents that are applied as item charges to purchase lines. This document applied to %1 %2 %3.', Comment = '%1 - Document Type; %2 - Document No., %3 - Item No.';

    local procedure GetCurrency()
    begin
        PurchLine.Get("Document Type", "Document No.", "Document Line No.");
        if not Currency.Get(PurchLine."Currency Code") then
            Currency.InitRoundingPrecision();
    end;

    local procedure GetCurrencyCode(): Code[10]
    begin
        if PurchLine.Get("Document Type", "Document No.", "Document Line No.") then
            exit(PurchLine."Currency Code");
    end;

    procedure PurchLineInvoiced(): Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        PurchLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        exit(PurchLine.Quantity = PurchLine."Quantity Invoiced");
    end;

    procedure CheckAssignment(AppliesToDocumentType: Enum "Purchase Applies-to Document Type"; AppliesToDocumentNo: Code[20]; AppliesToDocumentLineNo: Integer)
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
    local procedure OnValidateQtyToAssignOnBeforeTestFieldAppliesToDocLineNo(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; var IsHandled: Boolean)
    begin
    end;
}
