// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

enum 3352 "MX Compl. Cancel Status"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Cancel In Progress")
    {
        Caption = 'Cancel In Progress';
    }
    value(2; Canceled)
    {
        Caption = 'Canceled';
    }
    value(3; "Cancel Error")
    {
        Caption = 'Cancel Error';
    }
}
