#pragma warning disable AA0247
page 26593 "Stat. Rep. Table Map. Subform"
{
    Caption = 'Stat. Rep. Table Map. Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Stat. Report Table Row";

    layout
    {
    }

    actions
    {
    }

    var

    [Scope('OnPrem')]
    procedure UpdateForm(ReportCode: Code[20]; TableCode: Code[20])
    begin
    end;
}

