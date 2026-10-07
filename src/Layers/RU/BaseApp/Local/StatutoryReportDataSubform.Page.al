#pragma warning disable AA0247
page 26564 "Statutory Report Data Subform"
{
    Caption = 'Statutory Report Data Subform';
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
    procedure UpdateForm(NewResultCode: Code[20]; NewTableName: Code[20]; NewExcelSheetName: Text[30]; NewShowOnlyChangedValues: Boolean)
    begin
    end;
}

