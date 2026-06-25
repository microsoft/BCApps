namespace Microsoft.Sample.Loyalty;

codeunit 50102 "Loyalty Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        CreateDefaultMembers();
    end;

    local procedure CreateDefaultMembers()
    var
        Member: Record "Loyalty Member";
    begin
        Member.Init();
        Member."No." := 'DEFAULT';
        Member."Member Name" := 'Default House Account';
        Member."Loyalty Tier" := Member."Loyalty Tier"::Gold;
        if Member.Insert() then;
    end;
}
