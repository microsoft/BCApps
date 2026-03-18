// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

#pragma warning disable AL0659
enum 5997 "Service Contract Header Invoice Period"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Month)
    {
        Caption = 'Month';
    }
    value(1; "Two Months")
    {
        Caption = 'Two Months';
    }
    value(2; Quarter)
    {
        Caption = 'Quarter';
    }
    value(3; "Half Year")
    {
        Caption = 'Half Year';
    }
    value(4; Year)
    {
        Caption = 'Year';
    }
    value(5; "None")
    {
        Caption = 'None';
    }
}
