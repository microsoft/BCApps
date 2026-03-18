codeunit 101224 "Create Order Address"
{

    trigger OnRun()
    begin
        InsertData('10000', XHOPE, X100HopeStreet, XJohnArthur, CreatePostCode.Convert('GB-N12 5XY'));
        InsertData('10000', XTHEGROVE, X32TheGrove, XTerryCrayton, CreatePostCode.Convert('GB-N12 5XY'));
        InsertData('20000', XJAMES, X1JamesAllenWay, XBrianGroth, CreatePostCode.Convert('GB-GU3 2SE'));
        InsertData('20000', XWATFORD, X10FieldGreen, XMarcZimmerman, CreatePostCode.Convert('GB-WD2 4RG'));
    end;

    var
        "Order Address": Record "Order Address";
        CreatePostCode: Codeunit "Create Post Code";
        XHOPE: Label 'HOPE';
        X100HopeStreet: Label '100 Hope Street';
        XJohnArthur: Label 'John Arthur';
        XTHEGROVE: Label 'THE GROVE';
        X32TheGrove: Label '32 The Grove';
        XTerryCrayton: Label 'Terry Crayton';
        XJAMES: Label 'JAMES';
        X1JamesAllenWay: Label '1 James Allen Way';
        XBrianGroth: Label 'Brian Groth';
        XWATFORD: Label 'WATFORD';
        X10FieldGreen: Label '10 Field Green';
        XMarcZimmerman: Label 'Marc Zimmerman';

    procedure InsertData("Vendor No.": Code[20]; "Code": Code[10]; Address: Text[30]; Contact: Text[30]; "Post Code": Code[20])
    begin
        "Order Address".Init();
        "Order Address".Validate("Vendor No.", "Vendor No.");
        "Order Address".Validate(Code, Code);
        "Order Address".Validate(Address, Address);
        "Order Address".Validate(Contact, Contact);
        "Order Address"."Post Code" := CreatePostCode.FindPostCode("Post Code");
        "Order Address".City := CreatePostCode.FindCity("Post Code");
        "Order Address".Insert(true);
    end;
}

