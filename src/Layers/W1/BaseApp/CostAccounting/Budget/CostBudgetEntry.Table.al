// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Utilities;

table 1109 "Cost Budget Entry"
{
    Caption = 'Cost Budget Entry';
    DataClassification = CustomerContent;
    DrillDownPageID = "Cost Budget Entries";
    LookupPageID = "Cost Budget Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "Cost Budget Name";
        }
        field(3; "Cost Type No."; Code[20])
        {
            Caption = 'Cost Type No.';
            TableRelation = "Cost Type";
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
            ClosingDates = true;
        }
        field(5; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";
        }
        field(6; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(30; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(31; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(32; Allocated; Boolean)
        {
            Caption = 'Allocated';
        }
        field(33; "Allocated with Journal No."; Integer)
        {
            Caption = 'Allocated with Journal No.';
        }
        field(40; "Last Modified By User"; Code[50])
        {
            Caption = 'Last Modified By User';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(42; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(50; "Allocation Description"; Text[80])
        {
            Caption = 'Allocation Description';
        }
        field(51; "Allocation ID"; Code[10])
        {
            Caption = 'Allocation ID';
            TableRelation = "Cost Allocation Source";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Budget Name", "Cost Type No.", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date)
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Budget Name", "Cost Center Code", "Cost Type No.", Allocated, Date)
        {
            SumIndexFields = Amount;
        }
        key(Key5; "Budget Name", "Cost Object Code", "Cost Type No.", Allocated, Date)
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Budget Name", "Allocation ID", Date)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Entry No." = 0 then
            "Entry No." := GetLastEntryNo() + 1;
        CheckEntries();
        "Last Modified By User" := UserId();

        HandleCostBudgetRegister();
    end;

    trigger OnModify()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CheckEntries();
        CostBudgetEntry.Get(Rec."Entry No.");
        if ShouldUpdateCostRegister(CostBudgetEntry) then
            CostAccMgt.UpdateCostBudgetRegister(CurrRegNo, "Entry No.", Rec.Amount - CostBudgetEntry.Amount);
        Modified();
    end;

    var
        CostAccMgt: Codeunit "Cost Account Mgt";
        CurrRegNo: Integer;
#pragma warning disable AA0074
        Text000: Label 'This function must be started with a budget name.';
#pragma warning disable AA0470
        Text001: Label 'The entries in budget %1 will be compressed. Entries with identical cost type, cost center, cost object, and date will be combined.\\The first entry of each group remains unchanged. The amounts from all subsequent entries will be added to the first entry.\\Additional information such as text and allocation on other entries will be deleted.\\Are you sure that you want to continue?';
        Text002: Label 'Compress budget entries\Entry       #1#######\Processed   #2#######\Compressed  #3#######';
        Text003: Label '%1 entries in budget %2 processed. %3 entries compressed.';
#pragma warning restore AA0470
        Text004: Label 'A cost center or cost object is missing. Define a corresponding filter in the Budget window.';
        Text005: Label 'You cannot define both cost center and cost object.';
#pragma warning restore AA0074

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure CompressBudgetEntries(BudName: Code[20])
    var
        CostBudgetEntrySource: Record "Cost Budget Entry";
        CostBudgetEntryTarget: Record "Cost Budget Entry";
        Window: Dialog;
        NoProcessed: Integer;
        QtyPerGrp: Integer;
        NoCompressed: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCompressBudgetEntries(BudName, IsHandled);
        if IsHandled then
            exit;

        if BudName = '' then
            Error(Text000);

        if not Confirm(Text001, true, BudName) then
            Error('');

        CostBudgetEntrySource.SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
        CostBudgetEntrySource.SetRange("Budget Name", BudName);

        Window.Open(Text002);

        Window.Update(1, Count);

        if CostBudgetEntrySource.Find('-') then
            repeat
                if (CostBudgetEntrySource."Cost Type No." = CostBudgetEntryTarget."Cost Type No.") and
                   (CostBudgetEntrySource."Cost Center Code" = CostBudgetEntryTarget."Cost Center Code") and
                   (CostBudgetEntrySource."Cost Object Code" = CostBudgetEntryTarget."Cost Object Code") and
                   (CostBudgetEntrySource.Date = CostBudgetEntryTarget.Date)
                then begin
                    CostBudgetEntryTarget.Amount := CostBudgetEntryTarget.Amount + CostBudgetEntrySource.Amount;
                    CostBudgetEntrySource.Delete();
                    NoCompressed := NoCompressed + 1;
                    QtyPerGrp := QtyPerGrp + 1;
                end else begin
                    // Write total
                    if QtyPerGrp > 1 then begin
                        if CostBudgetEntryTarget.Amount = 0 then
                            CostBudgetEntryTarget.Delete()
                        else
                            CostBudgetEntryTarget.Modify();
                        QtyPerGrp := 0;
                    end;

                    // Save new rec.
                    CostBudgetEntryTarget := CostBudgetEntrySource;
                    QtyPerGrp := QtyPerGrp + 1;
                end;

                NoProcessed := NoProcessed + 1;
                if (NoProcessed < 50) or ((NoProcessed mod 100) = 0) then begin
                    Window.Update(2, NoProcessed);
                    Window.Update(3, NoCompressed);
                end;

            until CostBudgetEntrySource.Next() = 0;

        if CostBudgetEntryTarget.Amount <> 0 then
            CostBudgetEntryTarget.Modify();

        Window.Close();
        Message(Text003, NoProcessed, BudName, NoCompressed);
    end;

    procedure CheckEntries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Date);
        TestField("Budget Name");
        TestField("Cost Type No.");

        if ("Cost Center Code" = '') and ("Cost Object Code" = '') then
            Error(Text004);

        if ("Cost Center Code" <> '') and ("Cost Object Code" <> '') then
            Error(Text005);
    end;

    local procedure Modified()
    begin
        "Last Modified By User" := UserId;
        "Last Date Modified" := Today;
    end;

    local procedure HandleCostBudgetRegister()
    var
        CostBudgetReg: Record "Cost Budget Register";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleCostBudgetRegister(Rec, CurrRegNo, IsHandled);
        if IsHandled then
            exit;

        if CostBudgetReg.Get(CurrRegNo) then;
        if (CurrRegNo = 0) or (CostBudgetReg."To Cost Budget Entry No." <> "Entry No." - 1) then
            CurrRegNo := CostAccMgt.InsertCostBudgetRegister("Entry No.", "Budget Name", Amount)
        else
            CostAccMgt.UpdateCostBudgetRegister(CurrRegNo, "Entry No.", Amount);
    end;

    procedure SetCostBudgetRegNo(RegNo: Integer)
    begin
        CurrRegNo := RegNo;
    end;

    procedure GetCostBudgetRegNo(): Integer
    begin
        exit(CurrRegNo);
    end;

    procedure GetFirstCostType(CostTypeFilter: Text[250]): Text[20]
    var
        CostType: Record "Cost Type";
    begin
        CostType.SetFilter("No.", CostTypeFilter);
        if CostType.FindFirst() then
            exit(CostType."No.");
        exit('')
    end;

    procedure GetFirstDate(DateFilter: Text): Date
    var
        Period: Record Date;
        HiddenDate: Date;
    begin
        FilterGroup := 26;
        if GetFilter(Date) <> '' then begin
            DateFilter := GetFilter(Date);
            FilterGroup := 0;
            Evaluate(HiddenDate, CopyStr(DateFilter, StrPos(DateFilter, '..') + 2, StrPos(DateFilter, '|') - (StrPos(DateFilter, '..') + 2)));
            exit(HiddenDate);
        end;
        FilterGroup := 0;
        if DateFilter = '' then
            exit(WorkDate());

        Period.SetRange("Period Type", Period."Period Type"::Date);
        Period.SetFilter("Period Start", DateFilter);
        if Period.FindFirst() then
            exit(Period."Period Start");
        exit(0D)
    end;

    procedure GetFirstCostCenter(CostCenterFilter: Text[250]): Code[20]
    var
        CostCenter: Record "Cost Center";
    begin
        CostCenter.SetFilter(Code, CostCenterFilter);
        if CostCenter.FindFirst() then
            exit(CostCenter.Code);
        exit('')
    end;

    procedure GetFirstCostObject(CostObjectFilter: Text[250]): Code[20]
    var
        CostObject: Record "Cost Object";
    begin
        CostObject.SetFilter(Code, CostObjectFilter);
        if CostObject.FindFirst() then
            exit(CostObject.Code);
        exit('')
    end;

    local procedure ShouldUpdateCostRegister(CostBudgetEntry: Record "Cost Budget Entry") ShouldUpdate: Boolean
    begin
        ShouldUpdate := Rec.Amount <> CostBudgetEntry.Amount;

        OnAfterShouldUpdateCostRegister(Rec, CostBudgetEntry, CurrRegNo, ShouldUpdate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompressBudgetEntries(BudName: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEntries(CostBudgetEntry: Record "Cost Budget Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleCostBudgetRegister(var CostBudgetEntry: Record "Cost Budget Entry"; var CurrRegNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldUpdateCostRegister(var Rec: Record "Cost Budget Entry"; var CostBudgetEntry: Record "Cost Budget Entry"; CurrRegNo: Integer; var ShouldUpdate: Boolean)
    begin
    end;
}
