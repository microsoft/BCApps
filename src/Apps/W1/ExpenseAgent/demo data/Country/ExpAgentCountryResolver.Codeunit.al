// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Company;

codeunit 8221 "Exp. Agent Country Resolver"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Resolve() CountryData: Interface "Expense Agent Country Data"
    begin
        CountryData := ResolveCountry();
    end;

    procedure ResolveCountry() Country: Enum "Expense Agent Country"
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then
            case CompanyInformation."Country/Region Code" of
                'US':
                    exit(Country::US);
                'GB':
                    exit(Country::GB);
                'CA':
                    exit(Country::CA);
                'NZ':
                    exit(Country::NZ);
                'AU':
                    exit(Country::AU);
                'ES':
                    exit(Country::ES);
                'DK':
                    exit(Country::DK);
                'FR':
                    exit(Country::FR);
                'DE':
                    exit(Country::DE);
                'AT':
                    exit(Country::AT);
            end;
        exit(Country::Default);
    end;
}
