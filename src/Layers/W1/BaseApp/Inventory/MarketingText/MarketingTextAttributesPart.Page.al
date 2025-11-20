// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

page 5838 "Marketing Text Attributes Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Marketing Text Attributes";
    SourceTableTemporary = true;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field(Property; Rec.Property)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the name of the attribute.';
                    Editable = false;
                    Enabled = false;
                }

                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the attribute.';
                    Editable = false;
                    Enabled = false;
                }

                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include';
                    Width = 5;
                    ToolTip = 'Specifies if the attribute should be used to generate the marketing text.';
                    Editable = true;
                    Enabled = true;

                    trigger OnValidate()
                    var
                        TempMarketingTextAttributes: Record "Marketing Text Attributes" temporary;
                    begin
                        TempMarketingTextAttributes.Copy(Rec, true);
                        TempMarketingTextAttributes.SetRange(Selected, true);

                        if not Rec.Selected then begin
                            if Rec.Property = ItemCategoryTxt then begin
                                Rec.Selected := true;
                                Message(ItemCategoryRequiredTxt);
                                exit;
                            end;
                            if (TempMarketingTextAttributes.Count() - 1) < 1 then begin // taking into account deselecting this attribute
                                Rec.Selected := true;
                                Message(MinSelectionsRequiredTxt);
                                exit;
                            end;
                        end;

                        if TempMarketingTextAttributes.Count() > (MaxSelections - 1) then begin // excludes this current selection
                            Rec.Selected := false;
                            Message(MaxSelectionExceededTxt, MaxSelections);
                            exit;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnInit()
    var
        MarketingText: Codeunit "Marketing Text";
    begin
        MaxSelections := MarketingText.GetMaximumFacts();
    end;

    procedure AddAttribute(AttributeName: Text; AttributeValue: Text; MarkAsSelected: Boolean)
    begin
        Rec.Init();
        Rec.Property := CopyStr(AttributeName, 1, MaxStrLen(Rec.Property));
        Rec.Value := CopyStr(AttributeValue, 1, MaxStrLen(Rec.Value));
        Rec.Selected := MarkAsSelected;
        Rec.Insert();
    end;

    procedure SetSelectedAttributes(AttributeKeys: List of [Text])
    begin
        if Rec.FindSet() then begin
            repeat
                if AttributeKeys.Contains(Rec.Property) then
                    Rec.Selected := true
                else
                    Rec.Selected := false;
                Rec.Modify();
            until (Rec.Next() = 0);
            CurrPage.Update(false);
        end;
    end;


    procedure GetSelectedAttributes(): Dictionary of [Text, Text]
    var
        TempMarketingTextAttributes: Record "Marketing Text Attributes" temporary;
        SelectedAttributes: Dictionary of [Text, Text];
        FactCount: Integer;
    begin
        TempMarketingTextAttributes.Copy(Rec, true);
        TempMarketingTextAttributes.SetRange(Selected, true);
        if TempMarketingTextAttributes.FindSet() then
            repeat
                SelectedAttributes.Add(TempMarketingTextAttributes.Property, TempMarketingTextAttributes.Value);
                FactCount += 1;
            until (TempMarketingTextAttributes.Next() = 0) or (FactCount > MaxSelections);
        exit(SelectedAttributes);
    end;

    var
        MaxSelectionExceededTxt: Label 'You can only select up to %1 attributes', Comment = '%1 is the number of maximum attributes';
        MinSelectionsRequiredTxt: Label 'At least one attribute has to be selected.';
        ItemCategoryRequiredTxt: Label 'Sorry, you can''t exclude the item category from the attribute set.';
        MaxSelections: Integer;
        ItemCategoryTxt: Label 'Item Category', Locked = true;
}
