namespace System.IO;

page 8616 "Config. Package Errors"
{
    Caption = 'Config. Package Errors';
    DataCaptionExpression = Rec."Table Caption";
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Config. Package Error";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text of the error in the migration field. You can use information contained in the error text to fix migration problems before you attempt to apply migration data to the database.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the caption of the migration field to which the error applies.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the field in the migration table to which the error applies.';
                    Visible = false;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the migration table to which the error applies.';
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the caption of the migration table to which the error applies.';
                    Visible = false;
                }
                field(RecordIDValue; RecordIDValue)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Rec.FieldCaption("Record ID");
                    Editable = false;
                    ToolTip = 'Specifies the record in the migration table to which the error applies.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowRecord();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RecordIDValue := Format(Rec."Record ID");
    end;

    var
        RecordIDValue: Text;
}

