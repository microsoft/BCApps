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
        AddMapElement('991000', 'xxxx');
        AddMapElement('991002', 'xxxx');
        AddMapElement('991003', 'xxxx');
        AddMapElement('991005', 'xxxx');
        AddMapElement('991100', 'xxxx');
        AddMapElement('991110', '1600');
        AddMapElement('991120', '1600');
        AddMapElement('991130', '1600');
        AddMapElement('991140', '1609');
        AddMapElement('991190', 'xxxx');
        AddMapElement('991200', 'xxxx');
        AddMapElement('991210', '1500');
        AddMapElement('991220', '1500');
        AddMapElement('991230', '1500');
        AddMapElement('991240', '1509');
        AddMapElement('991290', 'xxxx');
        AddMapElement('991300', 'xxxx');
        AddMapElement('991310', '1530');
        AddMapElement('991320', '1530');
        AddMapElement('991330', '1530');
        AddMapElement('991340', '1539');
        AddMapElement('991390', 'xxxx');
        AddMapElement('991395', 'xxxx');
        AddMapElement('991999', 'xxxx');
        AddMapElement('992000', 'xxxx');
        AddMapElement('992100', 'xxxx');
        AddMapElement('992110', '1200');
        AddMapElement('992111', 'xxxx');
        AddMapElement('992120', '1260');
        AddMapElement('992121', 'xxxx');
        AddMapElement('992130', '1210');
        AddMapElement('992131', 'xxxx');
        AddMapElement('992180', '9100');
        AddMapElement('992190', 'xxxx');
        AddMapElement('992200', 'xxxx');
        AddMapElement('992210', '1280');
        AddMapElement('992211', '1282');
        AddMapElement('992212', '1280');
        AddMapElement('992220', '1280');
        AddMapElement('992230', '2230');
        AddMapElement('992231', '1280');
        AddMapElement('992232', '1282');
        AddMapElement('992240', '2240');
        AddMapElement('992290', 'xxxx');
        AddMapElement('992300', 'xxxx');
        AddMapElement('992310', '1100');
        AddMapElement('992320', '1102');
        AddMapElement('992325', '2325');
        AddMapElement('992330', '1300');
        AddMapElement('992340', '1300');
        AddMapElement('992390', 'xxxx');
        AddMapElement('992800', 'xxxx');
        AddMapElement('992810', '1400');
        AddMapElement('992890', 'xxxx');
        AddMapElement('992900', 'xxxx');
        AddMapElement('992910', '1000');
        AddMapElement('992920', '1020');
        AddMapElement('992930', '1022');
        AddMapElement('992940', '1010');
        AddMapElement('992990', 'xxxx');
        AddMapElement('992995', 'xxxx');
        AddMapElement('992999', 'xxxx');
        AddMapElement('993000', 'xxxx');
        AddMapElement('993100', 'xxxx');
        AddMapElement('993110', '2800');
        AddMapElement('993120', '2915');
        AddMapElement('993195', 'xxxx');
        AddMapElement('993199', 'xxxx');
        AddMapElement('994000', 'xxxx');
        AddMapElement('994010', '2340');
        AddMapElement('994999', 'xxxx');
        AddMapElement('995000', 'xxxx');
        AddMapElement('995100', 'xxxx');
        AddMapElement('995110', '2400');
        AddMapElement('995120', '2440');
        AddMapElement('995290', 'xxxx');
        AddMapElement('995300', 'xxxx');
        AddMapElement('995310', '2100');
        AddMapElement('995400', 'xxxx');
        AddMapElement('995410', '2000');
        AddMapElement('995420', '2002');
        AddMapElement('995425', '5425');
        AddMapElement('995490', 'xxxx');
        AddMapElement('995500', 'xxxx');
        AddMapElement('995510', '2200');
        AddMapElement('995530', '1170');
        AddMapElement('995590', 'xxxx');
        AddMapElement('995600', 'xxxx');
        AddMapElement('995610', '2000');
        AddMapElement('995611', 'xxxx');
        AddMapElement('995612', 'xxxx');
        AddMapElement('995615', 'xxxx');
        AddMapElement('995616', 'xxxx');
        AddMapElement('995620', '2000');
        AddMapElement('995621', 'xxxx');
        AddMapElement('995622', 'xxxx');
        AddMapElement('995625', 'xxxx');
        AddMapElement('995626', 'xxxx');
        AddMapElement('995630', '2000');
        AddMapElement('995631', 'xxxx');
        AddMapElement('995632', 'xxxx');
        AddMapElement('995635', 'xxxx');
        AddMapElement('995636', 'xxxx');
        AddMapElement('995710', '2210');
        AddMapElement('995720', '2210');
        AddMapElement('995730', '2210');
        AddMapElement('995740', '2210');
        AddMapElement('995750', '2210');
        AddMapElement('995760', '2210');
        AddMapElement('995780', '2210');
        AddMapElement('995790', 'xxxx');
        AddMapElement('995795', '5795');
        AddMapElement('995796', '2041');
        AddMapElement('995797', '2042');
        AddMapElement('995799', '5799');
        AddMapElement('995800', 'xxxx');
        AddMapElement('995810', '2000');
        AddMapElement('995820', '2000');
        AddMapElement('995830', '2000');
        AddMapElement('995830B', '2100');
        AddMapElement('995840', '2000');
        AddMapElement('995850', '2001');
        AddMapElement('995890', 'xxxx');
        AddMapElement('995900', 'xxxx');
        AddMapElement('995910', '2230');
        AddMapElement('995920', '2340');
        AddMapElement('995990', 'xxxx');
        AddMapElement('995995', 'xxxx');
        AddMapElement('995997', 'xxxx');
        AddMapElement('995999', 'xxxx');
        AddMapElement('996000', '2999');
        AddMapElement('996100', 'xxxx');
        AddMapElement('996105', 'xxxx');
        AddMapElement('996110', '3200');
        AddMapElement('996120', '3202');
        AddMapElement('996130', '3204');
        AddMapElement('996190', '3421');
        AddMapElement('996191', '3421');
        AddMapElement('996195', 'xxxx');
        AddMapElement('996205', 'xxxx');
        AddMapElement('996210', '3000');
        AddMapElement('996220', '3002');
        AddMapElement('996230', '3004');
        AddMapElement('996290', '3080');
        AddMapElement('996295', 'xxxx');
        AddMapElement('996300', '6300');
        AddMapElement('996399', '6399');
        AddMapElement('996405', 'xxxx');
        AddMapElement('996410', '3400');
        AddMapElement('996420', '3402');
        AddMapElement('996430', '3404');
        AddMapElement('996490', '3080');
        AddMapElement('996495', 'xxxx');
        AddMapElement('996605', 'xxxx');
        AddMapElement('996610', '3420');
        AddMapElement('996620', '3420');
        AddMapElement('996695', 'xxxx');
        AddMapElement('996710', '3430');
        AddMapElement('996810', '3430');
        AddMapElement('996910', '3901');
        AddMapElement('996950', '6950');
        AddMapElement('996955', '3490');
        AddMapElement('996959', '6959');
        AddMapElement('996995', 'xxxx');
        AddMapElement('997100', 'xxxx');
        AddMapElement('997105', 'xxxx');
        AddMapElement('997110', '4200');
        AddMapElement('997120', '4202');
        AddMapElement('997130', '4204');
        AddMapElement('997140', '4901');
        AddMapElement('997150', '6280');
        AddMapElement('997170', '4820');
        AddMapElement('997180', '4421');
        AddMapElement('997181', '4421');
        AddMapElement('997190', '4820');
        AddMapElement('997193', '4399');
        AddMapElement('997195', 'xxxx');
        AddMapElement('997205', 'xxxx');
        AddMapElement('997210', '4000');
        AddMapElement('997220', '4002');
        AddMapElement('997230', '4004');
        AddMapElement('997240', '4900');
        AddMapElement('997250', '6280');
        AddMapElement('997270', '4800');
        AddMapElement('997280', '4820');
        AddMapElement('997290', '4800');
        AddMapElement('997293', '4199');
        AddMapElement('997295', 'xxxx');
        AddMapElement('997405', 'xxxx');
        AddMapElement('997480', 'uuu6');
        AddMapElement('997490', 'uuu7');
        AddMapElement('997495', 'xxxx');
        AddMapElement('997620', '4420');
        AddMapElement('997710', '4400');
        AddMapElement('997894', '4999');
        AddMapElement('997995', 'xxxx');
        AddMapElement('998000', 'xxxx');
        AddMapElement('998100', 'xxxx');
        AddMapElement('998110', '6040');
        AddMapElement('998120', '6400');
        AddMapElement('998130', '6100');
        AddMapElement('998190', 'xxxx');
        AddMapElement('998200', 'xxxx');
        AddMapElement('998210', '6500');
        AddMapElement('998230', '6510');
        AddMapElement('998240', '6512');
        AddMapElement('998290', 'xxxx');
        AddMapElement('998300', 'xxxx');
        AddMapElement('998310', '6570');
        AddMapElement('998320', '6580');
        AddMapElement('998330', '6573');
        AddMapElement('998390', 'xxxx');
        AddMapElement('998400', 'xxxx');
        AddMapElement('998410', '6600');
        AddMapElement('998420', '6670');
        AddMapElement('998430', '6640');
        AddMapElement('998450', '6280');
        AddMapElement('998490', 'xxxx');
        AddMapElement('998500', 'xxxx');
        AddMapElement('998510', '6210');
        AddMapElement('998520', '6230');
        AddMapElement('998530', '6200');
        AddMapElement('998590', 'xxxx');
        AddMapElement('998600', 'xxxx');
        AddMapElement('998610', '6780');
        AddMapElement('998620', '3905');
        AddMapElement('998630', '6530');
        AddMapElement('998640', '6780');
        AddMapElement('998690', 'xxxx');
        AddMapElement('998695', 'xxxx');
        AddMapElement('998700', 'xxxx');
        AddMapElement('998710', '5000');
        AddMapElement('998720', '5000');
        AddMapElement('998720B', '5200');
        AddMapElement('998730', '5720');
        AddMapElement('998740', '5830');
        AddMapElement('998750', '5790');
        AddMapElement('998790', 'xxxx');
        AddMapElement('998800', 'xxxx');
        AddMapElement('998810', '6930');
        AddMapElement('998820', '6920');
        AddMapElement('998830', '6920');
        AddMapElement('998840', '7910');
        AddMapElement('998890', 'xxxx');
        AddMapElement('998910', '6780');
        AddMapElement('998995', 'xxxx');
        AddMapElement('999100', 'xxxx');
        AddMapElement('999110', '6800');
        AddMapElement('999120', '4901');
        AddMapElement('999130', '4900');
        AddMapElement('999135', 'xxxx');
        AddMapElement('999140', '4908');
        AddMapElement('999150', '4908');
        AddMapElement('999160', 'xxxx');
        AddMapElement('999170', 'xxxx');
        AddMapElement('999190', 'xxxx');
        AddMapElement('999200', 'xxxx');
        AddMapElement('999210', '6800');
        AddMapElement('999220', '6800');
        AddMapElement('999230', '6802');
        AddMapElement('999240', '6800');
        AddMapElement('999250', '3900');
        AddMapElement('999255', '9255');
        AddMapElement('999260', 'xxxx');
        AddMapElement('999270', 'xxxx');
        AddMapElement('999290', 'xxxx');
        AddMapElement('999310', '3906');
        AddMapElement('999320', '3906');
        AddMapElement('999330', '3907');
        AddMapElement('999340', '3907');
        AddMapElement('999350', 'xxxx');
        AddMapElement('999360', 'xxxx');
        AddMapElement('999395', '7000');
        AddMapElement('999410', 'uuu8');
        AddMapElement('999420', '8010');
        AddMapElement('999495', 'xxxx');
        AddMapElement('999510', '8900');
        AddMapElement('999999', 'xxxx');
        AddMapElement('997191', '7191');
        AddMapElement('997192', '7192');
        AddMapElement('997291', '7291');
        AddMapElement('997292', '7292');
        AddMapElement('997705', '7705');
        AddMapElement('997791', '7791');
        AddMapElement('997792', '7792');
        AddMapElement('997793', '7793');
        AddMapElement('997795', '7795');
        AddMapElement('997805', '7805');
        AddMapElement('997890', '7890');
        AddMapElement('997891', '7891');
        AddMapElement('997892', '7892');
        AddMapElement('997893', '7893');
        AddMapElement('997895', '7895');
        AddMapElement('992140', '2140');
        AddMapElement('1100', '1100');
        AddMapElement('1101', '1101');
        AddMapElement('1102', '1102');
        AddMapElement('3430', '3430');
        AddMapElement('3900', '3900');
        AddMapElement('3908', '3908');
        AddMapElement('3901', '3901');
        AddMapElement('2000', '2000');
        AddMapElement('2001', '2001');
        AddMapElement('2002', '2002');
        AddMapElement('6780', '6780');
        AddMapElement('4900', '4900');
        AddMapElement('4908', '4908');
        AddMapElement('1260', '1260');
        AddMapElement('1261', '1261');
        AddMapElement('1210', '1210');
        AddMapElement('1211', '1211');
        AddMapElement('1200', '1200');
        AddMapElement('1201', '1201');
        AddMapElement('2999', '2999');
        AddMapElement('8999', '8999');
        AddMapElement('3', '3');
        AddMapElement('3999', '3999');
        AddMapElement('4892', '4892');
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

