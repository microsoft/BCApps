report 103401 "Copy Reference Data"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Copy Reference Data';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'G/L Entry';

            trigger OnAfterGetRecord()
            begin
                GLERef."Use Case No." := UseCaseNo;
                GLERef."Test Case No." := TestCaseNo;
                GLERef."Iteration No." := IterationNo;
                GLERef.TransferFields("G/L Entry");
                if not GLERef.Insert() then
                    GLERef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                GLERef.SetRange("Use Case No.", UseCaseNo);
                GLERef.SetRange("Test Case No.", TestCaseNo);
                GLERef.SetRange("Iteration No.", IterationNo);
                if GLERef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', GLERef.TableName), false)
                    then
                        CurrReport.Break();
                GLERef.DeleteAll();
                GLERef.Reset();
            end;
        }
        dataitem("Value Entry"; "Value Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'Value Entry';

            trigger OnAfterGetRecord()
            begin
                VERef."Use Case No." := UseCaseNo;
                VERef."Test Case No." := TestCaseNo;
                VERef."Iteration No." := IterationNo;
                VERef.TransferFields("Value Entry");
                if not VERef.Insert() then
                    VERef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                VERef.SetRange("Use Case No.", UseCaseNo);
                VERef.SetRange("Test Case No.", TestCaseNo);
                VERef.SetRange("Iteration No.", IterationNo);
                if VERef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', VERef.TableName), false)
                    then
                        CurrReport.Break();
                VERef.DeleteAll();
                VERef.Reset();
            end;
        }
        dataitem("Item Ledger Entry"; "Item Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";
            RequestFilterHeading = 'ILE';

            trigger OnAfterGetRecord()
            begin
                ILERef."Use Case No." := UseCaseNo;
                ILERef."Test Case No." := TestCaseNo;
                ILERef."Iteration No." := IterationNo;
                ILERef.TransferFields("Item Ledger Entry");
                if not ILERef.Insert() then
                    ILERef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                ILERef.SetRange("Use Case No.", UseCaseNo);
                ILERef.SetRange("Test Case No.", TestCaseNo);
                ILERef.SetRange("Iteration No.", IterationNo);
                if ILERef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', ILERef.TableName), false)
                    then
                        CurrReport.Break();
                ILERef.DeleteAll();
                ILERef.Reset();
            end;
        }
        dataitem("Item Journal Line"; "Item Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Line No.";
            RequestFilterHeading = 'ItemJnl.Line';

            trigger OnAfterGetRecord()
            begin
                IJLRef."Use Case No." := UseCaseNo;
                IJLRef."Test Case No." := TestCaseNo;
                IJLRef."Iteration No." := IterationNo;
                IJLRef.TransferFields("Item Journal Line");
                if not IJLRef.Insert() then
                    IJLRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                IJLRef.SetRange("Use Case No.", UseCaseNo);
                IJLRef.SetRange("Test Case No.", TestCaseNo);
                IJLRef.SetRange("Iteration No.", IterationNo);
                if IJLRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', IJLRef.TableName), false)
                    then
                        CurrReport.Break();
                IJLRef.DeleteAll();
                IJLRef.Reset();
            end;
        }
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Item';

            trigger OnAfterGetRecord()
            var
                AverageCostLCY: Decimal;
                AverageCostACY: Decimal;
            begin
                ItemRef."Use Case No." := UseCaseNo;
                ItemRef."Test Case No." := TestCaseNo;
                ItemRef."Iteration No." := IterationNo;
                CalcFields(
                  "Assembly BOM", Comment, Inventory, "Net Invoiced Qty.", "Net Change",
                  "Purchases (Qty.)", "Sales (Qty.)", "Positive Adjmt. (Qty.)", "Negative Adjmt. (Qty.)", "Purchases (LCY)",
                  "Sales (LCY)", "Positive Adjmt. (LCY)", "Negative Adjmt. (LCY)", "COGS (LCY)", "Qty. on Purch. Order", "Qty. on Sales Order",
                  "Transferred (Qty.)", "Transferred (LCY)", "Reserved Qty. on Inventory"
                  );
                CalcFields(
                  "Reserved Qty. on Purch. Orders", "Reserved Qty. on Sales Orders", "Scheduled Receipt (Qty.)",
                  "Reserved Qty. on Prod. Order", "Res. Qty. on Prod. Order Comp.",
                  "Qty. in Transit", "Trans. Ord. Receipt (Qty.)", "Qty. Assigned to ship", "Qty. on Service Order",
                  "Qty. on Prod. Order", "Qty. on Component Lines"
                  );
                ItemCostMgmt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
                AverageCostLCY := Round(AverageCostLCY, 0.00001);
                AverageCostACY := Round(AverageCostACY, 0.00001);
                ItemRef.TransferFields(Item);
                ItemRef."Assembly BOM" := "Assembly BOM";
                ItemRef.Comment := Comment;
                ItemRef.Inventory := Inventory;
                ItemRef."Net Invoiced Qty." := "Net Invoiced Qty.";
                ItemRef."Net Change" := "Net Change";
                ItemRef."Purchases (Qty.)" := "Purchases (Qty.)";
                ItemRef."Sales (Qty.)" := "Sales (Qty.)";
                ItemRef."Positive Adjmt. (Qty.)" := "Positive Adjmt. (Qty.)";
                ItemRef."Negative Adjmt. (Qty.)" := "Negative Adjmt. (Qty.)";
                ItemRef."Purchases (LCY)" := "Purchases (LCY)";
                ItemRef."Sales (LCY)" := "Sales (LCY)";
                ItemRef."Positive Adjmt. (LCY)" := "Positive Adjmt. (LCY)";
                ItemRef."Negative Adjmt. (LCY)" := "Negative Adjmt. (LCY)";
                ItemRef."COGS (LCY)" := "COGS (LCY)";
                ItemRef."Qty. on Purch. Order" := "Qty. on Purch. Order";
                ItemRef."Qty. on Sales Order" := "Qty. on Sales Order";
                ItemRef."Transferred (Qty.)" := "Transferred (Qty.)";
                ItemRef."Transferred (LCY)" := "Transferred (LCY)";
                ItemRef."Reserved Qty. on Inventory" := "Reserved Qty. on Inventory";
                ItemRef."Reserved Qty. on Purch. Orders" := "Reserved Qty. on Purch. Orders";
                ItemRef."Reserved Qty. on Sales Orders" := "Reserved Qty. on Sales Orders";
                ItemRef."Scheduled Receipt (Qty.)" := "Scheduled Receipt (Qty.)";
                ItemRef."Qty. on Component Lines" := "Qty. on Component Lines";
                ItemRef."Reserved Qty. on Prod. Order" := "Reserved Qty. on Prod. Order";
                ItemRef."Res. Qty. on Prod. Order Comp." := "Res. Qty. on Prod. Order Comp.";
                ItemRef."Qty. in Transit" := "Qty. in Transit";
                ItemRef."Trans. Ord. Receipt (Qty.)" := "Trans. Ord. Receipt (Qty.)";
                ItemRef."Qty. Assigned to ship" := "Qty. Assigned to ship";
                ItemRef."Qty. on Service Order" := "Qty. on Service Order";
                ItemRef."Qty. on Prod. Order" := "Qty. on Prod. Order";
                ItemRef."Qty. on Component Lines" := "Qty. on Component Lines";
                ItemRef."Average Cost (LCY)" := AverageCostLCY;
                ItemRef."Average Cost (ACY)" := AverageCostACY;
                if not ItemRef.Insert() then
                    ItemRef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                ItemRef.SetRange("Use Case No.", UseCaseNo);
                ItemRef.SetRange("Test Case No.", TestCaseNo);
                ItemRef.SetRange("Iteration No.", IterationNo);
                if ItemRef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', ItemRef.TableName), false)
                    then
                        CurrReport.Break();
                ItemRef.DeleteAll();
                ItemRef.Reset();
            end;
        }
        dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
        {
            DataItemTableView = sorting("Location Code", "Item No.", "Variant Code");
            RequestFilterFields = "Item No.", "Variant Code", "Location Code";
            RequestFilterHeading = 'SKU';

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                InvtSetup: Record "Inventory Setup";
                AverageCostLCY: Decimal;
                AverageCostACY: Decimal;
            begin
                SKURef."Use Case No." := UseCaseNo;
                SKURef."Test Case No." := TestCaseNo;
                SKURef."Iteration No." := IterationNo;
                CalcFields(
                  Description, "Description 2", "Assembly BOM", Comment, Inventory, "Qty. on Purch. Order", "Qty. on Sales Order",
                  "Scheduled Receipt (Qty.)", "Qty. on Component Lines", "Qty. in Transit",
                  "Trans. Ord. Receipt (Qty.)", "Trans. Ord. Shipment (Qty.)",
                  "Planned Order Receipt (Qty.)", "FP Order Receipt (Qty.)", "Rel. Order Receipt (Qty.)", "Planned Order Release (Qty.)",
                  "Purch. Req. Receipt (Qty.)", "Purch. Req. Release (Qty.)"
                  );

                Item.Reset();
                if Item.Get("Item No.") then begin
                    InvtSetup.Get();
                    if InvtSetup."Average Cost Calc. Type" = InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant" then begin
                        Item.SetRange("Location Filter", "Location Code");
                        Item.SetRange("Variant Filter", "Variant Code");
                    end;
                end;
                ItemCostMgmt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
                AverageCostLCY := Round(AverageCostLCY, 0.00001);
                AverageCostACY := Round(AverageCostACY, 0.00001);
                SKURef.TransferFields("Stockkeeping Unit");
                SKURef.Description := Description;
                SKURef."Description 2" := "Description 2";
                SKURef."Assembly BOM" := "Assembly BOM";
                SKURef.Comment := Comment;
                SKURef.Inventory := Inventory;
                SKURef."Qty. on Purch. Order" := "Qty. on Purch. Order";
                SKURef."Qty. on Sales Order" := "Qty. on Sales Order";
                SKURef."Scheduled Receipt (Qty.)" := "Scheduled Receipt (Qty.)";
                SKURef."Scheduled Need (Qty.)" := "Qty. on Component Lines";
                SKURef."Qty. in Transit" := "Qty. in Transit";
                SKURef."Trans. Ord. Receipt (Qty.)" := "Trans. Ord. Receipt (Qty.)";
                SKURef."Trans. Ord. Shipment (Qty.)" := "Trans. Ord. Shipment (Qty.)";
                SKURef."Planned Order Receipt (Qty.)" := "Planned Order Receipt (Qty.)";
                SKURef."FP Order Receipt (Qty.)" := "FP Order Receipt (Qty.)";
                SKURef."Rel. Order Receipt (Qty.)" := "Rel. Order Receipt (Qty.)";
                SKURef."Planned Order Release (Qty.)" := "Planned Order Release (Qty.)";
                SKURef."Purch. Req. Receipt (Qty.)" := "Purch. Req. Receipt (Qty.)";
                SKURef."Purch. Req. Release (Qty.)" := "Purch. Req. Release (Qty.)";
                SKURef."Average Cost (LCY)" := AverageCostLCY;
                SKURef."Average Cost (ACY)" := AverageCostACY;
                if not SKURef.Insert() then
                    SKURef.Modify();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilters = '' then
                    CurrReport.Break();

                SKURef.SetRange("Use Case No.", UseCaseNo);
                SKURef.SetRange("Test Case No.", TestCaseNo);
                SKURef.SetRange("Iteration No.", IterationNo);
                if SKURef.FindFirst() then
                    if not Confirm(
                         StrSubstNo('%1 already exists - do you want to replace ?', SKURef.TableName), false)
                    then
                        CurrReport.Break();
                SKURef.DeleteAll();
                SKURef.Reset();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CheckIteration();
    end;

    var
        TestIteration: Record "Test Iteration";
        ILERef: Record "Item Ledger Entry Ref.";
        IJLRef: Record "Item Journal Line Ref.";
        VERef: Record "Value Entry Ref.";
        GLERef: Record "G/L Entry Ref.";
        ItemRef: Record "Item Ref.";
        SKURef: Record "SKU Ref.";
        ItemCostMgmt: Codeunit ItemCostManagement;
        UseCaseNo: Integer;
        TestCaseNo: Integer;
        IterationNo: Integer;

    [Scope('OnPrem')]
    procedure CheckIteration()
    begin
        TestIteration.Reset();
        TestIteration.SetRange("Use Case No.", UseCaseNo);
        TestIteration.SetRange("Test Case No.", TestCaseNo);
        TestIteration.SetRange("Iteration No.", IterationNo);
        TestIteration.FindFirst();
    end;
}

