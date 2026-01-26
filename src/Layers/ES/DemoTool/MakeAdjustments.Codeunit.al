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
        AddMapElement('2112', '3000004');
        AddMapElement('992112', '3000004');
        AddMapElement('5510', '6110001');
        AddMapElement('995510', '6110001');
        AddMapElement('7180', '6230004');
        AddMapElement('997180', '6230004');
        AddMapElement('7280', '6230004');
        AddMapElement('997280', '6230004');
        AddMapElement('991110', '2200001');
        AddMapElement('991120', '2200001');
        AddMapElement('991130', '2200001');
        AddMapElement('991140', '2820001');
        AddMapElement('991210', '2130001');
        AddMapElement('991220', '2130001');
        AddMapElement('991230', '2130001');
        AddMapElement('991240', '2820001');
        AddMapElement('991310', '2180001');
        AddMapElement('991320', '2180001');
        AddMapElement('991330', '2180001');
        AddMapElement('991340', '2820001');
        AddMapElement('992110', '3000001');
        AddMapElement('992111', '3000004');
        AddMapElement('992120', '3000002');
        AddMapElement('992121', '3000003');
        AddMapElement('992130', '3100001');
        AddMapElement('992131', '3100002');
        AddMapElement('992180', '3000001');
        AddMapElement('992210', '3300010');
        AddMapElement('992211', '3300010');
        AddMapElement('992212', '3300010');
        AddMapElement('992220', '3300020');
        AddMapElement('992230', '3300030');
        AddMapElement('992231', '3300030');
        AddMapElement('992232', '3300030');
        AddMapElement('992240', '3300030');
        AddMapElement('992310', '4300001');
        AddMapElement('992320', '4300002');
        AddMapElement('992330', '4300001');
        AddMapElement('992340', '4400001');
        AddMapElement('992390', '4400001');
        AddMapElement('992400', '4400001');
        AddMapElement('992410', '4400001');
        AddMapElement('992420', '4400001');
        AddMapElement('992430', '4400001');
        AddMapElement('992440', '4400001');
        AddMapElement('992810', '5410001');
        AddMapElement('992910', '5700001');
        AddMapElement('992920', '5720001');
        AddMapElement('992930', '5730001');
        AddMapElement('992940', '5720001');
        AddMapElement('993110', '1000001');
        AddMapElement('993120', '1130001');
        AddMapElement('994010', '1120001');
        AddMapElement('995110', '1700001');
        AddMapElement('995120', '1700001');
        AddMapElement('995310', '5740001');
        AddMapElement('995350', '5740001');
        AddMapElement('995360', '5740001');
        AddMapElement('995370', '5740001');
        AddMapElement('995380', '5740001');
        AddMapElement('995390', '5740001');
        AddMapElement('995410', '4000001');
        AddMapElement('995420', '4000002');
        AddMapElement('995610', '4770001');
        AddMapElement('995611', '4770001');
        AddMapElement('995520', '4770011');
        AddMapElement('995620', '4770011');
        AddMapElement('995621', '4770011');
        AddMapElement('995530', '4720001');
        AddMapElement('995630', '4720001');
        AddMapElement('995631', '4720001');
        AddMapElement('995710', '6240002');
        AddMapElement('995750', '6240002');
        AddMapElement('995780', '4750001');
        AddMapElement('995810', '4751001');
        AddMapElement('995820', '4751001');
        AddMapElement('995830', '4760001');
        AddMapElement('995840', '4760001');
        AddMapElement('995920', '4752001');
        AddMapElement('996080001', '6080001');
        AddMapElement('996080002', '6080002');
        AddMapElement('996080003', '6080003');
        AddMapElement('996110', '7000001');
        AddMapElement('996120', '7000002');
        AddMapElement('996130', '7000003');
        AddMapElement('996190', '7050003');
        AddMapElement('996191', '7050003');
        AddMapElement('996210', '7001001');
        AddMapElement('996220', '7001002');
        AddMapElement('996230', '7001003');
        AddMapElement('996290', '7050003');
        AddMapElement('996291', '7050003');
        AddMapElement('996410', '7050011');
        AddMapElement('996491', '7050003');
        AddMapElement('996420', '7050012');
        AddMapElement('996430', '7050013');
        AddMapElement('996490', '7050003');
        AddMapElement('996610', '7050004');
        AddMapElement('996620', '7050003');
        AddMapElement('996710', '7050001');
        AddMapElement('996810', '7050004');
        AddMapElement('996820', '7050007');
        AddMapElement('6810', '7050004');
        AddMapElement('996910', '7090001');
        AddMapElement('6910', '7090001');
        AddMapElement('997080001', '7080001');
        AddMapElement('997080002', '7080002');
        AddMapElement('997080003', '7080003');
        AddMapElement('997110', '6000001');
        AddMapElement('7110', '6000001');
        AddMapElement('997120', '6000002');
        AddMapElement('7120', '6000002');
        AddMapElement('997130', '6000003');
        AddMapElement('7130', '6000003');
        AddMapElement('997140', '6090001');
        AddMapElement('7140', '6090001');
        AddMapElement('997150', '6240001');
        AddMapElement('997170', '6100001');
        AddMapElement('997181', '6230004');
        AddMapElement('997190', '6100001');
        AddMapElement('997210', '6010001');
        AddMapElement('997220', '6010002');
        AddMapElement('997230', '6010003');
        AddMapElement('997240', '6091001');
        AddMapElement('997250', '6240001');
        AddMapElement('997270', '6110001');
        AddMapElement('997281', '6230004');
        AddMapElement('997290', '6110001');
        AddMapElement('997480', '6230004');
        AddMapElement('997481', '6230004');
        AddMapElement('997620', '6230004');
        AddMapElement('998110', '6210001');
        AddMapElement('998120', '6290002');
        AddMapElement('998130', '6220001');
        AddMapElement('998210', '6290002');
        AddMapElement('998230', '6280003');
        AddMapElement('998240', '6290001');
        AddMapElement('998310', '6290002');
        AddMapElement('998320', '6230003');
        AddMapElement('998330', '6280010');
        AddMapElement('998410', '6270001');
        AddMapElement('998420', '6290003');
        AddMapElement('998430', '6290003');
        AddMapElement('998450', '6240001');
        AddMapElement('998510', '6240002');
        AddMapElement('998520', '6240001');
        AddMapElement('998530', '6220001');
        AddMapElement('998610', '6690001');
        AddMapElement('998620', '6290001');
        AddMapElement('998630', '6230003');
        AddMapElement('998640', '6690001');
        AddMapElement('998710', '6400001');
        AddMapElement('998720', '6400001');
        AddMapElement('998730', '6400003');
        AddMapElement('998740', '6400002');
        AddMapElement('998750', '6420001');
        AddMapElement('998810', '6810001');
        AddMapElement('998820', '6810001');
        AddMapElement('998830', '6810001');
        AddMapElement('998840', '6810001');
        AddMapElement('998910', '6290001');
        AddMapElement('999110', '7690001');
        AddMapElement('999120', '7050004');
        AddMapElement('999130', '6080001');
        AddMapElement('999210', '6653001');
        AddMapElement('999220', '6653001');
        AddMapElement('999230', '6653001');
        AddMapElement('999240', '6690001');
        AddMapElement('999250', '6653001');
        AddMapElement('999310', '7680001');
        AddMapElement('999320', '6680001');
        AddMapElement('999330', '7680001');
        AddMapElement('999340', '6680001');
        AddMapElement('999350', '7680001');
        AddMapElement('999360', '6680001');
        AddMapElement('999410', '7780001');
        AddMapElement('999420', '6780001');
        AddMapElement('999510', '6300001');
        AddMapElement('9160', '6080001');
        AddMapElement('9170', '6080001');
        AddMapElement('9260', '6653002');
        AddMapElement('9270', '6653003');
        AddMapElement('999160', '6080001');
        AddMapElement('999170', '6080001');
        AddMapElement('999260', '6653002');
        AddMapElement('999270', '6653003');
        AddMapElement('997191', '3300100');
        AddMapElement('997192', '3300110');
        AddMapElement('997193', '3300120');
        AddMapElement('997291', '3300130');
        AddMapElement('997292', '3300140');
        AddMapElement('997293', '3300150');
        AddMapElement('997705', '3300160');
        AddMapElement('997710', '3300170');
        AddMapElement('997791', '3300180');
        AddMapElement('997792', '3300190');
        AddMapElement('997793', '3300200');
        AddMapElement('997795', '3300210');
        AddMapElement('997805', '3300220');
        AddMapElement('997891', '3300230');
        AddMapElement('997892', '3300240');
        AddMapElement('997893', '3300250');
        AddMapElement('997894', '3300260');
        AddMapElement('997895', '3300270');
        AddMapElement('992140', '3300280');
        AddMapElement('6100', '700');
        AddMapElement('6105', '7000');
        AddMapElement('6110', '7000001');
        AddMapElement('6120', '7000002');
        AddMapElement('6130', '7000003');
        AddMapElement('6195', '7000');
        AddMapElement('6205', '7001');
        AddMapElement('6210', '7001001');
        AddMapElement('6220', '7001002');
        AddMapElement('6230', '7001003');
        AddMapElement('6295', '7001');
        AddMapElement('6995', '70');
        AddMapElement('7100', '600');
        AddMapElement('7995', '60');
        AddMapElement('8790', '64');
        AddMapElement('2121', '3000003');
        AddMapElement('2131', '3100001');
        AddMapElement('2111', '3000004');
        AddMapElement('7191', '3000004');
        AddMapElement('5796', '7052001');
        AddMapElement('5797', '7052002');
        AddMapElement('6950', '7060002');
        AddMapElement('6955', '7051001');
        AddMapElement('996100', '700');
        AddMapElement('996105', '7000');
        AddMapElement('996195', '7000');
        AddMapElement('996205', '7001');
        AddMapElement('996295', '7001');
        AddMapElement('996995', '70');
        AddMapElement('997100', '600');
        AddMapElement('997995', '60');
        AddMapElement('998790', '64');
        AddMapElement('995799', '7052');
        AddMapElement('995796', '7052001');
        AddMapElement('995797', '7052002');
        AddMapElement('995795', '7052003');
        AddMapElement('996950', '7060002');
        AddMapElement('996955', '7060001');
        AddMapElement('9135', '6060001');
        AddMapElement('999135', '6060001');
        AddMapElement('9255', '6653001');
        AddMapElement('999255', '6653001');
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

