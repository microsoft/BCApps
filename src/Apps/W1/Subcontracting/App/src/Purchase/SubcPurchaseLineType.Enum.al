// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;
#pragma warning disable AS0072, AS0136
enum 20507 "Subc. Purchase Line Type"
{
    Extensible = true;

    value(0; None)
    {
        Caption = ' ';
    }
    value(1; LastOperation)
    {
        Caption = 'Last Operation';
    }
    value(2; NotLastOperation)
    {
        Caption = 'Not Last Operation';
    }
}
#pragma warning restore AS0072, AS0136
