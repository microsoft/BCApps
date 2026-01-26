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
        AddMapElement('991110', '0090');
        AddMapElement('991120', '0065');
        AddMapElement('991130', '1130');
        AddMapElement('991140', '0090');
        AddMapElement('991190', '1190');
        AddMapElement('991200', '1200');
        AddMapElement('991210', '0210');
        AddMapElement('991220', '0280');
        AddMapElement('991230', '0210');
        AddMapElement('991240', '0210');
        AddMapElement('991290', '1290');
        AddMapElement('991300', '1300');
        AddMapElement('991310', '0320');
        AddMapElement('991320', '0320');
        AddMapElement('991330', '0320');
        AddMapElement('991340', '0320');
        AddMapElement('991390', '1390');
        AddMapElement('991395', '1395');
        AddMapElement('991780', '1780');
        AddMapElement('991999', '1999');
        AddMapElement('992000', '2000');
        AddMapElement('992100', '2100');
        AddMapElement('992110', '3981');
        AddMapElement('992111', '3984');
        AddMapElement('992112', '3984');
        AddMapElement('992120', '3982');
        AddMapElement('992121', '3985');
        AddMapElement('992130', '3983');
        AddMapElement('992131', '3986');
        AddMapElement('992132', '3986');
        AddMapElement('992180', '3970');
        AddMapElement('992190', '3987');
        AddMapElement('992200', '2200');
        AddMapElement('992210', '3976');
        AddMapElement('992211', '3976');
        AddMapElement('992212', '3976');
        AddMapElement('992220', '3975');
        AddMapElement('992230', '2230');
        AddMapElement('992231', '3975');
        AddMapElement('992232', '3975');
        AddMapElement('992240', '2240');
        AddMapElement('992290', '2290');
        AddMapElement('992300', '2300');
        AddMapElement('992310', '1401');
        AddMapElement('992320', '1402');
        AddMapElement('992325', '1403');
        AddMapElement('992330', '1451');
        AddMapElement('992340', '1461');
        AddMapElement('992390', '1499');
        AddMapElement('992400', '2400');
        AddMapElement('992410', '1517');
        AddMapElement('992420', '1511');
        AddMapElement('992430', '1517');
        AddMapElement('992440', '2440');
        AddMapElement('992800', '2800');
        AddMapElement('992810', '0530');
        AddMapElement('992890', '1509');
        AddMapElement('992900', '2900');
        AddMapElement('992910', '1005');
        AddMapElement('992920', '1210');
        AddMapElement('992930', '1230');
        AddMapElement('992940', '1220');
        AddMapElement('992990', '2990');
        AddMapElement('992995', '2995');
        AddMapElement('992999', '2999');
        AddMapElement('993000', '3000');
        AddMapElement('993100', '3100');
        AddMapElement('993110', '0800');
        AddMapElement('993120', '0846');
        AddMapElement('993195', '3195');
        AddMapElement('993199', '3199');
        AddMapElement('994000', '4000');
        AddMapElement('994010', '0955');
        AddMapElement('994999', '4999');
        AddMapElement('995000', '5000');
        AddMapElement('995100', '5100');
        AddMapElement('995110', '0640');
        AddMapElement('995120', '0650');
        AddMapElement('995290', '5290');
        AddMapElement('995300', '5300');
        AddMapElement('995310', '1290');
        AddMapElement('995350', '5350');
        AddMapElement('995360', '1717');
        AddMapElement('995370', '1711');
        AddMapElement('995380', '1717');
        AddMapElement('995390', '5390');
        AddMapElement('995400', '5400');
        AddMapElement('995410', '1601');
        AddMapElement('995420', '1602');
        AddMapElement('995425', '1603');
        AddMapElement('995490', '1659');
        AddMapElement('995500', '5500');
        AddMapElement('995510', '');
        AddMapElement('995530', '');
        AddMapElement('995590', '5590');
        AddMapElement('995600', '5600');
        AddMapElement('995610', '1775');
        AddMapElement('995611', '1771');
        AddMapElement('995612', '');
        AddMapElement('995615', '');
        AddMapElement('995616', '5616');
        AddMapElement('995620', '1773');
        AddMapElement('995621', '1784');
        AddMapElement('995622', '5622');
        AddMapElement('995625', '1573');
        AddMapElement('995626', '1572');
        AddMapElement('995629', '1588');
        AddMapElement('995630', '1575');
        AddMapElement('995631', '1571');
        AddMapElement('995632', '5632');
        AddMapElement('995635', '5635');
        AddMapElement('995636', '5636');
        AddMapElement('995710', '4500');
        AddMapElement('995720', '4510');
        AddMapElement('995730', '4520');
        AddMapElement('995740', '4540');
        AddMapElement('995750', '4530');
        AddMapElement('995760', '4560');
        AddMapElement('995780', '1780');
        AddMapElement('995790', '1798');
        AddMapElement('995795', '5795');
        AddMapElement('995796', '5796');
        AddMapElement('995797', '5797');
        AddMapElement('995799', '5799');
        AddMapElement('995800', '5800');
        AddMapElement('995810', '4110');
        AddMapElement('995820', '4120');
        AddMapElement('995830', '4130');
        AddMapElement('995840', '4140');
        AddMapElement('995850', '4150');
        AddMapElement('995890', '4198');
        AddMapElement('995900', '5900');
        AddMapElement('995910', '5910');
        AddMapElement('995920', '2200');
        AddMapElement('995990', '5990');
        AddMapElement('995995', '5995');
        AddMapElement('995997', '5997');
        AddMapElement('995999', '5999');
        AddMapElement('996000', '6000');
        AddMapElement('996100', '8000');
        AddMapElement('996105', '6105');
        AddMapElement('996110', '8400');
        AddMapElement('996120', '8315');
        AddMapElement('996130', '8120');
        AddMapElement('996190', '8451');
        AddMapElement('996191', '8451');
        AddMapElement('996195', '8550');
        AddMapElement('996205', '6205');
        AddMapElement('996210', '8400');
        AddMapElement('996220', '8315');
        AddMapElement('996230', '8120');
        AddMapElement('996290', '');
        AddMapElement('996291', '6291');
        AddMapElement('996295', '6295');
        AddMapElement('996405', '6405');
        AddMapElement('996410', '8400');
        AddMapElement('996420', '8315');
        AddMapElement('996430', '8120');
        AddMapElement('996490', '');
        AddMapElement('996491', '6491');
        AddMapElement('996495', '6495');
        AddMapElement('996605', '6605');
        AddMapElement('996610', '8452');
        AddMapElement('996620', '8451');
        AddMapElement('996695', '6695');
        AddMapElement('996710', '4950');
        AddMapElement('996810', '8650');
        AddMapElement('996820', '8655');
        AddMapElement('996910', '8791');
        AddMapElement('996950', '6950');
        AddMapElement('996955', '6955');
        AddMapElement('996959', '6959');
        AddMapElement('996995', '8550');
        AddMapElement('997100', '5000');
        AddMapElement('997105', '7105');
        AddMapElement('997110', '3400');
        AddMapElement('997120', '3425');
        AddMapElement('997130', '3559');
        AddMapElement('997140', '3790');
        AddMapElement('997150', '4945');
        AddMapElement('997170', '3960');
        AddMapElement('997180', '5002');
        AddMapElement('997181', '5002');
        AddMapElement('997190', '4090');
        AddMapElement('997191', '4091');
        AddMapElement('997192', '4092');
        AddMapElement('997193', '4093');
        AddMapElement('997195', '7195');
        AddMapElement('997205', '7205');
        AddMapElement('997210', '3400');
        AddMapElement('997220', '3425');
        AddMapElement('997230', '3559');
        AddMapElement('997240', '3726');
        AddMapElement('997250', '4945');
        AddMapElement('997270', '3960');
        AddMapElement('997280', '');
        AddMapElement('997281', '7281');
        AddMapElement('997290', '4090');
        AddMapElement('997291', '4091');
        AddMapElement('997292', '4092');
        AddMapElement('997293', '4093');
        AddMapElement('997295', '7295');
        AddMapElement('997405', '7405');
        AddMapElement('997480', '');
        AddMapElement('997481', '7481');
        AddMapElement('997490', '7490');
        AddMapElement('997495', '7495');
        AddMapElement('997620', '5002');
        AddMapElement('997791', '4091');
        AddMapElement('997792', '4092');
        AddMapElement('997793', '4093');
        AddMapElement('997995', '5999');
        AddMapElement('998000', '8000');
        AddMapElement('998100', '8100');
        AddMapElement('998110', '4250');
        AddMapElement('998120', '4240');
        AddMapElement('998130', '4260');
        AddMapElement('998190', '8190');
        AddMapElement('998200', '8200');
        AddMapElement('998210', '4930');
        AddMapElement('998230', '4920');
        AddMapElement('998240', '4910');
        AddMapElement('998290', '8290');
        AddMapElement('998300', '8300');
        AddMapElement('998310', '4940');
        AddMapElement('998320', '4950');
        AddMapElement('998330', '4945');
        AddMapElement('998390', '8390');
        AddMapElement('998400', '8400');
        AddMapElement('998410', '4635');
        AddMapElement('998420', '4610');
        AddMapElement('998430', '4660');
        AddMapElement('998450', '4670');
        AddMapElement('998490', '8490');
        AddMapElement('998500', '8500');
        AddMapElement('998510', '4580');
        AddMapElement('998520', '4570');
        AddMapElement('998530', '4540');
        AddMapElement('998590', '8590');
        AddMapElement('998600', '8600');
        AddMapElement('998610', '4970');
        AddMapElement('998620', '4965');
        AddMapElement('998630', '4957');
        AddMapElement('998640', '4985');
        AddMapElement('998690', '8690');
        AddMapElement('998695', '8695');
        AddMapElement('998700', '8700');
        AddMapElement('998710', '4110');
        AddMapElement('998720', '4124');
        AddMapElement('998730', '4130');
        AddMapElement('998740', '4138');
        AddMapElement('998750', '4150');
        AddMapElement('998790', '8790');
        AddMapElement('998800', '8800');
        AddMapElement('998810', '4830');
        AddMapElement('998820', '4830');
        AddMapElement('998830', '4830');
        AddMapElement('998840', '2720');
        AddMapElement('998890', '8890');
        AddMapElement('998910', '3800');
        AddMapElement('998995', '8995');
        AddMapElement('999100', '9100');
        AddMapElement('999110', '8650');
        AddMapElement('999120', '2650');
        AddMapElement('999130', '3736');
        AddMapElement('999135', '3736');
        AddMapElement('999140', '2000');
        AddMapElement('999150', '2167');
        AddMapElement('999160', '3734');
        AddMapElement('999170', '3734');
        AddMapElement('999190', '9190');
        AddMapElement('999200', '9200');
        AddMapElement('999210', '2107');
        AddMapElement('999220', '2108');
        AddMapElement('999230', '2109');
        AddMapElement('999240', '2110');
        AddMapElement('999250', '8733');
        AddMapElement('999255', '8733');
        AddMapElement('999260', '8734');
        AddMapElement('999270', '8735');
        AddMapElement('999290', '9290');
        AddMapElement('999310', '2660');
        AddMapElement('999320', '2150');
        AddMapElement('999330', '2662');
        AddMapElement('999340', '2160');
        AddMapElement('999350', '2662');
        AddMapElement('999360', '2160');
        AddMapElement('999395', '9395');
        AddMapElement('999410', '9410');
        AddMapElement('999420', '2000');
        AddMapElement('999495', '9495');
        AddMapElement('999510', '2200');
        AddMapElement('999999', '9999');
        AddMapElement('997705', '7705');
        AddMapElement('997710', '7710');
        AddMapElement('997795', '7795');
        AddMapElement('997805', '7805');
        AddMapElement('997890', '5090');
        AddMapElement('997891', '5091');
        AddMapElement('997892', '5092');
        AddMapElement('997893', '5093');
        AddMapElement('997894', '5094');
        AddMapElement('997895', '7895');
        AddMapElement('992140', '7050');
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

