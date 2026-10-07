#pragma warning disable AA0247
page 17318 "Tax Calc. Dimension Filters"
{
    Caption = 'Tax Calc. Dimension Filters';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Calc. Dim. Filter";

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension code associated with the tax calculation dimension filter.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value that the data is filtered by.';
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;
                    Caption = 'Value Name';
                    ToolTip = 'Specifies the dimension name of the tax calculation dimension filter.';

                    trigger OnAssistEdit()
                    begin
                        DrillDownValueName();
                    end;
                }
                field("If No Value"; Rec."If No Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the tax calculation dimension filter will function if there is no value.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Editable := not CurrPage.LookupMode;
    end;

    var
        DimValue: Record "Dimension Value";

    [Scope('OnPrem')]
    procedure DrillDownValueName()
    begin
        if Rec."Dimension Value Filter" <> '' then begin
            DimValue.Reset();
            DimValue.FilterGroup(2);
            DimValue.SetRange("Dimension Code", Rec."Dimension Code");
            DimValue.FilterGroup(0);
            DimValue.SetFilter(Code, Rec."Dimension Value Filter");
            PAGE.RunModal(0, DimValue);
        end;
    end;
}

