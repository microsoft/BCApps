// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Sales.Customer;
using Microsoft.Service.Item;
using System.Utilities;

report 6037 "Change Customer in Contract"
{
    Caption = 'Change Customer in Contract';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ContractNoText; ContractNoText)
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract No.';
                        DrillDown = true;
                        Editable = false;
                        ToolTip = 'Specifies all billable profits for the project task, expressed in the local currency.';

                        trigger OnDrillDown()
                        begin
                            PAGE.RunModal(PAGE::"Service Contract List", TempServContract);
                        end;
                    }
                    field(ServiceItemNoText; ServiceItemNoText)
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item No.';
                        DrillDown = true;
                        Editable = false;
                        ToolTip = 'Specifies the field to see the list of related service items, if there are a number of service items.';

                        trigger OnDrillDown()
                        begin
                            PAGE.RunModal(PAGE::"Service Item List", TempServItem);
                        end;
                    }
#pragma warning disable AA0100
                    field("ServContract.""Customer No."""; ServContract."Customer No.")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Existing Customer No.';
                        Editable = false;
                        ToolTip = 'Specifies the field to see the existing customer number in the contract.';
                    }
#pragma warning disable AA0100
                    field("ServContract.""Ship-to Code"""; ServContract."Ship-to Code")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Existing Ship-to Code';
                        Editable = false;
                        ToolTip = 'Specifies the field to see the existing ship-to code in the contract.';
                    }
                    field(NewCustomerNo; NewCustomerNo)
                    {
                        ApplicationArea = Service;
                        Caption = 'New Customer No.';
                        ToolTip = 'Specifies the number of the new customer that you want to include in the batch job. Choose the field to see the existing customer numbers.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(Cust);
                            Cust."No." := NewCustomerNo;
                            Cust.SetFilter(Blocked, '<>%1', Cust.Blocked::All);
                            if PAGE.RunModal(0, Cust) = ACTION::LookupOK then
                                if Cust."No." <> '' then begin
                                    VerifyCustNo(Cust."No.", NewShiptoCode);
                                    NewCustomerNo := Cust."No.";
                                end;
                        end;

                        trigger OnValidate()
                        begin
                            if NewCustomerNo <> '' then
                                VerifyCustNo(NewCustomerNo, NewShiptoCode);
                        end;
                    }
                    field(NewShiptoCode; NewShiptoCode)
                    {
                        ApplicationArea = Service;
                        Caption = 'New Ship-to Code';
                        ToolTip = 'Specifies the new ship-to code that you want to include in the batch job. Choose the field to see the existing ship-to codes.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Clear(ShipToAddr);
                            ShipToAddr.SetRange("Customer No.", NewCustomerNo);
                            ShipToAddr.Code := NewShiptoCode;
                            if PAGE.RunModal(0, ShipToAddr) = ACTION::LookupOK then begin
                                ShipToAddr.Get(ShipToAddr."Customer No.", ShipToAddr.Code);
                                NewShiptoCode := ShipToAddr.Code;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if NewShiptoCode <> '' then
                                ShipToAddr.Get(NewCustomerNo, NewShiptoCode);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            ServContractMgt.GetAffectedItemsOnContractChange(
                ContractNo, TempServContract, TempServItem,
                false, ServContractLine."Contract Type"::Contract);

            if TempServContract.Count > 1 then
                ContractNoText := Text004
            else
                ContractNoText := TempServContract."Contract No.";

            if TempServItem.Count > 1 then
                ServiceItemNoText := Text004
            else
                ServiceItemNoText := TempServItem."No.";
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ServItem: Record "Service Item";
        Window: Dialog;
        CounterTotal: Integer;
        Counter: Integer;
        CounterBreak: Integer;
        ItemCounter: Integer;
    begin
        ServItem.LockTable();
        ServContractLine.LockTable();
        ServContract.LockTable();
        Clear(TempServContract);
        Clear(TempServItem);
        ServContractMgt.GetAffectedItemsOnContractChange(
          ContractNo, TempServContract, TempServItem, false, ServContractLine."Contract Type"::Contract);

        Window.Open(
          Text005 +
          Text006 +
          '#1###' +
          Text007 +
          '#2###  @3@@@@@@@@@\\' +
          Text008 +
          '#4###' +
          Text007 +
          '#5###  @6@@@@@@@@@\\');
        Window.Update(2, TempServContract.Count);
        Window.Update(5, TempServItem.Count);

        CounterTotal := TempServContract.Count();
        Counter := 0;
        ItemCounter := 0;
        CounterBreak := Round(CounterTotal / 100, 1, '>');
        if TempServContract.Find('-') then
            repeat
                Counter := Counter + 1;
                ItemCounter := ItemCounter + 1;
                if Counter >= CounterBreak then begin
                    Counter := 0;
                    Window.Update(3, Round(ItemCounter / CounterTotal * 10000, 1));
                end;
                Window.Update(1, ItemCounter);
                ServContract.Get(TempServContract."Contract Type", TempServContract."Contract No.");
                ServContractMgt.ChangeCustNoOnServContract(NewCustomerNo, NewShiptoCode, ServContract)
            until TempServContract.Next() = 0
        else
            Window.Update(3, 10000);

        CounterTotal := TempServItem.Count();
        Counter := 0;
        ItemCounter := 0;
        CounterBreak := Round(CounterTotal / 100, 1, '>');
        if TempServItem.Find('-') then
            repeat
                Counter := Counter + 1;
                ItemCounter := ItemCounter + 1;
                if Counter >= CounterBreak then begin
                    Counter := 0;
                    Window.Update(6, Round(ItemCounter / CounterTotal * 10000, 1));
                end;
                Window.Update(4, ItemCounter);
                ServItem.Get(TempServItem."No.");
                ServContractMgt.ChangeCustNoOnServItem(NewCustomerNo, NewShiptoCode, ServItem)
            until TempServItem.Next() = 0
        else
            Window.Update(6, 10000);
    end;

    trigger OnPreReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if NewCustomerNo = '' then
            Error(Text000);
        Cust.Get(NewCustomerNo);
        if NewShiptoCode <> '' then
            ShipToAddr.Get(NewCustomerNo, NewShiptoCode);
        if (NewShiptoCode = ServContract."Ship-to Code") and
           (NewCustomerNo = ServContract."Customer No.")
        then
            Error(Text011);

        if not ConfirmManagement.GetResponseOrDefault(Text002, true) then
            CurrReport.Quit();

        if TempServContract.Count > 1 then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text009, TempServContract.Count, TempServItem.Count), true)
            then
                CurrReport.Quit();
    end;

    var
        ServContract: Record "Service Contract Header";
        Cust: Record Customer;
        ShipToAddr: Record "Ship-to Address";
        ServContractLine: Record "Service Contract Line";
        TempServContract: Record "Service Contract Header" temporary;
        TempServItem: Record "Service Item" temporary;
        ServContractMgt: Codeunit ServContractManagement;
        ContractNo: Code[20];
        NewCustomerNo: Code[20];
        NewShiptoCode: Code[10];
        ContractNoText: Text[20];
        ServiceItemNoText: Text[20];

#pragma warning disable AA0074
        Text000: Label 'You must fill in the New Customer No. field.';
        Text002: Label 'If you change the customer number or the ship-to code, the related service orders and sales invoices will not be updated.\\Do you want to continue?';
        Text004: Label '(Multiple)';
        Text005: Label 'Updating related objects...\\';
        Text006: Label 'Contract     ';
        Text007: Label ' from ';
        Text008: Label 'Service item ';
#pragma warning disable AA0470
        Text009: Label 'Are you sure that you want to change the customer number in %1 related contracts/quotes and %2 related service items?';
#pragma warning restore AA0470
        Text010: Label 'You cannot select a customer with the status Blocked.';
        Text011: Label 'The customer number and the ship-to code that you have selected are the same as the ones on this document.';
#pragma warning restore AA0074

    procedure SetRecord(ContrNo: Code[20])
    begin
        ContractNo := ContrNo;
        ServContract.Get(ServContract."Contract Type"::Contract, ContractNo);
        ServContract.TestField("Change Status", ServContract."Change Status"::Open);
    end;

    local procedure VerifyCustNo(CustNo: Code[20]; ShiptoCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        if CustNo <> '' then begin
            Cust.Get(CustNo);
            IsHandled := false;
            OnVerifyCustNoOnBeforeCheck(CustNo, IsHandled);
            if not IsHandled then begin
                if Cust."Privacy Blocked" then
                    Error(Cust.GetPrivacyBlockedGenericErrorText(Cust));
                if Cust.Blocked = Cust.Blocked::All then
                    Error(Text010);
                if not ShipToAddr.Get(CustNo, ShiptoCode) then
                    NewShiptoCode := '';
            end;
        end;
    end;

    procedure InitializeRequest(NewCustomerNoFrom: Code[20]; NewShipToCodeFrom: Code[10])
    begin
        NewCustomerNo := NewCustomerNoFrom;
        NewShiptoCode := NewShipToCodeFrom;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyCustNoOnBeforeCheck(CustNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

