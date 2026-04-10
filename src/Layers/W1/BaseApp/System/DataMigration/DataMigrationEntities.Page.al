namespace System.Integration;

page 1810 "Data Migration Entities"
{
    Caption = 'Data Migration Entities';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Data Migration Entity";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control8)
            {
                ShowCaption = false;
                group(Control9)
                {
                    ShowCaption = false;
                    field(Description; Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                    }
                }
            }
            repeater(Group)
            {
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the table will be migrated. If the check box is selected, then the table will be migrated.';
                    Visible = not HideSelected;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the table to be migrated.';
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of records in the table to be migrated.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total monetary value, in your local currency, of all entities in the table.';
                    Visible = ShowBalance;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ShowBalance := false;
        HideSelected := false;
        Description := 'Verify that the number of records are correct.';
    end;

    var
        ShowBalance: Boolean;
        HideSelected: Boolean;
        Description: Text;

    procedure CopyToSourceTable(var TempDataMigrationEntity: Record "Data Migration Entity" temporary)
    begin
        Rec.DeleteAll();

        if TempDataMigrationEntity.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(TempDataMigrationEntity);
                Rec.Insert();
            until TempDataMigrationEntity.Next() = 0;
    end;

    procedure CopyFromSourceTable(var TempDataMigrationEntity: Record "Data Migration Entity" temporary)
    begin
        TempDataMigrationEntity.Reset();
        TempDataMigrationEntity.DeleteAll();

        if Rec.FindSet() then
            repeat
                TempDataMigrationEntity.Init();
                TempDataMigrationEntity.TransferFields(Rec);
                TempDataMigrationEntity.Insert();
            until Rec.Next() = 0;
    end;

    procedure SetShowBalance(ShowBalances: Boolean)
    begin
        ShowBalance := ShowBalances;
    end;

    procedure SetPostingInfromation(PostJournals: Boolean; PostingDate: Date)
    var
        TempDataMigrationEntity: Record "Data Migration Entity" temporary;
    begin
        TempDataMigrationEntity.Copy(Rec, true);
        TempDataMigrationEntity.ModifyAll(Post, PostJournals);
        TempDataMigrationEntity.ModifyAll("Posting Date", PostingDate);
    end;

    procedure SetHideSelected(HideCheckBoxes: Boolean)
    begin
        HideSelected := HideCheckBoxes;
    end;
}

