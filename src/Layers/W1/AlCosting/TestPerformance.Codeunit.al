codeunit 103101 "Test - Performance"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        SetPreconditions();
        PrepareOutput();
        CreatePostings();

        Window.Close();
    end;

    var
        PPUtil: Codeunit PPUtil;
        SRUtil: Codeunit SRUtil;
        Window: Dialog;
        StartTime: Time;
        Measurement: array[20] of Integer;
        NoOfDays: Integer;
        NoOfPostingSetPerDay: Integer;
        ClearAtMeasurementNo: Integer;
        CustNo: Code[20];
        VendorNo: Code[20];
        ItemNo: Code[20];
        OutputFileName: Text[30];
        OutputFile: File;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        NoSeriesLine: Record "No. Series Line";
        Item: Record Item;
    begin
        WorkDate := 20010101D;
        NoOfDays := 5000;
        NoOfPostingSetPerDay := 10;
        ClearAtMeasurementNo := 5000;
        // OutputFileName := 'c:\1.txt';
        ItemNo := 'AVG';
        VendorNo := 'a';
        CustNo := '10000NODIM';

        InsertItem(ItemNo, false, Item, Item."Costing Method"::Average, 0);
        InsertVendor(VendorNo);
        InsertCust(CustNo);

        PurchSetup.ModifyAll("Ext. Doc. No. Mandatory", false, true);
        NoSeriesLine.ModifyAll("Warning No.", '');
        NoSeriesLine.ModifyAll("Ending No.", '9999999999');
    end;

    [Scope('OnPrem')]
    procedure CreatePostings()
    var
        DayNo: Integer;
        PostingSetNo: Integer;
    begin
        for DayNo := 1 to NoOfDays do begin
            WorkDate := WorkDate() + 1;
            for PostingSetNo := 1 to NoOfPostingSetPerDay do begin
                // CreateItemPosting(ItemJnlLine."Entry Type"::Purchase,1,3.33333);
                // CreateItemPosting(ItemJnlLine."Entry Type"::Sale,1,3.33333);
                // CreatePurchPosting(1,3.33333);
                CreateSalesPosting(1, 3.33333);

                Measurement[1] := Measurement[1] + 1;
                Measurement[3] := Measurement[3] + Measurement[2];
                Measurement[6] := Measurement[6] + Measurement[5];
                Measurement[9] := Measurement[9] + Measurement[8];
                Measurement[12] := Measurement[12] + Measurement[11];
                UpdateOutput();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateItemPosting(EntryType: Option; Qty: Decimal; UnitAmount: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", EntryType);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine.Validate("Document No.", 'A');
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate(Quantity, Qty);
        ItemJnlLine.Validate("Unit Amount", UnitAmount);
        StartTime := Time;
        ItemJnlPostLine.Run(ItemJnlLine);
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Purchase:
                Measurement[2] := (Time - StartTime);
            ItemJnlLine."Entry Type"::Sale:
                Measurement[5] := (Time - StartTime);
        end;
        Commit();
    end;

    [Scope('OnPrem')]
    procedure CreatePurchPosting(Qty: Decimal; UnitAmount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
    begin
        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", ItemNo);
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", UnitAmount);
        PurchLine.Modify(true);
        Commit();
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        StartTime := Time;
        PurchPost.Run(PurchHeader);
        Measurement[8] := (Time - StartTime);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesPosting(Qty: Decimal; UnitAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
    begin
        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", CustNo);
        SalesHeader.Modify(true);
        SRUtil.InsertSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitAmount);
        SalesLine.Modify(true);
        Commit();
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        StartTime := Time;
        SalesPost.Run(SalesHeader);
        Measurement[11] := (Time - StartTime);
    end;

    [Scope('OnPrem')]
    procedure InsertItem(ItemNo: Code[20]; IsMfgItem: Boolean; var Item: Record Item; CostingMethod: Enum "Costing Method"; StandardCost: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if Item.Get(ItemNo) then
            exit;

        Clear(Item);
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        ItemUnitOfMeasure.Validate("Item No.", Item."No.");
        ItemUnitOfMeasure.Validate(Code, 'PCS');
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", 1);
        ItemUnitOfMeasure.Insert(true);

        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Rounding Precision", 0.00001);
        Item.Validate("Standard Cost", StandardCost);
        Item.Validate("Unit Cost", StandardCost);
        if IsMfgItem then begin
            Item."Inventory Posting Group" := 'FINISHED';
            Item."Gen. Prod. Posting Group" := 'RETAIL';
            Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        end else begin
            Item."Inventory Posting Group" := 'RAW MAT';
            Item."Gen. Prod. Posting Group" := 'RAW MAT';
        end;
        Item."VAT Prod. Posting Group" := 'VAT25';
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(VendorNo) then
            exit;

        Vendor.Get('10000');
        Vendor."No." := VendorNo;
        Vendor."Purchaser Code" := '';
        Vendor.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertCust(CustNo: Code[20])
    var
        Cust: Record Customer;
    begin
        if Cust.Get(CustNo) then
            exit;

        Cust.Get('10000');
        Cust."No." := CustNo;
        Cust."Salesperson Code" := '';
        Cust.Insert();
    end;

    [Scope('OnPrem')]
    procedure PrepareOutput()
    begin
        Window.Open(
          'No. of Posting Sets                                                        #1######\' +
          'Item - Purchase                                                            #2######\' +
          'Item - Purchase (average)                                                  #4######\' +
          'Item - Sale                                                                #5######\' +
          'Item - Sale (average)                                                      #7######\' +
          'Order - Purchase                                                           #8######\' +
          'Order - Purchase (average)                                                 #10#####\' +
          'Order - Sale                                                               #11#####\' +
          'Order - Sale (average)                                                     #13#####\');

        if OutputFileName <> '' then begin
            OutputFile.Create(OutputFileName);
            OutputFile.Close();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateOutput()
    var
        OutputText: Text[999];
        i: Integer;
        Tab: Char;
        Lf: Char;
        Cr: Char;
    begin
        Measurement[4] := Round(Measurement[3] / Measurement[1], 1);
        Measurement[7] := Round(Measurement[6] / Measurement[1], 1);
        Measurement[10] := Round(Measurement[9] / Measurement[1], 1);
        Measurement[13] := Round(Measurement[12] / Measurement[1], 1);

        Window.Update(1, Measurement[1]);
        Window.Update(2, Measurement[2]);
        Window.Update(4, Measurement[4]);
        Window.Update(5, Measurement[5]);
        Window.Update(7, Measurement[4]);
        Window.Update(8, Measurement[8]);
        Window.Update(10, Measurement[10]);
        Window.Update(11, Measurement[11]);
        Window.Update(13, Measurement[13]);

        if Measurement[1] = ClearAtMeasurementNo then begin
            if OutputFileName <> '' then begin
                Tab := 9;
                Lf := 10;
                Cr := 13;
                for i := 1 to ArrayLen(Measurement) do
                    OutputText := OutputText + Format(Measurement[i]) + Format(Tab);
                OutputFile.TextMode(true);
                OutputFile.Open(OutputFileName);
                OutputFile.Seek(OutputFile.Len);
                OutputFile.Write(OutputText);
                OutputFile.Close();
            end;
            Clear(Measurement);
        end;
    end;
}

