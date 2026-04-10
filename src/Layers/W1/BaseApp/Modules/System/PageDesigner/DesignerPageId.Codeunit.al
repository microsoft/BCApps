namespace System.Tooling;

codeunit 9621 DesignerPageId
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        DesignerPageId: Integer;

    procedure GetPageId(): Integer
    begin
        exit(DesignerPageId);
    end;

    procedure SetPageId(PageId: Integer): Boolean
    begin
        DesignerPageId := PageId;
        exit(true);
    end;
}

