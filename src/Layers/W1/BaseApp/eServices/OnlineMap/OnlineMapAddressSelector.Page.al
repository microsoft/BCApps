// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

page 802 "Online Map Address Selector"
{
    Caption = 'Online Map Address Selector';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LookupSelection; LookupSelection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Selection';

                    trigger OnValidate()
                    begin
                        LookupSelectionOnAfterValidate();
                    end;
                }
                field(LookupCode; LookupCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Lookup Code';
                    ToolTip = 'Specifies a list of contact, customer, or location codes to choose from.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        SelectedRecPosition := LoadLocationLookup(SelectedTableNo, LookupCode, true);
                    end;

                    trigger OnValidate()
                    begin
                        SelectedRecPosition := LoadLocationLookup(SelectedTableNo, LookupCode, false);
                    end;
                }
                field(Distance; Distance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Distance In';
                    OptionCaption = 'Miles,Kilometers';
                    ToolTip = 'Specifies if distances on the online map are shown in miles or kilometers.';
                }
                field(Route; Route)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Route';
                    OptionCaption = 'Quickest,Shortest';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        OnlineMapSetup.Get();
        Distance := OnlineMapSetup."Distance In";
        Route := OnlineMapSetup.Route;
    end;

    var
        OnlineMapSetup: Record "Online Map Setup";
        SelectedRecPosition: Text[1000];
        LookupCode: Code[20];
        LookupSelection: Enum "Online Map Table Selection";
#pragma warning disable AA0074
        Text001: Label 'The selection that was chosen is not valid.';
#pragma warning disable AA0470
        Text003: Label 'The value %1 from Table ID %2 could not be found.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Distance: Option Miles,Kilometers;
        Route: Option Quickest,Shortest;
        SelectedTableNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Table No. %1 is not set up.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetTableNo(): Integer
    begin
        exit(SelectedTableNo);
    end;

    procedure GetRecPosition(): Text[1000]
    begin
        exit(SelectedRecPosition);
    end;

    procedure SetTableNo()
    var
        IsHandled: Boolean;
    begin
        case LookupSelection of
            LookupSelection::" ":
                SelectedTableNo := 0;
            LookupSelection::Bank:
                SelectedTableNo := Database::"Bank Account";
            LookupSelection::Contact:
                SelectedTableNo := Database::Contact;
            LookupSelection::Customer:
                SelectedTableNo := Database::Customer;
            LookupSelection::Employee:
                SelectedTableNo := Database::Employee;
            LookupSelection::Job:
                SelectedTableNo := Database::Job;
            LookupSelection::Location:
                SelectedTableNo := Database::Location;
            LookupSelection::Resource:
                SelectedTableNo := Database::Resource;
            LookupSelection::Vendor:
                SelectedTableNo := Database::Vendor;
            LookupSelection::"Ship-to Address":
                SelectedTableNo := Database::"Ship-to Address";
            LookupSelection::"Order Address":
                SelectedTableNo := Database::"Order Address";
            else begin
                IsHandled := false;
                OnSetTableNoElseCase(LookupSelection.AsInteger(), SelectedTableNo, IsHandled);
                if not IsHandled then
                    Error(Text001);
            end;
        end;

        OnAfterSetTableNo(LookupSelection, SelectedTableNo);
    end;

    local procedure LoadLocationLookup(LoadTableNo: Integer; var LookupCode: Code[20]; Lookup: Boolean): Text[1000]
    var
        SelectedRecPosition: Text;
        IsHandled: Boolean;
    begin
        case LoadTableNo of
            Database::"Bank Account":
                exit(LoadBankAccount(LookupCode, Lookup));
            Database::Contact:
                exit(LoadContact(LookupCode, Lookup));
            Database::Customer:
                exit(LoadCustomer(LookupCode, Lookup));
            Database::Employee:
                exit(LoadEmployee(LookupCode, Lookup));
            Database::Job:
                exit(LoadJob(LookupCode, Lookup));
            Database::Location:
                exit(LoadLocation(LookupCode, Lookup));
            Database::Resource:
                exit(LoadResource(LookupCode, Lookup));
            Database::Vendor:
                exit(LoadVendor(LookupCode, Lookup));
            Database::"Ship-to Address":
                exit(LoadShipTo(LookupCode, Lookup));
            Database::"Order Address":
                exit(LoadOrderAddress(LookupCode, Lookup));
            else begin
                OnLoadLocationLookupElseCase(LoadTableNo, LookupCode, Lookup, SelectedRecPosition, IsHandled);
                if IsHandled then
                    exit(SelectedRecPosition);

                Error(Text004, Format(LoadTableNo));
            end;
        end;
    end;

    local procedure LoadBankAccount(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        BankAccount: Record "Bank Account";
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Bank Account List", BankAccount) = ACTION::LookupOK
        else
            Response := BankAccount.Get(LookUpCode);

        if Response then begin
            LookUpCode := BankAccount."No.";
            exit(BankAccount.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::"Bank Account");
    end;

    local procedure LoadContact(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Contact: Record Contact;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Contact List", Contact) = ACTION::LookupOK
        else
            Response := Contact.Get(LookUpCode);

        if Response then begin
            LookUpCode := Contact."No.";
            exit(Contact.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Contact);
    end;

    local procedure LoadCustomer(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Customer: Record Customer;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Customer List", Customer) = ACTION::LookupOK
        else
            Response := Customer.Get(LookUpCode);

        if Response then begin
            LookUpCode := Customer."No.";
            exit(Customer.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Customer);
    end;

    local procedure LoadEmployee(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Employee: Record Employee;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Employee List", Employee) = ACTION::LookupOK
        else
            Response := Employee.Get(LookUpCode);

        if Response then begin
            LookUpCode := Employee."No.";
            exit(Employee.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Employee);
    end;

    local procedure LoadJob(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Job: Record Job;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Job List", Job) = ACTION::LookupOK
        else
            Response := Job.Get(LookUpCode);

        if Response then begin
            LookUpCode := Job."No.";
            exit(Job.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Job);
    end;

    local procedure LoadLocation(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Location: Record Location;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Location List", Location) = ACTION::LookupOK
        else
            Response := Location.Get(LookUpCode);

        if Response then begin
            LookUpCode := Location.Code;
            exit(Location.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Location);
    end;

    local procedure LoadResource(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Resource: Record Resource;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Resource List", Resource) = ACTION::LookupOK
        else
            Response := Resource.Get(LookUpCode);

        if Response then begin
            LookUpCode := Resource."No.";
            exit(Resource.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Resource);
    end;

    local procedure LoadVendor(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        Vendor: Record Vendor;
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Vendor List", Vendor) = ACTION::LookupOK
        else
            Response := Vendor.Get(LookUpCode);

        if Response then begin
            LookUpCode := Vendor."No.";
            exit(Vendor.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::Vendor);
    end;

    local procedure LoadShipTo(var LookUpCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        ShipToAddress: Record "Ship-to Address";
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Ship-to Address List", ShipToAddress) = ACTION::LookupOK
        else
            Response := ShipToAddress.Get(LookUpCode);

        if Response then begin
            LookUpCode := ShipToAddress.Code;
            exit(ShipToAddress.GetPosition());
        end;
        Error(Text003, LookUpCode, Database::"Ship-to Address");
    end;

    local procedure LoadOrderAddress(var LookupCode: Code[20]; LookUp: Boolean): Text[1000]
    var
        OrderAddress: Record "Order Address";
        Response: Boolean;
    begin
        if LookUp then
            Response := PAGE.RunModal(PAGE::"Order Address List", OrderAddress) = ACTION::LookupOK
        else
            Response := OrderAddress.Get(LookupCode);

        if Response then begin
            LookupCode := OrderAddress.Code;
            exit(OrderAddress.GetPosition());
        end;
        Error(Text003, LookupCode, Database::"Order Address");
    end;

    procedure Getdefaults(var ActualDistance: Option Miles,Kilometers; var ActualRoute: Option Quickest,Shortest)
    begin
        ActualDistance := Distance;
        ActualRoute := Route;
    end;

    local procedure LookupSelectionOnAfterValidate()
    begin
        SetTableNo();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTableNo(LookupSelection: Enum "Online Map Table Selection"; var SelectedTableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadLocationLookupElseCase(LoadTableNo: Integer; var LookupCode: Code[20]; Lookup: Boolean; var SelectedRecPosition: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetTableNoElseCase(LookupSelection: Option; var SelectedTableNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

