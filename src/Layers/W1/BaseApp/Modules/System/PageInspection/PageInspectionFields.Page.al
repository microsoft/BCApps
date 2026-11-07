namespace System.Tooling;

page 9632 "Page Inspection Fields"
{
    Caption = 'Page Inspection Fields';
    PageType = ListPart;
    SourceTable = "Page Info And Fields";
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                Visible = HasSourceTable;
                field("Field Info"; Rec."Field Info")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field''s name, ID, data type, and if it is a primary key.';
                }
                field("Field Value"; Rec."Field Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the field for the record.';
                }
                field(EmptyText; EmptyText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies an empty field. This field is used for layout purposes.';
                }
                field(ExtensionSource; Rec.ExtensionSource)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the extension that adds the field.';
                }
                field(EmptyText2; EmptyText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies an empty field. This field is used for layout purposes.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field''s number.';
                }
                field(Tooltip; Rec.Tooltip)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field''s tooltip.';
                }

            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NavigateToSource)
            {
                AccessByPermission = System "Tools, Zoom" = X;
                ApplicationArea = All;
                Caption = 'Explore field in VS Code';
                Image = View;
                ToolTip = 'Navigate the field definition in source code in Visual Studio Code and attach debugger to current session.';
                Scope = Repeater;

                trigger OnAction()
                begin
                    PageInspectionVSCodeHelper.NavigateFieldDefinitionInVSCode(Rec, UpdateDependencies);
                    UpdateDependencies := false;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        // we need that to make Extension Source
        // move to the next line
        EmptyText := '';
    end;

    var
        PageInspectionVSCodeHelper: Codeunit "Page Inspection VS Code Helper";
        HasSourceTable: Boolean;
        EmptyText: Text;
        UpdateDependencies: Boolean;

    [Scope('OnPrem')]
    procedure UpdatePage(FormServerHandleId: Text; FormServerBookmark: Text)
    begin
        // that performs actual data retrieval
        Rec.Reset();
        Rec.SetFilter("Current Form ID", '%1', FormServerHandleId);
        Rec.SetFilter("Current Form Bookmark", '%1', FormServerBookmark);
        // sets current record to the first one
        // so we always are in the first data block when fields are loaded
        Rec.FindFirst();

        // this will actually update the content of the page
        CurrPage.Update(false);

        UpdateDependencies := true;
    end;

    [Scope('OnPrem')]
    procedure SetFieldListVisibility(IsFieldListVisible: Boolean)
    begin
        HasSourceTable := IsFieldListVisible;
    end;
}

