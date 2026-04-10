#pragma warning disable AA0247
report 12463 "Cash Order Journal CO-3"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Order Journal CO-3';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
        {
            DataItemTableView = sorting("Bank Account No.", "Posting Date");

            trigger OnAfterGetRecord()
            var
                NextEntryNo: Integer;
            begin
                if "Debit Amount (LCY)" <> 0 then begin
                    Idx[1] := Idx[1] + 1;
                    NextEntryNo := Idx[1] * 2 - 1;
                end else begin
                    Idx[2] := Idx[2] + 1;
                    NextEntryNo := Idx[2] * 2;
                end;
                TempAmt := "Bank Account Ledger Entry";
                TempAmt."Entry No." := NextEntryNo;
                TempAmt.Insert();
            end;

            trigger OnPreDataItem()
            begin
                if BankAccount = '' then
                    Error(CashCodeErr);

                Year := Date2DMY(EndingDate, 3);

                SetRange("Bank Account No.", BankAccount);
                SetRange("Posting Date", StartingDate, EndingDate);

                Clear(Idx);
                TempAmt.DeleteAll();

                FillTitle();
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            begin
                I := I + 1;
                BankLedgEntry[1].Init();
                BankLedgEntry[2].Init();
                if I <= Idx[1] then begin
                    TempAmt.Get(I * 2 - 1);
                    BankLedgEntry[1] := TempAmt;
                end;
                if I <= Idx[2] then begin
                    TempAmt.Get(I * 2);
                    BankLedgEntry[2] := TempAmt;
                end;

                FillBody();
            end;

            trigger OnPreDataItem()
            begin
                if Idx[1] > Idx[2] then
                    K := Idx[1]
                else
                    K := Idx[2];

                SetRange(Number, 1, K);
                I := 0;
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
                    field(BankAccount; BankAccount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Account No.';
                        LookupPageID = "Bank Account List";
                        TableRelation = "Bank Account" where("Account Type" = const("Cash Account"));
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';

                        trigger OnValidate()
                        begin
                            StartingDateOnAfterValidate();
                        end;
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(EmployeeCode; EmployeeCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee No.';
                        TableRelation = Employee;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            StartingDate := CalcDate('<-1M-CM>', WorkDate());
            EndingDate := CalcDate('<-1M+CM>', WorkDate());
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelReportBuilderMgr.ExportData();
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        InitReportTemplate();
    end;

    var
        CompanyInfo: Record "Company Information";
        TempAmt: Record "Bank Account Ledger Entry" temporary;
        BankLedgEntry: array[2] of Record "Bank Account Ledger Entry" temporary;
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        EmployeeCode: Code[20];
        StartingDate: Date;
        EndingDate: Date;
        BankAccount: Code[20];
        CashCodeErr: Label 'Select the Cash Account No.';
        I: Integer;
        K: Integer;
        Idx: array[2] of Integer;
#pragma warning disable AA0470
        PageTxt: Label 'Page %1';
#pragma warning restore AA0470
        Year: Integer;

    local procedure StartingDateOnAfterValidate()
    begin
        EndingDate := CalcDate('<+CM>', StartingDate);
    end;

    local procedure InitReportTemplate()
    var
        GeneralLedgSetup: Record "General Ledger Setup";
        SheetName: Text;
    begin
        SheetName := 'Sheet1';
        GeneralLedgSetup.Get();
        GeneralLedgSetup.TestField("Cash Order KO3 Template Code");
        ExcelReportBuilderMgr.InitTemplate(GeneralLedgSetup."Cash Order KO3 Template Code");
        ExcelReportBuilderMgr.SetSheet(SheetName);
    end;

    local procedure FillTitle()
    begin
        ExcelReportBuilderMgr.AddSection('TITLEPAGE');

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', CompanyInfo.Name);
        ExcelReportBuilderMgr.AddDataToSection('CodeOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('Year', Format(Year));
        ExcelReportBuilderMgr.AddDataToSection('PersonTitle', StdRepMgt.GetEmpPosition(EmployeeCode));
        ExcelReportBuilderMgr.AddDataToSection('PersonName', StdRepMgt.GetEmpName(EmployeeCode));

        FillHeader();
    end;

    local procedure FillTransfooter()
    begin
        ExcelReportBuilderMgr.AddDataToSection('CompanyNamePage', CompanyInfo.Name);
        ExcelReportBuilderMgr.AddDataToSection('PageNum', StrSubstNo(PageTxt, ExcelReportBuilderMgr.GetLastPageNo()));
    end;

    local procedure FillHeader()
    begin
        if not ExcelReportBuilderMgr.TryAddSection('PAGEHEADER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('PAGEHEADER');
        end;

        FillTransfooter();
    end;

    local procedure FillBody()
    var
        LocMgt: Codeunit "Localisation Management";
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('PAGEHEADER');
            FillTransfooter();
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        ExcelReportBuilderMgr.AddDataToSection('PKOTransDate', LocMgt.Date2Text(BankLedgEntry[1]."Posting Date"));
        ExcelReportBuilderMgr.AddDataToSection('PKONum', BankLedgEntry[1]."Document No.");
        ExcelReportBuilderMgr.AddDataToSection(
          'PKOSum',
          StdRepMgt.FormatReportValue(BankLedgEntry[1]."Debit Amount (LCY)" - BankLedgEntry[1]."Credit Amount (LCY)", 2));
        ExcelReportBuilderMgr.AddDataToSection('PKONotes', BankLedgEntry[1].Description);
        ExcelReportBuilderMgr.AddDataToSection('RKOTransDate', LocMgt.Date2Text(BankLedgEntry[2]."Posting Date"));
        ExcelReportBuilderMgr.AddDataToSection('RKONum', BankLedgEntry[2]."Document No.");
        ExcelReportBuilderMgr.AddDataToSection(
          'RKOSum',
          StdRepMgt.FormatReportValue(BankLedgEntry[2]."Credit Amount" - BankLedgEntry[2]."Debit Amount", 2));
        ExcelReportBuilderMgr.AddDataToSection('RKONotes', BankLedgEntry[2].Description);
    end;
}

