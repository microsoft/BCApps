codeunit 139000 "Test Filter Expr. COD41"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Filter Tokens] [UT]
    end;

    var
        Assert: Codeunit "Assert";

    [Test]
    [Scope('OnPrem')]
    procedure MakeTextFilter1()
    var
        CommentLine: Record "Comment Line";
        i: Integer;
    begin
        // ME
        // USER
        // COMPANY
        CommentLine.SETRANGE("Table Name", CommentLine."Table Name"::Insurance);
        CommentLine.DeleteAll();
        CommentLine.Init();

        CommentLine."Table Name" := CommentLine."Table Name"::Insurance;
        i := i + 1;
        InsertCommentLine(CommentLine, FORMAT(i), '', 0D);
        i := i + 1;
        InsertCommentLine(CommentLine, FORMAT(i), USERID, 0D);
        i := i + 1;
        InsertCommentLine(CommentLine, FORMAT(i), COMPANYNAME, 0D);

        Assert.AreEqual(3, CommentLine.COUNT, 'Check before applying filters to CommentLine failed.');

        CommentLine.SETFILTER(Comment, '%1', USERID);
        Assert.AreEqual(1, CommentLine.COUNT, '%ME filter returned wrong number of records.');
        CommentLine.SETFILTER(Comment, '%1', USERID);
        Assert.AreEqual(1, CommentLine.COUNT, '%USER filter returned wrong number of records.');
        CommentLine.SETFILTER(Comment, '%1', COMPANYNAME);
        Assert.AreEqual(1, CommentLine.COUNT, '%COMPANY filter returned wrong number of records.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeTextFilter2()
    var
        Customer: Record "Customer";
        MyCustomer: Record "My Customer";
        i: Integer;
        NoPrefix: Code[10];
        ExpectedFilter: Text;
        NoOfElementsInFilter: Integer;
    begin
        // MYCUSTOMERS
        NoPrefix := 'UTEST';
        Customer.SETFILTER("No.", 'UTEST' + '*');
        Customer.DeleteAll();
        MyCustomer.SETRANGE("User ID", USERID);
        MyCustomer.DeleteAll();
        ExpectedFilter := '';
        FOR i := 1 TO 100 DO BEGIN
            InsertCustomer(Customer, NoPrefix + FORMAT(100000 + i), 'Test Customer ' + FORMAT(i));
            IF i MOD 3 = 0 THEN BEGIN
                InsertMyCustomer(Customer);
                ExpectedFilter := AddToFilter(ExpectedFilter, Customer."No.", NoOfElementsInFilter);
            END;
        END;
        Assert.AreEqual(100, Customer.COUNT, 'Check before applying filters to Customer failed.');

        Customer.SETFILTER("No.", '%MYCUSTOMERS');
        // Raises a message
        Assert.IsTrue(Customer.COUNT <= MyCustomer.COUNT, '%MYCUSTOMERS filter returned too many records.');
        Assert.IsTrue(Customer.COUNT >= STRLEN(Customer.GETFILTER("No.")) DIV (STRLEN(Customer."No.") + 1), '%MYCUSTOMERS filter returned too few records.');
    end;

    [Test]
    [HandlerFunctions('ShowMessageHandler')]
    [Scope('OnPrem')]
    procedure MakeTextFilter3()
    var
        Vendor: Record "Vendor";
        MyVendor: Record "My Vendor";
        i: Integer;
        NoPrefix: Code[10];
        ExpectedFilter: Text;
        NoOfElementsInFilter: Integer;
    begin
        // MYVENDORS
        NoPrefix := 'UTEST';
        Vendor.SETFILTER("No.", 'UTEST' + '*');
        Vendor.DeleteAll();
        MyVendor.SETRANGE("User ID", USERID);
        MyVendor.DeleteAll();
        ExpectedFilter := '';
        FOR i := 1 TO 2100 DO BEGIN
            InsertVendor(Vendor, NoPrefix + FORMAT(100000 + i), 'Test Vendor ' + FORMAT(i));
            InsertMyVendor(Vendor);
            ExpectedFilter := AddToFilter(ExpectedFilter, Vendor."No.", NoOfElementsInFilter);
        END;
        Assert.AreEqual(2100, Vendor.COUNT, 'Check before applying filters to Vendor failed.');

        Vendor.SETFILTER("No.", '%MYVENDORS');
        Assert.IsTrue(Vendor.COUNT <= MyVendor.COUNT, '%MYVENDORS filter returned too many records.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeTextFilter4()
    var
        Item: Record "Item";
        MyItem: Record "My Item";
        i: Integer;
        NoPrefix: Code[10];
        ExpectedFilter: Text;
        NoOfElementsInFilter: Integer;
    begin
        // MYITEMS
        NoPrefix := 'UTEST';
        Item.SETFILTER("No.", 'UTEST' + '*');
        Item.DeleteAll();
        MyItem.SETRANGE("User ID", USERID);
        MyItem.DeleteAll();
        ExpectedFilter := '';
        FOR i := 1 TO 100 DO BEGIN
            InsertItem(Item, NoPrefix + FORMAT(100000 + i), 'Test Item ' + FORMAT(i));
            IF i MOD 3 = 0 THEN BEGIN
                InsertMyItem(Item);
                ExpectedFilter := AddToFilter(ExpectedFilter, Item."No.", NoOfElementsInFilter);
            END;
        END;
        Assert.AreEqual(100, Item.COUNT, 'Check before applying filters to Item failed.');

        Item.SETFILTER("No.", '%MYITEMS');
        Assert.IsTrue(Item.COUNT <= MyItem.COUNT, '%MYITEMS filter returned too many records.');
        Assert.IsTrue(Item.COUNT >= STRLEN(Item.GETFILTER("No.")) DIV (STRLEN(Item."No.") + 1), '%MYITEMS filter returned too few records.');
    end;

    local procedure InsertCommentLine(var CommentLine: Record "Comment Line"; No: Code[20]; Text: Text[80]; Date2: Date)
    begin
        CommentLine.Init();
        CommentLine."No." := No;
        CommentLine.Comment := Text;
        CommentLine.Date := Date2;
        CommentLine.Insert();
    end;

    local procedure InsertCustomer(var Customer: Record "Customer"; No: Code[20]; Name2: Text[50])
    begin
        Customer.Init();
        Customer."No." := No;
        Customer.Name := Name2;
        Customer.Insert();
    end;

    local procedure InsertMyCustomer(var Customer: Record "Customer")
    var
        MyCustomer: Record "My Customer";
    begin
        MyCustomer.Init();
        MyCustomer."User ID" := USERID;
        MyCustomer."Customer No." := Customer."No.";
        MyCustomer.Insert();
    end;

    local procedure InsertVendor(var Vendor: Record "Vendor"; No: Code[20]; Name2: Text[50])
    begin
        Vendor.Init();
        Vendor."No." := No;
        Vendor.Name := Name2;
        Vendor.Insert();
    end;

    local procedure InsertMyVendor(var Vendor: Record "Vendor")
    var
        MyVendor: Record "My Vendor";
    begin
        MyVendor.Init();
        MyVendor."User ID" := USERID;
        MyVendor."Vendor No." := Vendor."No.";
        MyVendor.Insert();
    end;

    local procedure InsertItem(var Item: Record "Item"; No: Code[20]; Description2: Text[50])
    begin
        Item.Init();
        Item."No." := No;
        Item.Description := Description2;
        Item.Insert();
    end;

    local procedure InsertMyItem(var Item: Record "Item")
    var
        MyItem: Record "My Item";
    begin
        MyItem.Init();
        MyItem."User ID" := USERID;
        MyItem."Item No." := Item."No.";
        MyItem.Insert();
    end;

    local procedure AddToFilter(OldString: Text; NewNo: Text; var CurrElementNo: Integer): Text
    begin
        CurrElementNo += 1;
        IF OldString = '' THEN
            EXIT(NewNo);
        IF CurrElementNo > 2000 THEN
            EXIT(OldString);
        EXIT(OldString + '|' + NewNo);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ShowMessageHandler(Msg: Text[1024])
    begin
    end;
}

