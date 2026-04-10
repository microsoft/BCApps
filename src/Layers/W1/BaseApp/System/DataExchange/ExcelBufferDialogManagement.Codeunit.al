namespace System.IO;

codeunit 5370 "Excel Buffer Dialog Management"
{

    trigger OnRun()
    begin
    end;

    var
        Window: Dialog;
        Progress: Integer;
        WindowOpen: Boolean;

    procedure Open(Text: Text)
    begin
        if not GuiAllowed then
            exit;

        Window.Open(Text + '@1@@@@@@@@@@@@@@@@@@@@@@@@@\');
        Window.Update(1, 0);
        WindowOpen := true;
    end;

    [TryFunction]
    procedure SetProgress(pProgress: Integer)
    begin
        Progress := pProgress;
        if WindowOpen then
            Window.Update(1, Progress);
    end;

    procedure Close()
    begin
        if WindowOpen then begin
            Window.Close();
            WindowOpen := false;
        end;
    end;
}

