// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

/// <summary>
/// Stores item charge allocation data linking charges to specific sales shipment or return receipt lines.
/// </summary>
table 5809 "Item Charge Assignment (Sales)"
{
    Caption = 'Item Charge Assignment (Sales)';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the type of sales document for this item charge assignment.
        /// </summary>
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Specifies the sales document number containing the item charge line.
        /// </summary>
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Sales Header"."No." where("Document Type" = field("Document Type"));
        }
        /// <summary>
        /// Specifies the line number of the item charge on the sales document.
        /// </summary>
        field(3; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = field("Document Type"),
                                                           "Document No." = field("Document No."));
        }
        /// <summary>
        /// Specifies the unique line number for this charge assignment entry.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Specifies the item charge number being assigned to sales lines.
        /// </summary>
        field(5; "Item Charge No."; Code[20])
        {
            Caption = 'Item Charge No.';
            NotBlank = true;
            TableRelation = "Item Charge";
        }
        /// <summary>
        /// Specifies the item number that receives the allocated charge.
        /// </summary>
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number on the document line that this item charge is assigned to.';
            TableRelation = Item;
        }
        /// <summary>
        /// Contains a description of the item charge assignment.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item on the document line that this item charge is assigned to.';
        }
        /// <summary>
        /// Specifies the quantity of the item charge to be assigned to the target document line.
        /// </summary>
        field(8; "Qty. to Assign"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. to Assign';
            ToolTip = 'Specifies how many units of the item charge will be assigned to the document line. If the document has more than one line of type Item, then this quantity reflects the distribution that you selected when you chose the Suggest Item Charge Assignment action.';
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
        /// <summary>
        /// Specifies the quantity of the item charge that has already been assigned.
        /// </summary>
        field(9; "Qty. Assigned"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Qty. Assigned';
            ToolTip = 'Specifies the number of units of the item charge will be assigned to the document line.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        /// <summary>
        /// Specifies the unit cost of the item charge for assignment calculations.
        /// </summary>
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
        /// <summary>
        /// Specifies the total amount of the item charge to be assigned, calculated from quantity and unit cost.
        /// </summary>
        field(11; "Amount to Assign"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount to Assign';
            ToolTip = 'Specifies the value of the item charge that is going to be assigned to the document line.';

            trigger OnValidate()
            var
                ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
            begin
                GetCurrency();
                "Amount to Assign" := Round("Qty. to Assign" * "Unit Cost", Currency."Amount Rounding Precision");
                ItemChargeAssgntSales.SuggestAssignmentFromLine(Rec);
            end;
        }
        /// <summary>
        /// Specifies the type of document to which this item charge is applied.
        /// </summary>
        field(12; "Applies-to Doc. Type"; Enum "Sales Applies-to Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            ToolTip = 'Specifies the type of the document that this document or journal line will be applied to when you post, for example to register payment.';
        }
        /// <summary>
        /// Specifies the document number to which this item charge is applied.
        /// </summary>
        field(13; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            ToolTip = 'Specifies the number of the document that this document or journal line will be applied to when you post, for example to register payment.';
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
        /// <summary>
        /// Specifies the document line number to which this item charge is applied.
        /// </summary>
        field(14; "Applies-to Doc. Line No."; Integer)
        {
            Caption = 'Applies-to Doc. Line No.';
            ToolTip = 'Specifies the number of the line on the document that this document or journal line will be applied to when you post, for example to register payment.';
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
        /// <summary>
        /// Specifies the amount of the document line to which the charge is applied.
        /// </summary>
        field(15; "Applies-to Doc. Line Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applies-to Doc. Line Amount';
        }
        /// <summary>
        /// Specifies the quantity of item charges to handle when posting.
        /// </summary>
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
        /// <summary>
        /// Specifies the amount of item charges to handle when posting.
        /// </summary>
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

    local procedure GetCurrencyCode(): Code[10]
    begin
        if SalesLine.Get("Document Type", "Document No.", "Document Line No.") then
            exit(SalesLine."Currency Code");
    end;

    /// <summary>
    /// Checks whether the applied-to sales line is fully invoiced.
    /// </summary>
    /// <returns>True if the sales line is fully invoiced.</returns>
    procedure SalesLineInvoiced() Result: Boolean
    begin
        if "Applies-to Doc. Type" <> "Document Type" then
            exit(false);
        SalesLine.Get("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        Result := SalesLine.Quantity = SalesLine."Quantity Invoiced";
        OnAfterSalesLineInvoiced(Rec, SalesLine, Result);
    end;

    /// <summary>
    /// Checks if item charge assignments exist for the specified document line and raises an error if found.
    /// </summary>
    /// <param name="AppliesToDocumentType">The document type to check.</param>
    /// <param name="AppliesToDocumentNo">The document number to check.</param>
    /// <param name="AppliesToDocumentLineNo">The document line number to check.</param>
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
