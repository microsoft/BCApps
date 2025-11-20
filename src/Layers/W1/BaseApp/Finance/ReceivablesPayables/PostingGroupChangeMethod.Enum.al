// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

enum 960 "Posting Group Change Method" implements "Posting Group Change Method"
{
    Extensible = true;

    value(0; "Alternative Groups")
    {
        Caption = 'Alternative Groups';
        Implementation = "Posting Group Change Method" = "Posting Group Change";
    }
}
