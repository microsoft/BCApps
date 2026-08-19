#pragma warning disable AA0247
page 12485 "Depreciation Code List"
{
    Caption = 'Depreciation Code List';
    Editable = false;
    PageType = List;
    SourceTable = "Depreciation Code";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the unique identification code for this depreciation code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the depreciation code.';
                }
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the code for the depreciation group to apply to this code.';
                }
                field("Service Life"; Rec."Service Life")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the projected service life for this fixed asset for use in calculating depreciation.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        NameOnFormat();
    end;

    var
        NameEmphasize: Boolean;
        NameIndent: Integer;

    local procedure NameOnFormat()
    begin
        NameIndent := Rec.Indentation * 440;
        if Rec."Code Type" = Rec."Code Type"::Header then
            NameEmphasize := true;
    end;
}

