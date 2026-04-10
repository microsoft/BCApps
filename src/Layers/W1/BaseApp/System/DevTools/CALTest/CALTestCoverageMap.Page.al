namespace System.TestTools.TestRunner;

page 130408 "CAL Test Coverage Map"
{
    Caption = 'CAL Test Coverage Map';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CAL Test Coverage Map";
    SourceTableView = sorting("Object Type", "Object ID");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;
                }
                field("Hit by Test Codeunits"; Rec."Hit by Test Codeunits")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowTestCodeunits();
                    end;
                }
                field("Test Codeunit ID"; Rec."Test Codeunit ID")
                {
                    ApplicationArea = All;
                    Visible = TestCodeunitVisible;
                }
                field("Test Codeunit Name"; Rec."Test Codeunit Name")
                {
                    ApplicationArea = All;
                    Visible = TestCodeunitVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportExportTestMap)
            {
                ApplicationArea = All;
                Caption = 'Import/Export';
                Image = ImportExport;

                trigger OnAction()
                begin
                    XMLPORT.Run(XMLPORT::"CAL Test Coverage Map");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ImportExportTestMap_Promoted; ImportExportTestMap)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        TestCodeunitVisible := Rec.GetFilter("Test Codeunit ID") = '';
        ObjectVisible := (Rec.GetFilter("Object ID") = '') and (Rec.GetFilter("Object Type") = '');
    end;

    var
        ObjectVisible: Boolean;
        TestCodeunitVisible: Boolean;
}

