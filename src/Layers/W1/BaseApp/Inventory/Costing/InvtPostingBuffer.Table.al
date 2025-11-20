// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

table 48 "Invt. Posting Buffer"
{
    Caption = 'Invt. Posting Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account Type"; Enum "Invt. Posting Buffer Account Type")
        {
            Caption = 'Account Type';
            DataClassification = SystemMetadata;
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            DataClassification = SystemMetadata;
        }
        field(4; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
            DataClassification = SystemMetadata;
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(6; "Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount (ACY)';
            DataClassification = SystemMetadata;
        }
        field(7; "Interim Account"; Boolean)
        {
            Caption = 'Interim Account';
            DataClassification = SystemMetadata;
        }
        field(8; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(11; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            DataClassification = SystemMetadata;
        }
        field(12; Negative; Boolean)
        {
            Caption = 'Negative';
            DataClassification = SystemMetadata;
        }
        field(13; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(14; "Bal. Account Type"; Enum "Invt. Posting Buffer Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = SystemMetadata;
        }
        field(15; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Posting Date", "Account Type", "Location Code", "Inventory Posting Group", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Dimension Set ID", Negative, "Bal. Account Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    procedure UseInvtPostSetup(): Boolean
    var
        UseInventoryPostingSetup: Boolean;
    begin
        UseInventoryPostingSetup :=
          "Account Type" in
          ["Account Type"::Inventory,
           "Account Type"::"Inventory (Interim)",
           "Account Type"::"WIP Inventory",
           "Account Type"::"Material Variance",
           "Account Type"::"Capacity Variance",
           "Account Type"::"Subcontracted Variance",
           "Account Type"::"Cap. Overhead Variance",
           "Account Type"::"Mfg. Overhead Variance",
           "Account Type"::"Material - Non Inventory Variance"];

        OnUseInvtPostSetup(Rec, UseInventoryPostingSetup);

        exit(UseInventoryPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUseInvtPostSetup(var InvtPostingBuffer: Record "Invt. Posting Buffer"; var UseInventoryPostingSetup: Boolean)
    begin
    end;
}
