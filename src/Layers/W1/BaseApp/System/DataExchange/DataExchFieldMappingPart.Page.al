namespace System.IO;

using System.Reflection;
using System.Text;

page 1217 "Data Exch Field Mapping Part"
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
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the field in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        TableFilter: Record "Table Filter";
                        FieldSelection: Codeunit "Field Selection";
                    begin
                        Field.SetRange(TableNo, Rec."Table ID");
                        if FieldSelection.Open(Field) then begin
                            if Field."No." = Rec."Field ID" then
                                exit;
                            TableFilter.CheckDuplicateField(Field);
                            Rec.FillSourceRecord(Field);
                            FieldCaptionText := Rec.GetFieldCaption();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        FieldCaptionText := Rec.GetFieldCaption();
                    end;
                }
                field(FieldCaptionText; FieldCaptionText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field in the external file that is mapped to the field in the Target Table ID field, when you are using an intermediate table for data import.';
                }
                field(Optional; Rec.Optional)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the map will be skipped if the field is empty. If you do not select this check box, then an export error will occur if the field is empty. When the Use as Intermediate Table check box is selected, the Validate Only check box specifies that the element-to-field map is not used to convert data, but only to validate data.';
                }
                field(Multiplier; Rec.Multiplier)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the rule that transforms imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365. When you choose a value in this field, the same value is entered in the Transformation Rule field in the Data Exch. Field Mapping Buf. table and vice versa.';
                }
                field("Overwrite Value"; Rec."Overwrite Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the current value will be overwritten by a new value.';
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
        FieldCaptionText := Rec.GetFieldCaption();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ColumnCaptionText := '';
        FieldCaptionText := '';
    end;

    var
        ColumnCaptionText: Text;
        FieldCaptionText: Text;
}

