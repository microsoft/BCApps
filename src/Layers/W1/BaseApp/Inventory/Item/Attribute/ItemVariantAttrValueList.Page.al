// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7514 "Item Variant Attr. Value List"
{
    Caption = 'Item Variant Attribute Values';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Item Attribute Value Selection";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Attribute';
                    TableRelation = "Item Attribute".Name where(Blocked = const(false));
                    ToolTip = 'Specifies the item variant attribute.';

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttribute: Record "Item Attribute";
                    begin
                        if xRec."Attribute Name" <> '' then begin
                            xRec.FindItemAttributeByName(ItemAttribute);
                            DeleteItemVariantAttributeValueMapping(ItemAttribute.ID);
                        end;

                        if (Rec.Value <> '') and not Rec.FindAttributeValue(ItemAttributeValue) then
                            Rec.InsertItemAttributeValue(ItemAttributeValue, Rec);

                        InsertItemVariantAttributeValueMapping(ItemAttributeValue);

                        CurrPage.Update(true);
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    TableRelation = if ("Attribute Type" = const(Option)) "Item Attribute Value".Value where("Attribute ID" = field("Attribute ID"),
                                                                                                            Blocked = const(false));
                    ToolTip = 'Specifies the value of the item variant attribute.';

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
                        ItemAttribute: Record "Item Attribute";
                    begin
                        if not Rec.FindAttributeValue(ItemAttributeValue) then
                            Rec.InsertItemAttributeValue(ItemAttributeValue, Rec);

                        InsertItemVariantAttributeValueMapping(ItemAttributeValue);
                        ItemVariantAttributeValueMapping.SetRange("Item No.", RelatedItemCode);
                        ItemVariantAttributeValueMapping.SetRange("Variant Code", RelatedVariantCode);
                        ItemVariantAttributeValueMapping.SetRange("Item Attribute ID", ItemAttributeValue."Attribute ID");
                        if ItemVariantAttributeValueMapping.FindFirst() then begin
                            ItemVariantAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValue.ID;
                            ItemVariantAttributeValueMapping."Inherited-From Table ID" := 0;
                            ItemVariantAttributeValueMapping."Inherited-From Key Value" := '';
                            ItemVariantAttributeValueMapping.Modify();

                            Rec."Inherited-From Table ID" := 0;
                            Rec."Inherited-From Key Value" := '';
                            Rec.Modify();
                        end;

                        ItemAttribute.Get(Rec."Attribute ID");
                        if ItemAttribute.Type <> ItemAttribute.Type::Option then
                            if Rec.FindAttributeValueFromRecord(ItemAttributeValue, xRec) then
                                if not ItemAttributeValue.HasBeenUsed() then
                                    ItemAttributeValue.Delete();
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        DeleteItemVariantAttributeValueMapping(Rec."Attribute ID");
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Editable(true);
    end;

    protected var
        RelatedItemCode: Code[20];
        RelatedVariantCode: Code[10];

    procedure LoadAttributes(ItemNo: Code[20]; VariantCode: Code[10])
    var
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        RelatedItemCode := ItemNo;
        RelatedVariantCode := VariantCode;
        ItemVariantAttributeValueMapping.SetRange("Item No.", ItemNo);
        ItemVariantAttributeValueMapping.SetRange("Variant Code", VariantCode);
        if ItemVariantAttributeValueMapping.FindSet() then
            repeat
                ItemAttributeValue.Get(ItemVariantAttributeValueMapping."Item Attribute ID", ItemVariantAttributeValueMapping."Item Attribute Value ID");
                TempItemAttributeValue.TransferFields(ItemAttributeValue);
                TempItemAttributeValue.Insert();

                Rec.InsertRecord(TempItemAttributeValue, ItemVariantAttributeValueMapping."Inherited-From Table ID", ItemVariantAttributeValueMapping."Inherited-From Key Value");
            until ItemVariantAttributeValueMapping.Next() = 0;
    end;

    local procedure DeleteItemVariantAttributeValueMapping(AttributeToDeleteID: Integer)
    var
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
        ItemAttribute: Record "Item Attribute";
    begin
        ItemVariantAttributeValueMapping.SetRange("Item No.", RelatedItemCode);
        ItemVariantAttributeValueMapping.SetRange("Variant Code", RelatedVariantCode);
        ItemVariantAttributeValueMapping.SetRange("Item Attribute ID", AttributeToDeleteID);
        if ItemVariantAttributeValueMapping.FindFirst() then
            ItemVariantAttributeValueMapping.Delete();

        ItemAttribute.Get(AttributeToDeleteID);
        ItemAttribute.RemoveUnusedArbitraryValues();
    end;

    local procedure InsertItemVariantAttributeValueMapping(ItemAttributeValue: Record "Item Attribute Value")
    var
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        if not ItemAttributeValue.Get(ItemAttributeValue."Attribute ID", ItemAttributeValue.ID) or
           ItemVariantAttributeValueMapping.Get(RelatedItemCode, RelatedVariantCode, ItemAttributeValue."Attribute ID") then
            exit;

        ItemVariantAttributeValueMapping.Reset();
        ItemVariantAttributeValueMapping.Init();
        ItemVariantAttributeValueMapping.Validate("Item No.", RelatedItemCode);
        ItemVariantAttributeValueMapping.Validate("Variant Code", RelatedVariantCode);
        ItemVariantAttributeValueMapping.Validate("Item Attribute ID", ItemAttributeValue."Attribute ID");
        ItemVariantAttributeValueMapping.Validate("Item Attribute Value ID", ItemAttributeValue.ID);
        ItemVariantAttributeValueMapping.Insert();
    end;
}