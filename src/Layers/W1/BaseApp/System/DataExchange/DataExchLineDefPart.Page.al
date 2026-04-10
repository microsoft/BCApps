namespace System.IO;

page 1215 "Data Exch Line Def Part"
{
    Caption = 'Line Definitions';
    PageType = ListPart;
    SourceTable = "Data Exch. Line Def";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Group';
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line Type';
                    ToolTip = 'Specifies the type of the line in the file.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line in the file.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the mapping setup.';
                }
                field("Column Count"; Rec."Column Count")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many columns the line in the bank statement file has.';
                }
                field("Data Line Tag"; Rec."Data Line Tag")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the position in the related XML schema of the element that represents the main entry of the data file.';
                }
                field(Namespace; Rec.Namespace)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsXMLFileType;
                    ToolTip = 'Specifies the namespace (uniform resource name (urn)) for a target document that is expected in the file for validation. You can leave the field blank if you do not want to enable namespace validation.';
                }
                field("Parent Code"; Rec."Parent Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the parent of the child that is specified in the Code field in cases where the data exchange setup is for files with parent and children entries, such as a document header and lines.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Field Mapping")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Field Mapping';
                Image = MapAccounts;
                RunObject = Page "Data Exch Mapping Card";
                RunPageLink = "Data Exch. Def Code" = field("Data Exch. Def Code"),
                              "Data Exch. Line Def Code" = field(Code);
                RunPageMode = Edit;
                ShortCutKey = 'Return';
                ToolTip = 'Associates columns in the data file with fields in Dynamics 365.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get(Rec."Data Exch. Def Code");
        IsXMLFileType := not DataExchDef.CheckEnableDisableIsNonXMLFileType();
    end;

    var
        IsXMLFileType: Boolean;
}

