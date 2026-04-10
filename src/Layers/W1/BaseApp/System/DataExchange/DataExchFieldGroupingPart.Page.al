namespace System.IO;

using System.Reflection;
using System.Text;

page 1222 "Data Exch Field Grouping Part"
{
    Caption = 'Data Exchange Field Grouping';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Data Exch. Field Grouping";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Field ID"; Rec."Field ID")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the field in the external file that is used for grouping.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        "Field": Record "Field";
                        TableFilter: Record "Table Filter";
                        FieldsLookup: Page "Fields Lookup";
                    begin
                        Field.SetRange(TableNo, Rec."Table ID");
                        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                        FieldsLookup.SetTableView(Field);
                        FieldsLookup.LookupMode(true);

                        if FieldsLookup.RunModal() = Action::LookupOK then begin
                            FieldsLookup.GetRecord(Field);
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
                    ToolTip = 'Specifies the caption of the field in the external file that is used for grouping.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FieldCaptionText := Rec.GetFieldCaption();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FieldCaptionText := '';
    end;

    var
        FieldCaptionText: Text;
}

