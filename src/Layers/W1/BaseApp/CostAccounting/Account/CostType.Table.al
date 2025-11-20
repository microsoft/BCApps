// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Account;

using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Period;
using System.Security.AccessControl;
using Microsoft.Finance.GeneralLedger.Setup;

table 1103 "Cost Type"
{
    Caption = 'Cost Type';
    DataCaptionFields = "No.", Name;
    DataClassification = CustomerContent;
    DrillDownPageID = "Chart of Cost Types";
    LookupPageID = "Chart of Cost Types";
    Permissions =;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                "Search Name" := Name;
            end;
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(4; Type; Enum "Cost Account Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            var
                CostEntry: Record "Cost Entry";
                CostBudgetEntry: Record "Cost Budget Entry";
            begin
                // Blocked if <> account
                if Type <> xRec.Type then
                    Blocked := Type <> Type::"Cost Type";

                // CHange only if no entries or budget
                if Blocked and not xRec.Blocked then begin
                    CostEntry.SetRange("Cost Type No.", "No.");
                    if not CostEntry.IsEmpty() then
                        Error(Text001, "No.", CostEntry.TableCaption());
                    CostBudgetEntry.SetRange("Cost Type No.", "No.");
                    if not CostBudgetEntry.IsEmpty() then
                        Error(Text001, "No.", CostBudgetEntry.TableCaption());
                end;

                Totaling := '';
            end;
        }
        field(6; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";
        }
        field(7; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";
        }
        field(10; "Combine Entries"; Option)
        {
            Caption = 'Combine Entries';
            OptionCaption = 'None,Day,Month';
            OptionMembers = "None",Day,Month;
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(18; "Blank Line"; Boolean)
        {
            BlankZero = true;
            Caption = 'Blank Line';
            MinValue = false;
        }
        field(19; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(20; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(22; "Cost Classification"; Option)
        {
            Caption = 'Cost Classification';
            OptionCaption = ' ,Fixed,Variable,Step Variable';
            OptionMembers = " ","Fixed",Variable,"Step Variable";
        }
        field(23; "Fixed Share"; Text[30])
        {
            Caption = 'Fixed Share';
        }
        field(26; "Modified Date"; Date)
        {
            Caption = 'Modified Date';
            Editable = false;
        }
        field(27; "Modified By"; Code[50])
        {
            Caption = 'Modified By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(28; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Cost Center Filter"; Code[20])
        {
            Caption = 'Cost Center Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Center";
        }
        field(30; "Cost Object Filter"; Code[20])
        {
            Caption = 'Cost Object Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Object";
        }
        field(31; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Type No." = field("No."),
                                                         "Cost Type No." = field(filter(Totaling)),
                                                         "Cost Center Code" = field("Cost Center Filter"),
                                                         "Cost Object Code" = field("Cost Object Filter"),
                                                         "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Net Change"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Type No." = field("No."),
                                                         "Cost Type No." = field(filter(Totaling)),
                                                         "Cost Center Code" = field("Cost Center Filter"),
                                                         "Cost Object Code" = field("Cost Object Filter"),
                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Budget Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Budget Entry".Amount where("Cost Type No." = field("No."),
                                                                "Cost Type No." = field(filter(Totaling)),
                                                                "Cost Center Code" = field("Cost Center Filter"),
                                                                "Cost Object Code" = field("Cost Object Filter"),
                                                                Date = field("Date Filter"),
                                                                "Budget Name" = field("Budget Filter")));
            Caption = 'Budget Amount';
            FieldClass = FlowField;
        }
        field(34; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = "Cost Type";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                SelectionFilter: Text[1024];
            begin
                if LookupCostTypeFilter(SelectionFilter) then
                    Validate(Totaling, CopyStr(SelectionFilter, 1, MaxStrLen(Totaling)));
            end;

            trigger OnValidate()
            begin
                if not (Type in [Type::Total, Type::"End-Total"]) then
                    FieldError(Type);

                CalcFields("Net Change");
            end;
        }
        field(35; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cost Budget Name";
        }
        field(36; Balance; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Type No." = field("No."),
                                                         "Cost Type No." = field(filter(Totaling)),
                                                         "Cost Center Code" = field("Cost Center Filter"),
                                                         "Cost Object Code" = field("Cost Object Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Budget at Date"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Budget at Date';
            Editable = false;
        }
        field(40; "G/L Account Range"; Text[50])
        {
            Caption = 'G/L Account Range';
            TableRelation = "G/L Account";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                SelectionFilter: Text[1024];
            begin
                if LookupGLAccFilter(SelectionFilter) then
                    Validate("G/L Account Range", CopyStr(SelectionFilter, 1, MaxStrLen("G/L Account Range")));
            end;
        }
        field(47; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Cost Entry"."Debit Amount" where("Cost Type No." = field("No."),
                                                                 "Cost Type No." = field(filter(Totaling)),
                                                                 "Cost Center Code" = field("Cost Center Filter"),
                                                                 "Cost Object Code" = field("Cost Object Filter"),
                                                                 "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount';
            FieldClass = FlowField;
        }
        field(48; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Cost Entry"."Credit Amount" where("Cost Type No." = field("No."),
                                                                  "Cost Type No." = field(filter(Totaling)),
                                                                  "Cost Center Code" = field("Cost Center Filter"),
                                                                  "Cost Object Code" = field("Cost Object Filter"),
                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Credit Amount';
            FieldClass = FlowField;
        }
        field(51; "Balance to Allocate"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry".Amount where("Cost Type No." = field("No."),
                                                         "Cost Center Code" = field("Cost Center Filter"),
                                                         "Cost Object Code" = field("Cost Object Filter"),
                                                         Allocated = const(false),
                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Balance to Allocate';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Budget Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankNumbers = BlankNegAndZero;
            CalcFormula = sum("Cost Budget Entry".Amount where("Cost Type No." = field("No."),
                                                                "Cost Type No." = field(filter(Totaling)),
                                                                "Cost Center Code" = field("Cost Center Filter"),
                                                                "Cost Object Code" = field("Cost Object Filter"),
                                                                Date = field("Date Filter"),
                                                                "Budget Name" = field("Budget Filter")));
            Caption = 'Budget Debit Amount';
            FieldClass = FlowField;
        }
        field(72; "Budget Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankNumbers = BlankNegAndZero;
            CalcFormula = - sum("Cost Budget Entry".Amount where("Cost Type No." = field("No."),
                                                                 "Cost Type No." = field(filter(Totaling)),
                                                                 "Cost Center Code" = field("Cost Center Filter"),
                                                                 "Cost Object Code" = field("Cost Object Filter"),
                                                                 Date = field("Date Filter"),
                                                                 "Budget Name" = field("Budget Filter")));
            Caption = 'Budget Credit Amount';
            FieldClass = FlowField;
        }
        field(73; "Add. Currency Net Change"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Cost Entry"."Additional-Currency Amount" where("Cost Type No." = field("No."),
                                                                               "Cost Type No." = field(filter(Totaling)),
                                                                               "Cost Center Code" = field("Cost Center Filter"),
                                                                               "Cost Object Code" = field("Cost Object Filter"),
                                                                               "Posting Date" = field("Date Filter")));
            Caption = 'Add. Currency Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(74; "Add. Currency Balance at Date"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Cost Entry"."Additional-Currency Amount" where("Cost Type No." = field("No."),
                                                                               "Cost Type No." = field(filter(Totaling)),
                                                                               "Cost Center Code" = field("Cost Center Filter"),
                                                                               "Cost Object Code" = field("Cost Object Filter"),
                                                                               "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Add. Currency Balance at Date';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, Type)
        {
        }
    }

    trigger OnDelete()
    var
        GLAccount: Record "G/L Account";
        CostEntry: Record "Cost Entry";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CheckBalance();

        // Error if movement in not closed fiscal year
        CostEntry.SetRange("Cost Type No.", "No.");
        AccPeriod.SetRange(Closed, false);
        if AccPeriod.FindFirst() then
            CostEntry.SetFilter("Posting Date", '>=%1', AccPeriod."Starting Date");
        if not CostEntry.IsEmpty() then
            Error(Text000);

        // Renumber to entries to no. 0
        CostEntry.Reset();
        CostEntry.SetCurrentKey("Cost Type No.");
        CostEntry.SetRange("Cost Type No.", "No.");
        CostEntry.ModifyAll("Cost Type No.", '');

        CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Type No.");
        CostBudgetEntry.SetRange("Cost Type No.", "No.");
        CostBudgetEntry.DeleteAll();

        GLAccount.SetRange("Cost Type No.", "No.");
        GLAccount.ModifyAll("Cost Type No.", '');
    end;

    trigger OnInsert()
    begin
        TestField("No.");
        Modified();
    end;

    trigger OnModify()
    begin
        Modified();
    end;

    trigger OnRename()
    begin
        "Modified Date" := Today;
    end;

    var
        AccPeriod: Record "Accounting Period";
#pragma warning disable AA0074
        Text000: Label 'You cannot delete a cost type with entries in an open fiscal year.';
#pragma warning disable AA0470
        Text001: Label 'You cannot change cost type %1. There are %2 associated with it.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure Modified()
    begin
        "Modified Date" := Today;
        "Modified By" := UserId;
    end;

    local procedure CheckBalance()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBalance(Rec, IsHandled);
        if IsHandled then
            exit;

        // Message if balance  <> 0
        if Rec.Type = Rec.Type::"Cost Type" then begin
            Rec.CalcFields(Balance);
            Rec.TestField(Balance, 0);
        end;
    end;

    procedure LookupGLAccFilter(var Text: Text): Boolean
    var
        GLAccList: Page "G/L Account List";
    begin
        GLAccList.LookupMode(true);
        if GLAccList.RunModal() = ACTION::LookupOK then begin
            Text := GLAccList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    procedure LookupCostTypeFilter(var Text: Text): Boolean
    var
        CostTypeList: Page "Cost Type List";
    begin
        CostTypeList.LookupMode(true);
        if CostTypeList.RunModal() = ACTION::LookupOK then begin
            Text := CostTypeList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBalance(var CostType: Record "Cost Type"; var IsHandled: Boolean)
    begin
    end;
}
