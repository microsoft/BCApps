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
        AddMapElement('991110', '0210');
        AddMapElement('991120', '0230');
        AddMapElement('991130', '1130');
        AddMapElement('991140', '0290');
        AddMapElement('991190', '1190');
        AddMapElement('991200', '1200');
        AddMapElement('991210', '0500');
        AddMapElement('991220', '0530');
        AddMapElement('991230', '0540');
        AddMapElement('991240', '0550');
        AddMapElement('991290', '1290');
        AddMapElement('991300', '1300');
        AddMapElement('991310', '0640');
        AddMapElement('991320', '0650');
        AddMapElement('991330', '0660');
        AddMapElement('991340', '0670');
        AddMapElement('991390', '1390');
        AddMapElement('991395', '1395');
        AddMapElement('991780', '3550');
        AddMapElement('991999', '1999');
        AddMapElement('992000', '2000');
        AddMapElement('992100', '2100');
        AddMapElement('992110', '1610');
        AddMapElement('992111', '1620');
        AddMapElement('992112', '1630');
        AddMapElement('992120', '1510');
        AddMapElement('992121', '1520');
        AddMapElement('992130', '1110');
        AddMapElement('992131', '1120');
        AddMapElement('992132', '1130');
        AddMapElement('992140', '1410');
        AddMapElement('992180', '1020');
        AddMapElement('992190', '1998');
        AddMapElement('992200', '2200');
        AddMapElement('992210', '2210');
        AddMapElement('992211', '1430');
        AddMapElement('992212', '1431');
        AddMapElement('992220', '1420');
        AddMapElement('992230', '2230');
        AddMapElement('992231', '1420');
        AddMapElement('992232', '1421');
        AddMapElement('992240', '2240');
        AddMapElement('992290', '2290');
        AddMapElement('992300', '2300');
        AddMapElement('992310', '2010');
        AddMapElement('992320', '2020');
        AddMapElement('992325', '2030');
        AddMapElement('992330', '4320');
        AddMapElement('992340', '2300');
        AddMapElement('992390', '2499');
        AddMapElement('992400', '2400');
        AddMapElement('992410', '2390');
        AddMapElement('992420', '2390');
        AddMapElement('992430', '2390');
        AddMapElement('992440', '2440');
        AddMapElement('992800', '2800');
        AddMapElement('992810', '0910');
        AddMapElement('992890', '2699');
        AddMapElement('992900', '2900');
        AddMapElement('992910', '2710');
        AddMapElement('992920', '2800');
        AddMapElement('992930', '2810');
        AddMapElement('992940', '2820');
        AddMapElement('992990', '2899');
        AddMapElement('992995', '2995');
        AddMapElement('992999', '2999');
        AddMapElement('993000', '3000');
        AddMapElement('993100', '3100');
        AddMapElement('993110', '9010');
        AddMapElement('993120', '9350');
        AddMapElement('993195', '3195');
        AddMapElement('993199', '3199');
        AddMapElement('994000', '4000');
        AddMapElement('994010', '9020');
        AddMapElement('994999', '4999');
        AddMapElement('995000', '5000');
        AddMapElement('995100', '5100');
        AddMapElement('995110', '3150');
        AddMapElement('995120', '3160');
        AddMapElement('995290', '5290');
        AddMapElement('995300', '5300');
        AddMapElement('995310', '2820');
        AddMapElement('995350', '5350');
        AddMapElement('995360', '3210');
        AddMapElement('995370', '3210');
        AddMapElement('995380', '3210');
        AddMapElement('995390', '5390');
        AddMapElement('995400', '5400');
        AddMapElement('995410', '3310');
        AddMapElement('995420', '3320');
        AddMapElement('995425', '3330');
        AddMapElement('995490', '3499');
        AddMapElement('995500', '5500');
        AddMapElement('995510', '5510');
        AddMapElement('995530', '5530');
        AddMapElement('995590', '5590');
        AddMapElement('995600', '5600');
        AddMapElement('995610', '3520');
        AddMapElement('995611', '3510');
        AddMapElement('995612', '5612');
        AddMapElement('995615', '5615');
        AddMapElement('995616', '5616');
        AddMapElement('995620', '3540');
        AddMapElement('995621', '3530');
        AddMapElement('995625', '2540');
        AddMapElement('995626', '2530');
        AddMapElement('995629', '2550');
        AddMapElement('995630', '2520');
        AddMapElement('995631', '2510');
        AddMapElement('995632', '5632');
        AddMapElement('995635', '5635');
        AddMapElement('995636', '5636');
        AddMapElement('995710', '7110');
        AddMapElement('995720', '7120');
        AddMapElement('995730', '7130');
        AddMapElement('995740', '7140');
        AddMapElement('995750', '7150');
        AddMapElement('995760', '7160');
        AddMapElement('995780', '7160');
        AddMapElement('995790', '3599');
        AddMapElement('995795', '5795');
        AddMapElement('995796', '5796');
        AddMapElement('995797', '5797');
        AddMapElement('995798', '5798');
        AddMapElement('995799', '5799');
        AddMapElement('995800', '5800');
        AddMapElement('995810', '3640');
        AddMapElement('995820', '3650');
        AddMapElement('995830', '3660');
        AddMapElement('995840', '3670');
        AddMapElement('995850', '3680');
        AddMapElement('995890', '3699');
        AddMapElement('995900', '5900');
        AddMapElement('995910', '5910');
        AddMapElement('995920', '3710');
        AddMapElement('995990', '3997');
        AddMapElement('995995', '5995');
        AddMapElement('995997', '5997');
        AddMapElement('995999', '5999');
        AddMapElement('996000', '6000');
        AddMapElement('996100', '4000');
        AddMapElement('996105', '6105');
        AddMapElement('996110', '4010');
        AddMapElement('996120', '4030');
        AddMapElement('996130', '4020');
        AddMapElement('996190', '4040');
        AddMapElement('996191', '4050');
        AddMapElement('996195', '4099');
        AddMapElement('996205', '6205');
        AddMapElement('996210', '4110');
        AddMapElement('996220', '4130');
        AddMapElement('996230', '4120');
        AddMapElement('996290', '');
        AddMapElement('996291', '6291');
        AddMapElement('996295', '6295');
        AddMapElement('996405', '6405');
        AddMapElement('996410', '4210');
        AddMapElement('996420', '4230');
        AddMapElement('996430', '4220');
        AddMapElement('996490', '');
        AddMapElement('996491', '6491');
        AddMapElement('996495', '6495');
        AddMapElement('996605', '6605');
        AddMapElement('996610', '4260');
        AddMapElement('996620', '4250');
        AddMapElement('996695', '6695');
        AddMapElement('996710', '4330');
        AddMapElement('996810', '4310');
        AddMapElement('996820', '4315');
        AddMapElement('996910', '8340');
        AddMapElement('996950', '6950');
        AddMapElement('996955', '6955');
        AddMapElement('996959', '6959');
        AddMapElement('996995', '4998');
        AddMapElement('997100', '5000');
        AddMapElement('997105', '7105');
        AddMapElement('997110', '5510');
        AddMapElement('997120', '5530');
        AddMapElement('997130', '5520');
        AddMapElement('997140', '5050');
        AddMapElement('997150', '5060');
        AddMapElement('997170', '5020');
        AddMapElement('997180', '5270');
        AddMapElement('997181', '5280');
        AddMapElement('997190', '5010');
        AddMapElement('997191', '5030');
        AddMapElement('997192', '5040');
        AddMapElement('997193', '5045');
        AddMapElement('997195', '7195');
        AddMapElement('997205', '7205');
        AddMapElement('997210', '5540');
        AddMapElement('997220', '5560');
        AddMapElement('997230', '5550');
        AddMapElement('997240', '5070');
        AddMapElement('997250', '5080');
        AddMapElement('997270', '5120');
        AddMapElement('997280', '7280');
        AddMapElement('997281', '7281');
        AddMapElement('997290', '5110');
        AddMapElement('997291', '5130');
        AddMapElement('997292', '5140');
        AddMapElement('997293', '5145');
        AddMapElement('997295', '7295');
        AddMapElement('997405', '7405');
        AddMapElement('997480', '');
        AddMapElement('997481', '7481');
        AddMapElement('997490', '7490');
        AddMapElement('997495', '7495');
        AddMapElement('997620', '5260');
        AddMapElement('997791', '5230');
        AddMapElement('997792', '5240');
        AddMapElement('997793', '5245');
        AddMapElement('997890', '5310');
        AddMapElement('997891', '5320');
        AddMapElement('997892', '5330');
        AddMapElement('997893', '5340');
        AddMapElement('997894', '5350');
        AddMapElement('997995', '5998');
        AddMapElement('998000', '8000');
        AddMapElement('998100', '8100');
        AddMapElement('998110', '7220');
        AddMapElement('998120', '7230');
        AddMapElement('998130', '7210');
        AddMapElement('998190', '8190');
        AddMapElement('998200', '8200');
        AddMapElement('998210', '7610');
        AddMapElement('998230', '7630');
        AddMapElement('998240', '7620');
        AddMapElement('998290', '8290');
        AddMapElement('998300', '8300');
        AddMapElement('998310', '7635');
        AddMapElement('998320', '7636');
        AddMapElement('998330', '7637');
        AddMapElement('998390', '8390');
        AddMapElement('998400', '8400');
        AddMapElement('998410', '7650');
        AddMapElement('998420', '7650');
        AddMapElement('998430', '7660');
        AddMapElement('998450', '7680');
        AddMapElement('998490', '8490');
        AddMapElement('998500', '8500');
        AddMapElement('998510', '7280');
        AddMapElement('998520', '7240');
        AddMapElement('998530', '7270');
        AddMapElement('998590', '8590');
        AddMapElement('998600', '8600');
        AddMapElement('998610', '7710');
        AddMapElement('998620', '7720');
        AddMapElement('998630', '7730');
        AddMapElement('998640', '7740');
        AddMapElement('998690', '8690');
        AddMapElement('998695', '8695');
        AddMapElement('998700', '8700');
        AddMapElement('998710', '6010');
        AddMapElement('998720', '6210');
        AddMapElement('998730', '6240');
        AddMapElement('998740', '6410');
        AddMapElement('998750', '6420');
        AddMapElement('998790', '8998');
        AddMapElement('998800', '8800');
        AddMapElement('998810', '7800');
        AddMapElement('998820', '7030');
        AddMapElement('998830', '7040');
        AddMapElement('998840', '4630');
        AddMapElement('998890', '8890');
        AddMapElement('998910', '7850');
        AddMapElement('998995', '8995');
        AddMapElement('999100', '9100');
        AddMapElement('999110', '8020');
        AddMapElement('999120', '8050');
        AddMapElement('999130', '5830');
        AddMapElement('999135', '5835');
        AddMapElement('999140', '8060');
        AddMapElement('999150', '8070');
        AddMapElement('999160', '8160');
        AddMapElement('999170', '8170');
        AddMapElement('999190', '9190');
        AddMapElement('999200', '9200');
        AddMapElement('999210', '8280');
        AddMapElement('999220', '8290');
        AddMapElement('999230', '8310');
        AddMapElement('999240', '8320');
        AddMapElement('999250', '4450');
        AddMapElement('999255', '4455');
        AddMapElement('999260', '8360');
        AddMapElement('999270', '8370');
        AddMapElement('999290', '9290');
        AddMapElement('999310', '4870');
        AddMapElement('999320', '7860');
        AddMapElement('999330', '4880');
        AddMapElement('999340', '7870');
        AddMapElement('999350', '9350');
        AddMapElement('999360', '9360');
        AddMapElement('999395', '9395');
        AddMapElement('999410', '9410');
        AddMapElement('999420', '4880');
        AddMapElement('999495', '9495');
        AddMapElement('999510', '7870');
        AddMapElement('999999', '9999');
        AddMapElement('997705', '7705');
        AddMapElement('997710', '7710');
        AddMapElement('997795', '7795');
        AddMapElement('997805', '7805');
        AddMapElement('997895', '7895');
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

