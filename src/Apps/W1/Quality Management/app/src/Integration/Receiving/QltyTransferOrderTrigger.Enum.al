// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Receiving;

/// <summary>
/// Helps determine the trigger for transfer specific reactions.
/// </summary>
enum 20454 "Qlty. Transfer Order Trigger"
{
    Extensible = true;
    Caption = 'Quality Transfer Order Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnTransferOrderPostReceive)
    {
        Caption = 'When Transfer Order is received';
    }
}
