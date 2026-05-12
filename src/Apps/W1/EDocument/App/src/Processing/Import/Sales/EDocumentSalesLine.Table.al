// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

table 6154 "E-Document Sales Line"
{
    Access = Internal;
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        #region External data - Sales fields [3-100]
        field(3; "External Line Id"; Text[100])
        {
            Caption = 'External Line Id';
            Editable = false;
        }
        field(4; "Description"; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description.';
            Editable = false;
        }
        field(5; "Quantity"; Decimal)
        {
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity.';
            Editable = false;
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(6; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            Editable = false;
        }
        field(7; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            ToolTip = 'Specifies the unit price.';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
        }
        field(8; "Line Extension Amount"; Decimal)
        {
            Caption = 'Line Extension Amount';
            ToolTip = 'Specifies the line extension amount.';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
        }
        field(9; "Line Discount Amount"; Decimal)
        {
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the line discount amount.';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
        }
        field(10; "VAT Rate"; Decimal)
        {
            Caption = 'VAT Rate';
            Editable = false;
            AutoFormatType = 0;
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
        field(12; "Buyer Item Id"; Text[100])
        {
            Caption = 'Buyer Item Id';
            Editable = false;
        }
        field(13; "Seller Item Id"; Text[100])
        {
            Caption = 'Seller Item Id';
            Editable = false;
        }
        field(14; "Standard Item Id"; Text[100])
        {
            Caption = 'Standard Item Id';
            Editable = false;
        }
        field(15; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            Editable = false;
        }
        #endregion Sales fields

        #region Business Central Data - Validated fields [101-200]
        field(101; "[BC] Sales Line Type"; Enum "Sales Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of entity that will be posted for this sales line, such as Item or Resource.';
        }
        field(102; "[BC] Sales Line No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the item or resource number.';
            TableRelation = if ("[BC] Sales Line Type" = const(" ")) "Standard Text"
            else
            if ("[BC] Sales Line Type" = const("G/L Account")) "G/L Account" where("Direct Posting" = const(true))
            else
            if ("[BC] Sales Line Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("[BC] Sales Line Type" = const("Charge (Item)")) "Item Charge"
            else
            if ("[BC] Sales Line Type" = const(Item)) Item
            else
            if ("[BC] Sales Line Type" = const("Allocation Account")) "Allocation Account"
            else
            if ("[BC] Sales Line Type" = const(Resource)) Resource;
        }
        field(103; "[BC] Unit of Measure"; Code[10])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the unit of measure code.';
            TableRelation = "Unit of Measure".Code;
        }
        field(104; "[BC] Item Reference No."; Code[50])
        {
            Caption = 'Item Reference No.';
            ToolTip = 'Specifies the item reference number.';
            TableRelation = "Item Reference"."Reference No." where("Unit of Measure" = field("[BC] Unit of Measure"), "Variant Code" = field("[BC] Variant Code"));
        }
        field(105; "[BC] Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant code.';
            TableRelation = "Item Variant".Code where("Item No." = field("[BC] Sales Line No."));
        }
        field(106; "[BC] Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(107; "[BC] Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(108; "[BC] Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        #endregion Validated fields
    }
    keys
    {
        key(PK; "E-Document Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    internal procedure GetNextLineNo(EDocumentEntryNo: Integer): Integer
    var
        EDocumentSalesLine: Record "E-Document Sales Line";
    begin
        EDocumentSalesLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        if EDocumentSalesLine.FindLast() then
            exit(EDocumentSalesLine."Line No." + 10000);
        exit(10000);
    end;

    procedure InsertForEDocument(EDocumentEntryNo: Integer)
    begin
        Rec."E-Document Entry No." := EDocumentEntryNo;
        Rec."Line No." := GetNextLineNo(EDocumentEntryNo);
        Rec.Insert();
    end;

    procedure GetFromEDocument(EDocument: Record "E-Document")
    begin
        Rec.SetRange("E-Document Entry No.", EDocument."Entry No");
    end;
}
