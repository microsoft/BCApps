codeunit 132803 "Upgrade Status"
{
    procedure SetUpgradeStatusTriggered()
    var
        UpgradeStatus: Record "Upgrade Status";
    begin
        if not UpgradeStatus.Get() then begin
            UpgradeStatus.UpgradeTriggered := true;
            UpgradeStatus.Insert();
        end;
    end;

    procedure RunUpgradePerDatabaseTriggers(): Boolean
    var
        Company: Record Company;
    begin
        Company.FindFirst();
        exit(UpperCase(CompanyName) = UpperCase(Company.Name));
    end;

    procedure UpgradeTriggered(): Boolean
    var
        UpgradeStatus: Record "Upgrade Status";
    begin
        if not UpgradeStatus.Get() then
            exit(false);

        exit(UpgradeStatus.UpgradeTriggered);
    end;

    procedure UpgradeTagPresentBeforeUpgrade(UpgradeTag: Code[250]): Boolean
    var
        UPGUpgradeTag: Record "UPG - Upgrade Tag";
    begin
        UPGUpgradeTag.SetFilter(Company, '=%1|''''', CompanyName());
        UPGUpgradeTag.SetRange(Tag, UpgradeTag);
        exit(UPGUpgradeTag.FindFirst());
    end;
}