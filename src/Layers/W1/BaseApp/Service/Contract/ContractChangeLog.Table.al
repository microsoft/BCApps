// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using System.Security.AccessControl;

table 5967 "Contract Change Log"
{
    Caption = 'Contract Change Log';
    DataCaptionFields = "Contract No.";
    Permissions = TableData "Contract Change Log" = rimd;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract Type"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = if ("Contract Type" = const(Contract)) "Service Contract Header"."Contract No." where("Contract Type" = field("Contract Type"));
        }
        field(3; "Change No."; Integer)
        {
            Caption = 'Change No.';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5; "Date of Change"; Date)
        {
            Caption = 'Date of Change';
        }
        field(6; "Time of Change"; Time)
        {
            Caption = 'Time of Change';
        }
        field(7; "Contract Part"; Option)
        {
            Caption = 'Contract Part';
            OptionCaption = 'Header,Line,Discount';
            OptionMembers = Header,Line,Discount;
        }
        field(8; "Field Description"; Text[100])
        {
            Caption = 'Field Description';
        }
        field(9; "Old Value"; Text[100])
        {
            Caption = 'Old Value';
        }
        field(10; "New Value"; Text[100])
        {
            Caption = 'New Value';
        }
        field(12; "Type of Change"; Option)
        {
            Caption = 'Type of Change';
            OptionCaption = 'Modify,Insert,Delete,Rename';
            OptionMembers = Modify,Insert,Delete,Rename;
        }
        field(13; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
        }
        field(14; "Serv. Contract Line No."; Integer)
        {
            Caption = 'Serv. Contract Line No.';
        }
    }

    keys
    {
        key(Key1; "Contract No.", "Change No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract Type")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ContractChangeLog: Record "Contract Change Log";
        NextChangeNo: Integer;

    procedure LogContractChange(ContractNo: Code[20]; ContractPart: Option Header,Line,Discount; FieldName: Text; ChangeType: Integer; OldValue: Text[100]; NewValue: Text[100]; ServItemNo: Code[20]; ServContractLineNo: Integer)
    begin
        ContractChangeLog.Reset();
        ContractChangeLog.LockTable();
        ContractChangeLog.SetRange("Contract No.", ContractNo);
        if ContractChangeLog.FindLast() then
            NextChangeNo := ContractChangeLog."Change No." + 1
        else
            NextChangeNo := 1;

        ContractChangeLog.Init();
        ContractChangeLog."Contract Type" := ContractChangeLog."Contract Type"::Contract;
        ContractChangeLog."Contract No." := ContractNo;
        ContractChangeLog."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        ContractChangeLog."Date of Change" := Today;
        ContractChangeLog."Time of Change" := Time;
        ContractChangeLog."Change No." := NextChangeNo;
        ContractChangeLog."Contract Part" := ContractPart;
        ContractChangeLog."Service Item No." := ServItemNo;
        ContractChangeLog."Serv. Contract Line No." := ServContractLineNo;

        case ChangeType of
            0:
                ContractChangeLog."Type of Change" := ContractChangeLog."Type of Change"::Modify;
            1:
                ContractChangeLog."Type of Change" := ContractChangeLog."Type of Change"::Insert;
            2:
                ContractChangeLog."Type of Change" := ContractChangeLog."Type of Change"::Delete;
            3:
                ContractChangeLog."Type of Change" := ContractChangeLog."Type of Change"::Rename;
        end;
        ContractChangeLog."Field Description" := CopyStr(FieldName, 1, MaxStrLen(ContractChangeLog."Field Description"));
        ContractChangeLog."Old Value" := OldValue;
        ContractChangeLog."New Value" := NewValue;
        ContractChangeLog.Insert();
    end;
}

