#pragma warning disable AA0247
page 12405 "G/L Account Turnover"
{
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Account Turnover';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "G/L Account";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        Rec.SetFilter("Date Filter", DateFilter);
                        DateFilter := Rec.GetFilter("Date Filter");
                        CurrPage.Update(false);
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
                        DateFilter := Rec.GetFilter("Date Filter");
                        CurrPage.Update(false);
                    end;
                }
                field("G/L Account Filter"; GLAccountFilter)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "G/L Account"."No.";

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("No.", GLAccountFilter);
                        CurrPage.Update(false);
                    end;
                }
                field("Business Unit Filter"; BusinessUnitFilter)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Business Unit";

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Business Unit Filter", BusinessUnitFilter);
                        CurrPage.Update(false);
                    end;
                }
                field("Global Dimension 1 Filter"; GlobalDimension1Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,3,1';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(GLSetup."Global Dimension 1 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Global Dimension 1 Filter", GlobalDimension1Filter);
                        CurrPage.Update(false);
                    end;
                }
                field("Global Dimension 2 Filter"; GlobalDimension2Filter)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = '1,3,2';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookUpDimFilter(GLSetup."Global Dimension 2 Code", Text));
                    end;

                    trigger OnValidate()
                    begin
                        Rec.SetFilter("Global Dimension 2 Filter", GlobalDimension2Filter);
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Control5)
            {
                Editable = false;
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NoEmphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the related record.';
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
                        DrillDownGLEntry(4);
                    end;
                }
                field(StartingBalanceDebit; BalanceAmounts[BalanceType::StartBalDebit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Starting Debit Balance';
                    Visible = false;
                }
                field(StartingBalanceCredit; BalanceAmounts[BalanceType::StartBalCredit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Starting Credit Balance';
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    Style = Strong;
                    StyleExpr = DebitAmountEmphasize;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(0);
                    end;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    Style = Strong;
                    StyleExpr = CreditAmountEmphasize;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(1);
                    end;
                }
                field("Balance at End Period"; Rec."Balance at Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Balance at End Period';
                    Style = Strong;
                    StyleExpr = BalanceEndPeriodEmphasize;
                }
                field(EndingBalanceDebit; BalanceAmounts[BalanceType::EndBalDebit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Ending Debit Balance';
                    Visible = false;
                }
                field(EndingBalanceCredit; BalanceAmounts[BalanceType::EndBalCredit])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Ending Credit Balance';
                    Visible = false;
                }
                field("Net Change"; Rec."Net Change")
                {
                    BlankZero = true;
                    Style = Strong;
                    StyleExpr = NetChangeEmphasize;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                    Visible = false;
                }
                field("BalanceAmounts[BalanceType::StartBalACY]"; BalanceAmounts[BalanceType::StartBalACY])
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'ACY Balance at Begin Period';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(5);
                    end;
                }
                field("Add.-Currency Debit Amount"; Rec."Add.-Currency Debit Amount")
                {
                    BlankZero = true;
                    ToolTip = 'Specifies the total of the debit entries in the additional reporting currency that have been posted to the account.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(2);
                    end;
                }
                field("Add.-Currency Credit Amount"; Rec."Add.-Currency Credit Amount")
                {
                    BlankZero = true;
                    ToolTip = 'Specifies the total of the credit entries in the additional reporting currency that have been posted to the account.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        DrillDownGLEntry(3);
                    end;
                }
                field("Add.-Currency Balance at Date"; Rec."Add.-Currency Balance at Date")
                {
                    BlankZero = true;
                    Caption = 'ACY Balance at End Period';
                    Visible = false;
                }
                field("Additional-Currency Net Change"; Rec."Additional-Currency Net Change")
                {
                    BlankZero = true;
                    ToolTip = 'Specifies the net change in the account balance. The net change is in the additional reporting currency and includes only those entries that are within the time period specified in the Date Filter field. The program automatically calculates and updates the contents of the field using the Additional-Currency Amount field in the G/L Entry table.';
                    Visible = false;
                }
            }
            group(Source)
            {
                Caption = 'Source';
                field(SourceType; SourceType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Type Filter';
                    OptionCaption = ' ,Customer,Vendor,Bank Account,Fixed Asset';

                    trigger OnValidate()
                    begin
                        SourceTypeOnAfterValidate();
                        CurrPage.Update(false);
                    end;
                }
                field(SourceNo; SourceNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source No. Filter';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CustList: Page "Customer List";
                        VendList: Page "Vendor List";
                        FAList: Page "Fixed Asset List";
                        BankAccList: Page "Bank Account List";
                    begin
                        case SourceType of
                            SourceType::Customer:
                                begin
                                    Clear(CustList);
                                    Cust."No." := SourceNo;
                                    CustList.SetRecord(Cust);
                                    CustList.LookupMode(true);
                                    if CustList.RunModal() = ACTION::LookupOK then begin
                                        CustList.GetRecord(Cust);
                                        SourceNo := Cust."No.";
                                    end;
                                end;
                            SourceType::Vendor:
                                begin
                                    Clear(VendList);
                                    Vend."No." := SourceNo;
                                    VendList.SetRecord(Vend);
                                    VendList.LookupMode(true);
                                    if VendList.RunModal() = ACTION::LookupOK then begin
                                        VendList.GetRecord(Vend);
                                        SourceNo := Vend."No.";
                                    end;
                                end;
                            SourceType::"Bank Account":
                                begin
                                    Clear(BankAccList);
                                    BankAcc."No." := SourceNo;
                                    BankAccList.SetRecord(BankAcc);
                                    BankAccList.LookupMode(true);
                                    if BankAccList.RunModal() = ACTION::LookupOK then begin
                                        BankAccList.GetRecord(BankAcc);
                                        SourceNo := BankAcc."No.";
                                    end;
                                end;
                            SourceType::"Fixed Asset":
                                begin
                                    Clear(FAList);
                                    FA."No." := SourceNo;
                                    FAList.SetRecord(FA);
                                    FAList.LookupMode(true);
                                    if FAList.RunModal() = ACTION::LookupOK then begin
                                        FAList.GetRecord(FA);
                                        SourceNo := FA."No.";
                                    end;
                                end;
                        end;
                        UpdateSourceNoFilter();
                    end;

                    trigger OnValidate()
                    begin
                        UpdateSourceNoFilter();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("G/L Account")
            {
                Caption = 'G/L Account';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Budget Filter" = field("Budget Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ShortCutKey = 'Shift+F7';
                }
                action("Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger Entries';
                    Image = GLRegisters;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("No.");
                    RunPageView = sorting("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("&Comments")
                {
                    Caption = '&Comments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("No.");
                }
                action("Receivables-Payables")
                {
                    ApplicationArea = Suite;
                    Caption = 'Receivables-Payables';
                    Image = ReceivablesPayables;
                    RunObject = Page "Receivables-Payables";
                    ToolTip = 'View a summary of the receivables and payables for the account, including customer and vendor balance due amounts.';
                }
            }
            group(Balance)
            {
                Caption = 'Balance';
                Image = Balance;
                action("G/L &Account Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L &Account Balance';
                    Image = GLAccountBalance;
                    RunObject = Page "G/L Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ToolTip = 'View a summary of the debit and credit balances for different time periods, for the account that you select in the chart of accounts.';
                }
                action("G/L &Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L &Balance';
                    Image = GLBalance;
                    RunObject = Page "G/L Balance";
                    ToolTip = 'View a summary of the debit and credit balances for all the accounts in the chart of accounts, for the time period that you select.';
                }
                action("G/L Balance by &Dimension")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Balance by &Dimension';
                    Image = GLBalanceDimension;
                    RunObject = Page "G/L Balance by Dimension";
                    ToolTip = 'View a summary of the debit and credit balances by dimensions for the current account.';
                }
                separator(Action1210008)
                {
                }
                action("G/L Account Balance/Bud&get")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Account Balance/Bud&get';
                    Image = Period;
                    RunObject = Page "G/L Account Balance/Budget";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ToolTip = 'View a summary of the debit and credit balances and the budgeted amounts for different time periods for the current account.';
                }
                action("G/L Balance/B&udget")
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Balance/B&udget';
                    Image = GeneralLedger;
                    RunObject = Page "G/L Balance/Budget";
                    ToolTip = 'View a summary of the debit and credit balances by dimensions for the current account.';
                }
                separator(Action1210011)
                {
                }
                action("G/L Turnover by Customers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Turnover by Customers';
                    Image = CustomerLedger;
                    RunObject = Page "Customer G/L Turnover";
                    RunPageLink = "G/L Account Filter" = field("No."),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'Analyze the turnover compared with customer account balances.';
                }
                action("G/L Turnover by Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Turnover by Vendors';
                    Image = VendorLedger;
                    RunObject = Page "Vendor G/L Turnover";
                    RunPageLink = "G/L Account Filter" = field("No."),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'Analyze the turnover compared with vendor account balances.';
                }
            }
        }
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                    DateFilter := Rec.GetFilter("Date Filter");
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                    DateFilter := Rec.GetFilter("Date Filter");
                end;
            }
            group(Print)
            {
                Caption = 'Print';
                Image = Print;
                action("G/L Account Turnover")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Turnover';
                    Image = Turnover;
                    ToolTip = 'View the general ledger account summary. You can use this information to verify if the entries are correct on general ledger accounts.';

                    trigger OnAction()
                    begin
                        GLAcc.Reset();
                        GLAcc.CopyFilters(Rec);
                        REPORT.RunModal(REPORT::"G/L Account Turnover", true, false, GLAcc);
                    end;
                }
                action("G/L Account Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Card';
                    Image = Account;
                    ToolTip = 'View or edit details for a general ledger account.';

                    trigger OnAction()
                    begin
                        GLAcc.Reset();
                        GLAcc.CopyFilters(Rec);
                        REPORT.RunModal(REPORT::"G/L Account Card", true, false, GLAcc);
                    end;
                }
                action(GLAccountEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account Entries';
                    Image = EntriesList;
                    ToolTip = 'View related general ledger entries.';

                    trigger OnAction()
                    begin
                        GLAcc.Reset();
                        GLAcc.CopyFilters(Rec);
                        REPORT.RunModal(REPORT::"G/L Account Entries Analysis", true, false, GLAcc);
                    end;
                }
                action("Correspondence Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Correspondence Entry';
                    Image = GLRegisters;

                    trigger OnAction()
                    begin
                        GLAcc.Reset();
                        GLAcc.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"G/L Corresp. General Ledger", true, false, GLAcc);
                    end;
                }
            }
            action("Show GL Correspondence")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show GL Correspondence';
                Image = GL;
                RunObject = Page "G/L Corresp. Gen. Ledger Lines";
                RunPageLink = "Debit Account No." = field("No."),
                              "Debit Account No." = field(filter(Totaling)),
                              "Debit Global Dim. 1 Filter" = field("Global Dimension 1 Filter"),
                              "Debit Global Dim. 2 Filter" = field("Global Dimension 2 Filter"),
                              "Date Filter" = field("Date Filter");
                RunPageMode = Create;
                ToolTip = 'View related correspondence transactions, for example to analyze the number of reports per correspondence.';
            }
        }
        area(reporting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
                actionref("Show GL Correspondence_Promoted"; "Show GL Correspondence")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("G/L Account Turnover_Promoted"; "G/L Account Turnover")
                {
                }
                actionref("G/L Account Card_Promoted"; "G/L Account Card")
                {
                }
                actionref(GLAccountEntries_Promoted; GLAccountEntries)
                {
                }
                actionref("Correspondence Entry_Promoted"; "Correspondence Entry")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        Rec.CalculateAmounts(BalanceAmounts);
        NoOnFormat();
        NameOnFormat();
        DebitAmountOnFormat();
        CreditAmountOnFormat();
        BalanceatDateOnFormat();
        NetChangeOnFormat();
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        if PeriodType = PeriodType::"Accounting Period" then
            FindUserPeriod('')
        else
            FindPeriod('');
        DateFilter := Rec.GetFilter("Date Filter");
        if GLAccountFilter <> '' then
            Rec.SetFilter("No.", GLAccountFilter);
        SourceTypeOnAfterValidate();
        UpdateSourceNoFilter();
    end;

    var
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        GLSetup: Record "General Ledger Setup";
        DateFilter: Text;
        GLAccountFilter: Code[250];
        BusinessUnitFilter: Code[250];
        GlobalDimension1Filter: Code[250];
        GlobalDimension2Filter: Code[250];
        PeriodType: Enum "Analysis Period Type";
        BalanceAmounts: array[7] of Decimal;
        BalanceType: Option ,StartBal,StartBalACY,StartBalCredit,StartBalDebit,EndBalCredit,EndBalDebit,EndBal;
        SourceType: Option " ",Customer,Vendor,"Bank Account","Fixed Asset";
        SourceNo: Code[20];
        NoEmphasize: Boolean;
        NameEmphasize: Boolean;
        NameIndent: Integer;
        DebitAmountEmphasize: Boolean;
        CreditAmountEmphasize: Boolean;
        BalanceEndPeriodEmphasize: Boolean;
        NetChangeEmphasize: Boolean;

    [Scope('OnPrem')]
    procedure DrillDownGLEntry(Show: Option Debit,Credit,ACYDebet,ACYCredit,BeginPeriod,ACYBeginPeriod)
    begin
        GLEntry.Reset();
        if (Rec.GetFilter("Business Unit Filter") <> '') or
           (Rec.GetFilter("Global Dimension 1 Filter") <> '') or
           (Rec.GetFilter("Global Dimension 2 Filter") <> '')
        then
            GLEntry.SetCurrentKey("G/L Account No.", "Business Unit Code", "Global Dimension 1 Code", "Global Dimension 2 Code")
        else
            GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        if Rec.Totaling = '' then
            GLEntry.SetRange("G/L Account No.", Rec."No.")
        else
            GLEntry.SetFilter("G/L Account No.", Rec.Totaling);
        GLEntry.SetFilter("Posting Date", Rec.GetFilter("Date Filter"));
        GLEntry.SetFilter("Global Dimension 1 Code", Rec.GetFilter("Global Dimension 1 Filter"));
        GLEntry.SetFilter("Global Dimension 2 Code", Rec.GetFilter("Global Dimension 2 Filter"));
        GLEntry.SetFilter("Business Unit Code", Rec.GetFilter("Business Unit Filter"));
        GLEntry.SetFilter("Source Type", Rec.GetFilter("Source Type Filter"));
        GLEntry.SetFilter("Source No.", Rec.GetFilter("Source No. Filter"));
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
                if CopyStr(Rec.GetFilter("Date Filter"), 1, 2) <> '..' then begin
                    if Rec.GetRangeMin("Date Filter") <> 0D then
                        GLEntry.SetRange("Posting Date", 0D, ClosingDate(Rec.GetRangeMin("Date Filter") - 1));
                end else
                    exit;
            else
                Error('');
        end;
        PAGE.Run(0, GLEntry);
    end;

    local procedure SourceTypeOnAfterValidate()
    begin
        if SourceType > 0 then
            Rec.SetFilter("Source Type Filter", '%1', SourceType)
        else begin
            Rec.SetRange("Source Type Filter");
            Rec.SetRange("Source No. Filter");
            SourceNo := '';
        end;
    end;

    local procedure UpdateSourceNoFilter()
    begin
        if SourceNo <> '' then
            Rec.SetFilter("Source No. Filter", '%1', SourceNo)
        else
            Rec.SetRange("Source No. Filter");
    end;

    local procedure NoOnFormat()
    begin
        NoEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    local procedure NameOnFormat()
    begin
        NameIndent := Rec.Indentation;
        NameEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    local procedure DebitAmountOnFormat()
    begin
        DebitAmountEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    local procedure CreditAmountOnFormat()
    begin
        CreditAmountEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    local procedure BalanceatDateOnFormat()
    begin
        BalanceEndPeriodEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    local procedure NetChangeOnFormat()
    begin
        NetChangeEmphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    [Scope('OnPrem')]
    procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
        if Calendar."Period Start" = Calendar."Period End" then
            Rec.SetRange("Date Filter", Calendar."Period Start")
        else
            Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
    end;

    [Scope('OnPrem')]
    procedure FindUserPeriod(SearchText: Code[10])
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId) then begin
            Rec.SetRange("Date Filter", UserSetup."Allow Posting From", UserSetup."Allow Posting To");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end else
            FindPeriod(SearchText);
    end;
}

