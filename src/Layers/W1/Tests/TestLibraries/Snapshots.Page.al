page 130013 Snapshots
{
    InsertAllowed = false;
    PageType = List;
    SourceTable = Snapshot;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater("<Group>")
            {
                Caption = '<Group>';
                field("Snapshot No."; "Snapshot No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Snapshot Name"; "Snapshot Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        SnapshotMgt.SetDescription("Snapshot No.", Description);
                    end;
                }
                field(Incremental; Incremental)
                {
                    ApplicationArea = All;
                }
                field("Incremental Index"; "Incremental Index")
                {
                    ApplicationArea = All;
                }
            }
            part("Tainted Tables"; "Tainted Tables")
            {
                ApplicationArea = All;
                Caption = 'Tainted Tables';
                Editable = false;
                SubPageLink = "Snapshot No." = FIELD("Snapshot No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("<Enable Snapshots>")
            {
                ApplicationArea = All;
                Caption = 'Enable Snapshots';
                Enabled = not SnapshotEnabled;
                Promoted = true;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SnapshotMgt.SetEnabled(true);
                    UpdateDisabledFlag();
                end;
            }
            action("<Refresh List>")
            {
                ApplicationArea = All;
                Caption = 'Refresh List';
                Enabled = SnapshotEnabled;
                Image = Refresh;
                Promoted = true;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    RefreshPage();
                end;
            }
            action("<Take Snapshot>")
            {
                ApplicationArea = All;
                Caption = 'Take Snapshot';
                Enabled = SnapshotEnabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SnapshotMgt.InitSnapshot('SNAPSHOT' + Format(SnapshotMgt.GetAvailableSnapshotNo()), true);
                    RefreshPage();
                end;
            }
            action("<Restore Snapshot>")
            {
                ApplicationArea = All;
                Caption = 'Restore Snapshot';
                Enabled = SnapshotEnabled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    SnapshotMgt.RestoreSnapshot("Snapshot No.");
                    RefreshPage();
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        SnapshotMgt.DeleteSnapshot("Snapshot No.");
        RefreshPage();
        exit(true);
    end;

    trigger OnInit()
    begin
        UpdateDisabledFlag();
    end;

    trigger OnOpenPage()
    begin
        UpdateDisabledFlag();
        RefreshPage();
    end;

    var
        SnapshotMgt: Codeunit "Snapshot Management";
        SnapshotEnabled: Boolean;

    [Scope('OnPrem')]
    procedure RefreshPage()
    begin
        DeleteAll();
        SnapshotMgt.ListSnapshots(Rec);
        if FindFirst() then;
        CurrPage."Tainted Tables".PAGE.RefreshPage();
    end;

    [Scope('OnPrem')]
    procedure UpdateDisabledFlag()
    begin
        SnapshotEnabled := SnapshotMgt.GetEnabledFlag();
    end;
}

