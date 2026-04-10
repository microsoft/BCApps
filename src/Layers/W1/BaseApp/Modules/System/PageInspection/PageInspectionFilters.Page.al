namespace System.Tooling;

page 9634 "Page Inspection Filters"
{
    Caption = 'Page Inspection Filters';
    PageType = ListPart;
    SourceTable = "Page Info And Fields";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                Visible = HasSourceTable;
                field("Field Info"; Rec."Field Info")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the filter field''s name, ID, data type, and if it is a primary key.';
                }
                field("Field Filter Expression"; Rec."Field Filter Expression")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the filter expression.';
                }
                field("Field Filter Type"; Rec."Field Filter Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the filter''s type, which indicates where it is defined. A UserFilters type is defined in code or by the user; TableViewFilter type is defined by the page''s SourceTableView property; SubFormLinkFilters type is defined by the SubPageLink property; FormViewFilters type is defined by the RunPageView property.';
                }
            }
        }
    }

    actions
    {
    }

    var
        HasSourceTable: Boolean;

    [Scope('OnPrem')]
    procedure UpdatePage(FormServerHandleId: Text; FormServerBookmark: Text)
    begin
        // that performs actual data retrival
        Rec.Reset();
        Rec.SetFilter("Current Form ID", '%1', FormServerHandleId);
        Rec.SetFilter("Current Form Bookmark", '%1', FormServerBookmark);
        Rec.SetFilter("Field Filter Expression", '<>%1', '');

        // this will actually update the content of the page
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetFilterListVisibility(IsFieldListVisible: Boolean)
    begin
        HasSourceTable := IsFieldListVisible;
    end;
}

