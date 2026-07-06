codeunit 101341 "Create Item Disc. Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.FinishedCode(), XFinishedgoods);
        InsertData(DemoDataSetup.RawMatCode(), XRawmaterial);
        InsertData(DemoDataSetup.ResaleCode(), XResale2);
        InsertData(XA, '');
        InsertData(XB, '');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ItemDiscGroup: Record "Item Discount Group";
        XFinishedgoods: Label 'Finished goods';
        XRawmaterial: Label 'Raw material';
        XResale2: Label 'Resale';
        XA: Label 'A';
        XB: Label 'B';

    procedure InsertData("Item Disc. Group": Code[10]; Description: Text[30])
    begin
        ItemDiscGroup.Init();
        ItemDiscGroup.Validate(Code, "Item Disc. Group");
        ItemDiscGroup.Validate(Description, Description);
        ItemDiscGroup.Insert();
    end;
}

