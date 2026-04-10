namespace System.IO;

page 1266 "Select Source"
{
    Caption = 'Select Source';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    SourceTable = "XML Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Depth;
                IndentationControls = Name;
                ShowAsTree = true;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Element';
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the name of the imported record.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Example Value';
                    ToolTip = 'Specifies the value of the imported record.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        StyleText: Text;

    local procedure SetStyle()
    begin
        if Rec.HasChildNodes() then
            StyleText := 'Strong'
        else
            StyleText := '';
    end;
}

