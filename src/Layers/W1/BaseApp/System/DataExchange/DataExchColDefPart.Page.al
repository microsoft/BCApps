namespace System.IO;

page 1216 "Data Exch Col Def Part"
{
    Caption = 'Column Definitions';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Data Exch. Column Def";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that reflects the column''s position on the line in the file.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the column.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies if the data to be exchanged is of type Text, Date, or Decimal.';

                    trigger OnValidate()
                    begin
                        DataFormatRequired := Rec.IsDataFormatRequired();
                        DataFormattingCultureRequired := Rec.IsDataFormattingCultureRequired();
                    end;
                }
                field("Data Format"; Rec."Data Format")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = DataFormatRequired;
                    ToolTip = 'Specifies the format of the data, if any. For example, MM-DD-YYYY if the data type is Date.';
                }
                field("Data Formatting Culture"; Rec."Data Formatting Culture")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = DataFormattingCultureRequired;
                    ToolTip = 'Specifies the culture of the data format, if any. For example, en-US if the data type is Decimal to ensure that comma is used as the .000 separator, according to the US format. This field is only relevant for import.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the fixed-width line that holds the column if the file is of type Fixed Text.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the column, for informational purposes.';
                }
                field(Path; Rec.Path)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the position of the element in the related XML schema.';
                }
                field("Negative-Sign Identifier"; Rec."Negative-Sign Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value that is used in the data file to identify negative amounts, in data files that cannot contain negative signs. This identifier is then used to reverse the identified amounts to negative signs during import.';
                }
                field(Constant; Rec.Constant)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any data that you want to export in this column, such as extra information about the payment type.';
                }
                field(Show; Rec.Show)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the element is shown in the data exchange definition.';
                    Visible = false;
                }
                field("Text Padding Required"; Rec."Text Padding Required")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the data must include text padding.';
                }
                field("Pad Character"; Rec."Pad Character")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that text padding.';
                }
                field(Justification; Rec.Justification)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the column justification is left or right.';
                }
                field("Use Node Name as Value"; Rec."Use Node Name as Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the node name should be used as value for file types Xml or Json during import.';
                    Visible = false;
                }
                field("Blank Zero"; Rec."Blank Zero")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the element is epmty if equal to 0.';
                }
                field("Export If Not Blank"; Rec."Export If Not Blank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the value of this column must be exported only if it is not blank.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GetFileStructure)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get File Structure';
                Ellipsis = true;
                ToolTip = 'Prefill the lines of the column definitions according to the structure of a data file on your computer or network.';

                trigger OnAction()
                begin
                    GetStructure();
                end;
            }
        }
    }

    var
        DataFormatRequired: Boolean;
        DataFormattingCultureRequired: Boolean;

    local procedure GetStructure()
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        GetFileStructure: Report "Get File Structure";
    begin
        DataExchLineDef.Get(Rec."Data Exch. Def Code", Rec."Data Exch. Line Def Code");
        GetFileStructure.Initialize(DataExchLineDef);
        GetFileStructure.RunModal();
    end;
}

