#pragma warning disable AA0247
report 12454 "Posted Advance Statement"
{
    // <changelog>
    //   <change releaseversion="RU4.00.03">Fix 15874</change>
    //   <change releaseversion="RU4.00.03">PS17293</change>
    //   <change releaseversion="RU5.00.01">PS19748</change>
    //   <change dev="olegrom" date="2009-11-19" feature="PS55454"
    //    releaseversion="RU5.00.01.04">Fix for RFH 55053</change>
    //   <change dev="ayakunin" date="2009-08-21" area="Captions"
    //     baseversion="RU5.00.01" releaseversion="RU6.00.01">Remove RU captions in request form</change>
    //   <change id="RU41360" dev="ayakunin" date="2009-12-07" area="HRP"
    //     releaseversion="RU6.00.01" feature="NC41360">HRP Merge</change>
    //   <change dev="i-seshma" date="2011-01-19"
    //     releaseversion="RU6.00.01" feature="244393">HRP Merge</change>
    // </changelog>

    Caption = 'Posted Advance Statement';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            dataitem("Purch. Inv. Line"; "Purch. Inv. Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    VATAccountNo: Code[10];
                    Separator: Text[1];
                begin
                    AccountNo := GetDebitAccount("Purch. Inv. Line");
                    Buffer.SetRange("Empl. Purchase Document Date", "Empl. Purchase Document Date");
                    Buffer.SetRange("Empl. Purchase Document No.", "Empl. Purchase Document No.");
                    if not Buffer.Find('-') then begin
                        Buffer := "Purch. Inv. Line";
                        if "Amount Including VAT" <> Amount then
                            VATAccountNo := GetVATDebitAccount("Purch. Inv. Line");
                        Separator := '';
                        if VATAccountNo <> '' then
                            Separator := ',';
                        Buffer."Description 2" := CopyStr(AccountNo + Separator + VATAccountNo, 1, 30);
                        Buffer.Insert();
                    end else begin
                        Buffer."Amount Including VAT" += "Amount Including VAT";
                        if AccountNo <> Buffer."Description 2" then
                            Buffer."Description 2" := '';
                        Buffer.Modify();
                    end;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        Buffer.Find('-')
                    else
                        Buffer.Next();
                    if (Buffer."Empl. Purchase Document Date" = 0D) or
                       (Buffer."Empl. Purchase Document No." = '')
                    then begin
                        Buffer."Empl. Purchase Document Date" := "Purch. Inv. Header"."Posting Date";
                        Buffer."Empl. Purchase Document No." := "Purch. Inv. Header"."No.";
                        Buffer.Description := "Purch. Inv. Header"."Posting Description";
                    end;

                    if "Purch. Inv. Header"."Currency Code" = '' then begin
                        CurrAmount := Buffer."Amount Including VAT";
                        TotalCurrAmount += Buffer."Amount Including VAT";
                    end else begin
                        CurrAmount2 := Buffer."Amount Including VAT";
                        TotalCurrAmount2 += Buffer."Amount Including VAT";
                    end;

                    AdvanceStatementHelper.FillBody(
                      Number, Buffer."Empl. Purchase Document Date", Buffer."Empl. Purchase Document No.",
                      Buffer.Description, CurrAmount, CurrAmount2, Buffer."Description 2");
                end;

                trigger OnPostDataItem()
                begin
                    AdvanceStatementHelper.FillFooter(TotalCurrAmount, TotalCurrAmount2);
                end;

                trigger OnPreDataItem()
                begin
                    Buffer.Reset();
                    SetRange(Number, 1, Buffer.Count);
                    TotalCurrAmount := 0;
                    TotalCurrAmount2 := 0;

                    AdvanceStatementHelper.FillPageHeader();
                end;
            }

            trigger OnAfterGetRecord()
            var
                LineAmountInclVAT: Decimal;
                LineAmount: Decimal;
            begin
                CalcFields("Amount Including VAT");
                if "Currency Code" <> '' then
                    AmountInclVATLCY := CurrencyExchRate.ExchangeAmtFCYToFCY("Posting Date", "Currency Code", '', "Amount Including VAT")
                else
                    AmountInclVATLCY := "Amount Including VAT";

                VendLedgerEntry2.Reset();
                VendLedgerEntry2.SetCurrentKey("Vendor No.", "Posting Date");
                VendLedgerEntry2.SetRange("Vendor No.", "Buy-from Vendor No.");
                VendLedgerEntry2.SetRange(Positive, false);
                VendLedgerEntry2.SetFilter("Posting Date", '<= %1', "Posting Date");
                if VendLedgerEntry2.FindLast() then;

                Vend.Get("Buy-from Vendor No.");
                Vend.SetRange("Date Filter", 0D, CalcDate('<-1D>', "Posting Date"));
                Vend.CalcFields("Net Change (LCY)");
                if Vend."Net Change (LCY)" < 0 then
                    Rest[1] := Abs(Vend."Net Change (LCY)")
                else
                    Overdraft[1] := Abs(Vend."Net Change (LCY)");

                PaymentNo := 0;

                VendLedgerEntry1.Reset();
                VendLedgerEntry1.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                VendLedgerEntry1.SetRange("Document No.", "Purch. Inv. Header"."No.");
                VendLedgerEntry1.SetRange("Vendor No.", "Purch. Inv. Header"."Buy-from Vendor No.");
                VendLedgerEntry1.SetRange("Document Type", VendLedgerEntry1."Document Type"::Invoice);
                VendLedgerEntry1.FindFirst();
                InvoiceEntryNo := VendLedgerEntry1."Entry No.";
                FindApplnEntries(InvoiceEntryNo);

                VendLedgerEntry.Reset();
                VendLedgerEntry.SetCurrentKey("Vendor No.", Open, Positive);
                VendLedgerEntry.SetRange("Vendor No.", Vend."No.");
                VendLedgerEntry.SetRange(Open, true);
                VendLedgerEntry.SetRange(Positive, true);
                VendLedgerEntry.SetRange("Posting Date", VendLedgerEntry2."Posting Date", "Posting Date");
                VendLedgerEntry.SetRange("Entry No.", 0, InvoiceEntryNo);
                if VendLedgerEntry.Find('-') then
                    repeat
                        VendLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                        AddPayment(VendLedgerEntry."Remaining Amt. (LCY)", VendLedgerEntry."Document No.");
                    until VendLedgerEntry.Next() = 0;
                VendLedgerEntry.SetRange(Positive, true);

                PurchaseLine.Reset();
                PurchaseLine.SetRange("Document No.", "No.");
                if PurchaseLine.Find('-') then
                    repeat
                        LineAmountInclVAT :=
                          CurrencyExchRate.ExchangeAmtFCYToFCY("Posting Date", "Currency Code", '', PurchaseLine."Amount Including VAT");
                        CtSum := CtSum + LineAmountInclVAT;
                        AccountNo := GetDebitAccount(PurchaseLine);
                        if PurchaseLine.Amount = PurchaseLine."Amount Including VAT" then
                            CheckDebitAccount(AccountNo, LineAmountInclVAT)
                        else
                            if PurchaseLine."Amount Including VAT" <> 0 then begin
                                LineAmount := LineAmountInclVAT /
                                  PurchaseLine."Amount Including VAT" * PurchaseLine.Amount;
                                CheckDebitAccount(AccountNo, LineAmount);
                                AccountNo := GetVATDebitAccount(PurchaseLine);
                                CheckDebitAccount(AccountNo, LineAmountInclVAT - LineAmount);
                            end;
                    until PurchaseLine.Next() = 0;

                VendorPostingGroup.Get("Vendor Posting Group");
                CtAccount := VendorPostingGroup."Payables Account";
                Temp := Rest[1] - Overdraft[1] - AmountInclVATLCY;
                if Temp > 0 then
                    Rest[2] := Temp
                else
                    Overdraft[2] := Temp;

                if "Remaining/Overdraft Doc. No." <> '' then begin
                    VendLedgerEntry3.Reset();
                    VendLedgerEntry3.SetCurrentKey("Document No.");
                    VendLedgerEntry3.SetRange("Document No.", "Remaining/Overdraft Doc. No.");
                    if VendLedgerEntry3.FindFirst() then begin
                        VendLedgerEntry3.CalcFields("Amount (LCY)");
                        Temp := VendLedgerEntry3."Amount (LCY)";
                        if Temp < 0 then
                            Rest[3] := Temp
                        else
                            Overdraft[3] := Temp;
                    end;
                end;

                AdvanceStatementHelper.InitReportTemplate();
                AdvanceStatementHelper.FillHeader(
                  AmountInclVATLCY, "No.", "Document Date", "Buy-from Vendor No.", "Buy-from Vendor Name", "Advance Purpose");
                AdvanceStatementHelper.FillAdvance(Abs(Rest[1]), Abs(Overdraft[1]));
                AdvanceStatementHelper.FillAdvanceDetails(
                  Poluch, Sum, AmountInclVATLCY, Rest[2], Overdraft[2], DtAccount, DtSum, CtAccount, CtSum);
                AdvanceStatementHelper.FillSummary(
                  "No. of Documents", "No. of Pages", AmountInclVATLCY, AccountantCode,
                  Rest[3], Overdraft[3], VendLedgerEntry3."Document No.", VendLedgerEntry3."Document Date",
                  CashierCode, "Document Date");
                AdvanceStatementHelper.FillReceipt(
                  "No.", "Document Date", AmountInclVATLCY,
                  "No. of Documents", "No. of Pages", CashierCode);
            end;

            trigger OnPostDataItem()
            begin
                if FileName <> '' then
                    AdvanceStatementHelper.ExportDataToClientFile(FileName)
                else
                    AdvanceStatementHelper.ExportData();
            end;

            trigger OnPreDataItem()
            begin
                Clear(DtAccount);
                Clear(DtSum);
                CtAccount := '';
                CtSum := 0;
                Clear(Rest);
                Clear(Overdraft);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CashierCode; CashierCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accountant (cashier)';
                        TableRelation = Employee;
                    }
                    field(AccountantCode; AccountantCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accountant';
                        TableRelation = Employee;
                    }
                }
            }
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
        CompInf.Get();
    end;

    var
        CompInf: Record "Company Information";
        Vend: Record Vendor;
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseLine: Record "Purch. Inv. Line";
        GeneralPostingSetup: Record "General Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
        Buffer: Record "Purch. Inv. Line" temporary;
        FAPostingGroup: Record "FA Posting Group";
        FA: Record "Fixed Asset";
        FADeprecationBook: Record "FA Depreciation Book";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        VendLedgerEntry3: Record "Vendor Ledger Entry";
        CurrencyExchRate: Record "Currency Exchange Rate";
        AdvanceStatementHelper: Codeunit "Advance Statement Helper";
        PaymentNo: Integer;
        Poluch: array[4] of Text;
        "Sum": array[4] of Decimal;
        DtSum: array[8] of Decimal;
        CtSum: Decimal;
        DtAccount: array[8] of Code[10];
        CtAccount: Code[10];
        Rest: array[4] of Decimal;
        Overdraft: array[4] of Decimal;
        Temp: Decimal;
        AccountNo: Code[10];
        CashierCode: Code[10];
        AccountantCode: Code[10];
        CurrAmount: Decimal;
        CurrAmount2: Decimal;
        AmountInclVATLCY: Decimal;
        InvoiceEntryNo: Integer;
        TotalCurrAmount: Decimal;
        TotalCurrAmount2: Decimal;
        AdvanceErrorErr: Label 'Cannot be issued more than 3 advances.';
        FileName: Text;

    [Scope('OnPrem')]
    procedure InsertDebitAccount(Account: Code[10]; "Sum": Decimal)
    var
        k: Integer;
    begin
        for k := 1 to 8 do
            if DtAccount[k] = '' then begin
                DtAccount[k] := Account;
                DtSum[k] := Sum;
                exit;
            end;
    end;

    [Scope('OnPrem')]
    procedure CheckDebitAccount(Account: Code[10]; "Sum": Decimal)
    var
        k: Integer;
    begin
        for k := 1 to 8 do
            if DtAccount[k] = Account then begin
                DtSum[k] := DtSum[k] + Sum;
                exit;
            end;
        InsertDebitAccount(Account, Sum);
    end;

    [Scope('OnPrem')]
    procedure GetDebitAccount(PurchesLineLoc: Record "Purch. Inv. Line"): Code[10]
    begin
        case PurchesLineLoc.Type of
            PurchesLineLoc.Type::"G/L Account":
                exit(PurchesLineLoc."No.");
            PurchesLineLoc.Type::Item:
                begin
                    InvPostingSetup.Get(PurchesLineLoc."Location Code", PurchesLineLoc."Posting Group");
                    exit(InvPostingSetup."Inventory Account");
                end;
            PurchesLineLoc.Type::"Charge (Item)":
                begin
                    GeneralPostingSetup.Get(PurchesLineLoc."Gen. Bus. Posting Group", PurchesLineLoc."Gen. Prod. Posting Group");
                    exit(GeneralPostingSetup."Purch. Account");
                end;
            PurchesLineLoc.Type::"Fixed Asset":
                begin
                    FA.Get(PurchesLineLoc."No.");
                    PurchesLineLoc.TestField("Depreciation Book Code");
                    FADeprecationBook.Get(PurchesLineLoc."No.", PurchesLineLoc."Depreciation Book Code");
                    FAPostingGroup.Get(FADeprecationBook."FA Posting Group");
                    exit(FAPostingGroup."Acquisition Cost Account");
                end;
            PurchesLineLoc.Type::"Empl. Purchase":
                begin
                    PurchesLineLoc.TestField("Empl. Purchase Vendor No.");
                    PurchesLineLoc.TestField("Empl. Purchase Entry No.");
                    Vend.Get(PurchesLineLoc."Empl. Purchase Vendor No.");
                    Vend.TestField("Vendor Posting Group");
                    VendorPostingGroup.Get(Vend."Vendor Posting Group");
                    exit(VendorPostingGroup."Payables Account");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATDebitAccount(PurchesLineLoc: Record "Purch. Inv. Line"): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("VAT Bus. Posting Group", PurchesLineLoc."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", PurchesLineLoc."VAT Prod. Posting Group");
        if VATPostingSetup.FindFirst() then begin
            if VATPostingSetup."Unrealized VAT Type" <> VATPostingSetup."Unrealized VAT Type"::" " then begin
                VATPostingSetup.TestField("Purch. VAT Unreal. Account");
                exit(VATPostingSetup."Purch. VAT Unreal. Account");
            end;
            VATPostingSetup.TestField("Trans. VAT Account");
            exit(VATPostingSetup."Trans. VAT Account");
        end;
    end;

    [Scope('OnPrem')]
    procedure FindApplnEntries(VendorLedgerEntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if not VendorLedgerEntry.Get(VendorLedgerEntryNo) then
            exit;
        GetAppliedVendorLedgerEntries(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Posting Date", 0D, "Purch. Inv. Header"."Posting Date" - 1);
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields("Amount (LCY)");
                AddPayment(VendorLedgerEntry."Amount (LCY)", VendorLedgerEntry."Document No.");
            until VendorLedgerEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AddPayment(Amount: Decimal; DocumentNo: Code[20])
    begin
        PaymentNo += 1;
        Sum[PaymentNo] := Amount;
        Poluch[PaymentNo] := DocumentNo;
        if PaymentNo = 4 then
            Error(AdvanceErrorErr);
    end;

    [Scope('OnPrem')]
    procedure GetAppliedVendorLedgerEntries(var VendLedgerEntry: Record "Vendor Ledger Entry")
    var
        CreateVendLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendLedgerEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgerEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        CreateVendLedgerEntry := VendLedgerEntry;
        DtldVendLedgerEntry1.SetCurrentKey("Vendor Ledger Entry No.");
        DtldVendLedgerEntry1.SetRange("Vendor Ledger Entry No.", CreateVendLedgerEntry."Entry No.");
        DtldVendLedgerEntry1.SetRange(Unapplied, false);
        if DtldVendLedgerEntry1.FindSet() then
            repeat
                if DtldVendLedgerEntry1."Vendor Ledger Entry No." =
                   DtldVendLedgerEntry1."Applied Vend. Ledger Entry No."
                then begin
                    DtldVendLedgerEntry2.Init();
                    DtldVendLedgerEntry2.SetCurrentKey("Applied Vend. Ledger Entry No.", "Entry Type");
                    DtldVendLedgerEntry2.SetRange(
                      "Applied Vend. Ledger Entry No.", DtldVendLedgerEntry1."Applied Vend. Ledger Entry No.");
                    DtldVendLedgerEntry2.SetRange("Entry Type", DtldVendLedgerEntry2."Entry Type"::Application);
                    DtldVendLedgerEntry2.SetRange(Unapplied, false);
                    if DtldVendLedgerEntry2.Find('-') then
                        repeat
                            if DtldVendLedgerEntry2."Vendor Ledger Entry No." <>
                               DtldVendLedgerEntry2."Applied Vend. Ledger Entry No."
                            then begin
                                VendLedgerEntry.SetCurrentKey("Entry No.");
                                VendLedgerEntry.SetRange("Entry No.", DtldVendLedgerEntry2."Vendor Ledger Entry No.");
                                if VendLedgerEntry.FindFirst() then
                                    VendLedgerEntry.Mark(true);
                            end;
                        until DtldVendLedgerEntry2.Next() = 0;
                end else begin
                    VendLedgerEntry.SetCurrentKey("Entry No.");
                    VendLedgerEntry.SetRange("Entry No.", DtldVendLedgerEntry1."Applied Vend. Ledger Entry No.");
                    if VendLedgerEntry.FindFirst() then
                        VendLedgerEntry.Mark(true);
                end;
            until DtldVendLedgerEntry1.Next() = 0;
        VendLedgerEntry.SetCurrentKey("Entry No.");
        VendLedgerEntry.SetRange("Entry No.");
        if CreateVendLedgerEntry."Closed by Entry No." <> 0 then begin
            VendLedgerEntry."Entry No." := CreateVendLedgerEntry."Closed by Entry No.";
            VendLedgerEntry.Mark(true);
        end;
        VendLedgerEntry.SetCurrentKey("Closed by Entry No.");
        VendLedgerEntry.SetRange("Closed by Entry No.", CreateVendLedgerEntry."Entry No.");
        if VendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry.Mark(true);
            until VendLedgerEntry.Next() = 0;
        VendLedgerEntry.SetCurrentKey("Entry No.");
        VendLedgerEntry.SetRange("Closed by Entry No.");
        VendLedgerEntry.MarkedOnly(true);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

