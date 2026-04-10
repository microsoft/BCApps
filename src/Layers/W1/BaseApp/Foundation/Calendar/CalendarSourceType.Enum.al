// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

enum 7602 "Calendar Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Company)
    {
        Caption = 'Company';
    }
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    value(2; Vendor)
    {
        Caption = 'Vendor';
    }
    value(3; Location)
    {
        Caption = 'Location';
    }
    value(4; "Shipping Agent")
    {
        Caption = 'Shipping Agent';
    }
    value(5; Service)
    {
        Caption = 'Service';
    }
}
