// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Routing;

tableextension 99001510 "Subc. RequisitionLine" extends "Requisition Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001516; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            DataClassification = CustomerContent;
            TableRelation = "Standard Task";
            ToolTip = 'Specifies the code that is assigned to the standard task.';
            trigger OnValidate()
            begin
                if (Type = Type::Item) and
                   ("No." <> '') and
                   ("Prod. Order No." <> '') and
                   (xRec."Standard Task Code" <> "Standard Task Code")
                then
                    UpdateSubcontractorPrice();
            end;
        }
        field(99001517; "Base UM Qty/PL UM Qty"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Base UM Qty/Price list UM Qty';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            ToolTip = 'Specifies the quantity of the base unit of measure or the price list unit of measure.';
        }
        field(99001518; "PL UM Qty/Base UM Qty"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Price list UM Qty/Base UM Qty';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity of the price list unit of measure or the base unit of measure.';
            trigger OnValidate()
            begin
                if (CurrFieldNo = FieldNo("PL UM Qty/Base UM Qty")) and
                   ("Prod. Order No." <> '') and
                   (Type = Type::Item) and
                   ("PL UM Qty/Base UM Qty" <> xRec."PL UM Qty/Base UM Qty")
                then begin
                    "Base UM Qty/PL UM Qty" := GetQuantityBase() / "PL UM Qty/Base UM Qty";
                    Validate("Pricelist Cost");
                end;
            end;
        }
        field(99001519; "UoM for Pricelist"; Code[10])
        {
            Caption = 'UoM for Price list';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
            ToolTip = 'Specifies the unit of measure for the price list that is on the subcontracting worksheet.';
            trigger OnValidate()
            begin
                if (CurrFieldNo = FieldNo("UoM for Pricelist")) and
                   ("Prod. Order No." <> '') and
                   (Type = Type::Item)
                then
                    UpdateSubcontractorPriceUOM();
            end;
        }
        field(99001520; "Pricelist Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Price list Cost';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the price list cost for the item on the subcontracting worksheet.';
            trigger OnValidate()
            var
                Currency: Record Currency;
                GeneralLedgerSetup: Record "General Ledger Setup";
            begin
                if ("Prod. Order No." <> '') and
                   (Type = Type::Item)
                then begin
                    "Direct Unit Cost" := "Pricelist Cost" / "Base UM Qty/PL UM Qty" * GetQuantityForUOM();
                    if ("Currency Code" <> '') and ("Direct Unit Cost" <> 0) then begin
                        Currency.Initialize("Currency Code");
                        Currency.TestField("Unit-Amount Rounding Precision");
                        "Direct Unit Cost" := Round("Direct Unit Cost", Currency."Unit-Amount Rounding Precision");
                    end else begin
                        GeneralLedgerSetup.Get();
                        "Direct Unit Cost" := Round("Direct Unit Cost", GeneralLedgerSetup."Unit-Amount Rounding Precision");
                    end;
                end;
            end;
        }
    }
    procedure GetQuantityForUOM(): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get("No.", "Unit of Measure Code");
        exit(ItemUnitofMeasure."Qty. per Unit of Measure");
    end;

    procedure GetQuantityBase(): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get("No.", "Unit of Measure Code");
        exit(Round(Quantity * ItemUnitofMeasure."Qty. per Unit of Measure", 0.00001));
    end;

    procedure UpdateSubcontractorPrice()
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        if (Type = Type::Item) and ("No." <> '') and ("Prod. Order No." <> '') then
            SubcPriceManagement.GetSubcPriceForReqLine(Rec, '');
    end;

    procedure UpdateSubcontractorPriceUOM()
    var
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
        if (Type = Type::Item) and ("No." <> '') and ("Prod. Order No." <> '') then
            SubcPriceManagement.GetSubcPriceForReqLine(Rec, "UoM for Pricelist");
    end;
}