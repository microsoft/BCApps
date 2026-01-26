codeunit 161403 "Create Entry/Exit Point"
{

    trigger OnRun()
    begin
        InsertData('0100', 'Lübeck-West');
        InsertData('0203', 'Lübeck-Travemünde');
        InsertData('0303', 'Heiligenhafen');
        InsertData('0305', 'Neustadt (Holst.)');
        InsertData('0307', 'Puttgarden');
        InsertData('0501', 'Eckernförde');
        InsertData('0509', 'Kiel-Wik');
        InsertData('0511', 'Laboe');
        InsertData('0513', 'Rendsburg');
        InsertData('0701', 'Flensburg');
        InsertData('0703', 'Kappeln');
        InsertData('0705', 'Schleswig');
        InsertData('0900', 'Husum');
        InsertData('0901', 'Büsum');
        InsertData('0905', 'Tönning');
        InsertData('0907', 'Westerland');
        InsertData('0909', 'Wyk');
        InsertData('1100', 'Itzehoe');
        InsertData('1101', 'Brunsbüttel');
        InsertData('1111', 'Pinneberg');
        InsertData('1200', 'Hbg.-Waltershof');
        InsertData('1202', 'Hbg.-Ernst-August-Schleuse');
        InsertData('1205', 'Hbg.-Südbahnhof');
        InsertData('1212', 'Hbg.-Köhlfleetdamm');
        InsertData('1214', 'Hbg.-Veddel');
        InsertData('1220', 'Hbg.-Ericus');
        InsertData('1222', 'Hbg.-Kornhausbrücke');
        InsertData('1223', 'Hbg.-Fischereihafen');
        InsertData('1225', 'Hbg.-Elbtunnel');
        InsertData('1228', 'Hbg.-Niederbaum');
        InsertData('1229', 'Hbg.-Zweibrückenstraße');
        InsertData('1231', 'Hbg.-Hafen-Harburg');
        InsertData('1232', 'Hbg.-Wilhelmsburg');
        InsertData('1233', 'Hbg.-Rethe');
        InsertData('1235', 'Cuxhaven');
        InsertData('1237', 'Helgoland');
        InsertData('1241', 'Hamburg-Flughafen');
        InsertData('1244', 'Hamburg-Köhlfleetdamm');
        InsertData('1263', 'Hbg.-Oberelbe');
        InsertData('1299', 'Hbg.-Freihafenamt');
        InsertData('1401', 'Buxtehude');
        InsertData('1403', 'Stade');
        InsertData('1503', 'Bremen-Hansator');
        InsertData('1523', 'Bremen-Holzhafen');
        InsertData('1524', 'Bremen-Industriehafen');
        InsertData('1526', 'Bremen-Vegesack');
        InsertData('1541', 'Bremen-Ost');
        InsertData('1542', 'Bremen-Neustädter-Hafen');
        InsertData('1543', 'Bremen-Flughafen');
        InsertData('1599', 'Bremen-Stat.-Landesamt');
        InsertData('1601', 'Bremen-Fischereihafen');
        InsertData('1603', 'Bremerhaven-Rotersand');
        InsertData('1605', 'Bremerhaven-Container-Terminal');
        InsertData('1700', 'Emden');
        InsertData('1707', 'Emden-Nesserland');
        InsertData('1713', 'Borkum');
        InsertData('1715', 'Herbrum');
        InsertData('1717', 'Leer');
        InsertData('1719', 'Norden');
        InsertData('1721', 'Norderney');
        InsertData('1723', 'Papenburg');
        InsertData('2001', 'Brake');
        InsertData('2003', 'Elsfleth');
        InsertData('2004', 'Elsfleth-Flughafen');
        InsertData('2009', 'Wilhelmshaven');
        InsertData('2101', 'Nordenham');
        InsertData('3245', 'Saarbrücken-Flughafen');
        InsertData('4302', 'Friedrichshafen-Güterbahnhof');
        InsertData('5821', 'Berlin-Tegel-Flughafen');
        InsertData('5901', 'Hannover-Flughafen');
        InsertData('6001', 'Mönchengladbach (Krefeld)');
        InsertData('6101', 'Düsseldorf-Flughafen');
        InsertData('6201', 'Köln/Bonn-Flughafen');
        InsertData('6303', 'Frankfurt/M.-Flughafen');
        InsertData('6401', 'Stuttgart-Flughafen');
        InsertData('6501', 'Nürnberg-Flughafen');
        InsertData('6601', 'München-Riehm-Flughafen');
        InsertData('6625', 'München-West');
        InsertData('7903', 'Münster-Flughafen');
        InsertData('9752', 'Berlin-Flughafen-Schönefeld');
        InsertData('9767', 'Dresden-Flughafen');
        InsertData('9814', 'Erfurt-Flughafen');
        InsertData('9880', 'Leipzig-Flughafen');
        InsertData('9931', 'Rostock-Stadthafen');
        InsertData('9932', 'Rostock-Seehafen');
        InsertData('9933', 'Warnemünde');
        InsertData('9938', 'Wismar-Hafen');
        InsertData('9945', 'Mukran');
        InsertData('9946', 'Saßnitz');
        InsertData('9947', 'Stralsund-Hafen');
    end;

    var
        "Entry/ExitPoint": Record "Entry/Exit Point";

    procedure InsertData("Code": Code[10]; Text: Text[250])
    begin
        "Entry/ExitPoint".Init();
        "Entry/ExitPoint".Validate(Code, Code);
        "Entry/ExitPoint".Validate(Description, Text);
        "Entry/ExitPoint".Insert();
    end;
}

