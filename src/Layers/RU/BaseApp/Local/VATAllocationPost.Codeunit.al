#pragma warning disable AA0247
codeunit 12417 "VAT Allocation-Post"
{
    Permissions = TableData "Purchase Header" = r,
                  TableData "Purchase Line" = r,
                  TableData "Purch. Rcpt. Line" = r,
                  TableData "Item Charge Assignment (Purch)" = imd,
                  TableData "Return Shipment Line" = r;

    trigger OnRun()
    begin
    end;

    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)" temporary;
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        GLSetup: Record "General Ledger Setup";
#pragma warning disable AA0074
        Text000: Label 'Related item ledger entries cannot be found.';
#pragma warning restore AA0074
        TempValueEntry: Record "Value Entry" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        ItemReg: Record "Item Register";
        TotalChargeAmt: Decimal;
        TotalChargeAmtLCY: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Fixed Asset %1 should be on inventory or released.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'You cannot reverse the transaction, because it has already been reversed.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'The combination of dimensions used in %1 %2 is blocked. %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NextReverseEntryNo: Integer;
        RoundingPrecision: Decimal;

    [Scope('OnPrem')]
    procedure PostItem(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line")
    var
        TotalAmount: Decimal;
        QtyRemainder: Decimal;
        AmountRemainder: Decimal;
        NextLineNo: Integer;
    begin
        GLSetup.Get();
        NextLineNo := 0;

        SourceCodeSetup.Get();

        VATPostingSetup.Get(VATAllocLine."VAT Bus. Posting Group", VATAllocLine."VAT Prod. Posting Group");

        InitiItemChargeAssgntBuffer(TempItemChargeAssgntPurch, TempItemChargeAssgntSales);
        RoundingPrecision := GLSetup."Amount Rounding Precision";

        // initialize
        TotalAmount := 0;
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Vendor:
                begin
                    FillItemChargeAssgntPurch(GenJnlLine, VATAllocLine, TotalAmount, NextLineNo);
                    AllocateItemChargeAssgntPurch(VATAllocLine, TotalAmount, QtyRemainder, AmountRemainder);
                    PostItemChargeAssgntPurch(GenJnlLine);
                end;
            GenJnlLine."Account Type"::Customer:
                begin
                    FillItemChargeAssgntSales(GenJnlLine, VATAllocLine, TotalAmount, NextLineNo);
                    AllocateItemChargeAssgntSales(VATAllocLine, TotalAmount, QtyRemainder, AmountRemainder);
                    PostItemChargeAssgntSales(GenJnlLine);
                end;
            else
                GenJnlLine.FieldError("Account Type");
        end;
    end;

    local procedure PostItemChargePerPurchInvLine(GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        PurchInvLine.TestField("Job No.", '');
        Sign := GetEntrySign(PurchInvLine."Quantity (Base)");

        DistributeCharge := false;
        PurchInvLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Inv. Line", 0, PurchInvLine."Document No.",
              '', 0, PurchInvLine."Line No.", PurchInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet() then begin
                NonDistrQuantity := PurchInvLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostPurchInvItemCharge(GenJnlLine, PurchInvHeader, PurchInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, PurchInvLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostPurchInvItemCharge(GenJnlLine, PurchInvHeader, PurchInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, PurchInvLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostPurchInvItemCharge(GenJnlLine, PurchInvHeader, PurchInvLine,
              TempItemLedgEntry."Entry No.", PurchInvLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              PurchInvLine."Indirect Cost %",
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostItemChargePerPurchCrMLine(GenJnlLine: Record "Gen. Journal Line"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        PurchCrMemoLine.TestField("Job No.", '');
        Sign := GetEntrySign(PurchCrMemoLine."Quantity (Base)");

        DistributeCharge := false;
        PurchCrMemoLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Inv. Line", 0, PurchCrMemoLine."Document No.",
              '', 0, PurchCrMemoLine."Line No.", PurchInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet() then begin
                NonDistrQuantity := PurchCrMemoLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntPurch."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntPurch."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostPurchCrMemoItemCharge(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign, PurchCrMemoLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostPurchCrMemoItemCharge(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign, PurchCrMemoLine."Indirect Cost %",
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostPurchCrMemoItemCharge(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine,
              TempItemLedgEntry."Entry No.", PurchCrMemoLine."Quantity (Base)",
              TempItemChargeAssgntPurch."Amount to Assign" * Sign,
              PurchCrMemoLine."Indirect Cost %",
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostItemChargePerSalesInvLine(GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesInvLine: Record "Sales Invoice Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        SalesInvLine.TestField("Job No.", '');
        Sign := GetEntrySign(SalesInvLine."Quantity (Base)");

        DistributeCharge := false;
        SalesInvLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Sales Invoice Line", 0, SalesInvLine."Document No.",
              '', 0, SalesInvLine."Line No.", SalesInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet() then begin
                NonDistrQuantity := SalesInvLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntSales."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntSales."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostSalesInvItemCharge(GenJnlLine, SalesInvHeader, SalesInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostSalesInvItemCharge(GenJnlLine, SalesInvHeader, SalesInvLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostSalesInvItemCharge(GenJnlLine, SalesInvHeader, SalesInvLine,
              TempItemLedgEntry."Entry No.", SalesInvLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign" * Sign,
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostItemChargePerSalesCrMLine(GenJnlLine: Record "Gen. Journal Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Factor: Decimal;
        NonDistrQuantity: Decimal;
        NonDistrQtyToAssign: Decimal;
        NonDistrAmountToAssign: Decimal;
        QtyToAssign: Decimal;
        AmountToAssign: Decimal;
        Sign: Decimal;
        DistributeCharge: Boolean;
    begin
        SalesCrMemoLine.TestField("Job No.", '');
        Sign := GetEntrySign(SalesCrMemoLine."Quantity (Base)");

        DistributeCharge := false;
        SalesCrMemoLine.GetItemLedgEntries(TempItemLedgEntry, false);
        if TempItemLedgEntry.Count > 1 then begin
            DistributeCharge := true;
            ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry,
              DATABASE::"Purch. Inv. Line", 0, SalesCrMemoLine."Document No.",
              '', 0, SalesCrMemoLine."Line No.", SalesInvLine."Quantity (Base)");
        end else
            TempItemLedgEntry.FindSet();

        if DistributeCharge then
            if TempItemLedgEntry.FindSet() then begin
                NonDistrQuantity := SalesCrMemoLine."Quantity (Base)";
                NonDistrQtyToAssign := TempItemChargeAssgntSales."Qty. to Assign";
                NonDistrAmountToAssign := TempItemChargeAssgntSales."Amount to Assign";
                repeat
                    Factor := TempItemLedgEntry.Quantity / NonDistrQuantity;
                    QtyToAssign := NonDistrQtyToAssign * Factor;
                    AmountToAssign := Round(NonDistrAmountToAssign * Factor, GLSetup."Amount Rounding Precision");
                    if Factor < 1 then begin
                        PostSalesCrMemoItemCharge(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          AmountToAssign * Sign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                        NonDistrQuantity := NonDistrQuantity - TempItemLedgEntry.Quantity;
                        NonDistrQtyToAssign := NonDistrQtyToAssign - QtyToAssign;
                        NonDistrAmountToAssign := NonDistrAmountToAssign - AmountToAssign;
                    end else // the last time
                        PostSalesCrMemoItemCharge(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine,
                          TempItemLedgEntry."Entry No.", TempItemLedgEntry.Quantity,
                          NonDistrAmountToAssign * Sign,
                          TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
                until TempItemLedgEntry.Next() = 0;
            end else
                Error(Text000)
        else
            PostSalesCrMemoItemCharge(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine,
              TempItemLedgEntry."Entry No.", SalesCrMemoLine."Quantity (Base)",
              TempItemChargeAssgntSales."Amount to Assign" * Sign,
              TempItemLedgEntry."Serial No.", TempItemLedgEntry."Lot No.");
    end;

    local procedure PostPurchInvItemCharge(GenJnlLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; IndirectCostPct: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        PrepareGenJnlLinePurch(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
          IndirectCostPct, ItemJnlLine."Document Type"::"Purchase Invoice");

        ItemJnlLine.CopyFromPurchInvHeader(PurchInvHeader);
        ItemJnlLine.CopyFromPurchInvLine(PurchInvLine);
        ItemJnlLine.Quantity := 0;
        ItemJnlLine."Quantity (Base)" := 0;

        if PurchInvHeader."Currency Code" <> '' then begin
            Currency.Get(PurchInvHeader."Currency Code");
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
            TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
            if PurchInvHeader."Currency Code" <> '' then
                ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchInvHeader."Currency Code", TotalChargeAmt, PurchInvHeader."Currency Factor");
        end else
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

        ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
        if PurchInvHeader."Currency Code" <> '' then
            TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure PostPurchCrMemoItemCharge(GenJnlLine: Record "Gen. Journal Line"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; PurchCrMemoLine: Record "Purch. Cr. Memo Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; IndirectCostPct: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        PrepareGenJnlLinePurch(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
          IndirectCostPct, ItemJnlLine."Document Type"::"Purchase Credit Memo");

        ItemJnlLine.CopyFromPurchCrMemoHeader(PurchCrMemoHeader);
        ItemJnlLine.CopyFromPurchCrMemoLine(PurchCrMemoLine);
        ItemJnlLine.Quantity := 0;
        ItemJnlLine."Quantity (Base)" := 0;

        if PurchCrMemoHeader."Currency Code" <> '' then begin
            Currency.Get(PurchCrMemoHeader."Currency Code");
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
            TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
            if PurchCrMemoHeader."Currency Code" <> '' then
                ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, PurchCrMemoHeader."Currency Code", TotalChargeAmt, PurchCrMemoHeader."Currency Factor");
        end else
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

        ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
        if PurchCrMemoHeader."Currency Code" <> '' then
            TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure PostSalesInvItemCharge(GenJnlLine: Record "Gen. Journal Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesInvLine: Record "Sales Invoice Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        PrepareGenJnlLineSales(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
          ItemJnlLine."Document Type"::"Sales Invoice");

        ItemJnlLine.CopyFromSalesInvHeader(SalesInvHeader);
        ItemJnlLine.CopyFromSalesInvLine(SalesInvLine);
        ItemJnlLine.Quantity := 0;
        ItemJnlLine."Quantity (Base)" := 0;

        if SalesInvHeader."Currency Code" <> '' then begin
            Currency.Get(SalesInvHeader."Currency Code");
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
            TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
            if SalesInvHeader."Currency Code" <> '' then
                ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, SalesInvHeader."Currency Code", TotalChargeAmt, SalesInvHeader."Currency Factor");
        end else
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

        ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
        if SalesInvHeader."Currency Code" <> '' then
            TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure PostSalesCrMemoItemCharge(GenJnlLine: Record "Gen. Journal Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesCrMemoLine: Record "Sales Cr.Memo Line"; ItemEntryNo: Integer; QuantityBase: Decimal; AmountToAssign: Decimal; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemJnlLine: Record "Item Journal Line";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        Usedate: Date;
    begin
        PrepareGenJnlLineSales(ItemJnlLine, GenJnlLine, SerialNo, LotNo, AmountToAssign, ItemEntryNo,
          ItemJnlLine."Document Type"::"Sales Credit Memo");

        ItemJnlLine.CopyFromSalesCrMemoHeader(SalesCrMemoHeader);
        ItemJnlLine.CopyFromSalesCrMemoLine(SalesCrMemoLine);
        ItemJnlLine.Quantity := 0;
        ItemJnlLine."Quantity (Base)" := 0;

        if SalesCrMemoHeader."Currency Code" <> '' then begin
            Currency.Get(SalesCrMemoHeader."Currency Code");
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, Currency."Unit-Amount Rounding Precision");
            TotalChargeAmt := TotalChargeAmt + ItemJnlLine.Amount;
            if SalesCrMemoHeader."Currency Code" <> '' then
                ItemJnlLine.Amount := CurrExchRate.ExchangeAmtFCYToLCY(
                    Usedate, SalesCrMemoHeader."Currency Code", TotalChargeAmt, SalesCrMemoHeader."Currency Factor");
        end else
            ItemJnlLine."Unit Cost" := Round(
                ItemJnlLine.Amount / QuantityBase, GLSetup."Unit-Amount Rounding Precision");

        ItemJnlLine.Amount := Round(ItemJnlLine.Amount, GLSetup."Amount Rounding Precision") - TotalChargeAmtLCY;
        if PurchCrMemoHeader."Currency Code" <> '' then
            TotalChargeAmtLCY := TotalChargeAmtLCY + ItemJnlLine.Amount;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PostFAAllocation(GenJnlLine: Record "Gen. Journal Line"; VATAllocation: Record "VAT Allocation Line"; var DeprAmount: Decimal; var DeprBookCode: Code[10])
    var
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        FAJnlLine: Record "FA Journal Line";
        FALedgEntry: Record "FA Ledger Entry";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
    begin
        FASetup.Get();
        FASetup.TestField("Default Depr. Book");
        FASetup.TestField("Release Depr. Book");

        SourceCodeSetup.Get();

        GenJnlLine.TestField("Object Type", GenJnlLine."Object Type"::"Fixed Asset");

        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", GenJnlLine."Document No.");
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"Fixed Asset");
        PurchInvLine.SetRange("No.", GenJnlLine."Object No.");
        PurchInvLine.SetRange("VAT Bus. Posting Group", VATAllocation."VAT Bus. Posting Group");
        PurchInvLine.SetRange("VAT Prod. Posting Group", VATAllocation."VAT Prod. Posting Group");
        if PurchInvLine.FindFirst() then begin
            FA.Get(PurchInvLine."No.");
            FADeprBook.Get(FA."No.", FA.GetDefDeprBook());
            FADeprBook.CalcFields("Book Value");
            if FADeprBook."Book Value" <> 0 then // not released to operation
                DeprBookCode := FA.GetDefDeprBook()
            else begin
                FADeprBook.Get(FA."No.", FASetup."Release Depr. Book");
                FADeprBook.CalcFields("Book Value");
                if (FADeprBook."Book Value" <> 0) or FA."Undepreciable FA" then // in operation
                    DeprBookCode := FASetup."Release Depr. Book"
                else
                    Error(Text001, FA."No.");
            end;

            FAJnlLine.Init();
            FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
            FAJnlLine.Validate("FA Posting Type", FAJnlLine."FA Posting Type"::"Acquisition Cost");
            FAJnlLine.Validate("FA No.", FA."No.");
            FAJnlLine."Posting Date" := GenJnlLine."Posting Date";
            if FADeprBook."Last Depreciation Date" <> 0D then begin
                FAJnlLine."FA Posting Date" := FADeprBook."Last Depreciation Date";
                FAJnlLine."Depr. Acquisition Cost" := true;
                FAJnlLine."Depr. until FA Posting Date" := true;
            end else
                FAJnlLine."FA Posting Date" := FAJnlLine."Posting Date";
            FAJnlLine."Document Type" := GenJnlLine."Document Type";
            FAJnlLine."Document No." := GenJnlLine."Document No.";
            FAJnlLine.Description := PurchInvLine.Description;
            FAJnlLine.Quantity := 0;
            FAJnlLine.Validate(Amount, VATAllocation.Amount);
            FAJnlLine."Shortcut Dimension 1 Code" := PurchInvLine."Shortcut Dimension 1 Code";
            FAJnlLine."Shortcut Dimension 2 Code" := PurchInvLine."Shortcut Dimension 2 Code";
            FAJnlLine."Dimension Set ID" := PurchInvLine."Dimension Set ID";
            FAJnlLine."Source Code" := SourceCodeSetup."VAT Allocation on Cost";
            FAJnlLine."Reason Code" := GenJnlLine."Reason Code";
            FAJnlPostLine.FAJnlPostLine(FAJnlLine, false);

            FALedgEntry.Reset();
            FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
            FALedgEntry.SetRange("FA No.", FA."No.");
            FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
            FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::Depreciation);
            if FALedgEntry.FindLast() then
                DeprAmount := FALedgEntry.Amount;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertItemReverseEntry(ValueEntryNo: Integer; var ReversalEntry: Record "Reversal Entry"): Integer
    var
        SourceCodeSetup: Record "Source Code Setup";
        ValueEntry: Record "Value Entry";
        ValueEntry3: Record "Value Entry";
        InvtSetup: Record "Inventory Setup";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
    begin
        ValueEntry3.Get(ValueEntryNo);
        ValueEntry3.TestField("Reversed by Entry No.", 0);

        if not DimMgt.CheckDimIDComb(ValueEntry3."Dimension Set ID") then
            Error(Text006, ValueEntry3.TableCaption(), ValueEntry3."Entry No.", DimMgt.GetDimCombErr());
        Clear(TableID);
        Clear(AccNo);
        TableID[1] := DATABASE::Item;
        AccNo[1] := ValueEntry3."Item No.";
        if not DimMgt.CheckDimValuePosting(TableID, AccNo, ValueEntry3."Dimension Set ID") then
            Error(DimMgt.GetDimValuePostingErr());
        if NextReverseEntryNo = 0 then begin
            ValueEntry.LockTable();
            if ValueEntry.FindLast() then
                NextReverseEntryNo := ValueEntry."Entry No.";
            SourceCodeSetup.Get();
            InvtSetup.Get();
        end;
        NextReverseEntryNo := NextReverseEntryNo + 1;
        TempValueEntry := ValueEntry3;
        TempValueEntry.Insert();
        SetItemReversalMark(ReversalEntry, ValueEntry3, NextReverseEntryNo);
        ValueEntry3."Entry No." := NextReverseEntryNo;
        ValueEntry3."Cost Amount (Actual)" := -ValueEntry3."Cost Amount (Actual)";
        ValueEntry3."Cost Posted to G/L" := -ValueEntry3."Cost Posted to G/L";
        ValueEntry3."Cost Amount (Actual) (ACY)" := -ValueEntry3."Cost Amount (Actual) (ACY)";
        ValueEntry3."Cost Posted to G/L (ACY)" := -ValueEntry3."Cost Posted to G/L (ACY)";
        ValueEntry3."Valued Quantity" := -ValueEntry3."Valued Quantity";
        ValueEntry3."User ID" := UserId;
        ValueEntry3."Source Code" := SourceCodeSetup.Reversal;
        ValueEntry3."Journal Batch Name" := '';
        ValueEntry3."Red Storno" := InvtSetup."Enable Red Storno";
        ValueEntry3."Dimension Set ID" := TempValueEntry."Dimension Set ID";
        ValueEntry3.Insert();
        InsertItemReg(NextReverseEntryNo, ValueEntry3."Source Code");
        exit(NextReverseEntryNo);
    end;

    local procedure SetItemReversalMark(var ReversalEntry: Record "Reversal Entry"; var ValueEntry: Record "Value Entry"; NextEntryNo: Integer)
    var
        ValueEntry2: Record "FA Ledger Entry";
        CloseReversal: Boolean;
    begin
        if ValueEntry."Reversed Entry No." <> 0 then begin
            ValueEntry2.Get(ValueEntry."Reversed Entry No.");
            if ValueEntry2."Reversed Entry No." <> 0 then
                Error(Text005);
            CloseReversal := true;
            ValueEntry2."Reversed by Entry No." := 0;
            ValueEntry2.Reversed := false;
            ValueEntry2.Modify();
        end;
        ValueEntry."Reversed by Entry No." := NextEntryNo;
        if CloseReversal then
            ValueEntry."Reversed Entry No." := NextEntryNo;
        ValueEntry.Reversed := true;
        ValueEntry.Modify();
        ValueEntry."Reversed by Entry No." := 0;
        ValueEntry."Reversed Entry No." := ValueEntry."Entry No.";
        if CloseReversal then
            ValueEntry."Reversed by Entry No." := ValueEntry."Entry No.";
        ReversalEntry.SetCurrentKey("Entry Type");
        ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"Fixed Asset");
        if ReversalEntry.FindFirst() then
            repeat
                if ReversalEntry."Entry No." = ValueEntry."Entry No." then
                    ValueEntry.Description := ReversalEntry.Description;
            until ReversalEntry.Next() = 0;
    end;

    local procedure InsertItemReg(ValueEntryNo: Integer; SourceCode: Code[10])
    begin
        if ItemReg."No." = 0 then begin
            ItemReg.LockTable();
            if ItemReg.FindLast() then
                ItemReg."No." := ItemReg."No." + 1
            else
                ItemReg."No." := 1;
            ItemReg.Init();
            ItemReg."From Value Entry No." := ValueEntryNo;
            ItemReg."To Value Entry No." := ValueEntryNo;
            ItemReg."Creation Date" := Today;
            ItemReg."Source Code" := SourceCode;
            ItemReg."User ID" := UserId;
            ItemReg.Insert();
        end else begin
            if ((ValueEntryNo < ItemReg."From Value Entry No.") and (ValueEntryNo <> 0)) or
               ((ItemReg."From Value Entry No." = 0) and (ValueEntryNo > 0))
            then
                ItemReg."From Value Entry No." := ValueEntryNo;
            if ValueEntryNo > ItemReg."To Value Entry No." then
                ItemReg."To Value Entry No." := ValueEntryNo;

            ItemReg.Modify();
        end;
    end;

    local procedure InsertItemChargeAssgntPurch(var NextLineNo: Integer; DocumentNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; UnitCostLCY: Decimal; LineAmount: Decimal): Decimal
    begin
        TempItemChargeAssgntPurch.Init();
        TempItemChargeAssgntPurch."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        VATPostingSetup.TestField("VAT Charge No.");
        TempItemChargeAssgntPurch."Item Charge No." := VATPostingSetup."VAT Charge No.";
        TempItemChargeAssgntPurch."Applies-to Doc. Type" := TempItemChargeAssgntPurch."Applies-to Doc. Type"::Invoice;
        TempItemChargeAssgntPurch."Applies-to Doc. No." := DocumentNo;
        TempItemChargeAssgntPurch."Applies-to Doc. Line No." := LineNo;
        TempItemChargeAssgntPurch."Item No." := ItemNo;
        TempItemChargeAssgntPurch.Description := TempItemChargeAssgntPurch.Description;
        TempItemChargeAssgntPurch."Unit Cost" := UnitCostLCY;
        TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" := LineAmount;
        TempItemChargeAssgntPurch.Insert();
        exit(TempItemChargeAssgntPurch."Applies-to Doc. Line Amount");
    end;

    local procedure InsertItemChargeAssgntSales(NextLineNo: Integer; DocumentNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; UnitCostLCY: Decimal; LineAmount: Decimal): Decimal
    begin
        TempItemChargeAssgntSales.Init();
        TempItemChargeAssgntSales."Document Line No." := LineNo;
        TempItemChargeAssgntSales."Line No." := NextLineNo;
        NextLineNo := NextLineNo + 10000;
        VATPostingSetup.TestField("VAT Charge No.");
        TempItemChargeAssgntSales."Item Charge No." := VATPostingSetup."VAT Charge No.";
        TempItemChargeAssgntSales."Applies-to Doc. Type" := TempItemChargeAssgntSales."Applies-to Doc. Type"::Invoice;
        TempItemChargeAssgntSales."Applies-to Doc. No." := DocumentNo;
        TempItemChargeAssgntSales."Applies-to Doc. Line No." := LineNo;
        TempItemChargeAssgntSales."Item No." := ItemNo;
        TempItemChargeAssgntSales.Description := TempItemChargeAssgntSales.Description;
        TempItemChargeAssgntSales."Unit Cost" := UnitCostLCY;
        TempItemChargeAssgntSales."Applies-to Doc. Line Amount" := LineAmount;
        TempItemChargeAssgntSales.Insert();
        exit(TempItemChargeAssgntSales."Applies-to Doc. Line Amount");
    end;

    local procedure PrepareGenJnlLinePurch(var ItemJnlLine: Record "Item Journal Line"; GenJnlLine: Record "Gen. Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; AmountToAssign: Decimal; ItemEntryNo: Integer; IndirectCostPct: Decimal; DocumentType: Enum "Item Ledger Document Type")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := GenJnlLine."Posting Date";
        ItemJnlLine."Document Date" := GenJnlLine."Document Date";
        ItemJnlLine.Description := TempItemChargeAssgntPurch.Description;
        ItemJnlLine."Item No." := TempItemChargeAssgntPurch."Item No.";
        ItemJnlLine."Serial No." := SerialNo;
        ItemJnlLine."Lot No." := LotNo;
        ItemJnlLine."Job Purchase" := ItemJnlLine."Job No." <> '';
        ItemJnlLine."Drop Shipment" := false;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
        ItemJnlLine."Document Type" := DocumentType;
        ItemJnlLine."Invoice No." := GenJnlLine."Document No.";
        ItemJnlLine."External Document No." := GenJnlLine."External Document No.";
        ItemJnlLine."Invoiced Quantity" := TempItemChargeAssgntPurch."Qty. to Assign";
        ItemJnlLine."Invoiced Qty. (Base)" := TempItemChargeAssgntPurch."Qty. to Assign";
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";
        ItemJnlLine."Item Charge No." := TempItemChargeAssgntPurch."Item Charge No.";
        ItemJnlLine.Amount := AmountToAssign;
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Vendor;
        ItemJnlLine."Source Code" := SourceCodeSetup."VAT Allocation on Cost";
        ItemJnlLine."Applies-to Entry" := ItemEntryNo;
        ItemJnlLine."Item Shpt. Entry No." := ItemEntryNo;
        ItemJnlLine."Indirect Cost %" := IndirectCostPct;
    end;

    [Scope('OnPrem')]
    procedure PrepareGenJnlLineSales(var ItemJnlLine: Record "Item Journal Line"; GenJnlLine: Record "Gen. Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; AmountToAssign: Decimal; ItemEntryNo: Integer; DocumentType: Enum "Item Ledger Document Type")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Posting Date" := GenJnlLine."Posting Date";
        ItemJnlLine."Document Date" := GenJnlLine."Document Date";
        ItemJnlLine.Description := TempItemChargeAssgntSales.Description;
        ItemJnlLine."Item No." := TempItemChargeAssgntSales."Item No.";
        ItemJnlLine."Serial No." := SerialNo;
        ItemJnlLine."Lot No." := LotNo;
        ItemJnlLine."Job Purchase" := ItemJnlLine."Job No." <> '';
        ItemJnlLine."Drop Shipment" := false;
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Purchase;
        ItemJnlLine."Document Type" := DocumentType;
        ItemJnlLine."Invoice No." := GenJnlLine."Document No.";
        ItemJnlLine."External Document No." := GenJnlLine."External Document No.";
        ItemJnlLine."Invoiced Quantity" := TempItemChargeAssgntSales."Qty. to Assign";
        ItemJnlLine."Invoiced Qty. (Base)" := TempItemChargeAssgntSales."Qty. to Assign";
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";
        ItemJnlLine."Item Charge No." := TempItemChargeAssgntSales."Item Charge No.";
        ItemJnlLine.Amount := AmountToAssign;
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Vendor;
        ItemJnlLine."Source Code" := SourceCodeSetup."VAT Allocation on Cost";
        ItemJnlLine."Applies-to Entry" := ItemEntryNo;
        ItemJnlLine."Item Shpt. Entry No." := ItemEntryNo;
    end;

    [Scope('OnPrem')]
    procedure InitiItemChargeAssgntBuffer(var TempItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
        TempItemChargeAssgntPurch.Reset();
        TempItemChargeAssgntPurch.DeleteAll();
        TempItemChargeAssgntSales.Reset();
        TempItemChargeAssgntSales.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure GetEntrySign(Quantity: Decimal): Integer
    begin
        if Quantity > 0 then
            exit(1);
        exit(-1);
    end;

    [Scope('OnPrem')]
    procedure FillItemChargeAssgntPurch(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line"; var TotalAmount: Decimal; var NextLineNo: Integer)
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                begin
                    PurchInvLine.Reset();
                    PurchInvLine.SetRange("Document No.", GenJnlLine."Document No.");
                    PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
                    PurchInvLine.SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    PurchInvLine.SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if PurchInvLine.FindSet() then
                        repeat
                            TotalAmount := TotalAmount + InsertItemChargeAssgntPurch(NextLineNo, PurchInvLine."Document No.", PurchInvLine."Line No.",
                                PurchInvLine."No.", PurchInvLine."Unit Cost (LCY)", PurchInvLine."Line Amount");
                        until PurchInvLine.Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    PurchCrMemoLine.Reset();
                    PurchCrMemoLine.SetRange("Document No.", GenJnlLine."Document No.");
                    PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
                    PurchCrMemoLine.SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    PurchCrMemoLine.SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if PurchCrMemoLine.FindSet() then
                        repeat
                            TotalAmount := TotalAmount + InsertItemChargeAssgntPurch(NextLineNo, PurchCrMemoLine."Document No.", PurchCrMemoLine."Line No.",
                                PurchCrMemoLine."No.", PurchCrMemoLine."Unit Cost (LCY)", PurchCrMemoLine."Line Amount");
                        until PurchCrMemoLine.Next() = 0;
                end;
            else
                GenJnlLine.FieldError("Document Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure AllocateItemChargeAssgntPurch(VATAllocLine: Record "VAT Allocation Line"; TotalAmount: Decimal; QtyRemainder: Decimal; AmountRemainder: Decimal)
    var
        TempItemChargeAssgntPurch2: Record "Item Charge Assignment (Purch)" temporary;
    begin
        TempItemChargeAssgntPurch.Reset();
        if TempItemChargeAssgntPurch.FindSet() then
            repeat
                if TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntPurch2."Qty. to Assign" :=
                      TempItemChargeAssgntPurch."Applies-to Doc. Line Amount" / TotalAmount + QtyRemainder
                else
                    TempItemChargeAssgntPurch2."Qty. to Assign" := 0;

                TempItemChargeAssgntPurch."Qty. to Assign" :=
                  Round(TempItemChargeAssgntPurch2."Qty. to Assign", 0.00001);
                TempItemChargeAssgntPurch."Amount to Assign" :=
                  TempItemChargeAssgntPurch."Qty. to Assign" * VATAllocLine.Amount + AmountRemainder;
                AmountRemainder :=
                  TempItemChargeAssgntPurch."Amount to Assign" -
                  Round(TempItemChargeAssgntPurch."Amount to Assign", RoundingPrecision);
                QtyRemainder :=
                  TempItemChargeAssgntPurch."Qty. to Assign" - TempItemChargeAssgntPurch2."Qty. to Assign";
                TempItemChargeAssgntPurch."Amount to Assign" :=
                  Round(TempItemChargeAssgntPurch."Amount to Assign", RoundingPrecision);
                TempItemChargeAssgntPurch.Modify();
            until TempItemChargeAssgntPurch.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PostItemChargeAssgntPurch(GenJnlLine: Record "Gen. Journal Line")
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                begin
                    PurchInvHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntPurch.Reset();
                    if TempItemChargeAssgntPurch.FindSet() then
                        repeat
                            PurchInvLine.Get(
                              TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            PostItemChargePerPurchInvLine(GenJnlLine, PurchInvHeader, PurchInvLine);
                        until TempItemChargeAssgntPurch.Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    PurchCrMemoHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntPurch.Reset();
                    if TempItemChargeAssgntPurch.FindSet() then
                        repeat
                            PurchCrMemoLine.Get(
                              TempItemChargeAssgntPurch."Applies-to Doc. No.", TempItemChargeAssgntPurch."Applies-to Doc. Line No.");
                            PostItemChargePerPurchCrMLine(GenJnlLine, PurchCrMemoHeader, PurchCrMemoLine);
                        until TempItemChargeAssgntPurch.Next() = 0;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FillItemChargeAssgntSales(GenJnlLine: Record "Gen. Journal Line"; VATAllocLine: Record "VAT Allocation Line"; var TotalAmount: Decimal; NextLineNo: Integer)
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                begin
                    SalesInvLine.Reset();
                    SalesInvLine.SetRange("Document No.", GenJnlLine."Document No.");
                    SalesInvLine.SetRange(Type, SalesInvLine.Type::Item);
                    SalesInvLine.SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    SalesInvLine.SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if SalesInvLine.FindSet() then
                        repeat
                            TotalAmount :=
                              TotalAmount +
                              InsertItemChargeAssgntSales(
                                NextLineNo, SalesInvLine."Document No.", SalesInvLine."Line No.",
                                SalesInvLine."No.", SalesInvLine."Unit Cost (LCY)", SalesInvLine."Line Amount");
                        until SalesInvLine.Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.Reset();
                    SalesCrMemoLine.SetRange("Document No.", GenJnlLine."Document No.");
                    SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
                    SalesCrMemoLine.SetRange("VAT Bus. Posting Group", VATAllocLine."VAT Bus. Posting Group");
                    SalesCrMemoLine.SetRange("VAT Prod. Posting Group", VATAllocLine."VAT Prod. Posting Group");
                    if SalesCrMemoLine.FindSet() then
                        repeat
                            TotalAmount := TotalAmount + InsertItemChargeAssgntSales(NextLineNo, SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.",
                                SalesCrMemoLine."No.", SalesCrMemoLine."Unit Cost (LCY)", SalesCrMemoLine."Line Amount");
                        until SalesCrMemoLine.Next() = 0;
                end;
            else
                GenJnlLine.FieldError("Document Type");
        end;
    end;

    [Scope('OnPrem')]
    procedure AllocateItemChargeAssgntSales(VATAllocLine: Record "VAT Allocation Line"; TotalAmount: Decimal; QtyRemainder: Decimal; AmountRemainder: Decimal)
    var
        TempItemChargeAssgntSales2: Record "Item Charge Assignment (Sales)" temporary;
    begin
        TempItemChargeAssgntSales.Reset();
        if TempItemChargeAssgntSales.FindSet() then
            repeat
                if TempItemChargeAssgntSales."Applies-to Doc. Line Amount" <> 0 then
                    TempItemChargeAssgntSales2."Qty. to Assign" :=
                      TempItemChargeAssgntSales."Applies-to Doc. Line Amount" / TotalAmount + QtyRemainder
                else
                    TempItemChargeAssgntSales2."Qty. to Assign" := 0;

                TempItemChargeAssgntSales."Qty. to Assign" :=
                  Round(TempItemChargeAssgntSales2."Qty. to Assign", 0.00001);
                TempItemChargeAssgntSales."Amount to Assign" :=
                  TempItemChargeAssgntSales."Qty. to Assign" * VATAllocLine.Amount + AmountRemainder;
                AmountRemainder :=
                  TempItemChargeAssgntSales."Amount to Assign" -
                  Round(TempItemChargeAssgntSales."Amount to Assign", RoundingPrecision);
                QtyRemainder :=
                  TempItemChargeAssgntSales."Qty. to Assign" - TempItemChargeAssgntSales2."Qty. to Assign";
                TempItemChargeAssgntSales."Amount to Assign" :=
                  Round(TempItemChargeAssgntSales."Amount to Assign", RoundingPrecision);
                TempItemChargeAssgntSales.Modify();
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PostItemChargeAssgntSales(GenJnlLine: Record "Gen. Journal Line")
    begin
        case GenJnlLine."Document Type" of
            GenJnlLine."Document Type"::Invoice:
                begin
                    SalesInvHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntSales.Reset();
                    if TempItemChargeAssgntSales.FindSet() then
                        repeat
                            SalesInvLine.Get(
                              TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                            PostItemChargePerSalesInvLine(GenJnlLine, SalesInvHeader, SalesInvLine);
                        until TempItemChargeAssgntSales.Next() = 0;
                end;
            GenJnlLine."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.Get(GenJnlLine."Document No.");
                    TempItemChargeAssgntPurch.Reset();
                    if TempItemChargeAssgntSales.FindSet() then
                        repeat
                            SalesCrMemoLine.Get(
                              TempItemChargeAssgntSales."Applies-to Doc. No.", TempItemChargeAssgntSales."Applies-to Doc. Line No.");
                            PostItemChargePerSalesCrMLine(GenJnlLine, SalesCrMemoHeader, SalesCrMemoLine);
                        until TempItemChargeAssgntSales.Next() = 0;
                end;
        end;
    end;
}

