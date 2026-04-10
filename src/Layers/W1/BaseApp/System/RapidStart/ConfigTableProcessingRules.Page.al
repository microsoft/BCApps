namespace System.IO;

page 8640 "Config. Table Processing Rules"
{
    AutoSplitKey = true;
    Caption = 'Config. Table Processing Rules';
    DataCaptionFields = "Table ID", "Package Code";
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    ShowFilter = false;
    SourceTable = "Config. Table Processing Rule";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Action"; Rec.Action)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an action that is related to the custom processing rule.';

                    trigger OnValidate()
                    begin
                        CustomCodeunitIdEditable := Rec.Action = Rec.Action::Custom;
                    end;
                }
                field(FilterInfo; Rec.GetFilterInfo())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Filter';
                    Editable = false;
                    ToolTip = 'Specifies any filters that are set.';
                }
                field("Custom Processing Codeunit ID"; Rec."Custom Processing Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = CustomCodeunitIdEditable;
                    ToolTip = 'Specifies the custom processing codeunit.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Filter")
            {
                Caption = 'Filter';
                action(ProcessingFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processing Filters';
                    Image = "Filter";
                    ToolTip = 'View or edit the filters that are used to process data.';

                    trigger OnAction()
                    begin
                        Rec.ShowFilters();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ProcessingFilters_Promoted; ProcessingFilters)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CustomCodeunitIdEditable := Rec.Action = Rec.Action::Custom;
    end;

    var
        CustomCodeunitIdEditable: Boolean;
}

