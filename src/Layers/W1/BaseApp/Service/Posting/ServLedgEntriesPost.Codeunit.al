// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;

codeunit 5912 "ServLedgEntries-Post"
{
    Permissions = TableData "Service Ledger Entry" = rimd,
                  TableData "Warranty Ledger Entry" = rimd,
                  TableData "Service Register" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ServContract: Record "Service Contract Header";
        ServLedgEntry: Record "Service Ledger Entry";
        WarrantyLedgEntry: Record "Warranty Ledger Entry";
        ServiceRegister: Record "Service Register";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ServOrderMgt: Codeunit ServOrderManagement;
        NextServLedgerEntryNo: Integer;
        NextWarrantyLedgerEntryNo: Integer;
        SrcCode: Code[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 No. %2 for Service %3 %4 cannot be posted. Please define the Service Item No. %5 in Service Contract No. %6.', Comment = 'Service Ledger Entry No. Line No. for Service Invoice SO000001 cannot be posted. Please define the Service Item No. 7 in Service Contract No. SC0001.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InitServiceRegister(var PassedServEntryNo: Integer; var PassedWarrantyEntryNo: Integer)
    var
        SrcCodeSetup: Record "Source Code Setup";
    begin
        NextServLedgerEntryNo := InitServLedgerEntry();
        NextWarrantyLedgerEntryNo := InitWarrantyLedgerEntry();
        PassedServEntryNo := NextServLedgerEntryNo;
        PassedWarrantyEntryNo := NextWarrantyLedgerEntryNo;

        ServiceRegister.Reset();
        ServiceRegister.LockTable();
        ServiceRegister."No." := ServiceRegister.GetLastEntryNo() + 1;
        ServiceRegister.Init();
        ServiceRegister."From Entry No." := NextServLedgerEntryNo;
        ServiceRegister."From Warranty Entry No." := NextWarrantyLedgerEntryNo;
        ServiceRegister."Creation Date" := Today;
        ServiceRegister."Creation Time" := Time;
        SrcCodeSetup.Get();
        SrcCode := SrcCodeSetup."Service Management";
        ServiceRegister."Source Code" := SrcCode;
        ServiceRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServiceRegister."User ID"));

        OnAfterInitServiceRegister(ServiceRegister);
    end;

    procedure FinishServiceRegister(var PassedServEntryNo: Integer; var PassedWarrantyEntryNo: Integer)
    begin
        OnBeforeFinishServiceRegister(ServiceRegister);

        PassedServEntryNo := NextServLedgerEntryNo;
        PassedWarrantyEntryNo := NextWarrantyLedgerEntryNo;

        ServiceRegister."To Warranty Entry No." := NextWarrantyLedgerEntryNo - 1;
        ServiceRegister."To Entry No." := NextServLedgerEntryNo - 1;

        if ServiceRegister."To Warranty Entry No." < ServiceRegister."From Warranty Entry No." then begin
            ServiceRegister."To Warranty Entry No." := 0;
            ServiceRegister."From Warranty Entry No." := 0;
        end;

        if ServiceRegister."To Entry No." >= ServiceRegister."From Entry No." then
            ServiceRegister.Insert();
    end;

    procedure InsertServLedgerEntry(var NextEntryNo: Integer; var ServHeader: Record "Service Header"; var TempServLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; Qty: Decimal; DocNo: Code[20]) Result: Integer
    var
        LineAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServLedgerEntry(NextEntryNo, ServHeader, TempServLine, ServItemLine, Qty, DocNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ServLedgEntry.LockTable();
        ServLedgEntry.Init();
        ServLedgEntry."Entry No." := NextEntryNo;
        if TempServLine."Contract No." <> '' then
            if ServOrderMgt.InServiceContract(TempServLine) then begin
                ServLedgEntry."Service Contract No." := TempServLine."Contract No.";
                if ServContract.Get(ServContract."Contract Type"::Contract, TempServLine."Contract No.") then begin
                    ServLedgEntry."Serv. Contract Acc. Gr. Code" := ServContract."Serv. Contract Acc. Gr. Code";
                    ServLedgEntry."Contract Group Code" := ServContract."Contract Group Code";
                end
            end else
                Error(
                  Text001,
                  TempServLine.TableCaption, TempServLine."Line No.", ServHeader."Document Type",
                  ServHeader."No.", TempServLine."Service Item No.", TempServLine."Contract No.");

        ServLedgEntry.CopyFromServHeader(ServHeader);
        ServLedgEntry.CopyFromServLine(TempServLine, DocNo);
        ServLedgEntry."External Document No." := ServHeader."External Document No.";

        IsHandled := false;
        OnInsertServLedgerEntryOnBeforeCopyServicedInfoFromServiceItemLine(ServLedgEntry, TempServLine, IsHandled);
        if not IsHandled then
            if not CopyServicedInfoFromServiceItemLine(ServLedgEntry, TempServLine."Document Type", TempServLine."Document No.", TempServLine."Service Item Line No.") then
                if not CopyServicedInfoFromServiceItem(ServLedgEntry, TempServLine."Service Item No.") then
                    CopyServicedInfoFromServiceLedgerEntry(ServLedgEntry, TempServLine."Appl.-to Service Entry");

        ServLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServLedgEntry."User ID"));
        ServLedgEntry."No." := TempServLine."No.";
        ServLedgEntry.Quantity := Qty;
        ServLedgEntry."Charged Qty." := Qty;
        if TempServLine."Qty. to Consume" <> 0 then
            ServLedgEntry."Charged Qty." := 0;

        ServLedgEntry."Unit Cost" := GetRefinedUnitCost(TempServLine);
        ServLedgEntry."Cost Amount" := Round(ServLedgEntry."Unit Cost" * Qty, Currency."Amount Rounding Precision");

        ServLedgEntry."Discount %" := TempServLine."Line Discount %";
        ServLedgEntry."Responsibility Center" := ServHeader."Responsibility Center";
        ServLedgEntry."Variant Code" := TempServLine."Variant Code";

        LineAmount := ServLedgEntry."Charged Qty." * TempServLine."Unit Price";
        if ServHeader."Currency Code" = '' then begin
            if TempServLine."Line Discount Type" = TempServLine."Line Discount Type"::"Contract Disc." then
                ServLedgEntry."Contract Disc. Amount" :=
                  Round(TempServLine."Line Discount Amount", Currency."Amount Rounding Precision");

            if ServHeader."Prices Including VAT" then begin
                ServLedgEntry."Unit Price" :=
                  Round(TempServLine."Unit Price" / (1 + TempServLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");
                ServLedgEntry."Discount Amount" :=
                  UsageServiceLedgerEntryDiscountAmount(
                    TempServLine."Qty. to Consume" <> 0, TempServLine."Line Discount Amount", TempServLine."VAT %", Currency."Amount Rounding Precision", true);
                ServLedgEntry."Amount (LCY)" :=
                  Round(LineAmount / (1 + TempServLine."VAT %" / 100), Currency."Amount Rounding Precision") - ServLedgEntry."Discount Amount";
            end else begin
                ServLedgEntry."Unit Price" :=
                  Round(TempServLine."Unit Price", Currency."Unit-Amount Rounding Precision");
                ServLedgEntry."Discount Amount" :=
                  UsageServiceLedgerEntryDiscountAmount(
                    TempServLine."Qty. to Consume" <> 0, TempServLine."Line Discount Amount", TempServLine."VAT %", Currency."Amount Rounding Precision", false);
                ServLedgEntry."Amount (LCY)" :=
                  Round(LineAmount, Currency."Amount Rounding Precision") - ServLedgEntry."Discount Amount";
            end;
            ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
        end else begin
            if TempServLine."Line Discount Type" = TempServLine."Line Discount Type"::"Contract Disc." then
                ServLedgEntry."Contract Disc. Amount" := AmountToLCY(ServHeader, TempServLine."Line Discount Amount");

            CalcAmounts(ServLedgEntry, ServHeader, TempServLine, 1);
        end;
        if TempServLine."Qty. to Consume" <> 0 then
            ServLedgEntry."Discount Amount" := 0;
        OnBeforeServLedgerEntryInsert(ServLedgEntry, TempServLine, ServItemLine, ServHeader);
        ServLedgEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
        NextServLedgerEntryNo := NextEntryNo;

        exit(ServLedgEntry."Entry No.");
    end;

    procedure InsertServLedgerEntrySale(var PassedNextEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; Qty: Decimal; QtyToCharge: Decimal; GenJnlLineDocNo: Code[20]; DocLineNo: Integer)
    var
        ServShptLine: Record "Service Shipment Line";
        ApplyToServLedgEntry: Record "Service Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServLedgerEntrySale(PassedNextEntryNo, ServHeader, ServLine, ServItemLine, ServLedgEntry, Qty, QtyToCharge, GenJnlLineDocNo, DocLineNo, IsHandled);
        if IsHandled then
            exit;

        if (ServLine."Document No." = '') and
           (ServLine."Contract No." = '')
        then
            exit;

        GetCurrencyRec(ServHeader."Currency Code");

        if ApplyToServLedgEntry.Get(ServLine."Appl.-to Service Entry") then begin
            if ApplyToServLedgEntry.Type = ApplyToServLedgEntry.Type::"Service Contract" then begin
                ServLedgEntry.Reset();
                ServLedgEntry.SetCurrentKey(
                  "Service Contract No.", "Entry No.", "Entry Type", Type, "Moved from Prepaid Acc.");
                ServLedgEntry.SetRange("Service Contract No.", ApplyToServLedgEntry."Service Contract No.");
                ServLedgEntry.SetRange("Entry Type", ApplyToServLedgEntry."Entry Type");
                ServLedgEntry.SetRange(Type, ApplyToServLedgEntry.Type);
                ServLedgEntry.SetRange("Moved from Prepaid Acc.", ApplyToServLedgEntry."Moved from Prepaid Acc.");
                ServLedgEntry.SetRange("Entry No.", ApplyToServLedgEntry."Entry No.");
                OnInsertServLedgerEntrySaleOnBeforeCloseEntries(ServLedgEntry, ApplyToServLedgEntry, ServLine, ServHeader);
                ServLedgEntry.ModifyAll(Open, false);
                if ServHeader."Document Type" = ServHeader."Document Type"::Invoice then begin
                    ServLedgEntry.ModifyAll("Document Type", ServLedgEntry."Document Type"::Invoice);
                    ServLedgEntry.ModifyAll("Document No.", GenJnlLineDocNo);
                end;
                exit;
            end;
            ApplyToServLedgEntry.Open := false;
            ApplyToServLedgEntry.Modify();
        end;

        ServContract.Reset();
        ServLedgEntry.Reset();
        ServLedgEntry.LockTable();

        ServLedgEntry.Init();
        NextServLedgerEntryNo := PassedNextEntryNo;
        ServLedgEntry."Entry No." := NextServLedgerEntryNo;

        if ServLine."Contract No." <> '' then
            if ServContract.Get(ServContract."Contract Type"::Contract, ServLine."Contract No.") then begin
                ServLedgEntry."Service Contract No." := ServContract."Contract No.";
                ServLedgEntry."Contract Group Code" := ServContract."Contract Group Code";
                ServLedgEntry."Serv. Contract Acc. Gr. Code" := ServContract."Serv. Contract Acc. Gr. Code";
            end;

        if not CopyServicedInfoFromServiceItemLine(
             ServLedgEntry, ServLine."Document Type",
             ServLine."Document No.", ServLine."Service Item Line No.")
        then begin
            if (ServLine."Shipment No." <> '') and (ServLine."Shipment Line No." <> 0) then begin
                ServShptLine.Get(ServLine."Shipment No.", ServLine."Shipment Line No.");
                CopyServicedInfoFromServiceItemLine(
                  ServLedgEntry, ServItemLine."Document Type"::Order,
                  ServShptLine."Order No.", ServShptLine."Service Item Line No.");
            end else
                CopyServicedInfoFromServiceItem(ServLedgEntry, ServLine."Service Item No.");
            OnInsertServLedgerEntrySaleOnAfterCopyFromServItemLine(ServLedgEntry, ServItemLine);
        end;

        case ServHeader."Document Type" of
            ServHeader."Document Type"::"Credit Memo":
                ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::"Credit Memo";
            else
                if (ServHeader."Document Type" = ServHeader."Document Type"::Order) and
                    (ServLine."Qty. to Consume" <> 0)
                then
                    ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::Shipment
                else
                    ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::Invoice;
        end;

        ServLedgEntry."Document No." := GenJnlLineDocNo;
        ServLedgEntry."External Document No." := ServHeader."External Document No.";
        ServLedgEntry.Open := false;
        if ServLine."Document No." <> '' then begin
            if ServHeader."Document Type" = ServHeader."Document Type"::Order then
                ServLedgEntry."Service Order No." := ServLine."Document No.";
            ServLedgEntry."Job No." := ServLine."Job No.";
            ServLedgEntry."Job Task No." := ServLine."Job Task No.";
            ServLedgEntry."Job Line Type" := ServLine."Job Line Type";
        end;
        // fill-in Service Order No with the value, taken from the shipment specified in Get Shipment Lines
        if (ServLedgEntry."Service Order No." = '') and
           (ServHeader."Document Type" = ServHeader."Document Type"::Invoice) and
           (ServLine."Shipment No." <> '')
        then
            ServLedgEntry."Service Order No." := GetOrderNoFromShipment(ServLine."Shipment No.");

        ServLedgEntry."Moved from Prepaid Acc." := true;
        ServLedgEntry."Posting Date" := ServHeader."Posting Date";
        if QtyToCharge = 0 then
            ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Consume
        else
            ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Sale;

        ServLedgEntry."Bill-to Customer No." := ServHeader."Bill-to Customer No.";
        ServLedgEntry."Customer No." := ServHeader."Customer No.";
        ServLedgEntry."Ship-to Code" := ServHeader."Ship-to Code";
        ServLedgEntry."Service Order Type" := ServHeader."Service Order Type";
        FillFromServiceLine(ServLedgEntry, ServLine);
        ServLedgEntry."Unit of Measure Code" := ServLine."Unit of Measure Code";
        ServLedgEntry."Work Type Code" := ServLine."Work Type Code";
        ServLedgEntry."Service Item No. (Serviced)" := ServLine."Service Item No.";
        ServLedgEntry.Description := ServLine.Description;
        ServLedgEntry."Responsibility Center" := ServHeader."Responsibility Center";
        ServLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServLedgEntry."User ID"));
        ServLedgEntry."Location Code" := ServLine."Location Code";
        case ServLine.Type of
            ServLine.Type::" ":
                ServLedgEntry.Type := ServLedgEntry.Type::" ";
            ServLine.Type::Item:
                begin
                    ServLedgEntry.Type := ServLedgEntry.Type::Item;
                    ServLedgEntry."Bin Code" := ServLine."Bin Code";
                end;
            ServLine.Type::Resource:
                ServLedgEntry.Type := ServLedgEntry.Type::Resource;
            ServLine.Type::Cost:
                ServLedgEntry.Type := ServLedgEntry.Type::"Service Cost";
            ServLine.Type::"G/L Account":
                ServLedgEntry.Type := ServLedgEntry.Type::"G/L Account";
        end;
        ServLedgEntry."No." := ServLine."No.";
        ServLedgEntry."Document Line No." := DocLineNo;
        ServLedgEntry.Quantity := Qty;
        ServLedgEntry."Charged Qty." := QtyToCharge;
        ServLedgEntry."Discount %" := -ServLine."Line Discount %";
        ServLedgEntry."Unit Cost" := -GetRefinedUnitCost(ServLine);
        ServLedgEntry."Cost Amount" := -Round(ServLedgEntry."Unit Cost" * Qty, Currency."Amount Rounding Precision");
        if ServHeader."Currency Code" = '' then begin
            ServLedgEntry."Unit Price" := -ServLine."Unit Price";
            ServLedgEntry."Discount Amount" := ServLine."Line Discount Amount";
            ServLedgEntry."Amount (LCY)" := ServLine.Amount;
            ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
            if ServHeader."Prices Including VAT" then begin
                ServLedgEntry."Unit Price" :=
                  Round(ServLedgEntry."Unit Price" / (1 + ServLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");
                ServLedgEntry."Discount Amount" :=
                  Round(ServLedgEntry."Discount Amount" / (1 + ServLine."VAT %" / 100), Currency."Amount Rounding Precision");
            end;
        end else begin
            ServLedgEntry."Unit Price" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  ServHeader."Posting Date", ServHeader."Currency Code",
                  -ServLine."Unit Price", ServHeader."Currency Factor"), Currency."Unit-Amount Rounding Precision");

            if ServHeader."Prices Including VAT" then
                ServLedgEntry."Unit Price" := Round(ServLedgEntry."Unit Price" / (1 + ServLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");

            TotalAmount := ServLedgEntry."Unit Price" * Abs(ServLedgEntry."Charged Qty.");
            if ServLedgEntry."Discount %" <> 0 then
                ServLedgEntry."Discount Amount" :=
                  -Round(TotalAmount * ServLedgEntry."Discount %" / 100, Currency."Amount Rounding Precision")
            else
                ServLedgEntry."Discount Amount" := 0;
            ServLedgEntry."Amount (LCY)" :=
              Round(TotalAmount - ServLedgEntry."Discount Amount", Currency."Amount Rounding Precision");
            ServLedgEntry.Amount :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  ServHeader."Posting Date", ServHeader."Currency Code",
                  ServLedgEntry."Amount (LCY)", ServHeader."Currency Factor"), Currency."Unit-Amount Rounding Precision");
        end;

        if ApplyToServLedgEntry.Get(ServLine."Appl.-to Service Entry") then
            ServLedgEntry."Contract Disc. Amount" := ApplyToServLedgEntry."Contract Disc. Amount";

        OnBeforeServLedgerEntrySaleInsert(ServLedgEntry, ServLine, ServItemLine, ServHeader);
        ServLedgEntry.Insert();
        NextServLedgerEntryNo += 1;
        PassedNextEntryNo := NextServLedgerEntryNo;
    end;

    local procedure InsertServLedgEntryCrMemo(var PassedNextEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; GenJnlLineDocNo: Code[20])
    var
        ServItem: Record "Service Item";
        TotalAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServLedgEntryCrMemo(PassedNextEntryNo, ServHeader, ServLine, GenJnlLineDocNo, IsHandled);
        if IsHandled then
            exit;

        if ServLine."Qty. to Invoice" = 0 then
            exit;

        GetCurrencyRec(ServHeader."Currency Code");

        ServLedgEntry.Reset();
        ServLedgEntry.LockTable();

        ServLedgEntry.Init();
        NextServLedgerEntryNo := PassedNextEntryNo;
        ServLedgEntry."Entry No." := NextServLedgerEntryNo;

        if ServItem.Get(ServLine."Service Item No.") then begin
            ServLedgEntry."Service Item No. (Serviced)" := ServItem."No.";
            ServLedgEntry."Item No. (Serviced)" := ServItem."Item No.";
            ServLedgEntry."Serial No. (Serviced)" := ServItem."Serial No.";
        end;

        ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::"Credit Memo";
        ServLedgEntry."Document No." := GenJnlLineDocNo;
        ServLedgEntry."Document Line No." := ServLine."Line No.";
        ServLedgEntry."External Document No." := ServHeader."External Document No.";
        ServLedgEntry.Open := false;
        ServLedgEntry."Moved from Prepaid Acc." := true;
        ServLedgEntry."Posting Date" := ServHeader."Posting Date";
        ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Sale;
        ServLedgEntry."Bill-to Customer No." := ServHeader."Bill-to Customer No.";
        ServLedgEntry."Customer No." := ServHeader."Customer No.";
        ServLedgEntry."Ship-to Code" := ServHeader."Ship-to Code";
        FillFromServiceLine(ServLedgEntry, ServLine);
        ServLedgEntry."Location Code" := ServLine."Location Code";
        ServLedgEntry.Description := ServLine.Description;
        ServLedgEntry."Responsibility Center" := ServHeader."Responsibility Center";
        ServLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServLedgEntry."User ID"));
        case ServLine.Type of
            ServLine.Type::" ":
                ServLedgEntry.Type := ServLedgEntry.Type::" ";
            ServLine.Type::Item:
                ServLedgEntry.Type := ServLedgEntry.Type::Item;
            ServLine.Type::Resource:
                ServLedgEntry.Type := ServLedgEntry.Type::Resource;
            ServLine.Type::Cost:
                ServLedgEntry.Type := ServLedgEntry.Type::"Service Cost";
            ServLine.Type::"G/L Account":
                ServLedgEntry.Type := ServLedgEntry.Type::"G/L Account";
        end;
        if ServLedgEntry.Type = ServLedgEntry.Type::Item then
            ServLedgEntry."Bin Code" := ServLine."Bin Code";
        ServLedgEntry."No." := ServLine."No.";
        ServLedgEntry.Quantity := ServLine.Quantity;
        ServLedgEntry."Charged Qty." := ServLine."Qty. to Invoice";
        ServLedgEntry."Discount %" := ServLine."Line Discount %";
        ServLedgEntry."Unit Cost" := GetRefinedUnitCost(ServLine);
        ServLedgEntry."Cost Amount" := Round(ServLedgEntry."Unit Cost" * ServLine.Quantity, Currency."Amount Rounding Precision");
        ServLedgEntry."Job Line Type" := ServLedgEntry."Job Line Type"::" ";
        if ServHeader."Currency Code" = '' then begin
            ServLedgEntry."Unit Price" := ServLine."Unit Price";
            ServLedgEntry."Discount Amount" := ServLine."Line Discount Amount";
            ServLedgEntry."Amount (LCY)" := ServLine.Amount;
            ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
            if ServHeader."Prices Including VAT" then begin
                ServLedgEntry."Unit Price" :=
                  Round(ServLedgEntry."Unit Price" / (1 + ServLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");
                ServLedgEntry."Discount Amount" :=
                  Round(ServLedgEntry."Discount Amount" / (1 + ServLine."VAT %" / 100), Currency."Amount Rounding Precision");
            end;
        end else begin
            ServLedgEntry."Unit Price" :=
              Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  ServHeader."Posting Date", ServHeader."Currency Code",
                  ServLine."Unit Price", ServHeader."Currency Factor"));

            if ServHeader."Prices Including VAT" then
                ServLedgEntry."Unit Price" := Round(ServLedgEntry."Unit Price" / (1 + ServLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");

            TotalAmount := ServLedgEntry."Unit Price" * Abs(ServLedgEntry."Charged Qty.");
            if ServLedgEntry."Discount %" <> 0 then
                ServLedgEntry."Discount Amount" :=
                  Abs(Round(TotalAmount * ServLedgEntry."Discount %" / 100, Currency."Amount Rounding Precision"))
            else
                ServLedgEntry."Discount Amount" := 0;
            ServLedgEntry."Amount (LCY)" :=
              Round(TotalAmount - ServLedgEntry."Discount Amount");
            ServLedgEntry.Amount :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  ServHeader."Posting Date", ServHeader."Currency Code",
                  ServLedgEntry."Amount (LCY)", ServHeader."Currency Factor"));
        end;
        OnInsertServLedgEntryCrMemoOnBeforeServLedgEntryInsert(ServLedgEntry, ServHeader, ServLine);
        ServLedgEntry.Insert();
        NextServLedgerEntryNo += 1;
        PassedNextEntryNo := NextServLedgerEntryNo;
    end;

    local procedure InsertServLedgerEntryCrMUsage(var NextEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; DocNo: Code[20])
    var
        LineAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServLedgerEntryCrMUsage(NextEntryNo, ServHeader, ServLine, DocNo, IsHandled);
        if IsHandled then
            exit;

        if ServLine."Qty. to Invoice" = 0 then
            exit;
        ServLedgEntry.Init();
        NextServLedgerEntryNo := NextEntryNo;
        ServLedgEntry."Entry No." := NextServLedgerEntryNo;

        ServLedgEntry.CopyFromServHeader(ServHeader);
        ServLedgEntry.CopyFromServLine(ServLine, DocNo);

        ServLedgEntry."Service Contract No." := ServLine."Contract No.";

        CopyServicedInfoCrMemoUsage(ServLine);

        ServLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServLedgEntry."User ID"));
        ServLedgEntry."No." := ServLine."No.";
        ServLedgEntry.Quantity := -ServLine.Quantity;
        ServLedgEntry."Charged Qty." := -ServLine.Quantity;
        if ServLine."Qty. to Consume" <> 0 then
            ServLedgEntry."Charged Qty." := 0;

        ServLedgEntry."Unit Cost" := GetRefinedUnitCost(ServLine);
        ServLedgEntry."Cost Amount" := Round(ServLedgEntry."Unit Cost" * ServLine.Quantity, Currency."Amount Rounding Precision");

        LineAmount := ServLedgEntry."Charged Qty." * ServLine."Unit Price";
        if ServHeader."Currency Code" = '' then begin
            if ServLine."Line Discount Type" = ServLine."Line Discount Type"::"Contract Disc." then
                ServLedgEntry."Contract Disc. Amount" :=
                  Round(ServLine."Line Discount Amount", Currency."Amount Rounding Precision");

            if ServHeader."Prices Including VAT" then begin
                ServLedgEntry."Unit Price" :=
                  Round(ServLine."Unit Price" / (1 + ServLine."VAT %" / 100), Currency."Unit-Amount Rounding Precision");
                ServLedgEntry."Discount Amount" :=
                  -Round(ServLine."Line Discount Amount" / (1 + ServLine."VAT %" / 100), Currency."Amount Rounding Precision");
                ServLedgEntry."Amount (LCY)" :=
                  Round(LineAmount / (1 + ServLine."VAT %" / 100), Currency."Amount Rounding Precision") - ServLedgEntry."Discount Amount";
            end else begin
                ServLedgEntry."Unit Price" :=
                  Round(ServLine."Unit Price", Currency."Unit-Amount Rounding Precision");
                ServLedgEntry."Discount Amount" :=
                  -Round(ServLine."Line Discount Amount", Currency."Amount Rounding Precision");
                ServLedgEntry."Amount (LCY)" :=
                  Round(LineAmount, Currency."Amount Rounding Precision") - ServLedgEntry."Discount Amount";
            end;
            ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
        end else begin
            if ServLine."Line Discount Type" = ServLine."Line Discount Type"::"Contract Disc." then
                ServLedgEntry."Contract Disc. Amount" := AmountToLCY(ServHeader, ServLine."Line Discount Amount");

            CalcAmounts(ServLedgEntry, ServHeader, ServLine, -1);
        end;

        if ServLine."Qty. to Consume" <> 0 then
            ServLedgEntry."Discount Amount" := 0;

        ServLedgEntry."Cost Amount" := -ServLedgEntry."Cost Amount";
        ServLedgEntry."Unit Cost" := -ServLedgEntry."Unit Cost";
        ServLedgEntry."Unit Price" := -ServLedgEntry."Unit Price";
        OnInsertServLedgerEntryCrMUsageOnBeforeServLedgEntryInsert(ServLedgEntry, ServHeader, ServLine);
        ServLedgEntry.Insert();
        NextEntryNo := NextEntryNo + 1;
        NextServLedgerEntryNo := NextEntryNo;
    end;

    local procedure CopyServicedInfoCrMemoUsage(var ServLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyServicedInfoCrMemoUsage(ServLedgEntry, ServLine, IsHandled);
        if IsHandled then
            exit;

        if not CopyServicedInfoFromServiceItemLine(ServLedgEntry, ServLine."Document Type", ServLine."Document No.", ServLine."Service Item Line No.") then
            CopyServicedInfoFromServiceItem(ServLedgEntry, ServLine."Service Item No.");
    end;

    procedure InsertWarrantyLedgerEntry(var PassedWarrantyEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; var ServItemLine: Record "Service Item Line"; Qty: Decimal; GenJnlLineDocNo: Code[20]): Integer
    begin
        if ServLine.Warranty and (ServLine.Type in [ServLine.Type::Item, ServLine.Type::Resource]) and (ServLine."Qty. to Ship" <> 0) then begin
            Clear(WarrantyLedgEntry);
            WarrantyLedgEntry.LockTable();

            WarrantyLedgEntry.Reset();
            WarrantyLedgEntry.Init();
            NextWarrantyLedgerEntryNo := PassedWarrantyEntryNo;
            WarrantyLedgEntry."Entry No." := NextWarrantyLedgerEntryNo;
            WarrantyLedgEntry."Document No." := GenJnlLineDocNo;
            WarrantyLedgEntry."Service Order Line No." := ServLine."Line No.";
            WarrantyLedgEntry."Posting Date" := ServLine."Posting Date";
            WarrantyLedgEntry."Customer No." := ServHeader."Customer No.";
            WarrantyLedgEntry."Ship-to Code" := ServLine."Ship-to Code";
            WarrantyLedgEntry."Bill-to Customer No." := ServHeader."Bill-to Customer No.";

            if not ServItemLine.Get(ServLine."Document Type", ServLine."Document No.", ServLine."Service Item Line No.") then
                Clear(ServItemLine);
            WarrantyLedgEntry."Service Item No. (Serviced)" := ServItemLine."Service Item No.";
            WarrantyLedgEntry."Item No. (Serviced)" := ServItemLine."Item No.";
            WarrantyLedgEntry."Variant Code (Serviced)" := ServItemLine."Variant Code";
            WarrantyLedgEntry."Serial No. (Serviced)" := ServItemLine."Serial No.";
            WarrantyLedgEntry."Service Item Group (Serviced)" := ServItemLine."Service Item Group Code";
            WarrantyLedgEntry."Service Order No." := ServLine."Document No.";
            WarrantyLedgEntry."Service Contract No." := ServLine."Contract No.";
            WarrantyLedgEntry."Fault Reason Code" := ServLine."Fault Reason Code";
            WarrantyLedgEntry."Fault Area Code" := ServLine."Fault Area Code";
            WarrantyLedgEntry."Symptom Code" := ServLine."Symptom Code";
            WarrantyLedgEntry."Fault Code" := ServLine."Fault Code";
            WarrantyLedgEntry."Resolution Code" := ServLine."Resolution Code";
            WarrantyLedgEntry.Type := ServLine.Type;
            WarrantyLedgEntry."No." := ServLine."No.";
            WarrantyLedgEntry.Quantity := Abs(Qty);
            WarrantyLedgEntry."Work Type Code" := ServLine."Work Type Code";
            WarrantyLedgEntry."Unit of Measure Code" := ServLine."Unit of Measure Code";
            WarrantyLedgEntry.Description := ServLine.Description;
            WarrantyLedgEntry."Gen. Bus. Posting Group" := ServLine."Gen. Bus. Posting Group";
            WarrantyLedgEntry."Gen. Prod. Posting Group" := ServLine."Gen. Prod. Posting Group";
            WarrantyLedgEntry."Global Dimension 1 Code" := ServLine."Shortcut Dimension 1 Code";
            WarrantyLedgEntry."Global Dimension 2 Code" := ServLine."Shortcut Dimension 2 Code";
            WarrantyLedgEntry."Dimension Set ID" := ServLine."Dimension Set ID";
            WarrantyLedgEntry.Open := true;
            WarrantyLedgEntry."Vendor No." := ServItemLine."Vendor No.";
            WarrantyLedgEntry."Vendor Item No." := ServItemLine."Vendor Item No.";
            WarrantyLedgEntry."Variant Code" := ServLine."Variant Code";

            if ServLine."Line Discount Type" = ServLine."Line Discount Type"::"Warranty Disc." then begin
                if ServHeader."Currency Code" = '' then
                    WarrantyLedgEntry.Amount := ServLine."Line Discount Amount"
                else
                    WarrantyLedgEntry.Amount := AmountToLCY(ServHeader, ServLine."Line Discount Amount");
                WarrantyLedgEntry.Amount := Abs(WarrantyLedgEntry.Amount);
            end;
            OnBeforeWarrantyLedgerEntryInsert(WarrantyLedgEntry, ServLine);
            WarrantyLedgEntry.Insert();

            NextWarrantyLedgerEntryNo += 1;
            PassedWarrantyEntryNo := NextWarrantyLedgerEntryNo;

            exit(WarrantyLedgEntry."Entry No.");
        end;
        exit(0);
    end;

    local procedure InitServLedgerEntry(): Integer
    begin
        // returns NextEntryNo
        ServLedgEntry.Reset();
        ServLedgEntry.LockTable();
        exit(ServLedgEntry.GetLastEntryNo() + 1);
    end;

    local procedure InitWarrantyLedgerEntry(): Integer
    begin
        WarrantyLedgEntry.Reset();
        WarrantyLedgEntry.LockTable();
        exit(WarrantyLedgEntry.GetLastEntryNo() + 1);
    end;

    procedure ReverseCnsmServLedgEntries(ServiceShipmentLine: Record "Service Shipment Line")
    var
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        TempNewServiceLedgerEntry: Record "Service Ledger Entry" temporary;
    begin
        ServiceLedgerEntry.LockTable();
        ServiceLedgerEntry.Reset();
        ServiceLine.Get(ServiceLine."Document Type"::Order, ServiceShipmentLine."Order No.", ServiceShipmentLine."Order Line No.");
        ServiceLedgerEntry.SetCurrentKey("Entry Type", "Document Type", "Document No.", "Document Line No.");
        ServiceLedgerEntry.SetFilter("Entry Type", '%1|%2', ServiceLedgerEntry."Entry Type"::Consume, ServiceLedgerEntry."Entry Type"::Usage);
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Document No.", ServiceShipmentLine."Document No.");
        ServiceLedgerEntry.SetRange("Document Line No.", ServiceShipmentLine."Line No.");
        if ServiceLedgerEntry.Find('-') then begin
            repeat
                TempNewServiceLedgerEntry.Copy(ServiceLedgerEntry);
                InvertServLedgEntry(TempNewServiceLedgerEntry);
                TempNewServiceLedgerEntry."Entry No." := NextServLedgerEntryNo;
                TempNewServiceLedgerEntry.Insert();
                NextServLedgerEntryNo += 1;
            until ServiceLedgerEntry.Next() = 0;

            TempNewServiceLedgerEntry.Reset();
            if TempNewServiceLedgerEntry.FindSet() then
                repeat
                    ServiceLedgerEntry.Init();
                    ServiceLedgerEntry.Copy(TempNewServiceLedgerEntry);
                    ServiceLedgerEntry.Insert();
                until TempNewServiceLedgerEntry.Next() = 0;
            TempNewServiceLedgerEntry.DeleteAll();
        end;
    end;

    procedure UnapplyOpenServiceLines(var ServiceLine: Record "Service Line")
    var
        ServLedgEntryNo, WarrantyLedgEntryNo : Integer;
    begin
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField("Qty. Shipped Not Invoiced", 0);
            ServiceLine.TestField("Appl.-to Service Entry");

            InitServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);
            ReverseOpenServiceLedgerEntry(ServiceLine);

            ServiceLine."Appl.-to Service Entry" := 0;
            ServiceLine.Modify(true);

            FinishServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);
        until ServiceLine.Next() = 0;
    end;

    local procedure ReverseOpenServiceLedgerEntry(ServiceLine: Record "Service Line")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        NewServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.Get(ServiceLine."Appl.-to Service Entry");
        ServiceLedgerEntry.TestField(Open);

        ServiceLedgerEntry.Open := false;
        ServiceLedgerEntry.Modify();

        NewServiceLedgerEntry.Copy(ServiceLedgerEntry);
        InvertServLedgEntry(NewServiceLedgerEntry);
        NewServiceLedgerEntry."Applies-to Entry No." := ServiceLedgerEntry."Entry No.";
        NewServiceLedgerEntry."Entry No." := NextServLedgerEntryNo;
        NewServiceLedgerEntry.Insert();
        NextServLedgerEntryNo += 1;

        OnAfterReverseOpenServiceLedgerEntry(ServiceLedgerEntry, NextServLedgerEntryNo);
    end;

    procedure ReverseServLedgEntry(var ServShptLine: Record "Service Shipment Line")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        NewServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.LockTable();
        if ServiceLedgerEntry.Get(ServShptLine."Appl.-to Service Entry") then begin
            NewServiceLedgerEntry := ServiceLedgerEntry;
            NewServiceLedgerEntry."Entry No." := NextServLedgerEntryNo;
            InvertServLedgEntry(NewServiceLedgerEntry);
            OnReverseServLedgEntryOnBeforeNewServLedgEntryInsert(NewServiceLedgerEntry, ServiceLedgerEntry, ServShptLine);
            NewServiceLedgerEntry.Insert();
            NextServLedgerEntryNo += 1;
        end;
    end;

    local procedure InvertServLedgEntry(var ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
        ServiceLedgerEntry.Amount := -ServiceLedgerEntry.Amount;
        ServiceLedgerEntry."Amount (LCY)" := -ServiceLedgerEntry."Amount (LCY)";
        ServiceLedgerEntry."Cost Amount" := -ServiceLedgerEntry."Cost Amount";
        ServiceLedgerEntry."Contract Disc. Amount" := -ServiceLedgerEntry."Contract Disc. Amount";
        ServiceLedgerEntry."Discount Amount" := -ServiceLedgerEntry."Discount Amount";
        ServiceLedgerEntry."Charged Qty." := -ServiceLedgerEntry."Charged Qty.";
        ServiceLedgerEntry.Quantity := -ServiceLedgerEntry.Quantity;
    end;

    procedure ReverseWarrantyEntry(var ServShptLine: Record "Service Shipment Line")
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        NewWarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.LockTable();
        if WarrantyLedgerEntry.Get(ServShptLine."Appl.-to Warranty Entry") then begin
            WarrantyLedgerEntry.Open := false;
            WarrantyLedgerEntry.Modify();
            NewWarrantyLedgerEntry := WarrantyLedgerEntry;
            NewWarrantyLedgerEntry."Entry No." := NextWarrantyLedgerEntryNo;
            InvertWarrantyLedgEntry(NewWarrantyLedgerEntry);
            OnReverseWarrantyEntryOnBeforeNewWarrantyLedgEntryInsert(NewWarrantyLedgerEntry, WarrantyLedgerEntry);
            NewWarrantyLedgerEntry.Insert();
            NextWarrantyLedgerEntryNo += 1;
        end;
    end;

    local procedure InvertWarrantyLedgEntry(var WarrantyLedgerEntry: Record "Warranty Ledger Entry")
    begin
        WarrantyLedgerEntry.Amount := -WarrantyLedgerEntry.Amount;
        WarrantyLedgerEntry.Quantity := -WarrantyLedgerEntry.Quantity;
    end;

    procedure CreateCreditEntry(var PassedNextEntryNo: Integer; var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; GenJnlLineDocNo: Code[20])
    var
        ServShptHeader: Record "Service Shipment Header";
        ServContractAccGr: Record "Service Contract Account Group";
        ApplyToServLedgEntry: Record "Service Ledger Entry";
        ServDocReg: Record "Service Document Register";
        ServDocType: Integer;
        ServDocNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCreditEntry(ServDocReg, ServLine, ServHeader, ServLedgEntry, GenJnlLineDocNo, ServDocType, PassedNextEntryNo, ServDocNo, IsHandled);
        if IsHandled then
            exit;

        if ServLine."Contract No." = '' then begin
            InsertServLedgEntryCrMemo(PassedNextEntryNo, ServHeader, ServLine, GenJnlLineDocNo);
            InsertServLedgerEntryCrMUsage(PassedNextEntryNo, ServHeader, ServLine, GenJnlLineDocNo);
            exit;
        end;

        if ServLine.Type = ServLine.Type::" " then
            exit;

        if ServHeader."Document Type" <> ServHeader."Document Type"::"Credit Memo" then
            exit;

        GetCurrencyRec(ServHeader."Currency Code");
        Clear(ServLedgEntry);
        ServLedgEntry.Init();
        NextServLedgerEntryNo := PassedNextEntryNo;
        ServLedgEntry."Entry No." := NextServLedgerEntryNo;

        if ServLine."Shipment No." <> '' then begin
            ServShptHeader.Get(ServLine."Shipment No.");
            ServLine.TestField("Contract No.", ServShptHeader."Contract No.");
            if ServHeader."Document Type" = ServHeader."Document Type"::Order then
                ServLedgEntry."Service Order No." := ServLine."Document No.";
        end;

        if ServLine."Contract No." <> '' then begin
            ServContract.Get(ServContract."Contract Type"::Contract, ServLine."Contract No.");
            ServLedgEntry."Service Contract No." := ServContract."Contract No.";
            ServLedgEntry."Contract Group Code" := ServContract."Contract Group Code";
        end else
            if ServShptHeader."Contract No." <> '' then begin
                ServContract.Get(ServContract."Contract Type"::Contract, ServShptHeader."Contract No.");
                ServLedgEntry."Service Contract No." := ServContract."Contract No.";
                ServLedgEntry."Contract Group Code" := ServContract."Contract Group Code";
                ServLedgEntry."Contract Invoice Period" := Format(ServContract."Invoice Period");
            end;

        if ServLine."Service Item No." <> '' then
            CopyServicedInfoFromServiceItem(ServLedgEntry, ServLine."Service Item No.");

        ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::" ";
        ServLedgEntry."Document No." := GenJnlLineDocNo;
        ServLedgEntry."External Document No." := ServHeader."External Document No.";
        ServLedgEntry.Open := false;
        ServLedgEntry."Posting Date" := ServHeader."Posting Date";
        ServLedgEntry."Moved from Prepaid Acc." := true;
        ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Usage;
        ServLedgEntry."Bill-to Customer No." := ServHeader."Bill-to Customer No.";
        ServLedgEntry."Customer No." := ServHeader."Customer No.";
        ServLedgEntry."Ship-to Code" := ServHeader."Ship-to Code";
        ServLedgEntry."Location Code" := ServLine."Location Code";
        ServLedgEntry."Global Dimension 1 Code" := ServLine."Shortcut Dimension 1 Code";
        ServLedgEntry."Global Dimension 2 Code" := ServLine."Shortcut Dimension 2 Code";
        ServLedgEntry."Dimension Set ID" := ServLine."Dimension Set ID";
        ServLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServLedgEntry."User ID"));
        ServLedgEntry."Job Line Type" := ServLedgEntry."Job Line Type"::" ";

        OnCreateCreditEntryOnBeforeServDocRegServiceDocument(ServLedgEntry, ServHeader, ServLine);
        Clear(ServDocReg);
        ServDocReg.ServiceDocument(ServHeader."Document Type".AsInteger(), ServHeader."No.", ServDocType, ServDocNo);
        case ServDocType of
            DATABASE::"Service Shipment Header", DATABASE::"Service Header":
                begin
                    case ServLine.Type of
                        ServLine.Type::Item:
                            ServLedgEntry.Type := ServLedgEntry.Type::Item;
                        ServLine.Type::Resource:
                            ServLedgEntry.Type := ServLedgEntry.Type::Resource;
                        ServLine.Type::Cost:
                            ServLedgEntry.Type := ServLedgEntry.Type::"Service Cost";
                        ServLine.Type::"G/L Account":
                            ServLedgEntry.Type := ServLedgEntry.Type::"G/L Account";
                    end;
                    ServLedgEntry."No." := ServLine."No.";
                    ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Sale;
                    ServLedgEntry."Document Line No." := ServLine."Line No.";
                    ServLedgEntry."Amount (LCY)" := -ServLine.Amount;
                    ServLedgEntry.Quantity := -ServLine.Quantity;
                    ServLedgEntry."Charged Qty." := -ServLine."Qty. to Invoice";
                    ServLedgEntry."Discount Amount" := -ServLine."Line Discount Amount";
                    ServLedgEntry."Unit Cost" := -GetRefinedUnitCost(ServLine);
                    ServLedgEntry."Cost Amount" := -Round(ServLedgEntry."Unit Cost" * ServLine.Quantity);
                    ServLedgEntry."Discount %" := -ServLine."Line Discount %";
                    ServLedgEntry."Unit Price" :=
                      Round(
                        -(ServLedgEntry."Amount (LCY)" + ServLedgEntry."Discount Amount") / ServLedgEntry.Quantity, Currency."Unit-Amount Rounding Precision");
                    ServLedgEntry."Gen. Bus. Posting Group" := ServLine."Gen. Bus. Posting Group";
                    ServLedgEntry."Gen. Prod. Posting Group" := ServLine."Gen. Prod. Posting Group";
                    ServLedgEntry.Open := false;
                    ServLedgEntry.Description := ServLine.Description;
                    OnCreateCreditEntryOnBeforeServLedgEntryInsertFromServiceHeader(ServLedgEntry, ServHeader, ServLine);
                    ServLedgEntry.Insert();

                    NextServLedgerEntryNo += 1;
                    ServLedgEntry."Entry No." := NextServLedgerEntryNo;
                    ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::"Credit Memo";
                    ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Sale;
                    ServLedgEntry."Document Line No." := ServLine."Line No.";
                    ServLedgEntry."Amount (LCY)" := ServLine.Amount;
                    if ServHeader."Currency Code" <> '' then
                        ServLedgEntry.Amount := AmountToFCY(ServHeader, ServLedgEntry."Amount (LCY)")
                    else
                        ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
                    ServLedgEntry.Quantity := ServLine.Quantity;
                    ServLedgEntry."Charged Qty." := ServLine."Qty. to Invoice";
                    ServLedgEntry."Discount Amount" := ServLine."Line Discount Amount";
                    ServLedgEntry."Unit Cost" := GetRefinedUnitCost(ServLine);
                    ServLedgEntry."Cost Amount" := Round(ServLedgEntry."Unit Cost" * ServLine.Quantity);
                    ServLedgEntry."Discount %" := ServLine."Line Discount %";
                    ServLedgEntry."Unit Price" :=
                      Round(
                        (ServLedgEntry."Amount (LCY)" + ServLedgEntry."Discount Amount") / ServLedgEntry.Quantity, Currency."Unit-Amount Rounding Precision");
                    ServLedgEntry.Description := ServLine.Description;
                    OnCreateCreditEntryOnBeforeServLedgEntryInsertFromServiceHeader(ServLedgEntry, ServHeader, ServLine);
                    ServLedgEntry.Insert();

                    NextServLedgerEntryNo += 1;
                end;
            DATABASE::"Service Contract Header":
                begin
                    ServLedgEntry.Type := ServLedgEntry.Type::"Service Contract";
                    ServLedgEntry."No." := ServDocNo;
                    ServContract.TestField("Serv. Contract Acc. Gr. Code");
                    ServContractAccGr.Get(ServContract."Serv. Contract Acc. Gr. Code");
                    if ServContract.Prepaid and (ServContractAccGr."Prepaid Contract Acc." = ServLine."No.") then begin
                        ServLedgEntry."Moved from Prepaid Acc." := false;
                        ServLedgEntry.Prepaid := true;
                    end;
                    ServLedgEntry."Serv. Contract Acc. Gr. Code" := ServContract."Serv. Contract Acc. Gr. Code";
                    ServLedgEntry."Entry No." := NextServLedgerEntryNo;
                    ServLedgEntry."Document Type" := ServLedgEntry."Document Type"::"Credit Memo";
                    ServLedgEntry."Entry Type" := ServLedgEntry."Entry Type"::Sale;
                    ServLedgEntry."Unit Price" := ServLine."Unit Price";
                    ServLedgEntry."Amount (LCY)" := ServLine.Amount;
                    if ServHeader."Currency Code" <> '' then
                        ServLedgEntry.Amount := AmountToFCY(ServHeader, ServLedgEntry."Amount (LCY)")
                    else
                        ServLedgEntry.Amount := ServLedgEntry."Amount (LCY)";
                    ServLedgEntry.Quantity := ServLine.Quantity;
                    ServLedgEntry."Charged Qty." := ServLine."Qty. to Invoice";
                    ServLedgEntry."Contract Disc. Amount" := -ServLine."Line Discount Amount";
                    ServLedgEntry."Unit Cost" := ServLine."Unit Cost (LCY)";
                    ServLedgEntry."Cost Amount" := Round(ServLedgEntry."Unit Cost" * ServLedgEntry."Charged Qty.", Currency."Amount Rounding Precision");
                    ServLedgEntry."Discount Amount" := ServLine."Line Discount Amount";
                    ServLedgEntry."Discount %" := ServLine."Line Discount %";
                    ServLedgEntry."Gen. Bus. Posting Group" := ServLine."Gen. Bus. Posting Group";
                    ServLedgEntry."Gen. Prod. Posting Group" := ServLine."Gen. Prod. Posting Group";
                    ServLedgEntry.Description := ServLine.Description;
                    if ServLine."Appl.-to Service Entry" <> 0 then
                        if ApplyToServLedgEntry.Get(ServLine."Appl.-to Service Entry") then
                            ServLedgEntry."Posting Date" := ApplyToServLedgEntry."Posting Date";
                    ServLedgEntry."Applies-to Entry No." := ServLine."Appl.-to Service Entry";

                    OnCreateCreditEntryOnBeforeServLedgEntryInsert(ServLedgEntry, ServHeader, ServLine);
                    ServLedgEntry.Insert();

                    NextServLedgerEntryNo += 1;
                end;
        end;

        PassedNextEntryNo := NextServLedgerEntryNo;
        InsertServLedgerEntryCrMUsage(PassedNextEntryNo, ServHeader, ServLine, GenJnlLineDocNo);
    end;

    local procedure GetCurrencyRec(CurrencyCode: Code[10])
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Unit-Amount Rounding Precision");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure CalcDivideAmount(Qty: Decimal; var PassedServHeader: Record "Service Header"; var PassedTempServLine: Record "Service Line"; var PassedVATAmountLine: Record "VAT Amount Line")
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        ServAmtsMgt: Codeunit "Serv-Amounts Mgt.";
    begin
        TempVATAmountLineRemainder.DeleteAll();
        ServAmtsMgt.DivideAmount(2, Qty, PassedServHeader, PassedTempServLine, PassedVATAmountLine, TempVATAmountLineRemainder);
    end;

    local procedure GetOrderNoFromShipment(ShipmentNo: Code[20]): Code[20]
    var
        ServShptHeader: Record "Service Shipment Header";
    begin
        ServShptHeader.Get(ShipmentNo);
        exit(ServShptHeader."Order No.");
    end;

    local procedure AmountToFCY(ServiceHeader: Record "Service Header"; AmountLCY: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Get(ServiceHeader."Currency Code");
        Currency.TestField("Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              ServiceHeader."Posting Date", ServiceHeader."Currency Code",
              AmountLCY, ServiceHeader."Currency Factor"),
            Currency."Amount Rounding Precision"));
    end;

    local procedure AmountToLCY(ServiceHeader: Record "Service Header"; FCAmount: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Get(ServiceHeader."Currency Code");
        Currency.TestField("Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              ServiceHeader."Posting Date", ServiceHeader."Currency Code",
              FCAmount, ServiceHeader."Currency Factor"),
            Currency."Amount Rounding Precision"));
    end;

    local procedure UnitAmountToLCY(var ServiceHeader: Record "Service Header"; FCAmount: Decimal): Decimal
    var
        Currency: Record Currency;
    begin
        Currency.Get(ServiceHeader."Currency Code");
        Currency.TestField("Unit-Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              ServiceHeader."Posting Date", ServiceHeader."Currency Code",
              FCAmount, ServiceHeader."Currency Factor"),
            Currency."Unit-Amount Rounding Precision"));
    end;

    local procedure GetRefinedUnitCost(ServiceLine: Record "Service Line"): Decimal
    var
        Item: Record Item;
    begin
        if ServiceLine.Type = ServiceLine.Type::Item then
            if Item.Get(ServiceLine."No.") then
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    exit(Item."Unit Cost");

        exit(ServiceLine."Unit Cost (LCY)");
    end;

    local procedure UsageServiceLedgerEntryDiscountAmount(Consumption: Boolean; LineDiscountAmt: Decimal; VATPct: Decimal; AmountRoundingPrecision: Decimal; InclVAT: Boolean): Decimal
    begin
        if Consumption then
            exit(0);
        if not InclVAT then
            VATPct := 0;
        exit(Round(LineDiscountAmt / (1 + VATPct / 100), AmountRoundingPrecision));
    end;

    local procedure CalcAmounts(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; Sign: Integer)
    var
        LineAmount: Decimal;
    begin
        LineAmount := ServiceLedgerEntry."Charged Qty." * ServiceLine."Unit Price";
        if ServiceHeader."Prices Including VAT" then begin
            ServiceLedgerEntry."Unit Price" :=
              UnitAmountToLCY(
                ServiceHeader, ServiceLine."Unit Price" / (1 + ServiceLine."VAT %" / 100));
            ServiceLedgerEntry."Discount Amount" :=
              AmountToLCY(
                ServiceHeader, ServiceLine."Line Discount Amount" / (1 + ServiceLine."VAT %" / 100));
            ServiceLedgerEntry."Amount (LCY)" :=
              AmountToLCY(
                ServiceHeader,
                (LineAmount - ServiceLine."Line Discount Amount") / (1 + ServiceLine."VAT %" / 100));
        end else begin
            ServiceLedgerEntry."Unit Price" :=
              UnitAmountToLCY(ServiceHeader, ServiceLine."Unit Price");
            ServiceLedgerEntry."Discount Amount" :=
              AmountToLCY(ServiceHeader, ServiceLine."Line Discount Amount");
            ServiceLedgerEntry."Amount (LCY)" :=
              AmountToLCY(ServiceHeader, LineAmount - ServiceLine."Line Discount Amount");
        end;
        ServiceLedgerEntry."Discount Amount" := Sign * ServiceLedgerEntry."Discount Amount";
        ServiceLedgerEntry.Amount := AmountToFCY(ServiceHeader, ServiceLedgerEntry."Amount (LCY)");
    end;

    local procedure FillFromServiceLine(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceLine: Record "Service Line")
    begin
        ServiceLedgerEntry."Global Dimension 1 Code" := ServiceLine."Shortcut Dimension 1 Code";
        ServiceLedgerEntry."Global Dimension 2 Code" := ServiceLine."Shortcut Dimension 2 Code";
        ServiceLedgerEntry."Dimension Set ID" := ServiceLine."Dimension Set ID";
        ServiceLedgerEntry."Gen. Bus. Posting Group" := ServiceLine."Gen. Bus. Posting Group";
        ServiceLedgerEntry."Gen. Prod. Posting Group" := ServiceLine."Gen. Prod. Posting Group";
        ServiceLedgerEntry."Serv. Price Adjmt. Gr. Code" := ServiceLine."Serv. Price Adjmt. Gr. Code";
        ServiceLedgerEntry."Service Price Group Code" := ServiceLine."Service Price Group Code";
        ServiceLedgerEntry."Fault Reason Code" := ServiceLine."Fault Reason Code";
    end;

    local procedure CopyServicedInfoFromServiceItemLine(var ServiceLedgerEntry: Record "Service Ledger Entry"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; LineNo: Integer): Boolean
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        if ServiceItemLine.Get(DocumentType, DocumentNo, LineNo) then begin
            ServiceLedgerEntry.CopyServicedInfo(
              ServiceItemLine."Service Item No.", ServiceItemLine."Item No.",
              ServiceItemLine."Serial No.", ServiceItemLine."Variant Code");

            OnCopyServicedInfoFromServiceItemLineOnAfterCopyServicedInfo(ServiceLedgerEntry, ServiceItemLine);

            exit(true);
        end;

        exit(false);
    end;

    local procedure CopyServicedInfoFromServiceItem(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceItemNo: Code[20]): Boolean
    var
        ServiceItem: Record "Service Item";
    begin
        if ServiceItem.Get(ServiceItemNo) then begin
            ServiceLedgerEntry.CopyServicedInfo(
              ServiceItem."No.", ServiceItem."Item No.",
              ServiceItem."Serial No.", ServiceItem."Variant Code");

            OnCopyServicedInfoFromServiceItemOnAfterCopyServicedInfo(ServiceLedgerEntry, ServiceItem);

            exit(true);
        end;

        exit(false);
    end;

    local procedure CopyServicedInfoFromServiceLedgerEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; EntryNo: Integer): Boolean
    var
        SourceServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        if SourceServiceLedgerEntry.Get(EntryNo) then begin
            ServiceLedgerEntry.CopyServicedInfo(
              SourceServiceLedgerEntry."Service Item No. (Serviced)", SourceServiceLedgerEntry."Item No. (Serviced)",
              SourceServiceLedgerEntry."Serial No. (Serviced)", SourceServiceLedgerEntry."Variant Code (Serviced)");

            OnCopyServicedInfoFromServiceLedgerEntryOnAfterCopyServicedInfo(ServiceLedgerEntry, SourceServiceLedgerEntry);

            exit(true);
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyServicedInfoCrMemoUsage(var ServiceLedgerEntry: Record "Service Ledger Entry"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCreditEntry(var ServiceDocumentRegister: Record "Service Document Register"; var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; var ServiceLedgerEntry: Record "Service Ledger Entry"; var GenJnlLineDocNo: Code[20]; var ServDocType: Integer; var PassedNextEntryNo: Integer; var ServDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLedgerEntryCrMUsage(var NextEntryNo: Integer; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLedgerEntryInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceLine: Record "Service Line"; ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServLedgerEntrySaleInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceLine: Record "Service Line"; ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarrantyLedgerEntryInsert(var WarrantyLedgerEntry: Record "Warranty Ledger Entry"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServLedgEntryCrMemoOnBeforeServLedgEntryInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServLedgerEntryCrMUsageOnBeforeServLedgEntryInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServLedgerEntryOnBeforeCopyServicedInfoFromServiceItemLine(var ServLedgEntry: Record "Service Ledger Entry"; var TempServLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditEntryOnBeforeServLedgEntryInsert(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditEntryOnBeforeServDocRegServiceDocument(var ServiceLedgerEntry: Record "Service Ledger Entry"; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCreditEntryOnBeforeServLedgEntryInsertFromServiceHeader(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyServicedInfoFromServiceItemLineOnAfterCopyServicedInfo(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyServicedInfoFromServiceItemOnAfterCopyServicedInfo(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyServicedInfoFromServiceLedgerEntryOnAfterCopyServicedInfo(var ServiceLedgerEntry: Record "Service Ledger Entry"; SourceServiceLedgerEntry: Record "Service Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServLedgerEntrySaleOnBeforeCloseEntries(var ServiceLedgerEntry: Record "Service Ledger Entry"; var ApplyToServLedgEntry: Record "Service Ledger Entry"; var ServiceLine: Record "Service Line"; var ServHeader: Record "Service Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServLedgerEntrySaleOnAfterCopyFromServItemLine(var ServLedgEntry: Record "Service Ledger Entry"; var ServItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseWarrantyEntryOnBeforeNewWarrantyLedgEntryInsert(var NewWarrantyLedgerEntry: Record "Warranty Ledger Entry"; var WarrantyLedgerEntry: Record "Warranty Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseServLedgEntryOnBeforeNewServLedgEntryInsert(var NewServLedgEntry: Record "Service Ledger Entry"; var ServLedgEntry: Record "Service Ledger Entry"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLedgerEntry(var NextEntryNo: Integer; var ServiceHeader: Record "Service Header"; var TempServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line"; Qty: Decimal; DocNo: Code[20]; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLedgerEntrySale(var PassedNextEntryNo: Integer; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServiceItemLine: Record "Service Item Line"; var ServiceLedgerEntry: Record "Service Ledger Entry"; Qty: Decimal; QtyToCharge: Decimal; GenJnlLineDocNo: Code[20]; DocLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLedgEntryCrMemo(var PassedNextEntryNo: Integer; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; GenJnlLineDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitServiceRegister(var ServiceRegister: Record "Service Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinishServiceRegister(var ServiceRegister: Record "Service Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseOpenServiceLedgerEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; var NextServLedgerEntryNo: Integer)
    begin
    end;
}

