namespace System.IO;

page 8627 "Config. Package Data"
{
    Caption = 'Config. Package Data';
    PageType = List;
    SourceTable = "Config. Package Data";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Package Code"; Rec."Package Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the package that contains the data that is being created.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value that has been entered for the field in the configuration package record. As needed, you can update and modify the information in this field, which you can use for comments. You can also correct the errors that are preventing the record from being part of the configuration. This is indicated when the Invalid check box is selected.';
                }
            }
        }
    }

    actions
    {
    }
}

