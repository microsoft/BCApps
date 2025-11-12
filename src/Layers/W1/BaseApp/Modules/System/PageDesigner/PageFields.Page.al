namespace System.Tooling;

page 9620 "Page Fields"
{
    Caption = 'Add Field to Page';
    DeleteAllowed = false;
    Description = 'Place fields by dragging from the list to a position on the page.';
    Editable = true;
    InsertAllowed = false;
    InstructionalText = 'Place fields by dragging from the list to a position on the page.';
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Page Table Field";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = All;
                    Caption = 'Page ID';
                    ToolTip = 'Specifies the number of the page.';
                }
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = All;
                    Caption = 'Field ID';
                    ToolTip = 'Specifies the ID of the field.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    OptionCaption = 'TableFilter,RecordID,OemText,Date,Time,DateFormula,Decimal,Media,MediaSet,Text,Code,NotSupported_Binary,BLOB,Boolean,Integer,OemCode,Option,BigInteger,Duration,GUID,DateTime';
                    ToolTip = 'Specifies the type of the field.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    Caption = 'Length';
                    ToolTip = 'Specifies the length of the field.';
                }
                field(Caption; Rec.Caption)
                {
                    ApplicationArea = All;
                    Caption = 'Caption';
                    ToolTip = 'Specifies the caption of the field.';
                }
#pragma warning disable AL0432
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    OptionCaption = 'New,Ready,Placed';
                    Style = Favorable;
                    StyleExpr = FieldPlaced;
                    ToolTip = 'Specifies the field''s status, such as if the field is already placed on the page.';
                }
#pragma warning restore AL0432
                field(Tooltip; Rec.Tooltip)
                {
                    ApplicationArea = All;
                    Caption = 'Tooltip';
                    ToolTip = 'Specifies the field''s tooltip.';
                }
                field(Scope; Rec.Scope)
                {
                    ApplicationArea = All;
                    Caption = 'Scope';
                    ToolTip = 'Specifies the scope of the field.';
                }
                field(FieldKind; Rec.FieldKind)
                {
                    ApplicationArea = All;
                    Caption = 'FieldKind';
                    ToolTip = 'Specifies the kind of the field.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(View)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View';
                ShortCutKey = 'Return';
                ToolTip = 'View information for the selected field.';

                trigger OnAction()
                begin
                    // Comment to indicate to the server that this action must be run
                    // This action is here to override the default behavior of opening the card page with this record
                    // which is not desired in this case.
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(View_Promoted; View)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        DesignerPageId: Codeunit DesignerPageId;
    begin
#pragma warning disable AL0432
        FieldPlaced := Rec.Status = 1;
#pragma warning restore AL0432
        DesignerPageId.SetPageId(Rec."Page ID");
    end;

    var
        FieldPlaced: Boolean;
}
