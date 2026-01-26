// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 10705 "SII Tax Period"
{
    Extensible = true;

    value(0; Monthly) { Caption = 'Monthly'; }
    value(1; Quarterly) { Caption = 'Quarterly'; }
}