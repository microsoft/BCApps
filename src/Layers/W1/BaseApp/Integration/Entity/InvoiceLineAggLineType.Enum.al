// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

enum 5478 "Invoice Line Agg. Line Type"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; Comment)
    {
        Caption = 'Comment';
    }
    value(1; Account)
    {
        Caption = 'Account';
    }
    value(2; Item)
    {
        Caption = 'Item';
    }
    value(3; Resource)
    {
        Caption = 'Resource';
    }
    value(4; "Fixed Asset")
    {
        Caption = 'Fixed Asset';
    }
    value(5; Charge)
    {
        Caption = 'Charge';
    }
    value(10; "Allocation Account") 
    { 
        Caption = 'Allocation Account'; 
    }
}
