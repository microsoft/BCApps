// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Security.AccessControl;
using System.Security.User;

table 847 "Cash Flow Forecast Entry"
{
    Caption = 'Cash Flow Forecast Entry';
    DrillDownPageID = "Cash Flow Forecast Entries";
    LookupPageID = "Cash Flow Forecast Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(10; "Cash Flow Forecast No."; Code[20])
        {
            Caption = 'Cash Flow Forecast No.';
            TableRelation = "Cash Flow Forecast";
        }
        field(11; "Cash Flow Date"; Date)
        {
            Caption = 'Cash Flow Date';
        }
        field(12; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(13; "Cash Flow Account No."; Code[20])
        {
            Caption = 'Cash Flow Account No.';
            TableRelation = "Cash Flow Account";
        }
        field(14; "Source Type"; Enum "Cash Flow Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(15; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(16; Overdue; Boolean)
        {
            Caption = 'Overdue';
            Editable = false;
        }
        field(17; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(21; "Payment Discount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Payment Discount';
        }
        field(22; "Associated Entry No."; Integer)
        {
            Caption = 'Associated Entry No.';
        }
        field(23; "Associated Document No."; Code[20])
        {
            Caption = 'Associated Document No.';
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(26; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(29; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';

            trigger OnValidate()
            begin
                Positive := "Amount (LCY)" > 0;
            end;
        }
        field(30; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
        field(33; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const("Liquid Funds")) "G/L Account"
            else
            if ("Source Type" = const(Receivables)) "Cust. Ledger Entry"."Document No."
            else
            if ("Source Type" = const(Payables)) "Vendor Ledger Entry"."Document No."
            else
            if ("Source Type" = const("Fixed Assets Budget")) "Fixed Asset"
            else
            if ("Source Type" = const("Fixed Assets Disposal")) "Fixed Asset"
            else
            if ("Source Type" = const("Sales Orders")) "Sales Header"."No." where("Document Type" = const(Order))
            else
            if ("Source Type" = const("Purchase Orders")) "Purchase Header"."No." where("Document Type" = const(Order))
            else
            if ("Source Type" = const("Cash Flow Manual Expense")) "Cash Flow Manual Expense"
            else
            if ("Source Type" = const("Cash Flow Manual Revenue")) "Cash Flow Manual Revenue"
            else
            if ("Source Type" = const("G/L Budget")) "G/L Account"
            else
            if ("Source Type" = const(Job)) Job."No.";
        }
        field(35; "G/L Budget Name"; Code[10])
        {
            Caption = 'G/L Budget Name';
            TableRelation = "G/L Budget Name";
        }
        field(36; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
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
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Cash Flow Account No.", "Cash Flow Date", "Cash Flow Forecast No.")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key3; "Cash Flow Forecast No.", "Cash Flow Account No.", "Source Type", "Cash Flow Date", Positive)
        {
            SumIndexFields = "Amount (LCY)", "Payment Discount";
        }
        key(Key4; "Cash Flow Account No.", "Cash Flow Forecast No.", "Global Dimension 1 Code", "Global Dimension 2 Code", "Cash Flow Date")
        {
            SumIndexFields = "Amount (LCY)", "Payment Discount";
        }
        key(Key5; "Cash Flow Forecast No.", "Cash Flow Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Cash Flow Account No.", "Cash Flow Date", "Source Type")
        {
        }
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;

    procedure DrillDownOnEntries(var CashFlowForecast: Record "Cash Flow Forecast")
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CashFlowForecast.CopyFilter("Cash Flow Date Filter", CFForecastEntry."Cash Flow Date");
        CashFlowForecast.CopyFilter("Source Type Filter", CFForecastEntry."Source Type");
        CashFlowForecast.CopyFilter("Account No. Filter", CFForecastEntry."Cash Flow Account No.");
        CashFlowForecast.CopyFilter("Positive Filter", CFForecastEntry.Positive);
        PAGE.Run(0, CFForecastEntry);
    end;

    procedure ShowSource(ShowDocument: Boolean)
    var
        CFManagement: Codeunit "Cash Flow Management";
    begin
        if ShowDocument then
            CFManagement.ShowSourceDocument(Rec)
        else
            CFManagement.ShowSource(Rec);
    end;
}
