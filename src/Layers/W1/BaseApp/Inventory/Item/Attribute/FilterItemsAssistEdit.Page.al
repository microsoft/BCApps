// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7507 "Filter Items - AssistEdit"
{
    Caption = 'Specify Filter Value';
    PageType = StandardDialog;
    SourceTable = "Item Attribute";

    layout
    {
        area(content)
        {
            group(Control14)
            {
                ShowCaption = false;
                group(Control2)
                {
                    ShowCaption = false;
                    Visible = TextGroupVisible;
                    field(TextConditions; TextConditions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Condition';
                        OptionCaption = 'Contains,Starts With,Ends With,Exact Match';
                        ToolTip = 'Specifies the condition for the filter value. Example: To specify that the value for a Material Description attribute must start with blue, fill the fields as follows: Condition field = Starts With. Value field = blue.';
                    }
                    field(TextValue; TextValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value';
                        ToolTip = 'Specifies the filter value that the condition applies to.';
                    }
                }
                group(Control9)
                {
                    ShowCaption = false;
                    Visible = NumericGroupVisible;
                    field(NumericConditions; NumericConditions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Condition';
                        OptionCaption = '=  - Equals,..  - Range,<  - Less,<= - Less or Equal,>  - Greater,>= - Greater or Equal';
                        ToolTip = 'Specifies the condition for the filter value. Example: To specify that the value for a Quantity attribute must be higher than 10, fill the fields as follows: Condition field > Greater. Value field = 10.';

                        trigger OnValidate()
                        begin
                            UpdateGroupVisiblity();
                        end;
                    }
                    field(NumericValue; NumericValue)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value';
                        ToolTip = 'Specifies the filter value that the condition applies to.';

                        trigger OnValidate()
                        begin
                            ValidateValueIsNumeric(NumericValue);
                        end;
                    }
                    group(Control12)
                    {
                        ShowCaption = false;
                        Visible = NumericGroupMaxValueVisible;
                        field(MaxNumericValue; MaxNumericValue)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'To Value';
                            ToolTip = 'Specifies the end value in the range.';

                            trigger OnValidate()
                            begin
                                ValidateValueIsNumeric(MaxNumericValue);
                            end;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateGroupVisiblity();
    end;

    var
        TextValue: Text[240];
        TextConditions: Option Contains,"Starts With","Ends With","Exact Match";
        NumericConditions: Option "=  - Equals","..  - Range","<  - Less","<= - Less or Equal",">  - Greater",">= - Greater or Equal";
        NumericValue: Text;
        MaxNumericValue: Text;
        NumericGroupVisible: Boolean;
        NumericGroupMaxValueVisible: Boolean;
        TextGroupVisible: Boolean;

    local procedure UpdateGroupVisiblity()
    begin
        TextGroupVisible := Rec.Type = Rec.Type::Text;
        NumericGroupVisible := Rec.Type in [Rec.Type::Decimal, Rec.Type::Integer];
        NumericGroupMaxValueVisible := NumericGroupVisible and (NumericConditions = NumericConditions::"..  - Range");

        OnAfterUpdateGroupVisiblity(Rec, TextGroupVisible, NumericGroupMaxValueVisible, NumericGroupVisible, NumericConditions);
    end;

    local procedure ValidateValueIsNumeric(TextValue: Text)
    var
        ValidDecimal: Decimal;
        ValidInteger: Integer;
    begin
        if Rec.Type = Rec.Type::Decimal then
            Evaluate(ValidDecimal, TextValue);

        if Rec.Type = Rec.Type::Integer then
            Evaluate(ValidInteger, TextValue);

        OnAfterValidateValueIsNumeric(Rec, TextValue);
    end;

    procedure LookupOptionValue(PreviousValue: Text): Text
    var
        ItemAttributeValue: Record "Item Attribute Value";
        SelectedItemAttributeValue: Record "Item Attribute Value";
        SelectItemAttributeValue: Page "Select Item Attribute Value";
        OptionFilter: Text;
    begin
        ItemAttributeValue.SetRange("Attribute ID", Rec.ID);
        SelectItemAttributeValue.SetTableView(ItemAttributeValue);
        // SelectItemAttributeValue.LOOKUPMODE(TRUE);
        SelectItemAttributeValue.Editable(false);

        if not (SelectItemAttributeValue.RunModal() in [ACTION::OK, ACTION::LookupOK]) then
            exit(PreviousValue);

        OptionFilter := '';
        SelectItemAttributeValue.GetSelectedValue(SelectedItemAttributeValue);
        if SelectedItemAttributeValue.FindSet() then begin
            repeat
                if SelectedItemAttributeValue.Value <> '' then
                    OptionFilter := StrSubstNo('%1|%2', SelectedItemAttributeValue.Value, OptionFilter);
            until SelectedItemAttributeValue.Next() = 0;
            OptionFilter := CopyStr(OptionFilter, 1, StrLen(OptionFilter) - 1);
        end;

        exit(OptionFilter);
    end;

    procedure GenerateFilter() FilterText: Text
    begin
        case Rec.Type of
            Rec.Type::Decimal, Rec.Type::Integer:
                begin
                    if NumericValue = '' then
                        exit('');

                    if NumericConditions = NumericConditions::"..  - Range" then
                        FilterText := StrSubstNo('%1..%2', NumericValue, MaxNumericValue)
                    else
                        FilterText := StrSubstNo('%1%2', DelChr(CopyStr(Format(NumericConditions), 1, 2), '=', ' '), NumericValue);
                end;
            Rec.Type::Text:
                begin
                    if TextValue = '' then
                        exit('');

                    case TextConditions of
                        TextConditions::"Starts With":
                            FilterText := StrSubstNo('@%1*', TextValue);
                        TextConditions::"Ends With":
                            FilterText := StrSubstNo('@*%1', TextValue);
                        TextConditions::Contains:
                            FilterText := StrSubstNo('@*%1*', TextValue);
                        TextConditions::"Exact Match":
                            FilterText := StrSubstNo('''%1''', TextValue);
                    end;
                end;
        end;

        OnAfterGenerateFilter(Rec, NumericValue, NumericConditions, MaxNumericValue, FilterText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateFilter(ItemAttribute: Record "Item Attribute"; NumericValue: Text; NumericConditions: Option "=  - Equals","..  - Range","<  - Less","<= - Less or Equal",">  - Greater",">= - Greater or Equal"; MaxNumericValue: Text; var FilterText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateValueIsNumeric(ItemAttribute: Record "Item Attribute"; TextValue: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateGroupVisiblity(ItemAttribute: Record "Item Attribute"; var TextGroupVisible: Boolean; var NumericGroupMaxValueVisible: Boolean; var NumericGroupVisible: Boolean; NumericConditions: Option "=  - Equals","..  - Range","<  - Less","<= - Less or Equal",">  - Greater",">= - Greater or Equal")
    begin
    end;
}

