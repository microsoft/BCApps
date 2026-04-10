#pragma warning disable AA0247
codeunit 17206 "Create Tax Register Item Entry"
{
    TableNo = "Tax Register Item Entry";

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Search Table    #4############################\Begin period    #1##########\End period      #2##########\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000901: Label '%1 %2 from %3';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxDimMgt: Codeunit "Tax Dimension Mgt.";
#pragma warning disable AA0074
        Text21000902: Label 'Adjust Cost Item Entries & Post Inventory Cost to G/L needed.';
#pragma warning restore AA0074
        Window: Dialog;

    [Scope('OnPrem')]
    procedure CreateRegister(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        Item: Record Item;
        ItemApplEntry: Record "Item Application Entry";
        ItemApplEntry2: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntryPostedToGL: Record "Value Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegGLCorrEntry: Record "Tax Register G/L Corr. Entry";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        Total: Integer;
        Procesing: Integer;
        QtyEntry: Decimal;
        AmountEntry: Decimal;
        SecondaryBatch: Boolean;
        AmountForTaxAccounting: Decimal;
        DocumentAmountForTaxAccounting: Decimal;
    begin
        TaxRegMgt.ValidateAbsenceItemEntriesDate(StartDate, EndDate, SectionCode);

        if not TaxRegItemEntry.FindLast() then
            TaxRegItemEntry."Entry No." := 0;

        Clear(TaxDimMgt);

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        ValueEntryPostedToGL.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        Window.Update(4, ItemLedgEntry.TableCaption);

        ItemLedgEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgEntry.SetRange("Posting Date", StartDate, EndDate);

        ItemLedgEntry.SetFilter("Entry Type", '%1|%2|%3|%4',
          ItemLedgEntry."Entry Type"::Purchase,
          ItemLedgEntry."Entry Type"::Sale,
          ItemLedgEntry."Entry Type"::"Positive Adjmt.",
          ItemLedgEntry."Entry Type"::"Negative Adjmt.");

        Total := ItemLedgEntry.Count;
        Procesing := 0;

        if ItemLedgEntry.FindSet() then
            repeat
                Procesing += 1;
                if (Procesing mod 50) = 1 then
                    Window.Update(3, Round((Procesing / Total) * 10000, 1));
                Item.Get(ItemLedgEntry."Item No.");

                ItemLedgEntry.CalcFields("Cost Amount (Actual)");
                ValueEntryPostedToGL.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntryPostedToGL.CalcSums("Cost Posted to G/L");
                if ItemLedgEntry."Cost Amount (Actual)" <> ValueEntryPostedToGL."Cost Posted to G/L" then
                    Error(Text21000902);
                TaxRegItemEntry.Init();
                TaxRegItemEntry."Section Code" := SectionCode;
                TaxRegItemEntry."Starting Date" := StartDate;
                TaxRegItemEntry."Ending Date" := EndDate;
                TaxRegItemEntry."Posting Date" := ItemLedgEntry."Posting Date";
                TaxRegItemEntry."Ledger Entry No." := ItemLedgEntry."Entry No.";
                TaxDimMgt.SetLedgEntryDim(SectionCode, ItemLedgEntry."Dimension Set ID");
                TaxRegItemEntry."Item No." := Item."No.";
                UpdateDescription(ItemLedgEntry, TaxRegItemEntry);
                UpdatePostingData(TaxRegItemEntry);
                if TaxRegGLCorrEntry.Get(SectionCode, TaxRegItemEntry."Debit Account No.", '', TaxRegGLCorrEntry."Register Type"::Item) or
                   TaxRegGLCorrEntry.Get(SectionCode, '', TaxRegItemEntry."Credit Account No.", TaxRegGLCorrEntry."Register Type"::Item)
                then
                    if not TaxDimMgt.WhereUsedByDimensions(TaxRegGLCorrEntry, TaxRegItemEntry."Where Used Register IDs",
                         TaxRegItemEntry."Dimension 1 Value Code", TaxRegItemEntry."Dimension 2 Value Code",
                         TaxRegItemEntry."Dimension 3 Value Code", TaxRegItemEntry."Dimension 4 Value Code")
                    then
                        TaxRegItemEntry."Where Used Register IDs" := '';

                CheckWhereUsedByCostingMetod(TaxRegItemEntry, Item);
                if TaxRegItemEntry."Where Used Register IDs" <> '' then
                    if ItemLedgEntry.Positive then begin
                        TaxRegItemEntry."Original Amount" := ItemLedgEntry."Cost Amount (Actual)";
                        TaxRegItemEntry."Qty. (Document)" := ItemLedgEntry.Quantity;
                        AmountForTaxAccounting := CalcAmountForTaxAccounting(ItemLedgEntry);
                        TaxRegItemEntry."Amount (Document)" := AmountForTaxAccounting;
                        TaxRegItemEntry."Entry Type" := TaxRegItemEntry."Entry Type"::Incoming;
                        TaxRegItemEntry."Batch Date" := ItemLedgEntry."Posting Date";
                        TaxRegItemEntry."Appl. Entry No." := ItemLedgEntry."Entry No.";
                        TaxRegItemEntry."Batch Qty." := ItemLedgEntry.Quantity;
                        TaxRegItemEntry."Batch Amount" := AmountForTaxAccounting;
                        TaxRegItemEntry."Debit Unit Cost" :=
                          Round(AmountForTaxAccounting / ItemLedgEntry.Quantity);
                        TaxRegItemEntry."Credit Qty." := ItemLedgEntry.Quantity;
                        TaxRegItemEntry."Credit Amount" := AmountForTaxAccounting;
                        TaxRegItemEntry."Entry No." += 1;
                        TaxRegItemEntry.Insert();
                    end else begin
                        DocumentAmountForTaxAccounting := 0;
                        TaxRegItemEntry."Qty. (Document)" := -ItemLedgEntry.Quantity;
                        TaxRegItemEntry."Amount (Document)" := -ItemLedgEntry."Cost Amount (Actual)";
                        TaxRegItemEntry."Entry Type" := TaxRegItemEntry."Entry Type"::Spending;
                        QtyEntry := ItemLedgEntry.Quantity;
                        AmountEntry := ItemLedgEntry."Cost Amount (Actual)";
                        ItemApplEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                        SecondaryBatch := false;
                        if ItemApplEntry.FindSet() then
                            repeat
                                if ItemApplEntry.Quantity < 0 then begin
                                    if not ItemLedgEntry2.Get(ItemApplEntry."Inbound Item Entry No.") then
                                        ItemLedgEntry2.Init();
                                    if ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Transfer then
                                        repeat
                                            ItemApplEntry2.SetRange("Item Ledger Entry No.", ItemLedgEntry2."Entry No.");
                                            ItemApplEntry2.FindFirst();
                                            if not ItemLedgEntry2.Get(ItemApplEntry2."Transferred-from Entry No.") then
                                                ItemLedgEntry2.Init();
                                        until ItemLedgEntry2."Entry Type" <> ItemLedgEntry2."Entry Type"::Transfer;

                                    if ItemLedgEntry2.Quantity <> 0 then
                                        if ItemLedgEntry2."Entry Type" in
                                           [ItemLedgEntry2."Entry Type"::Purchase, ItemLedgEntry2."Entry Type"::Sale,
                                            ItemLedgEntry2."Entry Type"::"Positive Adjmt."]
                                        then begin
                                            ItemLedgEntry2.CalcFields("Cost Amount (Actual)");
                                            AmountForTaxAccounting := CalcAmountForTaxAccounting(ItemLedgEntry2);
                                            TaxRegItemEntry."Batch Date" := ItemLedgEntry2."Posting Date";
                                            TaxRegItemEntry."Appl. Entry No." := ItemLedgEntry2."Entry No.";
                                            TaxRegItemEntry."Batch Qty." := ItemLedgEntry2.Quantity;
                                            TaxRegItemEntry."Batch Amount" := AmountForTaxAccounting;
                                            TaxRegItemEntry."Debit Unit Cost" :=
                                              Round(AmountForTaxAccounting / ItemLedgEntry2.Quantity);
                                            TaxRegItemEntry."Qty. (Batch)" := ItemApplEntry.Quantity;
                                            TaxRegItemEntry."Original Amount" :=
                                              Round(ItemLedgEntry2."Cost Amount (Actual)" / ItemLedgEntry2.Quantity * ItemApplEntry.Quantity);
                                            TaxRegItemEntry."Amount (Batch)" :=
                                              Round(AmountForTaxAccounting / ItemLedgEntry2.Quantity * ItemApplEntry.Quantity);
                                            TaxRegItemEntry."Debit Qty." := -TaxRegItemEntry."Qty. (Batch)";
                                            TaxRegItemEntry."Debit Amount" := -TaxRegItemEntry."Amount (Batch)";
                                            DocumentAmountForTaxAccounting += TaxRegItemEntry."Amount (Batch)";
                                            TaxRegItemEntry."Entry Secondary Batch" := SecondaryBatch;
                                            InsertTaxRegEntry(TaxRegItemEntry, SecondaryBatch);
                                        end;
                                    QtyEntry -= -TaxRegItemEntry."Debit Qty.";
                                    AmountEntry -= TaxRegItemEntry."Original Amount";
                                    if (QtyEntry = 0) and (AmountEntry <> 0) then begin
                                        TaxRegItemEntry."Amount (Batch)" += AmountEntry;
                                        TaxRegItemEntry."Debit Amount" := -TaxRegItemEntry."Amount (Batch)";
                                        DocumentAmountForTaxAccounting += TaxRegItemEntry."Amount (Batch)";
                                        TaxRegItemEntry.Modify();
                                        AmountEntry := 0;
                                    end;
                                end;
                            until ItemApplEntry.Next(1) = 0;
                        if QtyEntry <> 0 then begin
                            TaxRegItemEntry."Batch Date" := 0D;
                            TaxRegItemEntry."Appl. Entry No." := 0;
                            TaxRegItemEntry."Batch Qty." := 0;
                            TaxRegItemEntry."Batch Amount" := 0;
                            TaxRegItemEntry."Debit Unit Cost" := 0;
                            TaxRegItemEntry."Qty. (Batch)" := QtyEntry;
                            TaxRegItemEntry."Amount (Batch)" := AmountEntry;
                            TaxRegItemEntry."Debit Qty." := -TaxRegItemEntry."Qty. (Batch)";
                            TaxRegItemEntry."Debit Amount" := -TaxRegItemEntry."Amount (Batch)";
                            DocumentAmountForTaxAccounting += TaxRegItemEntry."Amount (Batch)";
                            TaxRegItemEntry."Entry Secondary Batch" := SecondaryBatch;
                            TaxRegItemEntry."Entry No." += 1;
                            TaxRegItemEntry.Insert();
                        end;
                        ModifyTaxRegEntry(TaxRegItemEntry, DocumentAmountForTaxAccounting);
                    end;
            until ItemLedgEntry.Next(1) = 0;

        CreateTaxRegAccumulation(StartDate, EndDate, SectionCode);
    end;

    local procedure UpdateDescription(ItemLedgEntry2: Record "Item Ledger Entry"; var TaxRegItemEntry: Record "Tax Register Item Entry")
    begin
        TaxRegItemEntry."Document No." := ItemLedgEntry2."Document No.";
        TaxRegItemEntry."Document Type" :=
          SearchDocument(ItemLedgEntry2, TaxRegItemEntry);
        TaxRegItemEntry.Description :=
          DelChr(
            StrSubstNo(
              Text21000901,
              TaxRegItemEntry."Document Type", TaxRegItemEntry."Document No.", TaxRegItemEntry."Posting Date"));
    end;

    local procedure SearchDocument(ItemLedgEntry2: Record "Item Ledger Entry"; var TaxRegItemEntry: Record "Tax Register Item Entry"): Integer
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        ItemRcptHeader: Record "Invt. Receipt Header";
        ItemShptHeader: Record "Invt. Shipment Header";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        case ItemLedgEntry2."Entry Type" of
            ItemLedgEntry2."Entry Type"::Purchase:
                if ItemLedgEntry2."Source Type" = ItemLedgEntry2."Source Type"::Vendor then
                    if ItemLedgEntry2.Positive then begin
                        if PurchInvHeader.Get(ItemLedgEntry2."Document No.") and
                           (PurchInvHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (PurchInvHeader."Buy-from Vendor No." = ItemLedgEntry2."Source No.")
                        then
                            exit(TaxRegItemEntry."Document Type"::Invoice);
                        if PurchRcptHeader.Get(ItemLedgEntry2."Document No.") and
                           (PurchRcptHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (PurchRcptHeader."Buy-from Vendor No." = ItemLedgEntry2."Source No.")
                        then begin
                            PurchInvHeader.SetRange("Posting Description", PurchRcptHeader."Posting Description");
                            if PurchInvHeader.FindFirst() and
                               (PurchInvHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                               (PurchInvHeader."Buy-from Vendor No." = ItemLedgEntry2."Source No.")
                            then begin
                                TaxRegItemEntry."Document No." := PurchInvHeader."No.";
                                exit(TaxRegItemEntry."Document Type"::Invoice);
                            end;
                            exit(TaxRegItemEntry."Document Type"::Receipt);
                        end;
                    end else begin
                        if PurchCrMemoHdr.Get(ItemLedgEntry2."Document No.") and
                           (PurchCrMemoHdr."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (PurchCrMemoHdr."Buy-from Vendor No." = ItemLedgEntry2."Source No.")
                        then begin
                            TaxRegItemEntry.Correction := PurchCrMemoHdr.Correction;
                            exit(TaxRegItemEntry."Document Type"::"Credit Memo");
                        end;
                        if ReturnShptHeader.Get(ItemLedgEntry2."Document No.") and
                           (ReturnShptHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (ReturnShptHeader."Buy-from Vendor No." = ItemLedgEntry2."Source No.")
                        then
                            exit(TaxRegItemEntry."Document Type"::"Return Shpt.");
                    end;
            ItemLedgEntry2."Entry Type"::Sale:
                if ItemLedgEntry2."Source Type" = ItemLedgEntry2."Source Type"::Customer then
                    if not ItemLedgEntry2.Positive then begin
                        if SalesInvoiceHeader.Get(ItemLedgEntry2."Document No.") and
                           (SalesInvoiceHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (SalesInvoiceHeader."Sell-to Customer No." = ItemLedgEntry2."Source No.")
                        then
                            exit(TaxRegItemEntry."Document Type"::Invoice);
                        if SalesShipmentHeader.Get(ItemLedgEntry2."Document No.") and
                           (SalesShipmentHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (SalesShipmentHeader."Sell-to Customer No." = ItemLedgEntry2."Source No.")
                        then begin
                            SalesInvoiceHeader.SetRange("Posting Description", PurchRcptHeader."Posting Description");
                            if SalesInvoiceHeader.FindFirst() and
                               (SalesInvoiceHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                               (SalesInvoiceHeader."Sell-to Customer No." = ItemLedgEntry2."Source No.")
                            then begin
                                TaxRegItemEntry."Document No." := SalesInvoiceHeader."No.";
                                exit(TaxRegItemEntry."Document Type"::Invoice);
                            end;
                            exit(TaxRegItemEntry."Document Type"::Shipment);
                        end;
                    end else begin
                        if SalesCrMemoHeader.Get(ItemLedgEntry2."Document No.") and
                           (SalesCrMemoHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (SalesCrMemoHeader."Sell-to Customer No." = ItemLedgEntry2."Source No.")
                        then begin
                            TaxRegItemEntry.Correction := SalesCrMemoHeader.Correction;
                            exit(TaxRegItemEntry."Document Type"::"Credit Memo");
                        end;
                        if ReturnRcptHeader.Get(ItemLedgEntry2."Document No.") and
                           (ReturnRcptHeader."Posting Date" = ItemLedgEntry2."Posting Date") and
                           (ReturnRcptHeader."Sell-to Customer No." = ItemLedgEntry2."Source No.")
                        then
                            exit(TaxRegItemEntry."Document Type"::"Return Rcpt.");
                    end;
            ItemLedgEntry2."Entry Type"::"Positive Adjmt.":
                if ItemRcptHeader.Get(ItemLedgEntry2."Document No.") and
                   (ItemRcptHeader."Posting Date" = ItemLedgEntry2."Posting Date")
                then
                    exit(TaxRegItemEntry."Document Type"::"Positive Adj.");
            ItemLedgEntry2."Entry Type"::"Negative Adjmt.":
                if ItemShptHeader.Get(ItemLedgEntry2."Document No.") and
                   (ItemShptHeader."Posting Date" = ItemLedgEntry2."Posting Date")
                then
                    exit(TaxRegItemEntry."Document Type"::"Negative Adj.");
        end;
    end;

    local procedure UpdatePostingData(var TaxRegItemEntry: Record "Tax Register Item Entry")
    var
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
    begin
        InventoryPostingToGL.TaxRegisterPostGrps(
          TaxRegItemEntry."Ledger Entry No.",
          TaxRegItemEntry."Sales/Purch. Account No.", TaxRegItemEntry."Inventory Account No.", TaxRegItemEntry."Direct Cost Account No.",
          TaxRegItemEntry."Sales/Purch. Posting Code", TaxRegItemEntry."Location Code", TaxRegItemEntry."Inventory Posting Group",
          TaxRegItemEntry."Gen. Bus. Posting Group", TaxRegItemEntry."Gen. Prod. Posting Group");

        TaxRegItemEntry.CalcFields("Ledger Entry Type", "Item Ledger Source Type");

        if (TaxRegItemEntry."Ledger Entry Type" = TaxRegItemEntry."Ledger Entry Type"::"Positive Adjmt.") and
           ((TaxRegItemEntry."Item Ledger Source Type" = TaxRegItemEntry."Item Ledger Source Type"::Vendor) or
            (TaxRegItemEntry."Item Ledger Source Type" = TaxRegItemEntry."Item Ledger Source Type"::Customer)) and
           (TaxRegItemEntry."Posting Date" < 20021231D)
        then
            if TaxRegItemEntry."Item Ledger Source Type" = TaxRegItemEntry."Item Ledger Source Type"::Vendor then
                TaxRegItemEntry."Ledger Entry Type" := TaxRegItemEntry."Ledger Entry Type"::Purchase
            else
                TaxRegItemEntry."Ledger Entry Type" := TaxRegItemEntry."Ledger Entry Type"::Sale;

        case TaxRegItemEntry."Ledger Entry Type" of
            TaxRegItemEntry."Ledger Entry Type"::Purchase:
                if (TaxRegItemEntry."Document Type" = TaxRegItemEntry."Document Type"::"Credit Memo") and
                   not TaxRegItemEntry.Correction
                then begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Sales/Purch. Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Inventory Account No.";
                end else begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Inventory Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Sales/Purch. Account No.";
                end;
            TaxRegItemEntry."Ledger Entry Type"::Sale:
                if (TaxRegItemEntry."Document Type" = TaxRegItemEntry."Document Type"::"Credit Memo") and
                   not TaxRegItemEntry.Correction
                then begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Inventory Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Direct Cost Account No.";
                end else begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Direct Cost Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Inventory Account No.";
                end;
            TaxRegItemEntry."Ledger Entry Type"::"Positive Adjmt.":
                if TaxRegItemEntry."Batch Amount" >= 0 then begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Inventory Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Direct Cost Account No.";
                end else begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Direct Cost Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Inventory Account No.";
                end;
            TaxRegItemEntry."Ledger Entry Type"::"Negative Adjmt.":
                if TaxRegItemEntry."Batch Amount" < 0 then begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Inventory Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Direct Cost Account No.";
                end else begin
                    TaxRegItemEntry."Debit Account No." := TaxRegItemEntry."Direct Cost Account No.";
                    TaxRegItemEntry."Credit Account No." := TaxRegItemEntry."Inventory Account No.";
                end;
        end;
    end;

    local procedure InsertTaxRegEntry(var TaxRegItemEntry: Record "Tax Register Item Entry"; var SecondaryBatch: Boolean)
    var
        TaxRegItemEntry2: Record "Tax Register Item Entry";
    begin
        TaxRegItemEntry2.SetCurrentKey("Section Code", "Starting Date");
        TaxRegItemEntry2.SetRange("Section Code", TaxRegItemEntry."Section Code");
        TaxRegItemEntry2.SetRange("Starting Date", TaxRegItemEntry."Starting Date");
        TaxRegItemEntry2.SetRange("Ending Date", TaxRegItemEntry."Ending Date");
        TaxRegItemEntry2.SetRange("Appl. Entry No.", TaxRegItemEntry."Appl. Entry No.");
        TaxRegItemEntry2.SetRange("Ledger Entry No.", TaxRegItemEntry."Ledger Entry No.");
        if TaxRegItemEntry2.FindFirst() then begin
            TaxRegItemEntry2."Qty. (Batch)" += TaxRegItemEntry."Qty. (Batch)";
            TaxRegItemEntry2."Amount (Batch)" += TaxRegItemEntry."Amount (Batch)";
            TaxRegItemEntry2."Debit Qty." += TaxRegItemEntry."Debit Qty.";
            TaxRegItemEntry2."Debit Amount" += TaxRegItemEntry."Debit Amount";
            TaxRegItemEntry2.Modify();
        end else begin
            TaxRegItemEntry."Entry No." += 1;
            TaxRegItemEntry.Insert();
            SecondaryBatch := true;
        end;
    end;

    local procedure CreateTaxRegAccumulation(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TempTaxRegTemplate: Record "Tax Register Template" temporary;
        TempGLCorrEntry: Record "G/L Correspondence Entry" temporary;
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        AddValue: Decimal;
        DebitAccountNo: Code[1024];
        CreditAccountNo: Code[1024];
        FoudGLCoresp: Boolean;
    begin
        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register Item Entry");
        if not TaxReg.FindFirst() then
            exit;

        TempGLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
        TempGLCorrEntry.Insert();

        TaxRegAccumulation.Reset();
        if not TaxRegAccumulation.FindLast() then
            TaxRegAccumulation."Entry No." := 0;

        TaxRegAccumulation.Reset();
        TaxRegAccumulation.Init();
        TaxRegAccumulation."Section Code" := SectionCode;
        TaxRegAccumulation."Starting Date" := StartDate;
        TaxRegAccumulation."Ending Date" := EndDate;

        TaxRegLineSetup.Reset();
        TaxRegLineSetup.SetRange("Section Code", SectionCode);

        Clear(TaxDimMgt);

        TaxReg.FindSet();
        repeat
            TaxRegLineSetup.SetRange("Tax Register No.", TaxReg."No.");
            if TaxRegLineSetup.FindFirst() then begin
                TempTaxRegTemplate.DeleteAll();
                TaxRegTemplate.SetRange("Section Code", SectionCode);
                TaxRegTemplate.SetRange(Code, TaxReg."No.");
                if TaxRegTemplate.FindSet() then
                    repeat
                        TempTaxRegTemplate := TaxRegTemplate;
                        TempTaxRegTemplate.Value := 0;
                        TempTaxRegTemplate.Insert();
                    until TaxRegTemplate.Next() = 0;

                TaxRegItemEntry.Reset();
                TaxRegItemEntry.SetCurrentKey("Section Code", "Ending Date");
                TaxRegItemEntry.SetRange("Section Code", SectionCode);
                TaxRegItemEntry.SetRange("Ending Date", EndDate);
                TaxRegItemEntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                if TaxRegItemEntry.FindSet() then
                    repeat
                        TaxDimMgt.SetTaxEntryDim(SectionCode,
                          TaxRegItemEntry."Dimension 1 Value Code", TaxRegItemEntry."Dimension 2 Value Code",
                          TaxRegItemEntry."Dimension 3 Value Code", TaxRegItemEntry."Dimension 4 Value Code");
                        TempGLCorrEntry."Debit Account No." := TaxRegItemEntry."Debit Account No.";
                        TempGLCorrEntry."Credit Account No." := TaxRegItemEntry."Credit Account No.";
                        TempGLCorrEntry.Modify();
                        TaxRegLineSetup.FindSet();
                        repeat
                            if (TaxRegLineSetup."Account No." <> '') or
                               (TaxRegLineSetup."Bal. Account No." <> '')
                            then begin
                                if (TaxRegLineSetup."Account Type" = TaxRegLineSetup."Account Type"::"G/L Account") and
                                   (TaxRegLineSetup."Amount Type" <> TaxRegLineSetup."Amount Type"::Debit)
                                then begin
                                    CreditAccountNo := TaxRegLineSetup."Account No.";
                                    DebitAccountNo := '';
                                end else begin
                                    DebitAccountNo := TaxRegLineSetup."Account No.";
                                    CreditAccountNo := TaxRegLineSetup."Bal. Account No.";
                                end;
                                if DebitAccountNo <> '' then
                                    TempGLCorrEntry.SetFilter("Debit Account No.", DebitAccountNo)
                                else
                                    TempGLCorrEntry.SetRange("Debit Account No.");
                                if CreditAccountNo <> '' then
                                    TempGLCorrEntry.SetFilter("Credit Account No.", CreditAccountNo)
                                else
                                    TempGLCorrEntry.SetRange("Credit Account No.");
                                FoudGLCoresp := TempGLCorrEntry.Find();
                                if not FoudGLCoresp and
                                   (TaxRegLineSetup."Account Type" = TaxRegLineSetup."Account Type"::"G/L Account") and
                                   (TaxRegLineSetup."Amount Type" = TaxRegLineSetup."Amount Type"::"Net Change")
                                then begin
                                    TempGLCorrEntry.SetRange("Debit Account No.");
                                    TempGLCorrEntry.SetFilter("Credit Account No.", DebitAccountNo);
                                    FoudGLCoresp := TempGLCorrEntry.Find();
                                end;
                                if FoudGLCoresp then begin
                                    TempTaxRegTemplate.SetRange("Link Tax Register No.", TaxRegLineSetup."Tax Register No.");
                                    TempTaxRegTemplate.SetFilter("Term Line Code", '%1|%2', '', TaxRegLineSetup."Line Code");
                                    if TempTaxRegTemplate.FindSet() then
                                        repeat
                                            if TaxDimMgt.ValidateTemplateDimFilters(TempTaxRegTemplate) then begin
                                                case TempTaxRegTemplate."Sum Field No." of
                                                    TaxRegItemEntry.FieldNo("Amount (Batch)"):
                                                        AddValue := TaxRegItemEntry."Amount (Batch)";
                                                    TaxRegItemEntry.FieldNo("Credit Amount"):
                                                        AddValue := TaxRegItemEntry."Credit Amount";
                                                    TaxRegItemEntry.FieldNo("Debit Amount"):
                                                        AddValue := TaxRegItemEntry."Debit Amount";
                                                    else
                                                        AddValue := 0;
                                                end;
                                                if AddValue <> 0 then begin
                                                    TempTaxRegTemplate.Value += AddValue;
                                                    TempTaxRegTemplate.Modify();
                                                end;
                                            end;
                                        until TempTaxRegTemplate.Next(1) = 0;
                                end;
                            end;
                        until TaxRegLineSetup.Next(1) = 0;
                    until TaxRegItemEntry.Next(1) = 0;

                TempTaxRegTemplate.Reset();
                if TempTaxRegTemplate.FindSet() then
                    repeat
                        TaxRegAccumulation."Report Line Code" := TempTaxRegTemplate."Report Line Code";
                        TaxRegAccumulation."Template Line Code" := TempTaxRegTemplate."Line Code";
                        TaxRegAccumulation."Section Code" := TempTaxRegTemplate."Section Code";
                        TaxRegAccumulation."Tax Register No." := TempTaxRegTemplate.Code;
                        TaxRegAccumulation.Indentation := TempTaxRegTemplate.Indentation;
                        TaxRegAccumulation.Bold := TempTaxRegTemplate.Bold;
                        TaxRegAccumulation.Description := TempTaxRegTemplate.Description;
                        TaxRegAccumulation.Amount := TempTaxRegTemplate.Value;
                        TaxRegAccumulation."Amount Period" := TempTaxRegTemplate.Value;
                        TaxRegAccumulation."Template Line No." := TempTaxRegTemplate."Line No.";
                        TaxRegAccumulation."Amount Date Filter" :=
                          TaxRegTermMgt.CalcIntervalDate(
                            TaxRegAccumulation."Starting Date",
                            TaxRegAccumulation."Ending Date",
                            TempTaxRegTemplate.Period);
                        TaxRegAccumulation.Amount := TaxRegAccumulation."Amount Period";
                        TaxRegAccumulation."Entry No." += 1;
                        TaxRegAccumulation.Insert();
                        if TempTaxRegTemplate.Period <> '' then begin
                            TaxRegAccumulation2 := TaxRegAccumulation;
                            TaxRegAccumulation2.Reset();
                            TaxRegAccumulation2.SetCurrentKey(
                              "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
                            TaxRegAccumulation2.SetRange("Section Code", TaxRegAccumulation."Section Code");
                            TaxRegAccumulation2.SetRange("Tax Register No.", TaxRegAccumulation."Tax Register No.");
                            TaxRegAccumulation2.SetRange("Template Line No.", TaxRegAccumulation."Template Line No.");
                            TaxRegAccumulation2.SetFilter("Starting Date", TaxRegAccumulation."Amount Date Filter");
                            TaxRegAccumulation2.SetFilter("Ending Date", TaxRegAccumulation."Amount Date Filter");
                            TaxRegAccumulation2.CalcSums("Amount Period");
                            TaxRegAccumulation.Amount := TaxRegAccumulation2."Amount Period";
                            TaxRegAccumulation.Modify();
                        end;
                    until TempTaxRegTemplate.Next() = 0;
            end;
        until TaxReg.Next(1) = 0;
        TempTaxRegTemplate.DeleteAll();
    end;

    local procedure ModifyTaxRegEntry(TaxRegItemEntry: Record "Tax Register Item Entry"; DocAmount: Decimal)
    var
        TaxRegItemEntry2: Record "Tax Register Item Entry";
    begin
        if TaxRegItemEntry2."Amount (Document)" = DocAmount then
            exit;

        TaxRegItemEntry2.SetCurrentKey("Section Code", "Starting Date");
        TaxRegItemEntry2.SetRange("Section Code", TaxRegItemEntry."Section Code");
        TaxRegItemEntry2.SetRange("Starting Date", TaxRegItemEntry."Starting Date");
        TaxRegItemEntry2.SetRange("Ending Date", TaxRegItemEntry."Ending Date");
        TaxRegItemEntry2.SetRange("Appl. Entry No.", TaxRegItemEntry."Appl. Entry No.");
        TaxRegItemEntry2.SetRange("Ledger Entry No.", TaxRegItemEntry."Ledger Entry No.");
        if TaxRegItemEntry2.FindSet(true, false) then
            repeat
                TaxRegItemEntry2."Amount (Document)" := DocAmount;
                TaxRegItemEntry2.Modify();
            until TaxRegItemEntry2.Next(1) = 0;
    end;

    local procedure CalcAmountForTaxAccounting(ItemLedgEntry1: Record "Item Ledger Entry") FineAmount: Decimal
    var
        ItemCharge: Record "Item Charge";
        ValueEntry: Record "Value Entry";
    begin
        FineAmount := ItemLedgEntry1."Cost Amount (Actual)";
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry1."Entry No.");
        ValueEntry.SetFilter("Item Charge No.", '<>''''');
        if ValueEntry.FindSet() then
            repeat
                ItemCharge.Get(ValueEntry."Item Charge No.");
                if ItemCharge."Exclude Cost for TA" then
                    FineAmount -= ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next(1) = 0;
    end;

    local procedure CheckWhereUsedByCostingMetod(var TaxRegItemEntry: Record "Tax Register Item Entry"; Item: Record Item)
    var
        TaxReg: Record "Tax Register";
        WhereUsedRegisterIDs: Code[1024];
    begin
        if TaxRegItemEntry."Where Used Register IDs" = '' then
            exit;

        WhereUsedRegisterIDs := TaxRegItemEntry."Where Used Register IDs";
        TaxRegItemEntry."Where Used Register IDs" := '';

        TaxReg.SetRange("Table ID", DATABASE::"Tax Register Item Entry");
        case Item."Costing Method" of
            Item."Costing Method"::FIFO:
                TaxReg.SetFilter("Costing Method", '%1|%2|%3',
                  TaxReg."Costing Method"::" ",
                  TaxReg."Costing Method"::FIFO,
                  TaxReg."Costing Method"::"FIFO+LIFO");
            Item."Costing Method"::LIFO:
                TaxReg.SetFilter("Costing Method", '%1|%2|%3',
                  TaxReg."Costing Method"::" ",
                  TaxReg."Costing Method"::LIFO,
                  TaxReg."Costing Method"::"FIFO+LIFO");
            Item."Costing Method"::Average:
                TaxReg.SetFilter("Costing Method", '%1|%2',
                  TaxReg."Costing Method"::" ",
                  TaxReg."Costing Method"::Average);
            else
                TaxReg.SetRange("Costing Method", TaxReg."Costing Method"::" ");
        end;

        if TaxReg.FindSet() then
            repeat
                if StrPos(WhereUsedRegisterIDs, '~' + TaxReg."Register ID" + '~') <> 0 then
                    TaxRegItemEntry."Where Used Register IDs" :=
                      TaxRegItemEntry."Where Used Register IDs" + TaxReg."Register ID" + '~';
            until TaxReg.Next(1) = 0;
        if TaxRegItemEntry."Where Used Register IDs" <> '' then
            TaxRegItemEntry."Where Used Register IDs" := '~' + TaxRegItemEntry."Where Used Register IDs";
    end;
}

