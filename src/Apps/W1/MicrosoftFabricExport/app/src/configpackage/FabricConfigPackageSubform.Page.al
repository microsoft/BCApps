namespace Microsoft.FabricExport;

page 150007 "Fabric Config Package Subform"
{
    Caption = 'Fabric Config Package Lines';
    PageType = ListPart;
    SourceTable = "Fabric Config Package Line";
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the ID of the table included in this configuration package.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table.';
                }
                field("Per Company"; Rec."Per Company")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the table is exported per company.';
                }
                field("Fabric Schema Type"; Rec."Fabric Schema Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the table is exported as data or logging.';
                }
            }
        }
    }
}
