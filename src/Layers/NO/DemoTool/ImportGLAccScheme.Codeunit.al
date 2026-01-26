codeunit 160805 "Import GLAcc. Scheme"
{

    trigger OnRun()
    begin
        //lang := GLOBALLANGUAGE();
        kontoskjema.DeleteAll();
        analyse.DeleteAll();
        dds.Get();

        lesfil2();
        lesfil3();
    end;

    var
        dds: Record "Demo Data Setup";
        int: Integer;
        kontoskjema: Record "Acc. Schedules Conversion";
        analyse: Record "Analysis Conversion";

    procedure lesfil2()
    var
        f: File;
        strin: InStream;
        txt: Text[1024];
    begin
        f.TextMode(true);
        f.WriteMode(false);
        f.Open('localfiles\accschedules.txt');

        f.CreateInStream(strin);
        //Starting a loop
        while not (strin.EOS()) do begin
            int := strin.ReadText(txt);
            convert2(txt);
        end;
        f.Close();
    end;

    procedure lesfil3()
    var
        f: File;
        strin: InStream;
        txt: Text[1024];
    begin
        f.TextMode(true);
        f.WriteMode(false);
        f.Open('localfiles\analysis.txt');

        f.CreateInStream(strin);
        //Starting a loop
        while not (strin.EOS()) do begin
            int := strin.ReadText(txt);
            convert3(txt);
        end;
        f.Close();
    end;

    procedure convert2(txt: Text[1024])
    begin
        kontoskjema.Reset();
        kontoskjema.Init();
        kontoskjema."Schedule Name" := CopyStr(txt, 1, 10);
        Evaluate(kontoskjema."Line No.", CopyStr(txt, 12, 7));
        Evaluate(kontoskjema."Totaling (New)", CopyStr(txt, 101, 80));
        kontoskjema.Insert();
    end;

    procedure convert3(txt: Text[1024])
    begin
        analyse.Reset();
        analyse.Init();
        analyse."Analysis Code" := CopyStr(txt, 1, 10);
        Evaluate(analyse."GL Acc Filter (New)", CopyStr(txt, 20, 250));
        analyse.Insert();
    end;
}

