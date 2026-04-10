// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Sales.Customer;
using System.Environment.Configuration;

codeunit 206 "Ship Alt. Cust. VAT Reg. Impl." implements "Ship-To Alt. Cust. VAT Reg."
{
    Access = Internal;

    var
        AltCustVATRegFacade: Codeunit "Alt. Cust. VAT. Reg. Facade";
        AddAlternativeCustVATRegQst: Label 'The country for the address is different than the customer''s. Do you want to add an alternative VAT registration for the customer?';
        AddAlternativeCustVATRegMsg: Label 'Add';
        DontShowMsg: Label 'Don''t show';
        AddAltCustVATRegNotificationNameTok: Label 'Suggest an alternative customer VAT registration from ship-to address';
        AddAltCustVATRegNotificationDescTok: Label 'Suggest the user to add an alternative customer VAT registration when choosing a Ship-To country different from the customer''s';

    procedure HandleCountryChangeInShipToAddress(ShipToAddress: Record "Ship-to Address")
    var
        Customer: Record Customer;
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
    begin
        Customer.SetLoadFields("No.", "Country/Region Code");
        if not Customer.Get(ShipToAddress."Customer No.") then
            exit;
        if Customer."Country/Region Code" = ShipToAddress."Country/Region Code" then
            exit;
        if AltCustVATRegFacade.GetAlternativeCustVATReg(AltCustVATReg, ShipToAddress."Customer No.", ShipToAddress."Country/Region Code") then
            exit;
        ThrowAddAltCustVATRegNotification(ShipToAddress);
    end;

    procedure AddAltCustVATRegFromNotification(Notification: Notification)
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        ShipToAddress: Record "Ship-to Address";
        NewId: Integer;
    begin
        if AltCustVATReg.FindLast() then
            NewId := AltCustVATReg.Id;
        NewId += 1;
        AltCustVATReg.Init();
        AltCustVATReg.Validate(Id, NewId);
        AltCustVATReg.Validate("Customer No.",
            CopyStr(Notification.GetData(ShipToAddress.FieldName("Customer No.")), 1, MaxStrLen(ShipToAddress."Customer No.")));
        AltCustVATReg.Validate("VAT Country/Region Code",
            CopyStr(Notification.GetData(ShipToAddress.FieldName("Country/Region Code")), 1, MaxStrLen(ShipToAddress."Country/Region Code")));
        AltCustVATReg.Insert(true);
        Commit();
        Page.RunModal(0, AltCustVATReg);
    end;

    procedure DisableAddAltCustVATRegNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(Notification.Id()) then
            MyNotifications.InsertDefault(Notification.Id(), AddAltCustVATRegNotificationNameTok, AddAltCustVATRegNotificationDescTok, false);
    end;

    local procedure ThrowAddAltCustVATRegNotification(ShipToAddress: Record "Ship-to Address")
    var
        MyNotifications: Record "My Notifications";
        Notification: Notification;
    begin
        if not MyNotifications.IsEnabled(AddAltCustVATRegNotificationId()) then
            exit;
        Notification.Id(AddAltCustVATRegNotificationId());
        Notification.Message(AddAlternativeCustVATRegQst);
        Notification.SetData(ShipToAddress.FieldName("Customer No."), ShipToAddress."Customer No.");
        Notification.SetData(ShipToAddress.FieldName("Country/Region Code"), ShipToAddress."Country/Region Code");
        Notification.AddAction(AddAlternativeCustVATRegMsg, Codeunit::"Ship Alt. Cust. VAT Reg. Impl.", 'AddAltCustVATRegFromNotification');
        Notification.AddAction(DontShowMsg, Codeunit::"Ship Alt. Cust. VAT Reg. Impl.", 'DisableAddAltCustVATRegNotification');
        Notification.Send();
    end;

    local procedure AddAltCustVATRegNotificationId(): Text
    begin
        exit('44c9f482-ed1e-4882-9c96-3135915b566b')
    end;
}