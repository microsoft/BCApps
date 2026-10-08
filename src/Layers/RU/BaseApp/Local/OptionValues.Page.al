#pragma warning disable AA0247
page 17245 "Option Values"
{
    Caption = 'Option Values';
    DataCaptionExpression = FormTitle;
    Editable = false;
    PageType = List;
    SourceTable = "Lookup Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Integer"; Rec.Integer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID';
                    ToolTip = 'Specifies the ID.';
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'This field is used internally.';
                }
            }
        }
    }

    actions
    {
    }

    var
        LookupMgt: Codeunit "Lookup Management";
        FormTitle: Text[1024];

    [Scope('OnPrem')]
    procedure CreateLookupBuffer(TableID: Integer; FieldID: Integer)
    begin
        LookupMgt.BuildLookupBuffer(Rec, TableID, FieldID);
    end;

    [Scope('OnPrem')]
    procedure SetFormTitle(NewFormTitle: Text[1024])
    begin
        FormTitle := NewFormTitle;
    end;

    [Scope('OnPrem')]
    procedure CreateKeyList(TableID: Integer)
    begin
        LookupMgt.BuildKeyList(Rec, TableID);
    end;
}

