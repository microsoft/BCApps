namespace System.IO;

page 8619 "Config. Template Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Config. Template Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of data in the data template.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field in the data template.';

                    trigger OnAssistEdit()
                    begin
                        Rec.SelectFieldName();
                    end;
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field on which the data template is based. The caption comes from the Caption property of the field.';
                }
                field("Template Code"; Rec."Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the data template.';
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default value with reference to the data template line.';
                }
                field("Skip Relation Check"; Rec."Skip Relation Check")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the relationship between the table fields should not be checked. This can useful when you want to specify a value for a field that is not yet available. For example, you may want to specify a value for a payment term that is not available in the table on which you are basing you configuration. You can specify that value, select the Skip Relation Check box, and then continue to apply data without error.';
                }
                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether it is required that there be data in the field in the data template. By default, the check box is selected to make a value mandatory. You can clear the check box.';
                }
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a url address. Use this field to provide a url address to a location that specifies additional information about the field in the data template. For example, you could provide the address that specifies information on setup considerations that the solution implementer should consider.';
                }
            }
        }
    }

    actions
    {
    }
}

