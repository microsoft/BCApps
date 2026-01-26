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
        AddMapElement('991000', '1000');
        AddMapElement('991002', '1002');
        AddMapElement('991003', '1003');
        AddMapElement('991005', '1005');
        AddMapElement('991100', '1100');
        AddMapElement('991110', '1110');
        AddMapElement('991120', '1115');
        AddMapElement('991130', '1116');
        AddMapElement('991140', '1119');
        AddMapElement('991190', '1190');
        AddMapElement('991200', '1200');
        AddMapElement('991210', '1210');
        AddMapElement('991220', '1215');
        AddMapElement('991230', '1216');
        AddMapElement('991240', '1219');
        AddMapElement('991290', '1220');
        AddMapElement('991300', '1240');
        AddMapElement('991310', '1241');
        AddMapElement('991320', '1245');
        AddMapElement('991330', '1246');
        AddMapElement('991340', '1249');
        AddMapElement('991390', '1250');
        AddMapElement('991395', '1260');
        AddMapElement('991999', '1398');
        AddMapElement('992000', '1400');
        AddMapElement('992100', '1401');
        AddMapElement('992110', '1460');
        AddMapElement('992111', '1461');
        AddMapElement('992112', '4058');
        AddMapElement('991793', '1793');
        AddMapElement('992993', '2993');
        AddMapElement('992120', '1450');
        AddMapElement('992121', '1451');
        AddMapElement('992130', '1410');
        AddMapElement('992131', '1411');
        AddMapElement('992132', '4158');
        AddMapElement('992140', '1440');
        AddMapElement('992180', '1452');
        AddMapElement('992190', '1499');
        AddMapElement('992200', '1430');
        AddMapElement('992210', '1431');
        AddMapElement('992211', '1432');
        AddMapElement('992212', '1433');
        AddMapElement('992220', '1434');
        AddMapElement('992230', '1435');
        AddMapElement('992231', '1436');
        AddMapElement('992232', '1437');
        AddMapElement('992240', '1438');
        AddMapElement('992290', '1449');
        AddMapElement('992300', '1500');
        AddMapElement('992310', '1510');
        AddMapElement('992320', '1511');
        AddMapElement('992330', '1520');
        AddMapElement('992340', '1530');
        AddMapElement('992390', '1599');
        AddMapElement('992400', '1530');
        AddMapElement('992410', '1530');
        AddMapElement('992420', '1530');
        AddMapElement('992430', '1530');
        AddMapElement('992440', '1530');
        AddMapElement('992800', '1300');
        AddMapElement('992810', '1310');
        AddMapElement('992890', '1397');
        AddMapElement('992900', '1900');
        AddMapElement('992910', '1910');
        AddMapElement('992920', '1940');
        AddMapElement('992930', '1941');
        AddMapElement('992940', '1920');
        AddMapElement('992990', '1949');
        AddMapElement('992995', '1998');
        AddMapElement('992999', '1999');
        AddMapElement('993000', '2000');
        AddMapElement('993100', '2010');
        AddMapElement('993110', '2081');
        AddMapElement('993120', '2091');
        AddMapElement('993195', '2098');
        AddMapElement('993199', '2099');
        AddMapElement('994000', 'Bort1');
        AddMapElement('994010', '2085');
        AddMapElement('994999', 'Bort2');
        AddMapElement('995000', '2000');
        AddMapElement('995100', '2300');
        AddMapElement('995110', '2359');
        AddMapElement('995120', '2352');
        AddMapElement('995290', '2399');
        AddMapElement('995300', '2400');
        AddMapElement('995310', '2330');
        AddMapElement('995350', '2330');
        AddMapElement('995360', '2330');
        AddMapElement('995370', '2330');
        AddMapElement('995380', '2330');
        AddMapElement('995390', '2330');
        AddMapElement('995510', '4061');
        AddMapElement('995530', '4161');
        AddMapElement('995400', '2440');
        AddMapElement('995410', '2441');
        AddMapElement('995420', '2442');
        AddMapElement('995490', '2449');
        AddMapElement('995500', '2600');
        AddMapElement('995610', '2610');
        AddMapElement('995611', '2620');
        AddMapElement('995620', '2615');
        AddMapElement('995621', '2645');
        AddMapElement('995630', '2640');
        AddMapElement('995631', '2642');
        AddMapElement('995710', '5135');
        AddMapElement('995720', '2670');
        AddMapElement('995730', '2671');
        AddMapElement('995740', '2672');
        AddMapElement('995750', '5136');
        AddMapElement('995760', '2674');
        AddMapElement('995780', '2679');
        AddMapElement('995790', '2650');
        AddMapElement('995795', '5795');
        AddMapElement('995796', '1720');
        AddMapElement('995797', '1720');
        AddMapElement('995799', '5799');
        AddMapElement('995800', '7200');
        AddMapElement('995810', '2711');
        AddMapElement('995820', '2510');
        AddMapElement('995830', '2718');
        AddMapElement('995840', '7090');
        AddMapElement('995850', '7100');
        AddMapElement('995890', '7299');
        AddMapElement('995900', '2890');
        AddMapElement('995910', '8010');
        AddMapElement('995920', '2211');
        AddMapElement('995990', '2990');
        AddMapElement('995995', '2995');
        AddMapElement('995997', '2997');
        AddMapElement('995999', '2999');
        AddMapElement('996000', '3000');
        AddMapElement('996100', '3002');
        AddMapElement('996105', '3050');
        AddMapElement('996110', '3051');
        AddMapElement('996120', '3056');
        AddMapElement('996130', '3055');
        AddMapElement('996190', '3057');
        AddMapElement('996191', '3057');
        AddMapElement('996195', '3059');
        AddMapElement('996205', '3060');
        AddMapElement('996210', '3061');
        AddMapElement('996220', '3066');
        AddMapElement('996230', '3065');
        AddMapElement('996290', '3067');
        AddMapElement('996291', '3067');
        AddMapElement('996295', '3069');
        AddMapElement('996405', '3070');
        AddMapElement('996410', '3071');
        AddMapElement('996420', '3076');
        AddMapElement('996430', '3075');
        AddMapElement('996490', '3077');
        AddMapElement('996491', '3077');
        AddMapElement('996495', '3079');
        AddMapElement('996605', '3080');
        AddMapElement('996610', '3081');
        AddMapElement('996620', '3085');
        AddMapElement('996695', '3089');
        AddMapElement('996710', '3090');
        AddMapElement('996810', '3095');
        AddMapElement('996910', '3098');
        AddMapElement('996950', '3100');
        AddMapElement('996955', '3155');
        AddMapElement('996959', '3199');
        AddMapElement('996995', '3999');
        AddMapElement('997100', '4000');
        AddMapElement('997105', '4002');
        AddMapElement('997110', '4051');
        AddMapElement('997120', '4056');
        AddMapElement('997130', '4055');
        AddMapElement('997140', '4070');
        AddMapElement('997150', '4080');
        AddMapElement('997170', '4060');
        AddMapElement('997180', '4065');
        AddMapElement('997181', '4065');
        AddMapElement('997190', '4059');
        AddMapElement('997191', '4091');
        AddMapElement('997192', '4092');
        AddMapElement('997193', '4093');
        AddMapElement('997195', '4099');
        AddMapElement('997205', '4100');
        AddMapElement('997210', '4151');
        AddMapElement('997220', '4156');
        AddMapElement('997230', '4155');
        AddMapElement('997240', '4170');
        AddMapElement('997250', '4180');
        AddMapElement('997270', '4160');
        AddMapElement('997280', '4165');
        AddMapElement('997281', '4165');
        AddMapElement('997290', '4159');
        AddMapElement('997291', '4191');
        AddMapElement('997292', '4192');
        AddMapElement('997293', '4193');
        AddMapElement('997295', '4199');
        AddMapElement('997405', '4200');
        AddMapElement('997480', '4250');
        AddMapElement('997481', '4250');
        AddMapElement('997490', '4260');
        AddMapElement('997495', '4299');
        AddMapElement('997620', '4300');
        AddMapElement('997705', '4400');
        AddMapElement('997710', '4450');
        AddMapElement('997791', '4491');
        AddMapElement('997792', '4492');
        AddMapElement('997793', '4493');
        AddMapElement('997795', '4499');
        AddMapElement('997805', '4500');
        AddMapElement('997890', '4510');
        AddMapElement('997891', '4520');
        AddMapElement('997892', '4530');
        AddMapElement('997893', '4540');
        AddMapElement('997894', '4550');
        AddMapElement('997895', '4597');
        AddMapElement('997995', '4599');
        AddMapElement('998000', '1000');
        AddMapElement('998100', '5100');
        AddMapElement('998110', '5160');
        AddMapElement('998120', '5130');
        AddMapElement('998130', '5170');
        AddMapElement('998190', '5199');
        AddMapElement('998200', '6200');
        AddMapElement('998210', '6230');
        AddMapElement('998230', '6210');
        AddMapElement('998240', '6220');
        AddMapElement('998290', '6299');
        AddMapElement('998300', '6500');
        AddMapElement('998310', '6540');
        AddMapElement('998320', '6550');
        AddMapElement('998330', '6560');
        AddMapElement('998390', '6599');
        AddMapElement('998400', '5900');
        AddMapElement('998410', '5910');
        AddMapElement('998420', '5970');
        AddMapElement('998430', '5810');
        AddMapElement('998450', '5710');
        AddMapElement('998490', '5999');
        AddMapElement('998500', '5600');
        AddMapElement('998510', '5611');
        AddMapElement('998520', '5612');
        AddMapElement('998530', '5613');
        AddMapElement('998590', '5699');
        AddMapElement('998600', 'Bort3');
        AddMapElement('998610', '6351');
        AddMapElement('998620', '6352');
        AddMapElement('998630', '6420');
        AddMapElement('998640', '6450');
        AddMapElement('998690', '1000');
        AddMapElement('998695', '1000');
        AddMapElement('998700', '7000');
        AddMapElement('998710', '7010');
        AddMapElement('998720', '7210');
        AddMapElement('998730', '7400');
        AddMapElement('998740', '7090');
        AddMapElement('998750', '7590');
        AddMapElement('998790', '7599');
        AddMapElement('998800', '7800');
        AddMapElement('998810', '7820');
        AddMapElement('998820', '7830');
        AddMapElement('998830', '7834');
        AddMapElement('998840', '7891');
        AddMapElement('998890', '7899');
        AddMapElement('998910', '7990');
        AddMapElement('998995', 'Bort4');
        AddMapElement('999100', '8300');
        AddMapElement('999110', '8410');
        AddMapElement('999120', '8420');
        AddMapElement('999130', '3731');
        AddMapElement('999135', '4732');
        AddMapElement('999140', '3740');
        AddMapElement('999150', '7995');
        AddMapElement('999190', '1000');
        AddMapElement('999200', '8400');
        AddMapElement('999210', '8451');
        AddMapElement('999220', '8452');
        AddMapElement('999230', '8453');
        AddMapElement('999240', '8422');
        AddMapElement('999250', '4731');
        AddMapElement('999255', '3732');
        AddMapElement('999290', '8499');
        AddMapElement('999310', '8220');
        AddMapElement('999320', '8221');
        AddMapElement('999330', '8231');
        AddMapElement('999340', '8234');
        AddMapElement('999395', '1000');
        AddMapElement('999410', '8710');
        AddMapElement('999420', '8750');
        AddMapElement('999495', '8900');
        AddMapElement('999510', '8910');
        AddMapElement('999999', '8999');
        AddMapElement('999160', '3098');
        AddMapElement('999170', '3098');
        AddMapElement('999260', '3098');
        AddMapElement('999270', '3098');
        AddMapElement('1445', '1445');
        AddMapElement('992325', '1512');
        AddMapElement('995425', '2443');
        AddMapElement('2617', '2617');
        AddMapElement('2647', '2647');
        AddMapElement('2630', '2630');
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

