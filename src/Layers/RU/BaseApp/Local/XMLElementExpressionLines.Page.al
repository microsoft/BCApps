#pragma warning disable AA0247
page 26585 "XML Element Expression Lines"
{
    AutoSplitKey = true;
    Caption = 'XML Element Expression Lines';
    PageType = Worksheet;
    SourceTable = "XML Element Expression Line";

    layout
    {
        area(content)
        {
            field(ExpressionValueControl; ExpressionValue)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expression Value';
                Editable = false;
            }
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Source; Rec.Source)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source associated with the XML element expression line.';

                    trigger OnValidate()
                    begin
                        SourceOnAfterValidate();
                    end;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the field name associated with the XML element expression line.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, Rec."Table ID");
                        if FieldSelection.Open(Field) then begin
                            Rec.Validate("Field ID", Field."No.");
                            CurrPage.Update();

                            ExpressionValue := Rec.UpdateRequisiteValue(false);
                        end;
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value associated with the XML element expression line.';
                }
                field("String Before"; Rec."String Before")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is before the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            Rec."String Before" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
                field("String After"; Rec."String After")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the string that is after the line on which the XML expression is based.';

                    trigger OnValidate()
                    begin
                        if SpaceEntered then begin
                            Rec."String After" := ' ';
                            SpaceEntered := false;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ExpressionValue := GetExpressionValue();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.UpdateReferences();
    end;

    trigger OnOpenPage()
    begin
        ExpressionValue := GetExpressionValue();
        OnActivateForm();
    end;

    var
        XMLElementLine: Record "XML Element Line";
        ExpressionValue: Text[250];
        SpaceEntered: Boolean;

    [Scope('OnPrem')]
    procedure GetExpressionValue(): Text[250]
    begin
        if XMLElementLine.Get(Rec."Report Code", Rec."Base XML Element Line No.") then
            exit(XMLElementLine.Value);

        exit('');
    end;

    local procedure SourceOnAfterValidate()
    begin
        Rec.CalcFields("Field Name");
    end;

    local procedure OnActivateForm()
    begin
        ExpressionValue := GetExpressionValue();
    end;
}

