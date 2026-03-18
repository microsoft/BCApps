// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Service.Item;

codeunit 5975 "Copy Service Contract Mgt."
{
    var
        DocumentNoErr: Label 'Please enter a Contract No.';

    procedure CopyServiceContractLines(ToServiceContractHeader: Record "Service Contract Header"; FromContractType: Enum "Service Contract Type From"; FromContractNo: Code[20]; var FromServiceContractLine: Record "Service Contract Line") AllLinesCopied: Boolean
    var
        ExistingServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        LineNo: Integer;
    begin
        if FromContractNo = '' then
            Error(DocumentNoErr);

        ExistingServiceContractLine.LockTable();
        ExistingServiceContractLine.Reset();
        ExistingServiceContractLine.SetRange("Contract Type", ToServiceContractHeader."Contract Type");
        ExistingServiceContractLine.SetRange("Contract No.", ToServiceContractHeader."Contract No.");
        if ExistingServiceContractLine.FindLast() then
            LineNo := ExistingServiceContractLine."Line No." + 10000
        else
            LineNo := 10000;

        AllLinesCopied := true;
        FromServiceContractLine.Reset();
        FromServiceContractLine.SetRange("Contract Type", FromContractType);
        FromServiceContractLine.SetRange("Contract No.", FromContractNo);
        if FromServiceContractLine.Find('-') then
            repeat
                ServContractManagement.CheckServiceItemBlockedForServiceContract(FromServiceContractLine);
                ServContractManagement.CheckItemServiceBlocked(FromServiceContractLine);
                if not ProcessServiceContractLine(
                     ToServiceContractHeader,
                     FromServiceContractLine,
                     LineNo)
                then begin
                    AllLinesCopied := false;
                    FromServiceContractLine.Mark(true)
                end else
                    LineNo := LineNo + 10000
            until FromServiceContractLine.Next() = 0;

        OnAfterCopyServiceContractLines(ToServiceContractHeader, FromContractType, FromContractNo, FromServiceContractLine);
    end;

    procedure GetServiceContractType(FromContractType: Enum "Service Contract Type From") ToContractType: Enum "Service Contract Type"
    begin
        case FromContractType of
            FromContractType::Quote:
                ToContractType := Enum::"Service Contract Type"::Quote;
            FromContractType::Contract:
                ToContractType := Enum::"Service Contract Type"::Contract;
            else
                OnGetServiceContractTypeCaseElse(FromContractType, ToContractType);
        end;
    end;

    local procedure ProcessServiceContractLine(ToServiceContractHeader: Record "Service Contract Header"; var FromServiceContractLine: Record "Service Contract Line"; LineNo: Integer): Boolean
    var
        ToServiceContractLine: Record "Service Contract Line";
        ExistingServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
    begin
        if FromServiceContractLine."Service Item No." <> '' then begin
            ServiceItem.Get(FromServiceContractLine."Service Item No.");
            if ServiceItem."Customer No." <> ToServiceContractHeader."Customer No." then
                exit(false);

            ExistingServiceContractLine.Reset();
            ExistingServiceContractLine.SetCurrentKey("Service Item No.", "Contract Status");
            ExistingServiceContractLine.SetRange("Service Item No.", FromServiceContractLine."Service Item No.");
            ExistingServiceContractLine.SetRange("Contract Type", ToServiceContractHeader."Contract Type");
            ExistingServiceContractLine.SetRange("Contract No.", ToServiceContractHeader."Contract No.");
            if not ExistingServiceContractLine.IsEmpty() then
                exit(false);
        end;

        ToServiceContractLine := FromServiceContractLine;
        ToServiceContractLine."Last Planned Service Date" := 0D;
        ToServiceContractLine."Last Service Date" := 0D;
        ToServiceContractLine."Last Preventive Maint. Date" := 0D;
        ToServiceContractLine."Invoiced to Date" := 0D;
        ToServiceContractLine."Contract Type" := ToServiceContractHeader."Contract Type";
        ToServiceContractLine."Contract No." := ToServiceContractHeader."Contract No.";
        ToServiceContractLine."Line No." := LineNo;
        ToServiceContractLine."New Line" := true;
        ToServiceContractLine.Credited := false;
        ToServiceContractLine.SetupNewLine();
        ToServiceContractLine.Insert(true);

        OnAfterProcessServiceContractLine(ToServiceContractLine, FromServiceContractLine);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyServiceContractLines(ToServiceContractHeader: Record "Service Contract Header"; FromContractType: Enum "Service Contract Type From"; FromDocNo: Code[20]; var FormServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessServiceContractLine(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetServiceContractTypeCaseElse(FromContractType: Enum "Service Contract Type From"; var ToContractType: Enum "Service Contract Type")
    begin
    end;
}