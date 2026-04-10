// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 5800 "Item Charge"
{
    Caption = 'Item Charge';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Item Charges";
    LookupPageID = "Item Charges";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            OptimizeForTextSearch = true;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item charge number that you are setting up.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(3; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item charge''s product type to link transactions made for this item charge with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                GenProdPostingGrp: Record "Gen. Product Posting Group";
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(4; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            ToolTip = 'Specifies the sales tax group code that this item charge belongs to.';
            TableRelation = "Tax Group";
        }
        field(5; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
            OptimizeForTextSearch = true;
        }
        field(6; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            ToolTip = 'Specifies text to search for when you do not know the number of the item charge.';
            OptimizeForTextSearch = true;
        }
        field(7; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(8; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Gen. Prod. Posting Group")
        {
        }
        key(Key4; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Gen. Prod. Posting Group", "VAT Prod. Posting Group")
        {
        }
    }

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::"Item Charge", "No.");
    end;

    trigger OnModify()
    begin
        DimMgt.UpdateDefaultDim(
          DATABASE::"Item Charge", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::"Charge (Item)", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::"Charge (Item)", xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::"Item Charge", xRec."No.", "No.");
    end;

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Item Charge", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ItemCharge: Record "Item Charge"; xItemCharge: Record "Item Charge"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ItemCharge: Record "Item Charge"; xItemCharge: Record "Item Charge"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

