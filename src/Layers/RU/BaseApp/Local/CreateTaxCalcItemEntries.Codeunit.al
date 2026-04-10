#pragma warning disable AA0247
codeunit 17306 "Create Tax Calc. Item Entries"
{
    TableNo = "Tax Calc. Item Entry";

    trigger OnRun()
    begin
        Code(Rec."Starting Date", Rec."Ending Date", Rec."Section Code");
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
        TaxDimMgt: Codeunit "Tax Calc. Dim. Mgt.";
#pragma warning disable AA0074
        Text21000902: Label 'Adjust Cost Item Entries & Post Inventory Cost to G/L needed.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure "Code"(StartDate: Date; EndDate: Date; TaxCalcSectionCode: Code[10])
    var
        Item: Record Item;
        ItemApplEntry: Record "Item Application Entry";
        ItemApplEntry0: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntry0: Record "Item Ledger Entry";
        ValueEntryPostedToGL: Record "Value Entry";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcCorrespEntry: Record "Tax Calc. G/L Corr. Entry";
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        Wnd: Dialog;
        Total: Integer;
        Procesing: Integer;
        AmountForTaxAccounting: Decimal;
    begin
        TaxCalcMgt.ValidateAbsenceItemEntriesDate(StartDate, EndDate, TaxCalcSectionCode);

        if not TaxCalcItemEntry.FindLast() then
            TaxCalcItemEntry."Entry No." := 0;

        Clear(TaxDimMgt);

        Wnd.Open(Text21000900);
        Wnd.Update(1, StartDate);
        Wnd.Update(2, EndDate);
        ValueEntryPostedToGL.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        Wnd.Update(4, ItemLedgEntry.TableCaption);

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
                    Wnd.Update(3, Round((Procesing / Total) * 10000, 1));
                Item.Get(ItemLedgEntry."Item No.");

                ItemLedgEntry.CalcFields("Cost Amount (Actual)");
                ValueEntryPostedToGL.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                ValueEntryPostedToGL.CalcSums("Cost Posted to G/L");
                if ItemLedgEntry."Cost Amount (Actual)" <> ValueEntryPostedToGL."Cost Posted to G/L" then
                    Error(Text21000902);
                TaxCalcItemEntry.Init();
                TaxCalcItemEntry."Section Code" := TaxCalcSectionCode;
                TaxCalcItemEntry."Starting Date" := StartDate;
                TaxCalcItemEntry."Ending Date" := EndDate;
                TaxCalcItemEntry."Posting Date" := ItemLedgEntry."Posting Date";
                TaxCalcItemEntry."Ledger Entry No." := ItemLedgEntry."Entry No.";
                TaxDimMgt.SetLedgEntryDim(TaxCalcSectionCode, ItemLedgEntry."Dimension Set ID");
                TaxCalcItemEntry."Item No." := Item."No.";
                UpdateDescription(ItemLedgEntry, TaxCalcItemEntry);
                UpdatePostingData(TaxCalcItemEntry);
                if TaxCalcCorrespEntry.Get(
                     TaxCalcSectionCode, TaxCalcItemEntry."Debit Account No.", '',
                     TaxCalcCorrespEntry."Register Type"::Item) or
                   TaxCalcCorrespEntry.Get(
                     TaxCalcSectionCode, '', TaxCalcItemEntry."Credit Account No.",
                     TaxCalcCorrespEntry."Register Type"::Item)
                then
                    if not TaxDimMgt.WhereUsedByDimensions(TaxCalcCorrespEntry, TaxCalcItemEntry."Where Used Register IDs",
                         TaxCalcItemEntry."Dimension 1 Value Code", TaxCalcItemEntry."Dimension 2 Value Code",
                         TaxCalcItemEntry."Dimension 3 Value Code", TaxCalcItemEntry."Dimension 4 Value Code")
                    then
                        TaxCalcItemEntry."Where Used Register IDs" := '';

                if TaxCalcItemEntry."Where Used Register IDs" <> '' then
                    if ItemLedgEntry.Positive then begin
                        AmountForTaxAccounting := CalcAmountForTaxAccounting(ItemLedgEntry);
                        if AmountForTaxAccounting <> ItemLedgEntry."Cost Amount (Actual)" then begin
                            TaxCalcItemEntry."Amount (Actual)" := ItemLedgEntry."Cost Amount (Actual)";
                            TaxCalcItemEntry.Quantity := ItemLedgEntry.Quantity;
                            TaxCalcItemEntry."Amount (Tax)" := AmountForTaxAccounting;
                            TaxCalcItemEntry."Credit Quantity" := ItemLedgEntry.Quantity;
                            TaxCalcItemEntry."Credit Amount (Tax)" := AmountForTaxAccounting;
                            TaxCalcItemEntry."Credit Amount (Actual)" := ItemLedgEntry."Cost Amount (Actual)";
                            TaxCalcItemEntry."Appl. Entry No." := ItemLedgEntry."Entry No.";
                            TaxCalcItemEntry."Entry No." += 1;
                            TaxCalcItemEntry.Insert();
                        end;
                    end else begin
                        ItemApplEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
                        if ItemApplEntry.FindSet() then
                            repeat
                                if ItemApplEntry.Quantity < 0 then begin
                                    if not ItemLedgEntry0.Get(ItemApplEntry."Inbound Item Entry No.") then
                                        ItemLedgEntry0.Init();
                                    if ItemLedgEntry0."Entry Type" = ItemLedgEntry0."Entry Type"::Transfer then
                                        repeat
                                            ItemApplEntry0.SetRange("Item Ledger Entry No.", ItemLedgEntry0."Entry No.");
                                            ItemApplEntry0.FindFirst();
                                            if not ItemLedgEntry0.Get(ItemApplEntry0."Transferred-from Entry No.") then
                                                ItemLedgEntry0.Init();
                                        until ItemLedgEntry0."Entry Type" <> ItemLedgEntry0."Entry Type"::Transfer;

                                    if ItemLedgEntry0.Quantity <> 0 then
                                        if ItemLedgEntry0."Entry Type" in
                                           [ItemLedgEntry0."Entry Type"::Purchase, ItemLedgEntry0."Entry Type"::Sale,
                                            ItemLedgEntry0."Entry Type"::"Positive Adjmt."]
                                        then begin
                                            ItemLedgEntry0.CalcFields("Cost Amount (Actual)");
                                            AmountForTaxAccounting := CalcAmountForTaxAccounting(ItemLedgEntry0);
                                            if AmountForTaxAccounting <> ItemLedgEntry0."Cost Amount (Actual)" then begin
                                                TaxCalcItemEntry."Appl. Entry No." := ItemLedgEntry0."Entry No.";
                                                TaxCalcItemEntry.Quantity := ItemApplEntry.Quantity;
                                                TaxCalcItemEntry."Amount (Actual)" :=
                                                  Round(ItemLedgEntry0."Cost Amount (Actual)" / ItemLedgEntry0.Quantity * ItemApplEntry.Quantity);
                                                TaxCalcItemEntry."Amount (Tax)" :=
                                                  Round(AmountForTaxAccounting / ItemLedgEntry0.Quantity * ItemApplEntry.Quantity);
                                                TaxCalcItemEntry."Debit Quantity" := -TaxCalcItemEntry.Quantity;
                                                TaxCalcItemEntry."Debit Amount (Tax)" := -TaxCalcItemEntry."Amount (Tax)";
                                                TaxCalcItemEntry."Debit Amount (Actual)" := -TaxCalcItemEntry."Amount (Actual)";
                                                TaxCalcEntryINSERT(TaxCalcItemEntry);
                                            end;
                                        end;
                                end;
                            until ItemApplEntry.Next() = 0;
                    end;
            until ItemLedgEntry.Next() = 0;

        CreateTaxCalcAccumulation(StartDate, EndDate, TaxCalcSectionCode);
    end;

    [Scope('OnPrem')]
    procedure UpdateDescription(ItemLedgEntry0: Record "Item Ledger Entry"; var TaxCalcItemEntry: Record "Tax Calc. Item Entry")
    begin
        TaxCalcItemEntry."Document No." := ItemLedgEntry0."Document No.";
        TaxCalcItemEntry."Document Type" :=
          SearchDocument(ItemLedgEntry0, TaxCalcItemEntry);

        TaxCalcItemEntry.Description :=
          DelChr(
            StrSubstNo(
              Text21000901,
              TaxCalcItemEntry."Document Type", TaxCalcItemEntry."Document No.", TaxCalcItemEntry."Posting Date"),
            '<>', ' ');
    end;

    local procedure SearchDocument(ItemLedgEntry0: Record "Item Ledger Entry"; var TaxCalcItemEntry: Record "Tax Calc. Item Entry"): Integer
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        InvtRcptHeader: Record "Invt. Receipt Header";
        InvtShptHeader: Record "Invt. Shipment Header";
        ReturnShptHeader: Record "Return Shipment Header";
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        case ItemLedgEntry0."Entry Type" of
            ItemLedgEntry0."Entry Type"::Purchase:
                if ItemLedgEntry0."Source Type" = ItemLedgEntry0."Source Type"::Vendor then
                    if ItemLedgEntry0.Positive then begin
                        if PurchInvHeader.Get(ItemLedgEntry0."Document No.") and
                           (PurchInvHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (PurchInvHeader."Buy-from Vendor No." = ItemLedgEntry0."Source No.")
                        then
                            exit(TaxCalcItemEntry."Document Type"::Invoice);
                        if PurchRcptHeader.Get(ItemLedgEntry0."Document No.") and
                           (PurchRcptHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (PurchRcptHeader."Buy-from Vendor No." = ItemLedgEntry0."Source No.")
                        then begin
                            PurchInvHeader.SetRange("Posting Description", PurchRcptHeader."Posting Description");
                            if PurchInvHeader.FindFirst() and
                               (PurchInvHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                               (PurchInvHeader."Buy-from Vendor No." = ItemLedgEntry0."Source No.")
                            then begin
                                TaxCalcItemEntry."Document No." := PurchInvHeader."No.";
                                exit(TaxCalcItemEntry."Document Type"::Invoice);
                            end;
                            exit(TaxCalcItemEntry."Document Type"::Receipt);
                        end;
                    end else begin
                        if PurchCrMemoHdr.Get(ItemLedgEntry0."Document No.") and
                           (PurchCrMemoHdr."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (PurchCrMemoHdr."Buy-from Vendor No." = ItemLedgEntry0."Source No.")
                        then begin
                            TaxCalcItemEntry.Correction := PurchCrMemoHdr.Correction;
                            exit(TaxCalcItemEntry."Document Type"::"Credit Memo");
                        end;
                        if ReturnShptHeader.Get(ItemLedgEntry0."Document No.") and
                           (ReturnShptHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (ReturnShptHeader."Buy-from Vendor No." = ItemLedgEntry0."Source No.")
                        then
                            exit(TaxCalcItemEntry."Document Type"::"Return Shpt.");
                    end;
            ItemLedgEntry0."Entry Type"::Sale:
                if ItemLedgEntry0."Source Type" = ItemLedgEntry0."Source Type"::Customer then
                    if not ItemLedgEntry0.Positive then begin
                        if SalesInvoiceHeader.Get(ItemLedgEntry0."Document No.") and
                           (SalesInvoiceHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (SalesInvoiceHeader."Sell-to Customer No." = ItemLedgEntry0."Source No.")
                        then
                            exit(TaxCalcItemEntry."Document Type"::Invoice);
                        if SalesShipmentHeader.Get(ItemLedgEntry0."Document No.") and
                           (SalesShipmentHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (SalesShipmentHeader."Sell-to Customer No." = ItemLedgEntry0."Source No.")
                        then begin
                            SalesInvoiceHeader.SetRange("Posting Description", PurchRcptHeader."Posting Description");
                            if SalesInvoiceHeader.FindFirst() and
                               (SalesInvoiceHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                               (SalesInvoiceHeader."Sell-to Customer No." = ItemLedgEntry0."Source No.")
                            then begin
                                TaxCalcItemEntry."Document No." := SalesInvoiceHeader."No.";
                                exit(TaxCalcItemEntry."Document Type"::Invoice);
                            end;
                            exit(TaxCalcItemEntry."Document Type"::Shipment);
                        end;
                    end else begin
                        if SalesCrMemoHeader.Get(ItemLedgEntry0."Document No.") and
                           (SalesCrMemoHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (SalesCrMemoHeader."Sell-to Customer No." = ItemLedgEntry0."Source No.")
                        then begin
                            TaxCalcItemEntry.Correction := SalesCrMemoHeader.Correction;
                            exit(TaxCalcItemEntry."Document Type"::"Credit Memo");
                        end;
                        if ReturnRcptHeader.Get(ItemLedgEntry0."Document No.") and
                           (ReturnRcptHeader."Posting Date" = ItemLedgEntry0."Posting Date") and
                           (ReturnRcptHeader."Sell-to Customer No." = ItemLedgEntry0."Source No.")
                        then
                            exit(TaxCalcItemEntry."Document Type"::"Return Rcpt.");
                    end;
            ItemLedgEntry0."Entry Type"::"Positive Adjmt.":
                if InvtRcptHeader.Get(ItemLedgEntry0."Document No.") and
                   (InvtRcptHeader."Posting Date" = ItemLedgEntry0."Posting Date")
                then
                    exit(TaxCalcItemEntry."Document Type"::"Positive Adj.");
            ItemLedgEntry0."Entry Type"::"Negative Adjmt.":
                if InvtShptHeader.Get(ItemLedgEntry0."Document No.") and
                   (InvtShptHeader."Posting Date" = ItemLedgEntry0."Posting Date")
                then
                    exit(TaxCalcItemEntry."Document Type"::"Negative Adj.");
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePostingData(var TaxCalcItemEntry: Record "Tax Calc. Item Entry")
    var
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
    begin
        InventoryPostingToGL.TaxRegisterPostGrps(
          TaxCalcItemEntry."Ledger Entry No.",
          TaxCalcItemEntry."Sales/Purch. Account No.", TaxCalcItemEntry."Inventory Account No.",
          TaxCalcItemEntry."Direct Cost Account No.",
          TaxCalcItemEntry."Sales/Purch. Posting Code", TaxCalcItemEntry."Location Code", TaxCalcItemEntry."Inventory Posting Group",
          TaxCalcItemEntry."Gen. Bus. Posting Group", TaxCalcItemEntry."Gen. Prod. Posting Group");

        TaxCalcItemEntry.CalcFields("Ledger Entry Type", "Item Ledger Source Type");

        if (TaxCalcItemEntry."Ledger Entry Type" = TaxCalcItemEntry."Ledger Entry Type"::"Positive Adjmt.") and
           ((TaxCalcItemEntry."Item Ledger Source Type" = TaxCalcItemEntry."Item Ledger Source Type"::Vendor) or
            (TaxCalcItemEntry."Item Ledger Source Type" = TaxCalcItemEntry."Item Ledger Source Type"::Customer)) and
           (TaxCalcItemEntry."Posting Date" < 20021231D)
        then
            if TaxCalcItemEntry."Item Ledger Source Type" = TaxCalcItemEntry."Item Ledger Source Type"::Vendor then
                TaxCalcItemEntry."Ledger Entry Type" := TaxCalcItemEntry."Ledger Entry Type"::Purchase
            else
                TaxCalcItemEntry."Ledger Entry Type" := TaxCalcItemEntry."Ledger Entry Type"::Sale;

        case TaxCalcItemEntry."Ledger Entry Type" of
            TaxCalcItemEntry."Ledger Entry Type"::Purchase:
                if (TaxCalcItemEntry."Document Type" = TaxCalcItemEntry."Document Type"::"Credit Memo") and
                   not TaxCalcItemEntry.Correction
                then begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Sales/Purch. Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Inventory Account No.";
                end else begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Inventory Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Sales/Purch. Account No.";
                end;
            TaxCalcItemEntry."Ledger Entry Type"::Sale:
                if (TaxCalcItemEntry."Document Type" = TaxCalcItemEntry."Document Type"::"Credit Memo") and
                   not TaxCalcItemEntry.Correction
                then begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Inventory Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Direct Cost Account No.";
                end else begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Direct Cost Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Inventory Account No.";
                end;
            TaxCalcItemEntry."Ledger Entry Type"::"Positive Adjmt.":
                if TaxCalcItemEntry."Amount (Tax)" >= 0 then begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Inventory Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Direct Cost Account No.";
                end else begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Direct Cost Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Inventory Account No.";
                end;
            TaxCalcItemEntry."Ledger Entry Type"::"Negative Adjmt.":
                if TaxCalcItemEntry."Amount (Tax)" < 0 then begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Inventory Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Direct Cost Account No.";
                end else begin
                    TaxCalcItemEntry."Debit Account No." := TaxCalcItemEntry."Direct Cost Account No.";
                    TaxCalcItemEntry."Credit Account No." := TaxCalcItemEntry."Inventory Account No.";
                end;
        end;
    end;

    local procedure TaxCalcEntryINSERT(var TaxCalcItemEntry1: Record "Tax Calc. Item Entry")
    var
        TaxCalcItemEntry0: Record "Tax Calc. Item Entry";
    begin
        TaxCalcItemEntry0.SetCurrentKey("Section Code", "Starting Date");
        TaxCalcItemEntry0.SetRange("Section Code", TaxCalcItemEntry1."Section Code");
        TaxCalcItemEntry0.SetRange("Starting Date", TaxCalcItemEntry1."Starting Date");
        TaxCalcItemEntry0.SetRange("Ending Date", TaxCalcItemEntry1."Ending Date");
        TaxCalcItemEntry0.SetRange("Appl. Entry No.", TaxCalcItemEntry1."Appl. Entry No.");
        TaxCalcItemEntry0.SetRange("Ledger Entry No.", TaxCalcItemEntry1."Ledger Entry No.");
        if TaxCalcItemEntry0.FindFirst() then begin
            TaxCalcItemEntry0.Quantity += TaxCalcItemEntry1.Quantity;
            TaxCalcItemEntry0."Amount (Tax)" += TaxCalcItemEntry1."Amount (Tax)";
            TaxCalcItemEntry0."Debit Quantity" += TaxCalcItemEntry1."Debit Quantity";
            TaxCalcItemEntry0."Debit Amount (Tax)" += TaxCalcItemEntry1."Debit Amount (Tax)";
            TaxCalcItemEntry0.Modify();
        end else begin
            TaxCalcItemEntry1."Entry No." += 1;
            TaxCalcItemEntry1.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxCalcAccumulation(StartDate: Date; EndDate: Date; TaxCalcSectionCode: Code[10])
    var
        TaxCalcHeader: Record "Tax Calc. Header";
        TaxCalcLine: Record "Tax Calc. Line";
        TaxCalcAccumul: Record "Tax Calc. Accumulation";
        TaxCalcItemEntry: Record "Tax Calc. Item Entry";
        TaxCalcSelectionSetup: Record "Tax Calc. Selection Setup";
        TaxCalcLineTmp: Record "Tax Calc. Line" temporary;
        GLCorrespondEntryTmp: Record "G/L Correspondence Entry" temporary;
        TaxCalcAccumul0: Record "Tax Calc. Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        AddValue: Decimal;
    begin
        TaxCalcHeader.SetRange("Section Code", TaxCalcSectionCode);
        TaxCalcHeader.SetRange("Table ID", DATABASE::"Tax Calc. Item Entry");
        if TaxCalcHeader.IsEmpty() then
            exit;

        GLCorrespondEntryTmp.SetCurrentKey("Debit Account No.", "Credit Account No.");
        GLCorrespondEntryTmp.Insert();

        TaxCalcAccumul.Reset();
        if not TaxCalcAccumul.FindLast() then
            TaxCalcAccumul."Entry No." := 0;

        TaxCalcAccumul.Reset();
        TaxCalcAccumul.Init();
        TaxCalcAccumul."Section Code" := TaxCalcSectionCode;
        TaxCalcAccumul."Starting Date" := StartDate;
        TaxCalcAccumul."Ending Date" := EndDate;

        TaxCalcSelectionSetup.Reset();
        TaxCalcSelectionSetup.SetRange("Section Code", TaxCalcSectionCode);

        Clear(TaxDimMgt);

        TaxCalcHeader.FindSet();
        repeat
            TaxCalcSelectionSetup.SetRange("Register No.", TaxCalcHeader."No.");
            if TaxCalcSelectionSetup.FindFirst() then begin
                TaxCalcLineTmp.DeleteAll();
                TaxCalcLine.SetRange("Section Code", TaxCalcSectionCode);
                TaxCalcLine.SetRange(Code, TaxCalcHeader."No.");
                if TaxCalcLine.FindSet() then
                    repeat
                        TaxCalcLineTmp := TaxCalcLine;
                        TaxCalcLineTmp.Value := 0;
                        TaxCalcLineTmp.Insert();
                    until TaxCalcLine.Next() = 0;

                TaxCalcItemEntry.Reset();
                TaxCalcItemEntry.SetCurrentKey("Section Code", "Ending Date");
                TaxCalcItemEntry.SetRange("Section Code", TaxCalcSectionCode);
                TaxCalcItemEntry.SetRange("Ending Date", EndDate);
                TaxCalcItemEntry.SetFilter("Where Used Register IDs", '*~' + TaxCalcHeader."Register ID" + '~*');
                if TaxCalcItemEntry.FindSet() then
                    repeat
                        TaxDimMgt.SetTaxCalcEntryDim(TaxCalcSectionCode,
                          TaxCalcItemEntry."Dimension 1 Value Code", TaxCalcItemEntry."Dimension 2 Value Code",
                          TaxCalcItemEntry."Dimension 3 Value Code", TaxCalcItemEntry."Dimension 4 Value Code");
                        GLCorrespondEntryTmp."Debit Account No." := TaxCalcItemEntry."Debit Account No.";
                        GLCorrespondEntryTmp."Credit Account No." := TaxCalcItemEntry."Credit Account No.";
                        GLCorrespondEntryTmp.Modify();
                        TaxCalcSelectionSetup.FindSet();
                        repeat
                            if (TaxCalcSelectionSetup."Account No." <> '') or
                               (TaxCalcSelectionSetup."Bal. Account No." <> '')
                            then begin
                                if TaxCalcSelectionSetup."Account No." <> '' then
                                    GLCorrespondEntryTmp.SetFilter("Debit Account No.", TaxCalcSelectionSetup."Account No.")
                                else
                                    GLCorrespondEntryTmp.SetRange("Debit Account No.");
                                if TaxCalcSelectionSetup."Bal. Account No." <> '' then
                                    GLCorrespondEntryTmp.SetFilter("Credit Account No.", TaxCalcSelectionSetup."Bal. Account No.")
                                else
                                    GLCorrespondEntryTmp.SetRange("Credit Account No.");
                                if GLCorrespondEntryTmp.Find() then begin
                                    TaxCalcLineTmp.SetRange(Code, TaxCalcSelectionSetup."Register No.");
                                    TaxCalcLineTmp.SetFilter("Selection Line Code", '%1|%2', '', TaxCalcSelectionSetup."Line Code");
                                    TaxCalcLineTmp.SetRange("Line Type", TaxCalcLineTmp."Line Type"::" ");
                                    if TaxCalcLineTmp.FindSet() then
                                        repeat
                                            if TaxDimMgt.ValidateTaxCalcDimFilters(TaxCalcLineTmp) then begin
                                                case TaxCalcLineTmp."Sum Field No." of
                                                    TaxCalcItemEntry.FieldNo("Amount (Tax)"):
                                                        AddValue := TaxCalcItemEntry."Amount (Tax)";
                                                    TaxCalcItemEntry.FieldNo("Credit Amount (Tax)"):
                                                        AddValue := TaxCalcItemEntry."Credit Amount (Tax)";
                                                    TaxCalcItemEntry.FieldNo("Debit Amount (Tax)"):
                                                        AddValue := TaxCalcItemEntry."Debit Amount (Tax)";
                                                    TaxCalcItemEntry.FieldNo("Amount (Actual)"):
                                                        AddValue := TaxCalcItemEntry."Amount (Actual)";
                                                    TaxCalcItemEntry.FieldNo("Credit Amount (Actual)"):
                                                        AddValue := TaxCalcItemEntry."Credit Amount (Actual)";
                                                    TaxCalcItemEntry.FieldNo("Debit Amount (Actual)"):
                                                        AddValue := TaxCalcItemEntry."Debit Amount (Actual)";
                                                    else
                                                        AddValue := 0;
                                                end;
                                                if AddValue <> 0 then begin
                                                    TaxCalcLineTmp.Value += AddValue;
                                                    TaxCalcLineTmp.Modify();
                                                end;
                                            end;
                                        until TaxCalcLineTmp.Next() = 0;
                                end;
                            end;
                        until TaxCalcSelectionSetup.Next() = 0;
                    until TaxCalcItemEntry.Next() = 0;

                TaxCalcLineTmp.Reset();
                if TaxCalcLineTmp.FindSet() then
                    repeat
                        TaxCalcAccumul."Template Line Code" := TaxCalcLineTmp."Line Code";
                        TaxCalcAccumul."Section Code" := TaxCalcLineTmp."Section Code";
                        TaxCalcAccumul."Register No." := TaxCalcLineTmp.Code;
                        TaxCalcAccumul.Indentation := TaxCalcLineTmp.Indentation;
                        TaxCalcAccumul.Bold := TaxCalcLineTmp.Bold;
                        TaxCalcAccumul.Description := TaxCalcLineTmp.Description;
                        TaxCalcAccumul.Amount := TaxCalcLineTmp.Value;
                        TaxCalcAccumul."Amount Period" := TaxCalcLineTmp.Value;
                        TaxCalcAccumul."Template Line No." := TaxCalcLineTmp."Line No.";
                        TaxCalcAccumul."Tax Diff. Amount (Base)" := TaxCalcLineTmp."Tax Diff. Amount (Base)";
                        TaxCalcAccumul."Tax Diff. Amount (Tax)" := TaxCalcLineTmp."Tax Diff. Amount (Tax)";
                        TaxCalcAccumul."Amount Date Filter" :=
                          TaxRegTermMgt.CalcIntervalDate(
                            TaxCalcAccumul."Starting Date",
                            TaxCalcAccumul."Ending Date",
                            TaxCalcLineTmp.Period);
                        TaxCalcAccumul.Amount := TaxCalcAccumul."Amount Period";
                        TaxCalcAccumul."Entry No." += 1;
                        TaxCalcAccumul.Insert();
                        if TaxCalcLineTmp.Period <> '' then begin
                            TaxCalcAccumul0 := TaxCalcAccumul;
                            TaxCalcAccumul0.Reset();
                            TaxCalcAccumul0.SetCurrentKey(
                              "Section Code", "Register No.", "Template Line No.", "Starting Date", "Ending Date");
                            TaxCalcAccumul0.SetRange("Section Code", TaxCalcAccumul."Section Code");
                            TaxCalcAccumul0.SetRange("Register No.", TaxCalcAccumul."Register No.");
                            TaxCalcAccumul0.SetRange("Template Line No.", TaxCalcAccumul."Template Line No.");
                            TaxCalcAccumul0.SetFilter("Starting Date", TaxCalcAccumul."Amount Date Filter");
                            TaxCalcAccumul0.SetFilter("Ending Date", TaxCalcAccumul."Amount Date Filter");
                            TaxCalcAccumul0.CalcSums("Amount Period");
                            TaxCalcAccumul.Amount := TaxCalcAccumul0."Amount Period";
                            TaxCalcAccumul.Modify();
                        end;
                    until TaxCalcLineTmp.Next() = 0;
            end;
        until TaxCalcHeader.Next() = 0;
        TaxCalcLineTmp.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CalcAmountForTaxAccounting(ItemLedgEntry1: Record "Item Ledger Entry") FineAmount: Decimal
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
            until ValueEntry.Next() = 0;
    end;
}

