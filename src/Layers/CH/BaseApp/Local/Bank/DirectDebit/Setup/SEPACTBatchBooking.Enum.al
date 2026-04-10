// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

enum 11503 "SEPA CT Batch Booking"
{
    Extensible = true;

    value(0; Auto)
    {
        Caption = 'Auto';
    }
    value(1; Always)
    {
        Caption = 'Always';
    }
    value(2; Never)
    {
        Caption = 'Never';
    }
}
