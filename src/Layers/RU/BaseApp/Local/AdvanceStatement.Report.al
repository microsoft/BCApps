#pragma warning disable AA0247
report 12452 "Advance Statement"
{
    // <changelog>
    //   <change releaseversion="RU4.00.03">Fix 15874</change>
    //   <change releaseversion="RU5.00.01">Fix 19747</change>
    //   <change dev="olegrom" date="2009-11-19" feature="PS55454"
    //    releaseversion="RU5.00.01.04">Fix for RFH 55053</change>
    //   <change dev="ayakunin" date="2009-08-21" area="Captions"
    //     baseversion="RU5.00.01" releaseversion="RU6.00.01">Remove RU captions in request form</change>
    //   <change id="RU41360" dev="ayakunin" date="2009-12-07" area="HRP"
    //     releaseversion="RU6.00.01" feature="NC41360">HRP Merge</change>
    // </changelog>

    Caption = 'Advance Statement';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Invoice));
            RequestFilterFields = "No.";
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                trigger OnAfterGetRecord()
                var
                    VATAccountNo: Code[10];
                    Separator: Text[1];
                begin
                    AccountNo := GetDebitAccount("Purchase Line");
                    if Type = Type::"Empl. Purchase" then begin
                        TestField("Empl. Purchase Document Date");
                        TestField("Empl. Purchase Document No.");
                    end;

                    Buffer.SetRange("Empl. Purchase Document Date", "Empl. Purchase Document Date");
                    Buffer.SetRange("Empl. Purchase Document No.", "Empl. Purchase Document No.");
                    if not Buffer.Find('-') then begin
                        Buffer := "Purchase Line";
                        if "Amount Including VAT" <> Amount then
                            VATAccountNo := GetVATDebitAccount("Purchase Line");
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
                        Buffer.Find('-') else
                        Buffer.Next();
                    if (Buffer."Empl. Purchase Document Date" = 0D) or
                       (Buffer."Empl. Purchase Document No." = '')
                    then begin
                        Buffer."Empl. Purchase Document Date" := "Purchase Header"."Posting Date";
                        Buffer."Empl. Purchase Document No." := "Purchase Header"."No.";
                        Buffer.Description := "Purchase Header"."Posting Description";
                    end;

                    if "Purchase Header"."Currency Code" = '' then begin
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
                LineAmount: Decimal;
            begin
                TestField(Status);
                CalcFields("Amount Including VAT", "Outstanding Amount (LCY)");

                VendLedgerEntry2.Reset();
                VendLedgerEntry2.SetCurrentKey("Vendor No.", "Posting Date");
                VendLedgerEntry2.SetRange("Vendor No.", "Buy-from Vendor No.");
                VendLedgerEntry2.SetFilter("Posting Date", '<= %1', "Posting Date");
                VendLedgerEntry2.SetRange(Positive, false);
                if VendLedgerEntry2.FindLast() then;

                Vend.Get("Buy-from Vendor No.");
                Vend.SetRange("Date Filter", 0D, GetEndFilterDate("Buy-from Vendor No."));
                Vend.CalcFields("Net Change (LCY)");
                if Vend."Net Change (LCY)" < 0 then
                    Rest[1] := Abs(Vend."Net Change (LCY)")
                else
                    OverDraft[1] := Abs(Vend."Net Change (LCY)");

                PaymentNo := 0;
                VendLedgerEntry.Reset();
                VendLedgerEntry.SetCurrentKey("Vendor No.", Open, Positive);
                VendLedgerEntry.SetRange("Vendor No.", Vend."No.");
                VendLedgerEntry.SetRange(Open, true);
                VendLedgerEntry.SetRange(Positive, true);
                VendLedgerEntry.SetRange("Posting Date", VendLedgerEntry2."Posting Date", "Purchase Header"."Posting Date");
                if VendLedgerEntry.Find('-') then
                    repeat
                        PaymentNo += 1;
                        VendLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                        Sum[PaymentNo] := VendLedgerEntry."Remaining Amt. (LCY)";
                        Poluch[PaymentNo] := VendLedgerEntry."Document No.";
                        if PaymentNo = 4 then
                            Error(AdvanceErrorErr);
                    until VendLedgerEntry.Next() = 0;
                VendLedgerEntry.SetRange(Positive, true);

                PurchaseLine.Reset();
                PurchaseLine.SetRange("Document Type", "Purchase Header"."Document Type");
                PurchaseLine.SetRange("Document No.", "Purchase Header"."No.");
                if PurchaseLine.Find('-') then
                    repeat
                        CtSum := CtSum + PurchaseLine."Outstanding Amount (LCY)";
                        AccountNo := GetDebitAccount(PurchaseLine);
                        if PurchaseLine.Amount = PurchaseLine."Amount Including VAT" then
                            CheckDebitAccount(AccountNo, PurchaseLine."Outstanding Amount (LCY)")
                        else
                            if PurchaseLine."Amount Including VAT" <> 0 then begin
                                LineAmount := PurchaseLine."Outstanding Amount (LCY)" /
                                  PurchaseLine."Amount Including VAT" * PurchaseLine.Amount;
                                CheckDebitAccount(AccountNo, LineAmount);
                                AccountNo := GetVATDebitAccount(PurchaseLine);
                                CheckDebitAccount(AccountNo, PurchaseLine."Outstanding Amount (LCY)" - LineAmount);
                            end;
                    until PurchaseLine.Next() = 0;

                VendorPostingGroup.Get("Vendor Posting Group");
                CtAccount := VendorPostingGroup."Payables Account";

                Temp := Rest[1] - OverDraft[1] + Sum[1] + Sum[2] + Sum[3] - "Outstanding Amount (LCY)";
                if Temp > 0 then
                    Rest[2] := Temp
                else
                    OverDraft[2] := Temp;

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
                            OverDraft[3] := Temp;
                    end;
                end;

                AdvanceStatementHelper.InitReportTemplate();
                AdvanceStatementHelper.FillHeader(
                  "Outstanding Amount (LCY)", "No.", "Document Date", "Buy-from Vendor No.", "Buy-from Vendor Name", "Advance Purpose");
                AdvanceStatementHelper.FillAdvance(Abs(Rest[1]), Abs(OverDraft[1]));
                AdvanceStatementHelper.FillAdvanceDetails(
                  Poluch, Sum, "Outstanding Amount (LCY)", Rest[2], OverDraft[2], DtAccount, DtSum, CtAccount, CtSum);
                AdvanceStatementHelper.FillSummary(
                  "No. of Documents", "No. of Pages", "Outstanding Amount (LCY)", AccountantCode,
                  Rest[3], OverDraft[3], VendLedgerEntry3."Document No.", VendLedgerEntry3."Document Date",
                  CashierCode, "Document Date");
                AdvanceStatementHelper.FillReceipt(
                  "No.", "Document Date", "Outstanding Amount (LCY)",
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
                Clear(OverDraft);
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
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
        Buffer: Record "Purchase Line" temporary;
        FAPostingGroup: Record "FA Posting Group";
        FA: Record "Fixed Asset";
        FADeprecationBook: Record "FA Depreciation Book";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        VendLedgerEntry3: Record "Vendor Ledger Entry";
        AdvanceStatementHelper: Codeunit "Advance Statement Helper";
        PaymentNo: Integer;
        Poluch: array[4] of Text;
        "Sum": array[4] of Decimal;
        DtSum: array[8] of Decimal;
        CtSum: Decimal;
        DtAccount: array[8] of Code[20];
        CtAccount: Code[20];
        Rest: array[3] of Decimal;
        OverDraft: array[3] of Decimal;
        Temp: Decimal;
        AccountNo: Code[20];
        AccountantCode: Code[10];
        CashierCode: Code[10];
        CurrAmount: Decimal;
        CurrAmount2: Decimal;
        TotalCurrAmount: Decimal;
        TotalCurrAmount2: Decimal;
        AdvanceErrorErr: Label 'Cannot be issued more than 3 advances.';
        FileName: Text;

    [Scope('OnPrem')]
    procedure InsertDebitAccount(Account: Code[20]; "Sum": Decimal)
    var
        k: Integer;
    begin
        for k := 1 to 8 do
            if DtAccount[k] = '' then begin
                DtAccount[k] := Account;
                DtSum[k] := Sum;
                exit;
            end
    end;

    [Scope('OnPrem')]
    procedure CheckDebitAccount(Account: Code[20]; "Sum": Decimal)
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
    procedure GetDebitAccount(PurchesLineLoc: Record "Purchase Line"): Code[20]
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
    procedure GetVATDebitAccount(PurchesLineLoc: Record "Purchase Line"): Code[10]
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
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure GetEndFilterDate(VendorNo: Code[20]) EndFilterDate: Date
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        EndFilterDate := 0D;
        PurchInvHeader.SetCurrentKey("Posting Date");
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        if PurchInvHeader.FindLast() then
            EndFilterDate := PurchInvHeader."Posting Date";
    end;
}

