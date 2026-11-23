// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 20581 "Subc. WIP Processing State"
{
    Extensible = false;
    value(0; Unprocessed) { Caption = 'Unprocessed'; }
    value(1; Processed) { Caption = 'Processed'; }
}
