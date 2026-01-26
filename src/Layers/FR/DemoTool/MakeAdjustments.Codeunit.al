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
        AddMapElement('6110', '707100');
        AddMapElement('6120', '707200');
        AddMapElement('6130', '707900');
        AddMapElement('6910', '709000');
        AddMapElement('7110', '607100');
        AddMapElement('7120', '607200');
        AddMapElement('7130', '607900');
        AddMapElement('7140', '609700');
        AddMapElement('991000', '100000');
        AddMapElement('991002', '100002');
        AddMapElement('991003', '200002');
        AddMapElement('991110', '213100');
        AddMapElement('991120', '201000');
        AddMapElement('991130', '203000');
        AddMapElement('991140', '281300');
        AddMapElement('991210', '215000');
        AddMapElement('991220', '206000');
        AddMapElement('991230', '207000');
        AddMapElement('991240', '281500');
        AddMapElement('991310', '218200');
        AddMapElement('991320', '208000');
        AddMapElement('991330', '211000');
        AddMapElement('991340', '281820');
        AddMapElement('991999', '299990');
        AddMapElement('992000', '300000');
        AddMapElement('992100', '300002');
        AddMapElement('992110', '370000');
        AddMapElement('992111', '378000');
        AddMapElement('992112', '603728');
        AddMapElement('992120', '350000');
        AddMapElement('992121', '358000');
        AddMapElement('992130', '310000');
        AddMapElement('992131', '318000');
        AddMapElement('992132', '603128');
        AddMapElement('992140', '331000');
        AddMapElement('992180', '320000');
        AddMapElement('992190', '399990');
        AddMapElement('992210', '335100');
        AddMapElement('992211', '335100');
        AddMapElement('992212', '345200');
        AddMapElement('992220', '335900');
        AddMapElement('992230', '345000');
        AddMapElement('992231', '335100');
        AddMapElement('992232', '486100');
        AddMapElement('992240', '345999');
        AddMapElement('992300', '410002');
        AddMapElement('992310', '411100');
        AddMapElement('992320', '411900');
        AddMapElement('992330', '418800');
        AddMapElement('992340', '467000');
        AddMapElement('992390', '419990');
        AddMapElement('992400', '409100');
        AddMapElement('992410', '409110');
        AddMapElement('992420', '409120');
        AddMapElement('992430', '409130');
        AddMapElement('992440', '409199');
        AddMapElement('992800', '500003');
        AddMapElement('992810', '506000');
        AddMapElement('992890', '509990');
        AddMapElement('992900', '511001');
        AddMapElement('992910', '531000');
        AddMapElement('992920', '512100');
        AddMapElement('992930', '512400');
        AddMapElement('992940', '514000');
        AddMapElement('992990', '519990');
        AddMapElement('992995', '599950');
        AddMapElement('992999', '199990');
        AddMapElement('993100', '100003');
        AddMapElement('993110', '101000');
        AddMapElement('993120', '106000');
        AddMapElement('993195', '120000');
        AddMapElement('993199', '149990');
        AddMapElement('994000', '400002');
        AddMapElement('994010', '155000');
        AddMapElement('994999', '499990');
        AddMapElement('995000', '160003');
        AddMapElement('995110', '164100');
        AddMapElement('995120', '164400');
        AddMapElement('995310', '512200');
        AddMapElement('995350', '419100');
        AddMapElement('995360', '419110');
        AddMapElement('995370', '419120');
        AddMapElement('995380', '419130');
        AddMapElement('995390', '419199');
        AddMapElement('995400', '400003');
        AddMapElement('995410', '401100');
        AddMapElement('995420', '401900');
        AddMapElement('995490', '409990');
        AddMapElement('995500', '5500');
        AddMapElement('995510', '603718');
        AddMapElement('995530', '603118');
        AddMapElement('995590', '5590');
        AddMapElement('995600', '440002');
        AddMapElement('995610', '445711');
        AddMapElement('995611', '445712');
        AddMapElement('995612', '5612');
        AddMapElement('995615', '5615');
        AddMapElement('995616', '5616');
        AddMapElement('995620', '445210');
        AddMapElement('995621', '445220');
        AddMapElement('995622', '5622');
        AddMapElement('995625', '5625');
        AddMapElement('995626', '5626');
        AddMapElement('995630', '445661');
        AddMapElement('995631', '445662');
        AddMapElement('995632', '5632');
        AddMapElement('995635', '5635');
        AddMapElement('995636', '5636');
        AddMapElement('995710', '447100');
        AddMapElement('995720', '448200');
        AddMapElement('995730', '445620');
        AddMapElement('995740', '445670');
        AddMapElement('995750', '447200');
        AddMapElement('995760', '446100');
        AddMapElement('995780', '445510');
        AddMapElement('995790', '449990');
        AddMapElement('995795', '487500');
        AddMapElement('995796', '487700');
        AddMapElement('995797', '487800');
        AddMapElement('995799', '487999');
        AddMapElement('995800', '420002');
        AddMapElement('995810', '441000');
        AddMapElement('995820', '205000');
        AddMapElement('995830', '431000');
        AddMapElement('995840', '438200');
        AddMapElement('995850', '438300');
        AddMapElement('995890', '439990');
        AddMapElement('995900', '450002');
        AddMapElement('995910', '457000');
        AddMapElement('995920', '444000');
        AddMapElement('995990', '459990');
        AddMapElement('995997', '169990');
        AddMapElement('995999', '599990');
        AddMapElement('996000', '600000');
        AddMapElement('996100', '700002');
        AddMapElement('996105', '700003');
        AddMapElement('996110', '707100');
        AddMapElement('996120', '707200');
        AddMapElement('996130', '707900');
        AddMapElement('996190', '704700');
        AddMapElement('996191', '713451');
        AddMapElement('996195', '709990');
        AddMapElement('996205', '710002');
        AddMapElement('996210', '702100');
        AddMapElement('996220', '702200');
        AddMapElement('996230', '702900');
        AddMapElement('996290', '704100');
        AddMapElement('996291', '713452');
        AddMapElement('996295', '719990');
        AddMapElement('996410', '706100');
        AddMapElement('996420', '706200');
        AddMapElement('996430', '706900');
        AddMapElement('996490', '704300');
        AddMapElement('996491', '713453');
        AddMapElement('996495', '6495');
        AddMapElement('996610', '713480');
        AddMapElement('996620', '713450');
        AddMapElement('996710', '705000');
        AddMapElement('996810', '708000');
        AddMapElement('996820', '708010');
        AddMapElement('996910', '709000');
        AddMapElement('996950', '706500');
        AddMapElement('996955', '706550');
        AddMapElement('996959', '706999');
        AddMapElement('996995', '799990');
        AddMapElement('997100', '600002');
        AddMapElement('997105', '600003');
        AddMapElement('997110', '607100');
        AddMapElement('997120', '607200');
        AddMapElement('997130', '607900');
        AddMapElement('997140', '609700');
        AddMapElement('997150', '608700');
        AddMapElement('997170', '603710');
        AddMapElement('997180', '713550');
        AddMapElement('997181', '713491');
        AddMapElement('997190', '603720');
        AddMapElement('997191', '904000');
        AddMapElement('997192', '905000');
        AddMapElement('997193', '960000');
        AddMapElement('997195', '609990');
        AddMapElement('997210', '601100');
        AddMapElement('997220', '601200');
        AddMapElement('997230', '601900');
        AddMapElement('997240', '609100');
        AddMapElement('997250', '608100');
        AddMapElement('997270', '603110');
        AddMapElement('997280', '713510');
        AddMapElement('997281', '713492');
        AddMapElement('997290', '603120');
        AddMapElement('997291', '904100');
        AddMapElement('997292', '905100');
        AddMapElement('997293', '961000');
        AddMapElement('997480', '713560');
        AddMapElement('997481', '713493');
        AddMapElement('997490', '713590');
        AddMapElement('997620', '713490');
        AddMapElement('997705', '713300');
        AddMapElement('997710', '713310');
        AddMapElement('997791', '904300');
        AddMapElement('997792', '905300');
        AddMapElement('997793', '961300');
        AddMapElement('997795', '713399');
        AddMapElement('997805', '963000');
        AddMapElement('997890', '963100');
        AddMapElement('997891', '963200');
        AddMapElement('997892', '963300');
        AddMapElement('997893', '963400');
        AddMapElement('997894', '963500');
        AddMapElement('997895', '963999');
        AddMapElement('997995', '699990');
        AddMapElement('998100', '610002');
        AddMapElement('998110', '613200');
        AddMapElement('998120', '606100');
        AddMapElement('998130', '615200');
        AddMapElement('998190', '619990');
        AddMapElement('998200', '630002');
        AddMapElement('998210', '602250');
        AddMapElement('998230', '626200');
        AddMapElement('998240', '626100');
        AddMapElement('998290', '639990');
        AddMapElement('998300', '670002');
        AddMapElement('998310', '618300');
        AddMapElement('998320', '622600');
        AddMapElement('998330', '628100');
        AddMapElement('998390', '679990');
        AddMapElement('998400', '620002');
        AddMapElement('998410', '623000');
        AddMapElement('998420', '625700');
        AddMapElement('998430', '625100');
        AddMapElement('998450', '608100');
        AddMapElement('998490', '629990');
        AddMapElement('998510', '602210');
        AddMapElement('998520', '635400');
        AddMapElement('998530', '615500');
        AddMapElement('998610', '668000');
        AddMapElement('998620', '671400');
        AddMapElement('998630', '622700');
        AddMapElement('998640', '658000');
        AddMapElement('998695', '609990');
        AddMapElement('998700', '640002');
        AddMapElement('998710', '641120');
        AddMapElement('998720', '641110');
        AddMapElement('998730', '645300');
        AddMapElement('998740', '641200');
        AddMapElement('998750', '645100');
        AddMapElement('998790', '649990');
        AddMapElement('998800', '680002');
        AddMapElement('998810', '681121');
        AddMapElement('998820', '681122');
        AddMapElement('998830', '681123');
        AddMapElement('998890', '689990');
        AddMapElement('998910', '618000');
        AddMapElement('998995', '699990');
        AddMapElement('999100', '760002');
        AddMapElement('999110', '768000');
        AddMapElement('999120', '763000');
        AddMapElement('999130', '765000');
        AddMapElement('999135', '765000');
        AddMapElement('999140', '709100');
        AddMapElement('999150', '766500');
        AddMapElement('999160', '758600');
        AddMapElement('999170', '658600');
        AddMapElement('999190', '769990');
        AddMapElement('999200', '660002');
        AddMapElement('999210', '661600');
        AddMapElement('999220', '661160');
        AddMapElement('999230', '661700');
        AddMapElement('999240', '661800');
        AddMapElement('999250', '665000');
        AddMapElement('999255', '665000');
        AddMapElement('999260', '658700');
        AddMapElement('999270', '758700');
        AddMapElement('999290', '669990');
        AddMapElement('999310', '477000');
        AddMapElement('999320', '476000');
        AddMapElement('999330', '766100');
        AddMapElement('999340', '666100');
        AddMapElement('999350', '477600');
        AddMapElement('999360', '476600');
        AddMapElement('999395', '9395');
        AddMapElement('999410', '778800');
        AddMapElement('999420', '678800');
        AddMapElement('999495', '6495');
        AddMapElement('999510', '695000');
        AddMapElement('999999', '889990');
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

