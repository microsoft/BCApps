#pragma warning disable AA0247
codeunit 12422 "Corrective Document Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Line No. %1 already exists in Corrective %2 No. %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CorrectionType: Option "Original Item","Item Charge";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Line No. %1 has already been corrected by Sales Invoice %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Line No. %1 has already been corrected by Sales Credit Memo %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'The dimensions used in %1 %2 should be equal to %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure GetSalesHeader(DocType: Option; DocNo: Code[20])
    begin
        SalesHeader.Get(DocType, DocNo);
        SalesHeader.TestField("Corrective Document");
        SalesHeader.TestField("Corrected Doc. Type");
        SalesHeader.TestField("Corrected Doc. No.");

        if SalesHeader."Currency Code" <> '' then
            Currency.Get(SalesHeader."Currency Code")
        else
            Currency.InitRoundingPrecision();
    end;

    procedure SetSalesHeader(DocType: Option; DocNo: Code[20])
    begin
        GetSalesHeader(DocType, DocNo);
    end;

    procedure SetCorrectionType(SelectedCorrectionType: Option)
    begin
        CorrectionType := SelectedCorrectionType;
    end;

    local procedure GetItemChargeAssgntLineNo(SalesLine: Record "Sales Line"): Integer
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", SalesLine."Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", SalesLine."Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", SalesLine."Line No.");
        ItemChargeAssgntSales.SetRange("Item Charge No.", SalesLine."No.");
        if ItemChargeAssgntSales.FindLast() then;
        exit(ItemChargeAssgntSales."Line No.");
    end;

    local procedure ItemShptChargeAssgnt(SalesLine: Record "Sales Line"; var TempSalesShptLine: Record "Sales Shipment Line")
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        ItemChargeAssgntSales.Init();
        ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
        ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
        ItemChargeAssgntSales."Document Line No." := SalesLine."Line No.";
        ItemChargeAssgntSales."Item Charge No." := SalesLine."No.";
        ItemChargeAssgntSales."Line No." := GetItemChargeAssgntLineNo(SalesLine);
        ItemChargeAssgntSales."Unit Cost" := SalesLine."Unit Price";

        TempSalesShptLine.FindSet();
        AssignItemChargeSales.CreateShptChargeAssgnt(TempSalesShptLine, ItemChargeAssgntSales);
    end;

    local procedure ItemRcptChargeAssgnt(SalesLine: Record "Sales Line"; var TempSalesReturnRcptLine: Record "Return Receipt Line")
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        ItemChargeAssgntSales.Init();
        ItemChargeAssgntSales."Document Type" := SalesLine."Document Type";
        ItemChargeAssgntSales."Document No." := SalesLine."Document No.";
        ItemChargeAssgntSales."Document Line No." := SalesLine."Line No.";
        ItemChargeAssgntSales."Item Charge No." := SalesLine."No.";
        ItemChargeAssgntSales."Line No." := GetItemChargeAssgntLineNo(SalesLine);
        ItemChargeAssgntSales."Unit Cost" := SalesLine."Unit Price";

        TempSalesReturnRcptLine.FindSet();
        AssignItemChargeSales.CreateRcptChargeAssgnt(TempSalesReturnRcptLine, ItemChargeAssgntSales);
    end;

    local procedure SalesItemChargeAssgnt(SalesLine: Record "Sales Line"; var TempSalesShptLine: Record "Sales Shipment Line"; var TempSalesReturnRcptLine: Record "Return Receipt Line")
    var
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        if not TempSalesShptLine.IsEmpty() then
            ItemShptChargeAssgnt(SalesLine, TempSalesShptLine);

        if not TempSalesReturnRcptLine.IsEmpty() then
            ItemRcptChargeAssgnt(SalesLine, TempSalesReturnRcptLine);

        AssignItemChargeSales.AssignItemCharges(
          SalesLine, SalesLine.Quantity, SalesLine."Line Amount", AssignItemChargeSales.AssignByAmountMenuText());
    end;

    local procedure CreateItemChargeAssignment(SalesLine: Record "Sales Line")
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempSalesShptLine: Record "Sales Shipment Line" temporary;
        TempReturnRcptLine: Record "Return Receipt Line" temporary;
    begin
        if SalesLine.Type <> SalesLine.Type::"Charge (Item)" then
            exit;

        case SalesLine."Original Doc. Type" of
            SalesLine."Original Doc. Type"::Invoice:
                GetSalesShptLines(
                  TempSalesShptLine,
                  SalesLine."Original Doc. No.",
                  GetSalesInvHeaderPostingDate(SalesLine."Original Doc. No."),
                  SalesLine."Original No.",
                  SalesLine."Corrected Doc. Line No.");
            SalesLine."Original Doc. Type"::"Credit Memo":
                GetSalesRcptLines(
                  TempReturnRcptLine,
                  SalesLine."Original Doc. No.",
                  GetSalesCrMHeaderPostingDate(SalesLine."Original Doc. No."),
                  SalesLine."Original No.",
                  SalesLine."Corrected Doc. Line No.");
        end;

        SetSalesInvCrMemoLineFilters(
          SalesInvLine,
          SalesCrMemoLine,
          SalesLine."Original Doc. Type",
          SalesLine."Original Doc. No.",
          SalesLine."Original Doc. Line No.");

        if SalesInvLine.FindSet() then
            repeat
                if SalesInvLine.Type = SalesInvLine.Type::Item then
                    GetSalesShptLines(
                      TempSalesShptLine,
                      SalesInvLine."Document No.",
                      GetSalesInvHeaderPostingDate(SalesInvLine."Document No."),
                      SalesInvLine."Original No.",
                      SalesInvLine."Line No.");
            until SalesInvLine.Next() = 0;

        if SalesCrMemoLine.FindSet() then
            repeat
                if SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item then
                    GetSalesRcptLines(
                      TempReturnRcptLine,
                      SalesCrMemoLine."Document No.",
                      GetSalesCrMHeaderPostingDate(SalesCrMemoLine."Document No."),
                      SalesCrMemoLine."Original No.",
                      SalesCrMemoLine."Line No.");
            until SalesCrMemoLine.Next() = 0;

        SalesItemChargeAssgnt(SalesLine, TempSalesShptLine, TempReturnRcptLine);
    end;

    local procedure GetSalesShptLines(var TempSalesShptLine: Record "Sales Shipment Line"; DocNo: Code[20]; PostingDate: Date; ItemNo: Code[20]; LineNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesShptLine: Record "Sales Shipment Line";
    begin
        ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Document No.", "Document Line No.");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.SetRange("Document No.", DocNo);
        ValueEntry.SetRange("Document Line No.", LineNo);
        if ValueEntry.FindSet() then
            repeat
                if (ValueEntry."Item Ledger Entry No." <> 0) and
                   (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost")
                then begin
                    ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                    if ValueEntry.ItemValueEntryExists() then
                        if SalesShptLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then begin
                            TempSalesShptLine := SalesShptLine;
                            if TempSalesShptLine.Insert() then;
                        end;
                end;
            until ValueEntry.Next() = 0;
    end;

    local procedure GetSalesRcptLines(var TempReturnReceiptLine: Record "Return Receipt Line"; DocNo: Code[20]; PostingDate: Date; ItemNo: Code[20]; LineNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Document No.", "Document Line No.");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.SetRange("Document No.", DocNo);
        ValueEntry.SetRange("Document Line No.", LineNo);
        if ValueEntry.FindSet() then
            repeat
                if (ValueEntry."Item Ledger Entry No." <> 0) and
                   (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost")
                then begin
                    ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                    if ValueEntry.ItemValueEntryExists() then
                        if ReturnRcptLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then begin
                            TempReturnReceiptLine := ReturnRcptLine;
                            if TempReturnReceiptLine.Insert() then;
                        end;
                end;
            until ValueEntry.Next() = 0;
    end;

    procedure CreateSalesLinesFromPstdInv(var SourceSalesInvLine: Record "Sales Invoice Line")
    var
        InventorySetup: Record "Inventory Setup";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        LineNo: Integer;
        ItemLine: Boolean;
    begin
        InventorySetup.Get();
        SalesInvLine.Copy(SourceSalesInvLine);
        LineNo := GetSalesLineNo(SalesHeader."Document Type", SalesHeader."No.");

        if SalesInvLine.FindSet() then
            repeat
                CheckSalesLineExists(SalesInvLine."Line No.");
                CheckSalesLineCorrected(SalesInvLine."Line No.");
                TempSalesLine.TransferFields(SalesInvLine);
                ItemLine :=
                  (SalesInvLine.Type = SalesInvLine.Type::Item) or
                  (SalesInvLine."Original Type" = SalesInvLine."Original Type"::Item);

                InsertSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", LineNo);

                if SalesInvLine.Type <> SalesInvLine.Type::" " then begin
                    if not ItemLine then begin
                        SalesLine.Validate(Type, SalesInvLine.Type);
                        SalesLine.Validate("No.", SalesInvLine."No.");
                    end else
                        ValidateItemLine(SalesLine, TempSalesLine);
                    ValidateCorrValues(SalesLine, TempSalesLine);
                end else begin
                    SalesLine."No." := SalesInvLine."No.";
                    SalesLine.Description := SalesInvLine.Description;
                end;
                SalesLine."Dimension Set ID" := SalesInvLine."Dimension Set ID";
                if InventorySetup."Enable Red Storno" and
                   (SalesLine.Type = SalesLine.Type::Item) and
                   (SalesLine."Document Type" in [SalesLine."Document Type"::"Credit Memo", SalesLine."Document Type"::"Return Order"])
                then
                    FindAndSetApplFromItemEntryNo(SalesLine, SalesInvLine);
                SalesLine.Modify();
                if ItemLine then
                    CreateItemChargeAssignment(SalesLine);
                if SalesLine.Type = SalesLine.Type::Item then
                    CreateItemTracking(SalesLine, TempSalesLine);
                LineNo := LineNo + 10000;
            until SalesInvLine.Next() = 0;
    end;

    procedure CreateSalesLinesFromPstdCrMemo(var SourceSalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        LineNo: Integer;
        ItemLine: Boolean;
    begin
        SalesCrMemoLine.Copy(SourceSalesCrMemoLine);
        LineNo := GetSalesLineNo(SalesHeader."Document Type", SalesHeader."No.");

        if SalesCrMemoLine.FindSet() then
            repeat
                CheckSalesLineExists(SalesCrMemoLine."Line No.");
                CheckSalesLineCorrected(SalesCrMemoLine."Line No.");
                TempSalesLine.TransferFields(SalesCrMemoLine);
                ItemLine :=
                  (SalesCrMemoLine.Type = SalesCrMemoLine.Type::Item) or
                  (SalesCrMemoLine."Original Type" = SalesCrMemoLine."Original Type"::Item);

                InsertSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", LineNo);

                if SalesCrMemoLine.Type <> SalesCrMemoLine.Type::" " then begin
                    if not ItemLine then begin
                        SalesLine.Validate(Type, SalesCrMemoLine.Type);
                        SalesLine.Validate("No.", SalesCrMemoLine."No.");
                    end else
                        ValidateItemLine(SalesLine, TempSalesLine);
                    ValidateCorrValues(SalesLine, TempSalesLine);
                end else begin
                    SalesLine."No." := SalesCrMemoLine."No.";
                    SalesLine.Description := SalesCrMemoLine.Description;
                end;
                SalesLine."Dimension Set ID" := SalesCrMemoLine."Dimension Set ID";
                SalesLine.Modify();
                if ItemLine then
                    CreateItemChargeAssignment(SalesLine);
                if SalesLine.Type = SalesLine.Type::Item then
                    CreateItemTracking(SalesLine, TempSalesLine);
                LineNo := LineNo + 10000;
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure GetSalesLineNo(DocType: Enum "Sales Document Type"; DocNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        if SalesLine.FindLast() then;
        exit(SalesLine."Line No." + 10000);
    end;

    local procedure InsertSalesLine(var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; DocNo: Code[20]; LineNo: Integer)
    begin
        SalesLine.Init();
        SalesLine."Document Type" := DocType;
        SalesLine."Document No." := DocNo;
        SalesLine."Line No." := LineNo;
        SalesLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure SelectPstdSalesDocLines()
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesInvoiceLines: Page "Sales Invoice Lines";
        SalesCreditMemoLines: Page "Sales Cr. Memo Lines";
    begin
        case SalesHeader."Corrected Doc. Type" of
            SalesHeader."Corrected Doc. Type"::Invoice:
                begin
                    SalesInvLine.SetRange("Document No.", SalesHeader."Corrected Doc. No.");
                    SalesInvoiceLines.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
                    SalesInvoiceLines.SetTableView(SalesInvLine);
                    SalesInvoiceLines.LookupMode := true;
                    if SalesInvoiceLines.RunModal() <> ACTION::Cancel then;
                end;
            SalesHeader."Corrected Doc. Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.SetRange("Document No.", SalesHeader."Corrected Doc. No.");
                    SalesCreditMemoLines.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
                    SalesCreditMemoLines.SetTableView(SalesCrMemoLine);
                    SalesCreditMemoLines.LookupMode := true;
                    if SalesCreditMemoLines.RunModal() <> ACTION::Cancel then;
                end;
        end;
    end;

    local procedure ValidateItemLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line")
    var
        InvPostingGroup: Record "Inventory Posting Group";
        CorrectedLine: Boolean;
    begin
        CorrectedLine := TempSalesLine."Corrected Doc. Line No." <> 0;
        if CorrectionType = CorrectionType::"Original Item" then begin
            if CorrectedLine then begin
                SalesLine.Validate(Type, TempSalesLine."Original Type");
                SalesLine.Validate("No.", TempSalesLine."Original No.");
            end else begin
                SalesLine.Validate(Type, TempSalesLine.Type);
                SalesLine.Validate("No.", TempSalesLine."No.");
            end;
            SalesLine.Validate("Location Code", TempSalesLine."Location Code");
            SalesLine."Posting Group" := TempSalesLine."Posting Group";
        end else
            case TempSalesLine.Type of
                TempSalesLine.Type::Item:
                    begin
                        InvPostingGroup.Get(TempSalesLine."Posting Group");
                        InvPostingGroup.TestField("Sales Corr. Doc. Charge (Item)");
                        SalesLine.Validate(Type, SalesLine.Type::"Charge (Item)");
                        SalesLine.Validate("No.", InvPostingGroup."Sales Corr. Doc. Charge (Item)");
                    end;
                TempSalesLine.Type::"Charge (Item)",
                TempSalesLine.Type::"G/L Account":
                    begin
                        SalesLine.Validate(Type, TempSalesLine.Type);
                        SalesLine.Validate("No.", TempSalesLine."No.");
                    end;
            end;
    end;

    local procedure ValidateCorrValues(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line")
    var
        CorrectedLine: Boolean;
    begin
        CorrectedLine := TempSalesLine."Corrected Doc. Line No." <> 0;
        SalesLine.Validate("Gen. Prod. Posting Group", TempSalesLine."Gen. Prod. Posting Group");
        SalesLine.Validate("VAT Prod. Posting Group", TempSalesLine."VAT Prod. Posting Group");
        SalesLine."Corrected Doc. Line No." := TempSalesLine."Line No.";
        SalesLine.Description := TempSalesLine.Description;
        if CorrectedLine then begin
            SalesLine."Original Doc. Type" := TempSalesLine."Original Doc. Type";
            SalesLine."Original Doc. No." := TempSalesLine."Original Doc. No.";
            SalesLine."Original Doc. Line No." := TempSalesLine."Original Doc. Line No.";
            SalesLine."Original Type" := TempSalesLine."Original Type";
            SalesLine."Original No." := TempSalesLine."Original No.";
            SalesLine."Quantity (Before)" := TempSalesLine."Quantity (After)";
            SalesLine."Quantity (After)" := TempSalesLine."Quantity (After)";
            SalesLine."Unit Price (Before)" := TempSalesLine."Unit Price (After)";
            SalesLine."Unit Price (After)" := TempSalesLine."Unit Price (After)";
            SalesLine."Amount (Before)" := TempSalesLine."Amount (After)";
            SalesLine."Amount Including VAT (Before)" := TempSalesLine."Amount Including VAT (After)";
            SalesLine."Amount (LCY) (Before)" := TempSalesLine."Amount (LCY) (After)";
            SalesLine."Amt. Incl. VAT (LCY) (Before)" := TempSalesLine."Amt. Incl. VAT (LCY) (After)";
        end else begin
            SalesLine."Original Doc. Type" := SalesHeader."Corrected Doc. Type";
            SalesLine."Original Doc. No." := SalesHeader."Corrected Doc. No.";
            SalesLine."Original Doc. Line No." := TempSalesLine."Line No.";
            SalesLine."Original Type" := TempSalesLine.Type.AsInteger();
            SalesLine."Original No." := TempSalesLine."No.";
            SalesLine."Quantity (Before)" := TempSalesLine.Quantity;
            SalesLine."Quantity (After)" := TempSalesLine.Quantity;
            SalesLine."Unit Price (Before)" := TempSalesLine."Unit Price";
            SalesLine."Unit Price (After)" := TempSalesLine."Unit Price";
            SalesLine."Amount (Before)" := TempSalesLine.Amount;
            SalesLine."Amount Including VAT (Before)" := TempSalesLine."Amount Including VAT";
            SalesLine."Amount (LCY) (Before)" := TempSalesLine."Amount (LCY)";
            SalesLine."Amt. Incl. VAT (LCY) (Before)" := TempSalesLine."Amount Including VAT (LCY)";
            if TempSalesLine."Line Discount %" <> 0 then begin
                SalesLine."Unit Price (Before)" :=
                  Round(SalesLine."Amount (Before)" / SalesLine."Quantity (Before)", Currency."Unit-Amount Rounding Precision");
                SalesLine."Unit Price (After)" := SalesLine."Unit Price (Before)";
            end;
        end;
        SalesLine.Validate(Quantity, SalesLine."Quantity (After)");
        SalesLine.Validate("Unit of Measure Code", TempSalesLine."Unit of Measure Code");
        SalesLine.Validate("Unit Price", SalesLine."Unit Price (After)");
        SalesLine.Validate("Line Discount %", 0);
    end;

    local procedure CheckSalesLineExists(CorrLineNo: Integer)
    var
        CorrSalesHeader: Record "Sales Header";
        CorrSalesLine: Record "Sales Line";
    begin
        CorrSalesHeader.Reset();
        CorrSalesHeader.SetCurrentKey("Corrective Document", "Corrected Doc. Type", "Corrected Doc. No.");
        CorrSalesHeader.SetRange("Corrective Document", true);
        CorrSalesHeader.SetRange("Corrected Doc. Type", SalesHeader."Corrected Doc. Type");
        CorrSalesHeader.SetRange("Corrected Doc. No.", SalesHeader."Corrected Doc. No.");
        CorrSalesHeader.SetFilter("No.", '<>%1', SalesHeader."No.");
        if CorrSalesHeader.FindSet() then
            repeat
                CorrSalesLine.Reset();
                CorrSalesLine.SetRange("Document Type", CorrSalesHeader."Document Type");
                CorrSalesLine.SetRange("Document No.", CorrSalesHeader."No.");
                CorrSalesLine.SetRange("Corrected Doc. Line No.", CorrLineNo);
                if CorrSalesLine.FindFirst() then
                    Error(Text001, CorrLineNo, CorrSalesLine."Document Type", CorrSalesLine."Document No.");
            until CorrSalesHeader.Next() = 0;
    end;

    local procedure CheckSalesLineCorrected(CorrLineNo: Integer)
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        if SalesHeader."Corrective Doc. Type" = SalesHeader."Corrective Doc. Type"::Revision then
            exit;

        SetSalesInvCrMemoLineFilters(
          SalesInvLine,
          SalesCrMemoLine,
          SalesHeader."Corrected Doc. Type",
          SalesHeader."Corrected Doc. No.",
          CorrLineNo);

        if SalesInvLine.FindFirst() then
            Error(Text002, CorrLineNo, SalesInvLine."Document No.");

        if SalesCrMemoLine.FindFirst() then
            Error(Text003, CorrLineNo, SalesCrMemoLine."Document No.");
    end;

    local procedure SetSalesInvCrMemoLineFilters(var SalesInvLine: Record "Sales Invoice Line"; var SalesCrMemoLine: Record "Sales Cr.Memo Line"; OriginalDocType: Option; OriginalDocNo: Code[20]; OriginalDocLineNo: Integer)
    begin
        SalesInvLine.Reset();
        SalesInvLine.SetCurrentKey("Original Doc. Type", "Original Doc. No.", "Original Doc. Line No.");
        SalesInvLine.SetRange("Original Doc. Type", OriginalDocType);
        SalesInvLine.SetRange("Original Doc. No.", OriginalDocNo);
        SalesInvLine.SetRange("Original Doc. Line No.", OriginalDocLineNo);

        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetCurrentKey("Original Doc. Type", "Original Doc. No.", "Original Doc. Line No.");
        SalesCrMemoLine.SetRange("Original Doc. Type", OriginalDocType);
        SalesCrMemoLine.SetRange("Original Doc. No.", OriginalDocNo);
        SalesCrMemoLine.SetRange("Original Doc. Line No.", OriginalDocLineNo);
    end;

    [Scope('OnPrem')]
    procedure GetSalesInvHeaderPostingDate(DocNo: Code[20]): Date
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        if SalesInvHeader.Get(DocNo) then
            exit(SalesInvHeader."Posting Date");
        exit(0D);
    end;

    [Scope('OnPrem')]
    procedure GetSalesCrMHeaderPostingDate(DocNo: Code[20]): Date
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        if SalesCrMemoHeader.Get(DocNo) then
            exit(SalesCrMemoHeader."Posting Date");
        exit(0D);
    end;

    local procedure CreateItemTracking(SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line")
    var
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ItemLedgEntryBuf: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        MissingExCostRevLink: Boolean;
        FillExactCostRevLink: Boolean;
        ExactCostRevMandatory: Boolean;
    begin
        MissingExCostRevLink := false;
        FillExactCostRevLink := false;
        ExactCostRevMandatory := false;
        TempTrkgItemLedgEntry.Reset();
        TempTrkgItemLedgEntry.DeleteAll();

        case SalesHeader."Corrected Doc. Type" of
            SalesHeader."Corrected Doc. Type"::Invoice:
                begin
                    SalesInvLine.Get(TempSalesLine."Document No.", TempSalesLine."Line No.");
                    SalesInvLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                end;
            SalesHeader."Corrected Doc. Type"::"Credit Memo":
                begin
                    SalesCrMemoLine.Get(TempSalesLine."Document No.", TempSalesLine."Line No.");
                    SalesCrMemoLine.GetItemLedgEntries(ItemLedgEntryBuf, true);
                end;
        end;

        FillExactCostRevLink :=
          ((SalesHeader."Corrected Doc. Type" = SalesHeader."Corrected Doc. Type"::Invoice) and
           (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo")) or
          ((SalesHeader."Corrected Doc. Type" = SalesHeader."Corrected Doc. Type"::"Credit Memo") and
           (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice));

        if IsCopyItemTrkg(ItemLedgEntryBuf) then begin
            SalesSetup.Get();
            ExactCostRevMandatory := SalesSetup."Exact Cost Reversing Mandatory";
            MissingExCostRevLink := (SalesLine."Quantity (Base)" <> 0) and FillExactCostRevLink;
            ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempTrkgItemLedgEntry, ItemLedgEntryBuf);
            ItemTrackingMgt.CopyItemLedgEntryTrkgToSalesLn(
              TempTrkgItemLedgEntry, SalesLine,
              FillExactCostRevLink and ExactCostRevMandatory, MissingExCostRevLink,
              SalesHeader."Prices Including VAT", SalesHeader."Prices Including VAT", false);
        end;
    end;

    local procedure IsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        if ItemLedgEntry.IsEmpty() then
            exit(true);
        ItemLedgEntry.SetFilter("Lot No.", '<>%1', '');
        if not ItemLedgEntry.IsEmpty() then
            exit(true);
        ItemLedgEntry.SetRange("Lot No.");
        ItemLedgEntry.SetFilter("Serial No.", '<>%1', '');
        if not ItemLedgEntry.IsEmpty() then
            exit(true);
        ItemLedgEntry.SetRange("Serial No.");
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CheckSalesCorrDocHeader(CorrDocHeader: Record "Sales Header")
    var
        CorrSalesInvHeader: Record "Sales Invoice Header";
        CorrSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempSalesHeader: Record "Sales Header";
    begin
        case CorrDocHeader."Corrected Doc. Type" of
            CorrDocHeader."Corrected Doc. Type"::Invoice:
                begin
                    CorrSalesInvHeader.Get(CorrDocHeader."Corrected Doc. No.");
                    TempSalesHeader.TransferFields(CorrSalesInvHeader);
                end;
            CorrDocHeader."Corrected Doc. Type"::"Credit Memo":
                begin
                    CorrSalesCrMemoHeader.Get(CorrDocHeader."Corrected Doc. No.");
                    TempSalesHeader.TransferFields(CorrSalesCrMemoHeader);
                end;
        end;
        CorrDocHeader.TestField("Currency Code", TempSalesHeader."Currency Code");
        CorrDocHeader.TestField("Currency Factor", TempSalesHeader."Currency Factor");
        CorrDocHeader.TestField("Prices Including VAT", TempSalesHeader."Prices Including VAT");
        CorrDocHeader.TestField("Sell-to Customer No.", TempSalesHeader."Sell-to Customer No.");
        CorrDocHeader.TestField("Bill-to Customer No.", TempSalesHeader."Bill-to Customer No.");
        CorrDocHeader.TestField("Shortcut Dimension 1 Code", TempSalesHeader."Shortcut Dimension 1 Code");
        CorrDocHeader.TestField("Shortcut Dimension 2 Code", TempSalesHeader."Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure CheckSalesCorrDocHeaderDim(CorrDocHeader: Record "Sales Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case CorrDocHeader."Corrected Doc. Type" of
            CorrDocHeader."Corrected Doc. Type"::Invoice:
                begin
                    SalesInvHeader.Get(CorrDocHeader."Corrected Doc. No.");
                    if SalesInvHeader."Dimension Set ID" <> CorrDocHeader."Dimension Set ID" then
                        Error(Text004, CorrDocHeader."Document Type", CorrDocHeader."No.", CorrDocHeader."Corrected Doc. No.");
                end;
            CorrDocHeader."Corrected Doc. Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.Get(CorrDocHeader."Corrected Doc. No.");
                    if SalesCrMemoHeader."Dimension Set ID" <> CorrDocHeader."Dimension Set ID" then
                        Error(Text004, CorrDocHeader."Document Type", CorrDocHeader."No.", CorrDocHeader."Corrected Doc. No.");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPurchInvHeaderPostingDate(DocNo: Code[20]): Date
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if PurchInvHeader.Get(DocNo) then
            exit(PurchInvHeader."Posting Date");
        exit(0D);
    end;

    [Scope('OnPrem')]
    procedure GetPurchCrMHeaderPostingDate(DocNo: Code[20]): Date
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        if PurchCrMemoHeader.Get(DocNo) then
            exit(PurchCrMemoHeader."Posting Date");
        exit(0D);
    end;

    [Scope('OnPrem')]
    procedure IsCorrDocument(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        exit(IsCorrDocType(CorrSalesHeader) or GetRevToCorrDoc(CorrSalesHeader));
    end;

    local procedure IsCorrDocType(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        exit(CorrSalesHeader."Corrective Document" and (CorrSalesHeader."Corrective Doc. Type" = CorrSalesHeader."Corrective Doc. Type"::Correction));
    end;

    [Scope('OnPrem')]
    procedure GetInitialDoc(var CorrSalesHeader: Record "Sales Header")
    begin
        if not FindInitialDoc(CorrSalesHeader) then
            Clear(CorrSalesHeader);
    end;

    local procedure FindInitialDoc(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        if not GetRelatedDoc(CorrSalesHeader, CorrSalesHeader."Original Doc. Type", CorrSalesHeader."Original Doc. No.") then
            exit(false);
        if CorrSalesHeader."Corrective Document" then
            exit(FindInitialDoc(CorrSalesHeader));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetCorrToRevDoc(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        if CorrSalesHeader."Corrective Doc. Type" <> CorrSalesHeader."Corrective Doc. Type"::Correction then begin
            Clear(CorrSalesHeader);
            exit(false);
        end;
        if FindFirstRevDoc(CorrSalesHeader) then
            exit(true);
        Clear(CorrSalesHeader);
    end;

    local procedure FindFirstRevDoc(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        if (not GetRelatedDoc(CorrSalesHeader, CorrSalesHeader."Corrected Doc. Type", CorrSalesHeader."Corrected Doc. No.")) or
           (not CorrSalesHeader."Corrective Document")
        then
            exit(false);
        if CorrSalesHeader."Corrective Doc. Type" = CorrSalesHeader."Corrective Doc. Type"::Revision then
            exit(true);
        exit(FindFirstRevDoc(CorrSalesHeader));
    end;

    local procedure GetLastRevToInitial(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        GetInitialDoc(CorrSalesHeader);
        if FindLastRevToInitial(CorrSalesHeader) then
            exit(true);
        Clear(CorrSalesHeader);
    end;

    local procedure FindLastRevToInitial(var CorrSalesHeader: Record "Sales Header"): Boolean
    var
        LastRevSalesHeader: Record "Sales Header" temporary;
    begin
        if CorrSalesHeader."Corrective Doc. Type" = CorrSalesHeader."Corrective Doc. Type"::Revision then
            LastRevSalesHeader := CorrSalesHeader;
        if not FindNextRevision(CorrSalesHeader) then begin
            CorrSalesHeader := LastRevSalesHeader;
            exit(CorrSalesHeader."Corrective Doc. Type" = CorrSalesHeader."Corrective Doc. Type"::Revision);
        end;
        exit(FindLastRevToInitial(CorrSalesHeader));
    end;

    local procedure FindNextRevision(var CorrSalesHeader: Record "Sales Header"): Boolean
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case CorrSalesHeader."Document Type" of
            CorrSalesHeader."Document Type"::Invoice:
                begin
                    SalesInvHeader.SetRange("Corrected Doc. Type", GetCorrDocType(CorrSalesHeader));
                    SalesInvHeader.SetRange("Corrected Doc. No.", CorrSalesHeader."No.");
                    SalesInvHeader.SetRange("Corrective Doc. Type", CorrSalesHeader."Corrective Doc. Type"::Revision);
                    if SalesInvHeader.FindFirst() then begin
                        FillSalesInvCorrHeader(CorrSalesHeader, SalesInvHeader);
                        exit(true);
                    end;
                end;
            CorrSalesHeader."Document Type"::"Credit Memo":
                begin
                    SalesCrMemoHeader.SetRange("Corrected Doc. Type", GetCorrDocType(CorrSalesHeader));
                    SalesCrMemoHeader.SetRange("Corrected Doc. No.", CorrSalesHeader."No.");
                    SalesCrMemoHeader.SetRange("Corrective Doc. Type", CorrSalesHeader."Corrective Doc. Type"::Revision);
                    if SalesCrMemoHeader.FindFirst() then begin
                        FillSalesCrMemoCorrHeader(CorrSalesHeader, SalesCrMemoHeader);
                        exit(true);
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetRevToCorrDoc(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        if CorrSalesHeader."Corrective Doc. Type" <> CorrSalesHeader."Corrective Doc. Type"::Revision then begin
            Clear(CorrSalesHeader);
            exit(false);
        end;
        if FindFirstCorrDoc(CorrSalesHeader) then
            exit(true);
        Clear(CorrSalesHeader);
    end;

    local procedure FindFirstCorrDoc(var CorrSalesHeader: Record "Sales Header"): Boolean
    begin
        if (not GetRelatedDoc(CorrSalesHeader, CorrSalesHeader."Corrected Doc. Type", CorrSalesHeader."Corrected Doc. No.")) or
           (not CorrSalesHeader."Corrective Document")
        then
            exit(false);
        if CorrSalesHeader."Corrective Doc. Type" = CorrSalesHeader."Corrective Doc. Type"::Correction then
            exit(true);
        exit(FindFirstCorrDoc(CorrSalesHeader));
    end;

    local procedure GetRelatedDoc(var CorrSalesHeader: Record "Sales Header"; DocType: Option; DocNo: Code[20]): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        case DocType of
            CorrSalesHeader."Corrected Doc. Type"::Invoice:
                if SalesInvoiceHeader.Get(DocNo) then begin
                    FillSalesInvCorrHeader(CorrSalesHeader, SalesInvoiceHeader);
                    exit(true);
                end;
            CorrSalesHeader."Corrected Doc. Type"::"Credit Memo":
                if SalesCrMemoHeader.Get(DocNo) then begin
                    FillSalesCrMemoCorrHeader(CorrSalesHeader, SalesCrMemoHeader);
                    exit(true);
                end;
        end;
        Clear(CorrSalesHeader);
    end;

    local procedure GetCorrDocType(CorrSalesHeader: Record "Sales Header"): Integer
    begin
        case CorrSalesHeader."Document Type" of
            CorrSalesHeader."Document Type"::Invoice:
                exit(CorrSalesHeader."Corrected Doc. Type"::Invoice);
            CorrSalesHeader."Document Type"::"Credit Memo":
                exit(CorrSalesHeader."Corrected Doc. Type"::"Credit Memo");
        end;
    end;

    [Scope('OnPrem')]
    procedure FillSalesInvCorrHeader(var CorrSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CorrSalesHeader.TransferFields(SalesInvoiceHeader);
        CorrSalesHeader."Document Type" := CorrSalesHeader."Document Type"::Invoice;
    end;

    [Scope('OnPrem')]
    procedure FillSalesCrMemoCorrHeader(var CorrSalesHeader: Record "Sales Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        CorrSalesHeader.TransferFields(SalesCrMemoHeader);
        CorrSalesHeader."Document Type" := CorrSalesHeader."Document Type"::"Credit Memo";
    end;

    [Scope('OnPrem')]
    procedure GetDocHeaderText(PrintedSalesHeader: Record "Sales Header"; var ReportNos: array[4] of Text; var ReportDates: array[4] of Text)
    var
        TempSalesHeader: array[4] of Record "Sales Header" temporary;
    begin
        GetDocHeader(TempSalesHeader, PrintedSalesHeader);
        SetPrintedRevisionNo(TempSalesHeader[2]);
        SetPrintedRevisionNo(TempSalesHeader[4]);
        GetHeaderText(TempSalesHeader, ReportNos, ReportDates);
    end;

    [Scope('OnPrem')]
    procedure GetDocHeader(var RepSalesHeader: array[4] of Record "Sales Header"; PrintedSalesHeader: Record "Sales Header")
    begin
        GetCorrDocHeader(RepSalesHeader[1], PrintedSalesHeader);
        GetRevisionCorrectiveDocHeader(RepSalesHeader[2], PrintedSalesHeader);
        GetInitialDocHeader(RepSalesHeader[3], PrintedSalesHeader);
        GetRelatedCorrectionDocHeader(RepSalesHeader[4], PrintedSalesHeader);
    end;

    local procedure GetHeaderText(var RepSalesHeader: array[4] of Record "Sales Header"; var ReportNos: array[4] of Text; var ReportDates: array[4] of Text)
    var
        LocMgt: Codeunit "Localisation Management";
        i: Integer;
    begin
        for i := 1 to ArrayLen(RepSalesHeader) do
            if RepSalesHeader[i]."No." = '' then begin
                ReportNos[i] := '-';
                ReportDates[i] := '-';
            end else begin
                if RepSalesHeader[i]."Corrective Document" and (RepSalesHeader[i]."Posting No." <> '') then
                    ReportNos[i] := RepSalesHeader[i]."Posting No."
                else
                    ReportNos[i] := RepSalesHeader[i]."No.";
                ReportDates[i] := LocMgt.Date2Text(RepSalesHeader[i]."Document Date");
            end;
    end;

    local procedure SetPrintedRevisionNo(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."No." := SalesHeader."Revision No.";
    end;

    local procedure GetCorrDocHeader(var RepSalesHeader: Record "Sales Header"; PrintedSalesHeader: Record "Sales Header"): Text[100]
    var
        OldTempSalesHeader: Record "Sales Header" temporary;
    begin
        OldTempSalesHeader := PrintedSalesHeader;
        if GetRevToCorrDoc(PrintedSalesHeader) then
            RepSalesHeader := PrintedSalesHeader
        else
            RepSalesHeader := OldTempSalesHeader;
    end;

    [Scope('OnPrem')]
    procedure GetRevisionCorrectiveDocHeader(var RepSalesHeader: Record "Sales Header"; PrintedSalesHeader: Record "Sales Header"): Text[100]
    var
        OldTempSalesHeader: Record "Sales Header" temporary;
    begin
        OldTempSalesHeader := PrintedSalesHeader;
        if GetRevToCorrDoc(PrintedSalesHeader) then
            RepSalesHeader := OldTempSalesHeader
        else
            RepSalesHeader := PrintedSalesHeader;
    end;

    local procedure GetInitialDocHeader(var RepSalesHeader: Record "Sales Header"; PrintedSalesHeader: Record "Sales Header"): Text[100]
    begin
        GetInitialDoc(PrintedSalesHeader);
        RepSalesHeader := PrintedSalesHeader;
    end;

    local procedure GetRelatedCorrectionDocHeader(var RepSalesHeader: Record "Sales Header"; PrintedSalesHeader: Record "Sales Header"): Text[100]
    begin
        if GetLastRevToInitial(PrintedSalesHeader) then
            RepSalesHeader := PrintedSalesHeader;
    end;

    [Scope('OnPrem')]
    procedure IsCorrVATEntry(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(VATEntry."Corrective Doc. Type" <> VATEntry."Corrective Doc. Type"::" ");
    end;

    [Scope('OnPrem')]
    procedure GetSalesDocData(var DocumentNo: Code[30]; var DocumentDate: Date; IsInvoice: Boolean; OrigDocNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
    begin
        if IsInvoice then begin
            SalesInvHeader.Get(OrigDocNo);
            DocumentNo := SalesInvHeader."No.";
            DocumentDate := SalesInvHeader."Posting Date";
        end else begin
            SalesCrMemoHdr.Get(OrigDocNo);
            DocumentNo := SalesCrMemoHdr."No.";
            DocumentDate := SalesCrMemoHdr."Posting Date";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPurchDocData(var DocumentNo: Code[30]; var DocumentDate: Date; IsInvoice: Boolean; OrigDocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if IsInvoice then begin
            PurchInvHeader.Get(OrigDocNo);
            PurchInvHeader.CalcFields("Vendor VAT Invoice No.", "Vendor VAT Invoice Date");
            if PurchInvHeader."Vendor VAT Invoice No." <> '' then
                DocumentNo := PurchInvHeader."Vendor VAT Invoice No."
            else
                DocumentNo := PurchInvHeader."No.";
            if PurchInvHeader."Vendor VAT Invoice Date" <> 0D then
                DocumentDate := PurchInvHeader."Vendor VAT Invoice Date"
            else
                DocumentDate := PurchInvHeader."Posting Date";
        end else begin
            PurchCrMemoHdr.Get(OrigDocNo);
            DocumentNo := PurchCrMemoHdr."No.";
            DocumentDate := PurchCrMemoHdr."Posting Date";

            GetVendCrMemoLedgEntry(VendLedgEntry, PurchCrMemoHdr);
            if VendLedgEntry."Vendor VAT Invoice No." <> '' then
                DocumentNo := VendLedgEntry."Vendor VAT Invoice No.";
            if VendLedgEntry."Vendor VAT Invoice Date" <> 0D then
                DocumentDate := VendLedgEntry."Vendor VAT Invoice Date";
        end;
    end;

    local procedure GetVendCrMemoLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        VendLedgEntry.SetRange("Vendor No.", PurchCrMemoHdr."Pay-to Vendor No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
        VendLedgEntry.SetRange("Document No.", PurchCrMemoHdr."No.");
        VendLedgEntry.SetRange("Posting Date", PurchCrMemoHdr."Posting Date");
        VendLedgEntry.FindFirst();
    end;

    local procedure FindAndSetApplFromItemEntryNo(var SalesLine: Record "Sales Line"; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        SalesInvoiceLine.FilterPstdDocLineValueEntries(ValueEntry);
        ValueEntry.SetFilter("Invoiced Quantity", '<>0');
        if ValueEntry.FindFirst() then begin
            ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
            if ItemLedgEntry.TrackingExists() then
                exit;
            SalesLine.Validate(
              "Quantity (After)", SalesLine."Quantity (Before)" - UnitOfMeasureManagement.CalcQtyFromBase(
                Abs(ItemLedgEntry.Quantity), SalesLine."Qty. per Unit of Measure"));
            SalesLine.Validate("Appl.-from Item Entry", ValueEntry."Item Ledger Entry No.");
        end;
    end;
}

