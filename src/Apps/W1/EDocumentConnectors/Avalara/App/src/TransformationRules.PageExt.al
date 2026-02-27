namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.IO;
pageextension 6376 "Transformation Rules" extends "Transformation Rules"
{
    layout
    {
        addafter("Find Value")
        {
            field("Lookup Table ID"; Rec."Lookup Table ID")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the table to perform the lookup in.';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";

                trigger OnValidate()
                begin
                    CurrPage.Update(true);
                end;
            }

            field("Lookup Table Name"; Rec."Lookup Table Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the name of the selected lookup table.';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";
            }

            field("Primary Field No."; Rec."Primary Field No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the field number to match against the input value (e.g., Document ID field).';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";

                trigger OnValidate()
                begin
                    CurrPage.Update(true);
                end;
            }

            field("Primary Field Name"; Rec."Primary Field Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the name of the primary field.';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";
            }

            field("Secondary Field No."; Rec."Secondary Field No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the field number for the secondary filter (e.g., Key field).';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";

                trigger OnValidate()
                begin
                    CurrPage.Update(true);
                end;
            }

            field("Secondary Field Name"; Rec."Secondary Field Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the name of the secondary field.';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";
            }

            field("Secondary Filter Value"; Rec."Secondary Filter Value")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the static value to filter on the secondary field (e.g., the Key value to match).';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";
            }

            field("Result Field No."; Rec."Result Field No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the field number to return as the result (e.g., Value field).';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";

                trigger OnValidate()
                begin
                    CurrPage.Update(true);
                end;
            }

            field("Result Field Name"; Rec."Result Field Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the name of the result field.';
                Visible = Rec."Transformation Type" = Rec."Transformation Type"::"Avalara Lookup";
            }
        }
    }
}
