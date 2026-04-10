#pragma warning disable AA0247
page 12488 "Depreciation Code"
{
    ApplicationArea = FixedAssets;
    Caption = 'Depreciation Code';
    PageType = List;
    SourceTable = "Depreciation Code";
    UsageCategory = Administration;

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
                field("Code Type"; Rec."Code Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'This object supports the Microsoft Dynamics NAV infrastructure and is intended only for internal use.';
                }
                field(Parent; Rec.Parent)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'This object supports the Microsoft Dynamics NAV infrastructure and is intended only for internal use.';
                }
                field(Indentation; Rec.Indentation)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the indentation of the line.';
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
                field("Depreciation Quota"; Rec."Depreciation Quota")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'This object supports the Microsoft Dynamics NAV infrastructure and is intended only for internal use.';
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

