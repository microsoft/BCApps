namespace System.IO;

#pragma warning disable AS0032
page 9075 "RapidStart Services Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "RapidStart Services Cue";

    layout
    {
        area(content)
        {
            cuegroup(Tables)
            {
                Caption = 'Tables';
                field(PromotedField; Rec.Promoted)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Promoted';
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that have been promoted. The documents are filtered by today''s date.';
                }
                field("Not Started"; Rec."Not Started")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that have not been started. The documents are filtered by today''s date.';
                }
                field("In Progress"; Rec."In Progress")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that are in progress. The documents are filtered by today''s date.';
                }
                field(Completed; Rec.Completed)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that have been completed. The documents are filtered by today''s date.';
                }
                field(Ignored; Rec.Ignored)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that you have designated to be ignored. The documents are filtered by today''s date.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRange("User ID Filter", UserId());
    end;
}
#pragma warning restore AS0032

