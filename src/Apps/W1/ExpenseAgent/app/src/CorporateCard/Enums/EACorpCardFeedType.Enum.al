// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7430 "EA Corp Card Feed Type" implements "EA Corp Card Provider"
{
    Access = Internal;
    Caption = 'Corp Card Feed Type';
    Extensible = true;

    value(0; DataExch)
    {
        Caption = 'Data Exchange';
        Implementation = "EA Corp Card Provider" = "EA Corp Card Data Exch Prov";
    }
    value(2; CSV)
    {
        Caption = 'CSV';
        Implementation = "EA Corp Card Provider" = "EA Corp Card Data Exch Prov";
    }
    value(4; XML)
    {
        Caption = 'XML';
        Implementation = "EA Corp Card Provider" = "EA Corp Card Data Exch Prov";
    }
}