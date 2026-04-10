// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using System.Security.AccessControl;

table 5969 "Contract Gain/Loss Entry"
{
    Caption = 'Contract Gain/Loss Entry';
    DrillDownPageID = "Contract Gain/Loss Entries";
    LookupPageID = "Contract Gain/Loss Entries";
    Permissions = TableData "Contract Gain/Loss Entry" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            ToolTip = 'Specifies the contract number linked to this contract gain/loss entry.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(3; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            ToolTip = 'Specifies the contract group code linked to this contract gain/loss entry.';
            TableRelation = "Contract Group";
        }
        field(4; "Change Date"; Date)
        {
            Caption = 'Change Date';
            ToolTip = 'Specifies the date when the change on the service contract occurred.';
        }
        field(5; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(6; "Type of Change"; Enum "Service Contract Change Type")
        {
            Caption = 'Type of Change';
            ToolTip = 'Specifies the type of change on the service contract.';
        }
        field(8; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
            TableRelation = "Responsibility Center";
        }
        field(9; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the customer number that is linked to this contract gain/loss entry.';
            TableRelation = Customer;
        }
        field(10; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(12; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the change in annual amount on the service contract.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract No.", "Change Date", "Reason Code")
        {
            SumIndexFields = Amount;
        }
        key(Key3; "Contract Group Code", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Customer No.", "Ship-to Code", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key5; "Reason Code", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Responsibility Center", "Change Date")
        {
            SumIndexFields = Amount;
        }
        key(Key7; "Responsibility Center", "Type of Change", "Reason Code")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";

    procedure CreateEntry(ChangeType: Enum "Service Contract Change Type"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20]; ChangeAmount: Decimal; ReasonCode: Code[10])
    var
        ServContract: Record "Service Contract Header";
        NextLine: Integer;
    begin
        ContractGainLossEntry.Reset();
        ContractGainLossEntry.LockTable();
        if ContractGainLossEntry.FindLast() then
            NextLine := ContractGainLossEntry."Entry No." + 1
        else
            NextLine := 1;

        if ContractNo <> '' then
            ServContract.Get(ContractType, ContractNo)
        else
            Clear(ServContract);

        ContractGainLossEntry.Init();
        ContractGainLossEntry."Entry No." := NextLine;
        ContractGainLossEntry."Contract No." := ContractNo;
        ContractGainLossEntry."Contract Group Code" := ServContract."Contract Group Code";
        ContractGainLossEntry."Change Date" := Today;
        ContractGainLossEntry."Type of Change" := ChangeType;
        ContractGainLossEntry."Responsibility Center" := ServContract."Responsibility Center";
        ContractGainLossEntry."Customer No." := ServContract."Customer No.";
        ContractGainLossEntry."Ship-to Code" := ServContract."Ship-to Code";
        ContractGainLossEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        ContractGainLossEntry.Amount := ChangeAmount;
        ContractGainLossEntry."Reason Code" := ReasonCode;
        ContractGainLossEntry.Insert();
    end;
}

