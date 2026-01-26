// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

table 10801 "FR Acc. Schedule Line"
{
    Caption = 'FR Acc. Schedule Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Schedule Name"; Code[10])
        {
            Caption = 'Schedule Name';
            TableRelation = "FR Acc. Schedule Name";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Row No."; Code[10])
        {
            Caption = 'Row No.';
        }
        field(4; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = if ("Totaling Type" = const("Posting Accounts")) "G/L Account"
            else
            if ("Totaling Type" = const("Total Accounts")) "G/L Account";
            ValidateTableRelation = false;
        }
        field(6; "Totaling Type"; Option)
        {
            Caption = 'Totaling Type';
            OptionCaption = 'Posting Accounts,Total Accounts,Rows';
            OptionMembers = "Posting Accounts","Total Accounts",Rows;
        }
        field(7; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(11; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(13; "Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(14; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        field(15; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(10800; "Totaling Debtor"; Text[250])
        {
            Caption = 'Totaling Debtor';
            TableRelation = if ("Totaling Type" = const("Posting Accounts")) "G/L Account"
            else
            if ("Totaling Type" = const("Total Accounts")) "G/L Account";
            ValidateTableRelation = false;
        }
        field(10801; "Totaling Creditor"; Text[250])
        {
            Caption = 'Totaling Creditor';
            TableRelation = if ("Totaling Type" = const("Posting Accounts")) "G/L Account"
            else
            if ("Totaling Type" = const("Total Accounts")) "G/L Account";
            ValidateTableRelation = false;
        }
        field(10802; "Calculate with"; Option)
        {
            Caption = 'Calculate with';
            OptionCaption = 'Sign,Opposite Sign';
            OptionMembers = Sign,"Opposite Sign";
        }
        field(10803; "Totaling 2"; Text[250])
        {
            Caption = 'Totaling 2';
            TableRelation = if ("Totaling Type" = const("Posting Accounts")) "G/L Account"
            else
            if ("Totaling Type" = const("Total Accounts")) "G/L Account";
            ValidateTableRelation = false;
        }
        field(10804; "Date Filter 2"; Date)
        {
            Caption = 'Date Filter 2';
            FieldClass = FlowFilter;
        }
#if not CLEANSCHEMA25
        field(10810; "G/L Entry Type Filter"; Option)
        {
            Caption = 'G/L Entry Type Filter';
            FieldClass = FlowFilter;
            ObsoleteReason = 'Discontinued feature';
            ObsoleteState = Removed;
            OptionCaption = 'Definitive,Simulation';
            OptionMembers = Definitive,Simulation;
            ObsoleteTag = '25.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Schedule Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if xRec."Line No." = 0 then
            if not AccSchedName.Get("Schedule Name") then begin
                AccSchedName.Init();
                AccSchedName.Name := "Schedule Name";
                if AccSchedName.Name = '' then
                    AccSchedName.Description := Text10800;
                AccSchedName.Insert();
            end;
    end;

    var
        Text10800: Label 'Default Schedule';
        AccSchedName: Record "FR Acc. Schedule Name";
        DimManagement: Codeunit DimensionManagement;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimManagement.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Schedule Name", "Line No.", "Row No."));
    end;
}

