#pragma warning disable AA0247
page 12403 "G/L Corresp. General Ledger"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Ledger - Correspondence';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "G/L Correspondence Entry";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                field("Date Filter"; DateFilter)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        GLAccount.SetFilter("Date Filter", DateFilter);
                        DateFilter := GLAccount.GetFilter("Date Filter");
                        ModifyView();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if PeriodType = PeriodType::"Accounting Period" then
                            FindUserPeriod('')
                        else
                            FindPeriod('');
                        ModifyView();
                    end;
                }
                field("G/L Account Filter"; GLAccountFilter)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "G/L Account"."No.";

                    trigger OnValidate()
                    begin
                        UpdateView();
                    end;
                }
                field("Business Unit Filter"; BusinessUnitFilter)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Business Unit";

                    trigger OnValidate()
                    begin
                        ModifyView();
                    end;
                }
                field("Global Dimension 1 Filter"; GlobalDimension1Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,3,1';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(GLAccount.LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ModifyView();
                    end;
                }
                field("Global Dimension 2 Filter"; GlobalDimension2Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,3,2';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(GLAccount.LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        ModifyView();
                    end;
                }
                field("Switch Debit/Credit"; SwitchAccounts)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        SetColumnNames();
                        SwitchGLCorr();
                    end;
                }
            }
            repeater(Control6)
            {
                Editable = false;
                IndentationColumn = Rec."Transaction No.";
                ShowAsTree = true;
                ShowCaption = false;
                field("GLAccount.""No."""; GLAccount."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the account that the entry has been posted to.';
                }
                field("GLAccount.Name"; GLAccount.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Name';
                    Style = Strong;
                    StyleExpr = IsTotaling;
                    ToolTip = 'Specifies the name of the account that the entry has been posted to.';
                }
                field("BalanceAmounts[BalanceType::StartBal]"; BalanceAmounts[BalanceType::StartBal])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Starting Balance';
                    ToolTip = 'Specifies the balance at the beginning of the period.';

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(Show::BeginPeriod);
                    end;
                }
                field(StartingBalanceDebit; BalanceAmounts[BalanceType::StartBalDebit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Starting Balance Debit';
                    ToolTip = 'Specifies the balance for debits at the beginning of the period.';
                    Visible = false;
                }
                field(StartingBalanceCredit; BalanceAmounts[BalanceType::StartBalCredit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Starting Balance Credit';
                    ToolTip = 'Specifies the balance for credits at the beginning of the period.';
                    Visible = false;
                }
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = DebitAccNoColumnName;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the debit account number associated with this correspondence entry.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = CreditAccNoColumnName;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the credit account number associated with this correspondence entry.';
                }
                field(DebitAmount; DebitAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = DebitAmountColumnName;
                    Caption = 'Debit Amount';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the debit amount for the period on the line.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDebitCredit(true);
                    end;
                }
                field(CreditAmount; CreditAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = CreditAmountColumnName;
                    Caption = 'Credit Amount';
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the credit amount for the period on the line.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDebitCredit(false);
                    end;
                }
                field(EndingBalance; BalanceAmounts[BalanceType::EndBal])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Ending Balance';
                    ToolTip = 'Specifies the balance at the end of the period.';

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(Show::EndPeriod);
                    end;
                }
                field(EndingBalanceDebit; BalanceAmounts[BalanceType::EndBalDebit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Ending Balance Debit';
                    ToolTip = 'Specifies the balance for debits at the end of the period.';
                    Visible = false;
                }
                field(EndingBalanceCredit; BalanceAmounts[BalanceType::EndBalCredit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Ending Balance Credit';
                    ToolTip = 'Specifies the balance for credits at the end of the period.';
                    Visible = false;
                }
                field("GLAccount.""Net Change"""; GLAccount."Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Net Change';
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';

                    trigger OnDrillDown()
                    begin
                        DrillDownGLAccount(DateFilter, false, true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Sho&w")
            {
                Caption = 'Sho&w';
                Image = "Action";
            }
            action("C&ard")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'C&ard';
                Image = Card;
                RunObject = Page "G/L Account Card";
                RunPageLink = "No." = field("Debit Source No.");
                ShortCutKey = 'Shift+F7';
            }
            action("Ledger E&ntries")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Ledger E&ntries';
                Image = GeneralLedger;
                RunObject = Page "General Ledger Entries";
                RunPageLink = "G/L Account No." = field("Debit Source No.");
                ShortCutKey = 'Ctrl+F7';
                ToolTip = 'View the history of transactions that have been posted for the selected record.';
            }
            action("Co&mments")
            {
                Caption = 'Co&mments';
                Image = ViewComments;
                RunObject = Page "Comment Sheet";
                RunPageLink = "Table Name" = const("G/L Account"),
                              "No." = field("Debit Source No.");
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousSet;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                    ModifyView();
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextSet;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                    ModifyView();
                end;
            }
            separator(Action23)
            {
            }
            action(ForceRecalculation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Force Recalculation';
                Image = Refresh;

                trigger OnAction()
                begin
                    ForceRecalculate();
                end;
            }
        }
        area(processing)
        {
            group("B&alance")
            {
                Caption = 'B&alance';
                action("G/L Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Balance';
                    Image = GLAccountBalance;
                    RunObject = Page "G/L Account Balance";
                    RunPageLink = "No." = field("Debit Source No."),
                                  "Global Dimension 1 Filter" = field("Debit Global Dimension 1 Code"),
                                  "Global Dimension 2 Filter" = field("Debit Global Dimension 2 Code");
                    ToolTip = 'View a summary of the debit and credit balances for different time periods, for the account that you select in the chart of accounts.';

                    trigger OnAction()
                    begin
                        GLAccMakeFilters();
                        PAGE.RunModal(PAGE::"G/L Account Balance", GLAccount);
                    end;
                }
                action("G/L Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Balance';
                    Image = GLBalance;
                    RunObject = Page "G/L Balance";
                    ToolTip = 'View a summary of the debit and credit balances related to correspondence.';
                }
                action("G/L Balance by Dimension")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Balance by Dimension';
                    Image = GLBalanceDimension;
                    RunObject = Page "G/L Balance by Dimension";
                    ToolTip = 'View a summary of the debit and credit balances by dimensions for the current account.';
                }
                action("G/L Account Balance/Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Balance/Budget';
                    Image = GLAccountBalance;
                    RunObject = Page "G/L Account Balance/Budget";
                    RunPageLink = "No." = field("Debit Source No.");
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';

                    trigger OnAction()
                    begin
                        GLAccMakeFilters();
                        PAGE.RunModal(PAGE::"G/L Account Balance/Budget", GLAccount);
                    end;
                }
                action("G/L Balance/Budget")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Balance/Budget';
                    Image = GLBalance;
                    RunObject = Page "G/L Balance/Budget";
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';
                }
                action("Customer G/L Turnover")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer G/L Turnover';
                    Image = CustomerLedger;

                    trigger OnAction()
                    var
                        Customer: Record Customer;
                    begin
                        Customer.SetFilter("G/L Account Filter", Rec."Debit Source No.");
                        Customer.SetFilter("Date Filter", DateFilter);
                        PAGE.RunModal(PAGE::"Customer G/L Turnover", Customer);
                    end;
                }
                action("Vendor G/L Turnover")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor G/L Turnover';
                    Image = VendorLedger;
                    ToolTip = 'Analyze vendors'' turnover and account balances.';

                    trigger OnAction()
                    var
                        Vendor: Record Vendor;
                    begin
                        Vendor.SetFilter("G/L Account Filter", Rec."Debit Source No.");
                        Vendor.SetFilter("Date Filter", DateFilter);
                        PAGE.RunModal(PAGE::"Vendor G/L Turnover", Vendor);
                    end;
                }
            }
            group("P&rint")
            {
                Caption = 'P&rint';
                action("General Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Ledger';
                    Image = "Report";
                    ToolTip = 'Open the general ledger.';

                    trigger OnAction()
                    var
                        GLAcc: Record "G/L Account";
                    begin
                        GLAcc.Reset();
                        GLAcc.SetRange("No.", Rec."Debit Source No.");
                        REPORT.RunModal(REPORT::"G/L Corresp. General Ledger", true, false, GLAcc);
                    end;
                }
                action("G/L Account Turnover")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Turnover';
                    Image = "Report";
                    RunObject = Report "G/L Account Turnover";
                    ToolTip = 'View the general ledger account summary. You can use this information to verify if the entries are correct on general ledger accounts.';
                }
                action("G/L Account Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Card';
                    Image = "Report";
                    ToolTip = 'View or edit details for a general ledger account.';

                    trigger OnAction()
                    var
                        GLAcc: Record "G/L Account";
                    begin
                        GLAcc.Reset();
                        GLAcc.SetRange("No.", Rec."Debit Source No.");
                        REPORT.RunModal(REPORT::"G/L Account Card", true, false, GLAcc);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("C&ard_Promoted"; "C&ard")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(PreviousPeriod_Promoted; PreviousPeriod)
                {
                }
                actionref(NextPeriod_Promoted; NextPeriod)
                {
                }
                actionref(ForceRecalculation_Promoted; ForceRecalculation)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("General Ledger_Promoted"; "General Ledger")
                {
                }
                actionref("G/L Account Turnover_Promoted"; "G/L Account Turnover")
                {
                }
                actionref("G/L Account Card_Promoted"; "G/L Account Card")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Clear(GLAccount);
        Clear(BalanceAmounts);

        DebitAmount := CalcDebitCreditAmount(true);
        CreditAmount := CalcDebitCreditAmount(false);

        if Rec."Transaction No." = 0 then begin
            GLAccount.Get(Rec."Debit Source No.");
            GLAccMakeFilters();
            GLAccount.CalculateAmounts(BalanceAmounts);
            GLAccount.CalcFields("Net Change");
        end;

        Emphasize := EmphasizeLine();
        IsTotaling := GLAccount."Account Type" <> GLAccount."Account Type"::Posting;
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        if PeriodType = PeriodType::"Accounting Period" then
            FindUserPeriod('')
        else
            FindPeriod('');
        SetColumnNames();
        CreateView();
        ModifyView();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        DateFilter: Text;
        DebitAccNoColumnName: Text;
        CreditAccNoColumnName: Text;
        DebitAmountColumnName: Text;
        CreditAmountColumnName: Text;
        GLAccountFilter: Code[250];
        BusinessUnitFilter: Code[250];
        GlobalDimension1Filter: Code[250];
        GlobalDimension2Filter: Code[250];
        BalanceAmounts: array[7] of Decimal;
        DebitAmount: Decimal;
        CreditAmount: Decimal;
        PeriodType: Enum "Analysis Period Type";
        Show: Option Debit,Credit,ACYDebet,ACYCredit,BeginPeriod,ACYBeginPeriod,EndPeriod;
        BalanceType: Option ,StartBal,StartBalACY,StartBalCredit,StartBalDebit,EndBalCredit,EndBalDebit,EndBal;
        SwitchAccounts: Boolean;
        Emphasize: Boolean;
        IsTotaling: Boolean;
#pragma warning disable AA0074
        DebitAccountNoCap: Label 'Debit Account No.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        CreditAccountNoCap: Label 'Credit Account No.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        DebitAmountCap: Label 'Debit Amount';
#pragma warning restore AA0074
#pragma warning disable AA0074
        CreditAmountCap: Label 'Credit Amount';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CreateView()
    var
        GLAcc: Record "G/L Account";
        GLCorr: Record "G/L Correspondence";
        EntryNo: Integer;
    begin
        GLAcc.FindSet();
        repeat
            EntryNo += 1;
            InsertRec('', '', GLAcc."No.", EntryNo, 0, false);

            GLCorr.Reset();
            if GLAcc.Totaling = '' then
                GLCorr.SetRange("Debit Account No.", GLAcc."No.")
            else
                GLCorr.SetFilter("Debit Account No.", GLAcc.Totaling);
            if GLCorr.FindSet() then
                repeat
                    EntryNo += 1;
                    InsertRec(GLCorr."Debit Account No.", GLCorr."Credit Account No.", GLAcc."No.", EntryNo, 1, true);
                until GLCorr.Next() = 0;

            GLCorr.Reset();
            if GLAcc.Totaling = '' then
                GLCorr.SetRange("Credit Account No.", GLAcc."No.")
            else
                GLCorr.SetFilter("Credit Account No.", GLAcc.Totaling);
            if GLCorr.FindSet() then
                repeat
                    EntryNo += 1;
                    InsertRec(GLCorr."Debit Account No.", GLCorr."Credit Account No.", GLAcc."No.", EntryNo, 1, false);
                until GLCorr.Next() = 0;
        until GLAcc.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ModifyView()
    begin
        Rec.Reset();
        Rec.SetRange("Transaction No.", 1);
        Rec.ModifyAll("Debit Entry No.", 1);

        if Rec.FindSet() then
            repeat
                if CalcCorrAmount(true) <> 0 then
                    Rec."Debit Entry No." := 0
                else
                    if CalcCorrAmount(false) <> 0 then
                        Rec."Debit Entry No." := 0;
                Rec.Modify();
            until Rec.Next() = 0;
        UpdateView();
    end;

    [Scope('OnPrem')]
    procedure UpdateView()
    begin
        Rec.FilterGroup(6);
        Rec.Reset();
        Rec.SetRange("Debit Entry No.", 0);
        Rec.SetFilter("Debit Source No.", GLAccountFilter);
        Rec.FilterGroup(0);
        Rec.FindFirst();

        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure InsertRec(DebitAccNo: Code[20]; CreditAccNo: Code[20]; SourceAccountNo: Code[20]; EntryNo: Integer; Indentation: Integer; IsDebit: Boolean)
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;                 // defines sorting order
        Rec."Debit Account No." := DebitAccNo;
        Rec."Credit Account No." := CreditAccNo;
        Rec."Debit Source No." := SourceAccountNo;
        Rec."Transaction No." := Indentation;       // Level indentation
        Rec.Positive := IsDebit;                    // reversed debit/credit for line
        Rec.Insert();

        // "Debit Entry No." this field is used for filtering non-zero amount
    end;

    [Scope('OnPrem')]
    procedure CalcDebitCreditAmount(IsDebit: Boolean): Decimal
    var
        CalcAmount: Decimal;
    begin
        Clear(GLAccount);
        if Rec."Transaction No." = 0 then begin
            GLAccount.Get(Rec."Debit Source No.");
            GLAccMakeFilters();
            if IsDebit xor SwitchAccounts then begin
                GLAccount.CalcFields("Debit Amount");
                CalcAmount := GLAccount."Debit Amount";
            end else begin
                GLAccount.CalcFields("Credit Amount");
                CalcAmount := GLAccount."Credit Amount";
            end;
            exit(CalcAmount);
        end;

        exit(CalcCorrAmount(IsDebit));
    end;

    [Scope('OnPrem')]
    procedure CalcCorrAmount(IsDebit: Boolean): Decimal
    var
        GLCorr: Record "G/L Correspondence";
    begin
        GLCorrMakeFilters(GLCorr, IsDebit);

        GLCorr.CalcFields(Amount);
        exit(GLCorr.Amount);
    end;

    [Scope('OnPrem')]
    procedure GLAccMakeFilters()
    begin
        GLAccount.SetFilter("Date Filter", DateFilter);
        GLAccount.SetFilter("Business Unit Filter", BusinessUnitFilter);
        GLAccount.SetFilter("Global Dimension 1 Filter", GlobalDimension1Filter);
        GLAccount.SetFilter("Global Dimension 2 Filter", GlobalDimension2Filter);
    end;

    [Scope('OnPrem')]
    procedure GLCorrMakeFilters(var GLCorr: Record "G/L Correspondence"; IsDebit: Boolean)
    begin
        Clear(GLCorr);
        if IsDebit and Rec.Positive or
           not IsDebit and not Rec.Positive
        then
            if not SwitchAccounts then begin
                GLCorr.SetFilter("Debit Account No.", Rec."Debit Account No.");
                GLCorr.SetFilter("Credit Account No.", Rec."Credit Account No.");
            end else begin
                GLCorr.SetFilter("Debit Account No.", Rec."Credit Account No.");
                GLCorr.SetFilter("Credit Account No.", Rec."Debit Account No.");
            end
        else begin
            GLCorr.SetRange("Debit Account No.", '');
            GLCorr.SetRange("Credit Account No.", '');
        end;
        if GLCorr.FindFirst() then;

        GLCorr.SetFilter("Date Filter", DateFilter);
        GLCorr.SetFilter("Business Unit Filter", BusinessUnitFilter);
        GLCorr.SetFilter("Debit Global Dim. 1 Filter", GlobalDimension1Filter);
        GLCorr.SetFilter("Credit Global Dim. 1 Filter", GlobalDimension1Filter);
        GLCorr.SetFilter("Debit Global Dim. 2 Filter", GlobalDimension2Filter);
        GLCorr.SetFilter("Credit Global Dim. 2 Filter", GlobalDimension2Filter);
    end;

    local procedure DrillDownDebitCredit(IsDebit: Boolean)
    var
        GLCorr: Record "G/L Correspondence";
    begin
        case Rec."Transaction No." of
            0:
                DrillDownGLAccount(DateFilter, IsDebit, false);
            1:
                begin
                    GLCorrMakeFilters(GLCorr, IsDebit);
                    DrillDownGLCorrEntry(GLCorr."Debit Account No.", GLCorr."Credit Account No.");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDownGLCorrEntry(DebitNo: Code[20]; CreditNo: Code[20])
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
        GLCorrEntry.SetRange("Debit Account No.", DebitNo);
        GLCorrEntry.SetRange("Credit Account No.", CreditNo);
        GLCorrEntry.SetFilter("Debit Global Dimension 1 Code", GlobalDimension1Filter);
        GLCorrEntry.SetFilter("Debit Global Dimension 2 Code", GlobalDimension2Filter);
        GLCorrEntry.SetFilter("Business Unit Code", BusinessUnitFilter);
        GLCorrEntry.SetFilter("Posting Date", DateFilter);
        PAGE.RunModal(0, GLCorrEntry);
    end;

    [Scope('OnPrem')]
    procedure DrillDownGLAccount(AppliedDateFilter: Text; IsDebit: Boolean; NetChange: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLAccount.Totaling = '' then
            GLEntry.SetFilter("G/L Account No.", Rec."Debit Source No.")
        else
            GLEntry.SetFilter("G/L Account No.", GLAccount.Totaling);
        GLEntry.SetFilter("Posting Date", AppliedDateFilter);
        GLEntry.SetFilter("Global Dimension 1 Code", GlobalDimension1Filter);
        GLEntry.SetFilter("Global Dimension 2 Code", GlobalDimension2Filter);
        GLEntry.SetFilter("Business Unit Code", BusinessUnitFilter);
        if not NetChange then
            if IsDebit then
                GLEntry.SetFilter("Debit Amount", '<>0')
            else
                GLEntry.SetFilter("Credit Amount", '<>0');
        PAGE.RunModal(0, GLEntry);
    end;

    [Scope('OnPrem')]
    procedure DrillDownGLEntry(Show: Option Debit,Credit,ACYDebet,ACYCredit,BeginPeriod,ACYBeginPeriod,EndPeriod)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        if (BusinessUnitFilter <> '') or
           (GlobalDimension1Filter <> '') or
           (GlobalDimension2Filter <> '')
        then
            GLEntry.SetCurrentKey(
              "G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code")
        else
            GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        if GLAccount.Totaling = '' then
            GLEntry.SetRange("G/L Account No.", GLAccount."No.")
        else
            GLEntry.SetFilter("G/L Account No.", GLAccount.Totaling);
        GLEntry.SetFilter("Posting Date", DateFilter);
        GLEntry.SetFilter("Global Dimension 1 Code", GlobalDimension1Filter);
        GLEntry.SetFilter("Global Dimension 2 Code", GlobalDimension2Filter);
        GLEntry.SetFilter("Business Unit Code", BusinessUnitFilter);
        case Show of
            Show::Debit:
                GLEntry.SetFilter("Debit Amount", '<>%1', 0);
            Show::Credit:
                GLEntry.SetFilter("Credit Amount", '<>%1', 0);
            Show::ACYDebet:
                GLEntry.SetFilter("Add.-Currency Debit Amount", '<>%1', 0);
            Show::ACYCredit:
                GLEntry.SetFilter("Add.-Currency Credit Amount", '<>%1', 0);
            Show::BeginPeriod,
          Show::ACYBeginPeriod:
                if CopyStr(GLAccount.GetFilter("Date Filter"), 1, 2) <> '..' then begin
                    if GLAccount.GetRangeMin("Date Filter") <> 0D then
                        GLEntry.SetRange("Posting Date", 0D, ClosingDate(GLAccount.GetRangeMin("Date Filter") - 1));
                end else
                    exit;
            Show::EndPeriod:
                if CopyStr(GLAccount.GetFilter("Date Filter"), 1, 2) <> '..' then begin
                    if GLAccount.GetRangeMax("Date Filter") <> 0D then
                        GLEntry.SetRange("Posting Date", 0D, ClosingDate(GLAccount.GetRangeMax("Date Filter")));
                end else
                    exit;
            else
                Error('');
        end;
        PAGE.Run(0, GLEntry);
    end;

    [Scope('OnPrem')]
    procedure SetColumnNames()
    begin
        if not SwitchAccounts then begin
            DebitAccNoColumnName := DebitAccountNoCap;
            CreditAccNoColumnName := CreditAccountNoCap;
            DebitAmountColumnName := DebitAmountCap;
            CreditAmountColumnName := CreditAmountCap;
        end else begin
            DebitAccNoColumnName := CreditAccountNoCap;
            CreditAccNoColumnName := DebitAccountNoCap;
            DebitAmountColumnName := CreditAmountCap;
            CreditAmountColumnName := DebitAmountCap;
        end;
    end;

    [Scope('OnPrem')]
    procedure SwitchGLCorr()
    var
        GLAccNo: Code[20];
    begin
        Rec.Reset();
        Rec.SetRange("Transaction No.", 1);

        if Rec.FindSet() then
            repeat
                GLAccNo := Rec."Debit Account No.";
                Rec."Debit Account No." := Rec."Credit Account No.";
                Rec."Credit Account No." := GLAccNo;
                Rec.Positive := not Rec.Positive;
                Rec.Modify();
            until Rec.Next() = 0;

        UpdateView();
    end;

    [Scope('OnPrem')]
    procedure EmphasizeLine(): Boolean
    begin
        exit(Rec."Transaction No." = 0);
    end;

    [Scope('OnPrem')]
    procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);

        if Calendar."Period Start" = Calendar."Period End" then
            DateFilter := Format(Calendar."Period Start")
        else
            DateFilter := StrSubstNo('%1..%2', Calendar."Period Start", Calendar."Period End");
    end;

    [Scope('OnPrem')]
    procedure FindUserPeriod(SearchText: Code[10])
    var
        UserSetup: Record "User Setup";
        GLAcc: Record "G/L Account";
    begin
        if UserSetup.Get(UserId) then begin
            GLAcc.SetRange("Date Filter", UserSetup."Allow Posting From", UserSetup."Allow Posting To");
            if GLAcc.GetRangeMin("Date Filter") = GLAcc.GetRangeMax("Date Filter") then
                GLAcc.SetRange("Date Filter", GLAcc.GetRangeMin("Date Filter"));
            if DateFilter <> '' then
                DateFilter := GLAcc.GetFilter("Date Filter");
        end else
            FindPeriod(SearchText);
    end;

    local procedure ForceRecalculate()
    begin
        Rec.Reset();
        Rec.DeleteAll();
        CreateView();
        ModifyView();
    end;
}

