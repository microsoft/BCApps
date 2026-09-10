// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN29
namespace Microsoft.ExpenseAgent;

using Microsoft.Inventory.Location;

page 6958 "Expense Location API"
{
    APIGroup = 'expense';
    APIPublisher = 'microsoft';
    APIVersion = 'beta';
    EntityCaption = 'Location';
    EntitySetCaption = 'Locations';
    EntityName = 'location';
    EntitySetName = 'locations';
    ObsoleteReason = 'Expense Location API is no longer required.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;
    PageType = API;
    ODataKeyFields = SystemId;
    SourceTable = Location;
    AboutText = 'Exposes warehouse and inventory location master data including codes, addresses, contact details, and operational settings. Supports full CRUD operations to synchronize fulfillment nodes, manage routing rules, and integrate external WMS or e-commerce platforms with Business Central, ensuring all inventory movements and documents reference valid locations.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(code; Rec.Code)
                {
                    Caption = 'Code';
                }
                field(displayName; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(contact; Rec.Contact)
                {
                    Caption = 'Contact';
                }
                field(addressLine1; Rec.Address)
                {
                    Caption = 'Address Line 1';
                }
                field(addressLine2; Rec."Address 2")
                {
                    Caption = 'Address Line 2';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(state; Rec.County)
                {
                    Caption = 'State';
                }
                field(country; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(postalCode; Rec."Post Code")
                {
                    Caption = 'Post Code';
                }
                field(phoneNumber; Rec."Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(email; Rec."E-Mail")
                {
                    Caption = 'Email';
                }
                field(website; Rec."Home Page")
                {
                    Caption = 'Website';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInit()
    var
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
    begin
        ExpenseAgentAPIValidation.VerifyAgentAccess();
    end;
}
#endif