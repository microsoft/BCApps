page 130011 "Tainted Tables"
{
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Tainted Table";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater("<Group>")
            {
                Caption = '<Group>';
                field("<Table No.>"; "Table No.")
                {
                    ApplicationArea = All;
                    Caption = 'Table No.';
                    Style = Attention;
                    StyleExpr = Modified;
                }
                field("<Table Name>"; SourceTableName())
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    Style = Attention;
                    StyleExpr = Modified;
                }
                field("<Snapshot Row Count>"; RowCountBefore())
                {
                    ApplicationArea = All;
                    Caption = 'Snapshot Row Count';
                    Style = Attention;
                    StyleExpr = Modified;
                }
                field("<Current Row Count>"; RowCountNow())
                {
                    ApplicationArea = All;
                    Caption = 'Current Row Count';
                    Style = Attention;
                    StyleExpr = Modified;
                }
                field("<Implicit Taint>"; "Implicit Taint")
                {
                    ApplicationArea = All;
                    Caption = 'Implicit Taint';
                    Style = Attention;
                    StyleExpr = Modified;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Modified := RowCountBefore() <> RowCountNow();
    end;

    trigger OnOpenPage()
    begin
        RefreshPage();
    end;

    var
        SnapshotMgt: Codeunit "Snapshot Management";
        Modified: Boolean;

    [Scope('OnPrem')]
    procedure RefreshPage()
    begin
        Reset();
        DeleteAll();
        SnapshotMgt.ListTables(Rec);
    end;

    [Scope('OnPrem')]
    procedure SourceTableName(): Text[256]
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Table, "Table No.");
        exit(AllObj."Object Name");
    end;

    [Scope('OnPrem')]
    procedure RowCountBefore(): Integer
    begin
        exit(SnapshotMgt.BackupTableRowCount("Snapshot No.", "Table No."))
    end;

    [Scope('OnPrem')]
    procedure RowCountNow(): Integer
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open("Table No.");
        exit(RecordRef.Count)
    end;
}

