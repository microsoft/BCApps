#pragma warning disable AA0247
page 17215 "Tax Register Field Select"
{
    Caption = 'Tax Register Field Select';
    Editable = false;
    PageType = List;
    SourceTable = "Field";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the record.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(FieldName; Rec.FieldName)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        SelectionField: Record "Field";

    [Scope('OnPrem')]
    procedure GetSelectionField(var TempSelectionField: Record "Field" temporary)
    begin
        TempSelectionField.DeleteAll();
        if SelectionField.Find('-') then
            repeat
                TempSelectionField := SelectionField;
                TempSelectionField.Insert();
            until SelectionField.Next(1) = 0;
    end;

    local procedure LookupOKOnPush()
    begin
        CurrPage.SetSelectionFilter(SelectionField);
    end;
}

