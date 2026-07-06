#pragma warning disable AA0247
page 26588 "XML Element Line List"
{
    Caption = 'XML Element Line List';
    Editable = false;
    PageType = List;
    SourceTable = "XML Element Line";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Element Name"; Rec."Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element name associated with the XML element line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML element line.';
                }
                field("Element Type"; Rec."Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type associated with the XML element line.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type associated with the XML element line.';
                }
                field("Link Type"; Rec."Link Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link type associated with the XML element line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';
                }
            }
        }
    }

    actions
    {
    }
}

