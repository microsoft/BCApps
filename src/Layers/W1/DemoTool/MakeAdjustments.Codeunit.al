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
        AddMapElement('991120', '1120');
        AddMapElement('991130', '1130');
        AddMapElement('991140', '1140');
        AddMapElement('991190', '1190');
        AddMapElement('991200', '1200');
        AddMapElement('991210', '1210');
        AddMapElement('991220', '1220');
        AddMapElement('991230', '1230');
        AddMapElement('991240', '1240');
        AddMapElement('991290', '1290');
        AddMapElement('991300', '1300');
        AddMapElement('991310', '1310');
        AddMapElement('991320', '1320');
        AddMapElement('991330', '1330');
        AddMapElement('991340', '1340');
        AddMapElement('991390', '1390');
        AddMapElement('991395', '1395');
        AddMapElement('991999', '1999');
        AddMapElement('992000', '2000');
        AddMapElement('992100', '2100');
        AddMapElement('992110', '2110');
        AddMapElement('992111', '2111');
        AddMapElement('992112', '2112');
        AddMapElement('992120', '2120');
        AddMapElement('992121', '2121');
        AddMapElement('992130', '2130');
        AddMapElement('992131', '2131');
        AddMapElement('992132', '2132');
        AddMapElement('992180', '2180');
        AddMapElement('992190', '2190');
        AddMapElement('992200', '2200');
        AddMapElement('992210', '2210');
        AddMapElement('992211', '2211');
        AddMapElement('992212', '2212');
        AddMapElement('992220', '2220');
        AddMapElement('992230', '2230');
        AddMapElement('992231', '2231');
        AddMapElement('992232', '2232');
        AddMapElement('992240', '2240');
        AddMapElement('992290', '2290');
        AddMapElement('992300', '2300');
        AddMapElement('992310', '2310');
        AddMapElement('992320', '2320');
        AddMapElement('992325', '2325');
        AddMapElement('992330', '2330');
        AddMapElement('992340', '2340');
        AddMapElement('992390', '2390');
        AddMapElement('992400', '2400');
        AddMapElement('992410', '2410');
        AddMapElement('992420', '2420');
        AddMapElement('992430', '2430');
        AddMapElement('992440', '2440');
        AddMapElement('992800', '2800');
        AddMapElement('992810', '2810');
        AddMapElement('992890', '2890');
        AddMapElement('992900', '2900');
        AddMapElement('992910', '2910');
        AddMapElement('992920', '2920');
        AddMapElement('992930', '2930');
        AddMapElement('992940', '2940');
        AddMapElement('992990', '2990');
        AddMapElement('992995', '2995');
        AddMapElement('992999', '2999');
        AddMapElement('993000', '3000');
        AddMapElement('993100', '3100');
        AddMapElement('993110', '3110');
        AddMapElement('993120', '3120');
        AddMapElement('993195', '3195');
        AddMapElement('993199', '3199');
        AddMapElement('994000', '4000');
        AddMapElement('994010', '4010');
        AddMapElement('994999', '4999');
        AddMapElement('995000', '5000');
        AddMapElement('995100', '5100');
        AddMapElement('995110', '5110');
        AddMapElement('995120', '5120');
        AddMapElement('995290', '5290');
        AddMapElement('995300', '5300');
        AddMapElement('995310', '5310');
        AddMapElement('995350', '5350');
        AddMapElement('995360', '5360');
        AddMapElement('995370', '5370');
        AddMapElement('995380', '5380');
        AddMapElement('995390', '5390');
        AddMapElement('995400', '5400');
        AddMapElement('995410', '5410');
        AddMapElement('995420', '5420');
        AddMapElement('995425', '5425');
        AddMapElement('995490', '5490');
        AddMapElement('995500', '5500');
        AddMapElement('995510', '5510');
        AddMapElement('995530', '5530');
        AddMapElement('995590', '5590');
        AddMapElement('995600', '5600');
        AddMapElement('995610', '5610');
        AddMapElement('995611', '5611');
        AddMapElement('995612', '5612');
        AddMapElement('995615', '5615');
        AddMapElement('995616', '5616');
        AddMapElement('995620', '5620');
        AddMapElement('995621', '5621');
        AddMapElement('995622', '5622');
        AddMapElement('995625', '5625');
        AddMapElement('995626', '5626');
        AddMapElement('995630', '5630');
        AddMapElement('995631', '5631');
        AddMapElement('995632', '5632');
        AddMapElement('995635', '5635');
        AddMapElement('995636', '5636');
        AddMapElement('995710', '5710');
        AddMapElement('995720', '5720');
        AddMapElement('995730', '5730');
        AddMapElement('995740', '5740');
        AddMapElement('995750', '5750');
        AddMapElement('995760', '5760');
        AddMapElement('995780', '5780');
        AddMapElement('995790', '5790');
        AddMapElement('995795', '5795');
        AddMapElement('995796', '5796');
        AddMapElement('995797', '5797');
        AddMapElement('995799', '5799');
        AddMapElement('995800', '5800');
        AddMapElement('995810', '5810');
        AddMapElement('995820', '5820');
        AddMapElement('995830', '5830');
        AddMapElement('995840', '5840');
        AddMapElement('995850', '5850');
        AddMapElement('995890', '5890');
        AddMapElement('995900', '5900');
        AddMapElement('995910', '5910');
        AddMapElement('995920', '5920');
        AddMapElement('995990', '5990');
        AddMapElement('995995', '5995');
        AddMapElement('995997', '5997');
        AddMapElement('995999', '5999');
        AddMapElement('996000', '6000');
        AddMapElement('996100', '6100');
        AddMapElement('996105', '6105');
        AddMapElement('996110', '6110');
        AddMapElement('996120', '6120');
        AddMapElement('996130', '6130');
        AddMapElement('996190', '6190');
        AddMapElement('996191', '6191');
        AddMapElement('996195', '6195');
        AddMapElement('996205', '6205');
        AddMapElement('996210', '6210');
        AddMapElement('996220', '6220');
        AddMapElement('996230', '6230');
        AddMapElement('996290', '6290');
        AddMapElement('996291', '6291');
        AddMapElement('996295', '6295');
        AddMapElement('996405', '6405');
        AddMapElement('996410', '6410');
        AddMapElement('996420', '6420');
        AddMapElement('996430', '6430');
        AddMapElement('996490', '6490');
        AddMapElement('996491', '6491');
        AddMapElement('996495', '6495');
        AddMapElement('996605', '6605');
        AddMapElement('996610', '6610');
        AddMapElement('996620', '6620');
        AddMapElement('996695', '6695');
        AddMapElement('996710', '6710');
        AddMapElement('996810', '6810');
        AddMapElement('996820', '6820');
        AddMapElement('996910', '6910');
        AddMapElement('996950', '6950');
        AddMapElement('996955', '6955');
        AddMapElement('996959', '6959');
        AddMapElement('996995', '6995');
        AddMapElement('997100', '7100');
        AddMapElement('997105', '7105');
        AddMapElement('997110', '7110');
        AddMapElement('997120', '7120');
        AddMapElement('997130', '7130');
        AddMapElement('997140', '7140');
        AddMapElement('997150', '7150');
        AddMapElement('997170', '7170');
        AddMapElement('997180', '7180');
        AddMapElement('997181', '7181');
        AddMapElement('997190', '7190');
        AddMapElement('997195', '7195');
        AddMapElement('997205', '7205');
        AddMapElement('997210', '7210');
        AddMapElement('997220', '7220');
        AddMapElement('997230', '7230');
        AddMapElement('997240', '7240');
        AddMapElement('997250', '7250');
        AddMapElement('997270', '7270');
        AddMapElement('997280', '7280');
        AddMapElement('997281', '7281');
        AddMapElement('997290', '7290');
        AddMapElement('997295', '7295');
        AddMapElement('997405', '7405');
        AddMapElement('997480', '7480');
        AddMapElement('997481', '7481');
        AddMapElement('997490', '7490');
        AddMapElement('997495', '7495');
        AddMapElement('997620', '7620');
        AddMapElement('997995', '7995');
        AddMapElement('998000', '8000');
        AddMapElement('998100', '8100');
        AddMapElement('998110', '8110');
        AddMapElement('998120', '8120');
        AddMapElement('998130', '8130');
        AddMapElement('998190', '8190');
        AddMapElement('998200', '8200');
        AddMapElement('998210', '8210');
        AddMapElement('998230', '8230');
        AddMapElement('998240', '8240');
        AddMapElement('998290', '8290');
        AddMapElement('998300', '8300');
        AddMapElement('998310', '8310');
        AddMapElement('998320', '8320');
        AddMapElement('998330', '8330');
        AddMapElement('998390', '8390');
        AddMapElement('998400', '8400');
        AddMapElement('998410', '8410');
        AddMapElement('998420', '8420');
        AddMapElement('998430', '8430');
        AddMapElement('998450', '8450');
        AddMapElement('998490', '8490');
        AddMapElement('998500', '8500');
        AddMapElement('998510', '8510');
        AddMapElement('998520', '8520');
        AddMapElement('998530', '8530');
        AddMapElement('998590', '8590');
        AddMapElement('998600', '8600');
        AddMapElement('998610', '8610');
        AddMapElement('998620', '8620');
        AddMapElement('998630', '8630');
        AddMapElement('998640', '8640');
        AddMapElement('998690', '8690');
        AddMapElement('998695', '8695');
        AddMapElement('998700', '8700');
        AddMapElement('998710', '8710');
        AddMapElement('998720', '8720');
        AddMapElement('998730', '8730');
        AddMapElement('998740', '8740');
        AddMapElement('998750', '8750');
        AddMapElement('998790', '8790');
        AddMapElement('998800', '8800');
        AddMapElement('998810', '8810');
        AddMapElement('998820', '8820');
        AddMapElement('998830', '8830');
        AddMapElement('998840', '8840');
        AddMapElement('998890', '8890');
        AddMapElement('998910', '8910');
        AddMapElement('998995', '8995');
        AddMapElement('999100', '9100');
        AddMapElement('999110', '9110');
        AddMapElement('999120', '9120');
        AddMapElement('999130', '9130');
        AddMapElement('999135', '9135');
        AddMapElement('999140', '9140');
        AddMapElement('999150', '9150');
        AddMapElement('999160', '9160');
        AddMapElement('999170', '9170');
        AddMapElement('999190', '9190');
        AddMapElement('999200', '9200');
        AddMapElement('999210', '9210');
        AddMapElement('999220', '9220');
        AddMapElement('999230', '9230');
        AddMapElement('999240', '9240');
        AddMapElement('999250', '9250');
        AddMapElement('999255', '9255');
        AddMapElement('999260', '9260');
        AddMapElement('999270', '9270');
        AddMapElement('999290', '9290');
        AddMapElement('999310', '9310');
        AddMapElement('999320', '9320');
        AddMapElement('999330', '9330');
        AddMapElement('999340', '9340');
        AddMapElement('999350', '9350');
        AddMapElement('999360', '9360');
        AddMapElement('999395', '9395');
        AddMapElement('999410', '9410');
        AddMapElement('999420', '9420');
        AddMapElement('999495', '9495');
        AddMapElement('999510', '9510');
        AddMapElement('999999', '9999');
        AddMapElement('997191', '7191');
        AddMapElement('997192', '7192');
        AddMapElement('997193', '7193');
        AddMapElement('997291', '7291');
        AddMapElement('997292', '7292');
        AddMapElement('997293', '7293');
        AddMapElement('997705', '7705');
        AddMapElement('997710', '7710');
        AddMapElement('997791', '7791');
        AddMapElement('997792', '7792');
        AddMapElement('997793', '7793');
        AddMapElement('997795', '7795');
        AddMapElement('997805', '7805');
        AddMapElement('997890', '7890');
        AddMapElement('997891', '7891');
        AddMapElement('997892', '7892');
        AddMapElement('997893', '7893');
        AddMapElement('997894', '7894');
        AddMapElement('997895', '7895');
        AddMapElement('992140', '2140');
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

