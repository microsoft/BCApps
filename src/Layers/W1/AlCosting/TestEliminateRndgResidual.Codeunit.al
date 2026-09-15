codeunit 103521 "Test - Eliminate Rndg Residual"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(103521);
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 1"();

        if ShowScriptResult then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        INVTUtil: Codeunit INVTUtil;
        PPUtil: Codeunit PPUtil;
        SRUtil: Codeunit SRUtil;
        GLUtil: Codeunit GLUtil;
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.ModifyAll("Ext. Doc. No. Mandatory", false, true);
        GLUtil.SetRndgPrec(0.01, 0.00001);
        GLUtil.SetAddCurr('EUR', 10, 3, 0.01, 0.00001);
    end;

    [Scope('OnPrem')]
    procedure "Test 1"()
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        i: Integer;
        CostAmt: Decimal;
        CostAmtACY: Decimal;
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        INVTUtil.CreateBasisItem('TEST', false, Item, Item."Costing Method"::FIFO, 0);

        PPUtil.InsertPurchHeader(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        PurchHeader.Validate("Buy-from Vendor No.", '10000');
        PurchHeader.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", Item."No.");
        PurchLine.Validate(Quantity, 150);
        PurchLine.Validate("Direct Unit Cost", 1000);
        PurchLine.Modify(true);

        PPUtil.InsertPurchLine(PurchHeader, PurchLine);
        PurchLine.Validate(Type, PurchLine.Type::Item);
        PurchLine.Validate("No.", Item."No.");
        PurchLine.Validate(Quantity, 200);
        PurchLine.Validate("Direct Unit Cost", 1500);
        PurchLine.Modify(true);

        PPUtil.PostPurchase(PurchHeader, true, true);

        SRUtil.InsertSalesHeader(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", '10000');
        SalesHeader.Modify(true);
        for i := 1 to 208 do begin
            SRUtil.InsertSalesLine(SalesHeader, SalesLine);
            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", Item."No.");
            SalesLine.Validate(Quantity, 1);
            SalesLine.Validate("Location Code", '');
            SalesLine.Modify(true);
        end;

        SRUtil.PostSales(SalesHeader, true, true);

        INVTUtil.AdjustInvtCost();

        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", 'TEST');
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Rounding);
        if ValueEntry.Find('-') then
            repeat
                CostAmt := CostAmt + ValueEntry."Cost Amount (Actual)";
                CostAmtACY := CostAmtACY + ValueEntry."Cost Amount (Actual) (ACY)";
            until ValueEntry.Next() = 0;
        TestscriptMgt.TestNumberValue(ValueEntry.FieldName("Cost Amount (Actual)"), CostAmt, 0);
        TestscriptMgt.TestNumberValue(ValueEntry.FieldName("Cost Amount (Actual) (ACY)"), CostAmtACY, -0.5);
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult;
    end;
}

