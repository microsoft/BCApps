#pragma warning disable AA0247
codeunit 17204 "Create Tax Register CV Entry"
{
    TableNo = "Tax Register CV Entry";

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text21000900: Label 'Search Table    #4############################\Begin period    #1##########\End period      #2##########\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Window: Dialog;

    [Scope('OnPrem')]
    procedure CreateRegister(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        Total: Integer;
        Procesing: Integer;
        FiterDueDateTotal: Text[30];
        FiterDueDate45Days90Days: Text[30];
        FilterDueDate90Days3Years: Text[30];
        FilterDueDate3YearsDebit: Text[30];
        FilterDueDate3YearsCredit: Text[30];
        ExistEntry: Boolean;
        CVDebitBalance: array[4] of Decimal;
        CVCreditBalance: array[4] of Decimal;
    begin
        TaxRegMgt.CalcDebitBalancePointDate(SectionCode, EndDate,
          FiterDueDateTotal, FiterDueDate45Days90Days, FilterDueDate90Days3Years, FilterDueDate3YearsDebit);
        TaxRegMgt.CalcCreditBalancePointDate(SectionCode, EndDate, FilterDueDate3YearsCredit);

        TaxRegMgt.ValidateAbsenceCVEntriesDate(StartDate, EndDate, SectionCode);

        TaxRegCVEntry.Reset();
        if not TaxRegCVEntry.FindLast() then
            TaxRegCVEntry."Entry No." := 0;

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        TaxRegCVEntry.Init();
        TaxRegCVEntry."Section Code" := SectionCode;
        TaxRegCVEntry."Starting Date" := StartDate;
        TaxRegCVEntry."Ending Date" := EndDate;

        Clear(CVDebitBalance);
        Clear(CVCreditBalance);

        Vendor.SetFilter("Vendor Type", '%1|%2', Vendor."Vendor Type"::Vendor, Vendor."Vendor Type"::"Resp. Employee");
        Vendor.SetFilter("Vendor Type", '%1', Vendor."Vendor Type"::Vendor);
        Total := Vendor.Count;

        Window.Update(4, Customer.TableCaption());
        Total += Customer.Count();
        if Customer.FindSet() then
            repeat
                Procesing += 1;
                if (Procesing mod 50) = 1 then
                    Window.Update(3, Round((Procesing / Total) * 10000, 1));

                CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                CustLedgEntry.SetRange("Customer No.", Customer."No.");
                CustLedgEntry.SetRange("Posting Date", StartDate, EndDate);

                TaxRegCVEntry."C/V No." := Customer."No.";
                TaxRegCVEntry."Object Type" := TaxRegCVEntry."Object Type"::Customer;

                CustLedgEntry.SetRange(Positive, true);
                ExistEntry := CustLedgEntry.FindFirst();

                DtldCustLedgEntry.Reset();
                DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Positive", "Initial Entry Due Date", "Posting Date");
                DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                DtldCustLedgEntry.SetRange("Initial Entry Positive", true);
                DtldCustLedgEntry.SetFilter("Posting Date", '..%1', EndDate);
                DtldCustLedgEntry.CalcSums("Amount (LCY)");
                if ExistEntry or (DtldCustLedgEntry."Amount (LCY)" <> 0) then begin
                    TaxRegCVEntry."Register Type" := TaxRegCVEntry."Register Type"::"Debit Balance";
                    TaxRegCVEntry."CV Debit Balance Amnt 1" := DtldCustLedgEntry."Amount (LCY)";
                    DtldCustLedgEntry.SetFilter("Initial Entry Due Date", FiterDueDate45Days90Days);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Debit Balance Amnt 2" := DtldCustLedgEntry."Amount (LCY)";
                    DtldCustLedgEntry.SetFilter("Initial Entry Due Date", FilterDueDate90Days3Years);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Debit Balance Amnt 3" := DtldCustLedgEntry."Amount (LCY)";
                    DtldCustLedgEntry.SetFilter("Initial Entry Due Date", FilterDueDate3YearsDebit);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Debit Balance Amnt 4" := DtldCustLedgEntry."Amount (LCY)";
                    TaxRegCVEntry."CV Debit Balance Amnt 2-4" :=
                      TaxRegCVEntry."CV Debit Balance Amnt 2" +
                      TaxRegCVEntry."CV Debit Balance Amnt 3" +
                      TaxRegCVEntry."CV Debit Balance Amnt 4";
                    TaxRegCVEntry."Entry No." += 1;
                    TaxRegCVEntry.Insert();
                    CVDebitBalance[1] += TaxRegCVEntry."CV Debit Balance Amnt 1";
                    CVDebitBalance[2] += TaxRegCVEntry."CV Debit Balance Amnt 2";
                    CVDebitBalance[3] += TaxRegCVEntry."CV Debit Balance Amnt 3";
                    CVDebitBalance[4] += TaxRegCVEntry."CV Debit Balance Amnt 4";
                end;

                CustLedgEntry.SetRange(Positive, false);
                ExistEntry := CustLedgEntry.FindFirst();

                DtldCustLedgEntry.Reset();
                DtldCustLedgEntry.SetCurrentKey("Customer No.", "Initial Entry Positive", "Initial Entry Due Date", "Posting Date");
                DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                DtldCustLedgEntry.SetRange("Initial Entry Positive", false);
                DtldCustLedgEntry.SetFilter("Posting Date", '..%1', EndDate);
                DtldCustLedgEntry.CalcSums("Amount (LCY)");
                if ExistEntry or (DtldCustLedgEntry."Amount (LCY)" <> 0) then begin
                    TaxRegCVEntry."Register Type" := TaxRegCVEntry."Register Type"::"Credit Balance";
                    TaxRegCVEntry."CV Credit Balance Amnt 1" := DtldCustLedgEntry."Amount (LCY)";
                    DtldCustLedgEntry.SetFilter("Initial Entry Due Date", FilterDueDate3YearsCredit);
                    DtldCustLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Credit Balance Amnt 2" := DtldCustLedgEntry."Amount (LCY)";
                    TaxRegCVEntry."Entry No." += 1;
                    TaxRegCVEntry.Insert();
                    CVCreditBalance[1] += TaxRegCVEntry."CV Credit Balance Amnt 1";
                    CVCreditBalance[2] += TaxRegCVEntry."CV Credit Balance Amnt 2";
                end;

            until Customer.Next() = 0;

        Window.Update(4, Vendor.TableCaption());
        if Vendor.FindSet() then
            repeat
                Procesing += 1;
                if (Procesing mod 50) = 1 then
                    Window.Update(3, Round((Procesing / Total) * 10000, 1));
                VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
                VendLedgEntry.SetRange("Posting Date", StartDate, EndDate);

                TaxRegCVEntry."C/V No." := Vendor."No.";
                TaxRegCVEntry."Object Type" := TaxRegCVEntry."Object Type"::Vendor;

                VendLedgEntry.SetRange(Positive, true);
                ExistEntry := VendLedgEntry.FindFirst();

                DtldVendLedgEntry.Reset();
                DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Initial Entry Positive", "Initial Entry Due Date", "Posting Date");
                DtldVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
                DtldVendLedgEntry.SetRange("Initial Entry Positive", true);
                DtldVendLedgEntry.SetFilter("Posting Date", '..%1', EndDate);
                DtldVendLedgEntry.CalcSums("Amount (LCY)");
                if ExistEntry or (DtldVendLedgEntry."Amount (LCY)" <> 0) then begin
                    TaxRegCVEntry."Register Type" := TaxRegCVEntry."Register Type"::"Debit Balance";
                    TaxRegCVEntry."CV Debit Balance Amnt 1" := DtldVendLedgEntry."Amount (LCY)";
                    DtldVendLedgEntry.SetFilter("Initial Entry Due Date", FiterDueDate45Days90Days);
                    DtldVendLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Debit Balance Amnt 2" := DtldVendLedgEntry."Amount (LCY)";
                    DtldVendLedgEntry.SetFilter("Initial Entry Due Date", FilterDueDate90Days3Years);
                    DtldVendLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Debit Balance Amnt 3" := DtldVendLedgEntry."Amount (LCY)";
                    DtldVendLedgEntry.SetFilter("Initial Entry Due Date", FilterDueDate3YearsDebit);
                    DtldVendLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Debit Balance Amnt 4" := DtldVendLedgEntry."Amount (LCY)";
                    TaxRegCVEntry."CV Debit Balance Amnt 2-4" :=
                      TaxRegCVEntry."CV Debit Balance Amnt 2" +
                      TaxRegCVEntry."CV Debit Balance Amnt 3" +
                      TaxRegCVEntry."CV Debit Balance Amnt 4";
                    TaxRegCVEntry."Entry No." += 1;
                    TaxRegCVEntry.Insert();
                    CVDebitBalance[1] += TaxRegCVEntry."CV Debit Balance Amnt 1";
                    CVDebitBalance[2] += TaxRegCVEntry."CV Debit Balance Amnt 2";
                    CVDebitBalance[3] += TaxRegCVEntry."CV Debit Balance Amnt 3";
                    CVDebitBalance[4] += TaxRegCVEntry."CV Debit Balance Amnt 4";
                end;

                VendLedgEntry.SetRange(Positive, false);
                ExistEntry := VendLedgEntry.FindFirst();

                DtldVendLedgEntry.Reset();
                DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Initial Entry Positive", "Initial Entry Due Date", "Posting Date");
                DtldVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
                DtldVendLedgEntry.SetRange("Initial Entry Positive", false);
                DtldVendLedgEntry.SetFilter("Posting Date", '..%1', EndDate);
                DtldVendLedgEntry.CalcSums("Amount (LCY)");
                if ExistEntry or (DtldVendLedgEntry."Amount (LCY)" <> 0) then begin
                    TaxRegCVEntry."Register Type" := TaxRegCVEntry."Register Type"::"Credit Balance";
                    TaxRegCVEntry."CV Credit Balance Amnt 1" := DtldVendLedgEntry."Amount (LCY)";
                    DtldVendLedgEntry.SetFilter("Initial Entry Due Date", FilterDueDate3YearsCredit);
                    DtldVendLedgEntry.CalcSums("Amount (LCY)");
                    TaxRegCVEntry."CV Credit Balance Amnt 2" := DtldVendLedgEntry."Amount (LCY)";
                    TaxRegCVEntry."Entry No." += 1;
                    TaxRegCVEntry.Insert();
                    CVCreditBalance[1] += TaxRegCVEntry."CV Credit Balance Amnt 1";
                    CVCreditBalance[2] += TaxRegCVEntry."CV Credit Balance Amnt 2";
                end;
            until Vendor.Next() = 0;

        TaxRegAccumulation.Reset();
        if not TaxRegAccumulation.FindLast() then
            TaxRegAccumulation."Entry No." := 0;

        TaxRegAccumulation.Init();
        TaxRegAccumulation."Section Code" := SectionCode;
        TaxRegAccumulation."Starting Date" := StartDate;
        TaxRegAccumulation."Ending Date" := EndDate;

        TaxReg.Reset();
        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register CV Entry");
        TaxRegTemplate.SetRange("Section Code", SectionCode);
        if TaxReg.FindSet() then
            repeat
                TaxRegTemplate.SetRange(Code, TaxReg."No.");
                if TaxRegTemplate.FindSet() then
                    repeat
                        TaxRegAccumulation."Report Line Code" := TaxRegTemplate."Report Line Code";
                        TaxRegAccumulation."Template Line Code" := TaxRegTemplate."Line Code";
                        TaxRegAccumulation."Tax Register No." := TaxRegTemplate.Code;
                        TaxRegAccumulation.Indentation := TaxRegTemplate.Indentation;
                        TaxRegAccumulation.Bold := TaxRegTemplate.Bold;
                        TaxRegAccumulation.Description := TaxRegTemplate.Description;
                        TaxRegAccumulation."Template Line No." := TaxRegTemplate."Line No.";
                        case TaxRegTemplate."Sum Field No." of
                            TaxRegCVEntry.FieldNo("CV Credit Balance Amnt 1"):
                                TaxRegAccumulation.Amount := CVCreditBalance[1];
                            TaxRegCVEntry.FieldNo("CV Credit Balance Amnt 2"):
                                TaxRegAccumulation.Amount := CVCreditBalance[2];
                            TaxRegCVEntry.FieldNo("CV Debit Balance Amnt 1"):
                                TaxRegAccumulation.Amount := CVDebitBalance[1];
                            TaxRegCVEntry.FieldNo("CV Debit Balance Amnt 2"):
                                TaxRegAccumulation.Amount := CVDebitBalance[2];
                            TaxRegCVEntry.FieldNo("CV Debit Balance Amnt 3"):
                                TaxRegAccumulation.Amount := CVDebitBalance[3];
                            TaxRegCVEntry.FieldNo("CV Debit Balance Amnt 4"):
                                TaxRegAccumulation.Amount := CVDebitBalance[4];
                            else
                                TaxRegAccumulation.Amount := 0;
                        end;
                        TaxRegAccumulation."Amount Period" := TaxRegAccumulation.Amount;
                        TaxRegAccumulation."Amount Date Filter" :=
                          TaxRegTermMgt.CalcIntervalDate(
                            TaxRegAccumulation."Starting Date",
                            TaxRegAccumulation."Ending Date",
                            TaxRegTemplate.Period);
                        TaxRegAccumulation."Entry No." += 1;
                        TaxRegAccumulation.Insert();
                    until TaxRegTemplate.Next() = 0;
            until TaxReg.Next() = 0;
    end;
}

