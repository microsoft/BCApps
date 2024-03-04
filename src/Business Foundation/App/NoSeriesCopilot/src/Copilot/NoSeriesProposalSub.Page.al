page 325 "No. Series Proposal Sub"
{

    Caption = 'No. Series Proposals';
    PageType = ListPart;
    SourceTable = "No. Series Proposal Entry Line";
    SourceTableTemporary = true;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Series Code"; Rec."Series Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Starting No."; Rec."Starting No.")
                {
                    ApplicationArea = All;
                }
                field("Increment-by No."; Rec."Increment-by No.")
                {
                    ApplicationArea = All;
                }
                field("Ending No."; Rec."Ending No.")
                {
                    ApplicationArea = All;
                }
                field("Warning No."; Rec."Warning No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    internal procedure Load(var NoSeriesGenerated: Record "No. Series Proposal Entry Line")
    begin
        NoSeriesGenerated.Reset();
        if NoSeriesGenerated.FindSet() then
            repeat
                Rec := NoSeriesGenerated;
                Rec.Insert();
            until NoSeriesGenerated.Next() = 0;
    end;

    internal procedure GetTempRecord(EntryNo: Integer; var NoSeriesGenerated: Record "No. Series Proposal Entry Line")
    begin
        NoSeriesGenerated.DeleteAll();
        Rec.Reset();
        Rec.SetRange("Entry No.", EntryNo);
        if Rec.FindSet() then
            repeat
                NoSeriesGenerated.Copy(Rec, false);
                NoSeriesGenerated.Insert();
            until Rec.Next() = 0;
    end;
}
