pageextension 6372 "Data Exch Field Mapping Part" extends "Data Exch Field Mapping Part"
{
    layout
    {
        addafter(Priority)
        {
            field("Default Value"; Rec."Default Value")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default value for the field mapping.';
            }
        }
    }
}
