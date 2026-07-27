// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.BE;

using Microsoft.Integration.Shopify;
using Microsoft.Sales.Customer;

/// <summary>
/// Codeunit Shpfy Enterprise No. BE (ID 30461) implements Interface Shpfy Tax Registration Id Mapping.
/// Maps the Shopify tax registration id to the Belgian Enterprise No. field on the customer,
/// which is the legally required tax identifier for Belgian customers.
/// </summary>
codeunit 30461 "Shpfy Enterprise No. BE" implements "Shpfy Tax Registration Id Mapping"
{
    Access = Internal;

    procedure GetTaxRegistrationId(var Customer: Record Customer): Text[150]
    begin
        exit(Customer."Enterprise No.");
    end;

    procedure SetMappingFiltersForCustomers(var Customer: Record Customer; CompanyLocation: Record "Shpfy Company Location")
    begin
        Customer.SetRange("Enterprise No.", CompanyLocation."Tax Registration Id");
    end;

    procedure UpdateTaxRegistrationId(var Customer: Record Customer; NewTaxRegistrationId: Text[150])
    begin
        Customer.Validate("Enterprise No.", CopyStr(NewTaxRegistrationId, 1, MaxStrLen(Customer."Enterprise No.")));
        Customer.Modify(true);
    end;
}
