namespace System.IO;

page 1218 "Generic Data Exch Fld Mapping"
{
    Caption = 'Data Exchange Field Mapping';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Data Exch. Field Mapping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the column in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';

                    trigger OnValidate()
                    begin
                        ColumnCaptionText := Rec.GetColumnCaption();
                    end;
                }
                field(ColumnCaptionText; ColumnCaptionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Caption';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the column in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';
                }
                field("Target Table ID"; Rec."Target Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table that the value in the Column Caption field is mapped to, when you are using an intermediate table for data import.';
                }
                field("Target Table Caption"; Rec."Target Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Caption';
                    Editable = false;
                    ToolTip = 'Specifies the name of the table in the Target Table ID field, which is the table that the value in the Column Caption field is mapped to, when you are using an intermediate table for data import.';
                }
                field("Target Field ID"; Rec."Target Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field in the target table that the value in the Column Caption field is mapped to, when you are using an intermediate table for data import.';
                }
                field("Target Field Caption"; Rec."Target Table Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field in the target table that the value in the Column Caption field is mapped to, when you are using an intermediate table for data import.';
                }
                field(ValidateOnly; Rec.Optional)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate Only';
                    ToolTip = 'Specifies that the map will be skipped if the field is empty. If you do not select this check box, then an export error will occur if the field is empty. When the Use as Intermediate Table check box is selected, the Validate Only check box specifies that the element-to-field map is not used to convert data, but only to validate data.';
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rule that transforms imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365. When you choose a value in this field, the same value is entered in the Transformation Rule field in the Data Exch. Field Mapping Buf. table and vice versa.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order that the field mappings must be processed. The field mapping with the highest number will be processed first.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ColumnCaptionText := Rec.GetColumnCaption();
    end;

    trigger OnInit()
    begin
        Rec.SetAutoCalcFields("Target Table Caption", "Target Table Field Caption")
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ColumnCaptionText := '';
    end;

    var
        ColumnCaptionText: Text;
}

