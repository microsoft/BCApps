namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.IO;

pageextension 6375 "Transformation Rule Card" extends "Transformation Rule Card"
{
    layout
    {
        modify("Transformation Type")
        {
            trigger OnAfterValidate()
            begin
                UpdateAdvancedLookupVisibility();
            end;
        }
        addlast(General)
        {
            group(AdvancedLookup)
            {
                Caption = 'Advanced Lookup Configuration';
                Visible = IsAdvancedLookupVisible;

                field("Lookup Table ID"; Rec."Lookup Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table to perform the lookup in.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Lookup Table Name"; Rec."Lookup Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the selected lookup table.';
                }
                field("Primary Field No."; Rec."Primary Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number to match against the input value (e.g., Document ID field).';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Primary Field Name"; Rec."Primary Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the primary field.';
                }
                field("Secondary Field No."; Rec."Secondary Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number for the secondary filter (e.g., Key field).';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Secondary Field Name"; Rec."Secondary Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the secondary field.';
                }
                field("Secondary Filter Value"; Rec."Secondary Filter Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the static value to filter on the secondary field (e.g., the Key value to match).';
                }
                field("Result Field No."; Rec."Result Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number to return as the result (e.g., Value field).';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Result Field Name"; Rec."Result Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the result field.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAdvancedLookupVisibility();
    end;

    var
        IsAdvancedLookupVisible: Boolean;

    local procedure UpdateAdvancedLookupVisibility()
    begin
        IsAdvancedLookupVisible := Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";
    end;
}
