namespace System.IO;

using System.Environment.Configuration;

page 1800 "Configuration Package Files"
{
    Caption = 'Configuration Package Files';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Configuration Package File";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the Windows language to use for the configuration package.';
                }
                field("Setup Type"; Rec."Setup Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the configuration package file sets up a company on a per company basis, for the entire application, or for some other purpose.';
                }
                field("Processing Order"; Rec."Processing Order")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order in which the package is to be processed.';
                }
            }
        }
    }

    actions
    {
    }
}

