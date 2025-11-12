// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Telemetry;
using System.Text;

table 2671 "Alloc. Account Distribution"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Allocation Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            TableRelation = "Allocation Account"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account type';
            OptionMembers = Fixed,Variable;
        }
        field(6; Share; Decimal)
        {
            Caption = 'Share';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            InitValue = 1;

            trigger OnValidate()
            begin
                CalcPercent();
            end;
        }
        field(7; Percent; Decimal)
        {
            Caption = 'Percent';
            DecimalPlaces = 2 : 5;
            Editable = false;
            ExtendedDatatype = Ratio;
            MaxValue = 100;
            MinValue = 0;
        }
        field(8; "Share Updated at"; DateTime)
        {
            Caption = 'Shared Updated at';
        }
        field(9; "Destination Account Type"; Enum "Destination Account Type")
        {
            Caption = 'Destination Account Type';
            trigger OnValidate()
            begin
                Clear(Rec."Destination Account Number");
            end;
        }
        field(10; "Destination Account Number"; Code[20])
        {
            Caption = 'Destination Account Number';

            TableRelation = if ("Destination Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting), "Direct Posting" = const(true))
            else
            if ("Destination Account Type" = const("Bank Account")) "Bank Account";

        }
        field(19; "Breakdown Account Type"; Enum "Breakdown Account Type")
        {
            Caption = 'Breakdown Account Type';
        }
        field(20; "Breakdown Account Number"; Code[20])
        {
            Caption = 'Breakdown Account Number';

            trigger OnLookup()
            var
                GLAccount: Record "G/L Account";
                BankAccount: Record "Bank Account";
                GLAccountList: Page "G/L Account List";
                BankAccountList: Page "Bank Account List";
                Handled: Boolean;
            begin
                OnLookupBreakdownAccountNumber(Rec, Handled);
                if Handled then
                    exit;

                case rec."Breakdown Account Type" of
                    Rec."Breakdown Account Type"::"G/L Account":
                        begin
                            GLAccountList.LookupMode(true);
                            GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                            GLAccountList.SetTableView(GLAccount);
                            if GLAccountList.RunModal() = ACTION::LookupOK then begin
                                GLAccountList.GetRecord(GLAccount);
                                Rec.Validate("Breakdown Account Number", GLAccount."No.");
                            end;
                        end;
                    Rec."Breakdown Account Type"::"Bank Account":
                        begin
                            BankAccountList.LookupMode(true);
                            if BankAccountList.RunModal() = ACTION::LookupOK then begin
                                BankAccountList.GetRecord(BankAccount);
                                Rec.Validate("Breakdown Account Number", BankAccount."No.");
                            end;
                        end;
                end;
            end;
        }
        field(21; "Calculation Period"; Enum "Allocation Account Period")
        {
            Caption = 'Calculation Period';
        }

        field(23; "Dimension 1 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(1);
            Caption = 'Dimension 1 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(1);
            end;
        }
        field(24; "Dimension 2 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(2);
            Caption = 'Dimension 2 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(2);
            end;
        }
        field(25; "Dimension 3 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(3);
            Caption = 'Dimension 3 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(3);
            end;
        }
        field(26; "Dimension 4 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(4);
            Caption = 'Dimension 4 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(4);
            end;
        }
        field(27; "Dimension 5 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(5);
            Caption = 'Dimension 5 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(5);
            end;
        }
        field(28; "Dimension 6 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(6);
            Caption = 'Dimension 6 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(6);
            end;
        }
        field(29; "Dimension 7 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(7);
            Caption = 'Dimension 7 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(7);
            end;
        }
        field(30; "Dimension 8 Filter"; Text[1024])
        {
            CaptionClass = '3, ' + GetDimensionCaption(8);
            Caption = 'Dimension 8 Filter';
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
                LookupDimensionFilter(8);
            end;
        }
        field(35; "Business Unit Code Filter"; Text[1024])
        {
            Caption = 'Business Unit Code Filter';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec."Destination Account Type" <> Rec."Destination Account Type"::"G/L Account" then
                    Error(BusinessUnitCodeCanOnlyBeUsedWithGLAccFilterErr);
            end;
        }
        field(37; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(38; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimensionManagement: Codeunit DimensionManagement;
            begin
                DimensionManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Allocation Account No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KY0', AllocAccTelemetry.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        CalcPercent();
    end;

    trigger OnDelete()
    begin
        CalcPercentDelete();
    end;

    local procedure CalcPercentDelete()
    var
        ExistingAllocAccountDistribution: Record "Alloc. Account Distribution";
        TotalShare: Decimal;
    begin
        ExistingAllocAccountDistribution.SetRange("Allocation Account No.", Rec."Allocation Account No.");
#pragma warning disable AA0210
        ExistingAllocAccountDistribution.SetFilter(SystemId, '<>%1', Rec.SystemId);
#pragma warning restore AA0210

        if ExistingAllocAccountDistribution.IsEmpty() then
            exit;

        ExistingAllocAccountDistribution.CalcSums(Share);
        TotalShare := ExistingAllocAccountDistribution.Share;

        ExistingAllocAccountDistribution.FindSet();
        repeat
            ExistingAllocAccountDistribution.Percent := Round(100 * ExistingAllocAccountDistribution.Share / TotalShare, 0.00001);
            ExistingAllocAccountDistribution."Share Updated at" := CurrentDateTime();
            ExistingAllocAccountDistribution.Modify();
        until ExistingAllocAccountDistribution.Next() = 0;

        ExistingAllocAccountDistribution.CalcSums(Percent);
        ExistingAllocAccountDistribution.Percent := 100 - ExistingAllocAccountDistribution.Percent;
    end;

    local procedure CalcPercent()
    var
        ExistingAllocAccountDistribution: Record "Alloc. Account Distribution";
        TotalShare: Decimal;
    begin
        Rec.Percent := 100;
        Rec."Share Updated at" := CurrentDateTime();

        ExistingAllocAccountDistribution.SetRange("Allocation Account No.", Rec."Allocation Account No.");
#pragma warning disable AA0210
        ExistingAllocAccountDistribution.SetFilter(SystemId, '<>%1', Rec.SystemId);
#pragma warning restore AA0210

        if ExistingAllocAccountDistribution.IsEmpty() then
            exit;

        ExistingAllocAccountDistribution.CalcSums(Share);
        TotalShare := ExistingAllocAccountDistribution.Share + Rec.Share;

        ExistingAllocAccountDistribution.FindSet();
        repeat
            ExistingAllocAccountDistribution.Percent := Round(100 * ExistingAllocAccountDistribution.Share / TotalShare, 0.00001);
            ExistingAllocAccountDistribution."Share Updated at" := CurrentDateTime();
            ExistingAllocAccountDistribution.Modify();
        until ExistingAllocAccountDistribution.Next() = 0;

        ExistingAllocAccountDistribution.CalcSums(Percent);

        // Rounding always goes to the record modified
        Rec.Percent := 100 - ExistingAllocAccountDistribution.Percent;
    end;

    internal procedure LookupDistributionAccountName(): Text[2048]
    begin
        exit(LookupDistributionAccountName(Rec."Destination Account Type", Rec."Destination Account Number"));
    end;

    internal procedure LookupDistributionAccountName(DestinationAccountType: Enum "Destination Account Type"; DestinationAccountNumber: Code[20]): Text[2048]
    var
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
    begin
        case DestinationAccountType of
            DestinationAccountType::"Bank Account":
                begin
                    if BankAccount.Get(DestinationAccountNumber) then;
                    exit(BankAccount.Name);
                end;
            DestinationAccountType::"G/L Account":
                begin
                    if GLAccount.Get(DestinationAccountNumber) then;
                    exit(GLAccount.Name);
                end;
        end;
        exit('');
    end;

    internal procedure LookupBreakdownAccountName(): Text[2048]
    var
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        AccountName: Text[2048];
        Handled: Boolean;
    begin
        OnLookupBreakdownAccountName(Rec, AccountName, Handled);
        if Handled then
            exit(AccountName);

        case "Breakdown Account Type" of
            "Breakdown Account Type"::"Bank Account":
                begin
                    if BankAccount.Get(Rec."Breakdown Account Number") then;
                    exit(BankAccount.Name);
                end;
            "Breakdown Account Type"::"G/L Account":
                begin
                    if GLAccount.Get(Rec."Breakdown Account Number") then;
                    exit(GLAccount.Name);
                end;
        end;
        exit('');
    end;

    internal procedure LookupBusinessUnitFilter(var NewBusinessUnitFilter: Text): Boolean
    var
        BusinessUnit: Record "Business Unit";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        BusinessUnitList: Page "Business Unit List";
        BusinessUnitRecordRef: RecordRef;
    begin
        BusinessUnitList.LookupMode(true);
        if not (BusinessUnitList.RunModal() = ACTION::LookupOK) then
            exit(false);

        BusinessUnitList.SetSelectionFilter(BusinessUnit);
        BusinessUnitRecordRef.GetTable(BusinessUnit);
        NewBusinessUnitFilter := SelectionFilterManagement.GetSelectionFilter(BusinessUnitRecordRef, BusinessUnit.FieldNo("Code"));
        exit(true);
    end;

    internal procedure ShowDimensions()
    var
        DimensionManagement: Codeunit DimensionManagement;
        NewDimensionSetID: Integer;
    begin
        NewDimensionSetID :=
          DimensionManagement.EditDimensionSet(Rec."Dimension Set ID", StrSubstNo(DimensionPageCaptionLbl, Rec.TableCaption(), Rec."Allocation Account No.", Rec."Line No."));
        if NewDimensionSetID = Rec."Dimension Set ID" then
            exit;

        Rec."Dimension Set ID" := NewDimensionSetID;
        DimensionManagement.UpdateGlobalDimFromDimSetID(Rec."Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    internal procedure GetDimensionCaption(DimensionID: Integer): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionCaption: Code[20];
    begin
        if not (GeneralLedgerSetup.Get()) then
            exit(StrSubstNo(GenericDimensionFilterLbl, DimensionID));

        case DimensionID of
            1:
                DimensionCaption := GeneralLedgerSetup."Global Dimension 1 Code";
            2:
                DimensionCaption := GeneralLedgerSetup."Global Dimension 2 Code";
            3:
                DimensionCaption := GeneralLedgerSetup."Shortcut Dimension 3 Code";
            4:
                DimensionCaption := GeneralLedgerSetup."Shortcut Dimension 4 Code";
            5:
                DimensionCaption := GeneralLedgerSetup."Shortcut Dimension 5 Code";
            6:
                DimensionCaption := GeneralLedgerSetup."Shortcut Dimension 6 Code";
            7:
                DimensionCaption := GeneralLedgerSetup."Shortcut Dimension 7 Code";
            8:
                DimensionCaption := GeneralLedgerSetup."Shortcut Dimension 8 Code";
        end;

        if DimensionCaption = '' then
            exit(StrSubstNo(GenericDimensionFilterLbl, DimensionID));

        exit(StrSubstNo(DimensionFilterCaptionLbl, DimensionCaption, DimensionFilterLbl));
    end;

    local procedure LookupDimensionFilter(DimensionID: Integer)
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionCode: Code[20];
        SaveValue: Boolean;
        DimensionFilter: Text;
    begin
        GeneralLedgerSetup.Get();

        case DimensionID of
            1:
                DimensionCode := GeneralLedgerSetup."Global Dimension 1 Code";
            2:
                DimensionCode := GeneralLedgerSetup."Global Dimension 2 Code";
            3:
                DimensionCode := GeneralLedgerSetup."Shortcut Dimension 3 Code";
            4:
                DimensionCode := GeneralLedgerSetup."Shortcut Dimension 4 Code";
            5:
                DimensionCode := GeneralLedgerSetup."Shortcut Dimension 5 Code";
            6:
                DimensionCode := GeneralLedgerSetup."Shortcut Dimension 6 Code";
            7:
                DimensionCode := GeneralLedgerSetup."Shortcut Dimension 7 Code";
            8:
                DimensionCode := GeneralLedgerSetup."Shortcut Dimension 8 Code";
        end;

        SaveValue := DimensionValue.LookUpDimFilter(DimensionCode, DimensionFilter);
        if not SaveValue then
            exit;

        case DimensionID of
            1:
                Rec."Dimension 1 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 1 Filter"));
            2:
                Rec."Dimension 2 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 2 Filter"));
            3:
                Rec."Dimension 3 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 3 Filter"));
            4:
                Rec."Dimension 4 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 4 Filter"));
            5:
                Rec."Dimension 5 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 5 Filter"));
            6:
                Rec."Dimension 6 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 6 Filter"));
            7:
                Rec."Dimension 7 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 7 Filter"));
            8:
                Rec."Dimension 8 Filter" := CopyStr(DimensionFilter, 1, MaxStrLen(Rec."Dimension 8 Filter"));
        end;

        Rec.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupBreakdownAccountNumber(var AllocAccountDistribution: Record "Alloc. Account Distribution"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupBreakdownAccountName(var AllocAccountDistribution: Record "Alloc. Account Distribution"; var AccountName: Text[2048]; var Handled: Boolean)
    begin
    end;

    var
        GenericDimensionFilterLbl: Label 'Dimension %1 Filter', Comment = '%1 is a number most likely in a range from 1 to 8';
        BusinessUnitCodeCanOnlyBeUsedWithGLAccFilterErr: Label 'Business Unit Code Filter can only be used with distribution account that has G/L Account type';
        DimensionPageCaptionLbl: Label '%1 %2 %3', Locked = true;
        DimensionFilterCaptionLbl: Label '%1 %2', Locked = true;
        DimensionFilterLbl: Label 'Filter', Comment = 'Used to display to the users values like Department Filter, Project Filter, Sales Campaign Filter, etc.';
}
