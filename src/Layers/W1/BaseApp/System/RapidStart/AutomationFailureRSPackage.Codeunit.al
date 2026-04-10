namespace System.IO;

codeunit 5434 "Automation - Failure RSPackage"
{
    TableNo = "Config. Package";

    trigger OnRun()
    begin
        if Rec."Import Status" in [Rec."Import Status"::InProgress, Rec."Import Status"::Scheduled] then begin
            Rec."Import Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Rec."Import Error"));
            Rec.Validate("Import Status", Rec."Import Status"::Error);
        end else
            if Rec."Apply Status" in [Rec."Apply Status"::InProgress, Rec."Apply Status"::Scheduled] then begin
                Rec."Apply Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Rec."Apply Error"));
                if Rec."Apply Error" = '' then
                    Rec."Apply Error" := ApplyErrorLbl;
                Rec.Validate("Apply Status", Rec."Apply Status"::Error);
            end;
        Rec.Modify(true);
        Commit();
    end;

    var
        ApplyErrorLbl: Label 'Applying configuration package failed.';
}

