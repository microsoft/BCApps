codeunit 101902 "Make Adjustments"
{
    SingleInstance = true;

    trigger OnRun()
    begin
        GenerateMap();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        TempGLAccountMapBuffer: Record "G/L Account Map Buffer";

    procedure Convert("Account No.": Code[20]) Return: Code[20]
    begin
        if not IsAccountMapped("Account No.", Return) then
            exit("Account No.");
    end;

    // This Account is also used for Vendor and Customer posting grouppes
    procedure GetAdjustmentAccount(): Code[20]
    begin
        exit('999150');
    end;

    local procedure AddMapElement("Key": Code[20]; Value: Code[20])
    begin
        TempGLAccountMapBuffer.Key := Key;
        TempGLAccountMapBuffer.Value := Value;
        TempGLAccountMapBuffer.Insert();
    end;

    local procedure IsAccountMapped(AccountNo: Code[20]; var Return: Code[20]): Boolean
    begin
        TempGLAccountMapBuffer.SetCurrentKey(Key);
        if TempGLAccountMapBuffer.Get(AccountNo) then begin
            Return := TempGLAccountMapBuffer.Value;
            exit(true);
        end;
        exit(false);
    end;

    local procedure GenerateMap()
    begin
        AddMapElement('991100', '1120');
        AddMapElement('991110', '1120');
        AddMapElement('991120', '1120');
        AddMapElement('991130', '1120');
        AddMapElement('991140', '1128');
        AddMapElement('991210', '1200');
        AddMapElement('991220', '1200');
        AddMapElement('991230', '1200');
        AddMapElement('991240', '1218');
        AddMapElement('991300', '1250');
        AddMapElement('991310', '1250');
        AddMapElement('991320', '1250');
        AddMapElement('991330', '1250');
        AddMapElement('991340', '1258');
        AddMapElement('992100', '1609');
        AddMapElement('992110', '1620');
        AddMapElement('992111', '1621');
        AddMapElement('992112', '1622');
        AddMapElement('992120', '1630');
        AddMapElement('992121', '1631');
        AddMapElement('992130', '1610');
        AddMapElement('992131', '1611');
        AddMapElement('992132', '1612');
        AddMapElement('992180', '1660');
        AddMapElement('992190', '1679');
        AddMapElement('992210', '1640');
        AddMapElement('992220', '1641');
        AddMapElement('992290', '1645');
        AddMapElement('992300', '1699');
        AddMapElement('992310', '1700');
        AddMapElement('992320', '1701');
        AddMapElement('992325', '1702');
        AddMapElement('992330', '1860');
        AddMapElement('992340', '1860');
        AddMapElement('992390', '1869');
        AddMapElement('992800', '1879');
        AddMapElement('992810', '1890');
        AddMapElement('992890', '1891');
        AddMapElement('992900', '1899');
        AddMapElement('992910', '1900');
        AddMapElement('992920', '1920');
        AddMapElement('992930', '1970');
        AddMapElement('992940', '1916');
        AddMapElement('992990', '1979');
        AddMapElement('993110', '2000');
        AddMapElement('993120', '2080');
        AddMapElement('993195', '2090');
        AddMapElement('994010', '2275');
        AddMapElement('995000', '2499');
        AddMapElement('995110', '2530');
        AddMapElement('995120', '2594');
        AddMapElement('995310', '2520');
        AddMapElement('995400', '2760');
        AddMapElement('995410', '2760');
        AddMapElement('995420', '2761');
        AddMapElement('995425', '2762');
        AddMapElement('995490', '2996');
        AddMapElement('995500', '2840');
        AddMapElement('995510', '2841');
        AddMapElement('995530', '2842');
        AddMapElement('995590', '2849');
        AddMapElement('995610', '2941');
        AddMapElement('995611', '2943');
        AddMapElement('995620', '1843');
        AddMapElement('995621', '1845');
        AddMapElement('995630', '1840');
        AddMapElement('995631', '1842');
        AddMapElement('995710', '6710');
        AddMapElement('995720', '6580');
        AddMapElement('995730', '6580');
        AddMapElement('995740', '6580');
        AddMapElement('995750', '6580');
        AddMapElement('995760', '6570');
        AddMapElement('995780', '2940');
        AddMapElement('995790', '2940');
        AddMapElement('995795', '5795');
        AddMapElement('995796', '5796');
        AddMapElement('995797', '5797');
        AddMapElement('995799', '5799');
        AddMapElement('995810', '2911');
        AddMapElement('995820', '2911');
        AddMapElement('995830', '2911');
        AddMapElement('995850', '2914');
        AddMapElement('995840', '2915');
        AddMapElement('995890', '2915');
        AddMapElement('995910', '2990');
        AddMapElement('995920', '2800');
        AddMapElement('995990', '2800');
        AddMapElement('995995', '5995');
        AddMapElement('995997', '5997');
        AddMapElement('995999', '5999');
        AddMapElement('996000', '6000');
        AddMapElement('996100', '2999');
        AddMapElement('996110', '3001');
        AddMapElement('996120', '3111');
        AddMapElement('996130', '3101');
        AddMapElement('996190', '3121');
        AddMapElement('996195', '3001');
        AddMapElement('996210', '3000');
        AddMapElement('996220', '3110');
        AddMapElement('996230', '3100');
        AddMapElement('996290', '3120');
        AddMapElement('996410', '3002');
        AddMapElement('996420', '3112');
        AddMapElement('996430', '3102');
        AddMapElement('996490', '3122');
        AddMapElement('996491', '6491');
        AddMapElement('996495', '6495');
        AddMapElement('996605', '6605');
        AddMapElement('996610', '3075');
        AddMapElement('996620', '3070');
        AddMapElement('996710', '3002');
        AddMapElement('996810', '3145');
        AddMapElement('996820', '3146');
        AddMapElement('996910', '3600');
        AddMapElement('996950', '6950');
        AddMapElement('996955', '6955');
        AddMapElement('996959', '6959');
        AddMapElement('996995', '3679');
        AddMapElement('997100', '4000');
        AddMapElement('997110', '7110');
        AddMapElement('997120', '4111');
        AddMapElement('997130', '4101');
        AddMapElement('997140', '4600');
        AddMapElement('997150', '4983');
        AddMapElement('997170', '4820');
        AddMapElement('997180', '4121');
        AddMapElement('997190', '4830');
        AddMapElement('997210', '7210');
        AddMapElement('997220', '4110');
        AddMapElement('997230', '4100');
        AddMapElement('997240', '4600');
        AddMapElement('997250', '4983');
        AddMapElement('997270', '4800');
        AddMapElement('997280', '4120');
        AddMapElement('997290', '4810');
        AddMapElement('997480', '4122');
        AddMapElement('997620', '4150');
        AddMapElement('997995', '4998');
        AddMapElement('998100', '6526');
        AddMapElement('998110', '6530');
        AddMapElement('998120', '6580');
        AddMapElement('998130', '6510');
        AddMapElement('998210', '6851');
        AddMapElement('998230', '6822');
        AddMapElement('998240', '6821');
        AddMapElement('998310', '6856');
        AddMapElement('998320', '6862');
        AddMapElement('998330', '6856');
        AddMapElement('998410', '6400');
        AddMapElement('998420', '6460');
        AddMapElement('998430', '6380');
        AddMapElement('998450', '4983');
        AddMapElement('998490', '4983');
        AddMapElement('998500', '4983');
        AddMapElement('998510', '6710');
        AddMapElement('998520', '6750');
        AddMapElement('998530', '6720');
        AddMapElement('998610', '6870');
        AddMapElement('998620', '6930');
        AddMapElement('998630', '6860');
        AddMapElement('998640', '6870');
        AddMapElement('998695', '7001');
        AddMapElement('998710', '6010');
        AddMapElement('998720', '6040');
        AddMapElement('998730', '6108');
        AddMapElement('998740', '6050');
        AddMapElement('998750', '6101');
        AddMapElement('998810', '7030');
        AddMapElement('998820', '7040');
        AddMapElement('998830', '7040');
        AddMapElement('998840', '3810');
        AddMapElement('998890', '7499');
        AddMapElement('998910', '6870');
        AddMapElement('998995', '7001');
        AddMapElement('998790', '7001');
        AddMapElement('999110', '8310');
        AddMapElement('999120', '8200');
        AddMapElement('999130', '4610');
        AddMapElement('999135', '4611');
        AddMapElement('999140', '4615');
        AddMapElement('999150', '4620');
        AddMapElement('999160', '4630');
        AddMapElement('999170', '4631');
        AddMapElement('999210', '8500');
        AddMapElement('999220', '8500');
        AddMapElement('999230', '8500');
        AddMapElement('999240', '8500');
        AddMapElement('999250', '3610');
        AddMapElement('999255', '3611');
        AddMapElement('999260', '3630');
        AddMapElement('999270', '3631');
        AddMapElement('999310', '8491');
        AddMapElement('999320', '8901');
        AddMapElement('999330', '8490');
        AddMapElement('999340', '8900');
        AddMapElement('999395', '9395');
        AddMapElement('999410', '9100');
        AddMapElement('999420', '9300');
        AddMapElement('999510', '9800');
        AddMapElement('999999', '9999');
        AddMapElement('997191', '4131');
        AddMapElement('997192', '4132');
        AddMapElement('997193', '4133');
        AddMapElement('997291', '4141');
        AddMapElement('997292', '4142');
        AddMapElement('997293', '4143');
        AddMapElement('997705', '4400');
        AddMapElement('997710', '4410');
        AddMapElement('997791', '4411');
        AddMapElement('997792', '4412');
        AddMapElement('997793', '4413');
        AddMapElement('997795', '4499');
        AddMapElement('997805', '4500');
        AddMapElement('997890', '4510');
        AddMapElement('997891', '4511');
        AddMapElement('997892', '4512');
        AddMapElement('997893', '4513');
        AddMapElement('997894', '4514');
        AddMapElement('997895', '4599');
        AddMapElement('992140', '1650');
        AddMapElement('992211', '1641');
        AddMapElement('992212', '1641');
        AddMapElement('992230', '1641');
        AddMapElement('992231', '1641');
        AddMapElement('992232', '1641');
        AddMapElement('992240', '1641');
        AddMapElement('992400', '1641');
        AddMapElement('992410', '1670');
        AddMapElement('992420', '1670');
        AddMapElement('992430', '1670');
        AddMapElement('992440', '1641');
        AddMapElement('995350', '1641');
        AddMapElement('995360', '1670');
        AddMapElement('995370', '1670');
        AddMapElement('995380', '1670');
        AddMapElement('995390', '1641');
        AddMapElement('996191', '3122');
        AddMapElement('996291', '1641');
        AddMapElement('997181', '1641');
        AddMapElement('997281', '1641');
        AddMapElement('997481', '1641');
        AddMapElement('991642', '1642');
        AddMapElement('991643', '1643');
        AddMapElement('991644', '1644');
        AddMapElement('991645', '9640');
        AddMapElement('991646', '2220');
    end;

    procedure AdjustDate(OriginalDate: Date): Date
    var
        TempDate: Date;
        WeekDay: Integer;
        MonthDay: Integer;
        Week: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if DemoDataSetup.Get() then;
        if OriginalDate <> 0D then begin
            TempDate := CalcDate('<+92Y>', OriginalDate);
            WeekDay := Date2DWY(TempDate, 1);
            MonthDay := Date2DMY(TempDate, 1);
            Month := Date2DMY(TempDate, 2);
            Week := Date2DWY(TempDate, 2);
            Year := Date2DMY(TempDate, 3) + DemoDataSetup."Starting Year" - 1994;
            case Month of
                1, 3, 5, 7, 8, 10, 12:
                    if (MonthDay = 31) or (MonthDay = 1) then
                        exit(DMY2Date(MonthDay, Month, Year));
                2:
                    if (MonthDay = 28) or (MonthDay = 1) then
                        exit(DMY2Date(MonthDay, Month, Year));
                4, 6, 9, 11:
                    if (MonthDay = 30) or (MonthDay = 1) then
                        exit(DMY2Date(MonthDay, Month, Year));
            end;
            exit(DWY2Date(WeekDay, Week, Year));
        end;
        exit(0D);
    end;
}

