codeunit 118653 "Item Tracking - Item Transl."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('80102-T', 'DAN', '17" M780 Skærm');
        InsertData('80102-T', 'ENU', '17" M780 Monitor');
        InsertData(X80102T, XDEU, X17M780Monitor1);
        InsertData('80103-T', 'DAN', '19" M009 Skærm');
        InsertData('80103-T', 'ENU', '19" M009 Monitor');
        InsertData(X80103T, XDEU, X19M009Monitor1);
        InsertData('80208-T', 'DAN', 'Microsoft Intellimouse');
        InsertData('80208-T', 'ENU', 'Microsoft Intellimouse');
        InsertData(X80208T, XDEU, XMicrosoftIntelliMouse1);
        InsertData('80216-T', 'DAN', 'Ethernet Kabel');
        InsertData('80216-T', 'ENU', 'Ethernet Cable');
        InsertData(X80216T, XDEU, XEthernetKabel);
        InsertData('80218-T', 'DAN', 'Hard disk');
        InsertData('80218-T', 'ENU', 'Hard disk Drive');
        InsertData(X80218T, XDEU, XLaufwerkFestplatte);
    end;

    var
        "Item Translation": Record "Item Translation";
        DemoDataSetup: Record "Demo Data Setup";
        X80102T: Label '80102-T';
        X80103T: Label '80103-T';
        X80208T: Label '80208-T';
        X80216T: Label '80216-T';
        X80218T: Label '80218-T';
        XDEU: Label 'DEU';
        X17M780Monitor1: Label '17" M780 Monitor';
        X19M009Monitor1: Label '19" M009 Monitor';
        XMicrosoftIntelliMouse1: Label 'Microsoft IntelliMouse';
        XEthernetKabel: Label 'Ethernet-Kabel';
        XLaufwerkFestplatte: Label 'Laufwerk (Festplatte)';

    procedure InsertData("Item No.": Code[20]; "Language Code": Code[10]; Description: Text[30])
    var
        Item: Record Item;
    begin
        if "Language Code" = DemoDataSetup."Language Code" then begin
            Item.Get("Item No.");
            Item.Validate(Description, Description);
            Item.Modify();
            exit;
        end;

        "Item Translation".Init();
        "Item Translation".Validate("Item No.", "Item No.");
        "Item Translation".Validate("Language Code", "Language Code");
        "Item Translation".Validate(Description, Description);
        if "Item Translation".Insert() then;
    end;
}

