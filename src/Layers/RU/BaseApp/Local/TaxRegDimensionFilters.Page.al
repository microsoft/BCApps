#pragma warning disable AA0247
page 17241 "Tax Reg Dimension Filters"
{
    Caption = 'Tax Reg Dimension Filters';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Tax Register Dim. Filter";

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
                    ToolTip = 'Specifies the dimension code associated with the tax register dimension filter.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value that the data is filtered by.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                        DimensionValueList: Page "Dimension Value List";
                    begin
                        DimensionValue.FilterGroup(2);
                        DimensionValue.SetRange("Dimension Code", Rec."Dimension Code");
                        DimensionValue.FilterGroup(0);
                        DimensionValueList.SetTableView(DimensionValue);
                        DimensionValueList.LookupMode(true);
                        if not (DimensionValueList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := DimensionValueList.GetSelectionFilter();
                        exit(true);
                    end;
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the dimension name associated with the tax register dimension filter.';
                }
                field("If No Value"; Rec."If No Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how you want to specify the tax register dimension filter if it has no value.';
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
}

