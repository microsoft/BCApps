#pragma warning disable AA0247
codeunit 26581 AccSchedExtensionManagement
{

    trigger OnRun()
    begin
    end;

    var
        AccSchedLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        AccSchedExtension: Record "Acc. Schedule Extension";
        GLSetup: Record "General Ledger Setup";
        ReportPeriod: Record Date;
        AccSchedManagement: Codeunit AccSchedManagement;
#pragma warning disable AA0074
        Text001: Label 'BD';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'ED';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Invalid value for Date Filter = %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        StartDate: Date;
        EndDate: Date;

    [Scope('OnPrem')]
    procedure CalcCustomFunc(var NewAccSchedLine: Record "Acc. Schedule Line"; NewColumnLayout: Record "Column Layout"; NewStartDate: Date; NewEndDate: Date) Value: Decimal
    begin
        AccSchedLine.Copy(NewAccSchedLine);
        ColumnLayout := NewColumnLayout;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        Value := 0;
        GLSetup.Get();
        AccSchedManagement.SetDateParameters(StartDate, EndDate);
        if AccSchedExtension.Get(NewAccSchedLine.Totaling) then
            case AccSchedExtension."Source Table" of
                AccSchedExtension."Source Table"::"VAT Entry":
                    Value := GetVATEntryValue();
                AccSchedExtension."Source Table"::"Value Entry":
                    Value := GetValueEntry();
                AccSchedExtension."Source Table"::"Customer Entry":
                    Value := GetCustEntryValue();
                AccSchedExtension."Source Table"::"Vendor Entry":
                    Value := GetVendEntryValue();
            end;
    end;

    [Scope('OnPrem')]
    procedure SetAccSchedLine(var NewAccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.Copy(NewAccSchedLine);
    end;

    [Scope('OnPrem')]
    procedure SetReportPeriod(var NewReportPeriod: Record Date)
    begin
        ReportPeriod.Copy(NewReportPeriod);
    end;

    [Scope('OnPrem')]
    procedure CalcDateFormula(DateFormula: Text[250]): Date
    begin
        // ED or BD formulas proccessing
        // ED or BD have to be in the begining of the formula

        if DateFormula = '' then
            exit(0D);

        case CopyStr(DateFormula, 1, 2) of
            Text001:
                exit(CalcDate(CopyStr(DateFormula, 3), StartDate));
            Text002:
                exit(CalcDate(CopyStr(DateFormula, 3), EndDate));
        end;

        Error(Text003, DateFormula);
    end;

    [Scope('OnPrem')]
    procedure GetDateFilter(DateFilter: Text[250]): Text[250]
    var
        Position: Integer;
        LeftFormula: Text[250];
        RightFormula: Text[250];
    begin
        if DateFilter = '' then
            exit(DateFilter);

        Position := StrPos(DateFilter, '..');
        if Position > 0 then begin
            LeftFormula := CopyStr(DateFilter, 1, Position - 1);
            RightFormula := CopyStr(DateFilter, Position + 2);
            exit(Format(CalcDateFormula(LeftFormula)) + '..' + Format(CalcDateFormula(RightFormula)));
        end;

        case DateFilter of
            Text001:
                exit(Format(StartDate));
            Text002:
                exit(Format(EndDate));
            else
                Error(Text003, DateFilter);
        end;

        exit(DateFilter);
    end;

    [Scope('OnPrem')]
    procedure SetCustLedgEntryFilters(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if AccSchedExtension."Posting Date Filter" <> '' then
            CustLedgerEntry.SetFilter("Posting Date",
              GetDateFilter(AccSchedExtension."Posting Date Filter"))
        else
            CustLedgerEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        CustLedgerEntry.CopyFilter("Posting Date", CustLedgerEntry."Date Filter");

        if NetChangeFilter(CustLedgerEntry.GetFilter("Posting Date")) then
            CustLedgerEntry.SetRange("Posting Date", 0D);

        CustLedgerEntry.SetFilter("Due Date", GetDueDateFilter());
        if AccSchedExtension."Document Type Filter" <> '' then
            CustLedgerEntry.SetFilter("Document Type", AccSchedExtension."Document Type Filter");
        if AccSchedExtension."Posting Group Filter" <> '' then
            CustLedgerEntry.SetFilter("Customer Posting Group", AccSchedExtension."Posting Group Filter");
        case AccSchedExtension."Prepayment Filter" of
            AccSchedExtension."Prepayment Filter"::Yes:
                CustLedgerEntry.SetRange(Prepayment, true);
            AccSchedExtension."Prepayment Filter"::No:
                CustLedgerEntry.SetRange(Prepayment, false);
        end;
        case AccSchedExtension."Amount Sign" of
            AccSchedExtension."Amount Sign"::Positive:
                CustLedgerEntry.SetRange(Positive, true);
            AccSchedExtension."Amount Sign"::Negative:
                CustLedgerEntry.SetRange(Positive, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDtldCustLedgEntryFilters(var DtldCustLedgerEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        if AccSchedExtension."Posting Date Filter" <> '' then
            DtldCustLedgerEntry.SetFilter("Initial Entry Posting Date",
              GetDateFilter(AccSchedExtension."Posting Date Filter"))
        else
            DtldCustLedgerEntry.SetFilter(
              "Initial Entry Posting Date",
              AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        DtldCustLedgerEntry.CopyFilter("Initial Entry Posting Date", DtldCustLedgerEntry."Posting Date");

        if NetChangeFilter(DtldCustLedgerEntry.GetFilter("Initial Entry Posting Date")) then
            DtldCustLedgerEntry.SetRange("Initial Entry Posting Date", 0D);

        DtldCustLedgerEntry.SetFilter("Initial Entry Due Date", GetDueDateFilter());
        DtldCustLedgerEntry.SetRange("Prepmt. Diff. in TA", false);
        if AccSchedExtension."Document Type Filter" <> '' then
            DtldCustLedgerEntry.SetFilter("Document Type", AccSchedExtension."Document Type Filter");
        if AccSchedExtension."Posting Group Filter" <> '' then
            DtldCustLedgerEntry.SetFilter("Customer Posting Group", AccSchedExtension."Posting Group Filter");
        case AccSchedExtension."Prepayment Filter" of
            AccSchedExtension."Prepayment Filter"::Yes:
                DtldCustLedgerEntry.SetRange(Prepayment, true);
            AccSchedExtension."Prepayment Filter"::No:
                DtldCustLedgerEntry.SetRange(Prepayment, false);
        end;
        case AccSchedExtension."Amount Sign" of
            AccSchedExtension."Amount Sign"::Positive:
                DtldCustLedgerEntry.SetRange("Initial Entry Positive", true);
            AccSchedExtension."Amount Sign"::Negative:
                DtldCustLedgerEntry.SetRange("Initial Entry Positive", false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVendLedgEntryFilters(var VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if AccSchedExtension."Posting Date Filter" <> '' then
            VendLedgerEntry.SetFilter("Posting Date",
              GetDateFilter(AccSchedExtension."Posting Date Filter"))
        else
            VendLedgerEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        VendLedgerEntry.CopyFilter("Posting Date", VendLedgerEntry."Date Filter");

        if NetChangeFilter(VendLedgerEntry.GetFilter("Posting Date")) then
            VendLedgerEntry.SetRange("Posting Date", 0D);

        VendLedgerEntry.SetFilter("Due Date", GetDueDateFilter());
        if AccSchedExtension."Document Type Filter" <> '' then
            VendLedgerEntry.SetFilter("Document Type", AccSchedExtension."Document Type Filter");
        if AccSchedExtension."Posting Group Filter" <> '' then
            VendLedgerEntry.SetFilter("Vendor Posting Group", AccSchedExtension."Posting Group Filter");
        case AccSchedExtension."Prepayment Filter" of
            AccSchedExtension."Prepayment Filter"::Yes:
                VendLedgerEntry.SetRange(Prepayment, true);
            AccSchedExtension."Prepayment Filter"::No:
                VendLedgerEntry.SetRange(Prepayment, false);
        end;
        case AccSchedExtension."Amount Sign" of
            AccSchedExtension."Amount Sign"::Positive:
                VendLedgerEntry.SetRange(Positive, true);
            AccSchedExtension."Amount Sign"::Negative:
                VendLedgerEntry.SetRange(Positive, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDtldVendLedgEntryFilters(var DtldVendLedgerEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        if AccSchedExtension."Posting Date Filter" <> '' then
            DtldVendLedgerEntry.SetFilter("Initial Entry Posting Date",
              GetDateFilter(AccSchedExtension."Posting Date Filter"))
        else
            DtldVendLedgerEntry.SetFilter(
              "Initial Entry Posting Date",
              AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        DtldVendLedgerEntry.CopyFilter("Initial Entry Posting Date", DtldVendLedgerEntry."Posting Date");

        if NetChangeFilter(DtldVendLedgerEntry.GetFilter("Initial Entry Posting Date")) then
            DtldVendLedgerEntry.SetRange("Initial Entry Posting Date", 0D);

        DtldVendLedgerEntry.SetFilter("Initial Entry Due Date", GetDueDateFilter());
        DtldVendLedgerEntry.SetRange("Prepmt. Diff. in TA", false);
        if AccSchedExtension."Document Type Filter" <> '' then
            DtldVendLedgerEntry.SetFilter("Document Type", AccSchedExtension."Document Type Filter");
        if AccSchedExtension."Posting Group Filter" <> '' then
            DtldVendLedgerEntry.SetFilter("Vendor Posting Group", AccSchedExtension."Posting Group Filter");
        case AccSchedExtension."Prepayment Filter" of
            AccSchedExtension."Prepayment Filter"::Yes:
                DtldVendLedgerEntry.SetRange(Prepayment, true);
            AccSchedExtension."Prepayment Filter"::No:
                DtldVendLedgerEntry.SetRange(Prepayment, false);
        end;
        case AccSchedExtension."Amount Sign" of
            AccSchedExtension."Amount Sign"::Positive:
                DtldVendLedgerEntry.SetRange("Initial Entry Positive", true);
            AccSchedExtension."Amount Sign"::Negative:
                DtldVendLedgerEntry.SetRange("Initial Entry Positive", false);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetVATLedgEntryFilters(var VATEntry: Record "VAT Entry")
    begin
        case AccSchedExtension."VAT Entry Type" of
            AccSchedExtension."VAT Entry Type"::Purchase:
                VATEntry.SetRange(Type, VATEntry.Type::Purchase);
            AccSchedExtension."VAT Entry Type"::Sale:
                VATEntry.SetRange(Type, VATEntry.Type::Sale);
        end;
        case AccSchedExtension."Prepayment Filter" of
            AccSchedExtension."Prepayment Filter"::Yes:
                VATEntry.SetRange(Prepayment, true);
            AccSchedExtension."Prepayment Filter"::No:
                VATEntry.SetRange(Prepayment, false);
        end;
        VATEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        VATEntry.SetFilter("VAT Bus. Posting Group", AccSchedExtension."VAT Bus. Post. Group Filter");
        VATEntry.SetFilter("VAT Prod. Posting Group", AccSchedExtension."VAT Prod. Post. Group Filter");
        VATEntry.SetFilter("Gen. Bus. Posting Group", AccSchedExtension."Gen. Bus. Post. Group Filter");
        VATEntry.SetFilter("Gen. Prod. Posting Group", AccSchedExtension."Gen. Prod. Post. Group Filter");
        if AccSchedExtension."Object Type Filter" <> AccSchedExtension."Object Type Filter"::" " then
            VATEntry.SetRange("Object Type", AccSchedExtension."Object Type Filter" - 1);
        VATEntry.SetFilter("Object No.", AccSchedExtension."Object No. Filter");
        if AccSchedExtension."VAT Allocation Type Filter" <> AccSchedExtension."VAT Allocation Type Filter"::" " then
            VATEntry.SetRange("VAT Allocation Type", AccSchedExtension."VAT Allocation Type Filter" - 1);
    end;

    [Scope('OnPrem')]
    procedure SetValueLedgEntryFilters(var ValueEntry: Record "Value Entry")
    begin
        ValueEntry.SetFilter("Location Code", AccSchedExtension."Location Filter");
        ValueEntry.SetFilter("Item Charge No.", AccSchedExtension."Item Charge No. Filter");
        ValueEntry.SetFilter("Posting Date", AccSchedManagement.GetPostingDateFilter(AccSchedLine, ColumnLayout));
        ValueEntry.SetFilter("Inventory Posting Group", AccSchedExtension."Inventory Posting Group Filter");
        if AccSchedExtension."Value Entry Type Filter" <> AccSchedExtension."Value Entry Type Filter"::" " then
            ValueEntry.SetRange("Entry Type", AccSchedExtension."Value Entry Type Filter" - 1);
        case AccSchedExtension."Amount Sign" of
            AccSchedExtension."Amount Sign"::Positive:
                ValueEntry.SetRange(Positive, true);
            AccSchedExtension."Amount Sign"::Negative:
                ValueEntry.SetRange(Positive, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetVATEntryValue() Result: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Reset();
        VATEntry.SetCurrentKey(
          Type,
          "Posting Date",
          "VAT Bus. Posting Group",
          "VAT Prod. Posting Group",
          "Gen. Bus. Posting Group",
          "Gen. Prod. Posting Group",
          "Object Type",
          "Object No.",
          "VAT Allocation Type",
          Prepayment);

        SetVATLedgEntryFilters(VATEntry);
        VATEntry.CalcSums(
          Base,
          Amount,
          "Unrealized Amount",
          "Unrealized Base",
          "Remaining Unrealized Amount",
          "Remaining Unrealized Base");

        case AccSchedExtension."VAT Type" of
            AccSchedExtension."VAT Type"::Realized:
                case AccSchedExtension."VAT Amount Type" of
                    AccSchedExtension."VAT Amount Type"::Base:
                        Result := VATEntry.Base;
                    AccSchedExtension."VAT Amount Type"::Amount:
                        Result := VATEntry.Amount;
                    AccSchedExtension."VAT Amount Type"::Total:
                        Result := VATEntry.Base + VATEntry.Amount;
                end;
            AccSchedExtension."VAT Type"::Unrealized:
                case AccSchedExtension."VAT Amount Type" of
                    AccSchedExtension."VAT Amount Type"::Base:
                        Result := VATEntry."Unrealized Base";
                    AccSchedExtension."VAT Amount Type"::Amount:
                        Result := VATEntry."Unrealized Amount";
                    AccSchedExtension."VAT Amount Type"::Total:
                        Result := VATEntry."Unrealized Base" + VATEntry."Unrealized Amount";
                end;
            AccSchedExtension."VAT Type"::"Remaining Unrealized":
                case AccSchedExtension."VAT Amount Type" of
                    AccSchedExtension."VAT Amount Type"::Base:
                        Result := VATEntry."Remaining Unrealized Base";
                    AccSchedExtension."VAT Amount Type"::Amount:
                        Result := VATEntry."Remaining Unrealized Amount";
                    AccSchedExtension."VAT Amount Type"::Total:
                        Result := VATEntry."Remaining Unrealized Base" + VATEntry."Remaining Unrealized Amount";
                end;
        end;

        if AccSchedExtension."Reverse Sign" then
            Result := -1 * Result;
    end;

    [Scope('OnPrem')]
    procedure GetValueEntry() Result: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Posting Date", "Location Code", "Entry Type", "Inventory Posting Group", "Item Charge No.", Positive);
        SetValueLedgEntryFilters(ValueEntry);
        ValueEntry.CalcSums(
          "Cost Posted to G/L",
          "Sales Amount (Expected)",
          "Sales Amount (Actual)",
          "Cost Amount (Expected)",
          "Cost Amount (Actual)",
          "Cost Amount (Non-Invtbl.)",
          "Purchase Amount (Actual)",
          "Purchase Amount (Expected)");

        case AccSchedExtension."Value Entry Amount Type" of
            AccSchedExtension."Value Entry Amount Type"::"Cost Posted to G/L":
                Result := ValueEntry."Cost Posted to G/L";
            AccSchedExtension."Value Entry Amount Type"::"Sales Amount (Expected)":
                Result := ValueEntry."Sales Amount (Expected)";
            AccSchedExtension."Value Entry Amount Type"::"Sales Amount (Actual)":
                Result := ValueEntry."Sales Amount (Actual)";
            AccSchedExtension."Value Entry Amount Type"::"Cost Amount (Expected)":
                Result := ValueEntry."Cost Amount (Expected)";
            AccSchedExtension."Value Entry Amount Type"::"Cost Amount (Actual)":
                Result := ValueEntry."Cost Amount (Actual)";
            AccSchedExtension."Value Entry Amount Type"::"Cost Amount (Non-Invtbl.)":
                Result := ValueEntry."Cost Amount (Non-Invtbl.)";
            AccSchedExtension."Value Entry Amount Type"::"Purchase Amount (Actual)":
                Result := ValueEntry."Purchase Amount (Actual)";
            AccSchedExtension."Value Entry Amount Type"::"Purchase Amount (Expected)":
                Result := ValueEntry."Purchase Amount (Expected)";
        end;

        if AccSchedExtension."Reverse Sign" then
            Result := -1 * Result;
    end;

    [Scope('OnPrem')]
    procedure GetCustEntryValue() Amount: Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetCurrentKey(
          "Posting Date", "Initial Entry Posting Date", "Document Type",
          "Initial Entry Due Date", "Customer Posting Group", Prepayment, "Initial Entry Positive");
        SetDtldCustLedgEntryFilters(DetailedCustLedgEntry);
        DetailedCustLedgEntry.CalcSums("Amount (LCY)");
        Amount := DetailedCustLedgEntry."Amount (LCY)";

        if AccSchedExtension."Reverse Sign" then
            Amount := -Amount;
    end;

    [Scope('OnPrem')]
    procedure GetVendEntryValue() Amount: Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetCurrentKey(
          "Posting Date", "Initial Entry Posting Date", "Document Type",
          "Initial Entry Due Date", "Vendor Posting Group", Prepayment, "Initial Entry Positive");
        SetDtldVendLedgEntryFilters(DetailedVendorLedgEntry);
        DetailedVendorLedgEntry.CalcSums("Amount (LCY)");
        Amount := DetailedVendorLedgEntry."Amount (LCY)";

        if AccSchedExtension."Reverse Sign" then
            Amount := -Amount;
    end;

    [Scope('OnPrem')]
    procedure DrillDownAmount(var NewAccSchedLine: Record "Acc. Schedule Line"; var NewColumnLayout: Record "Column Layout"; ExtensionCode: Code[20]; NewStartDate: Date; NewEndDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
    begin
        AccSchedLine.Copy(NewAccSchedLine);
        ColumnLayout := NewColumnLayout;
        AccSchedExtension.Get(ExtensionCode);
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        GLSetup.Get();
        AccSchedManagement.SetDateParameters(StartDate, EndDate);
        case AccSchedExtension."Source Table" of
            AccSchedExtension."Source Table"::"VAT Entry":
                begin
                    SetVATLedgEntryFilters(VATEntry);
                    PAGE.Run(0, VATEntry);
                end;
            AccSchedExtension."Source Table"::"Customer Entry":
                begin
                    SetCustLedgEntryFilters(CustLedgerEntry);
                    PAGE.Run(0, CustLedgerEntry);
                end;
            AccSchedExtension."Source Table"::"Vendor Entry":
                begin
                    SetVendLedgEntryFilters(VendLedgerEntry);
                    PAGE.Run(0, VendLedgerEntry);
                end;
            AccSchedExtension."Source Table"::"Value Entry":
                begin
                    SetValueLedgEntryFilters(ValueEntry);
                    PAGE.Run(0, ValueEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDueDateFilter(): Text[100]
    var
        DateFormula: DateFormula;
        Period: Text[30];
        ShortTermDate: Date;
        ClosDate: Boolean;
    begin
        GLSetup.TestField("Short-Term Due Period");
        case ColumnLayout."Column Type" of
            ColumnLayout."Column Type"::"Beginning Balance":
                begin
                    ClosDate := true;
                    Evaluate(DateFormula, '<-1D>');
                    Period := Text001 + Format(DateFormula);
                end;
            ColumnLayout."Column Type"::"Balance at Date":
                Period := Text002;
            else
                exit('');
        end;
        case AccSchedExtension."Liability Type" of
            AccSchedExtension."Liability Type"::" ":
                exit(GetDateFilter(AccSchedExtension."Due Date Filter"));
            AccSchedExtension."Liability Type"::"Short Term":
                begin
                    ShortTermDate := CalcDateFormula(Period + Format(GLSetup."Short-Term Due Period"));
                    if ClosDate then
                        ShortTermDate := ClosingDate(ShortTermDate);
                    exit('..' + Format(ShortTermDate));
                end;
            AccSchedExtension."Liability Type"::"Long Term":
                begin
                    Evaluate(DateFormula, '<+1D>');
                    exit(Format(CalcDateFormula(Period + Format(GLSetup."Short-Term Due Period") + Format(DateFormula))) + '..');
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckDateFilter(DueDateFilter: Code[20])
    begin
        GLSetup.Get();
        StartDate := Today;
        EndDate := Today;
        GetDateFilter(DueDateFilter);
    end;

    [Scope('OnPrem')]
    procedure NetChangeFilter(DateFilter: Text[30]): Boolean
    begin
        exit(DateFilter[1] in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']);
    end;
}

