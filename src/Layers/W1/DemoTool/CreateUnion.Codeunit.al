codeunit 101607 "Create Union"
{

    trigger OnRun()
    begin
        InsertData(XUADMI, XAdministratorsapoUnion, X9BrightonRoad, CreatePostCode.Convert('GB-N12 5XY'));
        InsertData(XUPROD, XProductionWorkersapoUnion, X75WarwickRoad, CreatePostCode.Convert('GB-N12 5XY'));
        InsertData(XUDEVE, XDevelopmentEngineersapoUnion, X8BroadfieldPark, CreatePostCode.Convert('GB-N12 5XY'));
    end;

    var
        Union: Record Union;
        CreatePostCode: Codeunit "Create Post Code";
        XUADMI: Label 'UADMI';
        XAdministratorsapoUnion: Label 'Administrators'' Union';
        X9BrightonRoad: Label '9 Brighton Road';
        XUPROD: Label 'UPROD';
        XProductionWorkersapoUnion: Label 'Production Workers'' Union';
        X75WarwickRoad: Label '75 Warwick Road';
        XUDEVE: Label 'UDEVE';
        XDevelopmentEngineersapoUnion: Label 'Development Engineers'' Union';
        X8BroadfieldPark: Label '8 Broadfield Park';

    procedure InsertData("Code": Code[10]; Name: Text[30]; Address: Text[30]; "Post Code": Code[20])
    begin
        Union.Init();
        Union.Validate(Code, Code);
        Union.Validate(Name, Name);
        Union.Validate(Address, Address);
        Union."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Union.City := CreatePostCode.FindCity("Post Code");
        Union.Insert(true);
    end;
}

