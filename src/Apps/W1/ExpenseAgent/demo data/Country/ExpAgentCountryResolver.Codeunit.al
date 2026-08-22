// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool;

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
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
    begin
        if ContosoCoffeeDemoDataSetup.Get() then
            case ContosoCoffeeDemoDataSetup."Country/Region Code" of
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
                'NL':
                    exit(Country::NL);
                'BE':
                    exit(Country::BE);
                'IT':
                    exit(Country::IT);
                'CH':
                    exit(Country::CH);
                'NO':
                    exit(Country::NO);
                'FI':
                    exit(Country::FI);
                'CZ':
                    exit(Country::CZ);
            end;
        exit(Country::Default);
    end;
}
