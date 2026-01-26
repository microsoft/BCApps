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
        AddMapElement('991100', '22');
        AddMapElement('991110', '220000');
        AddMapElement('991120', '220000');
        AddMapElement('991130', '220000');
        AddMapElement('991140', '220009');
        AddMapElement('991190', '1190');
        AddMapElement('991200', '23');
        AddMapElement('991210', '230000');
        AddMapElement('991220', '230000');
        AddMapElement('991230', '230000');
        AddMapElement('991240', '230009');
        AddMapElement('991290', '1290');
        AddMapElement('991300', '24');
        AddMapElement('991310', '245000');
        AddMapElement('991320', '245000');
        AddMapElement('991330', '245000');
        AddMapElement('991340', '245009');
        AddMapElement('991390', '1390');
        AddMapElement('991395', '1395');
        AddMapElement('991999', '1999');
        AddMapElement('992000', '2000');
        AddMapElement('992100', '2100');
        AddMapElement('992110', '340000');
        AddMapElement('992111', '340010');
        AddMapElement('992112', '613399');
        AddMapElement('992120', '330000');
        AddMapElement('992121', '330010');
        AddMapElement('992130', '300000');
        AddMapElement('992131', '300010');
        AddMapElement('992132', '613399');
        AddMapElement('992180', '340000');
        AddMapElement('992190', '2190');
        AddMapElement('992200', '2200');
        AddMapElement('992210', '320000');
        AddMapElement('992211', '320000');
        AddMapElement('992212', '320000');
        AddMapElement('992220', '320000');
        AddMapElement('992230', '2230');
        AddMapElement('992231', '320000');
        AddMapElement('992232', '320000');
        AddMapElement('992240', '2240');
        AddMapElement('992290', '2290');
        AddMapElement('992300', '40');
        AddMapElement('992310', '400000');
        AddMapElement('992320', '400010');
        AddMapElement('992325', '400020');
        AddMapElement('992330', '404000');
        AddMapElement('992340', '417000');
        AddMapElement('992390', '2390');
        AddMapElement('992400', '36');
        AddMapElement('992410', '360000');
        AddMapElement('992420', '360000');
        AddMapElement('992430', '360000');
        AddMapElement('992440', '2440');
        AddMapElement('992800', '52');
        AddMapElement('992810', '510000');
        AddMapElement('992890', '2890');
        AddMapElement('992900', '55');
        AddMapElement('992910', '570000');
        AddMapElement('992920', '550000');
        AddMapElement('992930', '550010');
        AddMapElement('992940', '560000');
        AddMapElement('992990', '2990');
        AddMapElement('992995', '2995');
        AddMapElement('992999', '2999');
        AddMapElement('993000', '3000');
        AddMapElement('993100', '10');
        AddMapElement('993110', '100000');
        AddMapElement('993120', '101000');
        AddMapElement('993195', '3195');
        AddMapElement('993199', '3199');
        AddMapElement('994000', '4000');
        AddMapElement('994010', '168000');
        AddMapElement('994999', '4999');
        AddMapElement('995000', '5000');
        AddMapElement('995100', '17');
        AddMapElement('995110', '170000');
        AddMapElement('995120', '174000');
        AddMapElement('995290', '5290');
        AddMapElement('995300', '43');
        AddMapElement('995310', '550005');
        AddMapElement('995350', '406');
        AddMapElement('995360', '406000');
        AddMapElement('995370', '406000');
        AddMapElement('995380', '406000');
        AddMapElement('995390', '5390');
        AddMapElement('995400', '44');
        AddMapElement('995410', '440000');
        AddMapElement('995420', '440010');
        AddMapElement('995425', '440020');
        AddMapElement('995490', '5490');
        AddMapElement('995500', '41');
        AddMapElement('995510', '451000');
        AddMapElement('995530', '411000');
        AddMapElement('995590', '5590');
        AddMapElement('995600', '5600');
        AddMapElement('995610', '452000');
        AddMapElement('995611', '5611');
        AddMapElement('995612', '5612');
        AddMapElement('995615', '5615');
        AddMapElement('995616', '5616');
        AddMapElement('995620', '452000');
        AddMapElement('995621', '5621');
        AddMapElement('995622', '5622');
        AddMapElement('995625', '5625');
        AddMapElement('995626', '5626');
        AddMapElement('995630', '452000');
        AddMapElement('995631', '5631');
        AddMapElement('995632', '5632');
        AddMapElement('995635', '5635');
        AddMapElement('995636', '5636');
        AddMapElement('995710', '452000');
        AddMapElement('995720', '5720');
        AddMapElement('995730', '5730');
        AddMapElement('995740', '5740');
        AddMapElement('995750', '452000');
        AddMapElement('995760', '5760');
        AddMapElement('995780', '450000');
        AddMapElement('995790', '5790');
        AddMapElement('995795', '493');
        AddMapElement('995796', '493010');
        AddMapElement('995797', '493020');
        AddMapElement('995799', '5799');
        AddMapElement('995800', '453');
        AddMapElement('995810', '453000');
        AddMapElement('995820', '459000');
        AddMapElement('995830', '454000');
        AddMapElement('995840', '456000');
        AddMapElement('995850', '457000');
        AddMapElement('995890', '5890');
        AddMapElement('995900', '45');
        AddMapElement('995910', '471000');
        AddMapElement('995920', '452000');
        AddMapElement('995990', '5990');
        AddMapElement('995995', '5995');
        AddMapElement('995997', '5997');
        AddMapElement('995999', '5999');
        AddMapElement('996000', '6000');
        AddMapElement('996100', '70');
        AddMapElement('996105', '700');
        AddMapElement('996110', '700000');
        AddMapElement('996120', '700010');
        AddMapElement('996130', '700020');
        AddMapElement('996190', '742000');
        AddMapElement('996191', '742000');
        AddMapElement('996195', '6195');
        AddMapElement('996205', '701');
        AddMapElement('996210', '701000');
        AddMapElement('996220', '701010');
        AddMapElement('996230', '701020');
        AddMapElement('996290', '742010');
        AddMapElement('996291', '742010');
        AddMapElement('996295', '6295');
        AddMapElement('996405', '702');
        AddMapElement('996410', '702000');
        AddMapElement('996420', '702010');
        AddMapElement('996430', '702020');
        AddMapElement('996490', '742020');
        AddMapElement('996491', '742020');
        AddMapElement('996495', '6495');
        AddMapElement('996605', '74');
        AddMapElement('996610', '703010');
        AddMapElement('996620', '703000');
        AddMapElement('996695', '6695');
        AddMapElement('996710', '704000');
        AddMapElement('996810', '704000');
        AddMapElement('996910', '753000');
        AddMapElement('996950', '705');
        AddMapElement('996955', '705000');
        AddMapElement('996959', '6959');
        AddMapElement('996995', '79');
        AddMapElement('997100', '6');
        AddMapElement('997105', '604');
        AddMapElement('997110', '604000');
        AddMapElement('997120', '604010');
        AddMapElement('997130', '604020');
        AddMapElement('997140', '608400');
        AddMapElement('997150', '613930');
        AddMapElement('997170', '609170');
        AddMapElement('997180', '609180');
        AddMapElement('997181', '609180');
        AddMapElement('997190', '613395');
        AddMapElement('997195', '7195');
        AddMapElement('997205', '600');
        AddMapElement('997210', '600000');
        AddMapElement('997220', '600010');
        AddMapElement('997230', '600020');
        AddMapElement('997240', '608000');
        AddMapElement('997250', '613935');
        AddMapElement('997270', '609270');
        AddMapElement('997280', '609280');
        AddMapElement('997281', '609280');
        AddMapElement('997290', '613392');
        AddMapElement('997295', '7295');
        AddMapElement('997405', '602');
        AddMapElement('997480', '609480');
        AddMapElement('997481', '609480');
        AddMapElement('997490', '602000');
        AddMapElement('997495', '7495');
        AddMapElement('997620', '602010');
        AddMapElement('997995', '69');
        AddMapElement('998000', '61');
        AddMapElement('998100', '8100');
        AddMapElement('998110', '611400');
        AddMapElement('998120', '612000');
        AddMapElement('998130', '611000');
        AddMapElement('998190', '8190');
        AddMapElement('998200', '8200');
        AddMapElement('998210', '612500');
        AddMapElement('998230', '612200');
        AddMapElement('998240', '612400');
        AddMapElement('998290', '8290');
        AddMapElement('998300', '6126');
        AddMapElement('998310', '612600');
        AddMapElement('998320', '612610');
        AddMapElement('998330', '612620');
        AddMapElement('998390', '8390');
        AddMapElement('998400', '8400');
        AddMapElement('998410', '614000');
        AddMapElement('998420', '614500');
        AddMapElement('998430', '613900');
        AddMapElement('998450', '613930');
        AddMapElement('998490', '8490');
        AddMapElement('998500', '8500');
        AddMapElement('998510', '612120');
        AddMapElement('998520', '640100');
        AddMapElement('998530', '611300');
        AddMapElement('998590', '8590');
        AddMapElement('998600', '64');
        AddMapElement('998610', '650000');
        AddMapElement('998620', '613310');
        AddMapElement('998630', '613230');
        AddMapElement('998640', '643000');
        AddMapElement('998690', '8690');
        AddMapElement('998695', '8695');
        AddMapElement('998700', '69');
        AddMapElement('998710', '620300');
        AddMapElement('998720', '620200');
        AddMapElement('998730', '624000');
        AddMapElement('998740', '623000');
        AddMapElement('998750', '621000');
        AddMapElement('998790', '7');
        AddMapElement('998800', '63');
        AddMapElement('998810', '630200');
        AddMapElement('998820', '630210');
        AddMapElement('998830', '630220');
        AddMapElement('998840', '663000');
        AddMapElement('998890', '8890');
        AddMapElement('998910', '643000');
        AddMapElement('998995', '8995');
        AddMapElement('999100', '75');
        AddMapElement('999110', '750100');
        AddMapElement('999120', '756200');
        AddMapElement('999130', '753000');
        AddMapElement('999135', '753000');
        AddMapElement('999140', '754200');
        AddMapElement('999150', '755000');
        AddMapElement('999160', '655000');
        AddMapElement('999170', '655000');
        AddMapElement('999190', '9190');
        AddMapElement('999200', '65');
        AddMapElement('999210', '650010');
        AddMapElement('999220', '650000');
        AddMapElement('999230', '650020');
        AddMapElement('999240', '640200');
        AddMapElement('999250', '653000');
        AddMapElement('999255', '653000');
        AddMapElement('999260', '655000');
        AddMapElement('999270', '655000');
        AddMapElement('999290', '9290');
        AddMapElement('999310', '754000');
        AddMapElement('999320', '654000');
        AddMapElement('999330', '754100');
        AddMapElement('999340', '654100');
        AddMapElement('999350', '754100');
        AddMapElement('999360', '654100');
        AddMapElement('999395', '9395');
        AddMapElement('999410', '760000');
        AddMapElement('999420', '660000');
        AddMapElement('999495', '9495');
        AddMapElement('999510', '670000');
        AddMapElement('999999', '8');
        AddMapElement('997191', '609191');
        AddMapElement('997192', '609192');
        AddMapElement('997193', '609193');
        AddMapElement('997291', '609291');
        AddMapElement('997292', '609292');
        AddMapElement('997293', '609293');
        AddMapElement('997705', '609705');
        AddMapElement('997710', '609710');
        AddMapElement('997791', '609791');
        AddMapElement('997792', '609792');
        AddMapElement('997793', '609793');
        AddMapElement('997795', '609795');
        AddMapElement('997805', '609805');
        AddMapElement('997890', '609890');
        AddMapElement('997891', '609891');
        AddMapElement('997892', '609892');
        AddMapElement('997893', '609893');
        AddMapElement('997894', '609894');
        AddMapElement('997895', '609895');
        AddMapElement('992140', '330100');
        AddMapElement('995520', '411000');
        AddMapElement('998841', '663000');
        AddMapElement('997171', '609171');
        AddMapElement('997271', '609271');
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

