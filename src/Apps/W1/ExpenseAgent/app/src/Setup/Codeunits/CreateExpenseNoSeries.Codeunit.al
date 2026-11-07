// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.NoSeries;

codeunit 6972 "Create Expense No. Series"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        InsertExpenseUserNoSeries();
        InsertNoSeries(ExpenseNoSeries(), ExpenseNoSeriesDescriptionTok, ExpenseStartingNoLbl, ExpenseEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Sequence, true);
        InsertNoSeries(ExpenseReportNoSeries(), ExpenseReportNoSeriesDescriptionTok, ExpenseReportStartingNoLbl, ExpenseReportEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Sequence, true);
        InsertNoSeries(PostedExpenseReportNoSeries(), PostedExpenseReportNoSeriesDescriptionTok, PostedExpenseReportStartingNoLbl, PostedExpenseReportEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Normal, true);
        InsertNoSeries(ExpenseVendorNoSeries(), ExpenseVendorNoSeriesDescriptionTok, ExpenseVendorStartingNoLbl, ExpenseVendorEndingNoLbl, '', '', 1, Enum::"No. Series Implementation"::Sequence, true);
    end;

    procedure InsertExpenseUserNoSeries()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        if ExpenseAgentSetup."Expense User Nos." = '' then begin
            ExpenseAgentSetup."Expense User Nos." := ExpenseUserSeries();
            ExpenseAgentSetup.Modify();
        end;
        InsertNoSeries(ExpenseAgentSetup."Expense User Nos.", ExpenseUserSeriesDescriptionTok, ExpenseUserStartingNoLbl, '', '', '', 1, Enum::"No. Series Implementation"::Sequence, true);
    end;

    procedure ExpenseNoSeries(): Code[20]
    begin
        exit(ExpenseNoSeriesTok);
    end;

    procedure ExpenseUserSeries(): Code[20]
    begin
        exit(ExpenseUserSeriesTok);
    end;

    procedure ExpenseVendorNoSeries(): Code[20]
    begin
        exit(ExpenseVendorNoSeriesTok);
    end;

    procedure ExpenseReportNoSeries(): Code[20]
    begin
        exit(ExpenseReportNoSeriesTok);
    end;

    procedure PostedExpenseReportNoSeries(): Code[20]
    begin
        exit(PostedExpenseReportNoSeriesTok);
    end;

    procedure GetExpenseNoSeriesFilter(): Text
    var
        FilterTok: Label '%1|%2|%3|%4', Locked = true;
    begin
        exit(StrSubstNo(FilterTok, ExpenseNoSeriesTok, ExpenseUserSeriesTok, ExpenseReportNoSeriesTok, PostedExpenseReportNoSeriesTok));
    end;

    /// <summary>
    /// Builds the preview record set for expense-related number series: existing rows that match
    /// the seed codes plus seeds that do not yet exist. No database writes are performed.
    /// </summary>
    internal procedure LoadNoSeriesPreview(var TempNoSeries: Record "No. Series" temporary; var TempNoSeriesLine: Record "No. Series Line" temporary)
    var
        ExistingNoSeries: Record "No. Series";
        ExistingNoSeriesLine: Record "No. Series Line";
    begin
        TempNoSeries.Reset();
        TempNoSeries.DeleteAll();
        TempNoSeriesLine.Reset();
        TempNoSeriesLine.DeleteAll();

        ExistingNoSeries.SetFilter(Code, GetExpenseNoSeriesFilter());
        if ExistingNoSeries.FindSet() then
            repeat
                TempNoSeries := ExistingNoSeries;
                TempNoSeries.Insert();

                ExistingNoSeriesLine.SetRange("Series Code", ExistingNoSeries.Code);
                if ExistingNoSeriesLine.FindSet() then
                    repeat
                        TempNoSeriesLine := ExistingNoSeriesLine;
                        TempNoSeriesLine.Insert();
                    until ExistingNoSeriesLine.Next() = 0;
            until ExistingNoSeries.Next() = 0;

        AddNoSeriesSeed(TempNoSeries, TempNoSeriesLine, ExpenseNoSeriesTok, ExpenseNoSeriesDescriptionTok, ExpenseStartingNoLbl, ExpenseEndingNoLbl, Enum::"No. Series Implementation"::Sequence);
        AddNoSeriesSeed(TempNoSeries, TempNoSeriesLine, ExpenseUserSeriesTok, ExpenseUserSeriesDescriptionTok, ExpenseUserStartingNoLbl, '', Enum::"No. Series Implementation"::Sequence);
        AddNoSeriesSeed(TempNoSeries, TempNoSeriesLine, ExpenseReportNoSeriesTok, ExpenseReportNoSeriesDescriptionTok, ExpenseReportStartingNoLbl, ExpenseReportEndingNoLbl, Enum::"No. Series Implementation"::Sequence);
        AddNoSeriesSeed(TempNoSeries, TempNoSeriesLine, PostedExpenseReportNoSeriesTok, PostedExpenseReportNoSeriesDescriptionTok, PostedExpenseReportStartingNoLbl, PostedExpenseReportEndingNoLbl, Enum::"No. Series Implementation"::Normal);
    end;

    local procedure AddNoSeriesSeed(var TempNoSeries: Record "No. Series" temporary; var TempNoSeriesLine: Record "No. Series Line" temporary; SeriesCode: Code[20]; Description: Text[100]; StartingNo: Code[20]; EndingNo: Code[20]; Implementation: Enum "No. Series Implementation")
    begin
        if TempNoSeries.Get(SeriesCode) then
            exit;

        TempNoSeries.Init();
        TempNoSeries.Code := SeriesCode;
        TempNoSeries.Description := Description;
        TempNoSeries."Default Nos." := true;
        TempNoSeries.Insert();

        TempNoSeriesLine.Init();
        TempNoSeriesLine."Series Code" := SeriesCode;
        TempNoSeriesLine."Line No." := GetDefaultLineNo();
        TempNoSeriesLine."Starting No." := StartingNo;
        TempNoSeriesLine."Ending No." := EndingNo;
        TempNoSeriesLine."Increment-by No." := 1;
        TempNoSeriesLine.Implementation := Implementation;
        TempNoSeriesLine.Insert();
    end;

    var
        ExpenseNoSeriesTok: Label 'EXPENSE', MaxLength = 20, Locked = true;
        ExpenseNoSeriesDescriptionTok: Label 'Expenses', MaxLength = 100;
        ExpenseStartingNoLbl: Label 'EXP100001', MaxLength = 20, Locked = true;
        ExpenseEndingNoLbl: Label 'EXP999999', MaxLength = 20, Locked = true;
        ExpenseUserSeriesTok: Label 'EXPENSEUSERS', MaxLength = 20, Locked = true;
        ExpenseVendorNoSeriesTok: Label 'EXPENSEVENDORS', MaxLength = 20, Locked = true;
        ExpenseVendorNoSeriesDescriptionTok: Label 'Expense Vendors', MaxLength = 100;
        ExpenseVendorStartingNoLbl: Label 'EV100001', MaxLength = 20, Locked = true;
        ExpenseVendorEndingNoLbl: Label 'EV999999', MaxLength = 20, Locked = true;
        ExpenseUserSeriesDescriptionTok: Label 'Expense Users', MaxLength = 100;
        ExpenseUserStartingNoLbl: Label 'EXP000001', MaxLength = 20, Locked = true;
        ExpenseReportNoSeriesTok: Label 'EXPREP', MaxLength = 20, Locked = true;
        ExpenseReportNoSeriesDescriptionTok: Label 'Expense Reports', MaxLength = 100;
        ExpenseReportStartingNoLbl: Label 'ER100001', MaxLength = 20, Locked = true;
        ExpenseReportEndingNoLbl: Label 'ER999999', MaxLength = 20, Locked = true;
        PostedExpenseReportNoSeriesTok: Label 'P-EXPREP', MaxLength = 20, Locked = true;
        PostedExpenseReportNoSeriesDescriptionTok: Label 'Posted Expense Reports', MaxLength = 100;
        PostedExpenseReportStartingNoLbl: Label 'P-ER100001', MaxLength = 20, Locked = true;
        PostedExpenseReportEndingNoLbl: Label 'P-ER199999', MaxLength = 20, Locked = true;

    procedure InsertNoSeries(NoSeriesCode: Code[20]; Description: Text[100]; StartingNo: Code[20]; EndingNo: Code[20]; WarningNo: Code[20]; LastNoUsed: Code[20]; IncrementBy: Integer; Implementation: Enum "No. Series Implementation"; AllowManualNo: Boolean)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesExists, NoSeriesLineExists : Boolean;
    begin
        if NoSeries.Get(NoSeriesCode) then
            exit;

        NoSeries.Init();
        NoSeries.Validate(Code, NoSeriesCode);
        NoSeries.Validate(Description, Description);
        NoSeries.Validate("Default Nos.", true);
        NoSeries.Validate("Manual Nos.", AllowManualNo);

        if NoSeriesExists then
            NoSeries.Modify(true)
        else
            NoSeries.Insert(true);

        if NoSeriesLine.Get(NoSeriesCode, GetDefaultLineNo()) then
            exit;

        NoSeriesLine.Validate("Series Code", NoSeries.Code);
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Warning No.", WarningNo);
        NoSeriesLine.Validate("Last No. Used", LastNoUsed);
        NoSeriesLine.Validate("Increment-by No.", IncrementBy);
        NoSeriesLine.Validate(Implementation, Implementation);
        NoSeriesLine.Validate("Line No.", GetDefaultLineNo());

        if NoSeriesLineExists then
            NoSeriesLine.Modify(true)
        else
            NoSeriesLine.Insert(true);
    end;

    local procedure GetDefaultLineNo(): Integer
    begin
        exit(10000);
    end;
}