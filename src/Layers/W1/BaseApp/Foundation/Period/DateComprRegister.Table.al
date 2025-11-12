// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using Microsoft.Warehouse.Ledger;
using System.Reflection;
using System.Security.AccessControl;

table 87 "Date Compr. Register"
{
    Caption = 'Date Compr. Register';
    DataCaptionFields = "No.";
    LookupPageID = "Date Compr. Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(3; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Period Length"; Option)
        {
            Caption = 'Period Length';
            OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
        }
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ClosingDates = true;
        }
        field(6; "No. of New Records"; Integer)
        {
            Caption = 'No. of New Records';
        }
        field(7; "No. Records Deleted"; Integer)
        {
            Caption = 'No. Records Deleted';
        }
        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(9; "Filter"; Text[250])
        {
            Caption = 'Filter';
        }
        field(10; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ClosingDates = true;
        }
        field(11; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(12; "Register No."; Integer)
        {
            Caption = 'Register No.';
            TableRelation = if ("Table ID" = const(17)) "G/L Register"
            else
            if ("Table ID" = const(21)) "G/L Register"
            else
            if ("Table ID" = const(25)) "G/L Register"
            else
            if ("Table ID" = const(254)) "G/L Register"
            else
            if ("Table ID" = const(32)) "Item Register"
            else
            if ("Table ID" = const(203)) "Resource Register"
            else
            if ("Table ID" = const(169)) "Job Register"
            else
            if ("Table ID" = const(5601)) "FA Register"
            else
            if ("Table ID" = const(5629)) "Insurance Register"
            else
            if ("Table ID" = const(5625)) "FA Register"
            else
            if ("Table ID" = const(7312)) "Warehouse Register";
        }
        field(13; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(14; "Retain Field Contents"; Text[80])
        {
            Caption = 'Retain Field Contents';
        }
        field(15; "Retain Totals"; Text[80])
        {
            Caption = 'Retain Totals';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Table ID")
        {
        }
        key(Key3; "Table ID", "Ending Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The entry cannot be unapplied, because the %1 has been compressed.';
        Text001: Label 'The transaction cannot be reversed, because the %1 has been compressed.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    procedure InitRegister(TableID: Integer; RegNo: Integer; StartingDate: Date; EndingDate: Date; PeriodLength: Integer; EntryFilter: Text[250]; RelatedRegNo: Integer; SourceCode: Code[10])
    begin
        Init();
        "No." := RegNo;
        "Table ID" := TableID;
        "Creation Date" := Today;
        "Starting Date" := StartingDate;
        "Ending Date" := EndingDate;
        "Period Length" := PeriodLength;
        Filter := EntryFilter;
        "Register No." := RelatedRegNo;
        "Source Code" := SourceCode;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    local procedure CheckLedgerEntryCompressed(PostingDate: Date; TableID: Integer; Caption: Text[50]; Type: Option Unapply,Reversal)
    begin
        SetCurrentKey("Table ID", "Ending Date");
        SetRange("Table ID", TableID);
        if Find('+') then
            if PostingDate <= "Ending Date" then
                case Type of
                    Type::Unapply:
                        Error(Text000, Caption);
                    Type::Reversal:
                        Error(Text001, Caption);
                end;
    end;

    procedure CheckMaxDateCompressed(MaxPostingDate: Date; Type: Option Unapply,Reversal)
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        VATEntry: Record "VAT Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
    begin
        CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"Cust. Ledger Entry", CustLedgEntry.TableCaption(), Type);
        CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"Vendor Ledger Entry", VendLedgEntry.TableCaption(), Type);
        CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"Employee Ledger Entry", EmployeeLedgerEntry.TableCaption(), Type);
        CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"Bank Account Ledger Entry", BankAccLedgEntry.TableCaption(), Type);
        CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"VAT Entry", VATEntry.TableCaption(), Type);
        CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"G/L Entry", GLEntry.TableCaption(), Type);
        if Type = Type::Reversal then begin
            CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"FA Ledger Entry", FALedgEntry.TableCaption(), Type);
            CheckLedgerEntryCompressed(MaxPostingDate, DATABASE::"Maintenance Ledger Entry", MaintenanceLedgEntry.TableCaption(), Type);
        end;
    end;
}

