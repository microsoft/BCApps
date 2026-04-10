namespace System.Reflection;

page 9622 "Table Field Types ListPart"
{
    Caption = 'Table Field Types ListPart';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Table Field Types";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies Name displayed to users.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FieldType := Format(Rec.FieldTypeGroup);
    end;

    var
        FieldType: Text;

    procedure GetSelectedRecord(var TableFieldTypes: Record "Table Field Types")
    begin
        CurrPage.SetSelectionFilter(TableFieldTypes);
    end;

    procedure GetSelectedRecType(): Text
    begin
        exit(FieldType);
    end;
}

