// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving;

enum 20453 "Qlty. Sales Return Trigger"
{
    Extensible = true;
    Caption = 'Quality Sales Return Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnSalesReturnOrderPostReceive)
    {
        Caption = 'When Sales Return Order is received';
    }
}
