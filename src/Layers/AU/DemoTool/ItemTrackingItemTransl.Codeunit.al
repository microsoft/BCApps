codeunit 118653 "Item Tracking - Item Transl."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('80102-T', 'DAN', '17" M780 Skærm');
        InsertData(X80102T, XENA, X17M780Monitor);
        InsertData(X80102T, XENZ, X17M780Monitor);
        InsertData(X80102T, XENU, X17M780Monitor);
        InsertData('80103-T', 'DAN', '19" M009 Skærm');
        InsertData(X80103T, XENA, X19M009Monitor);
        InsertData(X80103T, XENZ, X19M009Monitor);
        InsertData(X80103T, XENU, X19M009Monitor);
        InsertData('80208-T', 'DAN', 'Microsoft Intellimouse');
        InsertData(X80208T, XENA, XMicrosoftIntellimouse);
        InsertData(X80208T, XENZ, XMicrosoftIntellimouse);
        InsertData(X80208T, XENU, XMicrosoftIntellimouse);
        InsertData('80216-T', 'DAN', 'Ethernet Kabel');
        InsertData(X80216T, XENA, XEthernetCable);
        InsertData(X80216T, XENZ, XEthernetCable);
        InsertData(X80216T, XENU, XEthernetCable);
        InsertData('80218-T', 'DAN', 'Hard disk');
        InsertData(X80218T, XENA, XHarddiskDrive);
        InsertData(X80218T, XENZ, XHarddiskDrive);
        InsertData(X80218T, XENU, XHarddiskDrive);
    end;

    var
        "Item Translation": Record "Item Translation";
        DemoDataSetup: Record "Demo Data Setup";
        X80102T: Label '80102-T';
        XENU: Label 'ENU';
        X17M780Monitor: Label '17" M780 Monitor';
        X80103T: Label '80103-T';
        X19M009Monitor: Label '19" M009 Monitor';
        X80208T: Label '80208-T';
        XMicrosoftIntellimouse: Label 'Microsoft Intellimouse';
        X80216T: Label '80216-T';
        XEthernetCable: Label 'Ethernet Cable';
        X80218T: Label '80218-T';
        XHarddiskDrive: Label 'Hard disk Drive';
        XENA: Label 'ENA';
        XENZ: Label 'ENZ';

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

