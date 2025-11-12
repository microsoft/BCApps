// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Setup;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 1100 "Cost Account Mgt"
{
    Permissions = TableData "G/L Account" = rm,
                  TableData "G/L Entry" = rm,
                  TableData Dimension = r,
                  TableData "Cost Entry" = rimd,
                  TableData "Cost Center" = r,
                  TableData "Cost Object" = r;

    trigger OnRun()
    begin
    end;

    var
        CostAccSetup: Record "Cost Accounting Setup";
        GLAcc: Record "G/L Account";
        CostType: Record "Cost Type";
        Window: Dialog;
        i: Integer;
        NoOfCostTypes: Integer;
        NoOfGLAcc: Integer;
        RecsProcessed: Integer;
        RecsCreated: Integer;
        CostTypeExists: Boolean;
        TransferFromChartOfAccountsQst: Label 'This function transfers all income statement accounts from the chart of accounts to the chart of cost types.\\All types including Heading, Begin-Total, and End-Total are transferred.\General ledger accounts that have the same number as an existing cost type are not transferred.\\Do you want to start the job?';
#pragma warning disable AA0470
        IndentQst: Label 'Indent %1?';
        CreateCostTypesProcessingTxt: Label 'Create cost types:\Number   #1########';
        AccountsProcessedAndCreatedMsg: Label '%1 income statement accounts processed. %2 cost types created.';
        IndentChartProcessingTxt: Label 'Indent chart of cost types\Number   #1########';
        EndTotalNotInRangeErr: Label 'End-Total %1 does not belong to the corresponding Begin-Total.';
#pragma warning restore AA0470
        LinkCostTypesToAcctQst: Label 'This function registers the cost types in the chart of accounts.\\This creates the link between chart of accounts and cost types and verifies that each income statement account is only linked to a cost type.\\Start job?';
#pragma warning disable AA0470
        CostTypesAndAccountsProcessedMsg: Label '%1 cost types are processed and logged in %2 G/L accounts.';
        CheckAssignmentProcessingTxt: Label 'Check assignment cost type - G/L account\Number   #1########';
        CostTypeAlreadyAssignedErr: Label 'Cost type %1 should be assigned to G/L account %2.\Cost type %3 is already linked to G/L account %2.\\Each G/L account can only be linked to a single cost type.\However, it is possible to link multiple G/L accounts to a single cost type.';
        IndentingChartProcessingTxt: Label 'Indenting chart\Number   #1########';
        EndTotalNotInBeginTotalRangeErr: Label 'End-Total %1 does not belong to Begin-Total.';
#pragma warning restore AA0470
        RangeTooLongErr: Label 'The range is too long and cannot be transferred to the End-Total field.\\Move End-Total closer to Begin-Total or use shorter codes.';
        NotDefinedInCostAcctErr: Label '%1 %2 is not defined in Cost Accounting.', Comment = '%1=Table caption Cost Center;%2=Field Value Cost Center Code';
        BlockedInCostAcctErr: Label '%1 %2 is blocked in Cost Accounting.', Comment = '%1=Table caption Cost Center;%2=Field Value Cost Center Code';
        DoesNotHaveLineTypeErr: Label '%1 %2 does not have line type %1 or Begin-Total.', Comment = '%1=Table caption Cost Center;%2=Field Value Cost Center Code';
        CreateInCostAcctQst: Label 'Do you want to create %1 %2 in Cost Accounting?', Comment = '%1=Table caption Cost Center or Cost Object;%2=Field Value';
        UpdatedInCostAcctMsg: Label '%1 %2 has been updated in Cost Accounting.', Comment = '%1=Table caption Cost Center or Cost Object or Cost Type;%2=Field Value';
#pragma warning disable AA0470
        CreateDimensionProcessingTxt: Label 'Create dimension\Number   #1########';
        CostCentersCreatedMsg: Label '%1 cost centers created.';
        CostObjectsCreatedMsg: Label '%1 cost objects created.';
        GetCostCentersFromDimQst: Label 'Do you want to get cost centers from dimension %1 ?';
        GetCostObjectsFromDimQst: Label 'Do you want to get cost objects from dimension %1 ?';
        AlreadyExistsAsErr: Label 'The %1 %2 cannot be inserted because it already exists as %3.', Comment = '%1=Table caption Cost Center or Cost Object or Cost Type or Dimension Value;%2=Field Value';
#pragma warning restore AA0470
        UpdateInCostAcctQst: Label 'Do you want to update %1 %2 in Cost Accounting?', Comment = '%1=Table caption Cost Center or Cost Object;%2=Field Value';
        EntryNoNotInRangeErr: Label 'The %1 cannot be updated with this %2 because the %3 does not fall within the From/To range.', Comment = '%1=Cost Budget Register tablecaption,%2=Cost Budget Entry tablecaption,%3=Entry No. fieldcaption';
        ArrayExceededErr: Label 'You can only indent %1 levels for entities of the type Begin-Total.', Comment = '%1 = A number bigger than 1';

    procedure GetCostTypesFromChartOfAccount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCostTypesFromChartOfAccount(IsHandled);
        if IsHandled then
            exit;

        if not Confirm(TransferFromChartOfAccountsQst, true) then
            Error('');

        GetCostTypesFromChartDirect();

        IndentCostTypes(true);

        Message(AccountsProcessedAndCreatedMsg, NoOfGLAcc, RecsCreated)
    end;

    procedure GetCostTypesFromChartDirect()
    begin
        NoOfGLAcc := 0;
        RecsCreated := 0;
        Window.Open(CreateCostTypesProcessingTxt);

        GLAcc.Reset();
        GLAcc.SetRange("Income/Balance", GLAcc."Income/Balance"::"Income Statement");
        OnGetCostTypesFromChartDirectOnAfterSetFilters(GLAcc);
        if GLAcc.Find('-') then
            repeat
                GetCostType(GLAcc."No.", CostTypeExists);
                Window.Update(1, GLAcc."No.");
                NoOfGLAcc := NoOfGLAcc + 1;

                CostType.Init();
                CostType."No." := GLAcc."No.";
                CostType.Name := GLAcc.Name;
                CostType."Search Name" := GLAcc."Search Name";
                CostType.Type := GLAcc."Account Type";
                CostType.Blocked := GLAcc."Account Type" <> GLAcc."Account Type"::Posting;
                CostType."Cost Center Code" := GetCostCenterCodeFromDefDim(DATABASE::"G/L Account", GLAcc."No.");
                if not CostCenterExists(CostType."Cost Center Code") then
                    CostType."Cost Center Code" := '';
                CostType."Cost Object Code" := GetCostObjectCodeFromDefDim(DATABASE::"G/L Account", GLAcc."No.");
                if not CostObjectExists(CostType."Cost Object Code") then
                    CostType."Cost Object Code" := '';
                CostType."New Page" := GLAcc."New Page";
                if GLAcc."No. of Blank Lines" > 0 then
                    CostType."Blank Line" := true;
                CostType.Totaling := GLAcc.Totaling;
                CostType."Modified Date" := Today;
                if GLAcc."Account Type" = GLAcc."Account Type"::Posting then
                    CostType."G/L Account Range" := GLAcc."No."
                else
                    CostType."G/L Account Range" := '';
                OnGetCostTypesFromChartDirectOnBeforeCostTypeInsert(GLAcc, CostType, CostTypeExists);
                if not CostTypeExists then
                    if CostType.Insert() then begin
                        RecsCreated := RecsCreated + 1;
                        GLAcc."Cost Type No." := GLAcc."No.";
                    end;
                GLAcc.Modify();
            until GLAcc.Next() = 0;
        Window.Close();

        IndentCostTypes(true);

        OnAfterGetCostTypesFromChartDirect();
    end;

    procedure ConfirmUpdate(CallingTrigger: Option OnInsert,OnModify,,OnRename; TableCaption2: Text[80]; Value: Code[20]): Boolean
    begin
        if CallingTrigger = CallingTrigger::OnInsert then
            exit(Confirm(CreateInCostAcctQst, true, TableCaption2, Value));
        exit(Confirm(UpdateInCostAcctQst, true, TableCaption2, Value));
    end;

    local procedure CanUpdate(Alignment: Option; NoAligment: Option; PromptAlignment: Option; DimValue: Record "Dimension Value"; DimensionCode: Code[20]; CallingTrigger: Option; TableCaption2: Text[80]): Boolean
    begin
        if DimValue."Dimension Code" <> DimensionCode then
            exit(false);
        if DimValue."Dimension Value Type" in
           [DimValue."Dimension Value Type"::"Begin-Total", DimValue."Dimension Value Type"::"End-Total"]
        then
            exit(false);
        case Alignment of
            NoAligment:
                exit(false);
            PromptAlignment:
                if not ConfirmUpdate(CallingTrigger, TableCaption2, DimValue.Code) then
                    exit(false);
        end;
        exit(true);
    end;

    procedure UpdateCostTypeFromGLAcc(var GLAcc: Record "G/L Account"; var xGLAcc: Record "G/L Account"; CallingTrigger: Option OnInsert,OnModify,,OnRename)
    var
        UpdateCostType: Boolean;
    begin
        if ShouldNotUpdateCostTypeFromGLAcc(GLAcc, xGLAcc, CostAccSetup, CallingTrigger) then
            exit;

        case CallingTrigger of
            CallingTrigger::OnInsert, CallingTrigger::OnModify:
                begin
                    if CostType.Get(GLAcc."Cost Type No.") then
                        UpdateCostType := IsGLAccNoFirstFromRange(CostType, GLAcc."No.")
                    else begin
                        CostType."No." := GLAcc."No.";
                        UpdateCostType := CostType.Insert();
                    end;

                    if UpdateCostType then begin
                        CostType.Name := GLAcc.Name;
                        CostType."Search Name" := GLAcc."Search Name";
                        CostType.Type := GLAcc."Account Type";
                        CostType.Blocked := GLAcc."Account Type" <> GLAcc."Account Type"::Posting;
                        CostType."Cost Center Code" := GetCostCenterCodeFromDefDim(DATABASE::"G/L Account", GLAcc."No.");
                        if not CostCenterExists(CostType."Cost Center Code") then
                            CostType."Cost Center Code" := '';
                        CostType."Cost Object Code" := GetCostObjectCodeFromDefDim(DATABASE::"G/L Account", GLAcc."No.");
                        if not CostObjectExists(CostType."Cost Object Code") then
                            CostType."Cost Object Code" := '';
                        CostType."New Page" := GLAcc."New Page";
                        CostType."Blank Line" := GLAcc."No. of Blank Lines" > 0;
                        CostType.Totaling := GLAcc.Totaling;
                        CostType."Modified Date" := Today;
                        if GLAcc."Account Type" = GLAcc."Account Type"::Posting then
                            CostType."G/L Account Range" := GLAcc."No."
                        else
                            CostType."G/L Account Range" := '';
                        OnUpdateCostTypeFromGLAccOnInsertOrModifyCostTypeBeforeModify(CostType);
                        CostType.Modify();
                        GLAcc."Cost Type No." := CostType."No.";
                    end;
                end;
            CallingTrigger::OnRename:
                begin
                    if CostType.Get(GLAcc."No.") then
                        Error(AlreadyExistsAsErr, GLAcc.TableCaption(), GLAcc."No.", CostType.TableCaption());
                    if CostType.Get(xGLAcc."No.") then begin
                        CostType.Rename(GLAcc."No.");
                        CostType."G/L Account Range" := GLAcc."No.";
                        OnUpdateCostTypeFromGLAccOnRenameCostTypeBeforeModify(CostType);
                        CostType.Modify();
                        GLAcc."Cost Type No." := GLAcc."No.";
                    end else
                        exit;
                end;
        end;

        OnAfterUpdateCostTypeFromGLAcc(CostType, GLAcc, xGLAcc, CallingTrigger);

        IndentCostTypes(false);
        Message(UpdatedInCostAcctMsg, CostType.TableCaption(), GLAcc."No.");
    end;

    local procedure ShouldNotUpdateCostTypeFromGLAcc(var GLAcc: Record "G/L Account"; var xGLAcc: Record "G/L Account"; var CostAccSetup: Record "Cost Accounting Setup"; CallingTrigger: Option OnInsert,OnModify,,OnRename) ShouldNotUpdate: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldNotUpdateCostTypeFromGLAcc(GLAcc, xGLAcc, CostAccSetup, CallingTrigger, ShouldNotUpdate, IsHandled);
        if IsHandled then
            exit(ShouldNotUpdate);

        ShouldNotUpdate :=
            (GLAcc."Income/Balance" <> GLAcc."Income/Balance"::"Income Statement") or
            ((CallingTrigger = CallingTrigger::OnModify) and (Format(GLAcc) = Format(xGLAcc))) or
            (not CostAccSetup.Get()) or
            (CostType.Get(GLAcc."No.") and (GLAcc."Cost Type No." = '')) or
            (not CheckAlignment(GLAcc, CallingTrigger));

        OnAfterShouldNotUpdateCostTypeFromGLAcc(GLAcc, xGLAcc, CostAccSetup, CallingTrigger, ShouldNotUpdate);
    end;

    procedure UpdateCostCenterFromDim(var DimValue: Record "Dimension Value"; var xDimValue: Record "Dimension Value"; CallingTrigger: Option OnInsert,OnModify,,OnRename)
    var
        CostCenter: Record "Cost Center";
        IsHandled: Boolean;
    begin
        CostAccSetup.Get();
        if not CanUpdate(
            CostAccSetup."Align Cost Center Dimension", CostAccSetup."Align Cost Center Dimension"::"No Alignment",
            CostAccSetup."Align Cost Center Dimension"::Prompt, DimValue, CostAccSetup."Cost Center Dimension", CallingTrigger,
            CostCenter.TableCaption())
        then
            exit;

        case CallingTrigger of
            CallingTrigger::OnInsert:
                begin
                    if CostCenterExists(DimValue.Code) then
                        Error(AlreadyExistsAsErr, CostCenter.TableCaption(), DimValue.Code, CostCenter.TableCaption());
                    InsertCostCenterFromDimValue(DimValue);
                end;
            CallingTrigger::OnModify:
                if not CostCenterExists(DimValue.Code) then
                    InsertCostCenterFromDimValue(DimValue)
                else
                    ModifyCostCenterFromDimValue(DimValue);
            CallingTrigger::OnRename:
                begin
                    if not CostCenterExists(xDimValue.Code) then
                        exit;
                    if CostCenterExists(DimValue.Code) then
                        Error(AlreadyExistsAsErr, DimValue.TableCaption(), DimValue.Code, CostCenter.TableCaption());
                    CostCenter.Get(xDimValue.Code);
                    CostCenter.Rename(DimValue.Code);
                end;
        end;

        IndentCostCenters();

        IsHandled := false;
        OnUpdateCostCenterFromDimOnBeforeMessage(IsHandled);
        if not IsHandled then
            Message(UpdatedInCostAcctMsg, CostCenter.TableCaption(), DimValue.Code);
    end;

    procedure UpdateCostObjectFromDim(var DimValue: Record "Dimension Value"; var xDimValue: Record "Dimension Value"; CallingTrigger: Option OnInsert,OnModify,,OnRename)
    var
        CostObject: Record "Cost Object";
        IsHandled: Boolean;
    begin
        CostAccSetup.Get();
        if not CanUpdate(CostAccSetup."Align Cost Object Dimension", CostAccSetup."Align Cost Object Dimension"::"No Alignment",
             CostAccSetup."Align Cost Object Dimension"::Prompt, DimValue, CostAccSetup."Cost Object Dimension", CallingTrigger,
             CostObject.TableCaption())
        then
            exit;

        case CallingTrigger of
            CallingTrigger::OnInsert:
                begin
                    if CostObjectExists(DimValue.Code) then
                        Error(AlreadyExistsAsErr, CostObject.TableCaption(), DimValue.Code, CostObject.TableCaption());
                    InsertCostObjectFromDimValue(DimValue);
                end;
            CallingTrigger::OnModify:
                if not CostObjectExists(DimValue.Code) then
                    InsertCostObjectFromDimValue(DimValue)
                else
                    ModifyCostObjectFromDimValue(DimValue);
            CallingTrigger::OnRename:
                begin
                    if not CostObjectExists(xDimValue.Code) then
                        exit;
                    if CostObjectExists(DimValue.Code) then
                        Error(AlreadyExistsAsErr, DimValue.TableCaption(), DimValue.Code, CostObject.TableCaption());
                    CostObject.Get(xDimValue.Code);
                    CostObject.Rename(DimValue.Code);
                end;
        end;

        IndentCostCenters();
        IsHandled := false;
        OnUpdateCostObjectFromDimOnBeforeMessage(IsHandled);
        if not IsHandled then
            Message(UpdatedInCostAcctMsg, CostObject.TableCaption(), DimValue.Code);
    end;

    procedure UpdateCostTypeFromDefaultDimension(var DefaultDim: Record "Default Dimension"; var GLAcc: Record "G/L Account"; CallingTrigger: Option OnInsert,OnModify,OnDelete)
    var
        CostType: Record "Cost Type";
    begin
        CostAccSetup.Get();

        if CostType.Get(GLAcc."Cost Type No.") then begin
            if not IsGLAccNoFirstFromRange(CostType, GLAcc."No.") then
                exit;
            if not CheckAlignment(GLAcc, CallingTrigger::OnModify) then
                exit;

            if CostAccSetup."Cost Center Dimension" = DefaultDim."Dimension Code" then
                if CostCenterExists(DefaultDim."Dimension Value Code") and not (CallingTrigger = CallingTrigger::OnDelete) then
                    CostType."Cost Center Code" := DefaultDim."Dimension Value Code"
                else
                    CostType."Cost Center Code" := '';

            if CostAccSetup."Cost Object Dimension" = DefaultDim."Dimension Code" then
                if CostObjectExists(DefaultDim."Dimension Value Code") and not (CallingTrigger = CallingTrigger::OnDelete) then
                    CostType."Cost Object Code" := DefaultDim."Dimension Value Code"
                else
                    CostType."Cost Object Code" := '';

            CostType.Modify();
        end;
    end;

    procedure ConfirmIndentCostTypes()
    begin
        if not Confirm(IndentQst, true, CostType.TableCaption()) then
            Error('');

        IndentCostTypes(true);
    end;

    procedure IndentCostTypes(ShowMessage: Boolean)
    var
        CostTypeNo: array[10] of Code[20];
    begin
        i := 0;
        if ShowMessage then
            Window.Open(IndentChartProcessingTxt);

        if CostType.Find('-') then
            repeat
                if ShowMessage then
                    Window.Update(1, CostType."No.");
                if CostType.Type = CostType.Type::"End-Total" then begin
                    if i < 1 then
                        Error(EndTotalNotInRangeErr, CostType."No.");
                    CostType.Totaling := CostTypeNo[i] + '..' + CostType."No.";
                    i := i - 1;
                end;
                CostType.Indentation := i;
                CostType.Modify();
                if CostType.Type = CostType.Type::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(CostTypeNo) then
                        Error(ArrayExceededErr, ArrayLen(CostTypeNo));
                    CostTypeNo[i] := CostType."No.";
                end;
            until CostType.Next() = 0;

        if ShowMessage then
            Window.Close();
    end;

    procedure LinkCostTypesToGLAccountsYN()
    begin
        if not Confirm(LinkCostTypesToAcctQst, true) then
            Error('');

        ClearAll();
        LinkCostTypesToGLAccounts();
        Message(CostTypesAndAccountsProcessedMsg, NoOfCostTypes, NoOfGLAcc);
    end;

    procedure LinkCostTypesToGLAccounts()
    begin
        Window.Open(CheckAssignmentProcessingTxt);

        GLAcc.Reset();
        CostType.Reset();
        GLAcc.ModifyAll("Cost Type No.", '');
        CostType.SetRange(Type, CostType.Type::"Cost Type");
        CostType.SetFilter("G/L Account Range", '<>%1', '');
        OnLinkCostTypesToGLAccountsOnAfterCostTypeSetFilter(CostType);
        if CostType.FindSet() then
            repeat
                Window.Update(1, CostType."No.");
                NoOfCostTypes := NoOfCostTypes + 1;
                GLAcc.SetFilter("No.", CostType."G/L Account Range");
                GLAcc.SetRange("Income/Balance", GLAcc."Income/Balance"::"Income Statement");
                OnLinkCostTypesToGLAccountsOnAfterSetFilters(GLAcc, CostType);
                if GLAcc.FindSet() then
                    repeat
                        if GLAcc."Cost Type No." <> '' then begin
                            Window.Close();
                            Error(CostTypeAlreadyAssignedErr, CostType."No.", GLAcc."No.", GLAcc."Cost Type No.");
                        end;
                        GLAcc."Cost Type No." := CostType."No.";
                        NoOfGLAcc := NoOfGLAcc + 1;
                        GLAcc.Modify();
                    until GLAcc.Next() = 0;
            until CostType.Next() = 0;

        Window.Close();
    end;

    procedure CreateCostCenters()
    var
        CostCenter: Record "Cost Center";
        DimValue: Record "Dimension Value";
    begin
        CostAccSetup.Get();
        if not Confirm(GetCostCentersFromDimQst, true, CostAccSetup."Cost Center Dimension") then
            Error('');

        RecsProcessed := 0;
        RecsCreated := 0;
        Window.Open(CreateDimensionProcessingTxt);

        CostCenter.Reset();
        DimValue.SetRange("Dimension Code", CostAccSetup."Cost Center Dimension");
        if DimValue.Find('-') then begin
            repeat
                Window.Update(1, CostCenter.Code);
                if InsertCostCenterFromDimValue(DimValue) then
                    RecsProcessed := RecsProcessed + 1;
            until DimValue.Next() = 0;
            Window.Close();
        end;

        IndentCostCenters();

        Message(CostCentersCreatedMsg, RecsProcessed);
    end;

    procedure IndentCostCentersYN()
    var
        CostCenter: Record "Cost Center";
    begin
        if not Confirm(IndentQst, true, CostCenter.TableCaption()) then
            Error('');

        IndentCostCenters();
    end;

    procedure IndentCostCenters()
    var
        CostCenter: Record "Cost Center";
        CostCenterRange: Code[250];
        StartRange: array[10] of Code[20];
        SpecialSort: Boolean;
    begin
        SpecialSort := false;
        i := 0;

        Window.Open(IndentingChartProcessingTxt);

        CostCenter.SetCurrentKey("Sorting Order");
        CostCenter.SetFilter("Sorting Order", '<>%1', '');
        if CostCenter.Find('-') then
            SpecialSort := true;

        CostCenterRange := '';
        CostCenter.Reset();
        if SpecialSort then begin
            CostCenter.SetCurrentKey("Sorting Order");
            if CostCenter.FindSet() then
                repeat
                    if CostCenter."Line Type" = CostCenter."Line Type"::"End-Total" then begin
                        CostCenter.Totaling := CostCenterRange;
                        if i < 1 then
                            Error(EndTotalNotInBeginTotalRangeErr, CostCenter.Code);
                        i := i - 1;
                    end;
                    CostCenter.Indentation := i;
                    CostCenter.Modify();
                    if CostCenter."Line Type" = CostCenter."Line Type"::"Begin-Total" then begin
                        CostCenterRange := '';
                        i := i + 1;
                    end;
                    if ((CostCenter."Line Type" = CostCenter."Line Type"::"Cost Center") and (i = 1)) or
                       (CostCenter."Line Type" = CostCenter."Line Type"::"Begin-Total")
                    then begin
                        if StrLen(CostCenterRange) + StrLen(CostCenter.Code) > MaxStrLen(CostCenterRange) then
                            Error(RangeTooLongErr);
                        if CostCenterRange = '' then
                            CostCenterRange := CostCenter.Code
                        else
                            CostCenterRange := CostCenterRange + '|' + CostCenter.Code;
                    end;
                until CostCenter.Next() = 0;
        end else begin
            CostCenter.SetCurrentKey(Code);
            if CostCenter.FindSet() then
                repeat
                    Window.Update(1, CostCenter.Code);

                    if CostCenter."Line Type" = CostCenter."Line Type"::"End-Total" then begin
                        if i < 1 then
                            Error(EndTotalNotInRangeErr, CostCenter.Code);
                        CostCenter.Totaling := StartRange[i] + '..' + CostCenter.Code;
                        i := i - 1;
                    end;
                    CostCenter.Indentation := i;
                    CostCenter.Modify();
                    if CostCenter."Line Type" = CostCenter."Line Type"::"Begin-Total" then begin
                        i := i + 1;
                        if i > ArrayLen(StartRange) then
                            Error(ArrayExceededErr, ArrayLen(StartRange));
                        StartRange[i] := CostCenter.Code;
                    end;
                until CostCenter.Next() = 0;
        end;
        Window.Close();
    end;

    procedure CreateCostObjects()
    var
        CostObject: Record "Cost Object";
        DimValue: Record "Dimension Value";
    begin
        CostAccSetup.Get();
        if not Confirm(GetCostObjectsFromDimQst, true, CostAccSetup."Cost Object Dimension") then
            Error('');

        RecsProcessed := 0;
        RecsCreated := 0;
        Window.Open(CreateDimensionProcessingTxt);

        CostObject.Reset();
        DimValue.SetRange("Dimension Code", CostAccSetup."Cost Object Dimension");
        if DimValue.Find('-') then begin
            repeat
                Window.Update(1, CostObject.Code);
                if InsertCostObjectFromDimValue(DimValue) then
                    RecsProcessed := RecsProcessed + 1;
            until DimValue.Next() = 0;
            Window.Close();
        end;

        IndentCostObjects();
        Message(CostObjectsCreatedMsg, RecsProcessed);
    end;

    procedure IndentCostObjectsYN()
    var
        CostObject: Record "Cost Object";
    begin
        if not Confirm(IndentQst, true, CostObject.TableCaption()) then
            Error('');

        IndentCostObjects();
    end;

    procedure IndentCostObjects()
    var
        CostObject: Record "Cost Object";
        CostObjRange: Code[250];
        StartRange: array[10] of Code[20];
        SpecialSort: Boolean;
    begin
        SpecialSort := false;
        i := 0;

        Window.Open(IndentingChartProcessingTxt);

        CostObject.SetCurrentKey("Sorting Order");
        CostObject.SetFilter("Sorting Order", '<>%1', '');
        if CostObject.Find('-') then
            SpecialSort := true;

        CostObjRange := '';
        CostObject.Reset();
        if SpecialSort then begin
            CostObject.SetCurrentKey("Sorting Order");
            if CostObject.FindSet() then
                repeat
                    if CostObject."Line Type" = CostObject."Line Type"::"End-Total" then begin
                        CostObject.Totaling := CostObjRange;
                        if i < 1 then
                            Error(EndTotalNotInBeginTotalRangeErr, CostObject.Code);
                        i := i - 1;
                    end;
                    CostObject.Indentation := i;
                    CostObject.Modify();
                    if CostObject."Line Type" = CostObject."Line Type"::"Begin-Total" then begin
                        CostObjRange := '';
                        i := i + 1;
                    end;

                    if ((CostObject."Line Type" = CostObject."Line Type"::"Cost Object") and (i = 1)) or
                       (CostObject."Line Type" = CostObject."Line Type"::"Begin-Total")
                    then begin
                        if StrLen(CostObjRange) + StrLen(CostObject.Code) > MaxStrLen(CostObjRange) then
                            Error(RangeTooLongErr);

                        if CostObjRange = '' then
                            CostObjRange := CostObject.Code
                        else
                            CostObjRange := CostObjRange + '|' + CostObject.Code;
                    end;
                until CostObject.Next() = 0;
        end else begin
            CostObject.SetCurrentKey(Code);
            if CostObject.Find('-') then
                repeat
                    Window.Update(1, CostObject.Code);
                    if CostObject."Line Type" = CostObject."Line Type"::"End-Total" then begin
                        if i < 1 then
                            Error(EndTotalNotInRangeErr, CostObject.Code);
                        CostObject.Totaling := StartRange[i] + '..' + CostObject.Code;
                        i := i - 1;
                    end;
                    CostObject.Indentation := i;
                    CostObject.Modify();

                    if CostObject."Line Type" = CostObject."Line Type"::"Begin-Total" then begin
                        i := i + 1;
                        if i > ArrayLen(StartRange) then
                            Error(ArrayExceededErr, ArrayLen(StartRange));
                        StartRange[i] := CostObject.Code;
                    end;
                until CostObject.Next() = 0;
        end;
        Window.Close();
    end;

    procedure CheckValidCCAndCOInGLEntry(DimSetID: Integer)
    var
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostCenterCode: Code[20];
        CostObjectCode: Code[20];
    begin
        if not CostAccSetup.Get() then
            exit;
        if not CostAccSetup."Check G/L Postings" then
            exit;

        CostCenterCode := GetCostCenterCodeFromDimSet(DimSetID);
        CostObjectCode := GetCostObjectCodeFromDimSet(DimSetID);

        if CostCenterCode <> '' then begin
            if not CostCenter.Get(CostCenterCode) then
                Error(NotDefinedInCostAcctErr, CostCenter.TableCaption(), CostCenterCode);
            if CostCenter.Blocked then
                Error(BlockedInCostAcctErr, CostCenter.TableCaption(), CostCenterCode);
            if not (CostCenter."Line Type" in [CostCenter."Line Type"::"Cost Center", CostCenter."Line Type"::"Begin-Total"]) then
                Error(DoesNotHaveLineTypeErr, CostCenter.TableCaption(), CostCenterCode);
        end;

        if CostObjectCode <> '' then begin
            if not CostObject.Get(CostObjectCode) then
                Error(NotDefinedInCostAcctErr, CostObject.TableCaption(), CostObjectCode);
            if CostObject.Blocked then
                Error(BlockedInCostAcctErr, CostObject.TableCaption(), CostObjectCode);
            if not (CostObject."Line Type" in [CostObject."Line Type"::"Cost Object", CostObject."Line Type"::"Begin-Total"]) then
                Error(DoesNotHaveLineTypeErr, CostObject.TableCaption(), CostObjectCode);
        end;
    end;

    procedure GetCostCenterCodeFromDimSet(DimSetID: Integer) Result: Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCostCenterCodeFromDimSet(DimSetID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CostAccSetup.Get();
        if DimSetEntry.Get(DimSetID, CostAccSetup."Cost Center Dimension") then
            exit(DimSetEntry."Dimension Value Code");
        exit('');
    end;

    procedure GetCostCenterCodeFromDefDim(TableID: Integer; No: Code[20]): Code[20]
    var
        DefaultDim: Record "Default Dimension";
    begin
        CostAccSetup.Get();
        if DefaultDim.Get(TableID, No, CostAccSetup."Cost Center Dimension") then
            exit(DefaultDim."Dimension Value Code");
    end;

    procedure CostCenterExists(CostCenterCode: Code[20]): Boolean
    var
        CostCenter: Record "Cost Center";
    begin
        exit(CostCenter.Get(CostCenterCode));
    end;

    procedure CostCenterExistsAsDimValue(CostCenterCode: Code[20]): Boolean
    var
        DimValue: Record "Dimension Value";
    begin
        CostAccSetup.Get();
        exit(DimValue.Get(CostAccSetup."Cost Center Dimension", CostCenterCode));
    end;

    procedure LookupCostCenterFromDimValue(var CostCenterCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        CostAccSetup.Get();
        DimValue.LookupDimValue(CostAccSetup."Cost Center Dimension", CostCenterCode);
    end;

    procedure GetCostObjectCodeFromDimSet(DimSetID: Integer) Result: Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCostObjectCodeFromDimSet(DimSetID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CostAccSetup.Get();
        if DimSetEntry.Get(DimSetID, CostAccSetup."Cost Object Dimension") then
            exit(DimSetEntry."Dimension Value Code");
        exit('');
    end;

    procedure GetCostObjectCodeFromDefDim(TableID: Integer; No: Code[20]): Code[20]
    var
        DefaultDim: Record "Default Dimension";
    begin
        CostAccSetup.Get();
        if DefaultDim.Get(TableID, No, CostAccSetup."Cost Object Dimension") then
            exit(DefaultDim."Dimension Value Code");
    end;

    procedure CostObjectExists(CostObjectCode: Code[20]): Boolean
    var
        CostObject: Record "Cost Object";
    begin
        exit(CostObject.Get(CostObjectCode));
    end;

    procedure CostObjectExistsAsDimValue(CostObjectCode: Code[20]): Boolean
    var
        DimValue: Record "Dimension Value";
    begin
        CostAccSetup.Get();
        exit(DimValue.Get(CostAccSetup."Cost Object Dimension", CostObjectCode));
    end;

    procedure LookupCostObjectFromDimValue(var COstObjectCode: Code[20])
    var
        DimValue: Record "Dimension Value";
    begin
        CostAccSetup.Get();
        DimValue.LookupDimValue(CostAccSetup."Cost Object Dimension", COstObjectCode);
    end;

    local procedure InsertCostCenterFromDimValue(DimValue: Record "Dimension Value"): Boolean
    var
        CostCenter: Record "Cost Center";
    begin
        CopyDimValueToCostCenter(DimValue, CostCenter);
        exit(CostCenter.Insert());
    end;

    local procedure ModifyCostCenterFromDimValue(DimValue: Record "Dimension Value"): Boolean
    var
        CostCenter: Record "Cost Center";
    begin
        CostCenter.Get(DimValue.Code);
        CopyDimValueToCostCenter(DimValue, CostCenter);
        exit(CostCenter.Modify());
    end;

    local procedure CopyDimValueToCostCenter(DimValue: Record "Dimension Value"; var CostCenter: Record "Cost Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDimValueToCostCenter(DimValue, CostCenter, IsHandled);
        if IsHandled then
            exit;

        CostCenter.Init();
        CostCenter.Code := DimValue.Code;
        CostCenter.Name := DimValue.Name;
        CostCenter."Line Type" := DimValue."Dimension Value Type";
        CostCenter.Blocked := DimValue.Blocked;
    end;

    local procedure InsertCostObjectFromDimValue(DimValue: Record "Dimension Value"): Boolean
    var
        CostObject: Record "Cost Object";
    begin
        CopyDimValueToCostObject(DimValue, CostObject);
        exit(CostObject.Insert());
    end;

    local procedure ModifyCostObjectFromDimValue(DimValue: Record "Dimension Value"): Boolean
    var
        CostObject: Record "Cost Object";
    begin
        CostObject.Get(DimValue.Code);
        CopyDimValueToCostObject(DimValue, CostObject);
        exit(CostObject.Modify());
    end;

    local procedure CopyDimValueToCostObject(DimValue: Record "Dimension Value"; var CostObject: Record "Cost Object")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDimValueToCostObject(DimValue, CostObject, IsHandled);
        if IsHandled then
            exit;

        CostObject.Init();
        CostObject.Code := DimValue.Code;
        CostObject.Name := DimValue.Name;
        CostObject."Line Type" := DimValue."Dimension Value Type";
        CostObject.Blocked := DimValue.Blocked;

        OnAfterCopyDimValueToCostObject(DimValue, CostObject);
    end;

    procedure InsertCostBudgetRegister(CostBudgetEntryNo: Integer; CostBudgetName: Code[10]; CostBudgetAmount: Decimal): Integer
    var
        CostBudgetReg: Record "Cost Budget Register";
    begin
        CostBudgetReg.LockTable();
        if CostBudgetReg.FindLast() then
            CostBudgetReg."No." := CostBudgetReg."No." + 1
        else
            CostBudgetReg."No." := 1;
        CostBudgetReg.Init();
        CostBudgetReg.Source := CostBudgetReg.Source::Manual;
        CostBudgetReg."From Cost Budget Entry No." := CostBudgetEntryNo;
        CostBudgetReg."To Cost Budget Entry No." := CostBudgetEntryNo;
        CostBudgetReg."No. of Entries" := 1;
        CostBudgetReg."Cost Budget Name" := CostBudgetName;
        CostBudgetReg.Amount := CostBudgetAmount;
        CostBudgetReg."Processed Date" := Today;
        CostBudgetReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(CostBudgetReg."User ID"));
        CostBudgetReg.Insert();

        exit(CostBudgetReg."No.");
    end;

    procedure UpdateCostBudgetRegister(CostBudgetRegNo: Integer; CostBudgetEntryNo: Integer; CostBudgetAmount: Decimal)
    var
        CostBudgetReg: Record "Cost Budget Register";
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        if CostBudgetRegNo = 0 then begin
            CostBudgetReg.SetCurrentKey("From Cost Budget Entry No.", "To Cost Budget Entry No.");
            CostBudgetReg.SetRange("From Cost Budget Entry No.", 0, CostBudgetEntryNo);
            CostBudgetReg.SetFilter("To Cost Budget Entry No.", '%1..', CostBudgetEntryNo);
            CostBudgetReg.FindLast();
        end else
            CostBudgetReg.Get(CostBudgetRegNo);

        if (CostBudgetEntryNo > CostBudgetReg."To Cost Budget Entry No." + 1) or
           (CostBudgetEntryNo < CostBudgetReg."From Cost Budget Entry No.")
        then
            Error(EntryNoNotInRangeErr, CostBudgetReg.TableCaption(), CostBudgetEntry.TableCaption(), CostBudgetEntry.FieldCaption("Entry No."));
        if CostBudgetEntryNo > CostBudgetReg."To Cost Budget Entry No." then begin
            CostBudgetReg."To Cost Budget Entry No." := CostBudgetEntryNo;
            CostBudgetReg."No. of Entries" := CostBudgetReg."To Cost Budget Entry No." - CostBudgetReg."From Cost Budget Entry No." + 1
        end;
        CostBudgetReg.Amount := CostBudgetReg.Amount + CostBudgetAmount;
        CostBudgetReg.Modify(true)
    end;

    local procedure CheckAlignment(var GLAcc: Record "G/L Account"; CallingTrigger: Option): Boolean
    begin
        CostAccSetup.Get();

        if CostAccSetup."Align G/L Account" = CostAccSetup."Align G/L Account"::"No Alignment" then
            exit(false);

        if CostAccSetup."Align G/L Account" = CostAccSetup."Align G/L Account"::Prompt then
            if not ConfirmUpdate(CallingTrigger, CostType.TableCaption(), GLAcc."No.") then
                exit(false);

        exit(true);
    end;

    procedure IsGLAccNoFirstFromRange(CostType: Record "Cost Type"; GLAccNo: Code[20]): Boolean
    var
        GLAccCheck: Record "G/L Account";
    begin
        GLAccCheck.SetFilter("No.", CostType."G/L Account Range");
        OnIsGLAccNoFirstFromRangeOnAfterGLAccSetFilter(CostType, GLAccCHeck);
        if GLAccCheck.FindFirst() then
            exit(GLAccNo = GLAccCheck."No.");

        exit(false);
    end;

    procedure GetCostType(GLAccNo: Code[20]; var CostTypeExists: Boolean)
    var
        GLAcc: Record "G/L Account";
        CostType: Record "Cost Type";
    begin
        CostType.Reset();
        CostType.SetRange("No.", GLAccNo);
        if CostType.IsEmpty() then begin
            CostTypeExists := false;
            CostType.Reset();
            CostType.SetRange(Type, CostType.Type::"Cost Type");
            CostType.SetFilter("G/L Account Range", '<>%1', '');
            OnGetCostTypeOnAfterCostTypeSetFilter(CostType);
            if CostType.FindSet() then
                repeat
                    GLAcc.Reset();
                    GLAcc.SetRange("Income/Balance", GLAcc."Income/Balance"::"Income Statement");
                    GLAcc.SetFilter("No.", CostType."G/L Account Range");
                    OnGetCostTypeOnAfterSetFilters(GLAcc, CostType);
                    if GLAcc.FindSet() then
                        repeat
                            if GLAccNo = GLAcc."No." then
                                CostTypeExists := true
                        until (GLAcc.Next() = 0) or CostTypeExists;
                until (CostType.Next() = 0) or CostTypeExists;
        end;
    end;

    procedure OpenDimValueListFiltered(FieldNo: Integer)
    var
        DimValue: Record "Dimension Value";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        DimCode: Code[20];
    begin
        CostAccSetup.Get();
        RecRef.GetTable(CostAccSetup);
        FieldRef := RecRef.Field(FieldNo);
        Evaluate(DimCode, Format(FieldRef.Value));
        DimValue.SetRange("Dimension Code", DimCode);
        PAGE.Run(0, DimValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCostTypesFromChartDirect()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCostTypeFromGLAcc(var CostType: Record "Cost Type"; var GLAcc: Record "G/L Account"; var xGLAcc: Record "G/L Account"; CallingTrigger: Option OnInsert,OnModify,,OnRename)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimValueToCostCenter(DimValue: Record "Dimension Value"; var CostCenter: Record "Cost Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimValueToCostObject(DimValue: Record "Dimension Value"; var CostObject: Record "Cost Object"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetCostTypesFromChartOfAccount(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCostCenterCodeFromDimSet(DimSetID: Integer; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCostObjectCodeFromDimSet(DimSetID: Integer; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCostTypesFromChartDirectOnBeforeCostTypeInsert(var GLAccount: Record "G/L Account"; var CostType: Record "Cost Type"; var CostTypeExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCostTypeOnAfterSetFilters(var GLAccount: Record "G/L Account"; var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCostTypeOnAfterCostTypeSetFilter(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkCostTypesToGLAccountsOnAfterSetFilters(var GLAccount: Record "G/L Account"; var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkCostTypesToGLAccountsOnAfterCostTypeSetFilter(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldNotUpdateCostTypeFromGLAcc(var GLAccount: Record "G/L Account"; var xGLAccount: Record "G/L Account"; var CostAccSetup: Record "Cost Accounting Setup"; CallingTrigger: Option OnInsert,OnModify,,OnRename; var ShouldNotUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostCenterFromDimOnBeforeMessage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostObjectFromDimOnBeforeMessage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCostTypesFromChartDirectOnAfterSetFilters(var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyDimValueToCostObject(DimValue: Record "Dimension Value"; var CostObject: Record "Cost Object")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsGLAccNoFirstFromRangeOnAfterGLAccSetFilter(var CostType: Record "Cost Type"; var GLAccountCheck: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostTypeFromGLAccOnInsertOrModifyCostTypeBeforeModify(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostTypeFromGLAccOnRenameCostTypeBeforeModify(var CostType: Record "Cost Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldNotUpdateCostTypeFromGLAcc(var GLAccount: Record "G/L Account"; var xGLAccount: Record "G/L Account"; var CostAccSetup: Record "Cost Accounting Setup"; CallingTrigger: Option OnInsert,OnModify,,OnRename; var ShouldNotUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;
}

