// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

page 10000 "Import Budget Information"
{
    Caption = 'Import Budget Information';
    PageType = Card;

    layout
    {
        area(content)
        {
            field(BudgetName; BudgetName)
            {
                ApplicationArea = Suite;
                Caption = 'Budget Name';
                TableRelation = "G/L Budget Name";
                ToolTip = 'Specifies the name of the budget to be imported.';
            }
            field(StartDate; StartDate)
            {
                ApplicationArea = Suite;
                Caption = 'Budget Start Date';
                ToolTip = 'Specifies the start date of the imported budget.';
            }
            field(NumPeriods; NumPeriods)
            {
                ApplicationArea = Suite;
                Caption = 'Number of Periods';
                MaxValue = 12;
                MinValue = 1;
                ToolTip = 'Specifies the number of budget periods to be created.';
            }
            field(BusinessUnitCode; BusinessUnitCode)
            {
                Caption = 'Business Unit Code';
                TableRelation = "Business Unit";
                ToolTip = 'Specifies the budget unit code for the budget information to be imported.';
            }
            field(GlobDim1; GlobDim1Code)
            {
                ApplicationArea = Suite;
                CaptionClass = '1,1,1';
                Enabled = GlobDim1Enable;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupShortcutDimCode(1, GlobDim1Code);
                end;

                trigger OnValidate()
                begin
                    ValidateShortcutDimCode(1, GlobDim1Code);
                end;
            }
            field(GlobDim2; GlobDim2Code)
            {
                ApplicationArea = Suite;
                CaptionClass = '1,1,2';
                Enabled = GlobDim2Enable;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupShortcutDimCode(2, GlobDim2Code);
                end;

                trigger OnValidate()
                begin
                    ValidateShortcutDimCode(2, GlobDim2Code);
                end;
            }
            field(Description; Description)
            {
                ApplicationArea = Suite;
                Caption = 'Description';
                ToolTip = 'Specifies a description of the budget import.';
            }
            field(ReplaceOption; ReplaceOption)
            {
                ApplicationArea = Suite;
                OptionCaption = 'Replace Current Budget,Add to Current Budget';
                ShowCaption = false;
            }
            label(Control21)
            {
                ApplicationArea = Suite;
                CaptionClass = Text19033369;
                MultiLine = true;
                ShowCaption = false;
            }
            label(Control20)
            {
                ApplicationArea = Suite;
                CaptionClass = Text19080001;
                ShowCaption = false;
            }
            label(Control19)
            {
                ApplicationArea = Suite;
                CaptionClass = Text19015020;
                ShowCaption = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
        GlobDim2Enable := true;
        GlobDim1Enable := true;
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();
        if GLSetup."Global Dimension 1 Code" = '' then begin
            GlobDim1Enable := false;
            GlobDim1Code := '';
        end;
        if GLSetup."Global Dimension 2 Code" = '' then begin
            GlobDim2Enable := false;
            GlobDim2Code := '';
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        DimManagement: Codeunit DimensionManagement;
        BudgetName: Code[10];
        StartDate: Date;
        NumPeriods: Integer;
        GlobDim1Code: Code[20];
        GlobDim2Code: Code[20];
        BusinessUnitCode: Code[20];
        Description: Text[50];
        ReplaceOption: Option "Replace Current Budget","Add to Current Budget";
        GlobDim1Enable: Boolean;
        GlobDim2Enable: Boolean;
        Text19015020: Label '*';
        Text19080001: Label '*';
        Text19033369: Label 'Imported budget amount will be divided evenly among this number of Accounting Periods';

    procedure SetBudgetName(NewBudgetName: Code[10])
    begin
        BudgetName := NewBudgetName;
    end;

    procedure GetBudgetName(): Code[10]
    begin
        exit(BudgetName);
    end;

    procedure SetStartDate(NewStartDate: Date)
    begin
        StartDate := NewStartDate;
    end;

    procedure GetStartDate(): Date
    begin
        exit(StartDate);
    end;

    procedure SetNumPeriods(NewNumPeriods: Integer)
    begin
        NumPeriods := NewNumPeriods;
    end;

    procedure GetNumPeriods(): Integer
    begin
        exit(NumPeriods);
    end;

    procedure SetGlobDim1Code(NewGlobDim1Code: Code[20])
    begin
        GlobDim1Code := NewGlobDim1Code;
    end;

    procedure GetGlobDim1Code(): Code[20]
    begin
        exit(GlobDim1Code);
    end;

    procedure SetGlobDim2Code(NewGlobDim2Code: Code[20])
    begin
        GlobDim2Code := NewGlobDim2Code;
    end;

    procedure GetGlobDim2Code(): Code[20]
    begin
        exit(GlobDim2Code);
    end;

    procedure SetBusinessUnitCode(NewBusinessUnitCode: Code[10])
    begin
        BusinessUnitCode := NewBusinessUnitCode;
    end;

    procedure GetBusinessUnitCode(): Code[10]
    begin
        exit(BusinessUnitCode);
    end;

    procedure SetDescription(NewDescription: Text[50])
    begin
        Description := NewDescription;
    end;

    procedure GetDescription(): Text[50]
    begin
        exit(Description);
    end;

    procedure SetReplaceOption(NewReplaceOption: Option "Replace Current Budget","Add to Current Budget")
    begin
        ReplaceOption := NewReplaceOption;
    end;

    procedure GetReplaceOption(): Integer
    begin
        exit(ReplaceOption);
    end;

    local procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.ValidateDimValueCode(FieldNo, ShortcutDimCode);
    end;

    local procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
    end;
}

